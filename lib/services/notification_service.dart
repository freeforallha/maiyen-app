import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localNotif =
FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotif.initialize(
      const InitializationSettings(android: android),
    );

    const alarmChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarm Channel',
      importance: Importance.max,
      playSound: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      'safehome_reminder_channel',
      'SafeHome Reminder',
      description: 'Nhắc nhở an toàn nhẹ nhàng',
      importance: Importance.high,
      playSound: false,
    );

    final androidPlugin =
    localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
  }

  static Future<void> showSafetyReminder({
    required bool isSafe,
    String reason = '',
  }) async {
    final title = isSafe ? 'SafeHome ✅ ĐÃ AN TOÀN' : 'SafeHome ⚠️ CHƯA AN TOÀN';

    final body = isSafe
        ? 'Hãy an tâm nghỉ ngơi.'
        : reason.trim().isEmpty
        ? 'Có thiết bị chưa an toàn.'
        : 'Lý do: ${reason.trim()}';

    final bigText = isSafe
        ? '✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi.'
        : reason.trim().isEmpty
        ? '⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn.'
        : '⚠️ CHƯA AN TOÀN\nLý do: ${reason.trim()}';

    final androidDetails = AndroidNotificationDetails(
      'safehome_reminder_channel',
      'SafeHome Reminder',
      channelDescription: 'Nhắc nhở an toàn nhẹ nhàng',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      fullScreenIntent: false,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(
        bigText,
        contentTitle: title,
        summaryText: 'SafeHome',
      ),
    );

    await localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}