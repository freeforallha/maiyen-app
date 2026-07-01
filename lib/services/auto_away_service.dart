import 'dart:async';
import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';

import '../firebase_options.dart';

const String _legacyAutoAwayGeofencePrefix =
    'safehome_auto_away';

const String _autoAwayGeofencePrefix =
    'safehome_auto_away_v2';

@pragma('vm:entry-point')
Future<void> safeHomeAutoAwayGeofenceCallback(
    GeofenceCallbackParams params,
    ) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // App Check không được phép làm hỏng callback vị trí nền.
    // Nếu việc kích hoạt thất bại, vẫn tiếp tục ghi trạng thái vị trí.
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
      );
    } catch (error) {
      debugPrint(
        'AUTO_AWAY_BACKGROUND_APP_CHECK_ERROR: $error',
      );
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      try {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (user == null) {
      debugPrint(
        'AUTO_AWAY_GEOFENCE_CALLBACK: no signed-in user',
      );
      return;
    }

    final state = params.event == GeofenceEvent.exit
        ? 'outside'
        : 'inside';

    for (final geofence in params.geofences) {
      final parsed = AutoAwayService.parseGeofenceId(
        geofence.id,
      );

      if (parsed == null || parsed.uid != user.uid) {
        continue;
      }

      await FirebaseDatabase.instance
          .ref(
        'accounts/${user.uid}/homePresence/${parsed.homeId}',
      )
          .update({
        'ownerUid': parsed.ownerUid,
        'homeId': parsed.homeId,
        'state': state,
        'event': params.event.name,
        'source': 'native_geofence',
        'updatedAt': ServerValue.timestamp,
      });
    }
  } catch (error, stackTrace) {
    debugPrint(
      'AUTO_AWAY_GEOFENCE_CALLBACK_ERROR: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AutoAwayService {
  static const MethodChannel _nativeChannel =
  MethodChannel('safehome/native_alarm_permission');

  static bool _initialized = false;
  static bool _initialPresenceSynced = false;

  // Mỗi tài khoản có chữ ký đồng bộ riêng.
  static final Map<String, String> _lastSyncSignatureByUid = {};

  // Chống ghi monitoringCheckedAt lặp lại theo từng tài khoản/nhà.
  // Timestamp chỉ được cập nhật khi trạng thái quyền thực sự đổi.
  static final Map<String, String>
  _lastMonitoringStatusSignatureByHome = {};

  static Future<void>? _syncInProgress;
  static bool _syncRequested = false;
  static bool _pendingForce = false;
  static String _pendingUid = '';
  static Map<String, dynamic> _pendingHomes = {};

  static Future<bool> ensureBackgroundPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always;
  }

  static Future<void> syncForHomes({
    required String uid,
    required Map<String, dynamic> homes,
    bool force = false,
  }) {
    _pendingUid = uid;
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
      final homes = Map<String, dynamic>.from(
        _pendingHomes,
      );
      final force = _pendingForce;

      _pendingForce = false;

      try {
        await _syncForHomesInternal(
          uid: uid,
          homes: homes,
          force: force,
        );
      } catch (error, stackTrace) {
        debugPrint('AUTO_AWAY_SYNC_ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  static Future<void> _syncForHomesInternal({
    required String uid,
    required Map<String, dynamic> homes,
    required bool force,
  }) async {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      return;
    }

    final desired = <String, _DesiredGeofence>{};

    for (final entry in homes.entries) {
      final homeId = entry.key.toString().trim();
      final home = _asMap(entry.value);
      final autoAway = _asMap(home['autoAway']);

      if (homeId.isEmpty || autoAway['enabled'] != true) {
        continue;
      }

      final latitude = _asDouble(autoAway['latitude']);
      final longitude = _asDouble(autoAway['longitude']);
      final radius =
          _asDouble(autoAway['radiusMeters']) ?? 150.0;

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
        radiusMeters:
        radius.clamp(100.0, 1000.0).toDouble(),
      );
    }

    final permission = await Geolocator.checkPermission();

    final monitoringStatus = await _readMonitoringStatus(
      permission: permission,
    );

    final signature = _buildSignature(
      desired,
      permission,
      monitoringStatus,
    );

    final previousSignature =
    _lastSyncSignatureByUid[normalizedUid];

    final signatureChanged =
        signature != previousSignature;

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

    // monitoringEligible chỉ quyết định người này có được dùng
    // để bật Auto Away hay không. Không được vô hiệu hóa geofence,
    // vì sự kiện đi vào nhà vẫn cần dùng để tắt Mode Bảo vệ.

    if (!_initialized) {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
    }

    final registered = await NativeGeofenceManager.instance
        .getRegisteredGeofences();

    final desiredHomeIds = desired.values
        .map((item) => item.homeId)
        .toSet();

    // Chỉ xóa geofence cũ hoặc geofence của nhà không còn dùng.
    // Thành viên thiếu điều kiện vẫn giữ geofence để một sự kiện
    // enter thực tế có thể đưa Mode về Bình thường.
    for (final registeredItem in registered) {
      if (!_isSafeHomeAutoAwayGeofenceId(
        registeredItem.id,
      )) {
        continue;
      }

      final parsed = parseGeofenceId(
        registeredItem.id,
      );

      final belongsToCurrentUser =
          parsed == null || parsed.uid == normalizedUid;

      if (!belongsToCurrentUser) {
        continue;
      }

      final isCurrentDesired =
      desired.containsKey(registeredItem.id);

      final shouldRemove = !isCurrentDesired;

      if (!shouldRemove) {
        continue;
      }

      await NativeGeofenceManager.instance
          .removeGeofenceById(registeredItem.id);

      // Chỉ xóa node presence khi nhà không còn bật Auto Away.
      // Khi chỉ đổi phiên bản geofence hoặc thiếu điều kiện nền,
      // vẫn giữ node để ghi trạng thái unknown và lý do bị chặn.
      if (parsed != null &&
          parsed.uid == normalizedUid &&
          !desiredHomeIds.contains(parsed.homeId)) {
        await FirebaseDatabase.instance
            .ref(
          'accounts/$normalizedUid/homePresence/${parsed.homeId}',
        )
            .remove();
      }
    }

    final registeredById = {
      for (final item in registered) item.id: item,
    };

    var changed = false;

    for (final item in desired.values) {
      final current = registeredById[item.id];

      final matches = current != null &&
          (current.location.latitude - item.latitude).abs() <
              0.000001 &&
          (current.location.longitude - item.longitude).abs() <
              0.000001 &&
          (current.radiusMeters - item.radiusMeters).abs() <
              0.5;

      if (matches) {
        continue;
      }

      if (current != null) {
        await NativeGeofenceManager.instance
            .removeGeofenceById(item.id);
      }

      final geofence = Geofence(
        id: item.id,
        location: Location(
          latitude: item.latitude,
          longitude: item.longitude,
        ),
        radiusMeters: item.radiusMeters,
        triggers: const {
          GeofenceEvent.enter,
          GeofenceEvent.exit,
        },
        iosSettings: const IosGeofenceSettings(
          initialTrigger: true,
        ),
        androidSettings: const AndroidGeofenceSettings(
          initialTriggers: {
            GeofenceEvent.enter,
          },
          notificationResponsiveness:
          Duration(seconds: 15),
        ),
      );

      await NativeGeofenceManager.instance.createGeofence(
        geofence,
        safeHomeAutoAwayGeofenceCallback,
      );

      changed = true;
    }

    if (!_initialPresenceSynced ||
        changed ||
        force ||
        signatureChanged) {
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
  }) async {
    if (desired.isEmpty) {
      return;
    }

    Position? position;

    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (error) {
      debugPrint(
        'AUTO_AWAY_CURRENT_POSITION_ERROR: $error',
      );

      try {
        position = await Geolocator.getLastKnownPosition();

        final timestamp = position?.timestamp;

        if (timestamp == null ||
            DateTime.now().difference(timestamp).abs() >
                const Duration(minutes: 5)) {
          position = null;
        }
      } catch (lastKnownError) {
        debugPrint(
          'AUTO_AWAY_LAST_POSITION_ERROR: $lastKnownError',
        );
        position = null;
      }
    }

    if (position == null) {
      // Không được ghi đè inside/outside hợp lệ thành unknown
      // chỉ vì một lần lấy GPS tạm thời thất bại.
      for (final item in desired) {
        await _markUnknownOnlyIfNoKnownState(
          uid: uid,
          item: item,
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
        state: distance <= item.radiusMeters
            ? 'inside'
            : 'outside',
        event: 'initial_sync',
      );
    }
  }

  static Future<void> _writePresenceIfChanged({
    required String uid,
    required _DesiredGeofence item,
    required String state,
    required String event,
  }) async {
    final reference = FirebaseDatabase.instance.ref(
      'accounts/$uid/homePresence/${item.homeId}',
    );

    final snapshot = await reference.once();
    final current = _asMap(snapshot.snapshot.value);

    final sameIdentity =
        current['ownerUid']?.toString() == item.ownerUid &&
            current['homeId']?.toString() == item.homeId;

    final sameState =
        current['state']?.toString() == state;

    if (sameIdentity && sameState) {
      return;
    }

    await reference.update({
      'ownerUid': item.ownerUid,
      'homeId': item.homeId,
      'state': state,
      'event': event,
      'source': 'native_geofence',
      'updatedAt': ServerValue.timestamp,
    });
  }

  static Future<void> _markUnknownOnlyIfNoKnownState({
    required String uid,
    required _DesiredGeofence item,
  }) async {
    final reference = FirebaseDatabase.instance.ref(
      'accounts/$uid/homePresence/${item.homeId}',
    );

    final snapshot = await reference.once();
    final current = _asMap(snapshot.snapshot.value);
    final currentState =
        current['state']?.toString().trim() ?? '';

    if (currentState == 'inside' ||
        currentState == 'outside') {
      return;
    }

    await reference.update({
      'ownerUid': item.ownerUid,
      'homeId': item.homeId,
      'state': 'unknown',
      'event': 'location_unavailable',
      'source': 'native_geofence',
      'updatedAt': ServerValue.timestamp,
    });
  }

  static Future<void> _writePresence({
    required String uid,
    required _DesiredGeofence item,
    required String state,
    required String event,
  }) {
    return FirebaseDatabase.instance
        .ref(
      'accounts/$uid/homePresence/${item.homeId}',
    )
        .update({
      'ownerUid': item.ownerUid,
      'homeId': item.homeId,
      'state': state,
      'event': event,
      'source': 'native_geofence',
      'updatedAt': ServerValue.timestamp,
    });
  }

  static Future<void> _writeMonitoringStatus({
    required String uid,
    required _DesiredGeofence item,
    required _MonitoringStatus status,
  }) async {
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
    if (_lastMonitoringStatusSignatureByHome[cacheKey] ==
        valueSignature) {
      return;
    }

    // Đặt cache trước khi await để callback Firebase chạy lại
    // trong lúc ghi cũng không tạo vòng lặp mới.
    _lastMonitoringStatusSignatureByHome[cacheKey] =
        valueSignature;

    try {
      await FirebaseDatabase.instance
          .ref(
        'accounts/$uid/homePresence/${item.homeId}',
      )
          .update({
        'ownerUid': item.ownerUid,
        'homeId': item.homeId,
        'monitoringEligible':
        status.monitoringEligible,
        'locationAlwaysGranted':
        status.locationAlwaysGranted,
        'batteryUnrestricted':
        status.batteryUnrestricted,
        'backgroundRestricted':
        status.backgroundRestricted,
        'autoStartConfirmed':
        status.autoStartConfirmed,
        'monitoringBlockingReason':
        status.blockingEvent,
        'monitoringCheckedAt':
        ServerValue.timestamp,
      });
    } catch (_) {
      // Cho phép lần đồng bộ sau thử ghi lại nếu lần này lỗi.
      if (_lastMonitoringStatusSignatureByHome[cacheKey] ==
          valueSignature) {
        _lastMonitoringStatusSignatureByHome.remove(
          cacheKey,
        );
      }

      rethrow;
    }
  }

  static String buildGeofenceId({
    required String uid,
    required String ownerUid,
    required String homeId,
  }) {
    return [
      _autoAwayGeofencePrefix,
      uid,
      ownerUid,
      homeId,
    ].join('|');
  }

  static AutoAwayGeofenceIdentity? parseGeofenceId(
      String rawId,
      ) {
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

    if (uid.isEmpty ||
        ownerUid.isEmpty ||
        homeId.isEmpty) {
      return null;
    }

    return AutoAwayGeofenceIdentity(
      uid: uid,
      ownerUid: ownerUid,
      homeId: homeId,
    );
  }

  static bool _isSafeHomeAutoAwayGeofenceId(
      String id,
      ) {
    return id.startsWith(
      '$_autoAwayGeofencePrefix|',
    ) ||
        id.startsWith(
          '$_legacyAutoAwayGeofencePrefix|',
        );
  }

  static Future<_MonitoringStatus> _readMonitoringStatus({
    required LocationPermission permission,
  }) async {
    final locationAlwaysGranted =
        permission == LocationPermission.always;

    if (defaultTargetPlatform != TargetPlatform.android) {
      return _MonitoringStatus(
        locationAlwaysGranted: locationAlwaysGranted,
        batteryUnrestricted: true,
        backgroundRestricted: false,
        autoStartConfirmed: true,
      );
    }

    var batteryUnrestricted = false;
    var backgroundRestricted = true;
    var autoStartConfirmed = false;

    try {
      batteryUnrestricted =
          await _nativeChannel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
              false;
    } catch (error) {
      debugPrint(
        'AUTO_AWAY_BATTERY_CHECK_ERROR: $error',
      );
    }

    try {
      backgroundRestricted =
          await _nativeChannel.invokeMethod<bool>(
            'isBackgroundRestricted',
          ) ??
              true;
    } catch (error) {
      debugPrint(
        'AUTO_AWAY_BACKGROUND_CHECK_ERROR: $error',
      );
    }

    try {
      autoStartConfirmed =
          await _nativeChannel.invokeMethod<bool>(
            'isBootReceiverConfirmed',
          ) ??
              false;
    } catch (error) {
      debugPrint(
        'AUTO_AWAY_AUTOSTART_CHECK_ERROR: $error',
      );
    }

    return _MonitoringStatus(
      locationAlwaysGranted: locationAlwaysGranted,
      batteryUnrestricted: batteryUnrestricted,
      backgroundRestricted: backgroundRestricted,
      autoStartConfirmed: autoStartConfirmed,
    );
  }

  static String _buildSignature(
      Map<String, _DesiredGeofence> desired,
      LocationPermission permission,
      _MonitoringStatus monitoringStatus,
      ) {
    final items = desired.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

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

  bool get monitoringEligible =>
      locationAlwaysGranted &&
          batteryUnrestricted &&
          !backgroundRestricted &&
          autoStartConfirmed;

  String get blockingEvent {
    if (!locationAlwaysGranted) {
      return 'permission_required';
    }

    if (!batteryUnrestricted) {
      return 'battery_optimization_required';
    }

    if (backgroundRestricted) {
      return 'background_restricted';
    }

    if (!autoStartConfirmed) {
      return 'auto_start_required';
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
