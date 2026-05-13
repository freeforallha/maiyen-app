import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static Future<void> setupFCM({required String uid}) async {
    final messaging = FirebaseMessaging.instance;

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
  }) {
    FirebaseMessaging.onMessage.listen((message) {
      print("MESSAGE DATA: ${message.data}");
      print("MESSAGE NOTIF: ${message.notification}");

      final notif = message.notification;

      if (notif == null) return;

      localNotif.show(
        0,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarm',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}
