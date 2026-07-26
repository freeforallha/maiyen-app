import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'account_session_service.dart';
import 'platform/platform_bootstrap_service.dart';
import 'platform/platform_auto_away_system_service.dart';
import 'single_device_session_service.dart';
import 'package:maiyen_app/helpers/debug_log.dart';
import '../config/legacy_identifiers.dart';

const String _legacyAutoAwayGeofencePrefix =
    MaiYenLegacyIdentifiers.legacyAutoAwayGeofencePrefix;

const String _autoAwayGeofencePrefix =
    MaiYenLegacyIdentifiers.autoAwayGeofencePrefixV2;

const String _pendingPresenceEventsStorageKey =
    MaiYenLegacyIdentifiers.pendingPresenceEventsStorageKey;

const int _pendingPresenceEventsLimit = 100;

@pragma('vm:entry-point')
Future<void> maiYenAutoAwayGeofenceCallback(
  GeofenceCallbackParams params,
) async {
  DartPluginRegistrant.ensureInitialized();

  final occurredAt = DateTime.now().millisecondsSinceEpoch;
  final state = params.event == GeofenceEvent.exit ? 'outside' : 'inside';
  final queuedUids = <String>{};

  // Ghi xuống máy trước khi khởi tạo Firebase/App Check.
  // Nếu hệ điều hành chỉ cho callback chạy trong thời gian ngắn,
  // sự kiện vẫn được giữ lại để gửi ở lần chạy sau.
  try {
    for (final geofence in params.geofences) {
      final parsed = AutoAwayService.parseGeofenceId(geofence.id);

      if (parsed == null) {
        continue;
      }

      await AutoAwayService.enqueueNativePresenceEvent(
        uid: parsed.uid,
        ownerUid: parsed.ownerUid,
        homeId: parsed.homeId,
        state: state,
        event: params.event.name,
        occurredAt: occurredAt,
      );

      queuedUids.add(parsed.uid);
    }
  } catch (error) {
    safeDebugPrint('AUTO_AWAY_LOCAL_EVENT_QUEUE_ERROR: $error');
  }

  if (queuedUids.isEmpty) {
    return;
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // App Check không được phép làm hỏng callback vị trí nền.
    try {
      await PlatformBootstrapService.activateAppCheck();
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_BACKGROUND_APP_CHECK_ERROR: $error');
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      try {
        user = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {}
    }

    if (user == null || !queuedUids.contains(user.uid)) {
      // Event vẫn nằm trong queue để gửi khi đúng tài khoản hoạt động.
      safeDebugPrint('AUTO_AWAY_GEOFENCE_CALLBACK: no matching signed-in user');
      return;
    }

    final sessionIdentity =
        await SingleDeviceSessionService.currentSessionIdentityIfActive(
          uid: user.uid,
        );

    if (sessionIdentity == null) {
      safeDebugPrint('AUTO_AWAY_GEOFENCE_CALLBACK: inactive session');
      return;
    }

    try {
      await AccountSessionService.touchFromBackground(
        uid: user.uid,
        sessionId: sessionIdentity.sessionId,
      );
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_BACKGROUND_SESSION_TOUCH_ERROR: $error');
    }

    try {
      await AutoAwayService.flushPendingPresenceEvents(uid: user.uid);
    } catch (error) {
      // Không xóa queue nếu upload lỗi.
      safeDebugPrint('AUTO_AWAY_BACKGROUND_EVENT_FLUSH_ERROR: $error');
    }
  } catch (error) {
    // Firebase/Auth lỗi không làm mất event đã lưu ở bước đầu.
    safeDebugPrint('AUTO_AWAY_GEOFENCE_CALLBACK_ERROR: $error');
  }
}

/// Entry point cũ được giữ lại để geofence đã đăng ký từ bản MaiYen
/// vẫn gọi được callback sau khi ứng dụng được nâng cấp.
@pragma('vm:entry-point')
Future<void> safeHomeAutoAwayGeofenceCallback(
  GeofenceCallbackParams params,
) {
  return maiYenAutoAwayGeofenceCallback(params);
}

class AutoAwayService {
  static bool _initialized = false;
  static bool _initialPresenceSynced = false;

  // Mỗi tài khoản có chữ ký đồng bộ riêng.
  static final Map<String, String> _lastSyncSignatureByUid = {};

  // Chống ghi monitoringCheckedAt lặp lại theo từng tài khoản/nhà.
  // Timestamp chỉ được cập nhật khi trạng thái quyền thực sự đổi.
  static final Map<String, String> _lastMonitoringStatusSignatureByHome = {};

  // Trong lúc đăng xuất, chặn mọi listener/timer cũ đăng ký lại
  // geofence hoặc ghi lại trạng thái inside/outside.
  static final Set<String> _loggingOutUids = <String>{};

  static Future<void>? _syncInProgress;
  static Future<void>? _presenceRefreshInProgress;
  static final Map<String, Future<void>> _pendingPresenceFlushByUid =
      <String, Future<void>>{};
  static bool _syncRequested = false;
  static bool _pendingForce = false;
  static String _pendingUid = '';
  static Map<String, dynamic> _pendingHomes = {};

  static Future<SingleDeviceSessionIdentity?> _sessionIdentityForWrite(
    String uid,
  ) async {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty || _loggingOutUids.contains(normalizedUid)) {
      return null;
    }

    try {
      return await SingleDeviceSessionService.currentSessionIdentityIfActive(
        uid: normalizedUid,
      );
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_SESSION_CHECK_ERROR: $error');
      return null;
    }
  }

  static Future<bool> ensureBackgroundPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final permission = await _ensureBackgroundLocationPermissionForIOS();
      return permission == LocationPermission.always;
    }

    var permission = await _readLocationPermission();

    if (permission == LocationPermission.denied) {
      permission = await _requestLocationPermission(
        fallbackPermission: permission,
      );
    }

    return permission == LocationPermission.always;
  }

  static bool _hasLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static bool _hasBackgroundLocationPermission(LocationPermission permission) {
    return permission == LocationPermission.always;
  }

  static Future<LocationPermission> _readLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_LOCATION_PERMISSION_CHECK_ERROR: $error');
      return LocationPermission.denied;
    }
  }

  static Future<LocationPermission> _requestLocationPermission({
    required LocationPermission fallbackPermission,
  }) async {
    try {
      return await Geolocator.requestPermission();
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_LOCATION_PERMISSION_REQUEST_ERROR: $error');
      return fallbackPermission;
    }
  }

  static Future<LocationPermission>
  _ensureForegroundLocationPermissionForIOS() async {
    var permission = await _readLocationPermission();

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return permission;
    }

    if (permission == LocationPermission.denied) {
      permission = await _requestLocationPermission(
        fallbackPermission: permission,
      );
    }

    return permission;
  }

  static Future<LocationPermission>
  _ensureBackgroundLocationPermissionForIOS() async {
    var permission = await _readLocationPermission();

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return permission;
    }

    // geolocator exposes one request API on iOS. With the Always usage strings
    // present in Info.plist, the native side requests the background-capable
    // permission needed by geofencing when iOS still allows a prompt.
    if (permission != LocationPermission.always) {
      permission = await _requestLocationPermission(
        fallbackPermission: permission,
      );
    }

    return permission;
  }

  static Future<List<Map<String, dynamic>>> _readPendingPresenceEvents() async {
    final preferences = await SharedPreferences.getInstance();

    // Background isolate và foreground isolate có cache riêng.
    await preferences.reload();

    final rawItems =
        preferences.getStringList(_pendingPresenceEventsStorageKey) ??
        const <String>[];

    final result = <Map<String, dynamic>>[];

    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);

        if (decoded is Map) {
          result.add(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      } catch (_) {
        // Bỏ qua một item hỏng, không làm mất các event còn lại.
      }
    }

    return result;
  }

  static Future<void> _writePendingPresenceEvents(
    List<Map<String, dynamic>> events,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();

    final normalized =
        events.where((item) {
          return (item['id']?.toString().trim() ?? '').isNotEmpty;
        }).toList()..sort((a, b) {
          final aTime = _asInt(a['occurredAt']) ?? 0;
          final bTime = _asInt(b['occurredAt']) ?? 0;
          return aTime.compareTo(bTime);
        });

    final limited = normalized.length > _pendingPresenceEventsLimit
        ? normalized.sublist(normalized.length - _pendingPresenceEventsLimit)
        : normalized;

    await preferences.setStringList(
      _pendingPresenceEventsStorageKey,
      limited.map(jsonEncode).toList(),
    );
  }

  static Future<void> enqueueNativePresenceEvent({
    required String uid,
    required String ownerUid,
    required String homeId,
    required String state,
    required String event,
    required int occurredAt,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedOwnerUid = ownerUid.trim();
    final normalizedHomeId = homeId.trim();

    if (normalizedUid.isEmpty ||
        normalizedOwnerUid.isEmpty ||
        normalizedHomeId.isEmpty) {
      return;
    }

    final eventId = [
      normalizedUid,
      normalizedHomeId,
      occurredAt,
      event,
      DateTime.now().microsecondsSinceEpoch,
    ].join('|');

    final pending = await _readPendingPresenceEvents();

    if (pending.any((item) => item['id']?.toString() == eventId)) {
      return;
    }

    pending.add({
      'id': eventId,
      'uid': normalizedUid,
      'ownerUid': normalizedOwnerUid,
      'homeId': normalizedHomeId,
      'state': state,
      'event': event,
      'source': 'native_geofence',
      'occurredAt': occurredAt,
    });

    await _writePendingPresenceEvents(pending);
  }

  static Future<void> _removePendingPresenceEventsForUid(String uid) async {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      return;
    }

    final pending = await _readPendingPresenceEvents();

    pending.removeWhere((item) => item['uid']?.toString() == normalizedUid);

    await _writePendingPresenceEvents(pending);
  }

  static Future<void> flushPendingPresenceEvents({required String uid}) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty || _loggingOutUids.contains(normalizedUid)) {
      return Future<void>.value();
    }

    final running = _pendingPresenceFlushByUid[normalizedUid];

    if (running != null) {
      return running;
    }

    final future = _flushPendingPresenceEventsInternal(normalizedUid);

    _pendingPresenceFlushByUid[normalizedUid] = future;

    return future.whenComplete(() {
      if (_pendingPresenceFlushByUid[normalizedUid] == future) {
        _pendingPresenceFlushByUid.remove(normalizedUid);
      }
    });
  }

  static Future<void> _flushPendingPresenceEventsInternal(String uid) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.uid != uid) {
      return;
    }

    if (await _sessionIdentityForWrite(uid) == null) {
      return;
    }

    final lastSignInAt =
        currentUser.metadata.lastSignInTime?.millisecondsSinceEpoch ?? 0;

    final pending = await _readPendingPresenceEvents();
    final items =
        pending.where((item) => item['uid']?.toString() == uid).toList()
          ..sort((a, b) {
            final aTime = _asInt(a['occurredAt']) ?? 0;
            final bTime = _asInt(b['occurredAt']) ?? 0;
            return aTime.compareTo(bTime);
          });

    if (items.isEmpty) {
      return;
    }

    final uploadedIds = <String>{};

    for (final item in items) {
      final eventId = item['id']?.toString().trim() ?? '';
      final ownerUid = item['ownerUid']?.toString().trim() ?? '';
      final homeId = item['homeId']?.toString().trim() ?? '';
      final state = item['state']?.toString().trim() ?? '';
      final event = item['event']?.toString().trim() ?? '';
      final occurredAt = _asInt(item['occurredAt']) ?? 0;

      // Không phát lại event thuộc phiên đăng nhập cũ sau khi user
      // đã logout rồi login lại. Cho phép sai lệch đồng hồ nhỏ 10 giây.
      if (lastSignInAt > 0 &&
          occurredAt + const Duration(seconds: 10).inMilliseconds <
              lastSignInAt) {
        uploadedIds.add(eventId);
        continue;
      }

      if (eventId.isEmpty ||
          ownerUid.isEmpty ||
          homeId.isEmpty ||
          occurredAt <= 0 ||
          (state != 'inside' && state != 'outside')) {
        uploadedIds.add(eventId);
        continue;
      }

      try {
        await _applyPresenceConfirmation(
          uid: uid,
          ownerUid: ownerUid,
          homeId: homeId,
          state: state,
          event: event,
          source: 'native_geofence',
          eventId: eventId,
          occurredAt: occurredAt,
          extraData: {'lastNativeEventAt': occurredAt},
        );

        uploadedIds.add(eventId);
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_PENDING_EVENT_UPLOAD_ERROR: $error');

        // Thường là mất mạng. Dừng để giữ nguyên thứ tự event.
        break;
      }
    }

    if (uploadedIds.isEmpty) {
      return;
    }

    // Reload trước khi xóa để không làm mất event vừa được callback
    // khác thêm vào trong lúc upload.
    final latestPending = await _readPendingPresenceEvents();

    latestPending.removeWhere(
      (item) => uploadedIds.contains(item['id']?.toString() ?? ''),
    );

    await _writePendingPresenceEvents(latestPending);
  }

  static Future<void> _applyPresenceConfirmation({
    required String uid,
    required String ownerUid,
    required String homeId,
    required String state,
    required String event,
    required String source,
    required String eventId,
    required int occurredAt,
    Map<String, Object?> extraData = const <String, Object?>{},
  }) async {
    final identity = await _sessionIdentityForWrite(uid);

    if (identity == null) {
      throw StateError('Current session is not active');
    }

    final reference = FirebaseDatabase.instance.ref(
      'accounts/$uid/homePresence/$homeId',
    );

    var supersededByNewerEvent = false;

    final result = await reference
        .runTransaction((currentValue) {
          final current = _asMap(currentValue);
          final currentOccurredAt =
              _asInt(current['lastEventOccurredAt']) ??
              _asInt(current['lastConfirmedAt']) ??
              0;
          final currentEventId = current['lastEventId']?.toString() ?? '';

          final olderThanCurrent =
              currentOccurredAt > occurredAt ||
              (currentOccurredAt == occurredAt &&
                  currentEventId.compareTo(eventId) >= 0);

          if (olderThanCurrent) {
            supersededByNewerEvent = true;
            return Transaction.abort();
          }

          final previousState = current['state']?.toString().trim() ?? '';

          final next = <String, Object?>{
            ...current,
            'ownerUid': ownerUid,
            'homeId': homeId,
            'installationId': identity.installationId,
            'sessionId': identity.sessionId,
            'state': state,
            'event': event,
            'source': source,
            'updatedAt': ServerValue.timestamp,
            'lastConfirmedAt': occurredAt,
            'lastEventOccurredAt': occurredAt,
            'lastEventId': eventId,
            'monitoringHealth': 'active',
            'monitoringHealthReason': null,
            ...extraData,
          };

          if (previousState != state ||
              _asInt(current['lastTransitionAt']) == null) {
            next['lastTransitionAt'] = occurredAt;
          }

          return Transaction.success(next);
        }, applyLocally: false)
        .timeout(const Duration(seconds: 20));

    if (!result.committed && !supersededByNewerEvent) {
      throw StateError('Presence transaction was not committed');
    }
  }

  static void activateForSignedInUser(String uid) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      return;
    }

    _loggingOutUids.remove(normalizedUid);
    _lastSyncSignatureByUid.remove(normalizedUid);
    _lastMonitoringStatusSignatureByHome.removeWhere(
      (key, _) => key.startsWith('$normalizedUid|'),
    );
    _initialPresenceSynced = false;

    unawaited(
      flushPendingPresenceEvents(uid: normalizedUid).catchError((Object error) {
        safeDebugPrint('AUTO_AWAY_LOGIN_PENDING_EVENT_FLUSH_ERROR: $error');
      }),
    );
  }

  static Future<void> prepareForLogout({
    required String uid,
    bool writePresence = true,
  }) async {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      return;
    }

    _loggingOutUids.add(normalizedUid);
    final logoutOccurredAt = DateTime.now().millisecondsSinceEpoch;
    SingleDeviceSessionIdentity? sessionIdentity;

    if (writePresence) {
      try {
        sessionIdentity =
            await SingleDeviceSessionService.currentSessionIdentityIfActive(
              uid: normalizedUid,
            );
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_LOGOUT_SESSION_CHECK_ERROR: $error');
      }
    }

    // Không được phát lại sự kiện vị trí cũ sau lần đăng nhập tiếp theo.
    try {
      await _removePendingPresenceEventsForUid(normalizedUid);
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_LOGOUT_CLEAR_PENDING_EVENTS_ERROR: $error');
    }

    // Hủy yêu cầu đồng bộ đang chờ của đúng tài khoản này.
    if (_pendingUid == normalizedUid) {
      _pendingHomes = <String, dynamic>{};
      _pendingForce = false;
      _syncRequested = false;
    }

    // Đợi lượt đồng bộ đang chạy kết thúc, sau đó mới dọn geofence.
    final runningSync = _syncInProgress;

    if (runningSync != null) {
      try {
        await runningSync.timeout(const Duration(seconds: 12));
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_LOGOUT_WAIT_SYNC_ERROR: $error');
      }
    }

    final identitiesByHome = <String, AutoAwayGeofenceIdentity>{};
    final currentPresenceByHome = <String, Map<String, dynamic>>{};
    Object? firstError;

    if (writePresence && sessionIdentity != null) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('accounts/$normalizedUid/homePresence')
            .get()
            .timeout(const Duration(seconds: 12));

        final presenceMap = _asMap(snapshot.value);

        for (final entry in presenceMap.entries) {
          final homeId = entry.key.toString().trim();
          final presence = _asMap(entry.value);
          final ownerUid = presence['ownerUid']?.toString().trim() ?? '';

          if (homeId.isEmpty || ownerUid.isEmpty) {
            continue;
          }

          currentPresenceByHome[homeId] = presence;
          identitiesByHome[homeId] = AutoAwayGeofenceIdentity(
            uid: normalizedUid,
            ownerUid: ownerUid,
            homeId: homeId,
          );
        }
      } catch (error) {
        firstError ??= error;
        safeDebugPrint('AUTO_AWAY_LOGOUT_READ_PRESENCE_ERROR: $error');
      }
    }

    List<dynamic> registered = <dynamic>[];

    try {
      if (!_initialized) {
        await NativeGeofenceManager.instance.initialize();
        _initialized = true;
      }

      registered = await NativeGeofenceManager.instance
          .getRegisteredGeofences();

      for (final registeredItem in registered) {
        final parsed = parseGeofenceId(registeredItem.id.toString());

        if (parsed == null || parsed.uid != normalizedUid) {
          continue;
        }

        identitiesByHome[parsed.homeId] = parsed;
      }
    } catch (error) {
      firstError ??= error;
      safeDebugPrint('AUTO_AWAY_LOGOUT_READ_GEOFENCE_ERROR: $error');
    }

    if (writePresence &&
        sessionIdentity != null &&
        identitiesByHome.isNotEmpty) {
      final updates = <String, Object?>{};

      for (final identity in identitiesByHome.values) {
        final basePath =
            'accounts/$normalizedUid/homePresence/${identity.homeId}';
        final current =
            currentPresenceByHome[identity.homeId] ?? const <String, dynamic>{};

        updates['$basePath/ownerUid'] = identity.ownerUid;
        updates['$basePath/homeId'] = identity.homeId;
        updates['$basePath/installationId'] = sessionIdentity.installationId;
        updates['$basePath/sessionId'] = sessionIdentity.sessionId;
        updates['$basePath/state'] = 'unknown';
        updates['$basePath/event'] = 'signed_out';
        updates['$basePath/source'] = 'native_geofence';
        updates['$basePath/updatedAt'] = ServerValue.timestamp;
        updates['$basePath/lastConfirmedAt'] = logoutOccurredAt;
        updates['$basePath/lastEventOccurredAt'] = logoutOccurredAt;
        updates['$basePath/lastEventId'] =
            'signed_out|$normalizedUid|${identity.homeId}|$logoutOccurredAt';
        updates['$basePath/monitoringHealth'] = 'unavailable';
        updates['$basePath/monitoringHealthReason'] = 'signed_out';
        updates['$basePath/monitoringEligible'] = false;
        updates['$basePath/monitoringAvailable'] = false;
        updates['$basePath/monitoringWarnings'] = null;
        updates['$basePath/monitoringWarningReason'] = null;
        updates['$basePath/locationAlwaysGranted'] =
            current['locationAlwaysGranted'] == true;
        updates['$basePath/batteryUnrestricted'] =
            current['batteryUnrestricted'] == true;
        updates['$basePath/backgroundRestricted'] =
            current['backgroundRestricted'] == true;
        updates['$basePath/autoStartConfirmed'] =
            current['autoStartConfirmed'] == true;
        updates['$basePath/monitoringBlockingReason'] = 'signed_out';
        updates['$basePath/monitoringCheckedAt'] = ServerValue.timestamp;
      }

      try {
        await FirebaseDatabase.instance
            .ref()
            .update(updates)
            .timeout(const Duration(seconds: 15));
      } catch (error) {
        firstError ??= error;
        safeDebugPrint('AUTO_AWAY_LOGOUT_WRITE_PRESENCE_ERROR: $error');
      }
    }

    // Xóa geofence sau khi đã cố gắng ghi signed_out lên Firebase.
    for (final registeredItem in registered) {
      final id = registeredItem.id.toString();
      final parsed = parseGeofenceId(id);

      if (parsed == null || parsed.uid != normalizedUid) {
        continue;
      }

      try {
        await NativeGeofenceManager.instance.removeGeofenceById(id);
      } catch (error) {
        firstError ??= error;
        safeDebugPrint('AUTO_AWAY_LOGOUT_REMOVE_GEOFENCE_ERROR: $error');
      }
    }

    _lastSyncSignatureByUid.remove(normalizedUid);
    _lastMonitoringStatusSignatureByHome.removeWhere(
      (key, _) => key.startsWith('$normalizedUid|'),
    );
    _initialPresenceSynced = false;

    if (firstError != null) {
      throw firstError;
    }
  }

  /// Đo vị trí trực tiếp khi app đang foreground.
  /// Không đăng ký lại geofence và không phụ thuộc cấu hình native.
  static Future<void> refreshPresenceForHomes({
    required String uid,
    required Map<String, dynamic> homes,
    Position? position,
    String event = 'foreground_check',
  }) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty ||
        homes.isEmpty ||
        _loggingOutUids.contains(normalizedUid)) {
      return Future<void>.value();
    }

    final running = _presenceRefreshInProgress;

    if (running != null) {
      return running;
    }

    final desired = <_DesiredGeofence>[];

    for (final entry in homes.entries) {
      final homeId = entry.key.toString().trim();
      final home = _asMap(entry.value);
      final autoAway = _asMap(home['autoAway']);

      if (homeId.isEmpty || autoAway['enabled'] != true) {
        continue;
      }

      if (!_isSelectedAutoAwayParticipant(autoAway, normalizedUid)) {
        continue;
      }

      final latitude = _asDouble(autoAway['latitude']);
      final longitude = _asDouble(autoAway['longitude']);
      final radius = _asDouble(autoAway['radiusMeters']) ?? 150.0;

      if (latitude == null || longitude == null) {
        continue;
      }

      final ownerUid = home['_shared'] == true
          ? home['_ownerUid']?.toString().trim() ?? ''
          : normalizedUid;

      if (ownerUid.isEmpty) {
        continue;
      }

      desired.add(
        _DesiredGeofence(
          id: buildGeofenceId(
            uid: normalizedUid,
            ownerUid: ownerUid,
            homeId: homeId,
          ),
          ownerUid: ownerUid,
          homeId: homeId,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radius.clamp(100.0, 1000.0).toDouble(),
        ),
      );
    }

    if (desired.isEmpty) {
      return Future<void>.value();
    }

    final future = () async {
      if (await _sessionIdentityForWrite(normalizedUid) == null) {
        return;
      }

      await flushPendingPresenceEvents(uid: normalizedUid);

      await _syncInitialPresence(
        uid: normalizedUid,
        desired: desired,
        event: event,
        providedPosition: position,
      );
    }();

    _presenceRefreshInProgress = future;

    return future.whenComplete(() {
      _presenceRefreshInProgress = null;
    });
  }

  static Future<void> syncForHomes({
    required String uid,
    required Map<String, dynamic> homes,
    bool force = false,
  }) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty || _loggingOutUids.contains(normalizedUid)) {
      return Future<void>.value();
    }

    _pendingUid = normalizedUid;
    _pendingHomes = Map<String, dynamic>.from(homes);
    _pendingForce = _pendingForce || force;
    _syncRequested = true;

    final running = _syncInProgress;

    if (running != null) {
      return running;
    }

    final future = _runSyncLoop();
    _syncInProgress = future;

    return future.whenComplete(() {
      _syncInProgress = null;
    });
  }

  static Future<void> _runSyncLoop() async {
    while (_syncRequested) {
      _syncRequested = false;

      final uid = _pendingUid;
      final homes = Map<String, dynamic>.from(_pendingHomes);
      final force = _pendingForce;

      _pendingForce = false;

      try {
        await _syncForHomesInternal(uid: uid, homes: homes, force: force);
      } catch (error) {
        safeDebugPrint('AUTO_AWAY_SYNC_ERROR: $error');
      }
    }
  }

  static Future<void> _syncForHomesInternal({
    required String uid,
    required Map<String, dynamic> homes,
    required bool force,
  }) async {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty || _loggingOutUids.contains(normalizedUid)) {
      return;
    }

    if (await _sessionIdentityForWrite(normalizedUid) == null) {
      return;
    }

    await flushPendingPresenceEvents(uid: normalizedUid);

    final desired = <String, _DesiredGeofence>{};

    for (final entry in homes.entries) {
      final homeId = entry.key.toString().trim();
      final home = _asMap(entry.value);
      final autoAway = _asMap(home['autoAway']);

      if (homeId.isEmpty || autoAway['enabled'] != true) {
        continue;
      }

      if (!_isSelectedAutoAwayParticipant(autoAway, normalizedUid)) {
        continue;
      }

      final latitude = _asDouble(autoAway['latitude']);
      final longitude = _asDouble(autoAway['longitude']);
      final radius = _asDouble(autoAway['radiusMeters']) ?? 150.0;

      if (latitude == null || longitude == null) {
        continue;
      }

      final ownerUid = home['_shared'] == true
          ? home['_ownerUid']?.toString().trim() ?? ''
          : normalizedUid;

      if (ownerUid.isEmpty) {
        continue;
      }

      final geofenceId = buildGeofenceId(
        uid: normalizedUid,
        ownerUid: ownerUid,
        homeId: homeId,
      );

      desired[geofenceId] = _DesiredGeofence(
        id: geofenceId,
        ownerUid: ownerUid,
        homeId: homeId,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius.clamp(100.0, 1000.0).toDouble(),
      );
    }

    final permission = desired.isEmpty
        ? await _readLocationPermission()
        : await _ensureBackgroundLocationPermissionForIOS();

    final monitoringStatus = await _readMonitoringStatus(
      permission: permission,
    );

    final signature = _buildSignature(desired, permission, monitoringStatus);

    final previousSignature = _lastSyncSignatureByUid[normalizedUid];

    final signatureChanged = signature != previousSignature;

    // Chặn vòng lặp:
    // ghi monitoringCheckedAt -> listener Firebase chạy lại
    // -> syncForHomes chạy lại -> tiếp tục ghi Firebase.
    //
    // Chỉ đồng bộ khi quyền/cấu hình/trạng thái giám sát
    // thực sự thay đổi hoặc khi caller chủ động force.
    if (!force && !signatureChanged) {
      return;
    }

    // Chỉ ghi trạng thái khi có thay đổi thực sự.
    for (final item in desired.values) {
      await _writeMonitoringStatus(
        uid: normalizedUid,
        item: item,
        status: monitoringStatus,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS &&
        !_hasBackgroundLocationPermission(permission)) {
      if (_hasLocationPermission(permission)) {
        await _syncInitialPresence(
          uid: normalizedUid,
          desired: desired.values.toList(),
        );
        _initialPresenceSynced = true;
      } else {
        for (final item in desired.values) {
          await _writeLocationCheckFailure(
            uid: normalizedUid,
            item: item,
            result: 'location_permission_denied',
            markStateUnknown: true,
          );
        }
      }

      _lastSyncSignatureByUid[normalizedUid] = signature;
      return;
    }

    // monitoringEligible chỉ quyết định người này có được dùng
    // để bật Auto Away hay không. Không được vô hiệu hóa geofence,
    // vì sự kiện đi vào nhà vẫn cần dùng để tắt Mode Bảo vệ.

    if (!_initialized) {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
    }

    final registered = await NativeGeofenceManager.instance
        .getRegisteredGeofences();

    final desiredHomeIds = desired.values.map((item) => item.homeId).toSet();

    // Chỉ xóa geofence cũ hoặc geofence của nhà không còn dùng.
    // Thành viên thiếu điều kiện vẫn giữ geofence để một sự kiện
    // enter thực tế có thể đưa Mode về Bình thường.
    for (final registeredItem in registered) {
      if (!_isMaiYenAutoAwayGeofenceId(registeredItem.id)) {
        continue;
      }

      final parsed = parseGeofenceId(registeredItem.id);

      final belongsToCurrentUser =
          parsed == null || parsed.uid == normalizedUid;

      if (!belongsToCurrentUser) {
        continue;
      }

      final isCurrentDesired = desired.containsKey(registeredItem.id);

      final shouldRemove = !isCurrentDesired;

      if (!shouldRemove) {
        continue;
      }

      await NativeGeofenceManager.instance.removeGeofenceById(
        registeredItem.id,
      );

      // Chỉ xóa node presence khi nhà không còn bật Auto Away.
      // Khi chỉ đổi phiên bản geofence hoặc thiếu điều kiện nền,
      // vẫn giữ node để ghi trạng thái unknown và lý do bị chặn.
      if (parsed != null &&
          parsed.uid == normalizedUid &&
          !desiredHomeIds.contains(parsed.homeId)) {
        await FirebaseDatabase.instance
            .ref('accounts/$normalizedUid/homePresence/${parsed.homeId}')
            .remove();
      }
    }

    final registeredById = {for (final item in registered) item.id: item};

    var changed = false;

    for (final item in desired.values) {
      final current = registeredById[item.id];

      final matches =
          current != null &&
          (current.location.latitude - item.latitude).abs() < 0.000001 &&
          (current.location.longitude - item.longitude).abs() < 0.000001 &&
          (current.radiusMeters - item.radiusMeters).abs() < 0.5;

      if (matches) {
        continue;
      }

      if (current != null) {
        await NativeGeofenceManager.instance.removeGeofenceById(item.id);
      }

      final geofence = Geofence(
        id: item.id,
        location: Location(latitude: item.latitude, longitude: item.longitude),
        radiusMeters: item.radiusMeters,
        triggers: const {GeofenceEvent.enter, GeofenceEvent.exit},
        iosSettings: const IosGeofenceSettings(initialTrigger: true),
        androidSettings: const AndroidGeofenceSettings(
          initialTriggers: {GeofenceEvent.enter},
          notificationResponsiveness: Duration(seconds: 15),
        ),
      );

      await NativeGeofenceManager.instance.createGeofence(
        geofence,
        maiYenAutoAwayGeofenceCallback,
      );

      changed = true;
    }

    if (!_initialPresenceSynced || changed || force || signatureChanged) {
      await _syncInitialPresence(
        uid: normalizedUid,
        desired: desired.values.toList(),
      );

      _initialPresenceSynced = true;
    }

    // Chỉ lưu signature sau khi toàn bộ quá trình thành công.
    // Nếu native plugin lỗi, lần sau hệ thống vẫn thử lại.
    _lastSyncSignatureByUid[normalizedUid] = signature;
  }

  static Future<void> _syncInitialPresence({
    required String uid,
    required List<_DesiredGeofence> desired,
    String event = 'initial_sync',
    Position? providedPosition,
  }) async {
    if (desired.isEmpty) {
      return;
    }

    if (await _sessionIdentityForWrite(uid) == null) {
      return;
    }

    final permission = await _ensureForegroundLocationPermissionForIOS();

    if (!_hasLocationPermission(permission)) {
      for (final item in desired) {
        await _writeLocationCheckFailure(
          uid: uid,
          item: item,
          result: 'location_permission_denied',
          locationPermission: permission,
          markStateUnknown: true,
        );
      }

      return;
    }

    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!locationServiceEnabled) {
      for (final item in desired) {
        await _writeLocationCheckFailure(
          uid: uid,
          item: item,
          result: 'location_service_disabled',
          locationPermission: permission,
          locationServiceEnabled: locationServiceEnabled,
        );
      }

      return;
    }

    Position? position = providedPosition;
    var usedLastKnownPosition = false;
    Object? currentPositionError;

    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (error) {
        currentPositionError = error;
        safeDebugPrint('AUTO_AWAY_CURRENT_POSITION_ERROR: $error');

        try {
          position = await Geolocator.getLastKnownPosition();

          final timestamp = position?.timestamp;

          if (timestamp == null ||
              DateTime.now().difference(timestamp).abs() >
                  const Duration(minutes: 5)) {
            position = null;
          } else {
            usedLastKnownPosition = true;
          }
        } catch (lastKnownError) {
          safeDebugPrint('AUTO_AWAY_LAST_POSITION_ERROR: $lastKnownError');
          position = null;
        }
      }
    }

    if (position == null) {
      // Giữ trạng thái hợp lệ trước đó, nhưng ghi rõ lần kiểm tra lỗi.
      for (final item in desired) {
        await _writeLocationCheckFailure(
          uid: uid,
          item: item,
          result: 'position_unavailable',
          locationPermission: permission,
          locationError: currentPositionError,
          locationServiceEnabled: locationServiceEnabled,
        );
      }

      return;
    }

    for (final item in desired) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        item.latitude,
        item.longitude,
      );

      await _writePresenceIfChanged(
        uid: uid,
        item: item,
        state: distance <= item.radiusMeters ? 'inside' : 'outside',
        event: event,
        distanceMeters: distance,
        accuracyMeters: position.accuracy,
        positionAt: position.timestamp,
        usedLastKnownPosition: usedLastKnownPosition,
        locationPermission: permission,
        locationError: currentPositionError,
        locationServiceEnabled: locationServiceEnabled,
      );
    }
  }

  static Future<void> _writePresenceIfChanged({
    required String uid,
    required _DesiredGeofence item,
    required String state,
    required String event,
    required double distanceMeters,
    required double accuracyMeters,
    required DateTime positionAt,
    required bool usedLastKnownPosition,
    LocationPermission? locationPermission,
    Object? locationError,
    bool? locationServiceEnabled,
  }) async {
    final occurredAt = DateTime.now().millisecondsSinceEpoch;
    final eventId = [
      uid,
      item.homeId,
      occurredAt,
      event,
      'foreground',
    ].join('|');

    // Đây là lớp xác minh chủ động từ app hoặc Android
    // foreground location service. Native geofence vẫn xử lý chuyển vùng.
    await _applyPresenceConfirmation(
      uid: uid,
      ownerUid: item.ownerUid,
      homeId: item.homeId,
      state: state,
      event: event,
      source: 'foreground_location_check',
      eventId: eventId,
      occurredAt: occurredAt,
      extraData: {
        'lastLocationCheckAt': occurredAt,
        'lastLocationCheckResult': usedLastKnownPosition
            ? 'last_known_position'
            : 'current_position',
        'lastDistanceMeters': double.parse(distanceMeters.toStringAsFixed(1)),
        'lastAccuracyMeters': double.parse(accuracyMeters.toStringAsFixed(1)),
        'lastPositionAt': positionAt.millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> _writeLocationCheckFailure({
    required String uid,
    required _DesiredGeofence item,
    required String result,
    LocationPermission? locationPermission,
    Object? locationError,
    bool? locationServiceEnabled,
    bool markStateUnknown = false,
  }) async {
    final identity = await _sessionIdentityForWrite(uid);

    if (identity == null) {
      return;
    }

    final updates = <String, Object?>{
      'ownerUid': item.ownerUid,
      'homeId': item.homeId,
      'installationId': identity.installationId,
      'sessionId': identity.sessionId,
      'lastLocationCheckAt': ServerValue.timestamp,
      'lastLocationCheckResult': result,
    };

    if (markStateUnknown) {
      updates.addAll({
        'state': 'unknown',
        'event': result,
        'source': 'foreground_location_check',
        'updatedAt': ServerValue.timestamp,
      });
    }

    await FirebaseDatabase.instance
        .ref('accounts/$uid/homePresence/${item.homeId}')
        .update(updates);
  }

  static Future<void> _writeMonitoringStatus({
    required String uid,
    required _DesiredGeofence item,
    required _MonitoringStatus status,
  }) async {
    final identity = await _sessionIdentityForWrite(uid);

    if (identity == null) {
      return;
    }

    final cacheKey = '$uid|${item.homeId}';

    final valueSignature = [
      item.ownerUid,
      item.homeId,
      status.signature,
      status.monitoringEligible,
      status.blockingEvent,
    ].join('|');

    // Dù syncForHomes được listener gọi lại nhiều lần,
    // không ghi Firebase nếu các giá trị quyền không thay đổi.
    if (_lastMonitoringStatusSignatureByHome[cacheKey] == valueSignature) {
      return;
    }

    // Đặt cache trước khi await để callback Firebase chạy lại
    // trong lúc ghi cũng không tạo vòng lặp mới.
    _lastMonitoringStatusSignatureByHome[cacheKey] = valueSignature;

    try {
      await FirebaseDatabase.instance
          .ref('accounts/$uid/homePresence/${item.homeId}')
          .update({
            'ownerUid': item.ownerUid,
            'homeId': item.homeId,
            'installationId': identity.installationId,
            'sessionId': identity.sessionId,
            // Chỉ quyền vị trí nền là điều kiện bắt buộc.
            // Các giới hạn pin/chạy nền/tự khởi động chỉ tạo cảnh báo.
            'monitoringEligible': status.monitoringEligible,
            'monitoringAvailable': status.monitoringEligible,
            'monitoringWarnings': status.warningFlags.isEmpty
                ? null
                : status.warningFlags,
            'monitoringWarningReason': status.primaryWarning.isEmpty
                ? null
                : status.primaryWarning,
            'locationAlwaysGranted': status.locationAlwaysGranted,
            'batteryUnrestricted': status.batteryUnrestricted,
            'backgroundRestricted': status.backgroundRestricted,
            'autoStartConfirmed': status.autoStartConfirmed,
            'monitoringBlockingReason': status.blockingEvent,
            'monitoringHealth': status.monitoringEligible
                ? 'active'
                : 'unavailable',
            'monitoringHealthReason': status.monitoringEligible
                ? null
                : status.blockingEvent,
            'monitoringCheckedAt': ServerValue.timestamp,
          });
    } catch (_) {
      // Cho phép lần đồng bộ sau thử ghi lại nếu lần này lỗi.
      if (_lastMonitoringStatusSignatureByHome[cacheKey] == valueSignature) {
        _lastMonitoringStatusSignatureByHome.remove(cacheKey);
      }

      rethrow;
    }
  }

  static String buildGeofenceId({
    required String uid,
    required String ownerUid,
    required String homeId,
  }) {
    return [_autoAwayGeofencePrefix, uid, ownerUid, homeId].join('|');
  }

  static AutoAwayGeofenceIdentity? parseGeofenceId(String rawId) {
    final parts = rawId.split('|');

    if (parts.length != 4) {
      return null;
    }

    final prefix = parts.first;

    if (prefix != _autoAwayGeofencePrefix &&
        prefix != _legacyAutoAwayGeofencePrefix) {
      return null;
    }

    final uid = parts[1].trim();
    final ownerUid = parts[2].trim();
    final homeId = parts[3].trim();

    if (uid.isEmpty || ownerUid.isEmpty || homeId.isEmpty) {
      return null;
    }

    return AutoAwayGeofenceIdentity(
      uid: uid,
      ownerUid: ownerUid,
      homeId: homeId,
    );
  }

  static bool _isMaiYenAutoAwayGeofenceId(String id) {
    return id.startsWith('$_autoAwayGeofencePrefix|') ||
        id.startsWith('$_legacyAutoAwayGeofencePrefix|');
  }

  static Future<_MonitoringStatus> _readMonitoringStatus({
    required LocationPermission permission,
  }) async {
    final locationAlwaysGranted = permission == LocationPermission.always;
    final systemStatus = await PlatformAutoAwaySystemService.readSystemStatus();

    return _MonitoringStatus(
      locationAlwaysGranted: locationAlwaysGranted,
      batteryUnrestricted: systemStatus.batteryUnrestricted,
      backgroundRestricted: systemStatus.backgroundRestricted,
      autoStartConfirmed: systemStatus.autoStartConfirmed,
    );
  }

  static String _buildSignature(
    Map<String, _DesiredGeofence> desired,
    LocationPermission permission,
    _MonitoringStatus monitoringStatus,
  ) {
    final items = desired.values.toList()..sort((a, b) => a.id.compareTo(b.id));

    return [
      permission.name,
      monitoringStatus.signature,
      for (final item in items)
        '${item.id}:${item.latitude}:${item.longitude}:${item.radiusMeters}',
    ].join(';');
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }


  static bool _isSelectedAutoAwayParticipant(
    Map<String, dynamic> autoAway,
    String uid,
  ) {
    final participantUids = _asMap(autoAway['participantUids']);

    // Nhà cũ chưa có participantUids tiếp tục dùng toàn bộ thành viên.
    if (participantUids.isEmpty) {
      return true;
    }

    return participantUids[uid] == true;
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }

    if (raw is num) {
      return raw.toInt();
    }

    return int.tryParse(raw?.toString() ?? '');
  }

  static double? _asDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }

    return double.tryParse(raw?.toString() ?? '');
  }
}

class _MonitoringStatus {
  const _MonitoringStatus({
    required this.locationAlwaysGranted,
    required this.batteryUnrestricted,
    required this.backgroundRestricted,
    required this.autoStartConfirmed,
  });

  final bool locationAlwaysGranted;
  final bool batteryUnrestricted;
  final bool backgroundRestricted;
  final bool autoStartConfirmed;

  // Phổ quát Android/iOS:
  // Chỉ quyền vị trí nền là điều kiện bắt buộc để tham gia Auto Away.
  // Pin, giới hạn chạy nền và tự khởi động khác nhau giữa từng hãng,
  // nên chỉ được dùng để cảnh báo người dùng.
  bool get monitoringEligible => locationAlwaysGranted;

  Map<String, bool> get warningFlags => {
    if (!batteryUnrestricted) 'battery_optimization_recommended': true,
    if (backgroundRestricted) 'background_activity_restricted': true,
    if (!autoStartConfirmed) 'auto_start_recommended': true,
  };

  String get primaryWarning {
    if (!batteryUnrestricted) {
      return 'battery_optimization_recommended';
    }

    if (backgroundRestricted) {
      return 'background_activity_restricted';
    }

    if (!autoStartConfirmed) {
      return 'auto_start_recommended';
    }

    return '';
  }

  String get blockingEvent {
    if (!locationAlwaysGranted) {
      return 'permission_required';
    }

    return '';
  }

  String get signature => [
    locationAlwaysGranted,
    batteryUnrestricted,
    backgroundRestricted,
    autoStartConfirmed,
  ].join(':');
}

class AutoAwayGeofenceIdentity {
  const AutoAwayGeofenceIdentity({
    required this.uid,
    required this.ownerUid,
    required this.homeId,
  });

  final String uid;
  final String ownerUid;
  final String homeId;
}

class _DesiredGeofence {
  const _DesiredGeofence({
    required this.id,
    required this.ownerUid,
    required this.homeId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final String id;
  final String ownerUid;
  final String homeId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}
