import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../firebase_options.dart';
import 'auto_away_service.dart';

const String _autoAwayTaskDataKey =
    'safehome_auto_away_foreground_task_config_v1';
const int _autoAwayForegroundServiceId = 884201;

@pragma('vm:entry-point')
void safeHomeAutoAwayForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(
    _SafeHomeAutoAwayTaskHandler(),
  );
}

class AutoAwayForegroundTaskService {
  const AutoAwayForegroundTaskService._();

  static bool _initialized = false;

  static bool get _isAndroid {
    return !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android;
  }

  static void initialize() {
    if (!_isAndroid || _initialized) {
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions:
      AndroidNotificationOptions(
        channelId: 'safehome_auto_away_location_v1',
        channelName: 'SafeHome cập nhật vị trí',
        channelDescription:
        'Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: true,
        stopWithTask: false,
      ),
    );

    _initialized = true;
  }

  static Future<void> syncForHomes({
    required String uid,
    required Map<String, dynamic> homes,
  }) async {
    if (!_isAndroid) {
      return;
    }

    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      await stop();
      return;
    }

    initialize();

    final taskHomes = _buildTaskHomes(
      uid: normalizedUid,
      homes: homes,
    );

    if (taskHomes.isEmpty) {
      await stop();
      return;
    }

    final taskConfig = jsonEncode({
      'uid': normalizedUid,
      'homes': taskHomes,
    });

    final previousTaskConfig =
    await FlutterForegroundTask.getData<String>(
      key: _autoAwayTaskDataKey,
    );

    final configChanged =
        previousTaskConfig != taskConfig;

    if (configChanged) {
      await FlutterForegroundTask.saveData(
        key: _autoAwayTaskDataKey,
        value: taskConfig,
      );
    }

    final locationServiceEnabled =
    await Geolocator.isLocationServiceEnabled();

    final permission =
    await Geolocator.checkPermission();

    if (!locationServiceEnabled ||
        permission != LocationPermission.always) {
      return;
    }

    if (await FlutterForegroundTask.isRunningService) {
      // Chỉ kiểm tra ngay khi bật/tắt Auto Away,
      // đổi tọa độ hoặc thay đổi danh sách nhà.
      // Các cập nhật hubStatus không còn kích hoạt GPS.
      if (configChanged) {
        FlutterForegroundTask.sendDataToTask(
          const <String, dynamic>{
            'action': 'refresh_now',
          },
        );
      }

      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: _autoAwayForegroundServiceId,
      serviceTypes: const <ForegroundServiceTypes>[
        ForegroundServiceTypes.location,
      ],
      notificationTitle: 'SafeHome đang cập nhật vị trí',
      notificationText:
      'Đang theo dõi để tự động bật Chế độ Bảo vệ.',
      callback: safeHomeAutoAwayForegroundTaskCallback,
    );
  }

  static Future<void> stop() async {
    if (!_isAndroid) {
      return;
    }

    await FlutterForegroundTask.removeData(
      key: _autoAwayTaskDataKey,
    );

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static Map<String, dynamic> _buildTaskHomes({
    required String uid,
    required Map<String, dynamic> homes,
  }) {
    final result = <String, dynamic>{};

    for (final entry in homes.entries) {
      final homeId = entry.key.toString().trim();
      final home = _asMap(entry.value);
      final autoAway = _asMap(home['autoAway']);

      if (homeId.isEmpty || autoAway['enabled'] != true) {
        continue;
      }

      final latitude = _asDouble(autoAway['latitude']);
      final longitude = _asDouble(autoAway['longitude']);
      final radiusMeters =
          _asDouble(autoAway['radiusMeters']) ?? 150.0;

      if (latitude == null || longitude == null) {
        continue;
      }

      final shared = home['_shared'] == true;
      final ownerUid = shared
          ? home['_ownerUid']?.toString().trim() ?? ''
          : uid;

      if (ownerUid.isEmpty) {
        continue;
      }

      result[homeId] = <String, dynamic>{
        '_shared': shared,
        '_ownerUid': ownerUid,
        'autoAway': <String, dynamic>{
          'enabled': true,
          'latitude': latitude,
          'longitude': longitude,
          'radiusMeters':
          radiusMeters.clamp(100.0, 1000.0).toDouble(),
        },
      };
    }

    return result;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map(
            (key, item) => MapEntry(key.toString(), item),
      );
    }

    return <String, dynamic>{};
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}

class _SafeHomeAutoAwayTaskHandler extends TaskHandler {
  bool _heartbeatRunning = false;
  bool _firebaseReady = false;

  @override
  Future<void> onStart(
      DateTime timestamp,
      TaskStarter starter,
      ) async {
    DartPluginRegistrant.ensureInitialized();
    await _runHeartbeat('foreground_task_started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(
      _runHeartbeat('foreground_task_heartbeat'),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['action'] == 'refresh_now') {
      unawaited(
        _runHeartbeat('foreground_task_config_changed'),
      );
    }
  }

  @override
  Future<void> onDestroy(
      DateTime timestamp,
      bool isTimeout,
      ) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  Future<void> _runHeartbeat(String event) async {
    if (_heartbeatRunning) {
      return;
    }

    _heartbeatRunning = true;

    try {
      final rawConfig =
      await FlutterForegroundTask.getData<String>(
        key: _autoAwayTaskDataKey,
      );

      if (rawConfig == null || rawConfig.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(rawConfig);

      if (decoded is! Map) {
        return;
      }

      final config = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
      );
      final uid = config['uid']?.toString().trim() ?? '';
      final homes = _asMap(config['homes']);

      if (uid.isEmpty || homes.isEmpty) {
        return;
      }

      await _ensureFirebaseReady();

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        try {
          user = await FirebaseAuth.instance
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }

      if (user == null || user.uid != uid) {
        return;
      }

      final locationServiceEnabled =
      await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      if (!locationServiceEnabled ||
          permission != LocationPermission.always) {
        return;
      }

      // Dùng lại logic hiện có: lấy vị trí hiện tại và tự fallback
      // sang last-known position còn mới nếu GPS tạm thời timeout.
      await AutoAwayService.refreshPresenceForHomes(
        uid: uid,
        homes: homes,
        event: event,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'AUTO_AWAY_FOREGROUND_TASK_HEARTBEAT_ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _heartbeatRunning = false;
    }
  }

  Future<void> _ensureFirebaseReady() async {
    if (_firebaseReady) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
      );
    } catch (error) {
      debugPrint(
        'AUTO_AWAY_FOREGROUND_TASK_APP_CHECK_ERROR: $error',
      );
    }

    _firebaseReady = true;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map(
            (key, item) => MapEntry(key.toString(), item),
      );
    }

    return <String, dynamic>{};
  }
}
