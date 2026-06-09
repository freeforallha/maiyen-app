import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app/safe_home_app.dart';
import '../pages/fullscreen_alarm_page.dart';

final FlutterLocalNotificationsPlugin localNotif =
FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> stopAlarmNotification() async {
    await localNotif.cancel(999999);
  }

  static Future<void> stopReminderNotification() async {
    await localNotif.cancel(999998);
  }
  static String lastScheduleBody = "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi.";
  static String lastReminderItemsJson = "";
  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: false,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: false,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotif.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload ?? '';

        if (payload.startsWith('alarm_summary|')) {
          final parts = payload.split('|||');

          final body = parts.length > 1
              ? Uri.decodeComponent(parts[1])
              : 'Có cảnh báo cần kiểm tra';

          final alarmItems = parts.length > 2
              ? Uri.decodeComponent(parts[2])
              : '';

          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => FullscreenAlarmPage(
                title: '🚨 SafeHome',
                body: body,
                alarmItemsJson: alarmItems,
              ),
            ),
          );

          return;
        }

        if (payload == 'alarm' || payload == 'open_home') {
          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => const FullscreenAlarmPage(
                title: '🚨 SafeHome',
                body: 'Có cảnh báo an ninh cần kiểm tra ngay.',
              ),
            ),
          );

          return;
        }

        if (payload.startsWith('schedule_notification::')) {
          String body = lastScheduleBody;
          String reminderItemsJson = lastReminderItemsJson;

          try {
            final raw = payload.replaceFirst('schedule_notification::', '');
            final data = Map<String, dynamic>.from(jsonDecode(raw));

            body = data["body"]?.toString() ?? body;
            reminderItemsJson =
                data["reminderItems"]?.toString() ?? reminderItemsJson;
          } catch (_) {}

          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => FullscreenAlarmPage(
                title: '🏡 SafeHome Reminder',
                body: body,
                silentMode: true,
                reminderItemsJson: reminderItemsJson,
              ),
            ),
          );

          return;
        }

        if (payload == 'schedule_notification') {
          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => FullscreenAlarmPage(
                title: '🏡 SafeHome Reminder',
                body: lastScheduleBody,
                silentMode: true,
                reminderItemsJson: lastReminderItemsJson,
              ),
            ),
          );

          return;
        }
      },
    );

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
    await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
  }
  static void openAlarmPage({
    required String title,
    required String body,
    String alarmItemsJson = '',
  }) {
    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => FullscreenAlarmPage(
          title: title,
          body: body,
          alarmItemsJson: alarmItemsJson,
        ),
      ),
    );
  }
  static Future<void> showSafetyReminder({
    required bool isSafe,
    String reason = '',
    String reminderItemsJson = '',
  }) async {
    final cleanReason = reason.trim();
    lastReminderItemsJson = reminderItemsJson;
    lastScheduleBody = isSafe
        ? "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi."
        : cleanReason.isEmpty
        ? "⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn."
        : "⚠️ CHƯA AN TOÀN\n$cleanReason";

    final title =
    isSafe ? 'SafeHome ✅ ĐÃ AN TOÀN' : 'SafeHome ⚠️ CHƯA AN TOÀN';

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
      payload: "schedule_notification",
    );
  }
}