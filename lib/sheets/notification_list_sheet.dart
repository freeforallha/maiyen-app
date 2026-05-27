import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotificationListSheet extends StatelessWidget {
  final String ownerUid;
  final String homeId;
  final String deviceId;

  const NotificationListSheet({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.deviceId,
  });

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  String formatTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}  "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref(
      "accounts/$ownerUid/homes/$homeId/devices/$deviceId/notifications",
    );

    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Thông báo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: ref.onValue,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snap.data!.snapshot.value;

                if (data == null) {
                  return const Center(
                    child: Text(
                      "Chưa có thông báo",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final map = safeMap(data);
                final list = map.entries.toList();

                list.sort((a, b) {
                  final ta = safeMap(a.value)["time"] ?? 0;
                  final tb = safeMap(b.value)["time"] ?? 0;
                  return tb.compareTo(ta);
                });

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = safeMap(list[i].value);

                    String text = item["text"]?.toString() ?? "";
                    final type = item["type"]?.toString() ?? "";

                    text = text
                        .replaceAll("Door opened", "Cửa mở")
                        .replaceAll("Door closed", "Cửa đóng")
                        .replaceAll("Tamper detected", "Phát hiện cạy phá")
                        .replaceAll("Tamper cleared", "Tamper bình thường")
                        .replaceAll("Motion detected", "Phát hiện chuyển động")
                        .replaceAll("Battery low", "Pin yếu")
                        .replaceAll("Device offline", "Thiết bị mất kết nối")
                        .replaceAll("Device online", "Thiết bị đã kết nối lại")
                        .replaceAll("Alarm triggered", "Báo động kích hoạt")
                        .replaceAll("Alarm cleared", "Báo động đã tắt");

                    final lower = text.toLowerCase();

                    final isSafe = lower.contains("đóng") ||
                        lower.contains("bình thường") ||
                        lower.contains("đã tắt") ||
                        lower.contains("kết nối lại") ||
                        lower.contains("cập nhật");

                    final time = item["time"] ?? 0;
                    final dt = DateTime.fromMillisecondsSinceEpoch(time);

                    IconData icon = Icons.notifications;
                    Color color = Colors.blueAccent;

                    if (type == "tamper") {
                      icon = Icons.warning_amber_rounded;
                      color = Colors.red;
                    } else if (type == "door" || type == "status") {
                      icon = Icons.sensor_door_rounded;
                      color = Colors.orange;
                    } else if (type == "motion") {
                      icon = Icons.directions_run_rounded;
                      color = Colors.deepPurple;
                    } else if (type == "battery") {
                      icon = Icons.battery_alert_rounded;
                      color = Colors.amber;
                    } else if (type == "heartbeat") {
                      icon = Icons.sync_rounded;
                      color = Colors.green;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(
                        text,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSafe ? Colors.black : Colors.red.shade300,
                        ),
                      ),
                      subtitle: Text(
                        formatTime(dt),
                        style: TextStyle(
                          color: isSafe ? Colors.grey : Colors.red.shade200,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}