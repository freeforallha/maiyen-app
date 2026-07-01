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
const double environmentWarningTemperatureC = 40;
const double environmentWarningHumidityPercent = 90;
double heartbeatLimitHours(String type) {
  switch (type) {
    case "temperature":
      return 2;

    case "repeater":
    case "hub":
      return 1;

    case "smoke":
    case "heat":
    case "carbon_monoxide":
    case "gas":
    case "water_leak":
    case "flood":
      return 24;

    case "door":
    case "window":
    case "lock":
    case "door_lock":
    case "gate":
    case "motion":
    case "presence":
    case "vibration":
    case "glass_break":
    case "sos":
    case "smart_plug":
    case "power_monitor":
    case "ups":
    case "siren":
    case "smart_valve":
    case "camera":
    case "doorbell":
    case "keypad":
    case "unknown":
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

bool isActiveDeviceSignal(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value?.toString().trim().toLowerCase() ?? "";

  return text == "true" ||
      text == "1" ||
      text == "on" ||
      text == "active" ||
      text == "alarm" ||
      text == "detected" ||
      text == "triggered" ||
      text == "emergency" ||
      text == "unsafe" ||
      text == "open" ||
      text == "unlocked";
}

String normalizeDeviceLockState(Map<String, dynamic> device) {
  final raw =
      device["lock_state"] ??
          device["lockState"] ??
          device["lock"] ??
          device["state"];

  if (raw is bool) {
    return raw ? "locked" : "unlocked";
  }

  if (raw is num) {
    return raw == 0 ? "unlocked" : "locked";
  }

  final text = raw?.toString().trim().toLowerCase() ?? "";

  if (text == "lock" ||
      text == "locked" ||
      text == "closed" ||
      text == "secure") {
    return "locked";
  }

  if (text == "unlock" ||
      text == "unlocked" ||
      text == "open" ||
      text == "unsecure") {
    return "unlocked";
  }

  final status =
      device["status"]?.toString().trim().toLowerCase() ?? "";

  if (status == "locked") return "locked";
  if (status == "unlocked") return "unlocked";

  final contact = parseDeviceBool(device["contact"]);

  if (contact == true) return "locked";
  if (contact == false) return "unlocked";

  return "";
}

String normalizeDeviceSwitchState(Map<String, dynamic> device) {
  final raw =
      device["state"] ??
          device["switch"] ??
          device["power_state"];

  if (raw is bool) {
    return raw ? "on" : "off";
  }

  if (raw is num) {
    return raw == 0 ? "off" : "on";
  }

  final text = raw?.toString().trim().toLowerCase() ?? "";

  if (text == "on" ||
      text == "open" ||
      text == "active" ||
      text == "running") {
    return "on";
  }

  if (text == "off" ||
      text == "closed" ||
      text == "inactive" ||
      text == "stopped") {
    return "off";
  }

  return "";
}

bool isRecentDeviceEvent(
    Map<String, dynamic> device, {
      int withinMs = 60 * 1000,
    }) {
  final eventTime = parseLastSeen(
    device["last_event"] ?? device["last_triggered"],
  );

  if (eventTime == null) {
    return false;
  }

  final ageMs = DateTime.now()
      .toUtc()
      .difference(eventTime.toUtc())
      .inMilliseconds;

  return ageMs >= 0 && ageMs <= withinMs;
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
  return value?.toString().trim().toLowerCase() == "armed" ? "armed" : "normal";
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

bool _hasTrueFlag(Map<String, dynamic> device, List<String> keys) {
  for (final key in keys) {
    if (isActiveDeviceSignal(device[key])) {
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
      device["type"]?.toString().trim().toLowerCase() ?? "unknown";
  final status =
      device["status"]?.toString().trim().toLowerCase() ?? "";

  final contact = parseDeviceBool(device["contact"]);
  final tamper = parseDeviceBool(device["tamper"]) == true;
  final availability = normalizeAvailability(device["availability"]);

  final battery = int.tryParse(device["battery"]?.toString() ?? "");
  final linkquality =
  int.tryParse(device["linkquality"]?.toString() ?? "");

  final dangerIssues = <String>[];
  final warningIssues = <String>[];

  final isLockDevice =
      type == "lock" || type == "door_lock";

  final isContactDevice =
      type == "door" ||
          type == "window" ||
          type == "gate" ||
          isLockDevice;

  final lockState =
  isLockDevice ? normalizeDeviceLockState(device) : "";

  final isClosed = isContactDevice &&
      (isLockDevice
          ? lockState == "locked"
          : contact == true ||
          status == "closed" ||
          status == "locked");

  final isOpen = isContactDevice &&
      (isLockDevice
          ? lockState == "unlocked"
          : contact == false ||
          status == "open" ||
          status == "unlocked");

  if (type == "temperature") {
    final temperature = double.tryParse(
      device["temperature"]?.toString() ?? "",
    );
    final humidity = double.tryParse(
      device["humidity"]?.toString() ?? "",
    );

    if (temperature != null &&
        temperature > environmentWarningTemperatureC) {
      warningIssues.add("Nhiệt độ cao");
    }

    if (humidity != null &&
        humidity >= environmentWarningHumidityPercent) {
      warningIssues.add("Độ ẩm cao");
    }
  }

  if (type == "sos" && isSosActive(device)) {
    dangerIssues.add("SOS");
  }

  if (type == "smoke" &&
      (isActiveDeviceSignal(device["smoke"]) ||
          status == "alarm")) {
    dangerIssues.add("Có khói");
  }

  if (type == "heat" &&
      (_hasTrueFlag(
        device,
        const [
          "heat",
          "heat_alarm",
          "high_temperature_alarm",
        ],
      ) ||
          status == "alarm")) {
    dangerIssues.add("Nhiệt độ nguy hiểm");
  }

  if (type == "carbon_monoxide" &&
      (_hasTrueFlag(
        device,
        const ["carbon_monoxide", "co_alarm"],
      ) ||
          status == "alarm")) {
    dangerIssues.add("Phát hiện khí CO");
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

  final motionActive =
      (type == "motion" || type == "presence") &&
          _hasTrueFlag(
            device,
            const ["occupancy", "motion", "presence"],
          );

  if (motionActive) {
    final issue = type == "presence"
        ? "Phát hiện hiện diện"
        : "Phát hiện chuyển động";

    if (isArmedMode || isNowInAlarmTime(device)) {
      dangerIssues.add(issue);
    } else {
      warningIssues.add(issue);
    }
  }

  final action =
      device["action"]?.toString().trim().toLowerCase() ?? "";

  final vibrationActive =
      (type == "vibration" || type == "glass_break") &&
          (_hasTrueFlag(
            device,
            const [
              "vibration",
              "shock",
              "glass_break",
              "broken_glass",
            ],
          ) ||
              (isRecentDeviceEvent(device) &&
                  (action.contains("vibration") ||
                      action.contains("shock") ||
                      action.contains("tilt") ||
                      action.contains("drop") ||
                      action.contains("glass"))));

  if (vibrationActive) {
    final issue = type == "glass_break"
        ? "Phát hiện kính vỡ"
        : "Phát hiện rung/chấn động";

    if (isArmedMode || isNowInAlarmTime(device)) {
      dangerIssues.add(issue);
    } else {
      warningIssues.add(issue);
    }
  }

  if (isOpen) {
    if (isLockDevice) {
      if (isArmedMode) {
        dangerIssues.add(
          "Khóa đang mở khi nhà ở chế độ Bảo vệ",
        );
      } else if (isNowInAlarmTime(device)) {
        dangerIssues.add("Khóa đang mở trong giờ Alarm");
      } else {
        warningIssues.add("Khóa đang mở");
      }
    } else {
      if (isArmedMode) {
        dangerIssues.add(
          "Đang mở khi nhà ở chế độ Bảo vệ",
        );
      } else if (isNowInAlarmTime(device)) {
        dangerIssues.add("Đang mở trong giờ Alarm");
      } else {
        warningIssues.add("Đang mở");
      }
    }
  }

  if (type == "power_monitor" || type == "ups") {
    final mainsPower =
    parseDeviceBool(
      device["mains_power"] ??
          device["ac_connected"] ??
          device["input_power"],
    );

    if (mainsPower == false) {
      warningIssues.add("Mất điện lưới");
    }
  }

  if (tamper) {
    dangerIssues.add("Bị tháo");
  }

  if (battery != null && battery <= 20) {
    warningIssues.add("Pin yếu");
  }

  if (linkquality != null &&
      linkquality > 0 &&
      linkquality < 40) {
    warningIssues.add("Sóng yếu");
  }

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
    "lockState": lockState,
  };
}

const int hubHeartbeatTimeoutMs = 90 * 1000;

DateTime _hubStatusGraceUntil =
DateTime.fromMillisecondsSinceEpoch(0);

void startHubStatusGracePeriod({
  Duration duration = const Duration(seconds: 35),
}) {
  final now = DateTime.now();

  // Không gia hạn lại nếu khoảng kiểm tra hiện tại vẫn đang chạy.
  if (now.isBefore(_hubStatusGraceUntil)) {
    return;
  }

  _hubStatusGraceUntil = now.add(duration);
}

bool get _hubStatusInGracePeriod {
  return DateTime.now().isBefore(_hubStatusGraceUntil);
}

Map<String, dynamic> evaluateHubStatus(dynamic rawHome) {
  final home = safeMap(rawHome);
  final hubId = home["hubId"]?.toString().trim() ?? "";

  if (hubId.isEmpty) {
    return {
      "tracked": false,
      "online": true,
      "checking": false,
      "issue": "",
    };
  }

  final hubStatus = safeMap(home["hubStatus"]);
  final heartbeatTime = parseLastSeen(
    hubStatus["lastHeartbeatAt"],
  );

  if (heartbeatTime == null) {
    if (_hubStatusInGracePeriod) {
      return {
        "tracked": true,
        "online": true,
        "checking": true,
        "issue": "",
      };
    }

    return {
      "tracked": true,
      "online": false,
      "checking": false,
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
    if (_hubStatusInGracePeriod) {
      return {
        "tracked": true,
        "online": true,
        "checking": true,
        "issue": "",
      };
    }

    return {
      "tracked": true,
      "online": false,
      "checking": false,
      "issue": "Hub mất kết nối",
    };
  }

  if (parseDeviceBool(hubStatus["mqttConnected"]) != true) {
    if (_hubStatusInGracePeriod) {
      return {
        "tracked": true,
        "online": true,
        "checking": true,
        "issue": "",
      };
    }

    return {
      "tracked": true,
      "online": false,
      "checking": false,
      "issue": "MQTT mất kết nối",
    };
  }

  return {
    "tracked": true,
    "online": true,
    "checking": false,
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
// Nhà chưa có thiết bị thì Hub không được làm trạng thái
// chuyển thành an toàn, nguy hiểm hoặc đang giám sát.
  if (overall["hasDevices"] != true) {
    return {
      ...overall,
      "safe": false,
      "level": "no_data",
      "dangerIssues": <String>[],
      "warningIssues": <String>[],
      "issues": <String>[],
      "safeSummary": <String>[
        "Chưa có dữ liệu để đánh giá",
      ],
      "hubTracked": false,
      "hubOnline": false,
      "hubChecking": false,
      "hubIssue": "",
    };
  }
  final dangerIssues = List<String>.from(
    overall["dangerIssues"] ?? const <String>[],
  );

  final warningIssues = List<String>.from(
    overall["warningIssues"] ?? const <String>[],
  );

  final safeSummary = List<String>.from(
    overall["safeSummary"] ?? const <String>[],
  );

  // ================= HUB =================

  final hub = evaluateHubStatus(home);

  final hubTracked = hub["tracked"] == true;
  final hubOnline = hub["online"] == true;
  final hubChecking = hub["checking"] == true;
  final hubIssue = hub["issue"]?.toString().trim() ?? "";

  if (hubTracked && hubChecking) {
    safeSummary.insert(0, "Đang kiểm tra kết nối Hub");
  } else if (hubTracked && !hubOnline && hubIssue.isNotEmpty) {
    dangerIssues.insert(0, hubIssue);
  } else if (hubTracked && hubOnline) {
    safeSummary.insert(0, "Hub đã kết nối");
  }

  // ================= THÀNH VIÊN =================

  final autoAway = safeMap(home["autoAway"]);

  final homeLatitude = double.tryParse(
    autoAway["latitude"]?.toString() ?? "",
  );

  final homeLongitude = double.tryParse(
    autoAway["longitude"]?.toString() ?? "",
  );

  final presenceTrackingEnabled =
      autoAway["enabled"] == true &&
          homeLatitude != null &&
          homeLongitude != null;

  // Chỉ đánh giá vị trí thành viên khi nhà đã đặt vị trí
  // và đang bật tính năng tự động nhận biết ra/vào nhà.
  if (presenceTrackingEnabled) {
    final presenceSummary = safeMap(
      home["presenceSummary"],
    );

    final memberCount = int.tryParse(
      presenceSummary["memberCount"]?.toString() ?? "",
    ) ??
        0;

    final insideCount = int.tryParse(
      presenceSummary["insideCount"]?.toString() ?? "",
    ) ??
        0;

    final unknownCount = int.tryParse(
      presenceSummary["unknownCount"]?.toString() ?? "",
    ) ??
        0;

    if (memberCount > 0) {
      final memberText =
          "Thành viên trong nhà $insideCount/$memberCount";

      if (insideCount > 0) {
        safeSummary.add(memberText);
      } else if (dangerIssues.isNotEmpty) {
        dangerIssues.add(memberText);
      } else {
        warningIssues.add(memberText);
      }

      if (unknownCount > 0) {
        warningIssues.add(
          "Thành viên chưa xác định vị trí: $unknownCount",
        );
      }
    }
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
    "hubChecking": hubChecking,
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
  final deviceTypes = <String>{};
  double? temperature;
  double? humidity;
  DateTime? newestLastSeen;
  DateTime? newestEnvironmentSeen;

  devices.forEach((id, raw) {
    final device = safeMap(raw);

    if (device.isEmpty) {
      return;
    }

    final nameText = device["name"]?.toString().trim() ?? "";
    final name = nameText.isNotEmpty ? nameText : id;
    final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";
    final lastSeenTime = parseLastSeen(device["last_seen"]);

    deviceCount++;
    deviceTypes.add(type);
    final latestSeen = newestLastSeen;

    if (lastSeenTime != null &&
        (latestSeen == null || lastSeenTime.isAfter(latestSeen))) {
      newestLastSeen = lastSeenTime;
    }

    if (type == "temperature") {
      final currentTemperature = double.tryParse(
        device["temperature"]?.toString() ?? "",
      );
      final currentHumidity = double.tryParse(
        device["humidity"]?.toString() ?? "",
      );

      final latestEnvironmentSeen = newestEnvironmentSeen;
      final shouldUseEnvironment =
          latestEnvironmentSeen == null ||
              (lastSeenTime != null && lastSeenTime.isAfter(latestEnvironmentSeen));

      if (shouldUseEnvironment) {
        temperature = currentTemperature;
        humidity = currentHumidity;

        if (lastSeenTime != null) {
          newestEnvironmentSeen = lastSeenTime;
        }
      }
    }

    final evaluation = evaluateDeviceStatus(device, securityMode: securityMode);

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
  if (deviceCount == 0) {
    return {
      "safe": false,
      "level": "no_data",
      "dangerIssues": <String>[],
      "warningIssues": <String>[],
      "issues": <String>[],
      "safeSummary": <String>[
        "Chưa có dữ liệu để đánh giá",
      ],
      "deviceCount": 0,
      "hasDevices": false,
      "deviceTypes": <String>[],
      "hasContactDevice": false,
      "hasSmokeDevice": false,
      "hasSosDevice": false,
      "hasEnvironmentDevice": false,
      "hasEmergencyDevice": false,
      "hasInfrastructureDevice": false,
    };
  }

  final hasContactDevice = deviceTypes.any(
    const {
      "door",
      "window",
      "gate",
      "lock",
      "door_lock",
    }.contains,
  );

  final hasSmokeDevice = deviceTypes.contains("smoke");
  final hasSosDevice = deviceTypes.contains("sos");
  final hasEnvironmentDevice = deviceTypes.contains("temperature");

  final hasEmergencyDevice = deviceTypes.any(
    const {
      "smoke",
      "heat",
      "carbon_monoxide",
      "gas",
      "water_leak",
      "flood",
      "sos",
    }.contains,
  );

  final hasInfrastructureDevice = deviceTypes.any(
    const {
      "repeater",
      "hub",
    }.contains,
  );
  if (doorCount > 0) {
    safeSummary.add("$closedDoorCount/$doorCount cửa và khóa đã an toàn");
  }

  if (temperature != null || humidity != null) {
    final currentTemperature = temperature;
    final currentHumidity = humidity;
    final tempText = currentTemperature != null
        ? "${currentTemperature.toStringAsFixed(0)}°C"
        : "--°C";
    final humText = currentHumidity != null
        ? "${currentHumidity.toStringAsFixed(0)}%"
        : "--%";

    safeSummary.add("Môi trường hiện tại: $tempText / $humText");
  }

  if (deviceCount > 0) {
    safeSummary.add("$deviceCount thiết bị đang được theo dõi");
  }

  final latestSeen = newestLastSeen;

  if (latestSeen != null) {
    var minutes = DateTime.now()
        .toUtc()
        .difference(latestSeen.toUtc())
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

    // Thông tin này giúp Status Panel chỉ mô tả
    // đúng những loại cảm biến thực sự đang có.
    "deviceCount": deviceCount,
    "hasDevices": true,
    "deviceTypes": deviceTypes.toList(),
    "hasContactDevice": hasContactDevice,
    "hasSmokeDevice": hasSmokeDevice,
    "hasSosDevice": hasSosDevice,
    "hasEnvironmentDevice": hasEnvironmentDevice,
    "hasEmergencyDevice": hasEmergencyDevice,
    "hasInfrastructureDevice": hasInfrastructureDevice,
  };
}

bool isUnsafe(Map<dynamic, dynamic> devices, {String securityMode = "normal"}) {
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
