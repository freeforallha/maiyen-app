
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
    final lastSeen = int.tryParse(d["last_seen"]?.toString() ?? "");

    final danger = <String>[];
    final warning = <String>[];

    if (type == "sos" && status == "triggered") {
      danger.add("SOS");
    } else if (type == "smoke" && (d["smoke"] == true || status == "alarm")) {
      danger.add("Có khói");
    } else if (type == "door" && status != "closed") {
      danger.add("Mở");
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

    if (lastSeen != null && lastSeen > 0) {
      final lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      final offlineHours = DateTime.now().difference(lastSeenTime).inHours;

      if (offlineHours >= 2) {
        warning.add("Offline lâu");
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
}bool isUnsafe(Map<dynamic, dynamic> devices) {
  return devices.values.any((raw) {
    final d = safeMap(raw);

    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    return status != "closed" || tamper;
  });
}