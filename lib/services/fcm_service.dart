import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../helpers/firebase_paths.dart';
import 'notification_service.dart';

class FCMService {
  static bool _foregroundListening = false;

  static Future<void> setupFCM({required String uid}) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();

    if (token != null) {
      await FirebaseDatabase.instance.ref(FirebasePaths.fcmToken(uid)).set(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      await FirebaseDatabase.instance.ref(FirebasePaths.fcmToken(uid)).set(newToken);
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

      final reason = message.data["reason"]?.toString() ?? "";

      if (isSchedule) {
        await NotificationService.showSafetyReminder(
          isSafe: isSafe,
          reason: reason,
        );
        return;
      }

      final title =
          message.notification?.title?.toString() ??
              message.data["title"]?.toString() ??
              "SafeHome Alarm";

      final body =
          message.notification?.body?.toString() ??
              message.data["body"]?.toString() ??
              "Có cảnh báo an ninh cần kiểm tra ngay.";

      await localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_siren_channel',
            'Alarm Siren',
            channelDescription: 'Báo động SafeHome có âm thanh còi',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            playSound: true,
            enableVibration: true,
            sound: RawResourceAndroidNotificationSound('alarm_siren'),
          ),
        ),
        payload: 'alarm|${message.data["uid"] ?? ""}|${message.data["homeId"] ?? ""}',
      );
    });
  }
}