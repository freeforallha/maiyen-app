import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../helpers/firebase_paths.dart';
import '../localization/app_language_controller.dart';
import 'installation_id_service.dart';
import 'notification_service.dart';
import 'platform/ios/ios_notification_config.dart';
import 'single_device_session_service.dart';
import 'package:maiyen_app/helpers/debug_log.dart';

class FCMService {
  static bool _foregroundListening = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String _activeUid = '';
  static Future<void>? _setupInFlight;
  static String _setupInFlightUid = '';

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

  static Future<bool> _saveToken({
    required String uid,
    required String token,
  }) async {
    final cleanUid = uid.trim();
    final cleanToken = token.trim();

    if (cleanUid.isEmpty || cleanToken.isEmpty) {
      return false;
    }

    final identity =
        await SingleDeviceSessionService.currentSessionIdentityIfActive(
          uid: cleanUid,
        );

    if (identity == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await FirebaseDatabase.instance
        .ref(
          FirebasePaths.fcmTokenInstallation(cleanUid, identity.installationId),
        )
        .set({
          'installationId': identity.installationId,
          'sessionId': identity.sessionId,
          'token': cleanToken,
          'platform': _platformName(),
          'updatedAt': now,
        });

    try {
      await FirebaseDatabase.instance
          .ref('accounts/$cleanUid/languageCode')
          .set(appLanguageController.languageCode);
    } catch (_) {
      // Token vẫn hợp lệ; ngôn ngữ sẽ được đồng bộ lại khi người dùng đổi.
    }

    return true;
  }

  static Future<bool> _saveTokenWhenSessionReady({
    required String uid,
    required String token,
  }) async {
    const retryDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ];

    Object? lastError;

    for (final delay in retryDelays) {
      if (_activeUid != uid) {
        return false;
      }

      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      if (_activeUid != uid) {
        return false;
      }

      try {
        if (await _saveToken(uid: uid, token: token)) {
          return true;
        }
      } catch (error) {
        lastError = error;
      }
    }

    safeDebugPrint(
      "PUSH_REGISTRATION_SAVE_RETRY_EXHAUSTED: ${lastError ?? 'session_not_ready'}",
    );
    return false;
  }

  static Future<void> setupFCM({required String uid}) {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return Future<void>.value();
    }

    final existingSetup = _setupInFlight;

    if (existingSetup != null && _setupInFlightUid == cleanUid) {
      return existingSetup;
    }

    late final Future<void> setupFuture;
    setupFuture = _setupFCMInternal(cleanUid).whenComplete(() {
      if (identical(_setupInFlight, setupFuture)) {
        _setupInFlight = null;
        _setupInFlightUid = '';
      }
    });

    _setupInFlight = setupFuture;
    _setupInFlightUid = cleanUid;

    return setupFuture;
  }

  static Future<void> _setupFCMInternal(String cleanUid) async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _activeUid = cleanUid;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: IosNotificationConfig.criticalAlertsEntitlementEnabled,
    );

    if (kDebugMode) {
      safeDebugPrint('PUSH_PERMISSION_STATUS: ${settings.authorizationStatus}');
    }

    if (_activeUid != cleanUid) {
      return;
    }

    final apnsToken = await messaging.getAPNSToken();
    if (kDebugMode && apnsToken != null) {
      safeDebugPrint('PUSH_IOS_REGISTRATION_AVAILABLE');
    }

    if (_activeUid != cleanUid) {
      return;
    }

    final token = await messaging.getToken();
    if (kDebugMode && token != null) {
      safeDebugPrint('PUSH_REGISTRATION_AVAILABLE');
    }

    if (_activeUid != cleanUid) {
      return;
    }

    if (token != null) {
      await _saveTokenWhenSessionReady(
        uid: cleanUid,
        token: token,
      );
    }

    if (_activeUid != cleanUid) {
      return;
    }

    _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
      (newToken) async {
        final targetUid = _activeUid;

        if (targetUid.isEmpty) {
          return;
        }

        if (kDebugMode) {
          safeDebugPrint('PUSH_REGISTRATION_REFRESHED');
        }

        try {
          await _saveTokenWhenSessionReady(
            uid: targetUid,
            token: newToken,
          );
        } catch (error) {
          safeDebugPrint('PUSH_REGISTRATION_REFRESH_SAVE_ERROR: $error');
        }
      },
      onError: (Object error) {
        safeDebugPrint('PUSH_REGISTRATION_REFRESH_STREAM_ERROR: $error');
      },
    );

    final initialMessage = await messaging.getInitialMessage();

    if (_activeUid != cleanUid) {
      return;
    }

    if (initialMessage != null) {
      await _handleOpenedMessage(initialMessage);
    }
  }

  static Future<void> removeCurrentInstallationToken({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    final installationId = await InstallationIdService.getOrCreate();

    await FirebaseDatabase.instance
        .ref(FirebasePaths.fcmTokenInstallation(cleanUid, installationId))
        .remove();

    if (_activeUid == cleanUid) {
      _activeUid = '';
      _setupInFlight = null;
      _setupInFlightUid = '';
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
    }
  }

  static void listenForeground() {
    if (_foregroundListening) return;
    _foregroundListening = true;

    FirebaseMessaging.onMessage.listen((message) async {
      final activeUid = _activeUid;

      if (activeUid.isEmpty) {
        return;
      }

      final type = message.data['type']?.toString() ?? '';

      if (type == 'hub_update_available' || type == 'hub_update') {
        // HomePage đã có banner realtime. Không tạo thêm notification khi app
        // đang foreground để tránh hiển thị trùng.
        return;
      }

      if (type == 'chat') {
        await NotificationService.showChatNotification(data: message.data);
        return;
      }

      if (type == 'sensor_notification') {
        await NotificationService.showSensorNotification(data: message.data);
        return;
      }

      if (type == 'alarm_resolved') {
        await NotificationService.handleAlarmResolved(message.data);
        return;
      }

      if (type == 'emergency_notification' ||
          type == 'alarm_detected' ||
          type == 'alarm') {
        await NotificationService.showPriorityAlarmNotification(
          data: message.data,
        );
        return;
      }

      if (type == 'alarm_siren') {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await NotificationService.openIosAlarmFromData(message.data);
        } else {
          await NotificationService.openAlarmFromData(message.data);
        }
        return;
      }

      final isSchedule = type == 'schedule_notification';

      if (!isSchedule) {
        return;
      }

      final isSafeText = message.data['isSafe']?.toString() ?? 'true';

      final isSafe =
          isSafeText == 'true' || isSafeText == '1' || isSafeText == 'yes';

      final reasonCode = message.data['reason']?.toString() ?? '';

      final reminderItems = message.data['reminderItems']?.toString() ?? '';

      final scheduleBody = message.data['body']?.toString() ?? '';

      final forceShow = message.data['forceShow']?.toString() == 'true';

      final displayReason = forceShow && scheduleBody.isNotEmpty
          ? scheduleBody
          : reasonCode;

      await NotificationService.showSafetyReminder(
        isSafe: isSafe,
        reason: displayReason,
        reminderItemsJson: reminderItems,
        title: message.data['title']?.toString() ?? '',
        forceShow: forceShow,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleOpenedMessage(message, expectedUid: _activeUid);
    });
  }

  static Future<void> _handleOpenedMessage(
    RemoteMessage message, {
    String expectedUid = '',
  }) async {
    final activeUid = expectedUid.trim().isNotEmpty
        ? expectedUid.trim()
        : _activeUid;

    if (activeUid.isEmpty || _activeUid != activeUid) {
      return;
    }

    final type = message.data['type']?.toString() ?? '';

    if (type == 'hub_update_available' || type == 'hub_update') {
      NotificationService.requestOpenHubUpdate(message.data);
      return;
    }

    if (type == 'chat') {
      NotificationService.requestOpenHomeChat(message.data);
      return;
    }

    if (type == 'schedule_notification') {
      await NotificationService.stopReminderNotification();
      return;
    }

    if (type == 'alarm_resolved') {
      await NotificationService.handleAlarmResolved(message.data);
      return;
    }

    if (type == 'emergency_notification' ||
        type == 'alarm_detected' ||
        type == 'alarm') {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await NotificationService.openIosAlarmFromData(message.data);
      } else {
        await NotificationService.handlePriorityAlarmOpened(message.data);
      }
      return;
    }

    if (type == 'alarm_siren') {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await NotificationService.openIosAlarmFromData(message.data);
      } else {
        await NotificationService.openAlarmFromData(message.data);
      }
    }
  }
}
