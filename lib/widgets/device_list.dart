import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  final Map<String, dynamic> devices;
  final String selectedRoomId;
  final bool isShared;
  final String ownerEmail;
  final Widget? header;

  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;
  final VoidCallback onPairSensor;

  const DeviceList({
    this.header,
    super.key,
    required this.devices,
    required this.isShared,
    required this.ownerEmail,
    required this.onRename,
    required this.onDelete,
    required this.onTapDevice,
    required this.onPairSensor,
    required this.selectedRoomId,
  });

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  double heartbeatLimitHours(String type) {
    switch (type) {
      case "temperature":
        return 2;

      case "repeater":
        return 1;

      case "smoke":
        return 24;

      case "door":
      case "window":
      case "lock":
      case "gate":
      case "sos":
      default:
        return 6;
    }
  }

  String getConnectionStatus(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";
    final availability = d["availability"]?.toString().toLowerCase() ?? "";

    if (availability == "online") {
      return "on";
    }

    final lastSeenText = d["last_seen"]?.toString();
    if (lastSeenText == null || lastSeenText.isEmpty) {
      return availability == "offline" ? "off" : "warn";
    }

    final lastSeen = DateTime.tryParse(lastSeenText);
    if (lastSeen == null) {
      return availability == "offline" ? "off" : "warn";
    }

    final ageHours =
        DateTime.now().toUtc().difference(lastSeen.toUtc()).inMinutes / 60;

    final limit = heartbeatLimitHours(type);
    final offlineLimit = limit * 1.3;

    if (availability == "offline") {
      if (ageHours <= 12) {
        return "warn";
      }

      if (ageHours > offlineLimit) {
        return "off";
      }

      return "warn";
    }

    if (ageHours <= limit) {
      return "on";
    }

    if (ageHours <= offlineLimit) {
      return "warn";
    }

    return "off";
  }

  Color getConnectionColor(String status) {
    switch (status) {
      case "on":
        return Colors.green;

      case "warn":
        return Colors.orange;

      case "off":
      default:
        return Colors.red;
    }
  }

  String getConnectionText(String status) {
    switch (status) {
      case "on":
        return "On";

      case "warn":
        return "!";

      case "off":
      default:
        return "Off";
    }
  }

  String formatAgo(dynamic ts) {
    if (ts == null) return "--";

    final value = int.tryParse(ts.toString());
    if (value == null || value <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inHours < 1) return "${diff.inMinutes} phút trước";

    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      if (m == 0) return "${h}h trước";
      return "${h}h$m' trước";
    }

    if (diff.inDays < 30) return "${diff.inDays} ngày trước";

    final months = (diff.inDays / 30).floor();
    return "$months tháng trước";
  }

  bool isSosActive(Map<String, dynamic> d) {
    final activeUntil =
        int.tryParse(d["sos_active_until"]?.toString() ?? "0") ?? 0;

    if (activeUntil <= 0) return false;

    return DateTime.now().millisecondsSinceEpoch < activeUntil;
  }

  bool isDeviceUnsafe(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";

    if (type == "smoke") {
      return d["smoke"] == true || d["tamper"] == true;
    }

    if (type == "sos") {
      return isSosActive(d);
    }

    if (type == "door" ||
        type == "window" ||
        type == "gate" ||
        type == "lock") {
      return d["contact"] == false || d["tamper"] == true;
    }

    return d["tamper"] == true;
  }

  String getDeviceGroup(String type) {
    switch (type) {
      case "door":
      case "window":
      case "gate":
      case "lock":
        return "An ninh ra/vào";

      case "smoke":
      case "gas":
      case "flood":
      case "sos":
        return "Nguy hiểm khẩn cấp";

      default:
        return "__HIDDEN__";
    }
  }

  IconData getDeviceIcon(String type) {
    switch (type) {
      case "door":
        return Icons.sensor_door_outlined;

      case "window":
        return Icons.window_rounded;

      case "gate":
        return Icons.garage_rounded;

      case "lock":
        return Icons.lock_rounded;

      case "smoke":
        return Icons.local_fire_department_rounded;

      case "sos":
        return Icons.warning_amber_rounded;

      default:
        return Icons.devices_rounded;
    }
  }

  String getMainStatus(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";

    if (type == "smoke") {
      if (d["tamper"] == true) return "Bị tháo";
      return d["smoke"] == true ? "Có khói" : "Bình thường";
    }

    if (type == "sos") {
      return isSosActive(d) ? "Đã kích hoạt" : "Sẵn sàng";
    }

    if (d["tamper"] == true) return "Bị tháo";

    return d["contact"] == true ? "Đang đóng" : "Đang mở";
  }

  String getTimeText(Map<String, dynamic> d) {
    return formatAgo(d["last_event"]);
  }

  Color getAccentColor(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";

    if (d["tamper"] == true) {
      return Colors.red.shade500;
    }

    if (type == "door" ||
        type == "window" ||
        type == "gate" ||
        type == "lock") {
      if (d["contact"] == false) {
        return Colors.orange.shade500;
      }
    }

    if (type == "smoke" && (d["smoke"] == true || d["tamper"] == true)) {
      return Colors.red.shade500;
    }

    if (type == "sos" && isSosActive(d)) {
      return Colors.red.shade500;
    }

    return Colors.green.shade600;
  }

  Color getSoftBackground(Map<String, dynamic> d) {
    return isDeviceUnsafe(d)
        ? Colors.red.withValues(alpha: 0.055)
        : Colors.green.withValues(alpha: 0.055);
  }

  Color getSoftBorder(Map<String, dynamic> d) {
    final connectionStatus = getConnectionStatus(d);

    if (connectionStatus == "warn") {
      return Colors.orange.withValues(alpha: 0.32);
    }

    if (connectionStatus == "off") {
      return Colors.red.withValues(alpha: 0.32);
    }

    return isDeviceUnsafe(d)
        ? Colors.red.withValues(alpha: 0.28)
        : Colors.green.withValues(alpha: 0.24);
  }

  Widget _deviceCard({
    required BuildContext context,
    required String id,
    required Map<String, dynamic> d,
    required bool compact,
  }) {
    final type = d["type"]?.toString() ?? "door";
    final connectionStatus = getConnectionStatus(d);
    final accentColor = getAccentColor(d);

    final titleSize = compact ? 13.5 : 15.0;
    final statusSize = compact ? 14.0 : 15.5;
    final smallTextSize = compact ? 10.5 : 11.5;

    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: () => onTapDevice(id),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: getSoftBorder(d), width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                offset: const Offset(0, 4),
                color: Colors.black.withValues(alpha: 0.035),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getDeviceIcon(type),
                          size: compact ? 16 : 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d["name"]?.toString() ?? id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      getMainStatus(d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: statusSize,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        height: 1.05,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            getTimeText(d),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: smallTextSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.black45,
                            ),
                          ),
                        ),

                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: getConnectionColor(connectionStatus),
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 4),

                        Text(
                          getConnectionText(connectionStatus),
                          style: TextStyle(
                            fontSize: smallTextSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          ?header,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;
                final spacing = compact ? 10.0 : 16.0;
                final itemWidth = (constraints.maxWidth - spacing - 16) / 2;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final groupName in [
                          "An ninh ra/vào",
                          "Nguy hiểm khẩn cấp",
                        ]) ...[
                          Builder(
                            builder: (_) {
                              final groupEntries = devices.entries.where((
                                entry,
                              ) {
                                final d = safeMap(entry.value);
                                final type = d["type"]?.toString() ?? "door";

                                if (getDeviceGroup(type) != groupName) {
                                  return false;
                                }

                                if (selectedRoomId == "overview") {
                                  return true;
                                }

                                final roomId =
                                    d["roomId"]?.toString() ?? "unassigned";

                                return roomId == selectedRoomId;
                              }).toList();

                              if (groupEntries.isEmpty &&
                                  groupName != "An ninh ra/vào") {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 2,
                                      top: 2,
                                      bottom: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: groupEntries.isEmpty
                                              ? const SizedBox.shrink()
                                              : Text(
                                                  groupName,
                                                  style: TextStyle(
                                                    fontSize: compact ? 13 : 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                        ),

                                        if (groupName == "An ninh ra/vào")
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            onTap: onPairSensor,
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.20,
                                                  ),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.add_rounded,
                                                size: 22,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Wrap(
                                    spacing: spacing,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.start,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.start,
                                    children: groupEntries.map((entry) {
                                      final d = safeMap(entry.value);

                                      return SizedBox(
                                        width: itemWidth,
                                        child: _deviceCard(
                                          context: context,
                                          id: entry.key,
                                          d: d,
                                          compact: compact,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
