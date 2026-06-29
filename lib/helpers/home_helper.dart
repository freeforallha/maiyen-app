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
    case "door_lock":
    case "gate":
    case "motion":
    case "gas":
    case "water_leak":
    case "flood":
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

String normalizeSecurityMode(dynamic value) {
  return value?.toString().trim().toLowerCase() == "armed"
      ? "armed"
      : "normal";
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

bool _hasTrueFlag(
    Map<String, dynamic> device,
    List<String> keys,
    ) {
  for (final key in keys) {
    if (parseDeviceBool(device[key]) == true) {
      return true;
    }
  }

  return false;
}

/// Nguồn rule duy nhất cho trạng thái của một thiết bị.
///
/// level:
/// - danger: Chưa an toàn
/// - warning: Cần chú ý
/// - safe: Đã an toàn
Map<String, dynamic> evaluateDeviceStatus(
    Map<String, dynamic> device, {
      String securityMode = "normal",
    }) {
  final normalizedMode = normalizeSecurityMode(securityMode);
  final isArmedMode = normalizedMode == "armed";

  final type =
      device["type"]?.toString().trim().toLowerCase() ?? "door";
  final status =
      device["status"]?.toString().trim().toLowerCase() ?? "";

  final contact = parseDeviceBool(device["contact"]);
  final tamper = parseDeviceBool(device["tamper"]) == true;
  final smoke = parseDeviceBool(device["smoke"]) == true;
  final availability = normalizeAvailability(device["availability"]);

  final battery = int.tryParse(device["battery"]?.toString() ?? "");
  final linkquality =
  int.tryParse(device["linkquality"]?.toString() ?? "");

  final dangerIssues = <String>[];
  final warningIssues = <String>[];

  final isContactDevice = type == "door" ||
      type == "window" ||
      type == "lock" ||
      type == "door_lock" ||
      type == "gate";

  final isClosed =
      isContactDevice && (contact == true || status == "closed");
  final isOpen =
      isContactDevice && (contact == false || status == "open");

  if (type == "temperature") {
    final temperature =
    double.tryParse(device["temperature"]?.toString() ?? "");
    final humidity =
    double.tryParse(device["humidity"]?.toString() ?? "");

    if (temperature != null && temperature >= 34) {
      warningIssues.add("Nhiệt độ cao");
    }

    if (humidity != null && humidity >= 80) {
      warningIssues.add("Độ ẩm cao");
    }
  }

  if (type == "sos" && isSosActive(device)) {
    dangerIssues.add("SOS");
  }

  if (type == "smoke" && (smoke || status == "alarm")) {
    dangerIssues.add("Có khói");
  }

  if (type == "gas" &&
      (_hasTrueFlag(device, const ["gas", "gas_alarm"]) ||
          status == "alarm")) {
    dangerIssues.add("Rò rỉ gas");
  }

  if ((type == "water_leak" || type == "flood") &&
      (_hasTrueFlag(
        device,
        const ["water_leak", "leak", "water"],
      ) ||
          status == "alarm")) {
    dangerIssues.add("Phát hiện ngập nước");
  }

  final motionActive = type == "motion" &&
      _hasTrueFlag(
        device,
        const ["occupancy", "motion", "presence"],
      );

  if (motionActive) {
    if (isArmedMode || isNowInAlarmTime(device)) {
      dangerIssues.add("Phát hiện chuyển động");
    } else {
      warningIssues.add("Phát hiện chuyển động");
    }
  }

  if (isOpen) {
    if (isArmedMode) {
      dangerIssues.add("Đang mở khi nhà ở chế độ Bảo vệ");
    } else if (isNowInAlarmTime(device)) {
      dangerIssues.add("Đang mở trong giờ Alarm");
    } else {
      warningIssues.add("Đang mở");
    }
  }

  if (tamper) {
    dangerIssues.add("Bị tháo");
  }

  if (battery != null && battery <= 20) {
    warningIssues.add("Pin yếu");
  }

  if (linkquality != null && linkquality > 0 && linkquality < 40) {
    warningIssues.add("Sóng yếu");
  }

  // availability là nguồn xác định Online/Offline.
  // last_seen chỉ dùng để hiển thị thời điểm cập nhật.
  if (availability == "offline") {
    warningIssues.add("Mất kết nối");
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
    "isContactDevice": isContactDevice,
    "isClosed": isClosed,
    "isOpen": isOpen,
  };
}

const int hubHeartbeatTimeoutMs = 90 * 1000;

Map<String, dynamic> evaluateHubStatus(dynamic rawHome) {
  final home = safeMap(rawHome);
  final hubId = home["hubId"]?.toString().trim() ?? "";

  // Nhà chưa được liên kết Hub sẽ không bị đánh dấu lỗi.
  if (hubId.isEmpty) {
    return {
      "tracked": false,
      "online": true,
      "issue": "",
    };
  }

  final hubStatus = safeMap(home["hubStatus"]);
  final heartbeatTime = parseLastSeen(
    hubStatus["lastHeartbeatAt"],
  );

  if (heartbeatTime == null) {
    return {
      "tracked": true,
      "online": false,
      "issue": "Hub chưa gửi trạng thái",
    };
  }

  var heartbeatAgeMs = DateTime.now()
      .toUtc()
      .difference(heartbeatTime.toUtc())
      .inMilliseconds;

  if (heartbeatAgeMs < 0) {
    heartbeatAgeMs = 0;
  }

  if (heartbeatAgeMs > hubHeartbeatTimeoutMs) {
    return {
      "tracked": true,
      "online": false,
      "issue": "Hub mất kết nối",
    };
  }

  if (parseDeviceBool(hubStatus["mqttConnected"]) != true) {
    return {
      "tracked": true,
      "online": false,
      "issue": "MQTT mất kết nối",
    };
  }

  return {
    "tracked": true,
    "online": true,
    "issue": "",
  };
}

/// Nguồn rule duy nhất cho trạng thái của một nhà.
///
/// Tự đọc securityMode và heartbeat của chính ngôi nhà, tránh việc
/// các màn hình cho ra màu hoặc trạng thái khác nhau.
Map<String, dynamic> getHomeOverallStatus(dynamic rawHome) {
  final home = safeMap(rawHome);
  final overall = getOverallStatus(
    safeMap(home["devices"]),
    securityMode: normalizeSecurityMode(home["securityMode"]),
  );

  final dangerIssues = List<String>.from(
    overall["dangerIssues"] ?? const <String>[],
  );
  final warningIssues = List<String>.from(
    overall["warningIssues"] ?? const <String>[],
  );
  final safeSummary = List<String>.from(
    overall["safeSummary"] ?? const <String>[],
  );

  final hub = evaluateHubStatus(home);
  final hubTracked = hub["tracked"] == true;
  final hubOnline = hub["online"] == true;
  final hubIssue = hub["issue"]?.toString().trim() ?? "";

  if (hubTracked && !hubOnline && hubIssue.isNotEmpty) {
    dangerIssues.insert(0, hubIssue);
  } else if (hubTracked && hubOnline) {
    safeSummary.insert(0, "Hub đang kết nối");
  }

  final level = dangerIssues.isNotEmpty
      ? "danger"
      : warningIssues.isNotEmpty
      ? "warning"
      : "safe";

  return {
    ...overall,
    "safe": level == "safe",
    "level": level,
    "dangerIssues": dangerIssues,
    "warningIssues": warningIssues,
    "issues": [...dangerIssues, ...warningIssues],
    "safeSummary": safeSummary,
    "hubTracked": hubTracked,
    "hubOnline": hubOnline,
    "hubIssue": hubIssue,
  };
}

Map<String, dynamic> getOverallStatus(
    Map<String, dynamic> devices, {
      String securityMode = "normal",
    }) {
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
    final device = safeMap(raw);
    final nameText = device["name"]?.toString().trim() ?? "";
    final name = nameText.isNotEmpty ? nameText : id;
    final type =
        device["type"]?.toString().trim().toLowerCase() ?? "door";
    final lastSeenTime = parseLastSeen(device["last_seen"]);

    deviceCount++;

    if (lastSeenTime != null &&
        (newestLastSeen == null ||
            lastSeenTime.isAfter(newestLastSeen!))) {
      newestLastSeen = lastSeenTime;
    }

    if (type == "temperature") {
      final currentTemperature =
      double.tryParse(device["temperature"]?.toString() ?? "");
      final currentHumidity =
      double.tryParse(device["humidity"]?.toString() ?? "");

      final shouldUseEnvironment = newestEnvironmentSeen == null ||
          (lastSeenTime != null &&
              lastSeenTime.isAfter(newestEnvironmentSeen!));

      if (shouldUseEnvironment) {
        temperature = currentTemperature;
        humidity = currentHumidity;

        if (lastSeenTime != null) {
          newestEnvironmentSeen = lastSeenTime;
        }
      }
    }

    final evaluation = evaluateDeviceStatus(
      device,
      securityMode: securityMode,
    );

    if (evaluation["isContactDevice"] == true) {
      doorCount++;

      if (evaluation["isClosed"] == true &&
          parseDeviceBool(device["tamper"]) != true) {
        closedDoorCount++;
      }
    }

    final deviceDangerIssues = List<String>.from(
      evaluation["dangerIssues"] ?? const <String>[],
    );
    final deviceWarningIssues = List<String>.from(
      evaluation["warningIssues"] ?? const <String>[],
    );

    if (deviceDangerIssues.isNotEmpty) {
      dangerIssues.add("$name: ${deviceDangerIssues.join(" & ")}");
    }

    if (deviceWarningIssues.isNotEmpty) {
      warningIssues.add("$name: ${deviceWarningIssues.join(" & ")}");
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

bool isUnsafe(
    Map<dynamic, dynamic> devices, {
      String securityMode = "normal",
    }) {
  final normalizedDevices = <String, dynamic>{};

  for (final entry in devices.entries) {
    normalizedDevices[entry.key.toString()] = entry.value;
  }

  return getOverallStatus(
    normalizedDevices,
    securityMode: securityMode,
  )["level"] !=
      "safe";
}
