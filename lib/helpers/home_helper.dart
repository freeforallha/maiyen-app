import 'package:firebase_auth/firebase_auth.dart';

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

const int emergencyStatusHoldMs = 5 * 60 * 1000;

Map<String, int> resolveAutoAwayPresenceDisplayCounts(dynamic rawHome) {
  final home = safeMap(rawHome);
  final autoAway = safeMap(home["autoAway"]);
  final presenceSummary = safeMap(home["presenceSummary"]);
  final memberPresenceStatus = safeMap(home["memberPresenceStatus"]);

  int summaryCount(String key) {
    return int.tryParse(presenceSummary[key]?.toString() ?? "") ?? 0;
  }

  final configuredParticipantUids = safeMap(autoAway["participantUids"]).entries
      .where((entry) => entry.value == true)
      .map((entry) => entry.key.toString().trim())
      .where((uid) => uid.isNotEmpty)
      .toSet();

  final flaggedParticipantUids = memberPresenceStatus.entries
      .where((entry) {
        final status = safeMap(entry.value);
        return status["autoAwayParticipant"] == true;
      })
      .map((entry) => entry.key.toString().trim())
      .where((uid) => uid.isNotEmpty)
      .toSet();

  final selectedParticipantUids = <String>{};

  if (configuredParticipantUids.isNotEmpty) {
    selectedParticipantUids.addAll(configuredParticipantUids);
  } else if (flaggedParticipantUids.isNotEmpty) {
    selectedParticipantUids.addAll(flaggedParticipantUids);
  } else {
    // Nhà cũ chưa có participantUids tiếp tục dùng toàn bộ thành viên.
    selectedParticipantUids.addAll(
      memberPresenceStatus.keys
          .map((uid) => uid.toString().trim())
          .where((uid) => uid.isNotEmpty),
    );
  }

  var totalMemberCount = summaryCount("totalMemberCount");

  if (memberPresenceStatus.length > totalMemberCount) {
    totalMemberCount = memberPresenceStatus.length;
  }

  if (selectedParticipantUids.length > totalMemberCount) {
    totalMemberCount = selectedParticipantUids.length;
  }

  var participantCount = selectedParticipantUids.length;
  final summaryParticipantCount = summaryCount("participantCount");

  if (participantCount <= 0 && summaryParticipantCount > 0) {
    participantCount = summaryParticipantCount;
  }

  if (participantCount <= 0 && totalMemberCount > 0) {
    participantCount = totalMemberCount;
  }

  var insideCount = 0;
  var outsideCount = 0;
  var unknownCount = 0;

  if (selectedParticipantUids.isNotEmpty) {
    for (final participantUid in selectedParticipantUids) {
      final status = safeMap(memberPresenceStatus[participantUid]);
      final state =
          status["state"]?.toString().trim().toLowerCase() ?? "unknown";

      if (state == "inside") {
        insideCount++;
      } else if (state == "outside") {
        outsideCount++;
      } else {
        unknownCount++;
      }
    }
  } else {
    final hasParticipantBreakdown =
        presenceSummary.containsKey("participantInsideCount") ||
        presenceSummary.containsKey("participantOutsideCount") ||
        presenceSummary.containsKey("participantUnknownCount");

    if (hasParticipantBreakdown) {
      insideCount = summaryCount("participantInsideCount");
      outsideCount = summaryCount("participantOutsideCount");
      unknownCount = summaryCount("participantUnknownCount");
    } else if (participantCount == totalMemberCount) {
      insideCount = summaryCount("insideCount");
      outsideCount = summaryCount("outsideCount");
      unknownCount = summaryCount("unknownCount");
    } else {
      // Không có danh tính hoặc breakdown của nhóm được chọn thì không được
      // gán nhầm trạng thái của thành viên ngoài nhóm vào số liệu hiển thị.
      unknownCount = participantCount;
    }
  }

  if (insideCount < 0) {
    insideCount = 0;
  }

  if (outsideCount < 0) {
    outsideCount = 0;
  }

  if (insideCount > participantCount) {
    insideCount = participantCount;
  }

  final remainingAfterInside = participantCount - insideCount;

  if (outsideCount > remainingAfterInside) {
    outsideCount = remainingAfterInside;
  }

  // Unknown luôn là phần còn lại của chính nhóm được chọn. Cách này tránh
  // hiển thị tổng lớn hơn mẫu số khi dữ liệu backend đang chuyển trạng thái.
  unknownCount = participantCount - insideCount - outsideCount;

  return <String, int>{
    "insideCount": insideCount,
    "outsideCount": outsideCount,
    "unknownCount": unknownCount,
    "participantCount": participantCount,
    "totalMemberCount": totalMemberCount,
  };
}

const Set<String> emergencyStatusDeviceTypes = {
  "smoke",
  "heat",
  "temperature",
  "carbon_monoxide",
  "gas",
  "water_leak",
  "flood",
  "sos",
  "smart_plug",
  "power_monitor",
  "ups",
  "electrical_fault",
  "short_circuit",
};

bool isEmergencyStatusDeviceType(dynamic rawType) {
  final type = rawType?.toString().trim().toLowerCase() ?? "";
  return emergencyStatusDeviceTypes.contains(type);
}

int emergencyStatusTriggeredAt(Map<String, dynamic> device) {
  final genericTriggeredAt =
      int.tryParse(device["emergency_triggered_at"]?.toString() ?? "") ?? 0;

  if (genericTriggeredAt > 0) {
    return genericTriggeredAt;
  }

  final type = device["type"]?.toString().trim().toLowerCase() ?? "";

  if (type != "sos") {
    return 0;
  }

  return int.tryParse(device["last_triggered"]?.toString() ?? "") ?? 0;
}

int emergencyStatusActiveUntil(Map<String, dynamic> device) {
  final genericActiveUntil =
      int.tryParse(device["emergency_active_until"]?.toString() ?? "") ?? 0;

  if (genericActiveUntil > 0) {
    return genericActiveUntil;
  }

  final type = device["type"]?.toString().trim().toLowerCase() ?? "";

  if (type != "sos") {
    return 0;
  }

  return int.tryParse(device["sos_active_until"]?.toString() ?? "") ?? 0;
}

int emergencyAcknowledgedTriggerForCurrentUser(Map<String, dynamic> device) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  if (uid.isEmpty) {
    return 0;
  }

  final acknowledgements = safeMap(device["emergencyAcknowledgements"]);
  final sosAcknowledgements = safeMap(device["sosAcknowledgements"]);
  final genericValue =
      int.tryParse(acknowledgements[uid]?.toString() ?? "") ?? 0;
  final sosValue =
      int.tryParse(sosAcknowledgements[uid]?.toString() ?? "") ?? 0;

  return genericValue > sosValue ? genericValue : sosValue;
}

bool isEmergencyStatusAcknowledgedByCurrentUser(Map<String, dynamic> device) {
  final triggeredAt = emergencyStatusTriggeredAt(device);

  return triggeredAt > 0 &&
      emergencyAcknowledgedTriggerForCurrentUser(device) >= triggeredAt;
}

bool isEmergencyStatusActiveForCurrentUser(
  Map<String, dynamic> device, {
  bool legacyActive = false,
}) {
  final triggeredAt = emergencyStatusTriggeredAt(device);

  // Dữ liệu mới luôn dùng mốc giữ trạng thái 5 phút và xác nhận theo tài khoản.
  if (triggeredAt > 0) {
    if (isEmergencyStatusAcknowledgedByCurrentUser(device)) {
      return false;
    }

    return emergencyStatusActiveUntil(device) >
        DateTime.now().millisecondsSinceEpoch;
  }

  // Tương thích thiết bị/backend cũ chưa có trường emergency_* .
  return legacyActive;
}

const Set<String> securityDeviceTypes = {
  "door",
  "window",
  "gate",
  "lock",
  "door_lock",
  "motion",
  "presence",
  "vibration",
  "glass_break",
};

bool isSecurityDeviceType(dynamic rawType) {
  final type = rawType?.toString().trim().toLowerCase() ?? "";
  return securityDeviceTypes.contains(type);
}

double heartbeatLimitHours(String type) {
  switch (type) {
    case "temperature":
      return 2;

    case "repeater":
    case "hub":
    case "siren":
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

  final status = device["status"]?.toString().trim().toLowerCase() ?? "";

  if (status == "locked") return "locked";
  if (status == "unlocked") return "unlocked";

  final contact = parseDeviceBool(device["contact"]);

  if (contact == true) return "locked";
  if (contact == false) return "unlocked";

  return "";
}

String normalizeDeviceSwitchState(Map<String, dynamic> device) {
  final raw = device["state"] ?? device["switch"] ?? device["power_state"];

  if (raw is bool) {
    return raw ? "on" : "off";
  }

  if (raw is num) {
    return raw == 0 ? "off" : "on";
  }

  final text = raw?.toString().trim().toLowerCase() ?? "";

  if (text == "on" || text == "open" || text == "active" || text == "running") {
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

bool isVibrationEventActive(
  Map<String, dynamic> device, {
  int withinMs = 15 * 1000,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final activeUntil =
      int.tryParse(device["vibration_active_until"]?.toString() ?? "") ?? 0;

  // Khi backend đã ghi cửa sổ rung, đây là nguồn trạng thái ưu tiên.
  // Nhờ vậy một packet `vibration: true` bị kẹt không làm UI cảnh báo mãi.
  if (activeUntil > 0) {
    return now < activeUntil;
  }

  final lastVibration = parseLastSeen(
    device["last_vibration_at"] ?? device["last_event"],
  );

  if (lastVibration != null) {
    final ageMs = DateTime.now()
        .toUtc()
        .difference(lastVibration.toUtc())
        .inMilliseconds;

    if (ageMs >= 0 && ageMs <= withinMs) {
      return true;
    }
  }

  return isActiveDeviceSignal(device["vibration"]) ||
      isActiveDeviceSignal(device["shock"]);
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

bool isSirenConnectedForUi(Map<String, dynamic> device) {
  if (normalizeAvailability(device["availability"]) != "online") {
    return false;
  }

  final lastSeen = parseLastSeen(device["last_seen"]);

  if (lastSeen == null) {
    return true;
  }

  final age = DateTime.now().toUtc().difference(lastSeen.toUtc());

  if (age.isNegative) {
    return true;
  }

  final maxAge = Duration(minutes: (heartbeatLimitHours("siren") * 60).round());

  return age <= maxAge;
}

bool isConfirmedSirenActiveForUi(Map<String, dynamic> device) {
  final type = device["type"]?.toString().trim().toLowerCase() ?? "";

  if (type != "siren" || !isSirenConnectedForUi(device)) {
    return false;
  }

  final hasAlarmState = device.containsKey("alarm");
  final alarmOn = hasAlarmState
      ? isActiveDeviceSignal(device["alarm"])
      : normalizeDeviceSwitchState(device) == "on";

  if (!alarmOn) {
    return false;
  }

  final commandStatus =
      device["siren_command_status"]?.toString().trim().toLowerCase() ?? "";

  if (commandStatus == "reported_on") {
    return true;
  }

  final reportedAt =
      int.tryParse(device["last_siren_report_at"]?.toString() ?? "") ?? 0;
  final commandedAt =
      int.tryParse(device["last_siren_command_at"]?.toString() ?? "") ?? 0;

  // MQTT broker nhận lệnh chưa chứng minh còi đã kêu. Chỉ hiển thị trạng thái
  // đang bật khi có packet trạng thái thật mới hơn lệnh điều khiển gần nhất.
  return reportedAt > 0 && (commandedAt <= 0 || reportedAt >= commandedAt);
}

String normalizeSecurityMode(dynamic value) {
  final mode = value?.toString().trim().toLowerCase() ?? "";

  if (mode == "armed" || mode == "unprotected") {
    return mode;
  }

  return "normal";
}

bool isSosActive(Map<String, dynamic> d) {
  final status = d["status"]?.toString().trim().toLowerCase();

  return isEmergencyStatusActiveForCurrentUser(
    d,
    legacyActive:
        status == "triggered" ||
        emergencyStatusActiveUntil(d) > DateTime.now().millisecondsSinceEpoch,
  );
}

int? _alarmClockToMinute(dynamic rawValue) {
  final text = rawValue?.toString().trim() ?? "";
  final match = RegExp(r"^([01]\d|2[0-3]):([0-5]\d)$").firstMatch(text);

  if (match == null) {
    return null;
  }

  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  return hour * 60 + minute;
}

Set<int> _normalizeAlarmScheduleDays(dynamic rawDays) {
  final days = <int>{};

  void addDay(dynamic rawDay) {
    final day = int.tryParse(rawDay?.toString() ?? "");

    if (day != null && day >= DateTime.monday && day <= DateTime.sunday) {
      days.add(day);
    }
  }

  if (rawDays is Iterable) {
    for (final rawDay in rawDays) {
      addDay(rawDay);
    }
  } else if (rawDays is Map) {
    // Firebase có thể trả mảng dưới dạng Map nếu dữ liệu có index rỗng.
    for (final rawDay in rawDays.values) {
      addDay(rawDay);
    }
  }

  // Dữ liệu cũ chưa có days được hiểu là chạy hằng ngày.
  if (days.isEmpty) {
    return {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    };
  }

  return days;
}

bool _isAlarmScheduleActiveNow(Map<String, dynamic> schedule, DateTime now) {
  if (schedule["enabled"] != true) {
    return false;
  }

  final startMinute = _alarmClockToMinute(schedule["start"]);
  final endMinute = _alarmClockToMinute(schedule["end"]);

  if (startMinute == null || endMinute == null || startMinute == endMinute) {
    return false;
  }

  final nowMinute = now.hour * 60 + now.minute;
  final crossesMidnight = startMinute > endMinute;
  final inTimeRange = crossesMidnight
      ? nowMinute >= startMinute || nowMinute < endMinute
      : nowMinute >= startMinute && nowMinute < endMinute;

  if (!inTimeRange) {
    return false;
  }

  var scheduleWeekday = now.weekday;

  // 01:00 thứ Ba vẫn thuộc lịch bắt đầu từ tối thứ Hai.
  if (crossesMidnight && nowMinute < endMinute) {
    scheduleWeekday = scheduleWeekday == DateTime.monday
        ? DateTime.sunday
        : scheduleWeekday - 1;
  }

  return _normalizeAlarmScheduleDays(
    schedule["days"],
  ).contains(scheduleWeekday);
}

List<Map<String, dynamic>> _deviceAlarmSchedules(Map<String, dynamic> device) {
  final schedules = <Map<String, dynamic>>[];
  final rawSchedules = device["alarmSchedules"];

  if (rawSchedules is Map) {
    for (final rawSchedule in rawSchedules.values) {
      final schedule = safeMap(rawSchedule);

      if (schedule.isNotEmpty) {
        schedules.add(schedule);
      }
    }
  } else if (rawSchedules is Iterable) {
    for (final rawSchedule in rawSchedules) {
      final schedule = safeMap(rawSchedule);

      if (schedule.isNotEmpty) {
        schedules.add(schedule);
      }
    }
  }

  // Chỉ dùng alarm cũ khi thiết bị chưa có collection alarmSchedules mới.
  if (schedules.isEmpty) {
    final legacyAlarm = safeMap(device["alarm"]);

    if (legacyAlarm.isNotEmpty) {
      schedules.add(legacyAlarm);
    }
  }

  return schedules;
}

bool isNowInAlarmTime(Map<String, dynamic> device, {DateTime? now}) {
  final alarmPolicy = safeMap(device["alarmPolicy"]);

  // Thiết bị đã rời hệ thống báo động thì cửa mở chỉ là trạng thái chú ý.
  if (alarmPolicy["enabled"] == false) {
    return false;
  }

  final currentTime = now ?? DateTime.now();

  return _deviceAlarmSchedules(
    device,
  ).any((schedule) => _isAlarmScheduleActiveNow(schedule, currentTime));
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
/// - emergency: Nguy hiểm
/// - danger: Chưa an toàn
/// - warning: Cần chú ý
/// - safe: Đã an toàn
Map<String, dynamic> evaluateDeviceStatus(
  Map<String, dynamic> device, {
  String securityMode = "normal",
}) {
  final normalizedMode = normalizeSecurityMode(securityMode);
  final isArmedMode = normalizedMode == "armed";

  final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";
  final status = device["status"]?.toString().trim().toLowerCase() ?? "";

  final contact = parseDeviceBool(device["contact"]);
  final tamper = parseDeviceBool(device["tamper"]) == true;
  final availability = normalizeAvailability(device["availability"]);

  final battery = int.tryParse(device["battery"]?.toString() ?? "");
  final linkquality = int.tryParse(device["linkquality"]?.toString() ?? "");

  final emergencyIssues = <String>[];
  final dangerIssues = <String>[];
  final warningIssues = <String>[];

  final isLockDevice = type == "lock" || type == "door_lock";

  final isContactDevice =
      type == "door" || type == "window" || type == "gate" || isLockDevice;

  final lockState = isLockDevice ? normalizeDeviceLockState(device) : "";

  final isClosed =
      isContactDevice &&
      (isLockDevice
          ? lockState == "locked"
          : contact == true || status == "closed" || status == "locked");

  final isOpen =
      isContactDevice &&
      (isLockDevice
          ? lockState == "unlocked"
          : contact == false || status == "open" || status == "unlocked");

  if (type == "temperature") {
    final temperature = double.tryParse(
      device["temperature"]?.toString() ?? "",
    );
    final humidity = double.tryParse(device["humidity"]?.toString() ?? "");
    final hasExplicitDangerousTemperatureAlarm = _hasTrueFlag(device, const [
      "temperature_alarm",
      "high_temperature_alarm",
      "over_temperature_alarm",
    ]);

    if (isEmergencyStatusActiveForCurrentUser(
      device,
      legacyActive: hasExplicitDangerousTemperatureAlarm,
    )) {
      emergencyIssues.add("Nhiệt độ nguy hiểm");
    } else if (temperature != null &&
        temperature > environmentWarningTemperatureC) {
      warningIssues.add("Nhiệt độ cao");
    }

    if (humidity != null && humidity >= environmentWarningHumidityPercent) {
      warningIssues.add("Độ ẩm cao");
    }
  }

  if (type == "sos" && isSosActive(device)) {
    emergencyIssues.add("SOS");
  }

  if (type == "smoke" &&
      isEmergencyStatusActiveForCurrentUser(
        device,
        legacyActive:
            isActiveDeviceSignal(device["smoke"]) || status == "alarm",
      )) {
    emergencyIssues.add("Có khói");
  }

  if (type == "heat" &&
      isEmergencyStatusActiveForCurrentUser(
        device,
        legacyActive:
            _hasTrueFlag(device, const [
              "heat",
              "heat_alarm",
              "high_temperature_alarm",
            ]) ||
            status == "alarm",
      )) {
    emergencyIssues.add("Nhiệt độ nguy hiểm");
  }

  if (type == "carbon_monoxide" &&
      isEmergencyStatusActiveForCurrentUser(
        device,
        legacyActive:
            _hasTrueFlag(device, const ["carbon_monoxide", "co_alarm"]) ||
            status == "alarm",
      )) {
    emergencyIssues.add("Phát hiện khí CO");
  }

  if (type == "gas" &&
      isEmergencyStatusActiveForCurrentUser(
        device,
        legacyActive:
            _hasTrueFlag(device, const ["gas", "gas_alarm"]) ||
            status == "alarm",
      )) {
    emergencyIssues.add("Rò rỉ gas");
  }

  if ((type == "water_leak" || type == "flood") &&
      isEmergencyStatusActiveForCurrentUser(
        device,
        legacyActive:
            _hasTrueFlag(device, const ["water_leak", "leak", "water"]) ||
            status == "alarm",
      )) {
    emergencyIssues.add("Phát hiện ngập nước");
  }

  // Chỉ nâng sự cố điện lên Nguy hiểm khi thiết bị gửi cờ Alarm rõ ràng.
  // Không suy đoán từ điện áp/dòng điện thông thường để tránh báo động giả.
  final supportsElectricalSafety = const {
    "smart_plug",
    "power_monitor",
    "ups",
    "electrical_fault",
    "short_circuit",
  }.contains(type);

  if (supportsElectricalSafety) {
    final shortCircuitActive = _hasTrueFlag(device, const [
      "short_circuit",
      "short_circuit_alarm",
      "electrical_fault",
    ]);
    final overCurrentActive = _hasTrueFlag(device, const [
      "over_current",
      "overcurrent",
      "over_current_alarm",
    ]);
    final overVoltageActive = _hasTrueFlag(device, const [
      "over_voltage",
      "overvoltage",
      "over_voltage_alarm",
    ]);
    final electricalOverheatActive = _hasTrueFlag(device, const [
      "over_temperature",
      "overtemperature",
      "device_overheat",
      "electrical_overheat",
    ]);
    final electricalEmergencyVisible = isEmergencyStatusActiveForCurrentUser(
      device,
      legacyActive:
          shortCircuitActive ||
          overCurrentActive ||
          overVoltageActive ||
          electricalOverheatActive,
    );

    if (electricalEmergencyVisible) {
      if (shortCircuitActive) {
        emergencyIssues.add("Phát hiện chập điện");
      } else if (overCurrentActive) {
        emergencyIssues.add("Phát hiện quá dòng");
      } else if (overVoltageActive) {
        emergencyIssues.add("Phát hiện quá áp");
      } else if (electricalOverheatActive) {
        emergencyIssues.add("Thiết bị điện quá nhiệt");
      } else {
        emergencyIssues.add("Sự cố điện nguy hiểm");
      }
    }
  }

  final motionActive =
      (type == "motion" || type == "presence") &&
      _hasTrueFlag(device, const ["occupancy", "motion", "presence"]);

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

  final action = device["action"]?.toString().trim().toLowerCase() ?? "";

  final vibrationActive = type == "vibration" && isVibrationEventActive(device);

  final glassBreakActive =
      type == "glass_break" &&
      (_hasTrueFlag(device, const ["glass_break", "broken_glass"]) ||
          (isRecentDeviceEvent(device) &&
              (action.contains("glass") || action.contains("break"))));

  if (vibrationActive || glassBreakActive) {
    final issue = glassBreakActive
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
        dangerIssues.add("Khóa đang mở khi nhà ở chế độ Bảo vệ");
      } else if (isNowInAlarmTime(device)) {
        dangerIssues.add("Khóa đang mở trong giờ báo động");
      } else {
        warningIssues.add("Khóa đang mở");
      }
    } else {
      if (isArmedMode) {
        dangerIssues.add("Đang mở khi nhà ở chế độ Bảo vệ");
      } else if (isNowInAlarmTime(device)) {
        dangerIssues.add("Đang mở trong giờ báo động");
      } else {
        warningIssues.add("Đang mở");
      }
    }
  }

  if (type == "power_monitor" || type == "ups") {
    final mainsPower = parseDeviceBool(
      device["mains_power"] ?? device["ac_connected"] ?? device["input_power"],
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

  if (linkquality != null && linkquality > 0 && linkquality < 40) {
    warningIssues.add("Sóng yếu");
  }

  if (availability == "offline") {
    warningIssues.add("Mất kết nối");
  }

  final level = emergencyIssues.isNotEmpty
      ? "emergency"
      : dangerIssues.isNotEmpty
      ? "danger"
      : warningIssues.isNotEmpty
      ? "warning"
      : "safe";

  return {
    "safe": level == "safe",
    "level": level,
    "emergencyIssues": emergencyIssues,
    "dangerIssues": dangerIssues,
    "warningIssues": warningIssues,
    "issues": [...emergencyIssues, ...dangerIssues, ...warningIssues],
    "isContactDevice": isContactDevice,
    "isClosed": isClosed,
    "isOpen": isOpen,
    "lockState": lockState,
  };
}

const int hubHeartbeatTimeoutMs = 180 * 1000;

DateTime _hubStatusGraceUntil = DateTime.fromMillisecondsSinceEpoch(0);

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
    return {"tracked": false, "online": true, "checking": false, "issue": ""};
  }

  final hubStatus = safeMap(home["hubStatus"]);
  final heartbeatTime = parseLastSeen(hubStatus["lastHeartbeatAt"]);

  if (heartbeatTime == null) {
    if (_hubStatusInGracePeriod) {
      return {"tracked": true, "online": true, "checking": true, "issue": ""};
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
      return {"tracked": true, "online": true, "checking": true, "issue": ""};
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
      return {"tracked": true, "online": true, "checking": true, "issue": ""};
    }

    return {
      "tracked": true,
      "online": false,
      "checking": false,
      "issue": "MQTT mất kết nối",
    };
  }

  return {"tracked": true, "online": true, "checking": false, "issue": ""};
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
      "emergencyIssues": <String>[],
      "dangerIssues": <String>[],
      "warningIssues": <String>[],
      "presenceWarnings": <String>[],
      "presencePanelLines": <String>[],
      "issues": <String>[],
      "safeSummary": <String>["Chưa có dữ liệu để đánh giá"],
      "hubTracked": false,
      "hubOnline": false,
      "hubChecking": false,
      "hubIssue": "",
    };
  }
  final emergencyIssues = List<String>.from(
    overall["emergencyIssues"] ?? const <String>[],
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

  // Thông tin vị trí thành viên chỉ dùng để hiển thị riêng.
  // Nó không được làm thay đổi trạng thái chung của ngôi nhà.
  final presenceWarnings = <String>[];
  final presencePanelLines = <String>[];

  // ================= HUB =================

  final hub = evaluateHubStatus(home);

  final hubTracked = hub["tracked"] == true;
  final hubOnline = hub["online"] == true;
  final hubChecking = hub["checking"] == true;
  final hubIssue = hub["issue"]?.toString().trim() ?? "";

  if (hubTracked && hubChecking) {
    safeSummary.add("Đang kiểm tra kết nối Hub");
  } else if (hubTracked && !hubOnline && hubIssue.isNotEmpty) {
    // Hub/MQTT mất kết nối làm khả năng bảo vệ không đầy đủ nhưng không phải
    // sự cố nguy hiểm thực tế như khói, CO hoặc đột nhập.
    warningIssues.insert(0, hubIssue);
  } else if (hubTracked && hubOnline) {
    safeSummary.add("Hub kết nối bình thường");
  }

  // ================= THÀNH VIÊN =================

  final autoAway = safeMap(home["autoAway"]);

  final homeLatitude = double.tryParse(autoAway["latitude"]?.toString() ?? "");

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
    final displayCounts = resolveAutoAwayPresenceDisplayCounts(home);
    final insideCount = displayCounts["insideCount"] ?? 0;
    final outsideCount = displayCounts["outsideCount"] ?? 0;
    final unknownCount = displayCounts["unknownCount"] ?? 0;
    final participantCount = displayCounts["participantCount"] ?? 0;
    final totalMemberCount = displayCounts["totalMemberCount"] ?? 0;

    // Các dòng vị trí trong StatusPanel và Tổng hợp trạng thái chỉ phản ánh
    // đúng nhóm thành viên được chọn để xác định Tự động bảo vệ.
    if (participantCount > 0) {
      final insideText =
          "Thành viên đang ở trong nhà: $insideCount/$participantCount";
      final outsideText =
          "Thành viên đang ở ngoài: $outsideCount/$participantCount";
      final unknownText =
          "Thành viên chưa xác định vị trí: $unknownCount/$participantCount";

      presencePanelLines.add(insideText);
      safeSummary.insert(0, insideText);

      if (outsideCount > 0) {
        presencePanelLines.add(outsideText);
        safeSummary.add(outsideText);
      }

      if (unknownCount > 0) {
        presencePanelLines.add(unknownText);
        presenceWarnings.add(unknownText);
      }
    }

    if (totalMemberCount > 0) {
      final participantSummaryText =
          "Số thành viên dùng để xác định mở Tự động bảo vệ: "
          "$participantCount/$totalMemberCount";

      presencePanelLines.add(participantSummaryText);
      safeSummary.add(participantSummaryText);
    }
  }

  final level = emergencyIssues.isNotEmpty
      ? "emergency"
      : dangerIssues.isNotEmpty
      ? "danger"
      : warningIssues.isNotEmpty
      ? "warning"
      : "safe";

  return {
    ...overall,
    "safe": level == "safe",
    "level": level,
    "emergencyIssues": emergencyIssues,
    "dangerIssues": dangerIssues,
    "warningIssues": warningIssues,
    "presenceWarnings": presenceWarnings,
    "presencePanelLines": presencePanelLines,
    "issues": [...emergencyIssues, ...dangerIssues, ...warningIssues],
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
  final emergencyIssues = <String>[];
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

    final deviceEmergencyIssues = List<String>.from(
      evaluation["emergencyIssues"] ?? const <String>[],
    );
    final deviceDangerIssues = List<String>.from(
      evaluation["dangerIssues"] ?? const <String>[],
    );
    final deviceWarningIssues = List<String>.from(
      evaluation["warningIssues"] ?? const <String>[],
    );

    if (deviceEmergencyIssues.isNotEmpty) {
      emergencyIssues.add("$name: ${deviceEmergencyIssues.join(" & ")}");
    }

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
      "emergencyIssues": <String>[],
      "dangerIssues": <String>[],
      "warningIssues": <String>[],
      "issues": <String>[],
      "safeSummary": <String>["Chưa có dữ liệu để đánh giá"],
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
    const {"door", "window", "gate", "lock", "door_lock"}.contains,
  );

  final hasSmokeDevice = deviceTypes.contains("smoke");
  final hasSosDevice = deviceTypes.contains("sos");
  final hasEnvironmentDevice = deviceTypes.contains("temperature");

  final hasEmergencyDevice = deviceTypes.any(
    const {
      "smoke",
      "heat",
      "temperature",
      "carbon_monoxide",
      "gas",
      "water_leak",
      "flood",
      "sos",
      "smart_plug",
      "power_monitor",
      "ups",
      "electrical_fault",
      "short_circuit",
    }.contains,
  );

  final hasInfrastructureDevice = deviceTypes.any(
    const {"repeater", "hub"}.contains,
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

  final level = emergencyIssues.isNotEmpty
      ? "emergency"
      : dangerIssues.isNotEmpty
      ? "danger"
      : warningIssues.isNotEmpty
      ? "warning"
      : "safe";

  return {
    "safe": level == "safe",
    "level": level,
    "emergencyIssues": emergencyIssues,
    "dangerIssues": dangerIssues,
    "warningIssues": warningIssues,
    "issues": [...emergencyIssues, ...dangerIssues, ...warningIssues],
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
