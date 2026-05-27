import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  await localNotif.initialize(
    const InitializationSettings(android: androidInit),
  );

  final type = message.data['type']?.toString() ?? 'alarm';
  final isSchedule = type == 'schedule_notification';

  final title = message.notification?.title?.toString() ??
      message.data['title']?.toString() ??
      (isSchedule ? '🏡 SAFEHOME' : 'SafeHome Alarm');

  final body = isSchedule
      ? _buildScheduleBody(message.data)
      : message.notification?.body?.toString() ??
      message.data['body']?.toString() ??
      'Alarm triggered';

  final channelId = isSchedule
      ? 'safehome_schedule_fullscreen_channel'
      : 'alarm_siren_channel';

  final channelName =
  isSchedule ? 'SafeHome Schedule Fullscreen' : 'Alarm Siren';

  await localNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
        category: isSchedule
            ? AndroidNotificationCategory.reminder
            : AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: !isSchedule,
        enableVibration: !isSchedule,
        sound: isSchedule
            ? null
            : const RawResourceAndroidNotificationSound('alarm_siren'),
      ),
    ),
    payload: isSchedule ? 'schedule_notification|$body' : 'alarm',
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