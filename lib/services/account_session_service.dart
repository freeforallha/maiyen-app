import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'installation_id_service.dart';
import 'package:safehome_app/helpers/debug_log.dart';
class AccountSessionService {
  const AccountSessionService._();

  static const Duration _heartbeatInterval =
  Duration(minutes: 5);

  static String _activeUid = '';
  static String _installationId = '';
  static bool _loggingOut = false;
  static bool _databaseConnected = false;
  static AppLifecycleState _lifecycleState =
      AppLifecycleState.resumed;

  static DatabaseReference? _sessionRef;
  static Timer? _heartbeatTimer;
  static StreamSubscription<DatabaseEvent>?
  _connectionSubscription;
  static Future<void>? _activationInProgress;

  static String _platformName() {
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

  static String _appStateName() {
    switch (_lifecycleState) {
      case AppLifecycleState.resumed:
        return 'foreground';
      case AppLifecycleState.inactive:
        return 'inactive';
      case AppLifecycleState.hidden:
        return 'background';
      case AppLifecycleState.paused:
        return 'background';
      case AppLifecycleState.detached:
        return 'detached';
    }
  }

  static Future<void> activate({
    required String uid,
  }) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Future<void>.value();
    }

    final running = _activationInProgress;

    if (running != null && _activeUid == cleanUid) {
      return running;
    }

    final future = _activateInternal(cleanUid);
    _activationInProgress = future;

    return future.whenComplete(() {
      if (identical(_activationInProgress, future)) {
        _activationInProgress = null;
      }
    });
  }

  static Future<void> _activateInternal(
      String cleanUid,
      ) async {
    if (_activeUid.isNotEmpty &&
        _activeUid != cleanUid) {
      await deactivateLocal();
    }

    _activeUid = cleanUid;
    _loggingOut = false;
    _installationId =
    await InstallationIdService.getOrCreate();

    final ref = FirebaseDatabase.instance.ref(
      'accounts/$cleanUid/sessions/$_installationId',
    );

    _sessionRef = ref;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _connectionSubscription = FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen(
          (event) {
        final connected = event.snapshot.value == true;
        _databaseConnected = connected;

        if (!connected ||
            _loggingOut ||
            _activeUid != cleanUid) {
          return;
        }

        unawaited(
          _markConnected(
            uid: cleanUid,
            ref: ref,
          ).catchError((Object error) {
            safeDebugPrint(
              'ACCOUNT_SESSION_CONNECTED_ERROR: $error',
            );
          }),
        );
      },
      onError: (Object error) {
        safeDebugPrint(
          'ACCOUNT_SESSION_CONNECTION_LISTENER_ERROR: $error',
        );
      },
    );

    await _writeSignedInState(
      uid: cleanUid,
      ref: ref,
      includeLoginTime: true,
    );

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
          (_) {
        if (_loggingOut || _activeUid != cleanUid) {
          return;
        }

        unawaited(
          _writeSignedInState(
            uid: cleanUid,
            ref: ref,
          ).catchError((Object error) {
            safeDebugPrint(
              'ACCOUNT_SESSION_HEARTBEAT_ERROR: $error',
            );
          }),
        );
      },
    );
  }

  static Future<void> _markConnected({
    required String uid,
    required DatabaseReference ref,
  }) async {
    if (_loggingOut || _activeUid != uid) {
      return;
    }

    // Đăng ký onDisconnect trước khi ghi connected=true để nếu
    // app bị tắt hoặc mất mạng đột ngột, signedIn vẫn giữ true
    // nhưng connected sẽ phản ánh đúng là thiết bị đã mất kết nối.
    await ref.onDisconnect().update({
      'installationId': _installationId,
      'signedIn': true,
      'connected': false,
      'appState': 'background',
      'platform': _platformName(),
      'lastSeenAt': ServerValue.timestamp,
    });

    _databaseConnected = true;

    await _writeSignedInState(
      uid: uid,
      ref: ref,
      connected: true,
    );
  }

  static Future<void> _writeSignedInState({
    required String uid,
    required DatabaseReference ref,
    bool? connected,
    bool includeLoginTime = false,
  }) async {
    if (_loggingOut || _activeUid != uid) {
      return;
    }

    final updates = <String, Object?>{
      'installationId': _installationId,
      'signedIn': true,
      'appState': _appStateName(),
      'platform': _platformName(),
      'lastSeenAt': ServerValue.timestamp,
      'signedOutAt': null,
    };

    updates['connected'] =
        connected ?? _databaseConnected;

    if (includeLoginTime) {
      updates['lastLoginAt'] = ServerValue.timestamp;
    }

    await ref.update(updates);
  }

  static Future<void> updateLifecycle(
      AppLifecycleState state,
      ) async {
    _lifecycleState = state;

    final uid = _activeUid;
    final ref = _sessionRef;

    if (uid.isEmpty || ref == null || _loggingOut) {
      return;
    }

    try {
      await _writeSignedInState(
        uid: uid,
        ref: ref,
      );
    } catch (error) {
      safeDebugPrint(
        'ACCOUNT_SESSION_LIFECYCLE_ERROR: $error',
      );
    }
  }

  static Future<void> markSignedOut({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    _loggingOut = true;
    _databaseConnected = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final installationId = _installationId.isNotEmpty
        ? _installationId
        : await InstallationIdService.getOrCreate();

    final ref = FirebaseDatabase.instance.ref(
      'accounts/$cleanUid/sessions/$installationId',
    );

    try {
      await ref.onDisconnect().cancel();
    } catch (error) {
      safeDebugPrint(
        'ACCOUNT_SESSION_CANCEL_DISCONNECT_ERROR: $error',
      );
    }

    await ref.update({
      'installationId': installationId,
      'signedIn': false,
      'connected': false,
      'appState': 'signed_out',
      'platform': _platformName(),
      'lastSeenAt': ServerValue.timestamp,
      'signedOutAt': ServerValue.timestamp,
    });

    if (_activeUid == cleanUid) {
      _activeUid = '';
      _installationId = '';
      _sessionRef = null;
    }
  }

  static Future<void> deactivateLocal() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _activeUid = '';
    _installationId = '';
    _sessionRef = null;
    _loggingOut = false;
    _databaseConnected = false;
  }

  @pragma('vm:entry-point')
  static Future<void> touchFromBackground({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    final installationId =
    await InstallationIdService.getOrCreate();

    await FirebaseDatabase.instance
        .ref(
      'accounts/$cleanUid/sessions/$installationId',
    )
        .update({
      'installationId': installationId,
      'signedIn': true,
      'connected': false,
      'appState': 'background_event',
      'platform': _platformName(),
      'lastSeenAt': ServerValue.timestamp,
      'signedOutAt': null,
    });
  }
}
