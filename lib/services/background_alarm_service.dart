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

  final type = message.data['type']?.toString() ?? 'alarm';
  final isSchedule = type == 'schedule_notification';

  final title = message.notification?.title ??
      message.data['title'] ??
      (isSchedule ? '🏡 SAFEHOME' : 'SafeHome Alarm');

  final body = message.notification?.body ??
      message.data['body'] ??
      (isSchedule ? 'Đã đến giờ kiểm tra SafeHome' : 'Alarm triggered');

  final androidDetails = AndroidNotificationDetails(
    isSchedule
        ? 'safehome_schedule_fullscreen_channel'
        : 'alarm_siren_channel',
    isSchedule ? 'SafeHome Schedule Fullscreen' : 'Alarm Siren',
    importance: Importance.max,
    priority: Priority.high,
    category: isSchedule
        ? AndroidNotificationCategory.reminder
        : AndroidNotificationCategory.alarm,
    fullScreenIntent: true,

    // Schedule: full màn hình nhưng không âm, không rung.
    // Alarm thật: có âm còi + rung.
    playSound: !isSchedule,
    enableVibration: !isSchedule,
    sound: isSchedule
        ? null
        : const RawResourceAndroidNotificationSound('alarm_siren'),
  );

  await backgroundLocalNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title.toString(),
    body.toString(),
    NotificationDetails(
      android: androidDetails,
    ),
    payload: isSchedule ? 'schedule_notification' : 'alarm',
  );
}