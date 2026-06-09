import 'package:flutter/material.dart';

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
                const Text(
                  "Toàn bộ thiết bị SafeHome",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),

                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: "An ninh ra/vào",
                  icon: Icons.door_front_door_rounded,
                  color: Colors.brown,
                  onTapDevice: onTapDevice,
                  items: [
                    {"name": "Mở/Đóng cửa", "types": ["door"]},
                    {"name": "Khoá/Mở cửa", "types": ["lock", "door_lock"]},
                    {"name": "Phát hiện chuyển động", "types": ["motion"]},
                  ],
                ),

                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: "Nguy hiểm khẩn cấp",
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  onTapDevice: onTapDevice,
                  items: [
                    {"name": "Báo khói", "types": ["smoke"]},
                    {"name": "Báo ngập", "types": ["water_leak"]},
                    {"name": "Báo gas", "types": ["gas"]},
                    {"name": "Nút SOS", "types": ["sos"]},
                  ],
                ),

                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: "Môi trường",
                  icon: Icons.thermostat_rounded,
                  color: Colors.blue,
                  onTapDevice: onTapDevice,
                  items: [
                    {"name": "Nhiệt độ / Độ ẩm", "types": ["temperature"]},
                    {"name": "Bụi mịn PM2.5", "types": ["pm25"]},
                    {"name": "CO₂", "types": ["co2"]},
                    {"name": "Chất lượng không khí", "types": ["air_quality"]},
                  ],
                ),

                _deviceGroup(
                  context: context,
                  devices: devices,
                  title: "Hạ tầng khác",
                  icon: Icons.settings_input_antenna_rounded,
                  color: Colors.deepPurple,
                  onTapDevice: onTapDevice,
                  items: [
                    {"name": "Bộ mở rộng sóng", "types": ["repeater"]},
                    {"name": "Bộ điều khiển trung tâm", "types": ["hub"]},
                    {"name": "Hệ thống điện", "types": ["power"]},
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
            name: item["name"],
            types: List<String>.from(item["types"]),
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
    final d = Map<String, dynamic>.from(entry.value as Map);
    final type = d["type"]?.toString() ?? "";
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
                  leading: const Icon(Icons.sensors_rounded),
                  title: Text(
                    Map<String, dynamic>.from(entry.value as Map)["name"]
                        ?.toString() ??
                        entry.key,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    final deviceId = entry.key;

                    Navigator.pop(context);

                    Future.delayed(const Duration(milliseconds: 180), () {
                      onTapDevice(deviceId);
                    });
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}