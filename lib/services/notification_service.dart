import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
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
  static String lastScheduleTitle = "Nhà";
  static String lastReminderItemsJson = "";
  static String lastAlarmItemsJson = "";
  static String lastAlarmBody = "Có cảnh báo an ninh cần kiểm tra ngay.";
  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: false,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: false,
        );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    await localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload ?? '';

        if (payload.startsWith('alarm_summary|')) {
          final parts = payload.split('|');
          final body = parts.length > 1
              ? Uri.decodeComponent(parts[1])
              : 'Có cảnh báo cần kiểm tra';

          final alarmItems = parts.length > 2
              ? Uri.decodeComponent(parts[2])
              : '';

          NotificationService.openAlarmPage(
            title: '🚨 SafeHome',
            body: body,
            alarmItemsJson: alarmItems,
          );

          return;
        }

        if (payload == 'alarm') {
          NotificationService.openAlarmPage(
            title: '🚨 SafeHome',
            body: lastAlarmBody,
            alarmItemsJson: lastAlarmItemsJson,
          );

          return;
        }

        if (payload == 'open_home') {
          return;
        }

        if (payload.startsWith('schedule_notification::')) {
          String title = 'Nhà';
          String body = lastScheduleBody;
          String reminderItemsJson = lastReminderItemsJson;

          try {
            final raw = payload.replaceFirst('schedule_notification::', '');
            final data = Map<String, dynamic>.from(jsonDecode(raw));

            title = data["title"]?.toString() ?? title;
            body = data["body"]?.toString() ?? body;
            reminderItemsJson =
                data["reminderItems"]?.toString() ?? reminderItemsJson;
          } catch (_) {}

          lastScheduleTitle = title;

          appNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => FullscreenAlarmPage(
                title: title,
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
                title: lastScheduleTitle,
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

    if (Platform.isAndroid) {
      const alarmChannel = AndroidNotificationChannel(
        'alarm_channel_silent_v3',
        'Alarm Channel Silent V3',
        description:
            'Alarm notification chỉ mở fullscreen, không phát âm thanh',
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

      final androidPlugin = localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(alarmChannel);
      await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
      await androidPlugin?.createNotificationChannel(reminderChannel);
    }
  }

  static const String alarmRouteName = "fullscreen_alarm";
  static final List<Map<String, dynamic>> activeAlarmItems = [];

  static String _alarmKey(Map<String, dynamic> item) {
    return [
      item["homeName"] ?? "",
      item["deviceId"] ?? "",
      item["deviceName"] ?? item["name"] ?? "",
      item["type"] ?? "",
      item["reason"] ?? "",
    ].join("|");
  }

  static void _addAlarmItems(String alarmItemsJson) {
    try {
      final decoded = jsonDecode(alarmItemsJson);

      if (decoded is! List) return;

      final existingKeys = activeAlarmItems.map(_alarmKey).toSet();

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final key = _alarmKey(map);

        if (!existingKeys.contains(key)) {
          activeAlarmItems.add(map);
          existingKeys.add(key);
        }
      }
    } catch (_) {}
  }

  static void openAlarmPage({
    required String title,
    required String body,
    String alarmItemsJson = '',
  }) {
    lastAlarmBody = body;
    lastAlarmItemsJson = alarmItemsJson;

    _addAlarmItems(alarmItemsJson);

    final mergedAlarmItemsJson = activeAlarmItems.isEmpty
        ? alarmItemsJson
        : jsonEncode(activeAlarmItems);

    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: alarmRouteName),
        builder: (_) => FullscreenAlarmPage(
          title: title,
          body: body,
          alarmItemsJson: mergedAlarmItemsJson,
        ),
      ),
      (route) => route.settings.name != alarmRouteName,
    );
  }

  static void clearActiveAlarms() {
    activeAlarmItems.clear();
    lastAlarmItemsJson = "";
    lastAlarmBody = "Có cảnh báo an ninh cần kiểm tra ngay.";
  }

  static Future<void> showSafetyReminder({
    required bool isSafe,
    String reason = '',
    String reminderItemsJson = '',
    String title = '',
    bool forceShow = false,
  }) async {
    final cleanReason = reason.trim();
    final cleanTitle = title.trim();
    lastScheduleTitle = cleanTitle.isNotEmpty ? cleanTitle : "Nhà";

    if (forceShow) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => FullscreenAlarmPage(
            title: lastScheduleTitle,
            body: reason.isEmpty
                ? 'Có thay đổi về tạm dừng Alarm hôm nay.'
                : reason,
            silentMode: true,
            reminderItemsJson: reminderItemsJson,
          ),
        ),
      );
    }
    lastReminderItemsJson = reminderItemsJson;
    lastScheduleBody = isSafe
        ? "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi."
        : cleanReason.isEmpty
        ? "⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn."
        : "⚠️ CHƯA AN TOÀN\n$cleanReason";

    final notificationTitle = isSafe
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
      visibility: NotificationVisibility.public,
      autoCancel: false,
      channelDescription: 'Nhắc nhở an toàn nhẹ nhàng',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      fullScreenIntent: false,
      category: AndroidNotificationCategory.reminder,
      styleInformation: BigTextStyleInformation(
        lastScheduleBody,
        contentTitle: notificationTitle,
        summaryText: 'SafeHome',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    await localNotif.show(
      999998,
      notificationTitle,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: "schedule_notification",
    );
  }
}
