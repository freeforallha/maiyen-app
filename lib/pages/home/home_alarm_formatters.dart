import 'package:flutter/material.dart';

import '../../helpers/home_helper.dart';
import '../../sheets/device_alarm_policy_sheet.dart';

class HomeAlarmFormatters {
  static Map<String, String> getHomeAlarmReminderInfo({
    required Map<String, dynamic> customRulesByHome,
    required String selectedHome,
    required Map<String, dynamic> devices,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final selectedRules = safeMap(customRulesByHome[selectedHome]);
    final customDevices = safeMap(selectedRules["devices"]);
    final legacyAlarmMode =
        (selectedRules["alarmMode"] ?? selectedRules["mode"] ?? "home")
            .toString();

    for (final entry in devices.entries) {
      final deviceId = entry.key.toString();
      final device = safeMap(entry.value);
      final realDeviceId = device["_deviceId"]?.toString() ?? deviceId;
      final homeAlarm = safeMap(device["alarm"]);
      final customDevice = safeMap(customDevices[realDeviceId]);
      final customAlarm = normalizeEffectivePersonalAlarmSchedule(
        customDevice: customDevice,
        legacyAlarmMode: legacyAlarmMode,
      );

      if (homeAlarm["enabled"] == true) {
        return {
          "mode": "Theo nhà",
          "start": homeAlarm["start"]?.toString() ?? "23:00",
          "end": homeAlarm["end"]?.toString() ?? "06:00",
        };
      }

      if (customAlarm["enabled"] == true) {
        return {
          "mode": "Riêng tôi",
          "start": customAlarm["start"]?.toString() ?? "23:00",
          "end": customAlarm["end"]?.toString() ?? "06:00",
        };
      }
    }

    return {
      "mode": "Theo nhà / Riêng tôi",
      "start": _formatTimeOfDay(start),
      "end": _formatTimeOfDay(end),
    };
  }

  static bool hasEnabledScheduleValue(dynamic raw) {
    return _hasEnabledScheduleValue(raw);
  }

  static String formatAlarmSchedules({
    required String selectedHome,
    required Map<String, dynamic> devices,
    required Map<String, dynamic> customRulesByHome,
  }) {
    if (selectedHome.isEmpty) {
      return "Tắt";
    }

    final selectedRules = safeMap(customRulesByHome[selectedHome]);
    final customDevices = safeMap(selectedRules["devices"]);
    final legacyAlarmMode =
        (selectedRules["alarmMode"] ?? selectedRules["mode"] ?? "home")
            .toString();
    final intervals = <Map<String, int>>[];

    void addAlarm(Map<String, dynamic> alarm) {
      if (alarm["enabled"] != true) {
        return;
      }

      final startMinutes = _parseClock(alarm["start"]);
      final endMinutes = _parseClock(alarm["end"]);
      if (startMinutes == null || endMinutes == null) {
        return;
      }
      intervals.add({"start": startMinutes, "end": endMinutes});
    }

    for (final entry in devices.entries) {
      final deviceId = entry.key.toString();
      final device = safeMap(entry.value);
      final realDeviceId = device["_deviceId"]?.toString() ?? deviceId;
      final homeAlarm = safeMap(device["alarm"]);
      final customDevice = safeMap(customDevices[realDeviceId]);
      final customAlarm = normalizeEffectivePersonalAlarmSchedule(
        customDevice: customDevice,
        legacyAlarmMode: legacyAlarmMode,
      );

      // Lịch chung và lịch cá nhân hoạt động song song.
      addAlarm(homeAlarm);
      addAlarm(customAlarm);
    }

    if (intervals.isEmpty) {
      return "Tắt";
    }

    if (intervals.length == 1) {
      final firstInterval = intervals.first;
      final start = firstInterval["start"];
      final end = firstInterval["end"];

      if (start == null || end == null) {
        return "Tắt";
      }

      return "${_formatClockMinutes(start)} → ${_formatClockMinutes(end)}";
    }

    // Tìm một khoảng liên tục ngắn nhất nhưng bao phủ toàn bộ
    // các lịch Alarm, kể cả lịch đi qua 00:00.
    int? bestStart;
    int? bestEnd;
    var bestSpan = 1 << 30;

    final candidateCuts = <int>{
      for (final interval in intervals)
        if (interval["start"] != null) interval["start"] as int,
      for (final interval in intervals)
        if (interval["end"] != null) interval["end"] as int,
    };

    for (final cut in candidateCuts) {
      var minStart = 1 << 30;
      var maxEnd = -(1 << 30);

      for (final interval in intervals) {
        final startMinutes = interval["start"];
        final endMinutes = interval["end"];

        if (startMinutes == null || endMinutes == null) {
          continue;
        }

        var duration = (endMinutes - startMinutes + 1440) % 1440;

        // Cùng giờ bắt đầu/kết thúc được hiểu là cả ngày.
        if (duration == 0) {
          duration = 1440;
        }

        final mappedStart = (startMinutes - cut + 1440) % 1440;
        final mappedEnd = mappedStart + duration;

        if (mappedStart < minStart) {
          minStart = mappedStart;
        }

        if (mappedEnd > maxEnd) {
          maxEnd = mappedEnd;
        }
      }

      final span = maxEnd - minStart;

      if (span < bestSpan) {
        bestSpan = span;
        bestStart = cut + minStart;
        bestEnd = cut + maxEnd;
      }
    }

    if (bestStart == null || bestEnd == null) {
      return "Tắt";
    }

    if (bestSpan >= 1440) {
      return "Cả ngày";
    }

    return "${_formatClockMinutes(bestStart)} → "
        "${_formatClockMinutes(bestEnd)}";
  }
}

bool _hasEnabledScheduleValue(dynamic raw) {
  if (raw is List) {
    return raw.any((item) {
      final schedule = safeMap(item);
      return schedule["enabled"] == true;
    });
  }

  if (raw is Map) {
    return raw.values.any((item) {
      final schedule = safeMap(item);
      return schedule["enabled"] == true;
    });
  }

  return false;
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, "0");
  final minute = time.minute.toString().padLeft(2, "0");
  return "$hour:$minute";
}

int? _parseClock(dynamic raw) {
  final value = raw?.toString().trim() ?? "";
  final parts = value.split(":");

  if (parts.length != 2) {
    return null;
  }

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);

  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }

  return hour * 60 + minute;
}

String _formatClockMinutes(int totalMinutes) {
  final normalized = ((totalMinutes % 1440) + 1440) % 1440;
  final hour = normalized ~/ 60;
  final minute = normalized % 60;

  return "${hour.toString().padLeft(2, "0")}:"
      "${minute.toString().padLeft(2, "0")}";
}
