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

bool isSosActive(Map<String, dynamic> d) {
  final status = d["status"]?.toString();
  final activeUntil =
      int.tryParse(d["sos_active_until"]?.toString() ?? "") ?? 0;

  return status == "triggered" ||
      activeUntil > DateTime.now().millisecondsSinceEpoch;
}

Map<String, dynamic> getOverallStatus(Map<String, dynamic> devices) {
  final dangerIssues = <String>[];
  final warningIssues = <String>[];
  final safeSummary = <String>[];

  int doorCount = 0;
  int closedDoorCount = 0;
  int deviceCount = 0;
  double? temperature;
  double? humidity;
  DateTime? newestLastSeen;

  devices.forEach((id, raw) {
    final d = safeMap(raw);

    deviceCount++;

    final name = d["name"]?.toString() ?? id;
    final type = d["type"]?.toString() ?? "door";
    final status = d["status"]?.toString();
    final contact = d["contact"];
    final tamper = d["tamper"] == true;

    final battery = int.tryParse(d["battery"]?.toString() ?? "");
    final linkquality = int.tryParse(d["linkquality"]?.toString() ?? "");
    final lastSeenTime = parseLastSeen(d["last_seen"]);

    final danger = <String>[];
    final warning = <String>[];

    if (type == "temperature") {
      temperature = double.tryParse(d["temperature"]?.toString() ?? "");
      humidity = double.tryParse(d["humidity"]?.toString() ?? "");

      if (temperature != null && temperature! >= 34) {
        warning.add("Nhiệt độ cao");
      }

      if (humidity != null && humidity! >= 80) {
        warning.add("Độ ẩm cao");
      }
    }

    if (type == "sos") {
      if (isSosActive(d)) {
        danger.add("SOS");
      }
    } else if (type == "smoke") {
      if (d["smoke"] == true || status == "alarm") {
        danger.add("Có khói");
      }
    } else if (type == "door" ||
        type == "window" ||
        type == "lock" ||
        type == "gate") {
      doorCount++;

      final isClosed = contact == true || status == "closed";

      if (isClosed && !tamper) {
        closedDoorCount++;
      }

      if (!isClosed) {
        danger.add("Đang mở");
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
      if (newestLastSeen == null || lastSeenTime.isAfter(newestLastSeen!)) {
        newestLastSeen = lastSeenTime;
      }

      final ageHours =
          DateTime.now().toUtc().difference(lastSeenTime.toUtc()).inMinutes /
              60;

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

  if (doorCount > 0) {
    safeSummary.add("$closedDoorCount/$doorCount cửa đã đóng an toàn");
  }

  if (temperature != null || humidity != null) {
    final tempText =
    temperature != null ? "${temperature!.toStringAsFixed(0)}°C" : "--°C";
    final humText =
    humidity != null ? "${humidity!.toStringAsFixed(0)}%" : "--%";

    safeSummary.add("Môi trường hiện tại: $tempText / $humText");
  }

  if (deviceCount > 0) {
    safeSummary.add("$deviceCount thiết bị đang được theo dõi");
  }

  if (newestLastSeen != null) {
    final minutes =
        DateTime.now().toUtc().difference(newestLastSeen!.toUtc()).inMinutes;

    if (minutes < 60) {
      safeSummary.add("Thiết bị vừa cập nhật $minutes phút trước");
    } else {
      safeSummary.add(
        "Thiết bị gần nhất cập nhật ${(minutes / 60).floor()} giờ trước",
      );
    }
  }

  if (safeSummary.isEmpty) {
    safeSummary.add("Chưa có dữ liệu thiết bị để đánh giá");
  }

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
    "safeSummary": safeSummary,
  };
}

bool isUnsafe(Map<dynamic, dynamic> devices) {
  return devices.values.any((raw) {
    final d = safeMap(raw);

    final type = d["type"]?.toString() ?? "door";
    final status = d["status"]?.toString();
    final contact = d["contact"];
    final tamper = d["tamper"] == true;

    if (tamper) return true;

    if (type == "sos") {
      return isSosActive(d);
    }

    if (type == "smoke") {
      return d["smoke"] == true || status == "alarm";
    }

    if (type == "door" ||
        type == "window" ||
        type == "lock" ||
        type == "gate") {
      final isClosed = contact == true || status == "closed";
      return !isClosed;
    }

    return false;
  });
}