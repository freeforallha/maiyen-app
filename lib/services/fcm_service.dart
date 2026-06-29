import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../helpers/firebase_paths.dart';
import 'notification_service.dart';

class FCMService {
  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String _installationIdKey =
      'safehome_fcm_installation_id';

  static bool _foregroundListening = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String _activeUid = '';

  static Future<String> _getInstallationId() async {
    final saved = await _storage.read(
      key: _installationIdKey,
    );

    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }

    final random = Random.secure();
    final bytes = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    final installationId = bytes
        .map(
          (value) => value.toRadixString(16).padLeft(2, '0'),
    )
        .join();

    await _storage.write(
      key: _installationIdKey,
      value: installationId,
    );

    return installationId;
  }

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

    final installationId = await _getInstallationId();
    final now = DateTime.now().millisecondsSinceEpoch;

    await FirebaseDatabase.instance.ref().update({
      // Giữ tương thích với backend/app cũ trong thời gian chuyển đổi.
      FirebasePaths.fcmToken(cleanUid): cleanToken,

      // Một tài khoản có thể lưu nhiều điện thoại.
      FirebasePaths.fcmTokenInstallation(
        cleanUid,
        installationId,
      ): {
        'installationId': installationId,
        'token': cleanToken,
        'platform': _platformName(),
        'updatedAt': now,
      },
    });
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
    );

    debugPrint(
      '🔔 Permission: ${settings.authorizationStatus}',
    );

    final apnsToken = await messaging.getAPNSToken();
    debugPrint('🍎 APNS TOKEN: $apnsToken');

    final token = await messaging.getToken();
    debugPrint('🔥 FCM TOKEN: $token');

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

            debugPrint(
              '🔥 FCM TOKEN REFRESH: $newToken',
            );

            try {
              await _saveToken(
                uid: targetUid,
                token: newToken,
              );
            } catch (error) {
              debugPrint(
                'FCM_TOKEN_REFRESH_SAVE_ERROR: $error',
              );
            }
          },
          onError: (Object error) {
            debugPrint(
              'FCM_TOKEN_REFRESH_STREAM_ERROR: $error',
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

    final installationId = await _getInstallationId();
    final currentToken =
    await FirebaseMessaging.instance.getToken();

    final updates = <String, Object?>{
      FirebasePaths.fcmTokenInstallation(
        cleanUid,
        installationId,
      ): null,
    };

    if (currentToken != null &&
        currentToken.trim().isNotEmpty) {
      final legacyRef = FirebaseDatabase.instance.ref(
        FirebasePaths.fcmToken(cleanUid),
      );

      final legacySnapshot = await legacyRef.get();
      final legacyToken =
          legacySnapshot.value?.toString().trim() ?? '';

      if (legacyToken == currentToken.trim()) {
        updates[FirebasePaths.fcmToken(cleanUid)] = null;
      }
    }

    await FirebaseDatabase.instance.ref().update(updates);

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
        NotificationService.openAlarmFromData(
          message.data,
        );
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
      await NotificationService.handlePriorityAlarmOpened(
        message.data,
      );
      return;
    }

    if (type == 'alarm_siren') {
      NotificationService.openAlarmFromData(
        message.data,
      );
    }
  }
}
