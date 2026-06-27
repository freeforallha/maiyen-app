import 'package:flutter/material.dart';

import '../safehome_theme.dart';

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

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
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
    final availability =
        d["availability"]?.toString().trim().toLowerCase() ?? "";

    // Đỏ chỉ dùng khi thiết bị xác nhận đang Offline.
    if (availability == "offline") {
      return "off";
    }

    final battery =
    int.tryParse(d["battery"]?.toString() ?? "");
    final batteryLow =
        d["battery_low"] == true ||
            (battery != null && battery <= 20);

    final linkquality =
    int.tryParse(d["linkquality"]?.toString() ?? "");
    final weakSignal =
        linkquality != null &&
            linkquality > 0 &&
            linkquality < 40;

    bool staleResponse = false;
    final lastSeenText = d["last_seen"]?.toString();
    final lastSeen = lastSeenText == null
        ? null
        : DateTime.tryParse(lastSeenText);

    if (lastSeen != null) {
      final ageHours = DateTime.now()
          .toUtc()
          .difference(lastSeen.toUtc())
          .inMinutes /
          60;

      staleResponse = ageHours > heartbeatLimitHours(type);
    }

    // Vàng: lâu không phản hồi, sóng yếu, pin yếu,
    // hoặc trạng thái kết nối chưa xác định rõ.
    if (batteryLow ||
        weakSignal ||
        staleResponse ||
        availability != "online") {
      return "warn";
    }

    return "on";
  }

  String getConnectionDescription(
      Map<String, dynamic> d,
      String status,
      ) {
    if (status == "off") {
      return "Thiết bị đang Offline";
    }

    if (status == "on") {
      return "Thiết bị đang Online";
    }

    final warnings = <String>[];

    final battery =
    int.tryParse(d["battery"]?.toString() ?? "");
    if (d["battery_low"] == true ||
        (battery != null && battery <= 20)) {
      warnings.add("pin yếu");
    }

    final linkquality =
    int.tryParse(d["linkquality"]?.toString() ?? "");
    if (linkquality != null &&
        linkquality > 0 &&
        linkquality < 40) {
      warnings.add("sóng yếu");
    }

    final type = d["type"]?.toString() ?? "door";
    final lastSeenText = d["last_seen"]?.toString();
    final lastSeen = lastSeenText == null
        ? null
        : DateTime.tryParse(lastSeenText);

    if (lastSeen != null) {
      final ageHours = DateTime.now()
          .toUtc()
          .difference(lastSeen.toUtc())
          .inMinutes /
          60;

      if (ageHours > heartbeatLimitHours(type)) {
        warnings.add("lâu không phản hồi");
      }
    }

    if (warnings.isEmpty) {
      return "Kết nối cần kiểm tra";
    }

    return "Cần kiểm tra: ${warnings.join(", ")}";
  }

  Color getConnectionColor(String status) {
    switch (status) {
      case "on":
        return SafeHomeColors.safe;

      case "warn":
        return SafeHomeColors.warning;

      case "off":
      default:
        return SafeHomeColors.danger;
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

    if (diff.inDays < 30) {
      return "${diff.inDays} ngày trước";
    }

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
        return Icons.sensor_door_rounded;

      case "window":
        return Icons.window_rounded;

      case "gate":
        return Icons.garage_rounded;

      case "lock":
        return Icons.lock_rounded;

      case "smoke":
        return Icons.local_fire_department_rounded;

      case "gas":
        return Icons.gas_meter_rounded;

      case "flood":
        return Icons.water_damage_rounded;

      case "sos":
        return Icons.sos_rounded;

      default:
        return Icons.sensors_rounded;
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
    final value = formatAgo(d["last_event"]);

    if (value == "--") {
      return "Chưa có cập nhật";
    }

    return "Cập nhật $value";
  }

  Color getAccentColor(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";

    if (d["tamper"] == true) {
      return SafeHomeColors.danger;
    }

    if (type == "door" ||
        type == "window" ||
        type == "gate" ||
        type == "lock") {
      if (d["contact"] == false) {
        return SafeHomeColors.warning;
      }
    }

    if (type == "smoke" &&
        (d["smoke"] == true || d["tamper"] == true)) {
      return SafeHomeColors.danger;
    }

    if (type == "sos" && isSosActive(d)) {
      return SafeHomeColors.danger;
    }

    if (type == "sos") {
      return SafeHomeColors.safe;
    }

    return SafeHomeColors.safe;
  }

  Color getIconBackground(Map<String, dynamic> d) {
    return getAccentColor(d).withValues(alpha: 0.11);
  }

  List<MapEntry<String, dynamic>> _groupEntries(
      String groupName,
      ) {
    return devices.entries.where((entry) {
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
  }

  Widget _deviceCard({
    required String id,
    required Map<String, dynamic> d,
    required bool compact,
  }) {
    final type = d["type"]?.toString() ?? "door";
    final connectionStatus = getConnectionStatus(d);
    final connectionColor =
    getConnectionColor(connectionStatus);
    final connectionDescription =
    getConnectionDescription(d, connectionStatus);
    final accentColor = getAccentColor(d);

    final cardStatusColor = connectionStatus == "off"
        ? SafeHomeColors.danger
        : connectionStatus == "warn"
        ? SafeHomeColors.warning
        : accentColor;

    return Material(
      color: SafeHomeColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => onTapDevice(id),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 9 : 10,
            compact ? 8 : 9,
            compact ? 9 : 10,
            compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: SafeHomeColors.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: cardStatusColor.withValues(alpha: 0.62),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: cardStatusColor.withValues(alpha: 0.055),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 34 : 36,
                    height: compact ? 34 : 36,
                    decoration: BoxDecoration(
                      color: getIconBackground(d),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getDeviceIcon(type),
                      size: compact ? 18 : 19,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          d["name"]?.toString() ?? id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 13.8 : 14.5,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: SafeHomeColors.textPrimary,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          getMainStatus(d),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11.6 : 12.3,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      getTimeText(d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9.8 : 10.4,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        color: SafeHomeColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Tooltip(
                    message: connectionDescription,
                    child: Semantics(
                      label: connectionDescription,
                      child: Container(
                        width: compact ? 8 : 9,
                        height: compact ? 8 : 9,
                        decoration: BoxDecoration(
                          color: connectionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
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

  Widget _addDeviceButton() {
    return Material(
      color: SafeHomeColors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPairSensor,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: SafeHomeColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required int count,
    required bool showAddButton,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 0,
        bottom: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: SafeHomeColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  TextSpan(
                    text: " ($count)",
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: SafeHomeColors.textSecondary,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showAddButton) _addDeviceButton(),
        ],
      ),
    );
  }

  Widget _emptySecurityState() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 12,
      ),
      child: Center(
        child: Text(
          "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: SafeHomeColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final securityEntries =
    _groupEntries("An ninh ra/vào");
    final emergencyEntries =
    _groupEntries("Nguy hiểm khẩn cấp");

    return Column(
      children: [
        ?header,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final spacing = compact ? 10.0 : 14.0;
              final contentWidth =
                  constraints.maxWidth - 24;
              final itemWidth =
                  (contentWidth - spacing) / 2;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  6,
                  12,
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    if (securityEntries.isNotEmpty)
                      _sectionHeader(
                        title: "An ninh ra/vào",
                        count: securityEntries.length,
                        showAddButton: true,
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 7,
                          ),
                          child: _addDeviceButton(),
                        ),
                      ),
                    if (securityEntries.isEmpty)
                      _emptySecurityState()
                    else
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: securityEntries.map((entry) {
                          return SizedBox(
                            width: itemWidth,
                            child: _deviceCard(
                              id: entry.key,
                              d: safeMap(entry.value),
                              compact: compact,
                            ),
                          );
                        }).toList(),
                      ),
                    if (emergencyEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader(
                        title: "Nguy hiểm khẩn cấp",
                        count: emergencyEntries.length,
                        showAddButton: false,
                      ),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: emergencyEntries.map((entry) {
                          return SizedBox(
                            width: itemWidth,
                            child: _deviceCard(
                              id: entry.key,
                              d: safeMap(entry.value),
                              compact: compact,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
