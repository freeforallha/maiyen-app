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

  const alarmChannel = AndroidNotificationChannel(
    'alarm_channel_siren_v1',
    'Alarm Channel Siren V1',
    description:
    'Alarm notification phát âm thanh khi app chạy nền',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(
      'alarm_siren',
    ),
    audioAttributesUsage:
    AudioAttributesUsage.alarm,
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
    alarmChannel,
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

  final isSchedule =
      type == 'schedule_notification';

  final isAlarm =
      type == 'alarm';

  if (!isSchedule && !isAlarm) {
    return;
  }

  if (isSchedule) {
    final body =
    _buildScheduleBody(message.data);

    final homeTitle =
    message.data['title']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? message.data['title']
        .toString()
        .trim()
        : 'SafeHome';

    final isSafe =
        message.data['isSafe']?.toString() == 'true' ||
            message.data['isSafe']?.toString() == '1' ||
            message.data['isSafe']?.toString() == 'yes';

    final notificationTitle = isSafe
        ? '$homeTitle · Đã an toàn'
        : '$homeTitle · Cần kiểm tra';

    // Reminder chỉ thay thế Reminder cũ.
    // Tuyệt đối không huỷ notification Alarm.
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
          category:
          AndroidNotificationCategory.reminder,
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

  final alarmItems =
      message.data['alarmItems']?.toString() ?? '';

  final payload =
      'alarm_summary|${Uri.encodeComponent(body)}|'
      '${Uri.encodeComponent(alarmItems)}';

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
        category:
        AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: false,
        enableVibration: true,
      ),
    ),
    payload: payload,
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
    "homeId": homeId,
    "homeName": homeName,
    "ownerUid":
    data['ownerUid']?.toString() ?? '',
    "messageId":
    data['messageId']?.toString() ?? '',
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
        category:
        AndroidNotificationCategory.message,
        playSound: true,
        enableVibration: true,
        tag: 'home_chat_$homeId',
        styleInformation:
        BigTextStyleInformation(
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
