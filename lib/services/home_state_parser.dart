import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
class HomeStateParser {
  static Map<String, dynamic> parseProfile(Map<String, dynamic> account) {
    final profile = safeMap(account["profile"]);

    return {
      "name": profile["name"]?.toString() ?? account["name"]?.toString() ?? "",
      "gender": profile["gender"]?.toString() ?? account["gender"]?.toString() ?? "",
      "dob": profile["dob"]?.toString() ?? account["dob"]?.toString() ?? "",
      "phone": profile["phone"]?.toString() ?? account["phone"]?.toString() ?? "",
      "photoUrl": profile["photoUrl"]?.toString() ?? "",
    };
  }

  static List<String> parseHomeOrder({
    required Map<String, dynamic> account,
    required Map<String, dynamic> homesData,
    required Map<String, dynamic> sharedHomes,
    required String selectedHome,
  }) {
    final savedOrder = account["homeOrder"];
    List<String> order;

    if (savedOrder != null) {
      order = List<String>.from(savedOrder);
      final allHomeIds = {...homesData.keys, ...sharedHomes.keys};

      order.removeWhere((id) => !allHomeIds.contains(id));

      for (final id in homesData.keys) {
        if (!order.contains(id)) order.add(id);
      }

      for (final id in sharedHomes.keys) {
        if (!order.contains(id)) order.add(id);
      }
    } else {
      order = [...homesData.keys, ...sharedHomes.keys];
    }

    return order;
  }
  static Map<String, dynamic> parseAlarm(
      Map<String, dynamic> home,
      ) {
    final alarm = safeMap(
      home["_customAlarm"] ?? home["alarm"],
    );

    final startStr = alarm["start"]?.toString() ?? "23:00";
    final endStr = alarm["end"]?.toString() ?? "06:00";

    final s = startStr.split(":");
    final e = endStr.split(":");

    return {
      "enabled": alarm["enabled"] == true,

      "start": TimeOfDay(
        hour: int.tryParse(s[0]) ?? 23,
        minute: int.tryParse(s[1]) ?? 0,
      ),

      "end": TimeOfDay(
        hour: int.tryParse(e[0]) ?? 6,
        minute: int.tryParse(e[1]) ?? 0,
      ),
    };
  }
}