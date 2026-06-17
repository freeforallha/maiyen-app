import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';

void showDeviceDetail({
  required BuildContext context,
  required String id,
  required Map<String, dynamic> d,
  required String ownerUid,
  required String homeId,
  VoidCallback? onRename,
  VoidCallback? onDelete,
  required VoidCallback onNotification,
}) {
  final deviceType = d["type"]?.toString() ?? "door";

  final availability = d["availability"]?.toString() ?? "unknown";
  final linkquality = _toInt(d["linkquality"]);
  final battery = _toInt(d["battery"]);

  final lastSeen = d["last_seen"];
  final lastEvent = d["last_event"];
  final lastTriggered = d["last_triggered"];

  final contact = d["contact"];
  final smoke = d["smoke"] == true;
  final tamper = d["tamper"] == true;
  final temperature = d["temperature"];
  final humidity = d["humidity"];
  final roomId = d["roomId"]?.toString() ?? "unassigned";
  final health = _getDeviceHealth(
    availability: availability,
    battery: battery,
    linkquality: linkquality,
    lastSeen: lastSeen,
  );

  String typeTitle;
  String statusValue;
  IconData statusIcon;
  Color statusColor;

  if (deviceType == "smoke") {
    typeTitle = "Báo cháy";
    statusValue = smoke ? "Phát hiện khói" : "Bình thường";
    statusIcon = Icons.local_fire_department_rounded;
    statusColor = smoke ? Colors.red : Colors.green;
  } else if (deviceType == "sos") {
    typeTitle = "Trạng thái";
    statusValue = "Sẵn sàng";
    statusIcon = Icons.sos_rounded;
    statusColor = Colors.green;
  } else if (deviceType == "temperature") {
    typeTitle = "Môi trường";
    statusValue = "Đang theo dõi";
    statusIcon = Icons.device_thermostat_rounded;
    statusColor = Colors.blue;
  } else if (deviceType == "repeater") {
    typeTitle = "Bộ mở rộng sóng";
    statusValue = availability == "online" ? "Đang hoạt động" : "Mất kết nối";
    statusIcon = Icons.wifi_tethering_rounded;
    statusColor = availability == "online" ? Colors.green : Colors.red;
  } else {
    typeTitle = "Cửa";
    statusValue = contact == true ? "Đang đóng" : "Đang mở";
    statusIcon = Icons.sensor_door_rounded;
    statusColor = contact == true ? Colors.green : Colors.red;
  }

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

            Row(
              children: [
                Expanded(
                  child: Text(
                    (d["name"]?.toString().trim().isNotEmpty == true)
                        ? d["name"].toString().trim()
                        : id,
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
                if (onRename != null)
                  _iconButton(
                    icon: Icons.edit_rounded,
                    color: Colors.teal,
                    onTap: onRename,
                  ),
              ],
            ),

            const SizedBox(height: 18),

            _infoRow(
              icon: health.icon,
              color: health.color,
              title: "Tình trạng",
              value: health.text,
              valueColor: health.color,
            ),

            if (deviceType != "temperature")
              _infoRow(
                icon: statusIcon,
                color: statusColor,
                title: typeTitle,
                value: statusValue,
                valueColor: statusColor,
              ),

            if (deviceType == "door" || deviceType == "smoke")
              _infoRow(
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                title: "Tháo/Lắp",
                value: tamper ? "Bị tháo" : "Bình thường",
                valueColor: tamper ? Colors.redAccent : Colors.black87,
              ),

            if (deviceType == "temperature" && temperature != null)
              _infoRow(
                icon: Icons.thermostat_rounded,
                color: Colors.blue,
                title: "Nhiệt độ",
                value: "$temperature°C",
              ),

            if (deviceType == "temperature" && humidity != null)
              _infoRow(
                icon: Icons.water_drop_rounded,
                color: Colors.cyan,
                title: "Độ ẩm",
                value: "$humidity%",
              ),

            if (deviceType != "repeater")
              _infoRow(
                icon: Icons.battery_full_rounded,
                color: battery != null && battery < 20 ? Colors.red : Colors.green,
                title: "Pin",
                value: getBatteryText(d),
              ),

            _infoRow(
              icon: Icons.network_cell_rounded,
              color: linkquality != null && linkquality < 50 ? Colors.red : Colors.purple,
              title: "Tín hiệu",
              value: linkquality != null ? "$linkquality" : "N/A",
            ),
            _roomPickerRow(
              ownerUid: ownerUid,
              homeId: homeId,
              deviceId: id,
              currentRoomId: roomId,
            ),
            _infoRow(
              icon: Icons.access_time_rounded,
              color: Colors.indigo,
              title: "Liên lạc cuối",
              value: formatFullDate(lastSeen),
            ),

            if (deviceType == "sos")
              _infoRow(
                icon: Icons.history_rounded,
                color: Colors.deepOrange,
                title: "Lần kích hoạt cuối",
                value: formatFullDate(lastTriggered),
              )
            else if (deviceType != "temperature" && deviceType != "repeater")
              _infoRow(
                icon: Icons.history_rounded,
                color: Colors.deepOrange,
                title: "Event cuối",
                value: formatFullDate(lastEvent),
              ),

            const SizedBox(height: 22),

            if (onDelete != null)
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

class _DeviceHealth {
  final String text;
  final IconData icon;
  final Color color;

  const _DeviceHealth({
    required this.text,
    required this.icon,
    required this.color,
  });
}

_DeviceHealth _getDeviceHealth({
  required String availability,
  required int? battery,
  required int? linkquality,
  required dynamic lastSeen,
}) {
  final lastSeenDate = _parseDate(lastSeen);
  final now = DateTime.now();

  if (availability == "offline") {
    return const _DeviceHealth(
      text: "Offline",
      icon: Icons.cancel_rounded,
      color: Colors.red,
    );
  }

  if (battery != null && battery < 20) {
    return const _DeviceHealth(
      text: "Pin yếu",
      icon: Icons.battery_alert_rounded,
      color: Colors.orange,
    );
  }

  if (linkquality != null && linkquality < 50) {
    return const _DeviceHealth(
      text: "Sóng yếu",
      icon: Icons.signal_cellular_connected_no_internet_4_bar_rounded,
      color: Colors.orange,
    );
  }

  if (lastSeenDate == null || now.difference(lastSeenDate).inHours >= 24) {
    return const _DeviceHealth(
      text: "Cần kiểm tra",
      icon: Icons.info_rounded,
      color: Colors.amber,
    );
  }

  if (availability == "online") {
    return const _DeviceHealth(
      text: "Online",
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );
  }

  return const _DeviceHealth(
    text: "Cần kiểm tra",
    icon: Icons.info_rounded,
    color: Colors.amber,
  );
}

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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
Widget _roomPickerRow({
  required String ownerUid,
  required String homeId,
  required String deviceId,
  required String currentRoomId,
}) {
  return Builder(
    builder: (context) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final roomsSnap = await FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId/rooms")
              .get();

          final rooms = roomsSnap.value is Map
              ? Map<String, dynamic>.from(roomsSnap.value as Map)
              : <String, dynamic>{};

          final selectedRoom = await showModalBottomSheet<String>(
            context: context,
            builder: (_) {
              return SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: rooms.entries.map((entry) {
                    final room = entry.value is Map
                        ? Map<String, dynamic>.from(entry.value)
                        : <String, dynamic>{};

                    final roomName =
                        room["name"]?.toString() ?? entry.key;

                    return ListTile(
                      leading: Icon(
                        entry.key == currentRoomId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(roomName),
                      onTap: () {
                        Navigator.pop(context, entry.key);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );

          if (selectedRoom == null ||
              selectedRoom == currentRoomId) {
            return;
          }

          await FirebaseDatabase.instance
              .ref(
            "accounts/$ownerUid/homes/$homeId/devices/$deviceId/roomId",
          )
              .set(selectedRoom);

          Navigator.pop(context);
        },
        child: FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId/rooms/$currentRoomId")
              .get(),
          builder: (context, snapshot) {
            String roomName = currentRoomId;

            final value = snapshot.data?.value;

            if (value is Map) {
              final room = Map<String, dynamic>.from(value);

              roomName =
                  room["name"]?.toString() ??
                      currentRoomId;
            }

            return _infoRow(
              icon: Icons.meeting_room_rounded,
              color: Colors.orange,
              title: "Phòng",
              value: roomName,
            );
          },
        ),
      );
    },
  );
}
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  if (value is int) {
    if (value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  final ms = int.tryParse(text);
  if (ms != null && ms > 0) {
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  return DateTime.tryParse(text)?.toLocal();
}

String formatFullDate(dynamic value) {
  final dt = _parseDate(value);
  if (dt == null) return "N/A";

  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');

  return "${dt.day}/${dt.month}/${dt.year} $hh:$mm";
}
String getBatteryText(Map<String, dynamic> d) {
  final battery = d["battery"];
  final batteryLow = d["battery_low"];
  final batteryStatus = d["battery_status"]?.toString();

  if (battery != null) {
    return "$battery%";
  }

  if (batteryLow != null) {
    return batteryLow == true ? "Pin yếu" : "OK";
  }

  if (batteryStatus == "ok") return "OK";
  if (batteryStatus == "low") return "Pin yếu";

  return "N/A";
}