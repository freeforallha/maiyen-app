import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../../config/maiyen_identifiers.dart';
import '../../../firebase_options.dart';
import '../../../helpers/debug_log.dart';
import '../../../localization/app_language_controller.dart';
import '../../../localization/app_strings.dart';
import '../../account_session_service.dart';
import '../../auto_away_service.dart';
import '../../single_device_session_service.dart';

const String _autoAwayTaskDataKey =
    MaiYenIdentifiers.autoAwayForegroundTaskConfigStorageKey;
const int _autoAwayForegroundServiceId = 884201;

@pragma('vm:entry-point')
void maiYenAutoAwayForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_MaiYenAutoAwayTaskHandler());
}

class AndroidAutoAwayForegroundTaskService {
  const AndroidAutoAwayForegroundTaskService._();

  static AppStrings get _strings =>
      AppStrings.fromLocale(appLanguageController.locale);

  static bool _initialized = false;
  static Future<bool>? _recoveryInFlight;

  static bool get _isAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static void initCommunicationPort() {
    if (!_isAndroid) {
      return;
    }

    FlutterForegroundTask.initCommunicationPort();
  }

  static Future<void> activateAppCheck() async {
    if (!_isAndroid) {
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
    );
  }

  static void initialize() {
    if (!_isAndroid || _initialized) {
      return;
    }

    final strings = _strings;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: MaiYenIdentifiers.androidAutoAwayLocationChannelId,
        channelName: strings.updatingLocationNotificationTitle(),
        channelDescription: strings.updatingLocationChannelDescription(),
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

  static Future<void> refreshNotificationLanguage() async {
    if (!_isAndroid) {
      return;
    }

    if (!await FlutterForegroundTask.isRunningService) {
      return;
    }

    final strings = _strings;

    await FlutterForegroundTask.updateService(
      notificationTitle: strings.updatingLocationNotificationTitle(),
      notificationText: strings.updatingLocationNotificationBody(),
    );
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

    final taskHomes = _buildTaskHomes(uid: normalizedUid, homes: homes);

    if (taskHomes.isEmpty) {
      await stop();
      return;
    }

    final taskConfig = jsonEncode({'uid': normalizedUid, 'homes': taskHomes});

    final previousTaskConfig = await FlutterForegroundTask.getData<String>(
      key: _autoAwayTaskDataKey,
    );

    final configChanged = previousTaskConfig != taskConfig;

    if (configChanged) {
      await FlutterForegroundTask.saveData(
        key: _autoAwayTaskDataKey,
        value: taskConfig,
      );
    }

    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    if (!locationServiceEnabled || permission != LocationPermission.always) {
      return;
    }

    if (await FlutterForegroundTask.isRunningService) {
      if (configChanged) {
        FlutterForegroundTask.sendDataToTask(const <String, dynamic>{
          'action': 'refresh_now',
        });
      }

      return;
    }

    await _startService();
  }

  /// Recovers monitoring from the last valid configuration stored on-device.
  ///
  /// This is safe to call from app startup/resume and from a high-priority FCM
  /// background isolate. It both repairs a stopped foreground service and runs
  /// one immediate presence confirmation, so stale members do not have to wait
  /// for the next five-minute service tick.
  static Future<bool> recoverFromStoredConfig({
    required String event,
  }) {
    if (!_isAndroid) {
      return Future<bool>.value(false);
    }

    final activeRecovery = _recoveryInFlight;

    if (activeRecovery != null) {
      return activeRecovery;
    }

    late final Future<bool> recovery;
    recovery = _recoverFromStoredConfigInternal(event: event).whenComplete(() {
      if (identical(_recoveryInFlight, recovery)) {
        _recoveryInFlight = null;
      }
    });

    _recoveryInFlight = recovery;
    return recovery;
  }

  static Future<bool> _recoverFromStoredConfigInternal({
    required String event,
  }) async {
    initialize();

    final config = await _readStoredTaskConfig();

    if (config == null) {
      return false;
    }

    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    if (!locationServiceEnabled || permission != LocationPermission.always) {
      return false;
    }

    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await _startService();
      }
    } catch (error) {
      // Even when an OEM temporarily rejects the service restart, the direct
      // heartbeat below can still refresh Firebase during this wake window.
      safeDebugPrint('AUTO_AWAY_SERVICE_RECOVERY_START_ERROR: $error');
    }

    return _StoredAutoAwayHeartbeatRunner.run(
      event: event,
      prefetchedConfig: config,
    );
  }

  static Future<void> _startService() async {
    final strings = _strings;

    await FlutterForegroundTask.startService(
      serviceId: _autoAwayForegroundServiceId,
      serviceTypes: const <ForegroundServiceTypes>[
        ForegroundServiceTypes.location,
      ],
      notificationTitle: strings.updatingLocationNotificationTitle(),
      notificationText: strings.updatingLocationNotificationBody(),
      callback: maiYenAutoAwayForegroundTaskCallback,
    );
  }

  static Future<_StoredAutoAwayTaskConfig?> _readStoredTaskConfig() async {
    final rawConfig = await FlutterForegroundTask.getData<String>(
      key: _autoAwayTaskDataKey,
    );

    if (rawConfig == null || rawConfig.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawConfig);

      if (decoded is! Map) {
        return null;
      }

      final config = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final uid = config['uid']?.toString().trim() ?? '';
      final homes = _asMap(config['homes']);

      if (uid.isEmpty || homes.isEmpty) {
        return null;
      }

      return _StoredAutoAwayTaskConfig(uid: uid, homes: homes);
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_STORED_CONFIG_READ_ERROR: $error');
      return null;
    }
  }

  static Future<void> stop() async {
    if (!_isAndroid) {
      return;
    }

    await FlutterForegroundTask.removeData(key: _autoAwayTaskDataKey);

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

      if (!_isSelectedAutoAwayParticipant(autoAway, uid)) {
        continue;
      }

      final latitude = _asDouble(autoAway['latitude']);
      final longitude = _asDouble(autoAway['longitude']);
      final radiusMeters = _asDouble(autoAway['radiusMeters']) ?? 150.0;

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
          'radiusMeters': radiusMeters.clamp(100.0, 1000.0).toDouble(),
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
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return <String, dynamic>{};
  }

  static bool _isSelectedAutoAwayParticipant(
    Map<String, dynamic> autoAway,
    String uid,
  ) {
    final participantUids = _asMap(autoAway['participantUids']);

    if (participantUids.isEmpty) {
      return true;
    }

    return participantUids[uid] == true;
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}

class _StoredAutoAwayTaskConfig {
  const _StoredAutoAwayTaskConfig({
    required this.uid,
    required this.homes,
  });

  final String uid;
  final Map<String, dynamic> homes;
}

class _StoredAutoAwayHeartbeatRunner {
  static bool _heartbeatRunning = false;
  static bool _firebaseReady = false;

  static Future<bool> run({
    required String event,
    _StoredAutoAwayTaskConfig? prefetchedConfig,
  }) async {
    if (_heartbeatRunning) {
      return false;
    }

    _heartbeatRunning = true;

    try {
      final config =
          prefetchedConfig ??
          await AndroidAutoAwayForegroundTaskService._readStoredTaskConfig();

      if (config == null) {
        return false;
      }

      await _ensureFirebaseReady();

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        try {
          user = await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 5),
          );
        } catch (_) {}
      }

      if (user == null || user.uid != config.uid) {
        return false;
      }

      final sessionIdentity =
          await SingleDeviceSessionService.currentSessionIdentityIfActive(
            uid: config.uid,
          );

      if (sessionIdentity == null) {
        return false;
      }

      await AccountSessionService.touchFromBackground(
        uid: config.uid,
        sessionId: sessionIdentity.sessionId,
      );

      final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      if (!locationServiceEnabled || permission != LocationPermission.always) {
        return false;
      }

      await AutoAwayService.refreshPresenceForHomes(
        uid: config.uid,
        homes: config.homes,
        event: event,
      );

      return true;
    } catch (error) {
      safeDebugPrint('AUTO_AWAY_RECOVERY_HEARTBEAT_ERROR: $error');
      return false;
    } finally {
      _heartbeatRunning = false;
    }
  }

  static Future<void> _ensureFirebaseReady() async {
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
      safeDebugPrint('AUTO_AWAY_RECOVERY_APP_CHECK_ERROR: $error');
    }

    _firebaseReady = true;
  }
}

class _MaiYenAutoAwayTaskHandler extends TaskHandler {
  final List<Timer> _recoveryTimers = <Timer>[];

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();

    await _StoredAutoAwayHeartbeatRunner.run(
      event: 'foreground_task_started_${starter.name}',
    );

    // On reboot the first callback can arrive before Firebase Auth and the
    // credential-protected user store are fully available. Retry after unlock
    // windows instead of waiting for the normal five-minute cycle.
    _scheduleRecoveryRetry(
      delay: const Duration(seconds: 30),
      event: 'foreground_task_recovery_30s',
    );
    _scheduleRecoveryRetry(
      delay: const Duration(minutes: 2),
      event: 'foreground_task_recovery_2m',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(
      _StoredAutoAwayHeartbeatRunner.run(
        event: 'foreground_task_heartbeat',
      ),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['action'] == 'refresh_now') {
      unawaited(
        _StoredAutoAwayHeartbeatRunner.run(
          event: 'foreground_task_config_changed',
        ),
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    for (final timer in _recoveryTimers) {
      timer.cancel();
    }
    _recoveryTimers.clear();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  void _scheduleRecoveryRetry({
    required Duration delay,
    required String event,
  }) {
    _recoveryTimers.add(
      Timer(delay, () {
        unawaited(_StoredAutoAwayHeartbeatRunner.run(event: event));
      }),
    );
  }
}
