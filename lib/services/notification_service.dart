import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app/safe_home_app.dart';
import '../helpers/top_toast.dart';
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

  static String localizedExactTextOrRaw(String raw, AppStrings strings) {
    final clean = raw.trim();

    if (clean.isEmpty) {
      return "";
    }

    final exact = strings.t(clean);
    if (exact != clean) {
      return exact;
    }

    const newMessageInPrefix = "Tin nhắn mới trong ";
    if (clean.startsWith(newMessageInPrefix)) {
      final homeName = clean.replaceFirst(newMessageInPrefix, "").trim();
      if (homeName.isNotEmpty) {
        return strings.newMessageInHome(homeName);
      }
    }

    const sentMessageSuffix = " đã gửi một tin nhắn";
    if (clean.endsWith(sentMessageSuffix)) {
      final senderName = clean.replaceFirst(sentMessageSuffix, "").trim();
      if (senderName.isNotEmpty) {
        return strings.homeChatSenderMessage(senderName);
      }
    }

    return strings.statusText(clean);
  }

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

  static List<Map<String, dynamic>> _alarmItemsFromValue(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (decoded is Map) {
        return [Map<String, dynamic>.from(decoded)];
      }
    } catch (_) {}

    return const [];
  }

  static List<Map<String, dynamic>> _alarmItemsFromData(
    Map<String, dynamic> data,
  ) {
    final directItems = _alarmItemsFromValue(data['alarmItems']);

    if (directItems.isNotEmpty) {
      return directItems;
    }

    return _alarmItemsFromValue(data['alarmItemsJson']);
  }

  static String localizedAlarmBodyForData(
    Map<String, dynamic> data,
    AppStrings strings,
  ) {
    final items = _alarmItemsFromData(data);
    final lines = <String>[];

    for (final item in items) {
      final deviceName =
          item['deviceName']?.toString().trim().isNotEmpty == true
          ? item['deviceName'].toString().trim()
          : item['name']?.toString().trim() ?? '';
      final reason = item['reason']?.toString().trim() ?? '';
      final translatedReason = reason.isEmpty ? '' : strings.statusText(reason);

      String line = '';

      if (deviceName.isNotEmpty && translatedReason.isNotEmpty) {
        line =
            translatedReason.toLowerCase().startsWith(
              '${deviceName.toLowerCase()}:',
            )
            ? translatedReason
            : '$deviceName: $translatedReason';
      } else if (translatedReason.isNotEmpty) {
        line = translatedReason;
      } else if (deviceName.isNotEmpty) {
        line = deviceName;
      }

      if (line.isNotEmpty && !lines.contains(line)) {
        lines.add(line);
      }
    }

    if (lines.isNotEmpty) {
      return lines.join('\n');
    }

    final rawBody = data['body']?.toString().trim() ?? '';

    if (rawBody.isEmpty) {
      return strings.alarmBody;
    }

    return strings.statusText(rawBody);
  }

  static String localizedNotificationTitle(
    String rawTitle,
    AppStrings strings,
    String fallback,
  ) {
    final cleanTitle = rawTitle.trim();

    if (cleanTitle.isEmpty) {
      return fallback;
    }

    final lowerTitle = cleanTitle.toLowerCase();
    if (lowerTitle.contains('safehome') ||
        const {
          'alarm',
          'reminder',
          'sos',
          'hub',
          'qr',
          'fcm',
          'uid',
          'firebase',
          'app check',
          'camera',
        }.contains(lowerTitle)) {
      return cleanTitle;
    }

    return strings.t(cleanTitle);
  }

  static String normalizedIncidentEventCategory(Map<String, dynamic> data) {
    final direct = data['eventCategory']?.toString().trim().toLowerCase() ?? '';

    if (direct == 'emergency' ||
        direct == 'security' ||
        direct == 'system_warning') {
      return direct;
    }

    final flow =
        data['alarmFlowType']?.toString().trim().toLowerCase() ??
        data['flowType']?.toString().trim().toLowerCase() ??
        '';

    if (flow == 'emergency') return 'emergency';
    if (flow == 'security') return 'security';

    final level = data['alarmLevel']?.toString().trim().toLowerCase() ?? '';
    if (level == 'emergency') return 'emergency';
    if (level == 'alarm') return 'security';

    return 'security';
  }

  static String normalizedIncidentAlarmLevel(Map<String, dynamic> data) {
    final direct = data['alarmLevel']?.toString().trim().toLowerCase() ?? '';

    if ({'info', 'warning', 'alarm', 'emergency'}.contains(direct)) {
      return direct;
    }

    final category = normalizedIncidentEventCategory(data);
    if (category == 'emergency') return 'emergency';
    if (category == 'system_warning') return 'warning';

    final severity = data['severity']?.toString().trim().toLowerCase() ?? '';
    if (severity == 'critical') return 'emergency';

    return 'alarm';
  }

  static String normalizedIncidentStatus(Map<String, dynamic> data) {
    final status =
        data['incidentStatus']?.toString().trim().toLowerCase() ??
        data['status']?.toString().trim().toLowerCase() ??
        '';

    return status.isEmpty ? 'active' : status;
  }

  static void _syncAlarmPresentationFromActiveIncidents() {
    if (_activeAlarmIncidentContexts.isEmpty) {
      lastAlarmEventCategory = '';
      lastAlarmLevel = '';
      return;
    }

    final contexts = _activeAlarmIncidentContexts.values;
    final hasEmergency = contexts.any(
      (context) =>
          context['eventCategory'] == 'emergency' ||
          context['alarmLevel'] == 'emergency',
    );

    if (hasEmergency) {
      lastAlarmEventCategory = 'emergency';
      lastAlarmLevel = 'emergency';
      return;
    }

    final hasAlarm = contexts.any(
      (context) => context['alarmLevel'] == 'alarm',
    );

    lastAlarmEventCategory = 'security';
    lastAlarmLevel = hasAlarm ? 'alarm' : 'warning';
  }

  static void rememberAlarmIncident(Map<String, dynamic> data) {
    final incidentId = data['incidentId']?.toString().trim() ?? '';

    if (incidentId.isEmpty) return;

    final status = normalizedIncidentStatus(data);

    if (status != 'active') {
      _activeAlarmIncidentContexts.remove(incidentId);
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final receiverUid =
        data['receiverUid']?.toString().trim().isNotEmpty == true
        ? data['receiverUid'].toString().trim()
        : currentUid;

    final ownerUid = data['ownerUid']?.toString().trim() ?? '';
    final homeId = data['homeId']?.toString().trim() ?? '';
    final eventCategory = normalizedIncidentEventCategory(data);
    final alarmLevel = normalizedIncidentAlarmLevel(data);
    final flowType = data['alarmFlowType']?.toString().trim().isNotEmpty == true
        ? data['alarmFlowType'].toString().trim()
        : eventCategory;

    // Mỗi người chỉ giữ incident mới nhất của cùng một nhà
    // và cùng nhóm sự kiện. Incident cũ đã superseded
    // không được gửi xác nhận lại.
    final supersededIncidentIds = <String>{};

    if (homeId.isNotEmpty && eventCategory.isNotEmpty) {
      _activeAlarmIncidentContexts.removeWhere((oldIncidentId, context) {
        if (oldIncidentId == incidentId) {
          return false;
        }

        final shouldRemove =
            context['receiverUid'] == receiverUid &&
            context['homeId'] == homeId &&
            context['eventCategory'] == eventCategory;

        if (shouldRemove) {
          supersededIncidentIds.add(oldIncidentId);
        }

        return shouldRemove;
      });
    }

    if (supersededIncidentIds.isNotEmpty) {
      activeAlarmItems.removeWhere(
        (item) => supersededIncidentIds.contains(
          item['incidentId']?.toString().trim() ?? '',
        ),
      );
    }

    _activeAlarmIncidentContexts[incidentId] = {
      'incidentId': incidentId,
      'receiverUid': receiverUid,
      'ownerUid': ownerUid,
      'homeId': homeId,
      'flowType': flowType,
      'eventCategory': eventCategory,
      'alarmLevel': alarmLevel,
      'status': status,
    };

    _syncAlarmPresentationFromActiveIncidents();
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

  static bool _isValidHubId(String value) {
    return RegExp(r'^dev_[a-f0-9]{16}$').hasMatch(value);
  }

  static Future<String> _resolveHomeHubId({
    required String requestedBy,
    required String homeId,
    required String fallbackHubId,
  }) async {
    try {
      String ownerUid = requestedBy;

      final ownHomeSnap = await FirebaseDatabase.instance
          .ref('accounts/$requestedBy/homes/$homeId')
          .get();

      DataSnapshot homeSnap = ownHomeSnap;

      if (!ownHomeSnap.exists) {
        final sharedHomeSnap = await FirebaseDatabase.instance
            .ref('accounts/$requestedBy/sharedHomes/$homeId')
            .get();
        final sharedHome = sharedHomeSnap.value;

        if (sharedHome is Map) {
          ownerUid = sharedHome['ownerUid']?.toString().trim() ?? '';
        }

        if (ownerUid.isNotEmpty) {
          homeSnap = await FirebaseDatabase.instance
              .ref('accounts/$ownerUid/homes/$homeId')
              .get();
        }
      }

      final rawHome = homeSnap.value;

      if (rawHome is Map) {
        final databaseHubId = rawHome['hubId']?.toString().trim() ?? '';

        if (_isValidHubId(databaseHubId)) {
          return databaseHubId;
        }
      }
    } catch (error) {
      safeDebugPrint('HOME SIREN HUB RESOLVE ERROR: $error');
    }

    final cleanFallbackHubId = fallbackHubId.trim();
    return _isValidHubId(cleanFallbackHubId) ? cleanFallbackHubId : '';
  }

  static Future<bool> muteHomeSiren({
    required String homeId,
    required String hubId,
  }) async {
    final requestedBy = FirebaseAuth.instance.currentUser?.uid ?? '';
    final cleanHomeId = homeId.trim();

    if (requestedBy.isEmpty || cleanHomeId.isEmpty) {
      return false;
    }

    final resolvedHubId = await _resolveHomeHubId(
      requestedBy: requestedBy,
      homeId: cleanHomeId,
      fallbackHubId: hubId,
    );

    if (resolvedHubId.isEmpty) {
      return false;
    }

    final ref = FirebaseDatabase.instance
        .ref('home_siren_action_requests')
        .push();
    final result = Completer<bool>();
    StreamSubscription<DatabaseEvent>? subscription;

    try {
      await ref.set({
        'status': 'pending',
        'homeId': cleanHomeId,
        'hubId': resolvedHubId,
        'requestedBy': requestedBy,
        'action': 'mute',
        'createdAt': ServerValue.timestamp,
      });

      // Chỉ mở listener sau khi node đã tồn tại, vì Firebase Rules đọc dựa
      // trên requestedBy. Backend giữ kết quả 30 giây nên không có race.
      subscription = ref.onValue.listen(
        (event) {
          final raw = event.snapshot.value;

          if (raw is! Map || result.isCompleted) {
            return;
          }

          final status = raw['status']?.toString().trim() ?? '';

          if (status == 'succeeded') {
            result.complete(true);
          } else if (status == 'failed' || status == 'rejected') {
            result.complete(false);
          }
        },
        onError: (Object error) {
          safeDebugPrint('HOME SIREN RESULT LISTENER ERROR: $error');

          if (!result.isCompleted) {
            result.complete(false);
          }
        },
      );

      return await result.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => false,
      );
    } catch (error) {
      safeDebugPrint('HOME SIREN MUTE REQUEST ERROR: $error');
      return false;
    } finally {
      final activeSubscription = subscription;

      if (activeSubscription != null) {
        await activeSubscription.cancel();
      }
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

  static Future<bool> muteActiveHomeSirens({String incidentId = ''}) async {
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

    if (targets.isEmpty) {
      return false;
    }

    // Một request cho mỗi Home là đủ. Backend sẽ snapshot toàn bộ incident
    // đang active trong Home và tắt tất cả còi vật lý của Home đó.
    final processedHomes = <String>{};

    for (final target in targets) {
      final ownerUid = target['ownerUid'] ?? '';
      final homeId = target['homeId'] ?? '';
      final fallbackIncidentId = target['incidentId'] ?? '';

      if (fallbackIncidentId.isEmpty) {
        return false;
      }

      final homeKey = ownerUid.isNotEmpty && homeId.isNotEmpty
          ? '$ownerUid|$homeId'
          : 'incident:$fallbackIncidentId';

      if (!processedHomes.add(homeKey)) {
        continue;
      }

      final ok = await _sendAlarmIncidentAction(
        incidentId: fallbackIncidentId,
        receiverUid: target['receiverUid'] ?? '',
        action: 'mute_siren',
      );

      if (!ok) {
        return false;
      }
    }

    return true;
  }

  static Future<void> showPriorityAlarmNotification({
    required Map<String, dynamic> data,
  }) async {
    rememberAlarmIncident(data);
    final strings = _strings;

    final title = localizedNotificationTitle(
      data['title']?.toString() ?? '',
      strings,
      strings.priorityAlarmNotificationTitle(),
    );

    final body = localizedAlarmBodyForData(data, strings);

    final payload = 'priority_alarm::${jsonEncode(data)}';

    final androidDetails = AndroidNotificationConfig.priorityAlarmDetails(
      title: title,
      body: body,
      strings: strings,
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

    // Chạm vào notification chỉ mở ứng dụng để kiểm tra.
    // Không được gửi check_home/stop vì incident phải tiếp tục
    // cho tới khi cảm biến an toàn hoặc người dùng chủ động tắt.
    await reconcileActiveAlarmIncidents();
  }

  static Future<void> handleAlarmResolved(Map<String, dynamic> data) async {
    final incidentId = data['incidentId']?.toString().trim() ?? '';
    final action =
        data['resolutionAction']?.toString().trim().isNotEmpty == true
        ? data['resolutionAction'].toString().trim()
        : data['action']?.toString().trim() ?? 'resolved';
    final resolvedMessage = _strings.alarmIncidentResolvedMessage(action);

    if (incidentId.isNotEmpty) {
      _activeAlarmIncidentContexts.remove(incidentId);
      activeAlarmItems.removeWhere(
        (item) => item['incidentId']?.toString().trim() == incidentId,
      );
    } else {
      _activeAlarmIncidentContexts.clear();
      activeAlarmItems.clear();
    }

    _syncAlarmPresentationFromActiveIncidents();
    lastAlarmItemsJson = activeAlarmItems.isEmpty
        ? ''
        : jsonEncode(activeAlarmItems);

    if (_activeAlarmIncidentContexts.isEmpty) {
      await stopAllAlarmNotifications();
      clearActiveAlarms(clearIncidentContexts: false);
      alarmResolvedRevision.value++;
    } else {
      // Còn incident khác đang hoạt động: chỉ cập nhật nội dung màn hình,
      // tuyệt đối không tắt notification/âm thanh của sự cố còn lại.
      alarmRevision.value++;
    }

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        final context = appNavigatorKey.currentContext;

        if (context == null) return;

        showTopToast(
          context,
          resolvedMessage,
          color: Colors.green.shade700,
          icon: Icons.check_circle_rounded,
        );
      }),
    );
  }

  static Future<bool> reconcileActiveAlarmIncidents() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUid.isEmpty || _activeAlarmIncidentContexts.isEmpty) {
      return _activeAlarmIncidentContexts.isNotEmpty;
    }

    final incidentIds = List<String>.from(_activeAlarmIncidentContexts.keys);
    var removedAny = false;

    for (final incidentId in incidentIds) {
      final context = _activeAlarmIncidentContexts[incidentId];
      final receiverUid = context?['receiverUid']?.trim().isNotEmpty == true
          ? context!['receiverUid']!.trim()
          : currentUid;

      if (receiverUid != currentUid) {
        _activeAlarmIncidentContexts.remove(incidentId);
        removedAny = true;
        continue;
      }

      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('accounts/$receiverUid/alarmIncidents/$incidentId/status')
            .get();
        final status = snapshot.value?.toString().trim() ?? '';

        if (status != 'active') {
          _activeAlarmIncidentContexts.remove(incidentId);
          removedAny = true;
        }
      } catch (error) {
        // Fail-safe: khi chưa đọc được Firebase, giữ incident hiện tại
        // để không vô tình tắt Alarm thật.
        safeDebugPrint('ALARM INCIDENT RECONCILE ERROR: $error');
      }
    }

    if (_activeAlarmIncidentContexts.isEmpty && removedAny) {
      await stopAllAlarmNotifications();
      clearActiveAlarms(clearIncidentContexts: false);
      alarmResolvedRevision.value++;
    }

    return _activeAlarmIncidentContexts.isNotEmpty;
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
      title: localizedNotificationTitle(
        data['title']?.toString() ?? '',
        strings,
        '🚨 SafeHome',
      ),
      body: localizedAlarmBodyForData(data, strings),
      alarmItemsJson:
          data['alarmItems']?.toString() ??
          data['alarmItemsJson']?.toString() ??
          '',
      incidentId: data['incidentId']?.toString() ?? '',
      receiverUid: data['receiverUid']?.toString() ?? '',
      ownerUid: data['ownerUid']?.toString() ?? '',
      homeId: data['homeId']?.toString() ?? '',
      flowType: data['alarmFlowType']?.toString() ?? '',
      eventCategory: normalizedIncidentEventCategory(data),
      alarmLevel: normalizedIncidentAlarmLevel(data),
    );
  }

  static Future<void> showSensorNotification({
    required Map<String, dynamic> data,
  }) async {
    final strings = _strings;
    final homeId = data['homeId']?.toString().trim() ?? '';
    final deviceId = data['deviceId']?.toString().trim() ?? '';
    final rawTitle = data['title']?.toString().trim() ?? '';
    final rawBody = data['body']?.toString().trim() ?? '';
    final title = rawTitle.isNotEmpty
        ? localizedExactTextOrRaw(rawTitle, strings)
        : strings.t('Thông báo cảm biến');
    final body = rawBody.isNotEmpty
        ? localizedExactTextOrRaw(rawBody, strings)
        : strings.t('Cảm biến vừa phát hiện một sự kiện.');
    final identity = '$homeId|$deviceId';

    final androidDetails = AndroidNotificationConfig.sensorNotificationDetails(
      title: title,
      body: body,
      strings: strings,
      tag: 'safehome_sensor_${homeId}_$deviceId',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await localNotif.show(
      _sensorNotificationId(identity),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'sensor_notification::$homeId',
    );
  }

  static int _sensorNotificationId(String identity) {
    var hash = 0;

    for (final codeUnit in identity.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return 1200000 + (hash % 700000);
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
        ? localizedExactTextOrRaw(rawTitle, strings)
        : unreadCount > 1
        ? "${homeName.isNotEmpty ? homeName : "HomeChat"} · "
              "${strings.homeChatNewMessages(unreadCount)}"
        : homeName.isNotEmpty
        ? homeName
        : strings.homeChatTitle();

    final body = rawBody.isNotEmpty
        ? localizedExactTextOrRaw(rawBody, strings)
        : senderName.isNotEmpty
        ? strings.homeChatSenderMessage(senderName)
        : strings.homeChatNewMessage();

    final androidDetails = AndroidNotificationConfig.chatDetails(
      title: title,
      body: body,
      strings: strings,
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
  static String lastAlarmEventCategory = "";
  static String lastAlarmLevel = "";
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
      final translatedCleanBody = cleanBody.isEmpty
          ? ""
          : strings.statusText(cleanBody);

      incomingItems.add({
        "homeId": "",
        "homeName": title.trim().isEmpty
            ? strings.defaultHomeName()
            : title.trim(),
        "reasons": isSafe
            ? <String>[]
            : <String>[
                translatedCleanBody.isEmpty
                    ? strings.defaultUnsafeReminderReason()
                    : translatedCleanBody,
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
          final translatedText = text.isEmpty ? "" : strings.statusText(text);

          if (translatedText.isNotEmpty && !reasons.contains(translatedText)) {
            reasons.add(translatedText);
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
        : strings.scheduledReminder;

    if (!hasUnsafe) {
      lastScheduleBody = strings.safetyReminderBody(isSafe: true);
      return;
    }

    final issueLines = <String>[];

    for (final item in mergedItems) {
      final reasons = item["reasons"];

      if (reasons is! List || reasons.isEmpty) continue;

      final homeName =
          item["homeName"]?.toString() ?? strings.defaultHomeName();

      issueLines.add("$homeName: ${reasons.join(", ")}");
    }

    lastScheduleBody =
        "⚠️ ${strings.unsafeStatusTitle()}\n${issueLines.join("\n")}";
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

    // [iOS] Tắt hiển thị APNs tự động khi app đang foreground.
    // onMessage bên dưới sẽ tạo đúng một local notification đã bản địa hoá.
    // Android không bị ảnh hưởng bởi tuỳ chọn này.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: false,
          sound: false,
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
          final rawBody = parts.length > 1
              ? Uri.decodeComponent(parts[1])
              : strings.alarmFallback;

          final alarmItems = parts.length > 2
              ? Uri.decodeComponent(parts[2])
              : '';
          final alarmData = {'body': rawBody, 'alarmItemsJson': alarmItems};

          openAlarmPage(
            title: '🚨 SafeHome',
            body: localizedAlarmBodyForData(alarmData, strings),
            alarmItemsJson: alarmItems,
          );

          return;
        }

        if (payload == 'alarm') {
          final strings = _strings;
          final alarmData = {
            'body': lastAlarmBody,
            'alarmItemsJson': lastAlarmItemsJson,
          };

          openAlarmPage(
            title: '🚨 SafeHome',
            body: localizedAlarmBodyForData(alarmData, strings),
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

    await AndroidNotificationConfig.configure(localNotif, strings: _strings);
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

    final strings = _strings;

    openAlarmPage(
      title: localizedNotificationTitle(
        data['title']?.toString() ?? '',
        strings,
        '🚨 SafeHome',
      ),
      body: localizedAlarmBodyForData(data, strings),
      alarmItemsJson: data['alarmItemsJson']?.toString() ?? '',
      incidentId: data['incidentId']?.toString() ?? '',
      receiverUid: data['receiverUid']?.toString() ?? '',
      ownerUid: data['ownerUid']?.toString() ?? '',
      homeId: data['homeId']?.toString() ?? '',
      flowType: data['flowType']?.toString() ?? '',
      eventCategory: data['eventCategory']?.toString() ?? '',
      alarmLevel: data['alarmLevel']?.toString() ?? '',
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
    String eventCategory = '',
    String alarmLevel = '',
  }) {
    if (incidentId.trim().isNotEmpty) {
      rememberAlarmIncident({
        'incidentId': incidentId,
        'receiverUid': receiverUid,
        'ownerUid': ownerUid,
        'homeId': homeId,
        'alarmFlowType': flowType,
        'eventCategory': eventCategory,
        'alarmLevel': alarmLevel,
        'incidentStatus': 'active',
      });
    }

    lastAlarmBody = body;
    final incidentData = <String, dynamic>{
      'alarmFlowType': flowType,
      'eventCategory': eventCategory,
      'alarmLevel': alarmLevel,
    };
    lastAlarmEventCategory = normalizedIncidentEventCategory(incidentData);
    lastAlarmLevel = normalizedIncidentAlarmLevel(incidentData);
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
        'eventCategory': eventCategory,
        'alarmLevel': alarmLevel,
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
              eventCategory: eventCategory,
              alarmLevel: alarmLevel,
            ),
          ),
        )
        .whenComplete(markAlarmPageClosed);
  }

  static void clearActiveAlarms({bool clearIncidentContexts = true}) {
    activeAlarmItems.clear();
    lastAlarmItemsJson = '';
    lastAlarmBody = _strings.alarmBody;
    lastAlarmEventCategory = '';
    lastAlarmLevel = '';

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
    final localizedTitle = cleanTitle == "Nhà"
        ? strings.defaultHomeName()
        : cleanTitle;

    final reminderBody = strings.safetyReminderBody(
      isSafe: isSafe,
      reason: cleanReason,
    );

    // Chỉ gộp dữ liệu để cập nhật cùng notification.
    // Không mở trang Reminder toàn màn hình.
    _mergeReminderSession(
      title: localizedTitle.isNotEmpty
          ? localizedTitle
          : strings.defaultHomeName(),
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
      strings: strings,
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
