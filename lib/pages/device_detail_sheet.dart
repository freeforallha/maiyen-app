import 'package:flutter/material.dart';

void showDeviceDetail({
  required BuildContext context,
  required String id,
  required Map d,
  required VoidCallback onRename,
  required VoidCallback onDelete,
  required VoidCallback onNotification,
}) {
  final linkquality = d["linkquality"];
  final battery = d["battery"];
  final lastSeen = d["last_seen"];
  final status = d["status"];
  final tamper = d["tamper"] == true;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// HEADER
            Row(
              children: [
                Expanded(
                  child: Text(
                    d["name"] ?? id,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),

                _iconButton(
                  icon: Icons.notifications_active_rounded,
                  color: Colors.amber,
                  onTap: onNotification,
                ),

                const SizedBox(width: 8),

                _iconButton(
                  icon: Icons.edit_rounded,
                  color: Colors.teal,
                  onTap: onRename,
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// INFO LIST
            _infoRow(
              icon: Icons.sensor_door_rounded,
              color: Colors.blue,
              title: "Cửa",
              value: status == "closed" ? "Đang đóng" : "Đang mở",
              valueColor:
              status == "closed" ? Colors.black87 : Colors.redAccent,
            ),

            _infoRow(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              title: "Tháo/Lắp",
              value: tamper ? "Bị tháo" : "Bình thường",
              valueColor: tamper ? Colors.redAccent : Colors.black87,
            ),

            _infoRow(
              icon: Icons.battery_full_rounded,
              color: Colors.green,
              title: "Pin",
              value: battery != null ? "$battery%" : "N/A",
            ),

            _infoRow(
              icon: Icons.network_cell_rounded,
              color: Colors.purple,
              title: "Tín hiệu",
              value: linkquality != null ? "$linkquality" : "N/A",
            ),

            _infoRow(
              icon: Icons.access_time_rounded,
              color: Colors.indigo,
              title: "Cập nhật cuối",
              value: formatFullDate(lastSeen),
            ),

            const SizedBox(height: 22),

            /// DELETE BUTTON
            Center(
              child: _iconButton(
                icon: Icons.delete_forever_rounded,
                color: Colors.red,
                size: 26,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// ================= ICON STYLE (GIỐNG SHARE SHEET) =================
Widget _iconButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  double size = 20,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size),
    ),
  );
}

/// ================= INFO ROW =================
Widget _infoRow({
  required IconData icon,
  required Color color,
  required String title,
  required String value,
  Color valueColor = Colors.black87,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(color: Colors.black54),
        ),

        const Spacer(),

        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// ================= DATE =================
String formatFullDate(dynamic ts) {
  if (ts == null) return "N/A";

  final dt = DateTime.fromMillisecondsSinceEpoch(
    int.tryParse(ts.toString()) ?? 0,
  );

  return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
}