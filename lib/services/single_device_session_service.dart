import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'installation_id_service.dart';
import 'package:maiyen_app/helpers/debug_log.dart';
import '../config/maiyen_identifiers.dart';

class SingleDeviceSessionIdentity {
  const SingleDeviceSessionIdentity({
    required this.uid,
    required this.installationId,
    required this.sessionId,
  });

  final String uid;
  final String installationId;
  final String sessionId;
}

class SingleDeviceSessionValidationResult {
  const SingleDeviceSessionValidationResult._({
    required this.isValid,
    this.identity,
  });

  factory SingleDeviceSessionValidationResult.valid(
    SingleDeviceSessionIdentity identity,
  ) {
    return SingleDeviceSessionValidationResult._(
      isValid: true,
      identity: identity,
    );
  }

  factory SingleDeviceSessionValidationResult.invalid() {
    return const SingleDeviceSessionValidationResult._(isValid: false);
  }

  final bool isValid;
  final SingleDeviceSessionIdentity? identity;
}

class ActiveSessionConflictException implements Exception {
  const ActiveSessionConflictException();
}

class SingleDeviceSessionService {
  const SingleDeviceSessionService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Duration _activeSessionHeartbeatInterval = Duration(minutes: 5);

  static final ValueNotifier<bool> interactiveLoginInProgress =
      ValueNotifier<bool>(false);

  static final Random _random = Random.secure();

  static Completer<void>? _interactiveLoginCompleter;
  static Future<SingleDeviceSessionIdentity>? _claimInProgress;
  static Future<SingleDeviceSessionValidationResult>? _validationInProgress;
  static StreamSubscription<DatabaseEvent>? _activeSessionSubscription;
  static Timer? _activeSessionHeartbeatTimer;

  static String _validationUid = '';
  static bool _validationAllowLegacyBootstrap = false;
  static String _listeningUid = '';
  static bool _localLogoutInProgress = false;
  static bool _remoteLogoutInProgress = false;

  static String platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }

  static void prepareForInteractiveLogin() {
    final completer = _interactiveLoginCompleter;

    if (completer != null && !completer.isCompleted) {
      return;
    }

    _interactiveLoginCompleter = Completer<void>();
    interactiveLoginInProgress.value = true;
  }

  static void cancelInteractiveLogin() {
    final completer = _interactiveLoginCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }

    interactiveLoginInProgress.value = false;
  }

  static Future<bool> hasActiveSessionOnAnotherInstallation({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return false;
    }

    final installationId = await InstallationIdService.getOrCreate();
    final activeValue = (await _activeSessionRef(cleanUid).get()).value;

    return _belongsToAnotherInstallation(
      activeValue,
      installationId: installationId,
    );
  }

  static Future<SingleDeviceSessionIdentity> claimForInteractiveLogin({
    required String uid,
    bool allowReplacingOtherInstallation = false,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Future<SingleDeviceSessionIdentity>.error(
        ArgumentError('uid is required'),
      );
    }

    final running = _claimInProgress;

    if (running != null) {
      return running;
    }

    final future = _claimForInteractiveLoginInternal(
      cleanUid,
      allowReplacingOtherInstallation: allowReplacingOtherInstallation,
    );
    _claimInProgress = future;

    return future.whenComplete(() {
      if (identical(_claimInProgress, future)) {
        _claimInProgress = null;
      }
    });
  }

  static Future<SingleDeviceSessionIdentity> _claimForInteractiveLoginInternal(
    String uid, {
    required bool allowReplacingOtherInstallation,
  }) async {
    final completer = _interactiveLoginCompleter ??= Completer<void>();
    final installationId = await InstallationIdService.getOrCreate();
    final sessionId = _generateSessionId();
    final identity = SingleDeviceSessionIdentity(
      uid: uid,
      installationId: installationId,
      sessionId: sessionId,
    );

    try {
      await _writeLocalSessionId(uid: uid, sessionId: sessionId);

      final result = await _activeSessionRef(uid).runTransaction((
        currentValue,
      ) {
        if (!allowReplacingOtherInstallation &&
            _belongsToAnotherInstallation(
              currentValue,
              installationId: installationId,
            )) {
          return Transaction.abort();
        }

        return Transaction.success(_activeSessionPayload(identity));
      }, applyLocally: false);

      if (!result.committed) {
        final latestValue = (await _activeSessionRef(uid).get()).value;

        if (_belongsToAnotherInstallation(
          latestValue,
          installationId: installationId,
        )) {
          throw const ActiveSessionConflictException();
        }

        throw StateError('Active session claim was not committed');
      }

      try {
        await _revokeSupersededClientRecords(identity);
      } catch (error) {
        safeDebugPrint('SUPERSEDED_SESSION_CLEANUP_ERROR: $error');
      }

      await clearInteractiveLoginRequirement(uid: uid);
      _startActiveSessionHeartbeat(identity);

      if (!completer.isCompleted) {
        completer.complete();
      }

      interactiveLoginInProgress.value = false;

      return identity;
    } catch (error) {
      await clearLocalSession(uid: uid);

      rethrow;
    }
  }

  static Future<SingleDeviceSessionValidationResult> ensureValidSession({
    required String uid,
    required bool allowLegacyBootstrap,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Future<SingleDeviceSessionValidationResult>.value(
        SingleDeviceSessionValidationResult.invalid(),
      );
    }

    final running = _validationInProgress;

    if (running != null &&
        _validationUid == cleanUid &&
        _validationAllowLegacyBootstrap == allowLegacyBootstrap) {
      return running;
    }

    final future = _ensureValidSessionInternal(
      uid: cleanUid,
      allowLegacyBootstrap: allowLegacyBootstrap,
    );
    _validationUid = cleanUid;
    _validationAllowLegacyBootstrap = allowLegacyBootstrap;
    _validationInProgress = future;

    return future.whenComplete(() {
      if (identical(_validationInProgress, future)) {
        _validationInProgress = null;
        _validationUid = '';
      }
    });
  }

  static Future<SingleDeviceSessionValidationResult>
  _ensureValidSessionInternal({
    required String uid,
    required bool allowLegacyBootstrap,
  }) async {
    final interactiveLogin = _interactiveLoginCompleter;

    if (interactiveLogin != null && !interactiveLogin.isCompleted) {
      await interactiveLogin.future;
    }

    final installationId = await InstallationIdService.getOrCreate();
    final localSessionId = await readLocalSessionId(uid: uid);
    final interactiveLoginRequired = await isInteractiveLoginRequired(uid: uid);
    final activeSnapshot = await _activeSessionRef(uid).get();
    final active = _activeSessionFromValue(activeSnapshot.value, uid: uid);

    if (interactiveLoginRequired) {
      _activeSessionHeartbeatTimer?.cancel();
      _activeSessionHeartbeatTimer = null;
      return SingleDeviceSessionValidationResult.invalid();
    }

    if (active != null) {
      if (active.installationId == installationId &&
          active.sessionId == localSessionId) {
        _startActiveSessionHeartbeat(active);
        unawaited(touchActiveSessionIfCurrent(uid: uid));
        return SingleDeviceSessionValidationResult.valid(active);
      }

      await requireInteractiveLogin(uid: uid);
      _activeSessionHeartbeatTimer?.cancel();
      _activeSessionHeartbeatTimer = null;
      return SingleDeviceSessionValidationResult.invalid();
    }

    if (!allowLegacyBootstrap) {
      return SingleDeviceSessionValidationResult.invalid();
    }

    return _bootstrapLegacyFirstSession(
      uid: uid,
      installationId: installationId,
      localSessionId: localSessionId,
    );
  }

  static Future<SingleDeviceSessionValidationResult>
  _bootstrapLegacyFirstSession({
    required String uid,
    required String installationId,
    required String localSessionId,
  }) async {
    final sessionId = _isValidSessionId(localSessionId)
        ? localSessionId
        : _generateSessionId();
    final identity = SingleDeviceSessionIdentity(
      uid: uid,
      installationId: installationId,
      sessionId: sessionId,
    );

    await _writeLocalSessionId(uid: uid, sessionId: sessionId);

    final result = await _activeSessionRef(uid).runTransaction((currentValue) {
      final current = _activeSessionFromValue(currentValue, uid: uid);

      if (current != null) {
        return Transaction.abort();
      }

      return Transaction.success(_activeSessionPayload(identity));
    }, applyLocally: false);

    if (result.committed) {
      try {
        await _revokeSupersededClientRecords(identity);
      } catch (error) {
        safeDebugPrint('LEGACY_SESSION_CLEANUP_ERROR: $error');
      }

      await clearInteractiveLoginRequirement(uid: uid);
      _startActiveSessionHeartbeat(identity);
      return SingleDeviceSessionValidationResult.valid(identity);
    }

    final latest = _activeSessionFromValue(
      (await _activeSessionRef(uid).get()).value,
      uid: uid,
    );

    if (latest != null &&
        latest.installationId == installationId &&
        latest.sessionId == sessionId) {
      await clearInteractiveLoginRequirement(uid: uid);
      _startActiveSessionHeartbeat(latest);
      return SingleDeviceSessionValidationResult.valid(latest);
    }

    await clearLocalSession(uid: uid);
    await requireInteractiveLogin(uid: uid);
    return SingleDeviceSessionValidationResult.invalid();
  }

  static Future<SingleDeviceSessionIdentity?> currentSessionIdentityIfActive({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    final installationId = await InstallationIdService.getOrCreate();
    final sessionId = await readLocalSessionId(uid: cleanUid);

    if (!_isValidSessionId(sessionId)) {
      return null;
    }

    final active = _activeSessionFromValue(
      (await _activeSessionRef(cleanUid).get()).value,
      uid: cleanUid,
    );

    if (active == null ||
        active.installationId != installationId ||
        active.sessionId != sessionId) {
      return null;
    }

    return active;
  }

  static Future<bool> touchActiveSessionIfCurrent({required String uid}) async {
    final identity = await currentSessionIdentityIfActive(uid: uid);

    if (identity == null) {
      return false;
    }

    final result = await _activeSessionRef(uid).runTransaction((currentValue) {
      final current = _activeSessionFromValue(currentValue, uid: uid);

      if (current == null ||
          current.installationId != identity.installationId ||
          current.sessionId != identity.sessionId) {
        return Transaction.abort();
      }

      final currentMap = _asStringKeyedMap(currentValue);

      return Transaction.success({
        ...currentMap,
        'installationId': identity.installationId,
        'sessionId': identity.sessionId,
        'platform': platformName(),
        'lastSeenAt': ServerValue.timestamp,
      });
    }, applyLocally: false);

    return result.committed;
  }

  static void startActiveSessionListener({
    required String uid,
    required Future<void> Function() onSessionRevoked,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty || _listeningUid == cleanUid) {
      return;
    }

    unawaited(stopActiveSessionListener());
    _listeningUid = cleanUid;

    _activeSessionSubscription = _activeSessionRef(cleanUid).onValue.listen(
      (event) {
        unawaited(
          _handleActiveSessionEvent(
            uid: cleanUid,
            event: event,
            onSessionRevoked: onSessionRevoked,
          ),
        );
      },
      onError: (Object error) {
        safeDebugPrint('ACTIVE_SESSION_LISTENER_ERROR: $error');
      },
    );
  }

  static Future<void> _handleActiveSessionEvent({
    required String uid,
    required DatabaseEvent event,
    required Future<void> Function() onSessionRevoked,
  }) async {
    if (_localLogoutInProgress || _remoteLogoutInProgress) {
      return;
    }

    final active = _activeSessionFromValue(event.snapshot.value, uid: uid);
    final installationId = await InstallationIdService.getOrCreate();
    final sessionId = await readLocalSessionId(uid: uid);

    if (active != null &&
        active.installationId == installationId &&
        active.sessionId == sessionId) {
      return;
    }

    if (_remoteLogoutInProgress) {
      return;
    }

    _remoteLogoutInProgress = true;
    _activeSessionHeartbeatTimer?.cancel();
    _activeSessionHeartbeatTimer = null;

    try {
      await requireInteractiveLogin(uid: uid);
      await onSessionRevoked();
    } finally {
      _remoteLogoutInProgress = false;
    }
  }

  static Future<void> stopActiveSessionListener() async {
    await _activeSessionSubscription?.cancel();
    _activeSessionSubscription = null;
    _listeningUid = '';
  }

  static Future<void> beginLocalLogout() async {
    _localLogoutInProgress = true;
    _activeSessionHeartbeatTimer?.cancel();
    _activeSessionHeartbeatTimer = null;
    await stopActiveSessionListener();
  }

  static void finishLocalLogout() {
    _localLogoutInProgress = false;
    _remoteLogoutInProgress = false;
  }

  static Future<bool> clearActiveSessionIfCurrent({required String uid}) async {
    final identity = await currentSessionIdentityIfActive(uid: uid);

    if (identity == null) {
      return false;
    }

    final result = await _activeSessionRef(uid).runTransaction((currentValue) {
      final current = _activeSessionFromValue(currentValue, uid: uid);

      if (current == null ||
          current.installationId != identity.installationId ||
          current.sessionId != identity.sessionId) {
        return Transaction.abort();
      }

      return Transaction.success(null);
    }, applyLocally: false);

    return result.committed;
  }

  static Future<void> requireInteractiveLogin({required String uid}) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    await _storage.write(
      key: _interactiveLoginRequiredStorageKey(cleanUid),
      value: 'true',
    );
  }

  static Future<void> clearInteractiveLoginRequirement({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    await _storage.delete(key: _interactiveLoginRequiredStorageKey(cleanUid));
  }

  static Future<bool> isInteractiveLoginRequired({required String uid}) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return true;
    }

    final value = await _storage.read(
      key: _interactiveLoginRequiredStorageKey(cleanUid),
    );

    return value == 'true';
  }

  static Future<String> readLocalSessionId({required String uid}) async {
    return (await _storage.read(key: _sessionStorageKey(uid)))?.trim() ?? '';
  }

  static Future<void> _writeLocalSessionId({
    required String uid,
    required String sessionId,
  }) async {
    await _storage.write(key: _sessionStorageKey(uid), value: sessionId.trim());
  }

  static Future<void> clearLocalSession({required String uid}) async {
    await _storage.delete(key: _sessionStorageKey(uid));
  }

  static Future<void> _revokeSupersededClientRecords(
    SingleDeviceSessionIdentity identity,
  ) async {
    final accountRef = FirebaseDatabase.instance.ref(
      'accounts/${identity.uid}',
    );
    final snapshots = await Future.wait([
      accountRef.child('sessions').get(),
      accountRef.child('fcmTokens').get(),
    ]);

    final sessions = _asStringKeyedMap(snapshots[0].value);
    final fcmTokens = _asStringKeyedMap(snapshots[1].value);
    final tokenUpdates = <String, Object?>{
      'accounts/${identity.uid}/fcmToken': null,
    };

    for (final installationId in fcmTokens.keys) {
      final cleanInstallationId = installationId.trim();

      if (cleanInstallationId.isEmpty ||
          cleanInstallationId == identity.installationId) {
        continue;
      }

      tokenUpdates['accounts/${identity.uid}/fcmTokens/$cleanInstallationId'] =
          null;
    }

    await FirebaseDatabase.instance.ref().update(tokenUpdates);

    for (final entry in sessions.entries) {
      final installationId = entry.key.trim();

      if (installationId.isEmpty || installationId == identity.installationId) {
        continue;
      }

      final session = _asStringKeyedMap(entry.value);

      if (session.isEmpty) {
        continue;
      }

      try {
        await accountRef.child('sessions/$installationId').update({
          'signedIn': false,
          'connected': false,
          'appState': 'signed_out',
          'lastSeenAt': ServerValue.timestamp,
          'signedOutAt': ServerValue.timestamp,
        });
      } catch (error) {
        safeDebugPrint(
          'SUPERSEDED_ACCOUNT_SESSION_MARK_SIGNED_OUT_ERROR: '
          '$installationId $error',
        );
      }
    }
  }

  static void _startActiveSessionHeartbeat(
    SingleDeviceSessionIdentity identity,
  ) {
    _activeSessionHeartbeatTimer?.cancel();
    _activeSessionHeartbeatTimer = Timer.periodic(
      _activeSessionHeartbeatInterval,
      (_) {
        unawaited(
          touchActiveSessionIfCurrent(uid: identity.uid).catchError((
            Object error,
          ) {
            safeDebugPrint('ACTIVE_SESSION_HEARTBEAT_ERROR: $error');
            return false;
          }),
        );
      },
    );
  }

  static DatabaseReference _activeSessionRef(String uid) {
    return FirebaseDatabase.instance.ref('accounts/$uid/activeSession');
  }

  static Map<String, Object?> _activeSessionPayload(
    SingleDeviceSessionIdentity identity,
  ) {
    return {
      'installationId': identity.installationId,
      'sessionId': identity.sessionId,
      'platform': platformName(),
      'activatedAt': ServerValue.timestamp,
      'lastSeenAt': ServerValue.timestamp,
    };
  }

  static SingleDeviceSessionIdentity? _activeSessionFromValue(
    Object? value, {
    required String uid,
  }) {
    final map = _asStringKeyedMap(value);
    final installationId = map['installationId']?.toString().trim() ?? '';
    final sessionId = map['sessionId']?.toString().trim() ?? '';

    if (installationId.isEmpty || !_isValidSessionId(sessionId)) {
      return null;
    }

    return SingleDeviceSessionIdentity(
      uid: uid,
      installationId: installationId,
      sessionId: sessionId,
    );
  }

  static bool _belongsToAnotherInstallation(
    Object? value, {
    required String installationId,
  }) {
    final map = _asStringKeyedMap(value);
    final activeInstallationId = map['installationId']?.toString().trim() ?? '';

    return activeInstallationId.isNotEmpty &&
        activeInstallationId != installationId;
  }

  static Map<String, dynamic> _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return <String, dynamic>{};
  }

  static String _sessionStorageKey(String uid) {
    return MaiYenIdentifiers.activeSessionStorageKey(uid);
  }

  static String _interactiveLoginRequiredStorageKey(String uid) {
    return MaiYenIdentifiers.interactiveLoginRequiredStorageKey(uid);
  }

  static String _generateSessionId() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));

    return bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool _isValidSessionId(String value) {
    return RegExp(r'^[A-Fa-f0-9]{32,128}$').hasMatch(value.trim());
  }
}
