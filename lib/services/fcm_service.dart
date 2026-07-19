import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../helpers/firebase_paths.dart';
import '../localization/app_language_controller.dart';
import 'installation_id_service.dart';
import 'notification_service.dart';
import 'platform/ios/ios_notification_config.dart';
import 'single_device_session_service.dart';
import 'package:safehome_app/helpers/debug_log.dart';
class FCMService {
  static bool _foregroundListening = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String _activeUid = '';

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

  static Future<void> _saveToken({
    required String uid,
    required String token,
  }) async {
    final cleanUid = uid.trim();
    final cleanToken = token.trim();

    if (cleanUid.isEmpty || cleanToken.isEmpty) {
      return;
    }

    final identity =
    await SingleDeviceSessionService.currentSessionIdentityIfActive(
      uid: cleanUid,
    );

    if (identity == null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await FirebaseDatabase.instance.ref(
      FirebasePaths.fcmTokenInstallation(
        cleanUid,
        identity.installationId,
      ),
    ).set({
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
  }

  static Future<void> setupFCM({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _activeUid = cleanUid;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert:
          IosNotificationConfig.criticalAlertsEntitlementEnabled,
    );

    if (kDebugMode) {
      safeDebugPrint('PUSH_PERMISSION_STATUS: ${settings.authorizationStatus}');
    }

    final apnsToken = await messaging.getAPNSToken();
    if (kDebugMode && apnsToken != null) {
      safeDebugPrint('PUSH_IOS_REGISTRATION_AVAILABLE');
    }

    final token = await messaging.getToken();
    if (kDebugMode && token != null) {
      safeDebugPrint('PUSH_REGISTRATION_AVAILABLE');
    }

    if (token != null) {
      await _saveToken(
        uid: cleanUid,
        token: token,
      );
    }

    _tokenRefreshSubscription =
        messaging.onTokenRefresh.listen(
              (newToken) async {
            final targetUid = _activeUid;

            if (targetUid.isEmpty) {
              return;
            }

            if (kDebugMode) {
              safeDebugPrint('PUSH_REGISTRATION_REFRESHED');
            }

            try {
              await _saveToken(
                uid: targetUid,
                token: newToken,
              );
            } catch (error) {
              safeDebugPrint(
                'PUSH_REGISTRATION_REFRESH_SAVE_ERROR: $error',
              );
            }
          },
          onError: (Object error) {
            safeDebugPrint(
              'PUSH_REGISTRATION_REFRESH_STREAM_ERROR: $error',
            );
          },
        );

    final initialMessage =
    await messaging.getInitialMessage();

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

    await FirebaseDatabase.instance.ref(
      FirebasePaths.fcmTokenInstallation(
        cleanUid,
        installationId,
      ),
    ).remove();

    if (_activeUid == cleanUid) {
      _activeUid = '';
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
    }
  }

  static void listenForeground({
    required FlutterLocalNotificationsPlugin localNotif,
  }) {
    if (_foregroundListening) return;
    _foregroundListening = true;

    FirebaseMessaging.onMessage.listen((message) async {
      final type =
          message.data['type']?.toString() ?? '';

      if (type == 'chat') {
        await NotificationService.showChatNotification(
          data: message.data,
        );
        return;
      }

      if (type == 'sensor_notification') {
        await NotificationService.showSensorNotification(
          data: message.data,
        );
        return;
      }

      if (type == 'alarm_resolved') {
        await NotificationService.handleAlarmResolved(
          message.data,
        );
        return;
      }

      if (type == 'emergency_notification' ||
          type == 'alarm_detected' ||
          type == 'alarm') {
        await NotificationService
            .showPriorityAlarmNotification(
          data: message.data,
        );
        return;
      }

      if (type == 'alarm_siren') {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await NotificationService.openIosAlarmFromData(
            message.data,
          );
        } else {
          NotificationService.openAlarmFromData(
            message.data,
          );
        }
        return;
      }

      final isSchedule =
          type == 'schedule_notification';

      if (!isSchedule) {
        return;
      }

      final isSafeText =
          message.data['isSafe']?.toString() ?? 'true';

      final isSafe = isSafeText == 'true' ||
          isSafeText == '1' ||
          isSafeText == 'yes';

      final reasonCode =
          message.data['reason']?.toString() ?? '';

      final reminderItems =
          message.data['reminderItems']?.toString() ?? '';

      final scheduleBody =
          message.data['body']?.toString() ?? '';

      final forceShow =
          message.data['forceShow']?.toString() == 'true';

      final displayReason =
      forceShow && scheduleBody.isNotEmpty
          ? scheduleBody
          : reasonCode;

      await NotificationService.showSafetyReminder(
        isSafe: isSafe,
        reason: displayReason,
        reminderItemsJson: reminderItems,
        title:
        message.data['title']?.toString() ?? '',
        forceShow: forceShow,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
          (message) async {
        await _handleOpenedMessage(message);
      },
    );
  }

  static Future<void> _handleOpenedMessage(
      RemoteMessage message,
      ) async {
    final type =
        message.data['type']?.toString() ?? '';

    if (type == 'chat') {
      NotificationService.requestOpenHomeChat(
        message.data,
      );
      return;
    }

    if (type == 'schedule_notification') {
      await NotificationService.stopReminderNotification();
      return;
    }

    if (type == 'alarm_resolved') {
      await NotificationService.handleAlarmResolved(
        message.data,
      );
      return;
    }

    if (type == 'emergency_notification' ||
        type == 'alarm_detected' ||
        type == 'alarm') {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await NotificationService.openIosAlarmFromData(
          message.data,
        );
      } else {
        await NotificationService.handlePriorityAlarmOpened(
          message.data,
        );
      }
      return;
    }

    if (type == 'alarm_siren') {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await NotificationService.openIosAlarmFromData(
          message.data,
        );
      } else {
        NotificationService.openAlarmFromData(
          message.data,
        );
      }
    }
  }
}
