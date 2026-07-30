part of '../notification_service.dart';

const String _notificationServiceAlarmRouteName = 'fullscreen_alarm';

bool _alarmPageOpen = false;

final ValueNotifier<int> _notificationServiceAlarmRevision = ValueNotifier<int>(0);

final List<Map<String, dynamic>> _notificationServiceActiveAlarmItems = [];

void _notificationServiceMarkAlarmPageOpened({
  String body = '',
  String alarmItemsJson = '',
  String eventCategory = '',
  String alarmLevel = '',
}) {
  _alarmPageOpen = true;

  if (body.trim().isNotEmpty) {
    _notificationServiceLastAlarmBody = body.trim();
  }

  if (alarmItemsJson.trim().isNotEmpty) {
    _addAlarmItems(alarmItemsJson);
    _notificationServiceLastAlarmItemsJson = _notificationServiceActiveAlarmItems.isEmpty
        ? alarmItemsJson
        : jsonEncode(_notificationServiceActiveAlarmItems);
  }

  if (eventCategory.trim().isNotEmpty) {
    _notificationServiceLastAlarmEventCategory = eventCategory.trim();
  }

  if (alarmLevel.trim().isNotEmpty) {
    _notificationServiceLastAlarmLevel = alarmLevel.trim();
  }
}

void _notificationServiceMarkAlarmPageClosed() {
  _alarmPageOpen = false;
}

String _alarmKey(Map<String, dynamic> item) {
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

void _addAlarmItems(String alarmItemsJson, {String incidentId = ''}) {
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
      final existingIndex = _notificationServiceActiveAlarmItems.indexWhere(
        (existing) => _alarmKey(existing) == key,
      );

      if (existingIndex >= 0) {
        _notificationServiceActiveAlarmItems[existingIndex] = map;
      } else {
        _notificationServiceActiveAlarmItems.add(map);
      }
    }
  } catch (_) {}
}

void _openPendingAlarmPage() {
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

  _notificationServiceOpenAlarmPage(
    title: _notificationServiceLocalizedNotificationTitle(
      data['title']?.toString() ?? '',
      strings,
      '🚨 ${BrandConfig.appName}',
    ),
    body: _notificationServiceLocalizedAlarmBodyForData(data, strings),
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

void _notificationServiceOpenAlarmPage({
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
    _notificationServiceRememberAlarmIncident({
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

  _notificationServiceLastAlarmBody = body;
  final incidentData = <String, dynamic>{
    'alarmFlowType': flowType,
    'eventCategory': eventCategory,
    'alarmLevel': alarmLevel,
  };

  if (_activeAlarmIncidentContexts.isEmpty) {
    _notificationServiceLastAlarmEventCategory = _notificationServiceNormalizedIncidentEventCategory(incidentData);
    _notificationServiceLastAlarmLevel = _notificationServiceNormalizedIncidentAlarmLevel(incidentData);
  } else {
    _syncAlarmPresentationFromActiveIncidents();
  }

  if (incidentId.trim().isNotEmpty) {
    // Payload đã được xác minh bằng incident hiện tại trên Firebase.
    // Thay toàn bộ item của incident thay vì chỉ cộng dồn, nếu không một
    // cửa đã xử lý có thể còn nằm trên máy Owner khi incident khác vẫn active.
    _notificationServiceActiveAlarmItems.removeWhere(
      (item) =>
          item['incidentId']?.toString().trim() == incidentId.trim(),
    );
  }

  _addAlarmItems(alarmItemsJson, incidentId: incidentId);

  _notificationServiceLastAlarmItemsJson = _notificationServiceActiveAlarmItems.isEmpty
      ? alarmItemsJson
      : jsonEncode(_notificationServiceActiveAlarmItems);

  _notificationServiceAlarmRevision.value++;

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
          settings: const RouteSettings(name: _notificationServiceAlarmRouteName),
          builder: (_) => FullscreenAlarmPage(
            title: title,
            body: _notificationServiceLastAlarmBody,
            alarmItemsJson: _notificationServiceLastAlarmItemsJson,
            eventCategory: eventCategory,
            alarmLevel: alarmLevel,
          ),
        ),
      )
      .whenComplete(_notificationServiceMarkAlarmPageClosed);
}

void _notificationServiceClearActiveAlarms({bool clearIncidentContexts = true}) {
  _notificationServiceActiveAlarmItems.clear();
  _notificationServiceLastAlarmItemsJson = '';
  _notificationServiceLastAlarmBody = _strings.alarmBody;
  _notificationServiceLastAlarmEventCategory = '';
  _notificationServiceLastAlarmLevel = '';

  if (clearIncidentContexts) {
    _activeAlarmIncidentContexts.clear();
  }
}

Future<void> _notificationServiceShowSafetyReminder({
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
    homeTitle: _notificationServiceLastScheduleTitle.trim().isEmpty
        ? BrandConfig.appName
        : _notificationServiceLastScheduleTitle,
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
    bigText: _notificationServiceLastScheduleBody,
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
