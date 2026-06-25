import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../helpers/firebase_paths.dart';
import 'notification_service.dart';

class FCMService {
  static bool _foregroundListening = false;

  static Future<void> setupFCM({required String uid}) async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("🔔 Permission: ${settings.authorizationStatus}");

    final apnsToken = await messaging.getAPNSToken();
    debugPrint("🍎 APNS TOKEN: $apnsToken");

    final token = await messaging.getToken();
    debugPrint("🔥 FCM TOKEN: $token");

    if (token != null) {
      await FirebaseDatabase.instance
          .ref(FirebasePaths.fcmToken(uid))
          .set(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint("🔥 FCM TOKEN REFRESH: $newToken");
      await FirebaseDatabase.instance
          .ref(FirebasePaths.fcmToken(uid))
          .set(newToken);
    });
  }

  static void listenForeground({
    required FlutterLocalNotificationsPlugin localNotif,
  }) {
    if (_foregroundListening) return;
    _foregroundListening = true;

    FirebaseMessaging.onMessage.listen((message) async {
      final type = message.data["type"]?.toString() ?? "alarm";
      final isSchedule = type == "schedule_notification";

      final isSafeText = message.data["isSafe"]?.toString() ?? "true";
      final isSafe =
          isSafeText == "true" || isSafeText == "1" || isSafeText == "yes";

      final reasonCode = message.data["reason"]?.toString() ?? "";
      final reminderItems = message.data["reminderItems"]?.toString() ?? "";
      final scheduleBody = message.data["body"]?.toString() ?? "";

      final forceShow = message.data["forceShow"]?.toString() == "true";

      final displayReason = forceShow && scheduleBody.isNotEmpty
          ? scheduleBody
          : reasonCode;

      if (isSchedule) {
        await NotificationService.showSafetyReminder(
          isSafe: isSafe,
          reason: displayReason,
          reminderItemsJson: reminderItems,
          title: message.data["title"]?.toString() ?? "",
          forceShow: forceShow,
        );
        return;
      }

      final title =
          message.notification?.title?.toString() ??
          message.data["title"]?.toString() ??
          "SafeHome Alarm";

      final alarmBody =
          message.notification?.body?.toString() ??
          message.data["body"]?.toString() ??
          "Có cảnh báo an ninh cần kiểm tra ngay.";

      final alarmItems = message.data["alarmItems"]?.toString() ?? "";

      NotificationService.openAlarmPage(
        title: title,
        body: alarmBody,
        alarmItemsJson: alarmItems,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final type = message.data["type"]?.toString() ?? "alarm";

      if (type != "alarm") return;

      final title = message.data["title"]?.toString() ?? "🚨 SafeHome";

      final alarmBody =
          message.data["body"]?.toString() ??
          "Có cảnh báo an ninh cần kiểm tra ngay.";

      final alarmItems = message.data["alarmItems"]?.toString() ?? "";

      NotificationService.openAlarmPage(
        title: title,
        body: alarmBody,
        alarmItemsJson: alarmItems,
      );
    });
  }
}
