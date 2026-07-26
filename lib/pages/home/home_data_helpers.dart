import 'package:flutter/material.dart';

import '../../helpers/home_helper.dart';
import '../../maiyen_theme.dart';

class HomeDataHelpers {
  static List<String> mergeVisibleHomeOrder({
    required List<String> visibleOrder,
    required List<String> homeOrder,
    required Map<String, dynamic> homes,
  }) {
    final visibleIds = visibleOrder.toSet();
    final nextOrder = <String>[];
    final seen = <String>{};
    var visibleIndex = 0;

    void addHomeId(String homeId) {
      if (seen.add(homeId)) {
        nextOrder.add(homeId);
      }
    }

    for (final homeId in homeOrder) {
      if (visibleIds.contains(homeId)) {
        if (visibleIndex < visibleOrder.length) {
          addHomeId(visibleOrder[visibleIndex]);
          visibleIndex++;
        }
      } else {
        addHomeId(homeId);
      }
    }

    while (visibleIndex < visibleOrder.length) {
      addHomeId(visibleOrder[visibleIndex]);
      visibleIndex++;
    }

    for (final homeId in homes.keys) {
      addHomeId(homeId);
    }

    return nextOrder;
  }

  static Map<String, dynamic> getDevices({
    required Map<String, dynamic> homes,
    required String selectedHome,
  }) {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["devices"]);
  }

  static Map<String, dynamic> getRooms({
    required Map<String, dynamic> homes,
    required String selectedHome,
  }) {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["rooms"]);
  }

  static Map<String, dynamic>? getTemperatureDevice({
    required Map<String, dynamic> devices,
  }) {
    for (final entry in devices.entries) {
      final d = safeMap(entry.value);

      if (d["type"] == "temperature") {
        return {"id": entry.key, "data": d};
      }
    }

    return null;
  }

  static String getHomeEnvironmentText({
    required Map<String, dynamic> devices,
  }) {
    for (final item in devices.values) {
      final d = safeMap(item);

      if (d["type"] == "temperature") {
        final temp = d["temperature"];
        final humidity = d["humidity"];

        final tempText = temp != null ? "$temp°C" : "--";
        final humidityText = humidity != null ? "$humidity%" : "--";

        return "$tempText / $humidityText";
      }
    }

    return "--°C / --%";
  }

  static Color getHomeColor({
    required Map<String, dynamic> homes,
    required String homeId,
    required String selectedHome,
  }) {
    final home = safeMap(homes[homeId]);
    final overall = getHomeOverallStatus(home);

    final level = overall["level"]?.toString() ?? "safe";
    final selected = homeId == selectedHome;

    if (level == "emergency") {
      return MaiYenColors.emergency;
    }

    if (level == "danger") {
      return MaiYenColors.danger;
    }

    if (level == "warning") {
      return MaiYenColors.warning;
    }

    return selected ? MaiYenColors.primary : MaiYenColors.safe;
  }
}
