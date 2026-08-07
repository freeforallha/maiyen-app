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

      if (!isSecurityDeviceType(device["type"])) {
        continue;
      }

      final realDeviceId = device["_deviceId"]?.toString() ?? deviceId;
      final customDevice = safeMap(customDevices[realDeviceId]);
      final policy = DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: device["type"]?.toString() ?? "door",
      );

      if (!policy.enabled) {
        continue;
      }
      final commonSchedules = normalizeDeviceAlarmSchedules(
        rawSchedules: device["alarmSchedules"],
        legacyAlarm: device["alarm"],
        personal: false,
        legacyFullscreenEnabled: policy.fullscreenEnabled,
        legacyPhysicalSirenEnabled: policy.physicalSirenEnabled,
      );
      final preferences = DevicePersonalAlarmPreferences.fromCustomDevice(
        customDevice: customDevice,
        legacyFullscreenEnabled: policy.fullscreenEnabled,
      );
      final effectiveSchedules = normalizeEffectivePersonalAlarmSchedules(
        customDevice: customDevice,
        legacyAlarmMode: legacyAlarmMode,
        commonSchedules: commonSchedules,
        legacyFullscreenEnabled: policy.fullscreenEnabled,
      );
      Map<String, dynamic>? enabledSchedule;
      for (final schedule in effectiveSchedules.values) {
        if (schedule["enabled"] == true) {
          enabledSchedule = schedule;
          break;
        }
      }

      if (enabledSchedule != null) {
        return {
          "mode": preferences.followHomeSchedule ? "Theo nhà" : "Riêng tôi",
          "start": enabledSchedule["start"]?.toString() ?? "23:00",
          "end": enabledSchedule["end"]?.toString() ?? "06:00",
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
    final intervalsByKey = <String, Map<String, int>>{};

    void addAlarm(Map<String, dynamic> alarm) {
      if (alarm["enabled"] != true) {
        return;
      }

      final startMinutes = _parseClock(alarm["start"]);
      final endMinutes = _parseClock(alarm["end"]);
      if (startMinutes == null || endMinutes == null) {
        return;
      }

      final intervalKey =
          "$startMinutes:$endMinutes:${_alarmScheduleDaysKey(alarm["days"])}";
      intervalsByKey.putIfAbsent(
        intervalKey,
        () => {"start": startMinutes, "end": endMinutes},
      );
    }

    for (final entry in devices.entries) {
      final deviceId = entry.key.toString();
      final device = safeMap(entry.value);

      if (!isSecurityDeviceType(device["type"])) {
        continue;
      }

      final realDeviceId = device["_deviceId"]?.toString() ?? deviceId;
      final customDevice = safeMap(customDevices[realDeviceId]);
      final policy = DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: device["type"]?.toString() ?? "door",
      );

      if (!policy.enabled) {
        continue;
      }
      final commonSchedules = normalizeDeviceAlarmSchedules(
        rawSchedules: device["alarmSchedules"],
        legacyAlarm: device["alarm"],
        personal: false,
        legacyFullscreenEnabled: policy.fullscreenEnabled,
        legacyPhysicalSirenEnabled: policy.physicalSirenEnabled,
      );
      final effectiveSchedules = normalizeEffectivePersonalAlarmSchedules(
        customDevice: customDevice,
        legacyAlarmMode: legacyAlarmMode,
        commonSchedules: commonSchedules,
        legacyFullscreenEnabled: policy.fullscreenEnabled,
      );

      for (final alarm in effectiveSchedules.values) {
        addAlarm(alarm);
      }
    }

    final intervals = intervalsByKey.values.toList(growable: false)
      ..sort((first, second) {
        final startCompare = (first["start"] ?? 0).compareTo(
          second["start"] ?? 0,
        );

        if (startCompare != 0) {
          return startCompare;
        }

        return (first["end"] ?? 0).compareTo(second["end"] ?? 0);
      });

    if (intervals.isEmpty) {
      return "Tắt";
    }

    final firstInterval = intervals.first;
    final start = firstInterval["start"];
    final end = firstInterval["end"];

    if (start == null || end == null) {
      return "Tắt";
    }

    final firstText =
        "${_formatClockMinutes(start)} → ${_formatClockMinutes(end)}";

    if (intervals.length == 1) {
      return firstText;
    }

    // Status Panel chỉ có một dòng ngắn. Không gộp nhiều lịch thành một
    // khoảng giả vì người dùng sẽ không biết lịch mới đã được thêm.
    return "$firstText (+${intervals.length - 1})";
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

String _alarmScheduleDaysKey(dynamic rawDays) {
  final days = <int>[];

  void addDay(dynamic rawDay) {
    final day = int.tryParse(rawDay?.toString() ?? "");

    if (day != null && day >= 1 && day <= 7 && !days.contains(day)) {
      days.add(day);
    }
  }

  if (rawDays is Iterable) {
    for (final rawDay in rawDays) {
      addDay(rawDay);
    }
  } else if (rawDays is Map) {
    for (final rawDay in rawDays.values) {
      addDay(rawDay);
    }
  }

  if (days.isEmpty) {
    return "1,2,3,4,5,6,7";
  }

  days.sort();
  return days.join(",");
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
