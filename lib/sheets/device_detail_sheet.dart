import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import 'device_alarm_policy_sheet.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';

void showDeviceDetail({
  required BuildContext context,
  required String id,
  required Map<String, dynamic> d,
  required String ownerUid,
  required String homeId,
  void Function(String deviceId)? onRename,
  void Function(String deviceId)? onDelete,
  required void Function(String deviceId) onNotification,
  required bool canManageAlarmPolicy,
  Map<String, dynamic>? selectableDevices,
}) {
  final deviceChoices = <String, Map<String, dynamic>>{};

  for (final entry in (selectableDevices ?? const <String, dynamic>{}).entries) {
    final value = entry.value;

    if (value is Map) {
      deviceChoices[entry.key] = Map<String, dynamic>.from(value);
    }
  }

  deviceChoices.putIfAbsent(id, () => Map<String, dynamic>.from(d));

  final showDeviceSelector = selectableDevices != null && deviceChoices.isNotEmpty;
  var selectedDeviceId = id;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentDeviceId = selectedDeviceId;
          final fallbackDevice =
              deviceChoices[currentDeviceId] ?? Map<String, dynamic>.from(d);
          final deviceRef = FirebaseDatabase.instance.ref(
            "accounts/$ownerUid/homes/$homeId/devices/$currentDeviceId",
          );

          return StreamBuilder<DatabaseEvent>(
            key: ValueKey("device_detail_$currentDeviceId"),
            stream: deviceRef.onValue,
            builder: (context, snapshot) {
          final strings = AppStrings.of(context);
          final raw = snapshot.data?.snapshot.value;

          late final Map<String, dynamic> device;

          if (raw is Map) {
            device = Map<String, dynamic>.from(raw);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            device = Map<String, dynamic>.from(fallbackDevice);
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
          final supportsAlarmPolicy = supportsDeviceAlarmPolicy(deviceType);
          final alarmPolicy = DeviceAlarmPolicySettings.fromDevice(
            device: device,
            deviceType: deviceType,
          );

          Future<void> saveAlarmPolicy(
            DeviceAlarmPolicySettings nextSettings,
          ) async {
            if (!canManageAlarmPolicy) {
              return;
            }

            try {
              await deviceRef
                  .child("alarmPolicy")
                  .set(nextSettings.toFirebaseMap());
            } catch (_) {
              if (!context.mounted) {
                return;
              }

              showTopToast(
                context,
                strings.t("Không thể lưu cấu hình báo động"),
                color: SafeHomeColors.danger,
                icon: Icons.error_rounded,
              );
            }
          }

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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  deviceName.isNotEmpty
                                      ? deviceName
                                      : currentDeviceId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: SafeHomeColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (showDeviceSelector) ...[
                                const SizedBox(width: 8),
                                _deviceCountButton(
                                  count: deviceChoices.length,
                                  onTap: () async {
                                    final selectedId = await _showDeviceSelector(
                                      context: context,
                                      devices: deviceChoices,
                                      selectedDeviceId: currentDeviceId,
                                      strings: strings,
                                    );

                                    if (selectedId == null ||
                                        selectedId == currentDeviceId) {
                                      return;
                                    }

                                    setSheetState(() {
                                      selectedDeviceId = selectedId;
                                    });
                                  },
                                ),
                              ],
                              if (onRename != null) ...[
                                const SizedBox(width: 8),
                                _compactIconButton(
                                  icon: Icons.edit_rounded,
                                  color: SafeHomeColors.primary,
                                  onTap: () => onRename(currentDeviceId),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _iconButton(
                          icon: Icons.notifications_active_rounded,
                          color: SafeHomeColors.warning,
                          onTap: () => onNotification(currentDeviceId),
                        ),
                      ],
                    ),
                    if (supportsAlarmPolicy) ...[
                      const SizedBox(height: 22),
                      _sectionHeading(
                        icon: Icons.notifications_active_rounded,
                        color: SafeHomeColors.danger,
                        title: strings.t("Cấu hình báo động"),
                      ),
                      const SizedBox(height: 10),
                      _alarmPolicySection(
                        strings: strings,
                        settings: alarmPolicy,
                        isEmergency: isEmergencyAlarmPolicyDevice(deviceType),
                        canEdit: canManageAlarmPolicy,
                        onChanged: saveAlarmPolicy,
                      ),
                    ],
                    const SizedBox(height: 22),
                    _sectionHeading(
                      icon: Icons.info_outline_rounded,
                      color: SafeHomeColors.primary,
                      title: strings.t("Thông tin chi tiết"),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: SafeHomeColors.border),
                      ),
                      child: Column(
                        children: [
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (onDelete != null)
                      Center(
                        child: _iconButton(
                          icon: Icons.delete_forever_rounded,
                          color: SafeHomeColors.danger,
                          size: 26,
                          onTap: () => onDelete(currentDeviceId),
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
      final detected = isVibrationEventActive(device);

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

Widget _sectionHeading({
  required IconData icon,
  required Color color,
  required String title,
}) {
  return Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: SafeHomeColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

Widget _alarmPolicySection({
  required AppStrings strings,
  required DeviceAlarmPolicySettings settings,
  required bool isEmergency,
  required bool canEdit,
  required Future<void> Function(DeviceAlarmPolicySettings settings) onChanged,
}) {
  const delayOptions = <int>[0, 5, 10, 15, 30, 60, 90, 120];
  final dependentControlsEnabled = canEdit && (isEmergency || settings.enabled);
  final selectedDelay = isEmergency ? 0 : settings.triggerDelaySeconds;
  final availableDelayOptions = <int>{
    ...delayOptions,
    selectedDelay,
  }.where((value) => value >= 0 && value <= 120).toList()
    ..sort();

  DeviceAlarmPolicySettings copyWith({
    bool? enabled,
    bool? physicalSirenEnabled,
    bool? fullscreenEnabled,
    int? triggerDelaySeconds,
  }) {
    return DeviceAlarmPolicySettings(
      enabled: isEmergency ? true : enabled ?? settings.enabled,
      physicalSirenEnabled:
          physicalSirenEnabled ?? settings.physicalSirenEnabled,
      fullscreenEnabled: fullscreenEnabled ?? settings.fullscreenEnabled,
      triggerDelaySeconds:
          isEmergency ? 0 : triggerDelaySeconds ?? settings.triggerDelaySeconds,
    );
  }

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: SafeHomeColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: SafeHomeColors.border),
    ),
    child: Column(
      children: [
        _alarmPolicySwitchRow(
          icon: Icons.shield_rounded,
          title: strings.t("Tham gia báo động"),
          value: isEmergency ? true : settings.enabled,
          enabled: canEdit && !isEmergency,
          onChanged: (value) => onChanged(copyWith(enabled: value)),
        ),
        const Divider(height: 1, indent: 52),
        _alarmPolicySwitchRow(
          icon: Icons.campaign_rounded,
          title: strings.t("Bật còi vật lý"),
          value: settings.physicalSirenEnabled,
          enabled: dependentControlsEnabled,
          onChanged: (value) =>
              onChanged(copyWith(physicalSirenEnabled: value)),
        ),
        const Divider(height: 1, indent: 52),
        _alarmPolicySwitchRow(
          icon: Icons.phone_android_rounded,
          title: strings.t("Đánh thức màn hình"),
          value: settings.fullscreenEnabled,
          enabled: dependentControlsEnabled,
          onChanged: (value) => onChanged(copyWith(fullscreenEnabled: value)),
        ),
        const Divider(height: 1, indent: 52),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          child: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.timer_outlined,
                  color: SafeHomeColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.t("Độ trễ kích hoạt"),
                  style: const TextStyle(
                    color: SafeHomeColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedDelay,
                  isDense: true,
                  items: availableDelayOptions
                      .map(
                        (seconds) => DropdownMenuItem<int>(
                          value: seconds,
                          child: Text(
                            seconds == 0
                                ? strings.t("Ngay lập tức")
                                : "$seconds ${strings.t("giây")}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: dependentControlsEnabled && !isEmergency
                      ? (value) {
                          if (value != null) {
                            onChanged(copyWith(triggerDelaySeconds: value));
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _alarmPolicySwitchRow({
  required IconData icon,
  required String title,
  required bool value,
  required bool enabled,
  required ValueChanged<bool> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
    child: Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            color: enabled
                ? SafeHomeColors.primary
                : SafeHomeColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: SafeHomeColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    ),
  );
}

bool _deviceNeedsAttention(Map<String, dynamic> device) {
  final availability =
      device["availability"]?.toString().trim().toLowerCase() ?? "unknown";
  final battery = _toInt(device["battery"]);
  final linkquality = _toInt(device["linkquality"]);
  final batteryLow = parseDeviceBool(device["battery_low"]) == true ||
      device["battery_status"]?.toString().trim().toLowerCase() == "low";
  final health = _getDeviceHealth(
    availability: availability,
    battery: battery,
    linkquality: linkquality,
    lastSeen: device["last_seen"],
  );
  final status = _getDeviceDisplayStatus(device);

  return batteryLow ||
      health.color == SafeHomeColors.warning ||
      health.color == SafeHomeColors.danger ||
      status.color == SafeHomeColors.warning ||
      status.color == SafeHomeColors.danger;
}

Widget _deviceCountButton({
  required int count,
  required VoidCallback onTap,
}) {
  return Material(
    color: SafeHomeColors.primarySoft,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.devices_other_rounded,
              size: 16,
              color: SafeHomeColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              "$count",
              style: const TextStyle(
                color: SafeHomeColors.primary,
                fontSize: 12.5,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _showDeviceSelector({
  required BuildContext context,
  required Map<String, Map<String, dynamic>> devices,
  required String selectedDeviceId,
  required AppStrings strings,
}) {
  final entries = devices.entries.toList()
    ..sort((first, second) {
      final firstAttention = _deviceNeedsAttention(first.value);
      final secondAttention = _deviceNeedsAttention(second.value);

      if (firstAttention != secondAttention) {
        return firstAttention ? -1 : 1;
      }

      final firstName =
          first.value["name"]?.toString().trim().toLowerCase() ?? first.key;
      final secondName =
          second.value["name"]?.toString().trim().toLowerCase() ?? second.key;

      return firstName.compareTo(secondName);
    });

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (selectorContext) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(selectorContext).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: SafeHomeColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hub_rounded,
                      color: SafeHomeColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.t("Điều khiển & hạ tầng"),
                        style: const TextStyle(
                          color: SafeHomeColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      "${entries.length}",
                      style: const TextStyle(
                        color: SafeHomeColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final device = entry.value;
                    final name = device["name"]?.toString().trim();
                    final displayName =
                        name == null || name.isEmpty ? entry.key : name;
                    final status = _getDeviceDisplayStatus(device);
                    final needsAttention = _deviceNeedsAttention(device);
                    final selected = entry.key == selectedDeviceId;
                    final textColor = needsAttention
                        ? SafeHomeColors.warning
                        : SafeHomeColors.textPrimary;

                    return Material(
                      color: selected
                          ? SafeHomeColors.primarySoft
                          : SafeHomeColors.surface,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: () => Navigator.pop(selectorContext, entry.key),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: selected
                                  ? SafeHomeColors.primary.withValues(alpha: 0.42)
                                  : needsAttention
                                  ? SafeHomeColors.warning.withValues(alpha: 0.42)
                                  : SafeHomeColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: (needsAttention
                                          ? SafeHomeColors.warning
                                          : status.color)
                                      .withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  status.icon,
                                  size: 20,
                                  color: needsAttention
                                      ? SafeHomeColors.warning
                                      : status.color,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      strings.statusText(status.value),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: needsAttention
                                            ? SafeHomeColors.warning
                                            : SafeHomeColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: SafeHomeColors.primary,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _compactIconButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
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

