import 'dart:convert';

import '../../localization/app_strings.dart';

class AlarmNotificationPresentation {
  final String title;
  final String body;
  final String stage;
  final String family;

  const AlarmNotificationPresentation({
    required this.title,
    required this.body,
    required this.stage,
    required this.family,
  });

  bool get isRepeat => stage == 'repeat';
  bool get isDetected => stage == 'detected';
  bool get isFullscreen => stage == 'fullscreen';
}

const Map<String, String> _alarmFamilyLabels = {
  'security': 'An ninh ra/vào',
  'sos': 'Nút SOS',
  'smoke': 'Báo khói',
  'heat': 'Báo nhiệt',
  'carbon_monoxide': 'Khí CO',
  'gas': 'Báo gas',
  'water': 'Báo ngập/rò nước',
};

const Map<String, String> _alarmFamilyEmoji = {
  'security': '🚨',
  'sos': '🆘',
  'smoke': '🔥',
  'heat': '🌡️',
  'carbon_monoxide': '☠️',
  'gas': '⚠️',
  'water': '🌊',
  'emergency': '🚨',
};

String _cleanAlarmText(Object? value) => value?.toString().trim() ?? '';

int _positiveAlarmInteger(Object? value) {
  final parsed = int.tryParse(_cleanAlarmText(value));
  return parsed != null && parsed > 0 ? parsed : 0;
}

List<Map<String, dynamic>> _presentationAlarmItems(Map<String, dynamic> data) {
  Object? raw = data['alarmItems'];
  raw ??= data['alarmItemsJson'];

  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  try {
    final decoded = jsonDecode(
      _cleanAlarmText(raw).isEmpty ? '[]' : raw.toString(),
    );

    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } catch (_) {
    return const [];
  }
}

String _alarmNotificationStage(Map<String, dynamic> data) {
  final explicit = _cleanAlarmText(
    data['alarmNotificationStage'],
  ).toLowerCase();

  if (const {
    'detected',
    'initial',
    'repeat',
    'fullscreen',
    'resolved',
  }.contains(explicit)) {
    return explicit;
  }

  final stage = _cleanAlarmText(data['alarmStage']).toLowerCase();
  final type = _cleanAlarmText(data['type']).toLowerCase();

  if (stage == 'detected' || type == 'alarm_detected') {
    return 'detected';
  }

  if (stage == 'siren' ||
      stage == 'fullscreen_siren' ||
      type == 'alarm_siren') {
    return 'fullscreen';
  }

  if (stage == 'resolved' || type == 'alarm_resolved') {
    return 'resolved';
  }

  return 'initial';
}

String _inferAlarmFamily(
  Map<String, dynamic> data,
  List<Map<String, dynamic>> items,
) {
  final explicit = _cleanAlarmText(data['alarmFamily']).toLowerCase();

  if (_alarmFamilyEmoji.containsKey(explicit)) {
    return explicit;
  }

  final flowType = _cleanAlarmText(
    data['alarmFlowType'] ?? data['flowType'],
  ).toLowerCase();

  if (flowType != 'emergency') {
    return 'security';
  }

  final types = items
      .map((item) => _cleanAlarmText(item['type']).toLowerCase())
      .toSet();

  if (types.contains('sos')) return 'sos';
  if (types.contains('smoke')) return 'smoke';
  if (types.contains('heat')) return 'heat';
  if (types.contains('carbon_monoxide')) return 'carbon_monoxide';
  if (types.contains('gas')) return 'gas';
  if (types.contains('water_leak') || types.contains('flood')) {
    return 'water';
  }

  return 'emergency';
}

String _localizedAlarmItemDetail(
  Map<String, dynamic> item,
  AppStrings strings,
) {
  final deviceName = _cleanAlarmText(item['deviceName'] ?? item['name']);
  final reason = _cleanAlarmText(item['reason']);
  final localizedReason = reason.isEmpty ? '' : strings.statusText(reason);

  if (deviceName.isNotEmpty && localizedReason.isNotEmpty) {
    if (localizedReason.toLowerCase().startsWith(
      '${deviceName.toLowerCase()}:',
    )) {
      return localizedReason;
    }

    return '$deviceName: $localizedReason';
  }

  return localizedReason.isNotEmpty ? localizedReason : deviceName;
}

String _localizedAlarmItemLine(Map<String, dynamic> item, AppStrings strings) {
  final homeName = _cleanAlarmText(item['homeName'] ?? item['homeId']);
  final detail = _localizedAlarmItemDetail(item, strings);

  if (homeName.isNotEmpty && detail.isNotEmpty) {
    return '$homeName: $detail';
  }

  return detail.isNotEmpty ? detail : homeName;
}

AlarmNotificationPresentation buildAlarmNotificationPresentation(
  Map<String, dynamic> data,
  AppStrings strings,
) {
  final items = _presentationAlarmItems(data);
  final stage = _alarmNotificationStage(data);
  final family = _inferAlarmFamily(data, items);
  final familyLabelKey = _alarmFamilyLabels[family] ?? '';
  final familyLabel = familyLabelKey.isEmpty ? '' : strings.t(familyLabelKey);
  final familyEmoji = _alarmFamilyEmoji[family] ?? '🚨';
  final flowType = _cleanAlarmText(
    data['alarmFlowType'] ?? data['flowType'],
  ).toLowerCase();
  final lines = <String>[];

  for (final item in items.take(4)) {
    final line = _localizedAlarmItemLine(item, strings);

    if (line.isNotEmpty && !lines.contains(line)) {
      lines.add(line);
    }
  }

  if (items.length > 4) {
    lines.add('...');
  }

  final rawBody = _cleanAlarmText(data['body']);

  if (lines.isEmpty && rawBody.isNotEmpty) {
    lines.add(strings.statusText(rawBody));
  }

  if (lines.isEmpty) {
    lines.add(strings.alarmBody);
  }

  final primaryDetail = items.isNotEmpty
      ? _localizedAlarmItemDetail(items.first, strings)
      : lines.first;

  late final String title;

  if (stage == 'resolved') {
    final resolvedLabel = flowType == 'emergency'
        ? strings.t('Sự cố nguy hiểm đã kết thúc')
        : strings.t('Cảnh báo an ninh đã kết thúc');
    title = '✅ $resolvedLabel';
  } else if (stage == 'repeat') {
    final repeatLabel = strings.isVietnamese
        ? 'Nhắc nhở lại'
        : strings.t('Lặp lại cảnh báo');
    title = primaryDetail.isEmpty
        ? '🔁 $repeatLabel'
        : '🔁 $repeatLabel “$primaryDetail”';

    final footer = <String>[strings.t('Sự cố vẫn đang được theo dõi.')];
    final repeatMinutes = _positiveAlarmInteger(data['repeatMinutes']);
    final repeatCount = _positiveAlarmInteger(data['repeatCount']);

    if (repeatMinutes > 0) {
      footer.add(strings.alarmRepeatAfterText(repeatMinutes));
    }

    if (repeatCount > 0) {
      footer.add('#$repeatCount');
    }

    lines.add(footer.join(' · '));
  } else if (stage == 'fullscreen') {
    final siren = strings.t('Còi báo động');
    title = familyLabel.isEmpty ? '📢 $siren' : '📢 $siren · $familyLabel';
  } else if (stage == 'detected') {
    final attention = strings.alarmIncidentLevelLabel('warning');
    title = familyLabel.isEmpty
        ? '👁️ $attention'
        : '👁️ $attention · $familyLabel';
  } else if (flowType == 'emergency') {
    final emergency = strings.alarmIncidentLevelLabel('emergency');
    title = familyLabel.isEmpty
        ? '$familyEmoji $emergency'
        : '$familyEmoji $emergency · $familyLabel';
  } else {
    final alarm = strings.alarmIncidentLevelLabel('alarm');
    title = familyLabel.isEmpty ? '🚨 $alarm' : '🚨 $alarm · $familyLabel';
  }

  return AlarmNotificationPresentation(
    title: title,
    body: lines.join('\n'),
    stage: stage,
    family: family,
  );
}
