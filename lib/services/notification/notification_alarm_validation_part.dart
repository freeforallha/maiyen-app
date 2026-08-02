part of '../notification_service.dart';

const int _notificationServiceEmergencyNotificationId = 999997;

const int _notificationServiceAlarmNotificationId = 999999;

final Map<String, Map<String, String>> _activeAlarmIncidentContexts = {};

final ValueNotifier<int> _notificationServiceAlarmResolvedRevision =
    ValueNotifier<int>(0);

Timer? _pendingAlarmOpenTimer;

Map<String, dynamic>? _pendingAlarmOpenData;

final Map<String, Future<Map<String, dynamic>?>>
_alarmPayloadValidationInFlight = {};

final Map<String, int> _presentedAlarmDeliveryAt = {};

final Map<String, int> _locallySuppressedAlarmIncidentAt = {};

const int _alarmDeliveryDedupeWindowMs = 24 * 60 * 60 * 1000;

const int _localAlarmIncidentSuppressionMs = 30 * 60 * 1000;

const int _alarmDeliveryDedupeMaxEntries = 300;

bool get _notificationServiceHasActiveAlarmIncidents =>
    _activeAlarmIncidentContexts.isNotEmpty;

Map<String, dynamic>? _decodeAlarmPayload(String payload, String prefix) {
  return NotificationPayloadCodec.decodePayload(prefix, payload);
}

String _alarmDeliveryKey(Map<String, dynamic> data) {
  final direct = data['alarmDeliveryId']?.toString().trim() ?? '';

  if (direct.isNotEmpty) {
    return direct;
  }

  final itemKeys = _alarmItemsFromData(data).map((item) {
    return [
      item['incidentId'] ?? data['incidentId'] ?? '',
      item['homeId'] ?? data['homeId'] ?? '',
      item['deviceId'] ?? '',
      item['type'] ?? '',
      item['reason'] ?? '',
    ].join('|');
  }).toList()..sort();

  return [
    data['receiverUid'] ?? '',
    data['incidentId'] ?? '',
    data['alarmStage'] ?? '',
    data['type'] ?? '',
    ...itemKeys,
  ].join('||');
}

bool _markAlarmDeliveryPresented(Map<String, dynamic> data) {
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

bool _dropAlarmIncidentLocally(String incidentId) {
  final cleanIncidentId = incidentId.trim();

  if (cleanIncidentId.isEmpty) {
    return false;
  }

  final removedContext =
      _activeAlarmIncidentContexts.remove(cleanIncidentId) != null;
  final oldLength = _notificationServiceActiveAlarmItems.length;

  _notificationServiceActiveAlarmItems.removeWhere(
    (item) => item['incidentId']?.toString().trim() == cleanIncidentId,
  );

  final removedItems = _notificationServiceActiveAlarmItems.length != oldLength;

  if (removedContext || removedItems) {
    _syncAlarmPresentationFromActiveIncidents();
    _notificationServiceLastAlarmItemsJson =
        _notificationServiceActiveAlarmItems.isEmpty
        ? ''
        : jsonEncode(_notificationServiceActiveAlarmItems);
  }

  return removedContext || removedItems;
}

Future<String> _restoredAlarmUserUid() async {
  final immediateUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

  if (immediateUid.isNotEmpty) {
    return immediateUid;
  }

  try {
    final restoredUser = await FirebaseAuth.instance
        .authStateChanges()
        .firstWhere((user) => user != null)
        .timeout(const Duration(seconds: 2), onTimeout: () => null);

    return restoredUser?.uid.trim() ?? '';
  } catch (_) {
    return '';
  }
}

bool _isUnverifiedAlarmPayloadStale(Map<String, dynamic> data) {
  final sentAt = int.tryParse(data['sentAt']?.toString() ?? '') ?? 0;

  if (sentAt <= 0) {
    return false;
  }

  return DateTime.now().millisecondsSinceEpoch - sentAt >
      const Duration(minutes: 2).inMilliseconds;
}

bool _isAlarmIncidentLocallySuppressed(String incidentId) {
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

void _suppressAlarmIncidentLocally(String incidentId) {
  final cleanIncidentId = incidentId.trim();

  if (cleanIncidentId.isEmpty) {
    return;
  }

  _locallySuppressedAlarmIncidentAt[cleanIncidentId] =
      DateTime.now().millisecondsSinceEpoch;
}

Future<Map<String, dynamic>?> _notificationServiceValidateIncomingAlarmData(
  Map<String, dynamic> rawData, {
  bool updateLocalState = true,
}) async {
  final data = Map<String, dynamic>.from(rawData);
  final incidentId = data['incidentId']?.toString().trim() ?? '';
  final explicitStatus = _notificationServiceNormalizedIncidentStatus(data);

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
  final payloadReceiverUid = data['receiverUid']?.toString().trim() ?? '';

  if (currentUid.isNotEmpty &&
      payloadReceiverUid.isNotEmpty &&
      payloadReceiverUid != currentUid) {
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
      final status = incident['status']?.toString().trim().toLowerCase() ?? '';
      final expireAt =
          int.tryParse(incident['expireAt']?.toString() ?? '') ?? 0;
      final isExpired =
          expireAt > 0 && expireAt <= DateTime.now().millisecondsSinceEpoch;
      final presentationSuppressedAt =
          int.tryParse(
            incident['presentationSuppressedAt']?.toString() ?? '',
          ) ??
          0;

      final incomingType = data['type']?.toString().trim().toLowerCase() ?? '';
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
          (freshData['alarmFlowType'] == 'emergency' ? 'emergency' : 'alarm');
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

List<Map<String, dynamic>> _alarmItemsFromValue(dynamic value) {
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

List<Map<String, dynamic>> _alarmItemsFromData(Map<String, dynamic> data) {
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

String _alarmConditionKey(Map<String, dynamic> item) {
  final homeId = item['homeId']?.toString().trim() ?? '';
  final deviceId = item['deviceId']?.toString().trim() ?? '';
  final deviceName = item['deviceName']?.toString().trim().isNotEmpty == true
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

List<Map<String, dynamic>> _freshAlarmItemsForDelivery({
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

String _alarmItemsJsonFromData(Map<String, dynamic> data) {
  final items = _alarmItemsFromData(data);
  return items.isEmpty ? '' : jsonEncode(items);
}

String _notificationServiceLocalizedAlarmTitleForData(
  Map<String, dynamic> data,
  AppStrings strings,
) {
  return buildAlarmNotificationPresentation(data, strings).title;
}

String _notificationServiceLocalizedAlarmBodyForData(
  Map<String, dynamic> data,
  AppStrings strings,
) {
  final items = _alarmItemsFromData(data);
  final lines = <String>[];

  for (final item in items) {
    final deviceName = item['deviceName']?.toString().trim().isNotEmpty == true
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

String _notificationServiceLocalizedNotificationTitle(
  String rawTitle,
  AppStrings strings,
  String fallback,
) {
  final cleanTitle = rawTitle.trim();

  if (cleanTitle.isEmpty) {
    return fallback;
  }

  final lowerTitle = cleanTitle.toLowerCase();
  if (lowerTitle.contains(MaiYenIdentifiers.brandToken) ||
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

String _notificationServiceNormalizedIncidentEventCategory(
  Map<String, dynamic> data,
) {
  return NotificationIncidentNormalizer.eventCategory(data);
}

String _notificationServiceNormalizedIncidentAlarmLevel(
  Map<String, dynamic> data,
) {
  return NotificationIncidentNormalizer.alarmLevel(data);
}

String _notificationServiceNormalizedIncidentStatus(Map<String, dynamic> data) {
  return NotificationIncidentNormalizer.status(data);
}
