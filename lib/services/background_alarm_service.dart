import 'dart:convert';

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

  const androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  await localNotif.initialize(
    const InitializationSettings(
      android: androidInit,
    ),
  );

  final androidPlugin = localNotif
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  const alarmFullscreenChannel =
  AndroidNotificationChannel(
    'safehome_alarm_fullscreen_v4',
    'SafeHome Alarm Fullscreen',
    description:
    'Mở cảnh báo toàn màn hình; âm còi phát từ trang Alarm',
    importance: Importance.max,
    playSound: false,
    enableVibration: true,
  );

  const emergencyPriorityChannel =
  AndroidNotificationChannel(
    'safehome_emergency_priority_v1',
    'SafeHome Emergency Priority',
    description:
    'Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  const reminderPriorityChannel =
  AndroidNotificationChannel(
    'safehome_reminder_priority_v2',
    'SafeHome Reminder Priority',
    description:
    'Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  const chatChannel = AndroidNotificationChannel(
    'safehome_chat_channel_v1',
    'Tin nhắn HomeChat',
    description:
    'Tin nhắn mới trong các nhà SafeHome',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await androidPlugin?.createNotificationChannel(
    alarmFullscreenChannel,
  );
  await androidPlugin?.createNotificationChannel(
    emergencyPriorityChannel,
  );
  await androidPlugin?.createNotificationChannel(
    reminderPriorityChannel,
  );
  await androidPlugin?.createNotificationChannel(
    chatChannel,
  );

  final type =
      message.data['type']?.toString() ?? '';

  if (type == 'chat') {
    await _showBackgroundChatNotification(
      message.data,
    );
    return;
  }

  if (type == 'alarm_resolved') {
    await Future.wait([
      localNotif.cancel(
        NotificationService.emergencyNotificationId,
      ),
      localNotif.cancel(
        NotificationService.alarmNotificationId,
      ),
    ]);
    return;
  }

  if (type == 'schedule_notification') {
    await _showBackgroundScheduleNotification(
      message.data,
    );
    return;
  }

  if (
  type == 'emergency_notification' ||
      type == 'alarm_detected' ||
      type == 'alarm'
  ) {
    await _showBackgroundPriorityAlarm(
      message.data,
    );
    return;
  }

  if (type == 'alarm_siren') {
    await _showBackgroundFullscreenAlarm(
      message.data,
      message.notification,
    );
  }
}

Future<void> _showBackgroundPriorityAlarm(
    Map<String, dynamic> data,
    ) async {
  final title =
  data['title']?.toString().trim().isNotEmpty == true
      ? data['title'].toString().trim()
      : '🚨 SafeHome phát hiện cảnh báo';

  final body =
  data['body']?.toString().trim().isNotEmpty == true
      ? data['body'].toString().trim()
      : 'Mở SafeHome để kiểm tra ngay.';

  final payload =
      'priority_alarm::${jsonEncode(data)}';

  await localNotif.cancel(
    NotificationService.emergencyNotificationId,
  );

  await localNotif.show(
    NotificationService.emergencyNotificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'safehome_emergency_priority_v1',
        'SafeHome Emergency Priority',
        channelDescription:
        'Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình',
        visibility: NotificationVisibility.public,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        autoCancel: false,
        ongoing: true,
        fullScreenIntent: false,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'SafeHome',
        ),
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

  final payload =
      'alarm_siren::${jsonEncode(data)}';

  await localNotif.cancel(
    NotificationService.emergencyNotificationId,
  );
  await localNotif.cancel(
    NotificationService.alarmNotificationId,
  );

  await localNotif.show(
    NotificationService.alarmNotificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'safehome_alarm_fullscreen_v4',
        'SafeHome Alarm Fullscreen',
        channelDescription:
        'Mở cảnh báo toàn màn hình; âm còi phát từ trang Alarm',
        visibility: NotificationVisibility.public,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        autoCancel: false,
        ongoing: true,
        fullScreenIntent: true,
        playSound: false,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'SafeHome',
        ),
      ),
    ),
    payload: payload,
  );
}

Future<void> _showBackgroundScheduleNotification(
    Map<String, dynamic> data,
    ) async {
  final body = _buildScheduleBody(data);

  final homeTitle =
  data['title']?.toString().trim().isNotEmpty == true
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
      android: AndroidNotificationDetails(
        'safehome_reminder_priority_v2',
        'SafeHome Reminder Priority',
        channelDescription:
        'Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình',
        visibility: NotificationVisibility.public,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        autoCancel: false,
        ongoing: true,
        fullScreenIntent: false,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: notificationTitle,
          summaryText: 'SafeHome',
        ),
      ),
    ),
    payload: 'open_home',
  );
}

Future<void> _showBackgroundChatNotification(
    Map<String, dynamic> data,
    ) async {
  final homeId =
      data['homeId']?.toString().trim() ?? '';

  if (homeId.isEmpty) {
    return;
  }

  final homeName =
      data['homeName']?.toString().trim() ?? '';

  final senderName =
      data['senderName']?.toString().trim() ?? '';

  final unreadCount = int.tryParse(
    data['unreadCount']?.toString() ?? '1',
  ) ??
      1;

  final rawTitle =
      data['title']?.toString().trim() ?? '';

  final rawBody =
      data['body']?.toString().trim() ?? '';

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
      'home_chat::${jsonEncode({
    'homeId': homeId,
    'homeName': homeName,
    'ownerUid': data['ownerUid']?.toString() ?? '',
    'messageId': data['messageId']?.toString() ?? '',
  })}';

  final notificationId =
  _chatNotificationId(homeId);

  await localNotif.cancel(notificationId);

  await localNotif.show(
    notificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'safehome_chat_channel_v1',
        'Tin nhắn HomeChat',
        channelDescription:
        'Tin nhắn mới trong các nhà SafeHome',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        playSound: true,
        enableVibration: true,
        tag: 'home_chat_$homeId',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      ),
    ),
    payload: payload,
  );
}

int _chatNotificationId(String homeId) {
  var hash = 0;

  for (final codeUnit in homeId.codeUnits) {
    hash =
    ((hash * 31) + codeUnit) & 0x7fffffff;
  }

  return 200000 + (hash % 700000);
}

String _buildScheduleBody(
    Map<String, dynamic> data,
    ) {
  final isSafeText =
      data['isSafe']?.toString() ?? 'true';

  final isSafe =
      isSafeText == 'true' ||
          isSafeText == '1' ||
          isSafeText == 'yes';

  final reason =
      data['reason']?.toString().trim() ?? '';

  NotificationService.lastScheduleBody = isSafe
      ? '✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi.'
      : reason.isEmpty
      ? '⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn.'
      : '⚠️ CHƯA AN TOÀN\n$reason';

  return NotificationService.lastScheduleBody;
}
