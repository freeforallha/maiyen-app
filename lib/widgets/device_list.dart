import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  final Map<String, dynamic> devices;

  final bool isShared;
  final String ownerEmail;
  final Widget? header;

  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;

  const DeviceList({
    this.header,
    super.key,
    required this.devices,
    required this.isShared,
    required this.ownerEmail,
    required this.onRename,
    required this.onDelete,
    required this.onTapDevice,
  });

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  bool isDeviceOnline(Map<String, dynamic> d) {
    return d["availability"] == "online";
  }

  String formatAgo(dynamic ts) {
    if (ts == null) return "--";

    final value = int.tryParse(ts.toString());
    if (value == null || value <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Vừa xong";

    if (diff.inHours < 1) {
      return "${diff.inMinutes} phút trước";
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;

      if (m == 0) return "${h}h trước";
      return "${h}h${m}' trước";
    }

    return "${diff.inDays} ngày trước";
  }

  bool isDeviceUnsafe(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";

    if (type == "smoke") {
      return d["smoke"] == true || d["tamper"] == true;
    }

    if (type == "sos") {
      return false;
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

      case "temperature":
      case "humidity":
      case "air_quality":
      case "pm25":
      case "co2":
      case "repeater":
      case "router":
      case "hub":
      case "coordinator":
        return "__HIDDEN__";

      default:
        return "__HIDDEN__";
    }
  }

  Widget buildDeviceIconBadge({
    required String type,
    required bool isUnsafe,
    required bool compact,
  }) {
    if (type == "smoke") {
      return Icon(
        Icons.smoke_free_rounded,
        size: compact ? 28 : 32,
        color: Colors.deepOrange,
      );
    }

    if (type == "sos") {
      return Icon(
        Icons.emergency_rounded,
        size: compact ? 28 : 32,
        color: Colors.red,
      );
    }

    return Icon(
      Icons.door_front_door_rounded,
      size: compact ? 28 : 32,
      color: isUnsafe ? Colors.brown.shade700 : Colors.brown.shade500,
    );
  }

  Widget _deviceCard({
    required BuildContext context,
    required String id,
    required Map<String, dynamic> d,
    required bool compact,
  }) {
    final type = d["type"]?.toString() ?? "door";
    final isUnsafe = isDeviceUnsafe(d);
    final online = isDeviceOnline(d);
    final eventAgo = formatAgo(d["last_event"]);

    final titleSize = compact ? 14.0 : 16.0;
    final textSize = compact ? 12.0 : 13.0;
    final smallTextSize = compact ? 10.5 : 12.0;
    final padding = compact ? 9.0 : 11.0;

    final bgColor = isUnsafe ? Colors.red.shade100 : Colors.green.shade100;
    final borderColor = isUnsafe ? Colors.red.shade300 : Colors.green.shade300;

    if (type == "door" ||
        type == "window" ||
        type == "gate" ||
        type == "lock") {
      final isClosed = d["contact"] == true;
      final tamper = d["tamper"] == true;

      return Align(
        alignment: Alignment.topLeft,
        child: InkWell(
          onTap: () => onTapDevice(id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    buildDeviceIconBadge(
                      type: type,
                      isUnsafe: isUnsafe,
                      compact: compact,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        d["name"]?.toString() ?? id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    Icon(
                      isClosed ? Icons.check_circle : Icons.cancel,
                      size: compact ? 15 : 16,
                      color: isClosed ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isClosed ? "Đóng" : "Mở",
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const Spacer(),

                    Icon(
                      tamper ? Icons.cancel : Icons.check_circle,
                      size: compact ? 15 : 16,
                      color: tamper ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tamper ? "Bị tháo" : "BT",
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  "${isClosed ? "Đóng" : "Mở"}: $eventAgo",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: smallTextSize,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: online ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      online ? "Online" : "Offline",
                      style: TextStyle(
                        fontSize: smallTextSize,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    String subtitle;

    switch (type) {
      case "smoke":
        subtitle = d["smoke"] == true ? "Có khói" : "Bình thường";
        break;

      case "sos":
        subtitle = online ? "Online" : "Offline";
        break;

      default:
        subtitle = online ? "Online" : "Offline";
    }

    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: () => onTapDevice(id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              buildDeviceIconBadge(
                type: type,
                isUnsafe: isUnsafe,
                compact: compact,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d["name"]?.toString() ?? id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: textSize,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: online ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          online ? "Online" : "Offline",
                          style: TextStyle(
                            fontSize: smallTextSize,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
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
          if (header != null) header!,
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
                              final groupEntries = devices.entries.where((entry) {
                                final d = safeMap(entry.value);
                                final type = d["type"]?.toString() ?? "door";
                                return getDeviceGroup(type) == groupName;
                              }).toList();

                              if (groupEntries.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 2,
                                      top: 10,
                                      bottom: 8,
                                    ),
                                    child: Text(
                                      groupName,
                                      style: TextStyle(
                                        fontSize: compact ? 13 : 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
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