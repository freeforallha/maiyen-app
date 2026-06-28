import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final deviceRef = FirebaseDatabase.instance.ref(
    "accounts/$ownerUid/homes/$homeId/devices/$id",
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StreamBuilder<DatabaseEvent>(
        stream: deviceRef.onValue,
        builder: (context, snapshot) {
          final raw = snapshot.data?.snapshot.value;

          late final Map<String, dynamic> device;

          if (raw is Map) {
            device = Map<String, dynamic>.from(raw);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            device = Map<String, dynamic>.from(d);
          } else {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: const SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sensors_off_rounded,
                      size: 44,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Thiết bị không còn tồn tại",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final deviceType =
              device["type"]?.toString() ?? "door";

          final availability =
              device["availability"]?.toString() ?? "unknown";

          final linkquality = _toInt(device["linkquality"]);
          final battery = _toInt(device["battery"]);

          final lastSeen = device["last_seen"];
          final lastEvent = device["last_event"];
          final lastTriggered = device["last_triggered"];

          final contact = device["contact"];
          final smoke = device["smoke"] == true;
          final tamper = device["tamper"] == true;
          final temperature = device["temperature"];
          final humidity = device["humidity"];

          final roomId =
              device["roomId"]?.toString() ?? "unassigned";

          final camera = device["camera"] is Map
              ? Map<String, dynamic>.from(device["camera"] as Map)
              : <String, dynamic>{};

          final cameraType = camera["type"]?.toString().trim() ?? "";
          final cameraName = camera["name"]?.toString().trim() ?? "";
          final cameraUrl = camera["url"]?.toString().trim() ?? "";
          final cameraSerial = camera["deviceSerial"]?.toString().trim() ?? "";

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
            statusValue =
            smoke ? "Phát hiện khói" : "Bình thường";
            statusIcon =
                Icons.local_fire_department_rounded;
            statusColor =
            smoke ? Colors.red : Colors.green;
          } else if (deviceType == "sos") {
            typeTitle = "Trạng thái";
            statusValue = "Sẵn sàng";
            statusIcon = Icons.sos_rounded;
            statusColor = Colors.green;
          } else if (deviceType == "temperature") {
            typeTitle = "Môi trường";
            statusValue = "Đang theo dõi";
            statusIcon =
                Icons.device_thermostat_rounded;
            statusColor = Colors.blue;
          } else if (deviceType == "repeater") {
            typeTitle = "Bộ mở rộng sóng";
            statusValue = availability == "online"
                ? "Đang hoạt động"
                : "Mất kết nối";
            statusIcon =
                Icons.wifi_tethering_rounded;
            statusColor = availability == "online"
                ? Colors.green
                : Colors.red;
          } else {
            typeTitle = "Cửa";
            statusValue = contact == true
                ? "Đang đóng"
                : "Đang mở";
            statusIcon =
                Icons.sensor_door_rounded;
            statusColor = contact == true
                ? Colors.green
                : Colors.red;
          }

          final deviceName =
              device["name"]?.toString().trim() ?? "";

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deviceName.isNotEmpty
                            ? deviceName
                            : id,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    _iconButton(
                      icon: Icons
                          .notifications_active_rounded,
                      color: Colors.amber,
                      onTap: onNotification,
                    ),

                    const SizedBox(width: 8),
                    _iconButton(
                      icon: Icons.videocam_rounded,
                      color: cameraType.isEmpty ? Colors.grey : Colors.blue,
                      onTap: () {
                        if (cameraType.isEmpty) {
                          _showCameraSetupSheet(
                            context: sheetContext,
                            ownerUid: ownerUid,
                            homeId: homeId,
                            deviceId: id,
                          );
                          return;
                        }

                        _openCameraProvider(
                          context: sheetContext,
                          type: cameraType,
                          url: cameraUrl,
                          serial: cameraSerial,
                        );
                      },
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

                if (deviceType == "door" ||
                    deviceType == "smoke")
                  _infoRow(
                    icon:
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    title: "Tháo/Lắp",
                    value: tamper
                        ? "Bị tháo"
                        : "Bình thường",
                    valueColor: tamper
                        ? Colors.redAccent
                        : Colors.black87,
                  ),

                if (deviceType == "temperature" &&
                    temperature != null)
                  _infoRow(
                    icon: Icons.thermostat_rounded,
                    color: Colors.blue,
                    title: "Nhiệt độ",
                    value: "$temperature°C",
                  ),

                if (deviceType == "temperature" &&
                    humidity != null)
                  _infoRow(
                    icon:
                    Icons.water_drop_rounded,
                    color: Colors.cyan,
                    title: "Độ ẩm",
                    value: "$humidity%",
                  ),

                if (deviceType != "repeater")
                  _infoRow(
                    icon:
                    Icons.battery_full_rounded,
                    color: battery != null &&
                        battery < 20
                        ? Colors.red
                        : Colors.green,
                    title: "Pin",
                    value: getBatteryText(device),
                  ),

                _infoRow(
                  icon: Icons.network_cell_rounded,
                  color: linkquality != null &&
                      linkquality < 50
                      ? Colors.red
                      : Colors.purple,
                  title: "Tín hiệu",
                  value: linkquality != null
                      ? "$linkquality"
                      : "N/A",
                ),

                _infoRow(
                  icon: Icons.videocam_rounded,
                  color: cameraType.isEmpty ? Colors.grey : Colors.blue,
                  title: "Camera",
                  value: cameraType.isEmpty
                      ? "Chưa liên kết"
                      : (cameraName.isNotEmpty ? cameraName : cameraType.toUpperCase()),
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
                    value:
                    formatFullDate(lastTriggered),
                  )
                else if (deviceType != "temperature" &&
                    deviceType != "repeater")
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
                      icon:
                      Icons.delete_forever_rounded,
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
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
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
  required bool canEdit,
}) {
  return Builder(
    builder: (context) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canEdit
            ? () async {
                final roomsSnap = await FirebaseDatabase.instance
                    .ref("accounts/$ownerUid/homes/$homeId/rooms")
                    .get();

                final rooms = roomsSnap.value is Map
                    ? Map<String, dynamic>.from(roomsSnap.value as Map)
                    : <String, dynamic>{};

                if (!context.mounted) return;

                final selectedRoom = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) {
                    return SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: rooms.entries.map((entry) {
                          final room = entry.value is Map
                              ? Map<String, dynamic>.from(entry.value as Map)
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

                if (selectedRoom == null || selectedRoom == currentRoomId) {
                  return;
                }

                await FirebaseDatabase.instance
                    .ref(
                      "accounts/$ownerUid/homes/$homeId/devices/$deviceId/roomId",
                    )
                    .set(selectedRoom);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            : null,
        child: FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId/rooms/$currentRoomId")
              .get(),
          builder: (context, snapshot) {
            String roomName = currentRoomId;

            final value = snapshot.data?.value;

            if (value is Map) {
              final room = Map<String, dynamic>.from(value);

              roomName = room["name"]?.toString() ?? currentRoomId;
            }

            return _infoRow(
              icon: canEdit
                  ? Icons.meeting_room_rounded
                  : Icons.lock_outline_rounded,
              color: canEdit ? Colors.orange : Colors.grey,
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
Future<void> _openCameraProvider({
  required BuildContext context,
  required String type,
  required String url,
  required String serial,
}) async {
  if (type == "rtsp" || type == "web") {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link camera không hợp lệ")),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!context.mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không mở được camera")),
      );
    }

    return;
  }

  if (type == "ezviz") {
    final opened = await launchUrl(
      Uri.parse("ezviz://"),
      mode: LaunchMode.externalApplication,
    );

    if (!context.mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa mở được app EZVIZ")),
      );
    }

    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Loại camera này chưa được hỗ trợ")),
  );
}

void _showCameraSetupSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required String deviceId,
}) {
  String type = "ezviz";

  final serialController = TextEditingController();
  final urlController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Liên kết camera",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: "Loại camera",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "ezviz", child: Text("EZVIZ")),
                      DropdownMenuItem(value: "rtsp", child: Text("RTSP")),
                      DropdownMenuItem(value: "web", child: Text("Web link")),
                      DropdownMenuItem(value: "imou", child: Text("Imou")),
                      DropdownMenuItem(value: "tapo", child: Text("Tapo")),
                      DropdownMenuItem(value: "other", child: Text("Khác")),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => type = value);
                    },
                  ),

                  const SizedBox(height: 12),



                  const SizedBox(height: 12),

                  if (type == "rtsp" || type == "web")
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: "Link camera",
                        hintText: "rtsp://... hoặc https://...",
                        border: OutlineInputBorder(),
                      ),
                    ),

                  if (type == "ezviz")
                    TextField(
                      controller: serialController,
                      decoration: const InputDecoration(
                        labelText: "Số serial EZVIZ",
                        hintText: "Ví dụ: BD9724993",
                        border: OutlineInputBorder(),
                      ),
                    ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Lưu camera"),
                      onPressed: () async {
                        await FirebaseDatabase.instance
                            .ref(
                          "accounts/$ownerUid/homes/$homeId/devices/$deviceId/camera",
                        )
                            .set({
                          "enabled": true,
                          "type": type,
                          "name": "",
                          "url": urlController.text.trim(),
                          "deviceSerial": serialController.text.trim(),
                          "updatedAt": ServerValue.timestamp,
                        });

                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}