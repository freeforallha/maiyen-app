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

  final number = int.tryParse(text);

  if (number != null && number > 0) {
    final milliseconds = number < 1000000000000 ? number * 1000 : number;

    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  return DateTime.tryParse(text);
}

bool? parseDeviceBool(dynamic value) {
  if (value is bool) return value;

  final text = value?.toString().trim().toLowerCase();

  if (text == "true" || text == "1" || text == "on") {
    return true;
  }

  if (text == "false" || text == "0" || text == "off") {
    return false;
  }

  return null;
}

String normalizeAvailability(dynamic value) {
  if (value is bool) {
    return value ? "online" : "offline";
  }

  final text = value?.toString().trim().toLowerCase() ?? "";

  if (text == "online" ||
      text == "available" ||
      text == "true" ||
      text == "1") {
    return "online";
  }

  if (text == "offline" ||
      text == "unavailable" ||
      text == "false" ||
      text == "0") {
    return "offline";
  }

  return "";
}

bool isSosActive(Map<String, dynamic> d) {
  final status = d["status"]?.toString().trim().toLowerCase();
  final activeUntil =
      int.tryParse(d["sos_active_until"]?.toString() ?? "") ?? 0;

  return status == "triggered" ||
      activeUntil > DateTime.now().millisecondsSinceEpoch;
}

bool isNowInAlarmTime(Map<String, dynamic> d) {
  final alarm = safeMap(d["alarm"]);

  if (alarm["enabled"] != true) return false;

  final startText = alarm["start"]?.toString() ?? "23:00";
  final endText = alarm["end"]?.toString() ?? "06:00";

  int toMinute(String text) {
    final parts = text.split(":");
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : "") ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : "") ?? 0;

    return h * 60 + m;
  }

  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;
  final startMin = toMinute(startText);
  final endMin = toMinute(endText);

  if (startMin > endMin) {
    return nowMin >= startMin || nowMin <= endMin;
  }

  return nowMin >= startMin && nowMin <= endMin;
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
  DateTime? newestEnvironmentSeen;

  devices.forEach((id, raw) {
    final d = safeMap(raw);

    deviceCount++;

    final name = d["name"]?.toString() ?? id;
    final type =
        d["type"]?.toString().trim().toLowerCase() ?? "door";
    final status =
        d["status"]?.toString().trim().toLowerCase() ?? "";

    final contact = parseDeviceBool(d["contact"]);
    final tamper = parseDeviceBool(d["tamper"]) == true;
    final smoke = parseDeviceBool(d["smoke"]) == true;
    final availability = normalizeAvailability(d["availability"]);

    final battery = int.tryParse(d["battery"]?.toString() ?? "");
    final linkquality =
    int.tryParse(d["linkquality"]?.toString() ?? "");
    final lastSeenTime = parseLastSeen(d["last_seen"]);

    final danger = <String>[];
    final warning = <String>[];

    if (lastSeenTime != null) {
      if (newestLastSeen == null ||
          lastSeenTime.isAfter(newestLastSeen!)) {
        newestLastSeen = lastSeenTime;
      }
    }

    if (type == "temperature") {
      final currentTemperature =
      double.tryParse(d["temperature"]?.toString() ?? "");
      final currentHumidity =
      double.tryParse(d["humidity"]?.toString() ?? "");

      final shouldUseEnvironment =
          newestEnvironmentSeen == null ||
              (lastSeenTime != null &&
                  lastSeenTime.isAfter(newestEnvironmentSeen!));

      if (shouldUseEnvironment) {
        temperature = currentTemperature;
        humidity = currentHumidity;

        if (lastSeenTime != null) {
          newestEnvironmentSeen = lastSeenTime;
        }
      }

      if (currentTemperature != null && currentTemperature >= 34) {
        warning.add("Nhiệt độ cao");
      }

      if (currentHumidity != null && currentHumidity >= 80) {
        warning.add("Độ ẩm cao");
      }
    }

    if (type == "sos") {
      if (isSosActive(d)) {
        danger.add("SOS");
      }
    } else if (type == "smoke") {
      if (smoke || status == "alarm") {
        danger.add("Có khói");
      }
    } else if (type == "door" ||
        type == "window" ||
        type == "lock" ||
        type == "gate") {
      doorCount++;

      final isClosed = contact == true || status == "closed";
      final isOpen = contact == false || status == "open";

      if (isClosed && !tamper) {
        closedDoorCount++;
      }

      if (isOpen) {
        if (isNowInAlarmTime(d)) {
          danger.add("Đang mở trong giờ Alarm");
        } else {
          warning.add("Đang mở");
        }
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

    // availability mới là nguồn xác định Online/Offline.
    // last_seen chỉ là thời điểm gửi dữ liệu gần nhất, không dùng để
    // kết luận mất kết nối vì thiết bị pin có thể ngủ nhiều giờ.
    if (availability == "offline") {
      warning.add("Mất kết nối");
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
    final tempText = temperature != null
        ? "${temperature!.toStringAsFixed(0)}°C"
        : "--°C";
    final humText =
    humidity != null ? "${humidity!.toStringAsFixed(0)}%" : "--%";

    safeSummary.add("Môi trường hiện tại: $tempText / $humText");
  }

  if (deviceCount > 0) {
    safeSummary.add("$deviceCount thiết bị đang được theo dõi");
  }

  if (newestLastSeen != null) {
    var minutes = DateTime.now()
        .toUtc()
        .difference(newestLastSeen!.toUtc())
        .inMinutes;

    if (minutes < 0) {
      minutes = 0;
    }

    if (minutes < 60) {
      safeSummary.add("Dữ liệu gần nhất cập nhật $minutes phút trước");
    } else {
      safeSummary.add(
        "Dữ liệu gần nhất cập nhật ${(minutes / 60).floor()} giờ trước",
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

    final type =
        d["type"]?.toString().trim().toLowerCase() ?? "door";
    final status =
        d["status"]?.toString().trim().toLowerCase() ?? "";
    final contact = parseDeviceBool(d["contact"]);
    final tamper = parseDeviceBool(d["tamper"]) == true;
    final smoke = parseDeviceBool(d["smoke"]) == true;

    if (tamper) return true;

    if (type == "sos") {
      return isSosActive(d);
    }

    if (type == "smoke") {
      return smoke || status == "alarm";
    }

    if (type == "door" ||
        type == "window" ||
        type == "lock" ||
        type == "gate") {
      return contact == false || status == "open";
    }

    return false;
  });
}
