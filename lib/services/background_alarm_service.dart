import 'dart:convert';
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
    'alarm_channel_siren_v1',
    'Alarm Channel Siren V1',
    description: 'Alarm notification phát âm thanh khi app chạy nền',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm_siren'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
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

  final type = message.data['type']?.toString() ?? '';
  final isSchedule = type == 'schedule_notification';
  final isAlarm = type == 'alarm';

  if (!isSchedule && !isAlarm) {
    return;
  }

  if (isSchedule) {
    final body = _buildScheduleBody(message.data);

    await localNotif.cancel(999998);
    await localNotif.cancel(999999);
    await localNotif.show(
      999998,
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
      payload: 'schedule_notification::${jsonEncode({
        "body": body,
        "reminderItems": message.data['reminderItems']?.toString() ?? '',
      })}',
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

  final alarmItems = message.data['alarmItems']?.toString() ?? '';

  final payload =
      'alarm_summary|${Uri.encodeComponent(body)}|${Uri.encodeComponent(alarmItems)}';

  await localNotif.cancel(999999);

  await localNotif.show(
    999999,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel_siren_v1',
        'Alarm Channel Siren V1',
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
    payload: payload,
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