import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../safehome_theme.dart';

void showAllDevicesSheet({
  required BuildContext context,
  required Map<String, dynamic> devices,
  required void Function(String deviceId) onTapDevice,
}) {
  SafeHomeNavigation.pushChildPage<void>(
    context: context,
    routeName: "all_devices",
    builder: (pageContext) {
      final strings = AppStrings.of(pageContext);

      return ColoredBox(
        color: SafeHomeColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AllDevicesHeader(
                title: strings.t("Toàn bộ thiết bị SafeHome"),
                subtitle: strings.allDevicesSubtitle,
                deviceCount: devices.length,
              ),
              const SizedBox(height: 20),
              _deviceGroup(
                context: pageContext,
                devices: devices,
                title: strings.t("An ninh ra/vào"),
                color: const Color(0xFF9B6A3D),
                onTapDevice: onTapDevice,
                items: const [
                  {
                    "name": "Cửa ra/vào",
                    "icon": Icons.door_front_door_rounded,
                    "types": ["door", "window", "gate"],
                  },
                  {
                    "name": "Khóa thông minh",
                    "icon": Icons.lock_rounded,
                    "types": ["lock", "door_lock"],
                  },
                  {
                    "name": "Chuyển động",
                    "icon": Icons.directions_walk_rounded,
                    "types": ["motion"],
                  },
                  {
                    "name": "Hiện diện",
                    "icon": Icons.sensors_rounded,
                    "types": ["presence"],
                  },
                  {
                    "name": "Rung/chấn động",
                    "icon": Icons.vibration_rounded,
                    "types": ["vibration"],
                  },
                ],
              ),
              _deviceGroup(
                context: pageContext,
                devices: devices,
                title: strings.t("Nguy hiểm khẩn cấp"),
                color: SafeHomeColors.danger,
                onTapDevice: onTapDevice,
                items: const [
                  {
                    "name": "Báo khói",
                    "icon": Icons.local_fire_department_rounded,
                    "types": ["smoke"],
                  },
                  {
                    "name": "Báo nhiệt",
                    "icon": Icons.thermostat_rounded,
                    "types": ["heat"],
                  },
                  {
                    "name": "Khí CO",
                    "icon": Icons.dangerous_rounded,
                    "types": ["carbon_monoxide"],
                  },
                  {
                    "name": "Báo gas",
                    "icon": Icons.gas_meter_rounded,
                    "types": ["gas"],
                  },
                  {
                    "name": "Báo ngập/rò nước",
                    "icon": Icons.water_damage_rounded,
                    "types": ["water_leak", "flood"],
                  },
                  {
                    "name": "Nút SOS",
                    "icon": Icons.sos_rounded,
                    "types": ["sos"],
                  },
                ],
              ),
              _deviceGroup(
                context: pageContext,
                devices: devices,
                title: strings.t("Môi trường"),
                color: SafeHomeColors.info,
                onTapDevice: onTapDevice,
                items: const [
                  {
                    "name": "Nhiệt độ/Độ ẩm",
                    "icon": Icons.device_thermostat_rounded,
                    "types": ["temperature"],
                  },
                  {
                    "name": "Bụi mịn PM2.5",
                    "icon": Icons.air_rounded,
                    "types": ["pm25"],
                  },
                  {
                    "name": "CO₂",
                    "icon": Icons.co2_rounded,
                    "types": ["co2"],
                  },
                  {
                    "name": "Chất lượng không khí",
                    "icon": Icons.air_rounded,
                    "types": ["air_quality"],
                  },
                ],
              ),
              _deviceGroup(
                context: pageContext,
                devices: devices,
                title: strings.t("Điều khiển & hạ tầng"),
                color: SafeHomeColors.primary,
                onTapDevice: onTapDevice,
                items: const [
                  {
                    "name": "Ổ điện thông minh",
                    "icon": Icons.power_rounded,
                    "types": ["smart_plug"],
                  },
                  {
                    "name": "Còi báo động",
                    "icon": Icons.notifications_active_rounded,
                    "types": ["siren"],
                  },
                  {
                    "name": "Van thông minh",
                    "icon": Icons.water_drop_rounded,
                    "types": ["smart_valve"],
                  },
                  {
                    "name": "Chuông cửa",
                    "icon": Icons.notifications_rounded,
                    "types": ["doorbell"],
                  },
                  {
                    "name": "Bàn phím an ninh",
                    "icon": Icons.grid_3x3_rounded,
                    "types": ["keypad"],
                  },
                  {
                    "name": "Bộ mở rộng sóng",
                    "icon": Icons.wifi_tethering_rounded,
                    "types": ["repeater"],
                  },
                  {
                    "name": "Đo điện năng",
                    "icon": Icons.flash_on_rounded,
                    "types": ["power_monitor"],
                  },
                  {
                    "name": "Chưa nhận diện",
                    "icon": Icons.sensors_off_rounded,
                    "types": ["unknown"],
                  },
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AllDevicesHeader extends StatelessWidget {
  const _AllDevicesHeader({
    required this.title,
    required this.subtitle,
    required this.deviceCount,
  });

  final String title;
  final String subtitle;
  final int deviceCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: SafeHomeColors.primarySoft,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.sensors_rounded,
            color: SafeHomeColors.primary,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SafeHomeColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SafeHomeColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SafeHomeColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "$deviceCount",
            style: const TextStyle(
              color: SafeHomeColors.primaryDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _safeDeviceMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }

  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }

  return {};
}

IconData _deviceIcon(String type) {
  switch (type) {
    case "door":
      return Icons.sensor_door_rounded;
    case "window":
      return Icons.window_rounded;
    case "gate":
      return Icons.garage_rounded;
    case "lock":
    case "door_lock":
      return Icons.lock_rounded;
    case "motion":
      return Icons.directions_walk_rounded;
    case "presence":
      return Icons.sensors_rounded;
    case "vibration":
      return Icons.vibration_rounded;
    case "glass_break":
      return Icons.broken_image_rounded;
    case "smoke":
      return Icons.local_fire_department_rounded;
    case "heat":
      return Icons.thermostat_rounded;
    case "carbon_monoxide":
      return Icons.dangerous_rounded;
    case "gas":
      return Icons.gas_meter_rounded;
    case "water_leak":
    case "flood":
      return Icons.water_damage_rounded;
    case "sos":
      return Icons.sos_rounded;
    case "smart_plug":
      return Icons.power_rounded;
    case "siren":
      return Icons.notifications_active_rounded;
    case "smart_valve":
      return Icons.water_drop_rounded;
    case "doorbell":
      return Icons.notifications_rounded;
    case "keypad":
      return Icons.grid_3x3_rounded;
    case "repeater":
      return Icons.wifi_tethering_rounded;
    case "hub":
      return Icons.router_rounded;
    case "power_monitor":
      return Icons.flash_on_rounded;
    case "ups":
      return Icons.battery_charging_full_rounded;
    case "temperature":
      return Icons.device_thermostat_rounded;
    default:
      return Icons.sensors_off_rounded;
  }
}

int _deviceGroupCount(
  Map<String, dynamic> devices,
  List<Map<String, dynamic>> items,
) {
  final supportedTypes = items
      .expand((item) => List<String>.from(item["types"] ?? const <String>[]))
      .toSet();

  return devices.values.where((rawDevice) {
    final device = _safeDeviceMap(rawDevice);
    final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";
    return supportedTypes.contains(type);
  }).length;
}

Widget _deviceGroup({
  required BuildContext context,
  required Map<String, dynamic> devices,
  required String title,
  required Color color,
  required List<Map<String, dynamic>> items,
  required void Function(String deviceId) onTapDevice,
}) {
  final groupCount = _deviceGroupCount(devices, items);

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: SafeHomeColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: SafeHomeColors.border, width: 0.9),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.028),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: SafeHomeColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 31, minHeight: 27),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: groupCount > 0
                      ? color.withValues(alpha: 0.10)
                      : SafeHomeColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$groupCount",
                  style: TextStyle(
                    color: groupCount > 0
                        ? color
                        : SafeHomeColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.8, color: SafeHomeColors.border),
        for (var index = 0; index < items.length; index++) ...[
          _deviceTypeRow(
            context: context,
            devices: devices,
            name: AppStrings.of(context).t(
              items[index]["name"]?.toString() ?? "",
            ),
            types: List<String>.from(
              items[index]["types"] ?? const <String>[],
            ),
            icon: items[index]["icon"] as IconData? ?? Icons.sensors_rounded,
            accentColor: color,
            onTapDevice: onTapDevice,
          ),
          if (index < items.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 58),
              child: Divider(
                height: 1,
                thickness: 0.7,
                color: SafeHomeColors.border,
              ),
            ),
        ],
      ],
    ),
  );
}

Widget _deviceTypeRow({
  required BuildContext context,
  required Map<String, dynamic> devices,
  required String name,
  required List<String> types,
  required IconData icon,
  required Color accentColor,
  required void Function(String deviceId) onTapDevice,
}) {
  final matched = devices.entries.where((entry) {
    final device = _safeDeviceMap(entry.value);
    final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";

    return types.contains(type);
  }).toList();

  final count = matched.length;
  final enabled = count > 0;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: !enabled
          ? null
          : () {
              if (count == 1) {
                onTapDevice(matched.first.key);
                return;
              }

              _showDevicePicker(
                context: context,
                title: name,
                devices: matched,
                onTapDevice: onTapDevice,
              );
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: enabled
                    ? accentColor.withValues(alpha: 0.09)
                    : SafeHomeColors.surfaceSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: enabled
                    ? accentColor
                    : SafeHomeColors.textSecondary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13.5,
                  color: enabled
                      ? SafeHomeColors.textPrimary
                      : SafeHomeColors.textSecondary,
                  fontWeight: enabled ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 26),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: enabled
                    ? SafeHomeColors.primarySoft
                    : SafeHomeColors.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  color: enabled
                      ? SafeHomeColors.primaryDark
                      : SafeHomeColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showDevicePicker({
  required BuildContext context,
  required String title,
  required List<MapEntry<String, dynamic>> devices,
  required void Function(String deviceId) onTapDevice,
}) {
  SafeHomeNavigation.showModalSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.76,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: const BoxDecoration(
            color: SafeHomeColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: SafeHomeColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: SafeHomeColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: SafeHomeColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final entry = devices[index];
                    final device = _safeDeviceMap(entry.value);
                    final type = device["type"]?.toString() ?? "unknown";
                    final name = device["name"]?.toString().trim() ?? "";

                    return Material(
                      color: SafeHomeColors.surface,
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(17),
                        onTap: () {
                          final deviceId = entry.key;
                          Navigator.of(sheetContext).pop();

                          Future.delayed(
                            const Duration(milliseconds: 180),
                            () => onTapDevice(deviceId),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: SafeHomeColors.border,
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: SafeHomeColors.primarySoft,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  _deviceIcon(type),
                                  color: SafeHomeColors.primary,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  name.isEmpty ? entry.key : name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: SafeHomeColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: SafeHomeColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
