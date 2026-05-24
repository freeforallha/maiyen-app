import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin backgroundLocalNotif =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  await backgroundLocalNotif.initialize(
    const InitializationSettings(
      android: androidInit,
    ),
  );

  const androidDetails = AndroidNotificationDetails(
    'alarm_siren_channel',
    'Alarm Siren',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('alarm_siren'),
  );

  final title =
      message.notification?.title ??
          message.data['title'] ??
          'SafeHome Alarm';

  final body =
      message.notification?.body ??
          message.data['body'] ??
          'Alarm triggered';

  await backgroundLocalNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: androidDetails,
    ),
    payload: "alarm",
  );
}