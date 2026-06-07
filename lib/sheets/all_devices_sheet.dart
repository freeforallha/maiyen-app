import 'package:flutter/material.dart';

int countDevice(
    Map<String, dynamic> devices,
    List<String> types,
    ) {
  int count = 0;

  for (final item in devices.values) {
    final d = Map<String, dynamic>.from(item as Map);

    final type = d["type"]?.toString() ?? "";

    if (types.contains(type)) {
      count++;
    }
  }

  return count;
}

void showAllDevicesSheet({
  required BuildContext context,
  required Map<String, dynamic> devices,
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
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 18),

                _deviceGroup(
                  title: "An ninh ra/vào",
                  icon: Icons.door_front_door_rounded,
                  color: Colors.brown,
                  items: [
                    {
                      "name": "Mở/Đóng cửa",
                      "count": countDevice(devices, ["door"]),
                    },
                    {
                      "name": "Khoá/Mở cửa",
                      "count": countDevice(devices, ["lock", "door_lock"]),
                    },
                    {
                      "name": "Phát hiện chuyển động",
                      "count": countDevice(devices, ["motion"]),
                    },
                  ],
                ),

                _deviceGroup(
                  title: "Nguy hiểm khẩn cấp",
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  items: [
                    {
                      "name": "Báo khói",
                      "count": countDevice(devices, ["smoke"]),
                    },
                    {
                      "name": "Báo ngập",
                      "count": 0,
                    },
                    {
                      "name": "Báo gas",
                      "count": 0,
                    },
                    {
                      "name": "Nút SOS",
                      "count": countDevice(devices, ["sos"]),
                    },
                  ],
                ),

                _deviceGroup(
                  title: "Môi trường",
                  icon: Icons.thermostat_rounded,
                  color: Colors.blue,
                  items: [
                    {
                      "name": "Nhiệt độ / Độ ẩm",
                      "count": countDevice(devices, ["temperature"]),
                    },
                    {
                      "name": "Bụi mịn PM2.5",
                      "count": 0,
                    },
                    {
                      "name": "CO₂",
                      "count": 0,
                    },
                    {
                      "name": "Chất lượng không khí",
                      "count": 0,
                    },
                  ],
                ),

                _deviceGroup(
                  title: "Hạ tầng khác",
                  icon: Icons.settings_input_antenna_rounded,
                  color: Colors.deepPurple,
                  items: [
                    {
                      "name": "Bộ mở rộng sóng",
                      "count": countDevice(devices, ["repeater"]),
                    },
                    {
                      "name": "Bộ điều khiển trung tâm",
                      "count": 0,
                    },
                    {
                      "name": "Hệ thống điện",
                      "count": 0,
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

Widget _deviceGroup({
  required String title,
  required IconData icon,
  required Color color,
  required List<Map<String, dynamic>> items,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                Icon(
                  item["count"] > 0
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: item["count"] > 0
                      ? Colors.green
                      : Colors.grey,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    item["name"],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: item["count"] > 0
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${item["count"]}",
                    style: TextStyle(
                      color: item["count"] > 0
                          ? Colors.green
                          : Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}