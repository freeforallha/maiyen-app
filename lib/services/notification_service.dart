import 'dart:async';
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
  static final ValueNotifier<Map<String, String>?> chatOpenRequest =
  ValueNotifier<Map<String, String>?>(null);

  static String? _activeHomeChatId;

  static void markHomeChatOpened(String homeId) {
    final cleanHomeId = homeId.trim();

    if (cleanHomeId.isEmpty) return;

    _activeHomeChatId = cleanHomeId;

    unawaited(
      localNotif.cancel(
        _chatNotificationId(cleanHomeId),
      ),
    );
  }

  static void markHomeChatClosed(String homeId) {
    if (_activeHomeChatId == homeId.trim()) {
      _activeHomeChatId = null;
    }
  }

  static void requestOpenHomeChat(
      Map<String, dynamic> rawData,
      ) {
    final homeId =
        rawData["homeId"]?.toString().trim() ?? "";

    if (homeId.isEmpty) return;

    chatOpenRequest.value = {
      "homeId": homeId,
      "homeName":
      rawData["homeName"]?.toString().trim() ?? "",
      "ownerUid":
      rawData["ownerUid"]?.toString().trim() ?? "",
      "messageId":
      rawData["messageId"]?.toString().trim() ?? "",
      "nonce":
      DateTime.now().microsecondsSinceEpoch.toString(),
    };
  }

  static bool _handleHomeChatPayload(String payload) {
    if (!payload.startsWith("home_chat::")) {
      return false;
    }

    try {
      final raw = payload.replaceFirst(
        "home_chat::",
        "",
      );

      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        requestOpenHomeChat(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}

    return true;
  }

  static Future<void> showChatNotification({
    required Map<String, dynamic> data,
  }) async {
    final homeId =
        data["homeId"]?.toString().trim() ?? "";

    if (homeId.isEmpty ||
        _activeHomeChatId == homeId) {
      return;
    }

    final homeName =
        data["homeName"]?.toString().trim() ?? "";
    final senderName =
        data["senderName"]?.toString().trim() ?? "";
    final rawTitle =
        data["title"]?.toString().trim() ?? "";
    final rawBody =
        data["body"]?.toString().trim() ?? "";

    final unreadCount = int.tryParse(
      data["unreadCount"]?.toString() ?? "1",
    ) ??
        1;

    final title = rawTitle.isNotEmpty
        ? rawTitle
        : unreadCount > 1
        ? "${homeName.isNotEmpty ? homeName : "HomeChat"} · "
        "$unreadCount tin nhắn mới"
        : homeName.isNotEmpty
        ? homeName
        : "Tin nhắn HomeChat";

    final body = rawBody.isNotEmpty
        ? rawBody
        : senderName.isNotEmpty
        ? "$senderName đã gửi một tin nhắn"
        : "Bạn có tin nhắn mới";

    final androidDetails =
    AndroidNotificationDetails(
      "safehome_chat_channel_v1",
      "Tin nhắn HomeChat",
      channelDescription:
      "Tin nhắn mới trong các nhà SafeHome",
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category:
      AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final payload = "home_chat::${jsonEncode({
      "homeId": homeId,
      "homeName": homeName,
      "ownerUid":
      data["ownerUid"]?.toString() ?? "",
      "messageId":
      data["messageId"]?.toString() ?? "",
    })}";

    await localNotif.show(
      _chatNotificationId(homeId),
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  static int _chatNotificationId(String homeId) {
    var hash = 0;

    for (final codeUnit in homeId.codeUnits) {
      hash =
      ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return 200000 + (hash % 700000);
  }
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
  static const String reminderRouteName = "fullscreen_reminder";

  static bool _reminderPageOpen = false;

  static final ValueNotifier<int> reminderRevision =
  ValueNotifier<int>(0);

  static void markReminderPageClosed() {
    _reminderPageOpen = false;
  }

  static List<Map<String, dynamic>> _decodeReminderItems(String raw) {
    try {
      final text = raw.trim();

      if (text.isEmpty) return [];

      final decoded = jsonDecode(text);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void _mergeReminderSession({
    required String title,
    required String body,
    required bool isSafe,
    required String reminderItemsJson,
  }) {
    final existingItems =
    _decodeReminderItems(lastReminderItemsJson);

    final incomingItems =
    _decodeReminderItems(reminderItemsJson);

    if (incomingItems.isEmpty) {
      final cleanBody = body
          .replaceAll("⚠️", "")
          .replaceAll("✅", "")
          .replaceAll("CHƯA AN TOÀN", "")
          .replaceAll("ĐÃ AN TOÀN", "")
          .trim();

      incomingItems.add({
        "homeId": "",
        "homeName": title.trim().isEmpty ? "Nhà" : title.trim(),
        "reasons": isSafe
            ? <String>[]
            : <String>[
          cleanBody.isEmpty
              ? "Có mục cần kiểm tra"
              : cleanBody,
        ],
      });
    }

    final merged = <String, Map<String, dynamic>>{};

    for (final item in [
      ...existingItems,
      ...incomingItems,
    ]) {
      final homeId =
          item["homeId"]?.toString().trim() ?? "";

      final homeName =
      item["homeName"]?.toString().trim().isNotEmpty == true
          ? item["homeName"].toString().trim()
          : "Nhà";

      final key = homeId.isNotEmpty
          ? homeId
          : homeName.toLowerCase();

      final reasons = <String>[];
      final rawReasons = item["reasons"];

      if (rawReasons is List) {
        for (final reason in rawReasons) {
          final text = reason?.toString().trim() ?? "";

          if (text.isNotEmpty && !reasons.contains(text)) {
            reasons.add(text);
          }
        }
      }

      final current = merged.putIfAbsent(
        key,
            () => {
          "homeId": homeId,
          "homeName": homeName,
          "reasons": <String>[],
        },
      );

      final currentReasons = List<String>.from(
        current["reasons"] as List,
      );

      for (final reason in reasons) {
        if (!currentReasons.contains(reason)) {
          currentReasons.add(reason);
        }
      }

      current["reasons"] = currentReasons;
    }

    final mergedItems = merged.values.toList();

    final hasUnsafe = mergedItems.any((item) {
      final reasons = item["reasons"];

      return reasons is List && reasons.isNotEmpty;
    });

    lastReminderItemsJson = jsonEncode(mergedItems);

    lastScheduleTitle = mergedItems.length == 1
        ? mergedItems.first["homeName"]?.toString() ?? "Nhà"
        : "SafeHome Reminder";

    if (!hasUnsafe) {
      lastScheduleBody =
      "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi.";
      return;
    }

    final issueLines = <String>[];

    for (final item in mergedItems) {
      final reasons = item["reasons"];

      if (reasons is! List || reasons.isEmpty) continue;

      final homeName =
          item["homeName"]?.toString() ?? "Nhà";

      issueLines.add(
        "$homeName: ${reasons.join(", ")}",
      );
    }

    lastScheduleBody =
    "⚠️ CHƯA AN TOÀN\n${issueLines.join("\n")}";
  }

  static void openOrMergeReminderPage({
    required String title,
    required String body,
    required bool isSafe,
    String reminderItemsJson = "",
  }) {
    _mergeReminderSession(
      title: title,
      body: body,
      isSafe: isSafe,
      reminderItemsJson: reminderItemsJson,
    );

    reminderRevision.value++;

    if (_reminderPageOpen) {
      return;
    }

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) return;

    _reminderPageOpen = true;

    navigator
        .push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: reminderRouteName,
        ),
        builder: (_) => FullscreenAlarmPage(
          title: lastScheduleTitle,
          body: lastScheduleBody,
          silentMode: true,
          reminderItemsJson: lastReminderItemsJson,
        ),
      ),
    )
        .whenComplete(markReminderPageClosed);
  }
  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload ?? '';

        if (_handleHomeChatPayload(payload)) {
          return;
        }

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

        if (payload == 'open_home' ||
            payload == 'schedule_notification' ||
            payload.startsWith('schedule_notification::') ||
            payload.startsWith('schedule_notification|')) {
          await NotificationService.stopReminderNotification();
          return;
        }
      },
    );

    final launchDetails =
    await localNotif.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp == true) {
      final launchPayload =
          launchDetails?.notificationResponse?.payload ?? "";

      _handleHomeChatPayload(launchPayload);

      if (launchPayload == 'open_home' ||
          launchPayload == 'schedule_notification' ||
          launchPayload.startsWith('schedule_notification::') ||
          launchPayload.startsWith('schedule_notification|')) {
        await stopReminderNotification();
      }
    }

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
        description: 'Tin nhắn mới trong các nhà SafeHome',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = localNotif
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >();
      final fullScreenPermission =
      await androidPlugin?.requestFullScreenIntentPermission();

      debugPrint(
        "FULL_SCREEN_INTENT_PERMISSION: $fullScreenPermission",
      );
      await androidPlugin?.createNotificationChannel(alarmChannel);
      await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
      await androidPlugin?.createNotificationChannel(reminderChannel);
      await androidPlugin?.createNotificationChannel(chatChannel);
    }
  }

  static const String alarmRouteName = "fullscreen_alarm";

  static bool _alarmPageOpen = false;

  static final ValueNotifier<int> alarmRevision =
  ValueNotifier<int>(0);

  static final List<Map<String, dynamic>> activeAlarmItems = [];

  static void markAlarmPageClosed() {
    _alarmPageOpen = false;
  }

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

    _addAlarmItems(alarmItemsJson);

    lastAlarmItemsJson = activeAlarmItems.isEmpty
        ? alarmItemsJson
        : jsonEncode(activeAlarmItems);

    alarmRevision.value++;

    if (_alarmPageOpen) {
      return;
    }

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) return;

    _alarmPageOpen = true;

    navigator
        .push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: alarmRouteName,
        ),
        builder: (_) => FullscreenAlarmPage(
          title: title,
          body: lastAlarmBody,
          alarmItemsJson: lastAlarmItemsJson,
        ),
      ),
    )
        .whenComplete(markAlarmPageClosed);
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

    final reminderBody = isSafe
        ? "✅ ĐÃ AN TOÀN\nHãy an tâm nghỉ ngơi."
        : cleanReason.isEmpty
        ? "⚠️ CHƯA AN TOÀN\nCó thiết bị chưa an toàn."
        : "⚠️ CHƯA AN TOÀN\n$cleanReason";

    // Chỉ gộp dữ liệu để cập nhật cùng notification.
    // Không mở trang Reminder toàn màn hình.
    _mergeReminderSession(
      title: cleanTitle.isNotEmpty ? cleanTitle : "Nhà",
      body: reminderBody,
      isSafe: isSafe,
      reminderItemsJson: reminderItemsJson,
    );

    final notificationTitle = isSafe
        ? '${lastScheduleTitle.trim().isEmpty ? "SafeHome" : lastScheduleTitle} · Đã an toàn'
        : '${lastScheduleTitle.trim().isEmpty ? "SafeHome" : lastScheduleTitle} · Cần kiểm tra';

    final notificationBody = isSafe
        ? 'Hãy an tâm nghỉ ngơi.'
        : cleanReason.isEmpty
        ? 'Có thiết bị chưa an toàn.'
        : cleanReason;

    final androidDetails = AndroidNotificationDetails(
      'safehome_reminder_priority_v2',
      'SafeHome Reminder Priority',
      channelDescription:
      'Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình',
      visibility: NotificationVisibility.public,
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: false,
      ongoing: true,
      fullScreenIntent: false,
      playSound: true,
      enableVibration: true,
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
      presentSound: true,
    );

    // ID cố định: Reminder mới cập nhật Reminder cũ,
    // không sinh nhiều notification trùng nhau.
    await localNotif.cancel(999998);

    await localNotif.show(
      999998,
      notificationTitle,
      notificationBody,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'open_home',
    );
  }
}