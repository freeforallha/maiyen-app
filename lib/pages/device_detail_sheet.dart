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
    backgroundColor: Colors.grey.shade900,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d["name"] ?? id,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: onNotification,

                  icon: Container(
                    padding: EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: onRename,

                  icon: Container(
                    padding: EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            infoRow(
              Icons.sensor_door,
              "Cửa",
              status == "closed" ? "Đang đóng" : "Đang mở",
              valueColor: status == "closed"
                  ? Colors.white
                  : Colors.red.shade300,
            ),

            infoRow(
              Icons.security,
              "Tháo/Lắp",
              tamper ? "Bị tháo" : "Bình thường",
              valueColor: tamper ? Colors.red.shade300 : Colors.white,
            ),

            infoRow(
              Icons.battery_full,
              "Pin",
              battery != null ? "$battery%" : "N/A",
            ),

            infoRow(
              Icons.network_cell,
              "Tín Hiệu",
              linkquality != null ? "$linkquality" : "N/A",
            ),

            infoRow(
              Icons.access_time,
              "Cập nhật cuối",
              formatFullDate(lastSeen),
            ),

            SizedBox(height: 24),

            Center(
              child: IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget infoRow(
  IconData icon,
  String title,
  String value, {
  Color valueColor = Colors.white,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),

        SizedBox(width: 12),

        Text("$title:", style: TextStyle(color: Colors.white70)),

        Spacer(),

        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

String formatFullDate(dynamic ts) {
  if (ts == null) return "N/A";

  final dt = DateTime.fromMillisecondsSinceEpoch(
    int.tryParse(ts.toString()) ?? 0,
  );

  return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
}
