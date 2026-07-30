class NotificationIncidentNormalizer {
  const NotificationIncidentNormalizer._();

  static String eventCategory(Map<String, dynamic> data) {
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

  static String alarmLevel(Map<String, dynamic> data) {
    final direct = data['alarmLevel']?.toString().trim().toLowerCase() ?? '';

    if ({'info', 'warning', 'alarm', 'emergency'}.contains(direct)) {
      return direct;
    }

    final category = eventCategory(data);
    if (category == 'emergency') return 'emergency';
    if (category == 'system_warning') return 'warning';

    final severity = data['severity']?.toString().trim().toLowerCase() ?? '';
    if (severity == 'critical') return 'emergency';

    return 'alarm';
  }

  static String status(Map<String, dynamic> data) {
    final status =
        data['incidentStatus']?.toString().trim().toLowerCase() ??
        data['status']?.toString().trim().toLowerCase() ??
        '';

    return status.isEmpty ? 'active' : status;
  }
}
