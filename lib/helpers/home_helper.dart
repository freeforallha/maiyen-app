import 'package:flutter/material.dart';

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
  final issues = <String>[];

  devices.forEach((id, raw) {
    final d = safeMap(raw);

    final name = d["name"]?.toString() ?? id;
    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    final problem = <String>[];

    if (status != "closed") {
      problem.add("Mở");
    }

    if (tamper) {
      problem.add("Bị tháo");
    }

    if (problem.isNotEmpty) {
      issues.add("$name: ${problem.join(" & ")}");
    }
  });

  return {
    "safe": issues.isEmpty,
    "issues": issues,
  };
}

bool isUnsafe(Map<dynamic, dynamic> devices) {
  return devices.values.any((raw) {
    final d = safeMap(raw);

    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    return status != "closed" || tamper;
  });
}

Color getDeviceColor(Map<dynamic, dynamic> raw) {
  final d = safeMap(raw);

  return isUnsafe({"device": d})
      ? Colors.red.shade200
      : Colors.green.shade200;
}