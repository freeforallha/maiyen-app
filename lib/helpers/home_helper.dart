import 'package:flutter/material.dart';

Map<String, dynamic> safeMap(dynamic data) {
  if (data == null) return {};
  return Map<String, dynamic>.from(data as Map);
}

Map<String, dynamic> getOverallStatus(Map<String, dynamic> devices) {
  List<String> issues = [];

  devices.forEach((id, raw) {
    final d = safeMap(raw);

    final name = d["name"]?.toString() ?? id;
    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    List<String> problem = [];

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

  return {"safe": issues.isEmpty, "issues": issues};
}

bool isUnsafe(Map dev) {
  return dev.values.any((d) {
    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    return status != "closed" || tamper;
  });
}

Color getDeviceColor(Map d) {
  final status = d["status"]?.toString();
  final tamper = d["tamper"] == true;

  if (status != "closed" || tamper) {
    return Colors.red.shade200;
  }

  return Colors.green.shade200;
}
