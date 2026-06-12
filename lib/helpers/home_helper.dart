
Map<String, dynamic> safeMap(dynamic data) {
  if (data == null) return {};

  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  return {};
}

double heartbeatLimitHours(String type) {
  switch (type) {
    case "temperature":
      return 2;

    case "repeater":
      return 1;

    case "smoke":
      return 24;

    case "door":
    case "window":
    case "lock":
    case "gate":
    case "sos":
    default:
      return 6;
  }
}

DateTime? parseLastSeen(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  final millis = int.tryParse(text);
  if (millis != null && millis > 0) {
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  return DateTime.tryParse(text);
}

Map<String, dynamic> getOverallStatus(Map<String, dynamic> devices) {
  final dangerIssues = <String>[];
  final warningIssues = <String>[];

  devices.forEach((id, raw) {
    final d = safeMap(raw);

    final name = d["name"]?.toString() ?? id;
    final type = d["type"]?.toString() ?? "door";
    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    final battery = int.tryParse(d["battery"]?.toString() ?? "");
    final linkquality = int.tryParse(d["linkquality"]?.toString() ?? "");
    final lastSeenTime = parseLastSeen(d["last_seen"]);

    final danger = <String>[];
    final warning = <String>[];

    if (type == "sos") {
      if (status == "triggered") {
        danger.add("SOS");
      }
    } else if (type == "smoke") {
      if (d["smoke"] == true || status == "alarm") {
        danger.add("Có khói");
      }
    } else if (
    type == "door" ||
        type == "window" ||
        type == "lock" ||
        type == "gate") {
      if (status != "closed") {
        danger.add("Mở");
      }
    }

    if (tamper) {
      danger.add("Bị tháo");
    }

    if (battery != null && battery <= 20) {
      warning.add("Pin yếu");
    }

    if (linkquality != null && linkquality > 0 && linkquality < 40) {
      warning.add("Sóng yếu");
    }

    if (lastSeenTime != null) {
      final ageHours =
          DateTime.now().toUtc().difference(lastSeenTime.toUtc()).inMinutes / 60;

      final limit = heartbeatLimitHours(type);
      final offlineLimit = limit * 1.3;

      if (ageHours > offlineLimit) {
        warning.add("Mất kết nối");
      } else if (ageHours > limit) {
        warning.add("Lâu không cập nhật");
      }
    }

    if (danger.isNotEmpty) {
      dangerIssues.add("$name: ${danger.join(" & ")}");
    }

    if (warning.isNotEmpty) {
      warningIssues.add("$name: ${warning.join(" & ")}");
    }
  });

  final level = dangerIssues.isNotEmpty
      ? "danger"
      : warningIssues.isNotEmpty
      ? "warning"
      : "safe";

  return {
    "safe": level == "safe",
    "level": level,
    "dangerIssues": dangerIssues,
    "warningIssues": warningIssues,
    "issues": [...dangerIssues, ...warningIssues],
  };
}

bool isUnsafe(Map<dynamic, dynamic> devices) {
  return devices.values.any((raw) {
    final d = safeMap(raw);

    final type = d["type"]?.toString() ?? "door";
    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    if (tamper) return true;

    if (type == "sos") {
      return status == "triggered";
    }

    if (type == "smoke") {
      return d["smoke"] == true || status == "alarm";
    }

    if (
    type == "door" ||
        type == "window" ||
        type == "lock" ||
        type == "gate") {
      return status != "closed";
    }

    return false;
  });
}