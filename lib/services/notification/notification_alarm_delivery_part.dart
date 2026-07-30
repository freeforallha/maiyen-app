part of '../notification_service.dart';

Future<void> _notificationServiceShowPriorityAlarmNotification({
  required Map<String, dynamic> data,
}) async {
  final alarmData = await _notificationServiceValidateIncomingAlarmData(data);

  if (alarmData == null) {
    await _notificationServiceStopAllAlarmNotifications();
    return;
  }

  if (_alarmPageOpen) {
    // Một Fullscreen Alarm đang hiển thị: thêm sự cố mới ngay ở cấp
    // notification đầu tiên, không chờ tới cấp còi/fullscreen tiếp theo.
    await _notificationServiceOpenAlarmFromData(alarmData, validate: false);
  } else {
    _notificationServiceRememberAlarmIncident(alarmData);
  }

  final strings = _strings;

  final title = _notificationServiceLocalizedNotificationTitle(
    alarmData['title']?.toString() ?? '',
    strings,
    strings.priorityAlarmNotificationTitle(),
  );

  final body = _notificationServiceLocalizedAlarmBodyForData(alarmData, strings);

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

  await localNotif.cancel(_notificationServiceEmergencyNotificationId);

  await localNotif.show(
    _notificationServiceEmergencyNotificationId,
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: payload,
  );
}

Future<void> _notificationServiceHandlePriorityAlarmOpened(
  Map<String, dynamic> data,
) async {
  final alarmData = await _notificationServiceValidateIncomingAlarmData(data);

  if (alarmData == null) {
    await _notificationServiceStopAllAlarmNotifications();
    return;
  }

  _notificationServiceRememberAlarmIncident(alarmData);
  await _notificationServiceStopEmergencyNotification();

  // Chạm vào notification chỉ mở ứng dụng để kiểm tra.
  // Không được gửi check_home/stop vì incident phải tiếp tục
  // cho tới khi cảm biến an toàn hoặc người dùng chủ động tắt.
  await _notificationServiceReconcileActiveAlarmIncidents();
}

Future<void> _notificationServiceHandleAlarmResolved(Map<String, dynamic> data) async {
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
    _notificationServiceActiveAlarmItems.clear();
  }

  _syncAlarmPresentationFromActiveIncidents();
  _notificationServiceLastAlarmItemsJson = _notificationServiceActiveAlarmItems.isEmpty
      ? ''
      : jsonEncode(_notificationServiceActiveAlarmItems);

  if (_activeAlarmIncidentContexts.isEmpty) {
    await _notificationServiceStopAllAlarmNotifications();
    _notificationServiceClearActiveAlarms(clearIncidentContexts: false);
    _notificationServiceAlarmResolvedRevision.value++;
  } else {
    // Còn incident khác đang hoạt động: chỉ cập nhật nội dung màn hình,
    // tuyệt đối không tắt notification/âm thanh của sự cố còn lại.
    _notificationServiceAlarmRevision.value++;
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

Future<bool> _notificationServiceReconcileActiveAlarmIncidents() async {
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
        _notificationServiceActiveAlarmItems
            .where(
              (item) =>
                  item['incidentId']?.toString().trim() == incidentId,
            )
            .toList(),
      );
      final freshItemsJson = jsonEncode(freshItems);

      if (previousItemsJson != freshItemsJson) {
        _notificationServiceActiveAlarmItems.removeWhere(
          (item) => item['incidentId']?.toString().trim() == incidentId,
        );

        if (freshItems.isNotEmpty) {
          _addAlarmItems(freshItemsJson, incidentId: incidentId);
        }

        contentChanged = true;
      }

      _notificationServiceRememberAlarmIncident({
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
    _notificationServiceLastAlarmItemsJson = _notificationServiceActiveAlarmItems.isEmpty
        ? ''
        : jsonEncode(_notificationServiceActiveAlarmItems);
  }

  if (_activeAlarmIncidentContexts.isEmpty && removedAny) {
    await _notificationServiceStopAllAlarmNotifications();
    _notificationServiceClearActiveAlarms(clearIncidentContexts: false);
    _notificationServiceAlarmResolvedRevision.value++;
  } else if (removedAny || contentChanged) {
    // Còn incident khác: cập nhật ngay nội dung Fullscreen để loại bỏ
    // event cũ hoặc chi tiết cảm biến đã được backend dọn khỏi incident.
    _notificationServiceAlarmRevision.value++;
  }

  return _activeAlarmIncidentContexts.isNotEmpty;
}

Future<bool> _notificationServiceHandleAlarmNotificationPayload(String payload) async {
  final priorityData = _decodeAlarmPayload(payload, 'priority_alarm');

  if (priorityData != null) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationServiceStopEmergencyNotification();
      await _notificationServiceOpenIosAlarmFromData(priorityData);
    } else {
      await _notificationServiceHandlePriorityAlarmOpened(priorityData);
    }
    return true;
  }

  final sirenData = _decodeAlarmPayload(payload, 'alarm_siren');

  if (sirenData != null) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationServiceOpenIosAlarmFromData(sirenData);
    } else {
      await _notificationServiceOpenAlarmFromData(sirenData);
    }
    return true;
  }

  return false;
}

Future<void> _notificationServiceOpenAlarmFromData(
  Map<String, dynamic> data, {
  bool validate = true,
}) async {
  final alarmData = validate
      ? await _notificationServiceValidateIncomingAlarmData(data)
      : Map<String, dynamic>.from(data);

  if (alarmData == null) {
    await _notificationServiceStopAllAlarmNotifications();
    return;
  }

  _notificationServiceRememberAlarmIncident(alarmData);

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

  _notificationServiceOpenAlarmPage(
    title: _notificationServiceLocalizedNotificationTitle(
      alarmData['title']?.toString() ?? '',
      strings,
      '🚨 ${BrandConfig.appName}',
    ),
    body: _notificationServiceLocalizedAlarmBodyForData(alarmData, strings),
    alarmItemsJson: _alarmItemsJsonFromData(alarmData),
    incidentId: alarmData['incidentId']?.toString() ?? '',
    receiverUid: alarmData['receiverUid']?.toString() ?? '',
    ownerUid: alarmData['ownerUid']?.toString() ?? '',
    homeId: alarmData['homeId']?.toString() ?? '',
    flowType: alarmData['alarmFlowType']?.toString() ?? '',
    eventCategory: _notificationServiceNormalizedIncidentEventCategory(alarmData),
    alarmLevel: _notificationServiceNormalizedIncidentAlarmLevel(alarmData),
  );
}

/// iOS chỉ đưa ứng dụng lên foreground sau khi người dùng chạm notification.
/// Mở ngay dữ liệu trong payload để phản hồi nhanh, sau đó đồng bộ toàn bộ
/// incident đang active của tài khoản để giữ đúng mô hình gom nhiều nhà và
/// nhiều Alarm giống Android.

Future<void> _notificationServiceOpenIosAlarmFromData(Map<String, dynamic> data) async {
  final alarmData = await _notificationServiceValidateIncomingAlarmData(data);

  if (alarmData == null) {
    await _notificationServiceStopAllAlarmNotifications();
    return;
  }

  await _notificationServiceOpenAlarmFromData(alarmData, validate: false);
  await _hydrateIosActiveAlarmIncidents(
    preserveIncidentId:
        alarmData['incidentId']?.toString().trim() ?? '',
  );
}

Future<void> _hydrateIosActiveAlarmIncidents({
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

      _notificationServiceRememberAlarmIncident({
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
      _notificationServiceActiveAlarmItems.removeWhere(
        (item) => item['incidentId']?.toString().trim() == incidentId,
      );
    }

    if (mergedAny || staleIncidentIds.isNotEmpty) {
      _syncAlarmPresentationFromActiveIncidents();
      _notificationServiceLastAlarmItemsJson = _notificationServiceActiveAlarmItems.isEmpty
          ? ''
          : jsonEncode(_notificationServiceActiveAlarmItems);
      _notificationServiceAlarmRevision.value++;
    }
  } catch (error) {
    // Fail-safe: payload vừa chạm vẫn đã mở Alarm. Không dọn dữ liệu cục bộ
    // nếu iOS chưa cho đọc Firebase hoặc mạng đang gián đoạn.
    safeDebugPrint('IOS ACTIVE ALARM HYDRATE ERROR: $error');
  }
}
