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
    if (diff.inHours < 1) return "${diff.inMinutes} phút trước";

    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      if (m == 0) return "${h}h trước";
      return "${h}h${m}' trước";
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
    return isDeviceUnsafe(d) ? Colors.red.shade500 : Colors.green.shade600;
  }

  Color getSoftBackground(Map<String, dynamic> d) {
    return isDeviceUnsafe(d)
        ? Colors.red.withValues(alpha: 0.055)
        : Colors.green.withValues(alpha: 0.055);
  }

  Color getSoftBorder(Map<String, dynamic> d) {
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
    final online = isDeviceOnline(d);
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
            border: Border.all(
              color: getSoftBorder(d),
              width: 1,
            ),
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
                            color: online ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 4),

                        Text(
                          online ? "On" : "Off",
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
                              final groupEntries =
                              devices.entries.where((entry) {
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