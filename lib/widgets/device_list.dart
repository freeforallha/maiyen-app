import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';

class DeviceList extends StatelessWidget {
  final Map<String, dynamic> devices;
  final String selectedRoomId;
  final String securityMode;
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
    this.securityMode = "normal",
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
      AppStrings strings,
      ) {
    if (status == "off") {
      return strings.t("Thiết bị đang Offline");
    }

    if (status == "on") {
      return strings.t("Thiết bị đang Online");
    }

    final warnings = <String>[];

    final battery =
    int.tryParse(d["battery"]?.toString() ?? "");
    if (d["battery_low"] == true ||
        (battery != null && battery <= 20)) {
      warnings.add(strings.t("pin yếu"));
    }

    final linkquality =
    int.tryParse(d["linkquality"]?.toString() ?? "");
    if (linkquality != null &&
        linkquality > 0 &&
        linkquality < 40) {
      warnings.add(strings.t("sóng yếu"));
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
        warnings.add(strings.t("lâu không phản hồi"));
      }
    }

    if (warnings.isEmpty) {
      return strings.t("Kết nối cần kiểm tra");
    }

    return strings.choose(
      vi: "Cần kiểm tra: ${warnings.join(", ")}",
      en: "Needs attention: ${warnings.join(", ")}",
    );
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


  String formatAgo(
      dynamic ts,
      AppStrings strings,
      ) {
    if (ts == null) return "--";

    final value = int.tryParse(ts.toString());

    if (value == null || value <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return strings.t("Vừa xong");
    if (diff.inHours < 1) {
      return strings.choose(
        vi: "${diff.inMinutes} phút trước",
        en: "${diff.inMinutes} minutes ago",
      );
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;

      if (m == 0) {
        return strings.choose(
          vi: "${h}h trước",
          en: "${h}h ago",
        );
      }

      return strings.choose(
        vi: "${h}h$m' trước",
        en: "${h}h ${m}m ago",
      );
    }

    if (diff.inDays < 30) {
      return strings.choose(
        vi: "${diff.inDays} ngày trước",
        en: "${diff.inDays} days ago",
      );
    }

    final months = (diff.inDays / 30).floor();

    return strings.choose(
      vi: "$months tháng trước",
      en: "$months months ago",
    );
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
      case "door_lock":
      case "motion":
        return "An ninh ra/vào";

      case "smoke":
      case "gas":
      case "water_leak":
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
      case "door_lock":
        return Icons.lock_rounded;

      case "motion":
        return Icons.directions_walk_rounded;

      case "smoke":
        return Icons.local_fire_department_rounded;

      case "gas":
        return Icons.gas_meter_rounded;

      case "water_leak":
      case "flood":
        return Icons.water_damage_rounded;

      case "sos":
        return Icons.sos_rounded;

      default:
        return Icons.sensors_rounded;
    }
  }

  String getMainStatus(
      Map<String, dynamic> d,
      AppStrings strings,
      ) {
    final type =
        d["type"]?.toString().trim().toLowerCase() ?? "door";

    if (d["tamper"] == true) {
      return strings.t("Bị tháo");
    }

    if (type == "smoke") {
      return parseDeviceBool(d["smoke"]) == true
          ? strings.t("Có khói")
          : strings.t("Bình thường");
    }

    if (type == "sos") {
      return isSosActive(d)
          ? strings.t("Đã kích hoạt")
          : strings.t("Sẵn sàng");
    }

    if (type == "gas") {
      final active =
          parseDeviceBool(d["gas"]) == true ||
              parseDeviceBool(d["gas_alarm"]) == true;

      return active
          ? strings.t("Rò rỉ gas")
          : strings.t("Bình thường");
    }

    if (type == "water_leak" || type == "flood") {
      final active =
          parseDeviceBool(d["water_leak"]) == true ||
              parseDeviceBool(d["leak"]) == true ||
              parseDeviceBool(d["water"]) == true;

      return active
          ? strings.t("Phát hiện ngập nước")
          : strings.t("Bình thường");
    }

    if (type == "motion") {
      final active =
          parseDeviceBool(d["occupancy"]) == true ||
              parseDeviceBool(d["motion"]) == true ||
              parseDeviceBool(d["presence"]) == true;

      return active
          ? strings.t("Phát hiện chuyển động")
          : strings.t("Không có chuyển động");
    }

    final contact = parseDeviceBool(d["contact"]);
    final status =
        d["status"]?.toString().trim().toLowerCase() ?? "";

    return contact == true || status == "closed"
        ? strings.t("Đang đóng")
        : strings.t("Đang mở");
  }

  String getTimeText(
      Map<String, dynamic> d,
      AppStrings strings,
      ) {
    final value = formatAgo(d["last_event"], strings);

    if (value == "--") {
      return strings.t("Chưa có cập nhật");
    }

    return strings.choose(
      vi: "Cập nhật $value",
      en: "Updated $value",
    );
  }

  Color getAccentColor(Map<String, dynamic> d) {
    final evaluation = evaluateDeviceStatus(
      d,
      securityMode: securityMode,
    );

    final level = evaluation["level"]?.toString() ?? "safe";

    if (level == "danger") {
      return SafeHomeColors.danger;
    }

    if (level == "warning") {
      return SafeHomeColors.warning;
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
    required AppStrings strings,
  }) {
    final type = d["type"]?.toString() ?? "door";
    final connectionStatus = getConnectionStatus(d);
    final connectionColor =
    getConnectionColor(connectionStatus);
    final connectionDescription =
    getConnectionDescription(d, connectionStatus, strings);
    final accentColor = getAccentColor(d);

    final cardStatusColor =
    accentColor == SafeHomeColors.danger ||
        connectionStatus == "off"
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
                          getMainStatus(d, strings),
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
                      getTimeText(d, strings),
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

  Widget _emptySecurityState(AppStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 12,
      ),
      child: Center(
        child: Text(
          strings.t(
            "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh",
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
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
    final strings = AppStrings.of(context);
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
                        title: strings.t("An ninh ra/vào"),
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
                      _emptySecurityState(strings)
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
                              strings: strings,
                            ),
                          );
                        }).toList(),
                      ),
                    if (emergencyEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader(
                        title: strings.t("Nguy hiểm khẩn cấp"),
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
                              strings: strings,
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
