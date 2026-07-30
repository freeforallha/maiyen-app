part of '../notification_service.dart';

void _syncAlarmPresentationFromActiveIncidents() {
  if (_activeAlarmIncidentContexts.isEmpty) {
    _notificationServiceLastAlarmEventCategory = '';
    _notificationServiceLastAlarmLevel = '';
    return;
  }

  final contexts = _activeAlarmIncidentContexts.values;
  final hasEmergency = contexts.any(
    (context) =>
        context['eventCategory'] == 'emergency' ||
        context['alarmLevel'] == 'emergency',
  );

  if (hasEmergency) {
    _notificationServiceLastAlarmEventCategory = 'emergency';
    _notificationServiceLastAlarmLevel = 'emergency';
    return;
  }

  final hasAlarm = contexts.any(
    (context) => context['alarmLevel'] == 'alarm',
  );

  _notificationServiceLastAlarmEventCategory = 'security';
  _notificationServiceLastAlarmLevel = hasAlarm ? 'alarm' : 'warning';
}

void _notificationServiceRememberAlarmIncident(Map<String, dynamic> data) {
  final incidentId = data['incidentId']?.toString().trim() ?? '';

  if (incidentId.isEmpty) return;

  final status = _notificationServiceNormalizedIncidentStatus(data);

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
  final eventCategory = _notificationServiceNormalizedIncidentEventCategory(data);
  final alarmLevel = _notificationServiceNormalizedIncidentAlarmLevel(data);
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

Future<bool> _sendAlarmIncidentAction({
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

bool _isValidHubId(String value) {
  return RegExp(r'^dev_[a-f0-9]{16}$').hasMatch(value);
}

Future<String> _resolveHomeHubId({
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

Future<bool> _notificationServiceMuteHomeSiren({
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

Future<bool> _notificationServiceResolveActiveAlarmIncidents({
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

Future<bool> _notificationServiceMuteActiveHomeSirens({String incidentId = ''}) async {
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
