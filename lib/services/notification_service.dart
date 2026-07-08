import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app/safe_home_app.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import '../pages/fullscreen_alarm_page.dart';
import 'platform/android/android_notification_config.dart';
import 'package:safehome_app/helpers/debug_log.dart';
final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static AppStrings get _strings =>
      AppStrings.fromLocale(appLanguageController.locale);

  static final ValueNotifier<Map<String, String>?> chatOpenRequest =
      ValueNotifier<Map<String, String>?>(null);

  static String? _activeHomeChatId;

  static void markHomeChatOpened(String homeId) {
    final cleanHomeId = homeId.trim();

    if (cleanHomeId.isEmpty) return;

    _activeHomeChatId = cleanHomeId;

    unawaited(localNotif.cancel(_chatNotificationId(cleanHomeId)));
  }

  static void markHomeChatClosed(String homeId) {
    if (_activeHomeChatId == homeId.trim()) {
      _activeHomeChatId = null;
    }
  }

  static void requestOpenHomeChat(Map<String, dynamic> rawData) {
    final homeId = rawData["homeId"]?.toString().trim() ?? "";

    if (homeId.isEmpty) return;

    chatOpenRequest.value = {
      "homeId": homeId,
      "homeName": rawData["homeName"]?.toString().trim() ?? "",
      "ownerUid": rawData["ownerUid"]?.toString().trim() ?? "",
      "messageId": rawData["messageId"]?.toString().trim() ?? "",
      "nonce": DateTime.now().microsecondsSinceEpoch.toString(),
    };
  }

  static bool _handleHomeChatPayload(String payload) {
    if (!payload.startsWith("home_chat::")) {
      return false;
    }

    try {
      final raw = payload.replaceFirst("home_chat::", "");

      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        requestOpenHomeChat(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}

    return true;
  }

  static const int emergencyNotificationId = 999997;
  static const int alarmNotificationId = 999999;

  static final Map<String, Map<String, String>> _activeAlarmIncidentContexts =
      {};

  static final ValueNotifier<int> alarmResolvedRevision = ValueNotifier<int>(0);

  static Timer? _pendingAlarmOpenTimer;
  static Map<String, dynamic>? _pendingAlarmOpenData;

  static bool get hasActiveAlarmIncidents =>
      _activeAlarmIncidentContexts.isNotEmpty;

  static Map<String, dynamic>? _decodeAlarmPayload(
    String payload,
    String prefix,
  ) {
    if (!payload.startsWith('$prefix::')) {
      return null;
    }

    try {
      final raw = payload.replaceFirst('$prefix::', '');
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return null;
  }

  static void rememberAlarmIncident(Map<String, dynamic> data) {
    final incidentId = data['incidentId']?.toString().trim() ?? '';

    if (incidentId.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final receiverUid =
        data['receiverUid']?.toString().trim().isNotEmpty == true
        ? data['receiverUid'].toString().trim()
        : currentUid;

    final ownerUid = data['ownerUid']?.toString().trim() ?? '';

    final homeId = data['homeId']?.toString().trim() ?? '';

    final flowType = data['alarmFlowType']?.toString().trim() ?? '';

    // Mỗi người chỉ giữ incident mới nhất của cùng một nhà
    // và cùng luồng cảnh báo. Incident cũ đã superseded
    // không được gửi xác nhận lại.
    if (homeId.isNotEmpty && flowType.isNotEmpty) {
      _activeAlarmIncidentContexts.removeWhere((oldIncidentId, context) {
        if (oldIncidentId == incidentId) {
          return false;
        }

        return context['receiverUid'] == receiverUid &&
            context['homeId'] == homeId &&
            context['flowType'] == flowType;
      });
    }

    _activeAlarmIncidentContexts[incidentId] = {
      'incidentId': incidentId,
      'receiverUid': receiverUid,
      'ownerUid': ownerUid,
      'homeId': homeId,
      'flowType': flowType,
    };
  }

  static Future<bool> _sendAlarmIncidentAction({
    required String incidentId,
    required String receiverUid,
    required String action,
  }) async {
    final requestedBy = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (incidentId.isEmpty) {
      return true;
    }

    if (requestedBy.isEmpty) {
      safeDebugPrint('ALARM ACTION ERROR: chưa có người dùng đăng nhập');
      return false;
    }

    final realReceiverUid = receiverUid.isNotEmpty ? receiverUid : requestedBy;

    try {
      final ref = FirebaseDatabase.instance
          .ref('alarm_incident_action_requests')
          .push();

      await ref.set({
        'status': 'pending',
        'receiverUid': realReceiverUid,
        'incidentId': incidentId,
        'requestedBy': requestedBy,
        'action': action,
        'createdAt': ServerValue.timestamp,
      });

      return true;
    } catch (error) {
      safeDebugPrint('ALARM ACTION WRITE ERROR: $error');
      return false;
    }
  }

  static Future<bool> resolveActiveAlarmIncidents({
    required String action,
    String incidentId = '',
  }) async {
    final targets = <Map<String, String>>[];

    if (incidentId.trim().isNotEmpty) {
      final context = _activeAlarmIncidentContexts[incidentId.trim()];

      targets.add(
        context ??
            {
              'incidentId': incidentId.trim(),
              'receiverUid': FirebaseAuth.instance.currentUser?.uid ?? '',
            },
      );
    } else {
      targets.addAll(
        _activeAlarmIncidentContexts.values.map(
          (item) => Map<String, String>.from(item),
        ),
      );
    }

    // Alarm cũ không có incidentId vẫn được phép đóng cục bộ.
    if (targets.isEmpty) {
      return true;
    }

    for (final target in targets) {
      final ok = await _sendAlarmIncidentAction(
        incidentId: target['incidentId'] ?? '',
        receiverUid: target['receiverUid'] ?? '',
        action: action,
      );

      if (!ok) {
        return false;
      }
    }

    for (final target in targets) {
      final id = target['incidentId'] ?? '';

      if (id.isNotEmpty) {
        _activeAlarmIncidentContexts.remove(id);
      }
    }

    return true;
  }

  static Future<void> showPriorityAlarmNotification({
    required Map<String, dynamic> data,
  }) async {
    rememberAlarmIncident(data);
    final strings = _strings;

    final title = data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString().trim()
        : strings.priorityAlarmNotificationTitle();

    final body = data['body']?.toString().trim().isNotEmpty == true
        ? data['body'].toString().trim()
        : strings.openSafeHomeToCheckBody();

    final payload = 'priority_alarm::${jsonEncode(data)}';

    final androidDetails = AndroidNotificationConfig.priorityAlarmDetails(
      title: title,
      body: body,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await localNotif.cancel(emergencyNotificationId);

    await localNotif.show(
      emergencyNotificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static Future<void> handlePriorityAlarmOpened(
    Map<String, dynamic> data,
  ) async {
    rememberAlarmIncident(data);
    await stopEmergencyNotification();

    final incidentId = data['incidentId']?.toString().trim() ?? '';

    final ok = await resolveActiveAlarmIncidents(
      action: 'check_home',
      incidentId: incidentId,
    );

    if (ok && incidentId.isNotEmpty) {
      _activeAlarmIncidentContexts.remove(incidentId);
    }
  }

  static Future<void> handleAlarmResolved(Map<String, dynamic> data) async {
    final incidentId = data['incidentId']?.toString().trim() ?? '';

    if (incidentId.isNotEmpty) {
      _activeAlarmIncidentContexts.remove(incidentId);
    } else {
      _activeAlarmIncidentContexts.clear();
    }

    await stopAllAlarmNotifications();

    if (_activeAlarmIncidentContexts.isEmpty) {
      clearActiveAlarms(clearIncidentContexts: false);
      alarmResolvedRevision.value++;
    }
  }

  static Future<bool> handleAlarmNotificationPayload(String payload) async {
    final priorityData = _decodeAlarmPayload(payload, 'priority_alarm');

    if (priorityData != null) {
      await handlePriorityAlarmOpened(priorityData);
      return true;
    }

    final sirenData = _decodeAlarmPayload(payload, 'alarm_siren');

    if (sirenData != null) {
      openAlarmFromData(sirenData);
      return true;
    }

    return false;
  }

  static void openAlarmFromData(Map<String, dynamic> data) {
    rememberAlarmIncident(data);
    final strings = _strings;

    openAlarmPage(
      title: data['title']?.toString().trim().isNotEmpty == true
          ? data['title'].toString().trim()
          : '🚨 SafeHome',
      body: data['body']?.toString().trim().isNotEmpty == true
          ? data['body'].toString().trim()
          : strings.alarmBody,
      alarmItemsJson: data['alarmItems']?.toString() ?? '',
      incidentId: data['incidentId']?.toString() ?? '',
      receiverUid: data['receiverUid']?.toString() ?? '',
      ownerUid: data['ownerUid']?.toString() ?? '',
      homeId: data['homeId']?.toString() ?? '',
      flowType: data['alarmFlowType']?.toString() ?? '',
    );
  }

  static Future<void> showChatNotification({
    required Map<String, dynamic> data,
  }) async {
    final strings = _strings;
    final homeId = data["homeId"]?.toString().trim() ?? "";

    if (homeId.isEmpty || _activeHomeChatId == homeId) {
      return;
    }

    final homeName = data["homeName"]?.toString().trim() ?? "";
    final senderName = data["senderName"]?.toString().trim() ?? "";
    final rawTitle = data["title"]?.toString().trim() ?? "";
    final rawBody = data["body"]?.toString().trim() ?? "";

    final unreadCount =
        int.tryParse(data["unreadCount"]?.toString() ?? "1") ?? 1;

    final title = rawTitle.isNotEmpty
        ? rawTitle
        : unreadCount > 1
        ? "${homeName.isNotEmpty ? homeName : "HomeChat"} · "
              "${strings.homeChatNewMessages(unreadCount)}"
        : homeName.isNotEmpty
        ? homeName
        : strings.homeChatTitle();

    final body = rawBody.isNotEmpty
        ? rawBody
        : senderName.isNotEmpty
        ? strings.homeChatSenderMessage(senderName)
        : strings.homeChatNewMessage();

    final androidDetails = AndroidNotificationConfig.chatDetails(
      title: title,
      body: body,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final payload =
        "home_chat::${jsonEncode({"homeId": homeId, "homeName": homeName, "ownerUid": data["ownerUid"]?.toString() ?? "", "messageId": data["messageId"]?.toString() ?? ""})}";

    await localNotif.show(
      _chatNotificationId(homeId),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static int _chatNotificationId(String homeId) {
    var hash = 0;

    for (final codeUnit in homeId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return 200000 + (hash % 700000);
  }

  static Future<void> stopAlarmNotification() async {
    await localNotif.cancel(alarmNotificationId);
  }

  static Future<void> stopEmergencyNotification() async {
    await localNotif.cancel(emergencyNotificationId);
  }

  static Future<void> stopAllAlarmNotifications() async {
    await Future.wait([stopAlarmNotification(), stopEmergencyNotification()]);
  }

  static Future<void> stopReminderNotification() async {
    await localNotif.cancel(999998);
  }

  static String lastScheduleBody = _strings.safetyReminderBody(isSafe: true);
  static String lastScheduleTitle = _strings.defaultHomeName();
  static String lastReminderItemsJson = "";
  static String lastAlarmItemsJson = "";
  static String lastAlarmBody = _strings.alarmBody;
  static const String reminderRouteName = "fullscreen_reminder";

  static bool _reminderPageOpen = false;

  static final ValueNotifier<int> reminderRevision = ValueNotifier<int>(0);

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
    final strings = _strings;
    final existingItems = _decodeReminderItems(lastReminderItemsJson);

    final incomingItems = _decodeReminderItems(reminderItemsJson);

    if (incomingItems.isEmpty) {
      final cleanBody = strings.stripSafetyStatusText(body);

      incomingItems.add({
        "homeId": "",
        "homeName": title.trim().isEmpty ? strings.defaultHomeName() : title.trim(),
        "reasons": isSafe
            ? <String>[]
            : <String>[
                cleanBody.isEmpty
                    ? strings.defaultUnsafeReminderReason()
                    : cleanBody,
              ],
      });
    }

    final merged = <String, Map<String, dynamic>>{};

    for (final item in [...existingItems, ...incomingItems]) {
      final homeId = item["homeId"]?.toString().trim() ?? "";

      final homeName = item["homeName"]?.toString().trim().isNotEmpty == true
          ? item["homeName"].toString().trim()
          : strings.defaultHomeName();

      final key = homeId.isNotEmpty ? homeId : homeName.toLowerCase();

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
        () => {"homeId": homeId, "homeName": homeName, "reasons": <String>[]},
      );

      final currentReasons = List<String>.from(current["reasons"] as List);

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
        ? mergedItems.first["homeName"]?.toString() ?? strings.defaultHomeName()
        : "SafeHome Reminder";

    if (!hasUnsafe) {
      lastScheduleBody = strings.safetyReminderBody(isSafe: true);
      return;
    }

    final issueLines = <String>[];

    for (final item in mergedItems) {
      final reasons = item["reasons"];

      if (reasons is! List || reasons.isEmpty) continue;

      final homeName = item["homeName"]?.toString() ?? strings.defaultHomeName();

      issueLines.add("$homeName: ${reasons.join(", ")}");
    }

    lastScheduleBody = "⚠️ ${strings.unsafeStatusTitle()}\n${issueLines.join("\n")}";
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
            settings: const RouteSettings(name: reminderRouteName),
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

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await localNotif.initialize(
      const InitializationSettings(
        android: AndroidNotificationConfig.initializationSettings,
        iOS: ios,
      ),
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload ?? '';

        if (_handleHomeChatPayload(payload)) {
          return;
        }

        if (await handleAlarmNotificationPayload(payload)) {
          return;
        }

        if (payload.startsWith('alarm_summary|')) {
          final strings = _strings;
          final parts = payload.split('|');
          final body = parts.length > 1
              ? Uri.decodeComponent(parts[1])
              : strings.alarmFallback;

          final alarmItems = parts.length > 2
              ? Uri.decodeComponent(parts[2])
              : '';

          openAlarmPage(
            title: '🚨 SafeHome',
            body: body,
            alarmItemsJson: alarmItems,
          );

          return;
        }

        if (payload == 'alarm') {
          openAlarmPage(
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
          await stopReminderNotification();
          return;
        }
      },
    );

    final launchDetails = await localNotif.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp == true) {
      final launchPayload = launchDetails?.notificationResponse?.payload ?? '';

      final handledChat = _handleHomeChatPayload(launchPayload);

      final handledAlarm = handledChat
          ? false
          : await handleAlarmNotificationPayload(launchPayload);

      if (!handledChat &&
          !handledAlarm &&
          (launchPayload == 'open_home' ||
              launchPayload == 'schedule_notification' ||
              launchPayload.startsWith('schedule_notification::') ||
              launchPayload.startsWith('schedule_notification|'))) {
        await stopReminderNotification();
      }
    }

    await AndroidNotificationConfig.configure(localNotif);
  }

  static const String alarmRouteName = 'fullscreen_alarm';

  static bool _alarmPageOpen = false;

  static final ValueNotifier<int> alarmRevision = ValueNotifier<int>(0);

  static final List<Map<String, dynamic>> activeAlarmItems = [];

  static void markAlarmPageClosed() {
    _alarmPageOpen = false;
  }

  static String _alarmKey(Map<String, dynamic> item) {
    return [
      item['homeName'] ?? '',
      item['deviceId'] ?? '',
      item['deviceName'] ?? item['name'] ?? '',
      item['type'] ?? '',
      item['reason'] ?? '',
    ].join('|');
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

  static void _openPendingAlarmPage() {
    final data = _pendingAlarmOpenData;

    if (data == null) return;

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) {
      _pendingAlarmOpenTimer?.cancel();
      _pendingAlarmOpenTimer = Timer(
        const Duration(milliseconds: 300),
        _openPendingAlarmPage,
      );
      return;
    }

    _pendingAlarmOpenData = null;
    _pendingAlarmOpenTimer?.cancel();
    _pendingAlarmOpenTimer = null;

    openAlarmPage(
      title: data['title']?.toString() ?? '🚨 SafeHome',
      body: data['body']?.toString() ?? lastAlarmBody,
      alarmItemsJson: data['alarmItemsJson']?.toString() ?? '',
      incidentId: data['incidentId']?.toString() ?? '',
      receiverUid: data['receiverUid']?.toString() ?? '',
      ownerUid: data['ownerUid']?.toString() ?? '',
      homeId: data['homeId']?.toString() ?? '',
      flowType: data['flowType']?.toString() ?? '',
    );
  }

  static void openAlarmPage({
    required String title,
    required String body,
    String alarmItemsJson = '',
    String incidentId = '',
    String receiverUid = '',
    String ownerUid = '',
    String homeId = '',
    String flowType = '',
  }) {
    if (incidentId.trim().isNotEmpty) {
      rememberAlarmIncident({
        'incidentId': incidentId,
        'receiverUid': receiverUid,
        'ownerUid': ownerUid,
        'homeId': homeId,
        'alarmFlowType': flowType,
      });
    }

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

    if (navigator == null) {
      _pendingAlarmOpenData = {
        'title': title,
        'body': body,
        'alarmItemsJson': alarmItemsJson,
        'incidentId': incidentId,
        'receiverUid': receiverUid,
        'ownerUid': ownerUid,
        'homeId': homeId,
        'flowType': flowType,
      };

      _pendingAlarmOpenTimer?.cancel();
      _pendingAlarmOpenTimer = Timer(
        const Duration(milliseconds: 300),
        _openPendingAlarmPage,
      );
      return;
    }

    _alarmPageOpen = true;

    navigator
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(name: alarmRouteName),
            builder: (_) => FullscreenAlarmPage(
              title: title,
              body: lastAlarmBody,
              alarmItemsJson: lastAlarmItemsJson,
            ),
          ),
        )
        .whenComplete(markAlarmPageClosed);
  }

  static void clearActiveAlarms({bool clearIncidentContexts = true}) {
    activeAlarmItems.clear();
    lastAlarmItemsJson = '';
    lastAlarmBody = _strings.alarmBody;

    if (clearIncidentContexts) {
      _activeAlarmIncidentContexts.clear();
    }
  }

  static Future<void> showSafetyReminder({
    required bool isSafe,
    String reason = '',
    String reminderItemsJson = '',
    String title = '',
    bool forceShow = false,
  }) async {
    final strings = _strings;
    final cleanReason = reason.trim();
    final cleanTitle = title.trim();

    final reminderBody = strings.safetyReminderBody(
      isSafe: isSafe,
      reason: cleanReason,
    );

    // Chỉ gộp dữ liệu để cập nhật cùng notification.
    // Không mở trang Reminder toàn màn hình.
    _mergeReminderSession(
      title: cleanTitle.isNotEmpty ? cleanTitle : strings.defaultHomeName(),
      body: reminderBody,
      isSafe: isSafe,
      reminderItemsJson: reminderItemsJson,
    );

    final notificationTitle = strings.safetyReminderNotificationTitle(
      homeTitle: lastScheduleTitle.trim().isEmpty
          ? "SafeHome"
          : lastScheduleTitle,
      isSafe: isSafe,
    );

    final notificationBody = isSafe
        ? strings.safeReminderBody()
        : strings.unsafeReminderBody(cleanReason);

    final androidDetails = AndroidNotificationConfig.reminderDetails(
      title: notificationTitle,
      body: notificationBody,
      bigText: lastScheduleBody,
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
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'open_home',
    );
  }
}
