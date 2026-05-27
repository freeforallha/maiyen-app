import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localNotif =
FlutterLocalNotificationsPlugin();

class NotificationService {
  static String lastScheduleBody =
      "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi.";

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

    const alarmSirenChannel = AndroidNotificationChannel(
      'alarm_siren_channel',
      'Alarm Siren',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_siren'),
    );

    const scheduleFullscreenChannel = AndroidNotificationChannel(
      'safehome_schedule_fullscreen_channel',
      'SafeHome Schedule Fullscreen',
      description: 'Nhắc nhở SafeHome toàn màn hình không âm thanh',
      importance: Importance.max,
      playSound: false,
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
    await androidPlugin?.createNotificationChannel(alarmSirenChannel);
    await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
  }

  static Future<void> showSafetyReminder({
    required bool isSafe,
    String reason = '',
  }) async {
    final cleanReason = reason.trim();

    lastScheduleBody = isSafe
        ? "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi."
        : cleanReason.isEmpty
        ? "⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn."
        : "⚠️ CHƯA AN TOÀN\n$cleanReason";

    final title = isSafe
        ? 'SafeHome ✅ ĐÃ AN TOÀN'
        : 'SafeHome ⚠️ CHƯA AN TOÀN';

    final body = isSafe
        ? 'Hãy an tâm nghỉ ngơi.'
        : cleanReason.isEmpty
        ? 'Có thiết bị chưa an toàn.'
        : cleanReason;

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
        lastScheduleBody,
        contentTitle: title,
        summaryText: 'SafeHome',
      ),
    );

    await localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: "schedule_notification|$lastScheduleBody",
    );
  }
}