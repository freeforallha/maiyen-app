import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:safehome_app/helpers/debug_log.dart';
class AndroidNotificationConfig {
  const AndroidNotificationConfig._();

  static const initializationSettings = AndroidInitializationSettings(
    'ic_stat_safehome',
  );

  static bool get isAndroid => Platform.isAndroid;

  static Future<void> configure(
    FlutterLocalNotificationsPlugin localNotif,
  ) async {
    if (!isAndroid) {
      return;
    }

    final androidPlugin = localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final fullScreenPermission = await androidPlugin
        ?.requestFullScreenIntentPermission();

    safeDebugPrint('FULL_SCREEN_INTENT_PERMISSION: $fullScreenPermission');

    await createChannels(localNotif);
  }

  static Future<void> createChannels(
    FlutterLocalNotificationsPlugin localNotif,
  ) async {
    final androidPlugin = localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    const legacyAlarmChannel = AndroidNotificationChannel(
      'alarm_channel_silent_v3',
      'Alarm Channel Silent V3',
      description: 'Kênh Alarm cũ để giữ tương thích',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    const alarmFullscreenChannel = AndroidNotificationChannel(
      'safehome_alarm_fullscreen_v4',
      'SafeHome Alarm Fullscreen',
      description: 'Mở cảnh báo toàn màn hình; âm còi phát từ trang Alarm',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    const emergencyPriorityChannel = AndroidNotificationChannel(
      'safehome_emergency_priority_v1',
      'SafeHome Emergency Priority',
      description: 'Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const scheduleFullscreenChannel = AndroidNotificationChannel(
      'safehome_schedule_fullscreen_channel',
      'SafeHome Schedule Fullscreen',
      description: 'Nhắc nhở SafeHome toàn màn hình không âm thanh',
      importance: Importance.max,
      playSound: false,
    );

    const reminderChannel = AndroidNotificationChannel(
      'safehome_reminder_priority_v2',
      'SafeHome Reminder Priority',
      description: 'Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const chatChannel = AndroidNotificationChannel(
      'safehome_chat_channel_v1',
      'Tin nhắn HomeChat',
      description: 'Tin nhắn mới trong các nhà SafeHome',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(legacyAlarmChannel);
    await androidPlugin?.createNotificationChannel(alarmFullscreenChannel);
    await androidPlugin?.createNotificationChannel(emergencyPriorityChannel);
    await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
  }

  static Future<void> createBackgroundChannels(
    FlutterLocalNotificationsPlugin localNotif,
  ) async {
    final androidPlugin = localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    const alarmFullscreenChannel = AndroidNotificationChannel(
      'safehome_alarm_fullscreen_v4',
      'SafeHome Alarm Fullscreen',
      description: 'Mở cảnh báo toàn màn hình; âm còi phát từ trang Alarm',
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    const emergencyPriorityChannel = AndroidNotificationChannel(
      'safehome_emergency_priority_v1',
      'SafeHome Emergency Priority',
      description: 'Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const reminderPriorityChannel = AndroidNotificationChannel(
      'safehome_reminder_priority_v2',
      'SafeHome Reminder Priority',
      description: 'Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const chatChannel = AndroidNotificationChannel(
      'safehome_chat_channel_v1',
      'Tin nhắn HomeChat',
      description: 'Tin nhắn mới trong các nhà SafeHome',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(alarmFullscreenChannel);
    await androidPlugin?.createNotificationChannel(emergencyPriorityChannel);
    await androidPlugin?.createNotificationChannel(reminderPriorityChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
  }

  static AndroidNotificationDetails priorityAlarmDetails({
    required String title,
    required String body,
  }) {
    return AndroidNotificationDetails(
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
    );
  }

  static AndroidNotificationDetails fullscreenAlarmDetails({
    required String title,
    required String body,
  }) {
    return AndroidNotificationDetails(
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
    );
  }

  static AndroidNotificationDetails chatDetails({
    required String title,
    required String body,
    String? tag,
  }) {
    return AndroidNotificationDetails(
      'safehome_chat_channel_v1',
      'Tin nhắn HomeChat',
      channelDescription: 'Tin nhắn mới trong các nhà SafeHome',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      playSound: true,
      enableVibration: true,
      tag: tag,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );
  }

  static AndroidNotificationDetails reminderDetails({
    required String title,
    required String body,
    required String bigText,
  }) {
    return AndroidNotificationDetails(
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
        bigText,
        contentTitle: title,
        summaryText: 'SafeHome',
      ),
    );
  }
}
