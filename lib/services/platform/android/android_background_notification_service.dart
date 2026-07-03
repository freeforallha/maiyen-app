import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';
import '../../notification_service.dart';
import 'android_notification_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await localNotif.initialize(
    const InitializationSettings(
      android: AndroidNotificationConfig.initializationSettings,
    ),
  );

  await AndroidNotificationConfig.createBackgroundChannels(localNotif);

  final type = message.data['type']?.toString() ?? '';

  if (type == 'chat') {
    await _showBackgroundChatNotification(message.data);
    return;
  }

  if (type == 'alarm_resolved') {
    await Future.wait([
      localNotif.cancel(NotificationService.emergencyNotificationId),
      localNotif.cancel(NotificationService.alarmNotificationId),
    ]);
    return;
  }

  if (type == 'schedule_notification') {
    await _showBackgroundScheduleNotification(message.data);
    return;
  }

  if (type == 'emergency_notification' ||
      type == 'alarm_detected' ||
      type == 'alarm') {
    await _showBackgroundPriorityAlarm(message.data);
    return;
  }

  if (type == 'alarm_siren') {
    await _showBackgroundFullscreenAlarm(message.data, message.notification);
  }
}

Future<void> _showBackgroundPriorityAlarm(Map<String, dynamic> data) async {
  final title = data['title']?.toString().trim().isNotEmpty == true
      ? data['title'].toString().trim()
      : '🚨 SafeHome phát hiện cảnh báo';

  final body = data['body']?.toString().trim().isNotEmpty == true
      ? data['body'].toString().trim()
      : 'Mở SafeHome để kiểm tra ngay.';

  final payload = 'priority_alarm::${jsonEncode(data)}';

  await localNotif.cancel(NotificationService.emergencyNotificationId);

  await localNotif.show(
    NotificationService.emergencyNotificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.priorityAlarmDetails(
        title: title,
        body: body,
      ),
    ),
    payload: payload,
  );
}

Future<void> _showBackgroundFullscreenAlarm(
  Map<String, dynamic> data,
  RemoteNotification? notification,
) async {
  final title =
      data['title']?.toString() ??
      notification?.title?.toString() ??
      '🚨 BÁO ĐỘNG SAFEHOME';

  final body =
      data['body']?.toString() ??
      notification?.body?.toString() ??
      'Có cảnh báo cần kiểm tra ngay.';

  final payload = 'alarm_siren::${jsonEncode(data)}';

  await localNotif.cancel(NotificationService.emergencyNotificationId);
  await localNotif.cancel(NotificationService.alarmNotificationId);

  await localNotif.show(
    NotificationService.alarmNotificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.fullscreenAlarmDetails(
        title: title,
        body: body,
      ),
    ),
    payload: payload,
  );
}

Future<void> _showBackgroundScheduleNotification(
  Map<String, dynamic> data,
) async {
  final body = _buildScheduleBody(data);

  final homeTitle = data['title']?.toString().trim().isNotEmpty == true
      ? data['title'].toString().trim()
      : 'SafeHome';

  final isSafe =
      data['isSafe']?.toString() == 'true' ||
      data['isSafe']?.toString() == '1' ||
      data['isSafe']?.toString() == 'yes';

  final notificationTitle = isSafe
      ? '$homeTitle · Đã an toàn'
      : '$homeTitle · Cần kiểm tra';

  await localNotif.cancel(999998);

  await localNotif.show(
    999998,
    notificationTitle,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.reminderDetails(
        title: notificationTitle,
        body: body,
        bigText: body,
      ),
    ),
    payload: 'open_home',
  );
}

Future<void> _showBackgroundChatNotification(Map<String, dynamic> data) async {
  final homeId = data['homeId']?.toString().trim() ?? '';

  if (homeId.isEmpty) {
    return;
  }

  final homeName = data['homeName']?.toString().trim() ?? '';

  final senderName = data['senderName']?.toString().trim() ?? '';

  final unreadCount = int.tryParse(data['unreadCount']?.toString() ?? '1') ?? 1;

  final rawTitle = data['title']?.toString().trim() ?? '';

  final rawBody = data['body']?.toString().trim() ?? '';

  final title = rawTitle.isNotEmpty
      ? rawTitle
      : unreadCount > 1
      ? '${homeName.isNotEmpty ? homeName : "HomeChat"} · '
            '$unreadCount tin nhắn mới'
      : homeName.isNotEmpty
      ? homeName
      : 'Tin nhắn HomeChat';

  final body = rawBody.isNotEmpty
      ? rawBody
      : senderName.isNotEmpty
      ? '$senderName đã gửi một tin nhắn'
      : 'Bạn có tin nhắn mới';

  final payload =
      'home_chat::${jsonEncode({'homeId': homeId, 'homeName': homeName, 'ownerUid': data['ownerUid']?.toString() ?? '', 'messageId': data['messageId']?.toString() ?? ''})}';

  final notificationId = _chatNotificationId(homeId);

  await localNotif.cancel(notificationId);

  await localNotif.show(
    notificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.chatDetails(
        title: title,
        body: body,
        tag: 'home_chat_$homeId',
      ),
    ),
    payload: payload,
  );
}

int _chatNotificationId(String homeId) {
  var hash = 0;

  for (final codeUnit in homeId.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }

  return 200000 + (hash % 700000);
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
