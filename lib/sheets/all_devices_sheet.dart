import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

void showAllDevicesSheet({
  required BuildContext context,
  required Map<String, dynamic> devices,
  required void Function(String deviceId) onTapDevice,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      final strings = AppStrings.of(context);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  strings.t("Toàn bộ thiết bị SafeHome"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: strings.t("An ninh ra/vào"),
                  icon: Icons.door_front_door_rounded,
                  color: Colors.brown,
                  onTapDevice: onTapDevice,
                  items: const [
                    {
                      "name": "Cửa ra/vào",
                      "types": ["door"],
                    },
                    {
                      "name": "Cửa sổ",
                      "types": ["window"],
                    },
                    {
                      "name": "Cổng",
                      "types": ["gate"],
                    },
                    {
                      "name": "Khóa thông minh",
                      "types": ["lock", "door_lock"],
                    },
                    {
                      "name": "Chuyển động",
                      "types": ["motion"],
                    },
                    {
                      "name": "Hiện diện",
                      "types": ["presence"],
                    },
                    {
                      "name": "Rung/chấn động",
                      "types": ["vibration"],
                    },
                    {
                      "name": "Kính vỡ",
                      "types": ["glass_break"],
                    },
                  ],
                ),
                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: strings.t("Nguy hiểm khẩn cấp"),
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  onTapDevice: onTapDevice,
                  items: const [
                    {
                      "name": "Báo khói",
                      "types": ["smoke"],
                    },
                    {
                      "name": "Báo nhiệt",
                      "types": ["heat"],
                    },
                    {
                      "name": "Khí CO",
                      "types": ["carbon_monoxide"],
                    },
                    {
                      "name": "Báo gas",
                      "types": ["gas"],
                    },
                    {
                      "name": "Báo ngập/rò nước",
                      "types": ["water_leak", "flood"],
                    },
                    {
                      "name": "Nút SOS",
                      "types": ["sos"],
                    },
                  ],
                ),
                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: strings.t("Môi trường"),
                  icon: Icons.thermostat_rounded,
                  color: Colors.blue,
                  onTapDevice: onTapDevice,
                  items: const [
                    {
                      "name": "Nhiệt độ/Độ ẩm",
                      "types": ["temperature"],
                    },
                    {
                      "name": "Bụi mịn PM2.5",
                      "types": ["pm25"],
                    },
                    {
                      "name": "CO₂",
                      "types": ["co2"],
                    },
                    {
                      "name": "Chất lượng không khí",
                      "types": ["air_quality"],
                    },
                  ],
                ),
                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: strings.t("Điều khiển & hạ tầng"),
                  icon: Icons.tune_rounded,
                  color: Colors.teal,
                  onTapDevice: onTapDevice,
                  items: const [
                    {
                      "name": "Ổ điện thông minh",
                      "types": ["smart_plug"],
                    },
                    {
                      "name": "Còi báo động",
                      "types": ["siren"],
                    },
                    {
                      "name": "Van thông minh",
                      "types": ["smart_valve"],
                    },
                    {
                      "name": "Camera",
                      "types": ["camera"],
                    },
                    {
                      "name": "Chuông cửa",
                      "types": ["doorbell"],
                    },
                    {
                      "name": "Bàn phím an ninh",
                      "types": ["keypad"],
                    },
                    {
                      "name": "Bộ mở rộng sóng",
                      "types": ["repeater"],
                    },
                    {
                      "name": "Hub trung tâm",
                      "types": ["hub"],
                    },
                    {
                      "name": "Đo điện năng",
                      "types": ["power_monitor"],
                    },
                    {
                      "name": "Nguồn dự phòng UPS",
                      "types": ["ups"],
                    },
                    {
                      "name": "Chưa nhận diện",
                      "types": ["unknown"],
                    },
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
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
      return Icons.cloud_rounded;
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
    case "camera":
      return Icons.videocam_rounded;
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

Widget _deviceGroup({
  required BuildContext context,
  required Map<String, dynamic> devices,
  required String title,
  required IconData icon,
  required Color color,
  required List<Map<String, dynamic>> items,
  required void Function(String deviceId) onTapDevice,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final item in items)
          _deviceTypeRow(
            context: context,
            devices: devices,
            name: AppStrings.of(context).t(item["name"]?.toString() ?? ""),
            types: List<String>.from(item["types"] ?? const <String>[]),
            onTapDevice: onTapDevice,
          ),
      ],
    ),
  );
}

Widget _deviceTypeRow({
  required BuildContext context,
  required Map<String, dynamic> devices,
  required String name,
  required List<String> types,
  required void Function(String deviceId) onTapDevice,
}) {
  final matched = devices.entries.where((entry) {
    final device = _safeDeviceMap(entry.value);
    final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";

    return types.contains(type);
  }).toList();

  final count = matched.length;

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: count == 0
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            count > 0
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: count > 0 ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: count > 0
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                color: count > 0 ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in devices)
                ListTile(
                  leading: Icon(
                    _deviceIcon(
                      _safeDeviceMap(entry.value)["type"]?.toString() ??
                          "unknown",
                    ),
                  ),
                  title: Text(
                    _safeDeviceMap(entry.value)["name"]?.toString() ??
                        entry.key,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    final deviceId = entry.key;
                    Navigator.pop(context);

                    Future.delayed(
                      const Duration(milliseconds: 180),
                      () => onTapDevice(deviceId),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
