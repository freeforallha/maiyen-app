import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FCMService {
  static Future<void> setupFCM({required String uid}) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();

    print("NEW FCM TOKEN: $token");

    if (token != null) {
      await FirebaseDatabase.instance.ref("accounts/$uid/fcmToken").set(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      print("REFRESH TOKEN: $newToken");

      await FirebaseDatabase.instance
          .ref("accounts/$uid/fcmToken")
          .set(newToken);
    });
  }

  static void listenForeground({
    required FlutterLocalNotificationsPlugin localNotif,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    FirebaseMessaging.onMessage.listen((message) async {
      print("MESSAGE DATA: ${message.data}");
      print("MESSAGE NOTIF: ${message.notification}");

      final title =
          message.notification?.title ?? message.data["title"] ?? "SafeHome";

      final body =
          message.notification?.body ?? message.data["body"] ?? "Alarm triggered";

      final nav = navigatorKey.currentState;

      if (nav != null) {
        showDialog(
          context: nav.overlay!.context,
          useRootNavigator: true,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade700,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                body,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(nav.overlay!.context),                  child: const Text("Đóng"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(nav.overlay!.context);                  },
                  child: const Text("Kiểm tra"),
                ),
              ],
            );
          },
        );
      }

      await localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarm',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: false,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    });
  }
}