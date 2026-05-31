import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  await localNotif.initialize(
    const InitializationSettings(android: androidInit),
  );

  final androidPlugin =
  localNotif.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  const alarmChannel = AndroidNotificationChannel(
    'alarm_channel_silent_v3',
    'Alarm Channel Silent V3',
    description: 'Alarm notification chỉ mở fullscreen, không phát âm thanh',
    importance: Importance.max,
    playSound: false,
    enableVibration: true,
  );

  const scheduleFullscreenChannel = AndroidNotificationChannel(
    'safehome_schedule_fullscreen_channel',
    'SafeHome Schedule Fullscreen',
    description: 'Nhắc nhở SafeHome toàn màn hình không âm thanh',
    importance: Importance.max,
    playSound: false,
  );

  await androidPlugin?.createNotificationChannel(alarmChannel);
  await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);

  final type = message.data['type']?.toString() ?? 'alarm';
  final isSchedule = type == 'schedule_notification';

  if (isSchedule) {
    final body = _buildScheduleBody(message.data);

    await localNotif.show(
      999999,
      '🏡 SafeHome',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'safehome_schedule_fullscreen_channel',
          'SafeHome Schedule Fullscreen',
          channelDescription: 'Nhắc nhở SafeHome toàn màn hình không âm thanh',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          fullScreenIntent: true,
          playSound: false,
          enableVibration: false,
        ),
      ),
      payload: 'schedule_notification|$body',
    );

    return;
  }

  final title =
      message.data['title']?.toString() ??
          message.notification?.title?.toString() ??
          '🚨 BÁO ĐỘNG SAFEHOME';

  final body =
      message.data['body']?.toString() ??
          message.notification?.body?.toString() ??
          'Có cảnh báo an ninh cần kiểm tra ngay.';

  await localNotif.cancel(999999);

  await localNotif.show(
    999999,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel_silent_v3',
        'Alarm Channel Silent V3',
        channelDescription:
        'Alarm notification chỉ mở fullscreen, không phát âm thanh',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: false,
        enableVibration: true,
      ),
    ),
    payload: 'open_home',
  );
}

String _buildScheduleBody(Map<String, dynamic> data) {
  final isSafeText = data['isSafe']?.toString() ?? 'true';

  final isSafe =
      isSafeText == 'true' || isSafeText == '1' || isSafeText == 'yes';

  final reason = data['reason']?.toString().trim() ?? '';

  NotificationService.lastScheduleBody = isSafe
      ? '✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi.'
      : reason.isEmpty
      ? '⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn.'
      : '⚠️ CHƯA AN TOÀN\n$reason';

  return NotificationService.lastScheduleBody;
}