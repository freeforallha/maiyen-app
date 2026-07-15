import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';

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
          final strings = AppStrings.of(context);
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
                color: SafeHomeColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sensors_off_rounded,
                      size: 44,
                      color: SafeHomeColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.t("Thiết bị không còn tồn tại"),
                      style: const TextStyle(
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
              device["type"]?.toString().trim().toLowerCase() ?? "unknown";

          final availability =
              device["availability"]?.toString().trim().toLowerCase() ??
              "unknown";

          final linkquality = _toInt(device["linkquality"]);
          final battery = _toInt(device["battery"]);
          final lastSeen = device["last_seen"];
          final lastEvent = device["last_event"];
          final lastTriggered = device["last_triggered"];
          final tamper = parseDeviceBool(device["tamper"]) == true;
          final temperature = device["temperature"];
          final humidity = device["humidity"];

          final health = _getDeviceHealth(
            availability: availability,
            battery: battery,
            linkquality: linkquality,
            lastSeen: lastSeen,
          );

          final displayStatus = _getDeviceDisplayStatus(device);

          final deviceName = device["name"]?.toString().trim() ?? "";

          final hasBattery =
              device["battery"] != null ||
              device["battery_low"] != null ||
              device["battery_status"] != null;

          final showTamper =
              device.containsKey("tamper") ||
              {
                "door",
                "window",
                "gate",
                "lock",
                "door_lock",
                "motion",
                "presence",
                "vibration",
                "glass_break",
                "smoke",
                "heat",
                "carbon_monoxide",
                "gas",
                "water_leak",
                "flood",
              }.contains(deviceType);

          final metricRows = <Widget>[];

          void addMetric({
            required IconData icon,
            required Color color,
            required String title,
            required dynamic value,
            String suffix = "",
          }) {
            if (value == null) {
              return;
            }

            final text = value.toString().trim();

            if (text.isEmpty) {
              return;
            }

            metricRows.add(
              _infoRow(
                icon: icon,
                color: color,
                title: strings.t(title),
                value: "$text$suffix",
              ),
            );
          }

          if (deviceType == "temperature") {
            addMetric(
              icon: Icons.thermostat_rounded,
              color: SafeHomeColors.info,
              title: "Nhiệt độ",
              value: temperature,
              suffix: "°C",
            );

            addMetric(
              icon: Icons.water_drop_rounded,
              color: SafeHomeColors.info,
              title: "Độ ẩm",
              value: humidity,
              suffix: "%",
            );
          }

          if ({"smart_plug", "power_monitor", "ups"}.contains(deviceType)) {
            addMetric(
              icon: Icons.electric_bolt_rounded,
              color: SafeHomeColors.warning,
              title: "Công suất",
              value: device["power"],
              suffix: " W",
            );

            addMetric(
              icon: Icons.speed_rounded,
              color: SafeHomeColors.primary,
              title: "Điện áp",
              value: device["voltage"],
              suffix: " V",
            );

            addMetric(
              icon: Icons.electrical_services_rounded,
              color: SafeHomeColors.primary,
              title: "Dòng điện",
              value: device["current"],
              suffix: " A",
            );

            addMetric(
              icon: Icons.data_usage_rounded,
              color: SafeHomeColors.primary,
              title: "Điện năng",
              value: device["energy"] ?? device["consumption"],
              suffix: " kWh",
            );
          }

          if ({"vibration", "glass_break"}.contains(deviceType)) {
            addMetric(
              icon: Icons.vibration_rounded,
              color: SafeHomeColors.warning,
              title: "Cường độ rung",
              value: device["vibration_strength"],
            );

            addMetric(
              icon: Icons.screen_rotation_rounded,
              color: SafeHomeColors.textSecondary,
              title: "Góc nghiêng",
              value: device["angle"],
              suffix: "°",
            );
          }

          if (deviceType == "smart_valve") {
            addMetric(
              icon: Icons.tune_rounded,
              color: SafeHomeColors.info,
              title: "Độ mở van",
              value: device["position"] ?? device["valve_position"],
              suffix: "%",
            );
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: SafeHomeColors.border,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deviceName.isNotEmpty ? deviceName : id,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: SafeHomeColors.textPrimary,
                            ),
                          ),
                        ),
                        _iconButton(
                          icon: Icons.notifications_active_rounded,
                          color: SafeHomeColors.warning,
                          onTap: onNotification,
                        ),
                        const SizedBox(width: 8),
                        if (onRename != null)
                          _iconButton(
                            icon: Icons.edit_rounded,
                            color: SafeHomeColors.primary,
                            onTap: onRename,
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _infoRow(
                      icon: health.icon,
                      color: health.color,
                      title: strings.t("Tình trạng"),
                      value: strings.statusText(health.text),
                      valueColor: health.color,
                    ),
                    _infoRow(
                      icon: displayStatus.icon,
                      color: displayStatus.color,
                      title: strings.t(displayStatus.title),
                      value: strings.statusText(displayStatus.value),
                      valueColor: displayStatus.color,
                    ),
                    if (showTamper)
                      _infoRow(
                        icon: Icons.warning_amber_rounded,
                        color: tamper
                            ? SafeHomeColors.danger
                            : SafeHomeColors.warning,
                        title: strings.t("Tháo/Lắp"),
                        value: strings.statusText(
                          tamper ? "Bị tháo" : "Bình thường",
                        ),
                        valueColor: tamper
                            ? SafeHomeColors.danger
                            : SafeHomeColors.textPrimary,
                      ),
                    ...metricRows,
                    if (hasBattery)
                      _infoRow(
                        icon: Icons.battery_full_rounded,
                        color: battery != null && battery < 20
                            ? SafeHomeColors.danger
                            : SafeHomeColors.safe,
                        title: strings.t("Pin"),
                        value: strings.statusText(getBatteryText(device)),
                      ),
                    if (linkquality != null)
                      _infoRow(
                        icon: Icons.network_cell_rounded,
                        color: linkquality < 50
                            ? SafeHomeColors.danger
                            : SafeHomeColors.primary,
                        title: strings.t("Tín hiệu"),
                        value: "$linkquality",
                      ),
                    _infoRow(
                      icon: Icons.access_time_rounded,
                      color: SafeHomeColors.primary,
                      title: strings.t("Liên lạc cuối"),
                      value: formatFullDate(lastSeen),
                    ),
                    if (deviceType == "sos")
                      _infoRow(
                        icon: Icons.history_rounded,
                        color: SafeHomeColors.warning,
                        title: strings.t("Lần kích hoạt cuối"),
                        value: formatFullDate(lastTriggered),
                      )
                    else if (deviceType != "temperature" &&
                        deviceType != "repeater")
                      _infoRow(
                        icon: Icons.history_rounded,
                        color: SafeHomeColors.warning,
                        title: strings.t("Sự kiện cuối"),
                        value: formatFullDate(lastEvent),
                      ),
                    const SizedBox(height: 22),
                    if (onDelete != null)
                      Center(
                        child: _iconButton(
                          icon: Icons.delete_forever_rounded,
                          color: SafeHomeColors.danger,
                          size: 26,
                          onTap: onDelete,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _DeviceDisplayStatus {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DeviceDisplayStatus({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

_DeviceDisplayStatus _getDeviceDisplayStatus(Map<String, dynamic> device) {
  final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";

  bool active(List<String> keys) {
    for (final key in keys) {
      if (isActiveDeviceSignal(device[key])) {
        return true;
      }
    }

    return false;
  }

  switch (type) {
    case "door":
    case "window":
    case "gate":
      final closed =
          parseDeviceBool(device["contact"]) == true ||
          device["status"]?.toString().toLowerCase() == "closed";

      return _DeviceDisplayStatus(
        title: type == "window"
            ? "Cửa sổ"
            : type == "gate"
            ? "Cổng"
            : "Cửa",
        value: closed ? "Đang đóng" : "Đang mở",
        icon: type == "window"
            ? Icons.window_rounded
            : type == "gate"
            ? Icons.garage_rounded
            : Icons.sensor_door_rounded,
        color: closed ? SafeHomeColors.safe : SafeHomeColors.danger,
      );

    case "lock":
    case "door_lock":
      final unlocked = normalizeDeviceLockState(device) == "unlocked";

      return _DeviceDisplayStatus(
        title: "Khóa thông minh",
        value: unlocked ? "Khóa đang mở" : "Khóa đang đóng",
        icon: unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
        color: unlocked ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "motion":
      final detected = active(const ["occupancy", "motion"]);

      return _DeviceDisplayStatus(
        title: "Chuyển động",
        value: detected ? "Phát hiện chuyển động" : "Không có chuyển động",
        icon: Icons.directions_walk_rounded,
        color: detected ? SafeHomeColors.warning : SafeHomeColors.safe,
      );

    case "presence":
      final detected = active(const ["presence", "occupancy"]);

      return _DeviceDisplayStatus(
        title: "Hiện diện",
        value: detected ? "Phát hiện hiện diện" : "Không phát hiện hiện diện",
        icon: Icons.sensors_rounded,
        color: detected ? SafeHomeColors.warning : SafeHomeColors.safe,
      );

    case "vibration":
      final detected =
          active(const ["vibration", "shock"]) || isRecentDeviceEvent(device);

      return _DeviceDisplayStatus(
        title: "Rung/chấn động",
        value: detected
            ? "Phát hiện rung/chấn động"
            : "Không có rung bất thường",
        icon: Icons.vibration_rounded,
        color: detected ? SafeHomeColors.warning : SafeHomeColors.safe,
      );

    case "glass_break":
      final detected =
          active(const ["glass_break", "broken_glass"]) ||
          isRecentDeviceEvent(device);

      return _DeviceDisplayStatus(
        title: "Kính vỡ",
        value: detected ? "Phát hiện kính vỡ" : "Không có cảnh báo kính vỡ",
        icon: Icons.broken_image_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "smoke":
      final detected = active(const ["smoke"]);

      return _DeviceDisplayStatus(
        title: "Báo khói",
        value: detected ? "Phát hiện khói" : "Bình thường",
        icon: Icons.local_fire_department_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "heat":
      final detected = active(const [
        "heat",
        "heat_alarm",
        "high_temperature_alarm",
      ]);

      return _DeviceDisplayStatus(
        title: "Báo nhiệt",
        value: detected ? "Nhiệt độ nguy hiểm" : "Bình thường",
        icon: Icons.thermostat_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "carbon_monoxide":
      final detected = active(const ["carbon_monoxide", "co_alarm"]);

      return _DeviceDisplayStatus(
        title: "Khí CO",
        value: detected ? "Phát hiện khí CO" : "Không phát hiện khí CO",
        icon: Icons.dangerous_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "gas":
      final detected = active(const ["gas", "gas_alarm"]);

      return _DeviceDisplayStatus(
        title: "Báo gas",
        value: detected ? "Rò rỉ gas" : "Bình thường",
        icon: Icons.gas_meter_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "water_leak":
    case "flood":
      final detected = active(const ["water_leak", "leak", "water"]);

      return _DeviceDisplayStatus(
        title: "Ngập/rò nước",
        value: detected ? "Phát hiện ngập nước" : "Bình thường",
        icon: Icons.water_damage_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "sos":
      final detected = isSosActive(device);

      return _DeviceDisplayStatus(
        title: "SOS",
        value: detected ? "Đã kích hoạt" : "Sẵn sàng",
        icon: Icons.sos_rounded,
        color: detected ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "temperature":
      return const _DeviceDisplayStatus(
        title: "Môi trường",
        value: "Đang theo dõi",
        icon: Icons.device_thermostat_rounded,
        color: SafeHomeColors.info,
      );

    case "smart_plug":
      final on = normalizeDeviceSwitchState(device) == "on";

      return _DeviceDisplayStatus(
        title: "Ổ điện thông minh",
        value: on ? "Đang bật" : "Đang tắt",
        icon: Icons.power_rounded,
        color: on ? SafeHomeColors.safe : SafeHomeColors.textSecondary,
      );

    case "power_monitor":
      return const _DeviceDisplayStatus(
        title: "Đo điện năng",
        value: "Đang theo dõi điện năng",
        icon: Icons.flash_on_rounded,
        color: SafeHomeColors.primary,
      );

    case "ups":
      final mainsPower = parseDeviceBool(
        device["mains_power"] ??
            device["ac_connected"] ??
            device["input_power"],
      );

      return _DeviceDisplayStatus(
        title: "Nguồn dự phòng",
        value: mainsPower == false
            ? "Đang dùng nguồn dự phòng"
            : "Nguồn điện bình thường",
        icon: Icons.battery_charging_full_rounded,
        color: mainsPower == false
            ? SafeHomeColors.warning
            : SafeHomeColors.safe,
      );

    case "siren":
      final on =
          isActiveDeviceSignal(device["alarm"]) ||
          normalizeDeviceSwitchState(device) == "on";

      return _DeviceDisplayStatus(
        title: "Còi báo động",
        value: on ? "Còi đang bật" : "Còi sẵn sàng",
        icon: Icons.notifications_active_rounded,
        color: on ? SafeHomeColors.danger : SafeHomeColors.safe,
      );

    case "smart_valve":
      final open = normalizeDeviceSwitchState(device) == "on";

      return _DeviceDisplayStatus(
        title: "Van thông minh",
        value: open ? "Van đang mở" : "Van đã đóng",
        icon: Icons.water_drop_rounded,
        color: open ? SafeHomeColors.info : SafeHomeColors.safe,
      );

    case "doorbell":
      return const _DeviceDisplayStatus(
        title: "Chuông cửa",
        value: "Đang hoạt động",
        icon: Icons.notifications_rounded,
        color: SafeHomeColors.info,
      );

    case "keypad":
      return const _DeviceDisplayStatus(
        title: "Bàn phím an ninh",
        value: "Sẵn sàng",
        icon: Icons.grid_3x3_rounded,
        color: SafeHomeColors.safe,
      );

    case "repeater":
      final online = normalizeAvailability(device["availability"]) == "online";

      return _DeviceDisplayStatus(
        title: "Bộ mở rộng sóng",
        value: online ? "Đang hoạt động" : "Mất kết nối",
        icon: Icons.wifi_tethering_rounded,
        color: online ? SafeHomeColors.safe : SafeHomeColors.danger,
      );

    case "hub":
      return const _DeviceDisplayStatus(
        title: "Hub trung tâm",
        value: "Đang hoạt động",
        icon: Icons.router_rounded,
        color: SafeHomeColors.safe,
      );

    default:
      return const _DeviceDisplayStatus(
        title: "Loại thiết bị",
        value: "Chưa nhận diện",
        icon: Icons.sensors_off_rounded,
        color: SafeHomeColors.warning,
      );
  }
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
      color: SafeHomeColors.danger,
    );
  }

  if (battery != null && battery < 20) {
    return const _DeviceHealth(
      text: "Pin yếu",
      icon: Icons.battery_alert_rounded,
      color: SafeHomeColors.warning,
    );
  }

  if (linkquality != null && linkquality < 50) {
    return const _DeviceHealth(
      text: "Sóng yếu",
      icon: Icons.signal_cellular_connected_no_internet_4_bar_rounded,
      color: SafeHomeColors.warning,
    );
  }

  if (lastSeenDate == null || now.difference(lastSeenDate).inHours >= 24) {
    return const _DeviceHealth(
      text: "Cần kiểm tra",
      icon: Icons.info_rounded,
      color: SafeHomeColors.warning,
    );
  }

  if (availability == "online") {
    return const _DeviceHealth(
      text: "Online",
      icon: Icons.check_circle_rounded,
      color: SafeHomeColors.safe,
    );
  }

  return const _DeviceHealth(
    text: "Cần kiểm tra",
    icon: Icons.info_rounded,
    color: SafeHomeColors.warning,
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.14)),
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
  Color valueColor = SafeHomeColors.textPrimary,
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
          style: const TextStyle(
            color: SafeHomeColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
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

