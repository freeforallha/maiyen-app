import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app/safe_home_app.dart';
import '../helpers/top_toast.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import '../pages/fullscreen_alarm_page.dart';
import 'platform/android/android_notification_config.dart';
import 'platform/ios/ios_notification_config.dart';
import 'package:safehome_app/helpers/debug_log.dart';

final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static AppStrings get _strings =>
      AppStrings.fromLocale(appLanguageController.locale);

  static final ValueNotifier<Map<String, String>?> chatOpenRequest =
      ValueNotifier<Map<String, String>?>(null);

  static String homeChatPayload({
    required String homeId,
    required String homeName,
    required String ownerUid,
    required String messageId,
  }) {
    return 'home_chat::${jsonEncode({"homeId": homeId, "homeName": homeName, "ownerUid": ownerUid, "messageId": messageId})}';
  }

  static int homeChatNotificationId(String homeId) {
    var hash = 0;

    for (final codeUnit in homeId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return 200000 + (hash % 700000);
  }

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

    unawaited(localNotif.cancel(homeChatNotificationId(cleanHomeId)));
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
  static final Map<String, Future<Map<String, dynamic>?>>
  _alarmPayloadValidationInFlight = {};
  static final Map<String, int> _presentedAlarmDeliveryAt = {};
  static final Map<String, int> _locallySuppressedAlarmIncidentAt = {};
  static const int _alarmDeliveryDedupeWindowMs = 24 * 60 * 60 * 1000;
  static const int _localAlarmIncidentSuppressionMs = 30 * 60 * 1000;
  static const int _alarmDeliveryDedupeMaxEntries = 300;

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

  static String _alarmDeliveryKey(Map<String, dynamic> data) {
    final direct = data['alarmDeliveryId']?.toString().trim() ?? '';

    if (direct.isNotEmpty) {
      return direct;
    }

    final itemKeys = _alarmItemsFromData(data)
        .map((item) {
          return [
            item['incidentId'] ?? data['incidentId'] ?? '',
            item['homeId'] ?? data['homeId'] ?? '',
            item['deviceId'] ?? '',
            item['type'] ?? '',
            item['reason'] ?? '',
          ].join('|');
        })
        .toList()
      ..sort();

    return [
      data['receiverUid'] ?? '',
      data['incidentId'] ?? '',
      data['alarmStage'] ?? '',
      data['type'] ?? '',
      ...itemKeys,
    ].join('||');
  }

  static bool _markAlarmDeliveryPresented(Map<String, dynamic> data) {
    final key = _alarmDeliveryKey(data).trim();

    if (key.isEmpty) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _presentedAlarmDeliveryAt.removeWhere(
      (_, timestamp) => now - timestamp > _alarmDeliveryDedupeWindowMs,
    );

    final previous = _presentedAlarmDeliveryAt[key];

    if (previous != null && now - previous <= _alarmDeliveryDedupeWindowMs) {
      return false;
    }

    _presentedAlarmDeliveryAt[key] = now;

    if (_presentedAlarmDeliveryAt.length > _alarmDeliveryDedupeMaxEntries) {
      final oldestKeys = _presentedAlarmDeliveryAt.entries.toList()
        ..sort((first, second) => first.value.compareTo(second.value));

      for (final entry in oldestKeys.take(
        _presentedAlarmDeliveryAt.length - _alarmDeliveryDedupeMaxEntries,
      )) {
        _presentedAlarmDeliveryAt.remove(entry.key);
      }
    }

    return true;
  }

  static bool _dropAlarmIncidentLocally(String incidentId) {
    final cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      return false;
    }

    final removedContext =
        _activeAlarmIncidentContexts.remove(cleanIncidentId) != null;
    final oldLength = activeAlarmItems.length;

    activeAlarmItems.removeWhere(
      (item) => item['incidentId']?.toString().trim() == cleanIncidentId,
    );

    final removedItems = activeAlarmItems.length != oldLength;

    if (removedContext || removedItems) {
      _syncAlarmPresentationFromActiveIncidents();
      lastAlarmItemsJson = activeAlarmItems.isEmpty
          ? ''
          : jsonEncode(activeAlarmItems);
    }

    return removedContext || removedItems;
  }

  static Future<String> _restoredAlarmUserUid() async {
    final immediateUid =
        FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

    if (immediateUid.isNotEmpty) {
      return immediateUid;
    }

    try {
      final restoredUser = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

      return restoredUser?.uid.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool _isUnverifiedAlarmPayloadStale(
    Map<String, dynamic> data,
  ) {
    final sentAt = int.tryParse(data['sentAt']?.toString() ?? '') ?? 0;

    if (sentAt <= 0) {
      return false;
    }

    return DateTime.now().millisecondsSinceEpoch - sentAt >
        const Duration(minutes: 2).inMilliseconds;
  }

  static bool _isAlarmIncidentLocallySuppressed(String incidentId) {
    final cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _locallySuppressedAlarmIncidentAt.removeWhere(
      (_, timestamp) => now - timestamp > _localAlarmIncidentSuppressionMs,
    );

    return _locallySuppressedAlarmIncidentAt.containsKey(cleanIncidentId);
  }

  static void _suppressAlarmIncidentLocally(String incidentId) {
    final cleanIncidentId = incidentId.trim();

    if (cleanIncidentId.isEmpty) {
      return;
    }

    _locallySuppressedAlarmIncidentAt[cleanIncidentId] =
        DateTime.now().millisecondsSinceEpoch;
  }

  static Future<Map<String, dynamic>?> validateIncomingAlarmData(
    Map<String, dynamic> rawData, {
    bool updateLocalState = true,
  }) async {
    final data = Map<String, dynamic>.from(rawData);
    final incidentId = data['incidentId']?.toString().trim() ?? '';
    final explicitStatus = normalizedIncidentStatus(data);

    if (_isAlarmIncidentLocallySuppressed(incidentId)) {
      if (updateLocalState && incidentId.isNotEmpty) {
        _dropAlarmIncidentLocally(incidentId);
      }
      return null;
    }

    if (explicitStatus != 'active') {
      if (updateLocalState && incidentId.isNotEmpty) {
        _dropAlarmIncidentLocally(incidentId);
      }
      return null;
    }

    final currentUid = await _restoredAlarmUserUid();
    final payloadReceiverUid =
        data['receiverUid']?.toString().trim() ?? '';

    if (
      currentUid.isNotEmpty &&
      payloadReceiverUid.isNotEmpty &&
      payloadReceiverUid != currentUid
    ) {
      if (updateLocalState && incidentId.isNotEmpty) {
        _dropAlarmIncidentLocally(incidentId);
      }
      return null;
    }

    if (incidentId.isEmpty) {
      return data;
    }

    final receiverUid = payloadReceiverUid.isNotEmpty
        ? payloadReceiverUid
        : currentUid;

    if (receiverUid.isEmpty) {
      // Chỉ giữ fail-safe cho push vừa gửi. Payload nằm chờ lâu mà không xác
      // định được tài khoản không được phép tự mở lại Fullscreen cũ.
      return _isUnverifiedAlarmPayloadStale(data) ? null : data;
    }

    final validationKey =
        '$receiverUid|$incidentId|${updateLocalState ? 'local' : 'background'}';
    final inFlight = _alarmPayloadValidationInFlight[validationKey];

    if (inFlight != null) {
      return inFlight;
    }

    final validation = (() async {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('accounts/$receiverUid/alarmIncidents/$incidentId')
            .get();
        final rawIncident = snapshot.value;

        if (rawIncident is! Map) {
          if (updateLocalState) {
            _dropAlarmIncidentLocally(incidentId);
          }
          return null;
        }

        final incident = Map<String, dynamic>.from(rawIncident);
        final status =
            incident['status']?.toString().trim().toLowerCase() ?? '';
        final expireAt =
            int.tryParse(incident['expireAt']?.toString() ?? '') ?? 0;
        final isExpired =
            expireAt > 0 && expireAt <= DateTime.now().millisecondsSinceEpoch;
        final presentationSuppressedAt =
            int.tryParse(
              incident['presentationSuppressedAt']?.toString() ?? '',
            ) ??
            0;

        final incomingType =
            data['type']?.toString().trim().toLowerCase() ?? '';
        final incomingStage =
            data['alarmStage']?.toString().trim().toLowerCase() ?? '';
        final requestsFullscreen =
            incomingType == 'alarm_siren' ||
            incomingStage == 'siren' ||
            incomingStage == 'fullscreen_siren';

        // presentationSuppressedAt chỉ có nghĩa là người dùng đã đóng/đã xem
        // lần fullscreen hiện tại. Nó không được chặn notification báo lại
        // theo lịch 15/30/60 phút khi incident vẫn còn active.
        if (status != 'active' ||
            isExpired ||
            (presentationSuppressedAt > 0 && requestsFullscreen)) {
          if (updateLocalState) {
            _dropAlarmIncidentLocally(incidentId);
          }
          return null;
        }

        final freshData = Map<String, dynamic>.from(data);
        final incomingItems = _alarmItemsFromData(data);
        final freshIncidentItems = _alarmItemsFromValue(incident['items']);

        for (final item in freshIncidentItems) {
          item['incidentId'] = incidentId;
          item['homeId'] ??= incident['homeId']?.toString() ?? '';
          item['homeName'] ??= incident['homeName']?.toString() ?? '';
          item['ownerUid'] ??= incident['ownerUid']?.toString() ?? '';
        }

        // Fullscreen phải hiển thị toàn bộ điều kiện đang còn active. Riêng
        // notification gửi lại theo chu kỳ chỉ được giữ giao của payload lần
        // này với snapshot incident mới nhất. Nhờ vậy một lỗi đã được xử lý
        // không bị ghép trở lại chỉ vì incident của Home vẫn còn lỗi khác.
        final freshItems = requestsFullscreen
            ? freshIncidentItems
            : _freshAlarmItemsForDelivery(
                incomingItems: incomingItems,
                freshIncidentItems: freshIncidentItems,
              );

        if (!requestsFullscreen &&
            incomingItems.isNotEmpty &&
            freshItems.isEmpty) {
          return null;
        }

        freshData.remove('alarmItems');
        freshData.remove('alarmItemsJson');

        if (freshItems.isNotEmpty) {
          freshData['alarmItems'] = jsonEncode(freshItems);
          freshData['alarmItemsJson'] = jsonEncode(freshItems);
        }

        freshData['incidentId'] = incidentId;
        freshData['receiverUid'] = receiverUid;
        freshData['incidentStatus'] = 'active';
        freshData['homeId'] =
            incident['homeId']?.toString() ??
            freshData['homeId']?.toString() ??
            '';
        freshData['ownerUid'] =
            incident['ownerUid']?.toString() ??
            freshData['ownerUid']?.toString() ??
            '';
        freshData['alarmFlowType'] =
            incident['flowType']?.toString() ??
            freshData['alarmFlowType']?.toString() ??
            'security';
        freshData['eventCategory'] =
            incident['eventCategory']?.toString() ??
            freshData['eventCategory']?.toString() ??
            freshData['alarmFlowType']?.toString() ??
            'security';
        freshData['alarmLevel'] =
            incident['alarmLevel']?.toString() ??
            freshData['alarmLevel']?.toString() ??
            (freshData['alarmFlowType'] == 'emergency'
                ? 'emergency'
                : 'alarm');
        freshData['alarmStage'] =
            incident['stage']?.toString() ??
            freshData['alarmStage']?.toString() ??
            '';

        return freshData;
      } catch (error) {
        safeDebugPrint('ALARM PAYLOAD VALIDATION ERROR: $error');

        // Khi chưa xác minh được Firebase, chỉ fail-safe với push vừa gửi.
        // Payload đã nằm chờ quá lâu không được phép tự mở Fullscreen cũ.
        if (_isUnverifiedAlarmPayloadStale(data)) {
          if (updateLocalState) {
            _dropAlarmIncidentLocally(incidentId);
          }
          return null;
        }

        return data;
      } finally {
        _alarmPayloadValidationInFlight.remove(validationKey);
      }
    })();

    _alarmPayloadValidationInFlight[validationKey] = validation;
    return validation;
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

    final jsonItems = _alarmItemsFromValue(data['alarmItemsJson']);

    if (jsonItems.isNotEmpty) {
      return jsonItems;
    }

    final homeName = data['homeName']?.toString().trim() ?? '';
    final deviceName = data['deviceName']?.toString().trim().isNotEmpty == true
        ? data['deviceName'].toString().trim()
        : data['name']?.toString().trim() ?? '';
    final reason = data['reason']?.toString().trim().isNotEmpty == true
        ? data['reason'].toString().trim()
        : data['body']?.toString().trim() ?? '';

    if (homeName.isEmpty && deviceName.isEmpty && reason.isEmpty) {
      return const [];
    }

    return [
      {
        'incidentId': data['incidentId']?.toString().trim() ?? '',
        'homeId': data['homeId']?.toString().trim() ?? '',
        'homeName': homeName,
        'deviceId': data['deviceId']?.toString().trim() ?? '',
        'deviceName': deviceName,
        'type': data['deviceType']?.toString().trim().isNotEmpty == true
            ? data['deviceType'].toString().trim()
            : data['type']?.toString().trim() ?? '',
        'reason': reason,
        'nextAlarm': data['nextAlarm']?.toString().trim() ?? '',
      },
    ];
  }

  static String _alarmConditionKey(Map<String, dynamic> item) {
    final homeId = item['homeId']?.toString().trim() ?? '';
    final deviceId = item['deviceId']?.toString().trim() ?? '';
    final deviceName =
        item['deviceName']?.toString().trim().isNotEmpty == true
        ? item['deviceName'].toString().trim()
        : item['name']?.toString().trim() ?? '';
    final type = item['type']?.toString().trim() ?? '';
    final reason = item['reason']?.toString().trim() ?? '';

    return [
      homeId,
      deviceId.isNotEmpty ? deviceId : deviceName,
      type,
      reason,
    ].join('|');
  }

  static List<Map<String, dynamic>> _freshAlarmItemsForDelivery({
    required List<Map<String, dynamic>> incomingItems,
    required List<Map<String, dynamic>> freshIncidentItems,
  }) {
    if (incomingItems.isEmpty) {
      return freshIncidentItems;
    }

    final requestedKeys = incomingItems
        .map(_alarmConditionKey)
        .where((key) => key.isNotEmpty)
        .toSet();

    return freshIncidentItems
        .where((item) => requestedKeys.contains(_alarmConditionKey(item)))
        .toList();
  }

  static String _alarmItemsJsonFromData(Map<String, dynamic> data) {
    final items = _alarmItemsFromData(data);
    return items.isEmpty ? '' : jsonEncode(items);
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
      _dropAlarmIncidentLocally(incidentId);
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

    // Mỗi incident đang hoạt động phải được giữ độc lập.
    // Không xoá incident khác chỉ vì cùng nhà hoặc cùng nhóm sự kiện:
    // Fullscreen Alarm cần hiển thị đồng thời cửa, SOS, khói... của cùng nhà.

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
        _suppressAlarmIncidentLocally(id);
        _dropAlarmIncidentLocally(id);
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
    final alarmData = await validateIncomingAlarmData(data);

    if (alarmData == null) {
      await stopAllAlarmNotifications();
      return;
    }

    if (_alarmPageOpen) {
      // Một Fullscreen Alarm đang hiển thị: thêm sự cố mới ngay ở cấp
      // notification đầu tiên, không chờ tới cấp còi/fullscreen tiếp theo.
      await openAlarmFromData(alarmData, validate: false);
    } else {
      rememberAlarmIncident(alarmData);
    }

    final strings = _strings;

    final title = localizedNotificationTitle(
      alarmData['title']?.toString() ?? '',
      strings,
      strings.priorityAlarmNotificationTitle(),
    );

    final body = localizedAlarmBodyForData(alarmData, strings);

    final payload = 'priority_alarm::${jsonEncode(alarmData)}';

    final androidDetails = AndroidNotificationConfig.priorityAlarmDetails(
      title: title,
      body: body,
      strings: strings,
    );

    final iosDetails = IosNotificationConfig.alarmDetails(
      data: alarmData,
      playSound:
          alarmData['alarmStage']?.toString().trim().toLowerCase() != 'detected',
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
    final alarmData = await validateIncomingAlarmData(data);

    if (alarmData == null) {
      await stopAllAlarmNotifications();
      return;
    }

    rememberAlarmIncident(alarmData);
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
    final incidentStatus =
        data['incidentStatus']?.toString().trim().toLowerCase() ?? '';
    final isAcknowledged =
        action == 'check_home' || incidentStatus == 'acknowledged';
    final resolvedMessage = _strings.alarmIncidentResolvedMessage(action);

    if (incidentId.isNotEmpty) {
      _suppressAlarmIncidentLocally(incidentId);
      _dropAlarmIncidentLocally(incidentId);
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

    if (!isAcknowledged) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          final context = appNavigatorKey.currentContext;

          if (context == null) return;
          if (!context.mounted) return;

          showTopToast(
            context,
            resolvedMessage,
            color: Colors.green.shade700,
            icon: Icons.check_circle_rounded,
          );
        }),
      );
    }
  }

  static Future<bool> reconcileActiveAlarmIncidents() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (currentUid.isEmpty || _activeAlarmIncidentContexts.isEmpty) {
      return _activeAlarmIncidentContexts.isNotEmpty;
    }

    final incidentIds = List<String>.from(_activeAlarmIncidentContexts.keys);
    var removedAny = false;
    var contentChanged = false;

    for (final incidentId in incidentIds) {
      final context = _activeAlarmIncidentContexts[incidentId];
      final receiverUid = context?['receiverUid']?.trim().isNotEmpty == true
          ? context!['receiverUid']!.trim()
          : currentUid;

      if (receiverUid != currentUid) {
        removedAny = _dropAlarmIncidentLocally(incidentId) || removedAny;
        continue;
      }

      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('accounts/$receiverUid/alarmIncidents/$incidentId')
            .get();
        final rawIncident = snapshot.value;

        if (rawIncident is! Map) {
          removedAny = _dropAlarmIncidentLocally(incidentId) || removedAny;
          continue;
        }

        final incident = Map<String, dynamic>.from(rawIncident);
        final status =
            incident['status']?.toString().trim().toLowerCase() ?? '';
        final expireAt =
            int.tryParse(incident['expireAt']?.toString() ?? '') ?? 0;
        final isExpired =
            expireAt > 0 && expireAt <= DateTime.now().millisecondsSinceEpoch;
        final presentationSuppressedAt =
            int.tryParse(
              incident['presentationSuppressedAt']?.toString() ?? '',
            ) ??
            0;

        if (status != 'active' || isExpired || presentationSuppressedAt > 0) {
          removedAny = _dropAlarmIncidentLocally(incidentId) || removedAny;
          continue;
        }

        final freshItems = _alarmItemsFromValue(incident['items']);

        for (final item in freshItems) {
          item['incidentId'] = incidentId;
          item['homeId'] ??= incident['homeId']?.toString() ?? '';
          item['homeName'] ??= incident['homeName']?.toString() ?? '';
          item['ownerUid'] ??= incident['ownerUid']?.toString() ?? '';
        }

        final previousItemsJson = jsonEncode(
          activeAlarmItems
              .where(
                (item) =>
                    item['incidentId']?.toString().trim() == incidentId,
              )
              .toList(),
        );
        final freshItemsJson = jsonEncode(freshItems);

        if (previousItemsJson != freshItemsJson) {
          activeAlarmItems.removeWhere(
            (item) => item['incidentId']?.toString().trim() == incidentId,
          );

          if (freshItems.isNotEmpty) {
            _addAlarmItems(freshItemsJson, incidentId: incidentId);
          }

          contentChanged = true;
        }

        rememberAlarmIncident({
          'incidentId': incidentId,
          'receiverUid': receiverUid,
          'ownerUid': incident['ownerUid']?.toString() ?? '',
          'homeId': incident['homeId']?.toString() ?? '',
          'alarmFlowType': incident['flowType']?.toString() ?? 'security',
          'eventCategory':
              incident['eventCategory']?.toString() ?? 'security',
          'alarmLevel': incident['alarmLevel']?.toString() ?? 'alarm',
          'incidentStatus': 'active',
        });
      } catch (error) {
        // Fail-safe: khi chưa đọc được Firebase, giữ incident hiện tại
        // để không vô tình tắt Alarm thật.
        safeDebugPrint('ALARM INCIDENT RECONCILE ERROR: $error');
      }
    }

    if (removedAny || contentChanged) {
      lastAlarmItemsJson = activeAlarmItems.isEmpty
          ? ''
          : jsonEncode(activeAlarmItems);
    }

    if (_activeAlarmIncidentContexts.isEmpty && removedAny) {
      await stopAllAlarmNotifications();
      clearActiveAlarms(clearIncidentContexts: false);
      alarmResolvedRevision.value++;
    } else if (removedAny || contentChanged) {
      // Còn incident khác: cập nhật ngay nội dung Fullscreen để loại bỏ
      // event cũ hoặc chi tiết cảm biến đã được backend dọn khỏi incident.
      alarmRevision.value++;
    }

    return _activeAlarmIncidentContexts.isNotEmpty;
  }

  static Future<bool> handleAlarmNotificationPayload(String payload) async {
    final priorityData = _decodeAlarmPayload(payload, 'priority_alarm');

    if (priorityData != null) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await stopEmergencyNotification();
        await openIosAlarmFromData(priorityData);
      } else {
        await handlePriorityAlarmOpened(priorityData);
      }
      return true;
    }

    final sirenData = _decodeAlarmPayload(payload, 'alarm_siren');

    if (sirenData != null) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await openIosAlarmFromData(sirenData);
      } else {
        await openAlarmFromData(sirenData);
      }
      return true;
    }

    return false;
  }

  static Future<void> openAlarmFromData(
    Map<String, dynamic> data, {
    bool validate = true,
  }) async {
    final alarmData = validate
        ? await validateIncomingAlarmData(data)
        : Map<String, dynamic>.from(data);

    if (alarmData == null) {
      await stopAllAlarmNotifications();
      return;
    }

    rememberAlarmIncident(alarmData);

    final type = alarmData['type']?.toString().trim().toLowerCase() ?? '';
    final stage =
        alarmData['alarmStage']?.toString().trim().toLowerCase() ?? '';
    final opensFullscreen =
        type == 'alarm_siren' ||
        stage == 'siren' ||
        stage == 'fullscreen_siren';

    if (opensFullscreen) {
      final firstPresentation = _markAlarmDeliveryPresented(alarmData);

      if (!firstPresentation && !_alarmPageOpen) {
        // Cùng một delivery có thể đi qua background handler,
        // getInitialMessage và local notification launch. Chỉ mở một lần.
        return;
      }
    }

    final strings = _strings;

    openAlarmPage(
      title: localizedNotificationTitle(
        alarmData['title']?.toString() ?? '',
        strings,
        '🚨 SafeHome',
      ),
      body: localizedAlarmBodyForData(alarmData, strings),
      alarmItemsJson: _alarmItemsJsonFromData(alarmData),
      incidentId: alarmData['incidentId']?.toString() ?? '',
      receiverUid: alarmData['receiverUid']?.toString() ?? '',
      ownerUid: alarmData['ownerUid']?.toString() ?? '',
      homeId: alarmData['homeId']?.toString() ?? '',
      flowType: alarmData['alarmFlowType']?.toString() ?? '',
      eventCategory: normalizedIncidentEventCategory(alarmData),
      alarmLevel: normalizedIncidentAlarmLevel(alarmData),
    );
  }

  /// iOS chỉ đưa ứng dụng lên foreground sau khi người dùng chạm notification.
  /// Mở ngay dữ liệu trong payload để phản hồi nhanh, sau đó đồng bộ toàn bộ
  /// incident đang active của tài khoản để giữ đúng mô hình gom nhiều nhà và
  /// nhiều Alarm giống Android.
  static Future<void> openIosAlarmFromData(Map<String, dynamic> data) async {
    final alarmData = await validateIncomingAlarmData(data);

    if (alarmData == null) {
      await stopAllAlarmNotifications();
      return;
    }

    await openAlarmFromData(alarmData, validate: false);
    await _hydrateIosActiveAlarmIncidents(
      preserveIncidentId:
          alarmData['incidentId']?.toString().trim() ?? '',
    );
  }

  static Future<void> _hydrateIosActiveAlarmIncidents({
    String preserveIncidentId = '',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

    if (currentUid.isEmpty) {
      return;
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('accounts/$currentUid/alarmIncidents')
          .get();
      final rawIncidents = snapshot.value;

      if (rawIncidents is! Map) {
        return;
      }

      final activeIncidentIds = <String>{
        if (preserveIncidentId.isNotEmpty) preserveIncidentId,
      };
      var mergedAny = false;

      for (final entry in rawIncidents.entries) {
        final incidentId = entry.key.toString().trim();
        final rawIncident = entry.value;

        if (incidentId.isEmpty || rawIncident is! Map) {
          continue;
        }

        final incident = Map<String, dynamic>.from(rawIncident);
        final status =
            incident['status']?.toString().trim().toLowerCase() ?? '';

        if (status != 'active') {
          continue;
        }

        activeIncidentIds.add(incidentId);

        final flowType =
            incident['flowType']?.toString().trim().isNotEmpty == true
            ? incident['flowType'].toString().trim()
            : 'security';
        final eventCategory =
            incident['eventCategory']?.toString().trim().isNotEmpty == true
            ? incident['eventCategory'].toString().trim()
            : flowType;
        final alarmLevel =
            incident['alarmLevel']?.toString().trim().isNotEmpty == true
            ? incident['alarmLevel'].toString().trim()
            : flowType == 'emergency'
            ? 'emergency'
            : 'alarm';
        final items = _alarmItemsFromValue(incident['items']);

        for (final item in items) {
          item['incidentId'] = incidentId;
          item['homeId'] ??= incident['homeId']?.toString() ?? '';
          item['homeName'] ??= incident['homeName']?.toString() ?? '';
          item['ownerUid'] ??= incident['ownerUid']?.toString() ?? '';
          item['eventCategory'] ??= eventCategory;
          item['alarmLevel'] ??= alarmLevel;
        }

        rememberAlarmIncident({
          'incidentId': incidentId,
          'receiverUid': currentUid,
          'ownerUid': incident['ownerUid']?.toString() ?? '',
          'homeId': incident['homeId']?.toString() ?? '',
          'alarmFlowType': flowType,
          'eventCategory': eventCategory,
          'alarmLevel': alarmLevel,
          'incidentStatus': 'active',
        });

        if (items.isNotEmpty) {
          _addAlarmItems(jsonEncode(items), incidentId: incidentId);
          mergedAny = true;
        }
      }

      // Chỉ dọn những context có incidentId rõ ràng. Alarm legacy không có
      // incidentId vẫn được giữ theo cơ chế cũ để tránh tắt nhầm cảnh báo.
      final staleIncidentIds = _activeAlarmIncidentContexts.keys
          .where((id) => !activeIncidentIds.contains(id))
          .toList();

      for (final incidentId in staleIncidentIds) {
        _activeAlarmIncidentContexts.remove(incidentId);
        activeAlarmItems.removeWhere(
          (item) => item['incidentId']?.toString().trim() == incidentId,
        );
      }

      if (mergedAny || staleIncidentIds.isNotEmpty) {
        _syncAlarmPresentationFromActiveIncidents();
        lastAlarmItemsJson = activeAlarmItems.isEmpty
            ? ''
            : jsonEncode(activeAlarmItems);
        alarmRevision.value++;
      }
    } catch (error) {
      // Fail-safe: payload vừa chạm vẫn đã mở Alarm. Không dọn dữ liệu cục bộ
      // nếu iOS chưa cho đọc Firebase hoặc mạng đang gián đoạn.
      safeDebugPrint('IOS ACTIVE ALARM HYDRATE ERROR: $error');
    }
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

    final iosDetails = IosNotificationConfig.sensorDetails(data: data);

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

    final iosDetails = IosNotificationConfig.chatDetails(homeId: homeId);

    final payload = homeChatPayload(
      homeId: homeId,
      homeName: homeName,
      ownerUid: data["ownerUid"]?.toString() ?? "",
      messageId: data["messageId"]?.toString() ?? "",
    );

    await localNotif.show(
      homeChatNotificationId(homeId),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
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
    _resetReminderSession();
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
  static const Duration _reminderMergeWindow = Duration(seconds: 12);
  static int _lastReminderMergeAt = 0;

  static final ValueNotifier<int> reminderRevision = ValueNotifier<int>(0);

  static void markReminderPageClosed() {
    _reminderPageOpen = false;
  }

  static void _resetReminderSession() {
    lastReminderItemsJson = '';
    lastScheduleTitle = _strings.defaultHomeName();
    lastScheduleBody = _strings.safetyReminderBody(isSafe: true);
    _lastReminderMergeAt = 0;
    reminderRevision.value++;
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final keepPreviousBatch =
        _lastReminderMergeAt > 0 &&
        now - _lastReminderMergeAt <= _reminderMergeWindow.inMilliseconds;
    final existingItems = keepPreviousBatch
        ? _decodeReminderItems(lastReminderItemsJson)
        : <Map<String, dynamic>>[];
    final incomingItems = _decodeReminderItems(reminderItemsJson);

    _lastReminderMergeAt = now;

    if (incomingItems.isEmpty) {
      final cleanBody = strings.stripSafetyStatusText(body);
      final translatedCleanBody = cleanBody.isEmpty
          ? ''
          : strings.statusText(cleanBody);

      incomingItems.add({
        'homeId': '',
        'homeName': title.trim().isEmpty
            ? strings.defaultHomeName()
            : title.trim(),
        'reasons': isSafe
            ? <String>[]
            : <String>[
                translatedCleanBody.isEmpty
                    ? strings.defaultUnsafeReminderReason()
                    : translatedCleanBody,
              ],
      });
    }

    Map<String, dynamic> normalizeItem(Map<String, dynamic> item) {
      final homeId = item['homeId']?.toString().trim() ?? '';
      final homeName = item['homeName']?.toString().trim().isNotEmpty == true
          ? item['homeName'].toString().trim()
          : strings.defaultHomeName();
      final reasons = <String>[];
      final rawReasons = item['reasons'];

      if (rawReasons is List) {
        for (final reason in rawReasons) {
          final text = reason?.toString().trim() ?? '';
          final translatedText = text.isEmpty ? '' : strings.statusText(text);

          if (translatedText.isNotEmpty && !reasons.contains(translatedText)) {
            reasons.add(translatedText);
          }
        }
      }

      return {
        'homeId': homeId,
        'homeName': homeName,
        'reasons': reasons,
      };
    }

    String itemKey(Map<String, dynamic> item) {
      final homeId = item['homeId']?.toString().trim() ?? '';
      final homeName =
          item['homeName']?.toString().trim().toLowerCase() ?? '';

      return homeId.isNotEmpty ? homeId : homeName;
    }

    final merged = <String, Map<String, dynamic>>{};

    for (final item in existingItems) {
      final normalized = normalizeItem(item);
      merged[itemKey(normalized)] = normalized;
    }

    // Payload mới thay thế trạng thái cũ của cùng một nhà. Nhờ vậy một nhà
    // vừa trở lại an toàn sẽ không còn giữ lý do "chưa an toàn" từ Reminder
    // trước. Các nhà khác chỉ được gộp trong cửa sổ 12 giây của cùng một lượt.
    for (final item in incomingItems) {
      final normalized = normalizeItem(item);
      merged[itemKey(normalized)] = normalized;
    }

    final mergedItems = merged.values.toList();
    final hasUnsafe = mergedItems.any((item) {
      final reasons = item['reasons'];

      return reasons is List && reasons.isNotEmpty;
    });

    lastReminderItemsJson = jsonEncode(mergedItems);
    lastScheduleTitle = mergedItems.length == 1
        ? mergedItems.first['homeName']?.toString() ?? strings.defaultHomeName()
        : strings.scheduledReminder;

    if (!hasUnsafe) {
      lastScheduleBody = strings.safetyReminderBody(isSafe: true);
      return;
    }

    final issueLines = <String>[];

    for (final item in mergedItems) {
      final reasons = item['reasons'];

      if (reasons is! List || reasons.isEmpty) continue;

      final homeName =
          item['homeName']?.toString() ?? strings.defaultHomeName();

      issueLines.add('$homeName: ${reasons.join(', ')}');
    }

    lastScheduleBody =
        '⚠️ ${strings.unsafeStatusTitle()}\n${issueLines.join('\n')}';
  }

  static bool _currentReminderIsSafe() {
    final items = _decodeReminderItems(lastReminderItemsJson);

    return !items.any((item) {
      final reasons = item['reasons'];

      return reasons is List && reasons.isNotEmpty;
    });
  }

  static String _currentReminderReason() {
    final strings = _strings;
    final lines = <String>[];

    for (final item in _decodeReminderItems(lastReminderItemsJson)) {
      final reasons = item['reasons'];

      if (reasons is! List || reasons.isEmpty) continue;

      final homeName =
          item['homeName']?.toString().trim().isNotEmpty == true
          ? item['homeName'].toString().trim()
          : strings.defaultHomeName();

      lines.add('$homeName: ${reasons.join(', ')}');
    }

    return lines.join('\n');
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

  static Future<void>? _initializationFuture;

  static Future<void> init() {
    final existingFuture = _initializationFuture;

    if (existingFuture != null) {
      return existingFuture;
    }

    late final Future<void> future;
    future = _initInternal().catchError((Object error, StackTrace stackTrace) {
      if (identical(_initializationFuture, future)) {
        _initializationFuture = null;
      }

      Error.throwWithStackTrace(error, stackTrace);
    });
    _initializationFuture = future;

    return future;
  }

  static Future<void> _initInternal() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: IosNotificationConfig.criticalAlertsEntitlementEnabled,
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

    await localNotif.initialize(
      const InitializationSettings(
        android: AndroidNotificationConfig.initializationSettings,
        iOS: IosNotificationConfig.initializationSettings,
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

  static void markAlarmPageOpened({
    String body = '',
    String alarmItemsJson = '',
    String eventCategory = '',
    String alarmLevel = '',
  }) {
    _alarmPageOpen = true;

    if (body.trim().isNotEmpty) {
      lastAlarmBody = body.trim();
    }

    if (alarmItemsJson.trim().isNotEmpty) {
      _addAlarmItems(alarmItemsJson);
      lastAlarmItemsJson = activeAlarmItems.isEmpty
          ? alarmItemsJson
          : jsonEncode(activeAlarmItems);
    }

    if (eventCategory.trim().isNotEmpty) {
      lastAlarmEventCategory = eventCategory.trim();
    }

    if (alarmLevel.trim().isNotEmpty) {
      lastAlarmLevel = alarmLevel.trim();
    }
  }

  static void markAlarmPageClosed() {
    _alarmPageOpen = false;
  }

  static String _alarmKey(Map<String, dynamic> item) {
    final incidentId = item['incidentId']?.toString().trim() ?? '';

    if (incidentId.isNotEmpty) {
      return [
        'incident',
        incidentId,
        item['deviceId'] ?? '',
        item['deviceName'] ?? item['name'] ?? '',
        item['type'] ?? '',
      ].join('|');
    }

    return [
      item['homeId'] ?? '',
      item['homeName'] ?? '',
      item['deviceId'] ?? '',
      item['deviceName'] ?? item['name'] ?? '',
      item['type'] ?? '',
      item['reason'] ?? '',
    ].join('|');
  }

  static void _addAlarmItems(String alarmItemsJson, {String incidentId = ''}) {
    try {
      final decoded = jsonDecode(alarmItemsJson);

      if (decoded is! List) return;

      for (final item in decoded) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);

        if ((map['incidentId']?.toString().trim() ?? '').isEmpty &&
            incidentId.trim().isNotEmpty) {
          map['incidentId'] = incidentId.trim();
        }

        final key = _alarmKey(map);
        final existingIndex = activeAlarmItems.indexWhere(
          (existing) => _alarmKey(existing) == key,
        );

        if (existingIndex >= 0) {
          activeAlarmItems[existingIndex] = map;
        } else {
          activeAlarmItems.add(map);
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

    if (_activeAlarmIncidentContexts.isEmpty) {
      lastAlarmEventCategory = normalizedIncidentEventCategory(incidentData);
      lastAlarmLevel = normalizedIncidentAlarmLevel(incidentData);
    } else {
      _syncAlarmPresentationFromActiveIncidents();
    }

    if (incidentId.trim().isNotEmpty) {
      // Payload đã được xác minh bằng incident hiện tại trên Firebase.
      // Thay toàn bộ item của incident thay vì chỉ cộng dồn, nếu không một
      // cửa đã xử lý có thể còn nằm trên máy Owner khi incident khác vẫn active.
      activeAlarmItems.removeWhere(
        (item) =>
            item['incidentId']?.toString().trim() == incidentId.trim(),
      );
    }

    _addAlarmItems(alarmItemsJson, incidentId: incidentId);

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

    final effectiveIsSafe = _currentReminderIsSafe();
    final effectiveReason = effectiveIsSafe
        ? ''
        : _currentReminderReason();
    final notificationTitle = strings.safetyReminderNotificationTitle(
      homeTitle: lastScheduleTitle.trim().isEmpty
          ? "SafeHome"
          : lastScheduleTitle,
      isSafe: effectiveIsSafe,
    );

    final notificationBody = effectiveIsSafe
        ? strings.safeReminderBody()
        : strings.unsafeReminderBody(
            effectiveReason.isEmpty ? cleanReason : effectiveReason,
          );

    final androidDetails = AndroidNotificationConfig.reminderDetails(
      title: notificationTitle,
      body: notificationBody,
      bigText: lastScheduleBody,
      strings: strings,
    );

    const iosDetails = IosNotificationConfig.reminderDetails;

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
