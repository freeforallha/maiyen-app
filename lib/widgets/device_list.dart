import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/emergency_pulse_ticker.dart';
import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';
import '../services/notification_service.dart';
import '../sheets/device_alarm_policy_sheet.dart';

class DeviceList extends StatefulWidget {
  final String homeId;
  final String ownerUid;
  final String hubId;
  final Map<String, dynamic> devices;
  final String selectedRoomId;
  final String securityMode;
  final Map<String, dynamic> personalAlarmRules;
  final bool isShared;
  final String ownerEmail;
  final Widget? header;
  final double bottomPadding;

  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;
  final void Function(Map<String, dynamic> devices)? onTapInfrastructureGroup;
  final VoidCallback onPairSensor;

  const DeviceList({
    this.header,
    super.key,
    required this.homeId,
    required this.ownerUid,
    required this.hubId,
    required this.devices,
    required this.isShared,
    required this.ownerEmail,
    required this.onRename,
    required this.onDelete,
    required this.onTapDevice,
    this.onTapInfrastructureGroup,
    required this.onPairSensor,
    required this.selectedRoomId,
    this.securityMode = "normal",
    this.personalAlarmRules = const <String, dynamic>{},
    this.bottomPadding = 28,
  });

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  StreamSubscription<DatabaseEvent>? _deviceOrderSubscription;
  final Map<String, GlobalKey> _sectionGridKeys = {};
  String? _draggingDeviceId;
  String? _draggingSectionKey;
  List<String>? _draggingSectionOrder;
  Offset _draggingCardOffset = Offset.zero;
  Offset _draggingPointerOffset = Offset.zero;
  bool _draggingDeviceDropping = false;
  bool _mutingHomeSiren = false;
  bool _sirenAlertPulseDanger = false;
  Timer? _deviceDropTimer;
  Timer? _emergencyExpiryTimer;
  final Set<String> _acknowledgingEmergencyDeviceIds = <String>{};
  final Set<String> _locallyAcknowledgedEmergencyTriggers = <String>{};
  Map<String, Map<String, int>> _deviceOrderMap = {};
  Map<String, Map<String, int>> _localDeviceOrderMap = {};
  Map<String, Map<String, int>> _optimisticDeviceOrderMap = {};

  Map<String, dynamic> get devices => widget.devices;
  String get selectedRoomId => widget.selectedRoomId;
  String get securityMode => widget.securityMode;
  Widget? get header => widget.header;
  double get bottomPadding => widget.bottomPadding;
  VoidCallback get onPairSensor => widget.onPairSensor;
  Function(String) get onTapDevice => widget.onTapDevice;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? "";
  String get _homeId => widget.homeId.trim();
  String get _ownerUid => widget.ownerUid.trim();
  String get _hubId => widget.hubId.trim();

  static const String _deviceOrderRoot = "deviceOrder";

  @override
  void initState() {
    super.initState();
    EmergencyPulseTicker.ensureStarted();
    _sirenAlertPulseDanger = EmergencyPulseTicker.phase.value;
    EmergencyPulseTicker.phase.addListener(_handleSharedEmergencyPulse);
    _startDeviceOrderListener();
    _syncSirenAlertPulse();
    _syncEmergencyExpiryTimer();
  }

  @override
  void didUpdateWidget(covariant DeviceList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.homeId != widget.homeId ||
        oldWidget.ownerUid != widget.ownerUid) {
      _deviceOrderMap = {};
      _localDeviceOrderMap = {};
      _optimisticDeviceOrderMap = {};
      _acknowledgingEmergencyDeviceIds.clear();
      _locallyAcknowledgedEmergencyTriggers.clear();
      _clearDeviceDragState();
      _startDeviceOrderListener();
    }

    _syncSirenAlertPulse();
    _syncEmergencyExpiryTimer();
  }

  @override
  void dispose() {
    EmergencyPulseTicker.phase.removeListener(_handleSharedEmergencyPulse);
    _deviceOrderSubscription?.cancel();
    _deviceDropTimer?.cancel();
    _emergencyExpiryTimer?.cancel();
    super.dispose();
  }

  bool _isSirenActive(Map<String, dynamic> device) {
    return isActiveDeviceSignal(device["alarm"]) ||
        normalizeDeviceSwitchState(device) == "on";
  }

  bool _hasActiveSiren() {
    for (final value in devices.values) {
      final device = safeMap(value);
      final type = device["type"]?.toString().trim().toLowerCase() ?? "";

      if (type == "siren" && _isSirenActive(device)) {
        return true;
      }
    }

    return false;
  }

  bool _isEmergencyDeviceActiveForUi(
    String deviceId,
    Map<String, dynamic> device,
  ) {
    final type = device["type"]?.toString().trim().toLowerCase() ?? "";

    if (!isEmergencyStatusDeviceType(type)) {
      return false;
    }

    final triggeredAt = _emergencyTriggeredAt(device);

    if (triggeredAt > 0) {
      return emergencyStatusActiveUntil(device) >
              DateTime.now().millisecondsSinceEpoch &&
          !_isEmergencyAcknowledgedByCurrentUser(deviceId, device);
    }

    final evaluation = evaluateDeviceStatus(device, securityMode: securityMode);

    return evaluation["level"]?.toString() == "emergency";
  }

  bool _hasActiveEmergencyDevice() {
    for (final entry in devices.entries) {
      if (_isEmergencyDeviceActiveForUi(entry.key, safeMap(entry.value))) {
        return true;
      }
    }

    return false;
  }

  bool _hasActiveAlertPulseTarget() {
    return _hasActiveSiren() || _hasActiveEmergencyDevice();
  }

  void _handleSharedEmergencyPulse() {
    if (!mounted || !_hasActiveAlertPulseTarget()) {
      return;
    }

    final next = EmergencyPulseTicker.phase.value;
    if (_sirenAlertPulseDanger == next) {
      return;
    }

    setState(() {
      _sirenAlertPulseDanger = next;
    });
  }

  void _syncSirenAlertPulse() {
    _sirenAlertPulseDanger = _hasActiveAlertPulseTarget()
        ? EmergencyPulseTicker.phase.value
        : false;
  }

  void _startDeviceOrderListener() {
    _deviceOrderSubscription?.cancel();
    _deviceOrderSubscription = null;

    final uid = _currentUid;
    final homeId = _homeId;

    if (uid.isEmpty || homeId.isEmpty) {
      if (mounted) {
        setState(() {
          _deviceOrderMap = {};
          _localDeviceOrderMap = {};
          _optimisticDeviceOrderMap = {};
        });
      }

      return;
    }

    unawaited(_loadLocalDeviceOrder(uid: uid, homeId: homeId));

    _deviceOrderSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/$_deviceOrderRoot/$homeId")
        .onValue
        .listen((event) {
          final raw = event.snapshot.value;
          final orderMap = <String, Map<String, int>>{};

          if (raw is Map) {
            raw.forEach((sectionKey, sectionValue) {
              if (sectionValue is! Map) {
                return;
              }

              final sectionOrders = <String, int>{};

              sectionValue.forEach((deviceId, value) {
                final order = int.tryParse(value?.toString() ?? "");

                if (order != null) {
                  sectionOrders[deviceId.toString()] = order;
                }
              });

              orderMap[sectionKey.toString()] = sectionOrders;
            });
          }

          if (!mounted) return;

          setState(() {
            _deviceOrderMap = orderMap;
            _optimisticDeviceOrderMap.removeWhere((sectionKey, sectionOrders) {
              final syncedOrders = orderMap[sectionKey];

              return syncedOrders != null &&
                  _sameDeviceOrder(syncedOrders, sectionOrders);
            });
          });
        });
  }

  String _localOrderPrefsKey({required String uid, required String homeId}) {
    return "safehome_device_order_${uid}_$homeId";
  }

  Future<void> _loadLocalDeviceOrder({
    required String uid,
    required String homeId,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(
        _localOrderPrefsKey(uid: uid, homeId: homeId),
      );

      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      final localMap = <String, Map<String, int>>{};

      if (decoded is Map) {
        decoded.forEach((sectionKey, sectionValue) {
          if (sectionValue is! Map) {
            return;
          }

          final sectionOrders = <String, int>{};

          sectionValue.forEach((deviceId, value) {
            final order = int.tryParse(value?.toString() ?? "");

            if (order != null) {
              sectionOrders[deviceId.toString()] = order;
            }
          });

          localMap[sectionKey.toString()] = sectionOrders;
        });
      }

      if (!mounted || uid != _currentUid || homeId != _homeId) {
        return;
      }

      setState(() {
        _localDeviceOrderMap = localMap;
      });
    } catch (_) {}
  }

  Future<void> _saveLocalDeviceOrder({
    required String uid,
    required String homeId,
    required Map<String, Map<String, int>> orderMap,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _localOrderPrefsKey(uid: uid, homeId: homeId),
        jsonEncode(orderMap),
      );
    } catch (_) {}
  }

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

  double deviceHeartbeatLimitHours(String type) {
    return heartbeatLimitHours(type);
  }

  String getConnectionStatus(Map<String, dynamic> d) {
    final type = d["type"]?.toString() ?? "door";
    final availability =
        d["availability"]?.toString().trim().toLowerCase() ?? "";

    // Đỏ chỉ dùng khi thiết bị xác nhận đang Offline.
    if (availability == "offline") {
      return "off";
    }

    final battery = int.tryParse(d["battery"]?.toString() ?? "");
    final batteryLow =
        d["battery_low"] == true || (battery != null && battery <= 20);

    final linkquality = int.tryParse(d["linkquality"]?.toString() ?? "");
    final weakSignal =
        linkquality != null && linkquality > 0 && linkquality < 40;

    bool staleResponse = false;
    final lastSeenText = d["last_seen"]?.toString();
    final lastSeen = lastSeenText == null
        ? null
        : DateTime.tryParse(lastSeenText);

    if (lastSeen != null) {
      final ageHours =
          DateTime.now().toUtc().difference(lastSeen.toUtc()).inMinutes / 60;

      staleResponse = ageHours > deviceHeartbeatLimitHours(type);
    }

    // Vàng: lâu không phản hồi, sóng yếu, pin yếu,
    // hoặc trạng thái kết nối chưa xác định rõ.
    if (batteryLow || weakSignal || staleResponse || availability != "online") {
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

    final battery = int.tryParse(d["battery"]?.toString() ?? "");
    if (d["battery_low"] == true || (battery != null && battery <= 20)) {
      warnings.add(strings.t("pin yếu"));
    }

    final linkquality = int.tryParse(d["linkquality"]?.toString() ?? "");
    if (linkquality != null && linkquality > 0 && linkquality < 40) {
      warnings.add(strings.t("sóng yếu"));
    }

    final type = d["type"]?.toString() ?? "door";
    final lastSeenText = d["last_seen"]?.toString();
    final lastSeen = lastSeenText == null
        ? null
        : DateTime.tryParse(lastSeenText);

    if (lastSeen != null) {
      final ageHours =
          DateTime.now().toUtc().difference(lastSeen.toUtc()).inMinutes / 60;

      if (ageHours > deviceHeartbeatLimitHours(type)) {
        warnings.add(strings.t("lâu không phản hồi"));
      }
    }

    if (warnings.isEmpty) {
      return strings.t("Kết nối cần kiểm tra");
    }

    return strings.deviceWarningsText(warnings);
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

  String formatAgo(dynamic ts, AppStrings strings) {
    if (ts == null) return "--";

    final value = int.tryParse(ts.toString());

    if (value == null || value <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return strings.t("Vừa xong");
    if (diff.inHours < 1) {
      return strings.minutesAgo(diff.inMinutes);
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;

      if (m == 0) {
        return strings.hoursAgoShort(h);
      }

      return strings.hoursMinutesAgoShort(h, m);
    }

    if (diff.inDays < 30) {
      return strings.daysAgo(diff.inDays);
    }

    final months = (diff.inDays / 30).floor();

    return strings.monthsAgo(months);
  }

  int _emergencyTriggeredAt(Map<String, dynamic> device) {
    return emergencyStatusTriggeredAt(device);
  }

  String _emergencyAcknowledgementKey(String deviceId, int triggeredAt) {
    return "$deviceId|$triggeredAt";
  }

  bool _isEmergencyAcknowledgedByCurrentUser(
    String deviceId,
    Map<String, dynamic> device,
  ) {
    final uid = _currentUid;
    final triggeredAt = _emergencyTriggeredAt(device);

    if (uid.isEmpty || triggeredAt <= 0) {
      return false;
    }

    if (_locallyAcknowledgedEmergencyTriggers.contains(
      _emergencyAcknowledgementKey(deviceId, triggeredAt),
    )) {
      return true;
    }

    final acknowledgements = safeMap(device["emergencyAcknowledgements"]);
    final oldSosAcknowledgements = safeMap(device["sosAcknowledgements"]);
    final acknowledgedTrigger =
        int.tryParse(acknowledgements[uid]?.toString() ?? "0") ?? 0;
    final oldSosAcknowledgedTrigger =
        int.tryParse(oldSosAcknowledgements[uid]?.toString() ?? "0") ?? 0;

    return acknowledgedTrigger >= triggeredAt ||
        oldSosAcknowledgedTrigger >= triggeredAt;
  }

  bool _isEmergencyAwaitingAcknowledgement(
    String deviceId,
    Map<String, dynamic> device,
  ) {
    final type = device["type"]?.toString().trim().toLowerCase() ?? "";
    final triggeredAt = _emergencyTriggeredAt(device);

    return isEmergencyStatusDeviceType(type) &&
        triggeredAt > 0 &&
        emergencyStatusActiveUntil(device) >
            DateTime.now().millisecondsSinceEpoch &&
        !_isEmergencyAcknowledgedByCurrentUser(deviceId, device);
  }

  void _syncEmergencyExpiryTimer() {
    _emergencyExpiryTimer?.cancel();
    _emergencyExpiryTimer = null;

    final now = DateTime.now().millisecondsSinceEpoch;
    int? nearestExpiry;

    for (final entry in devices.entries) {
      final deviceId = entry.key;
      final device = safeMap(entry.value);
      final type = device["type"]?.toString().trim().toLowerCase() ?? "";

      if (!isEmergencyStatusDeviceType(type) ||
          _isEmergencyAcknowledgedByCurrentUser(deviceId, device)) {
        continue;
      }

      final activeUntil = emergencyStatusActiveUntil(device);

      if (activeUntil <= now) {
        continue;
      }

      if (nearestExpiry == null || activeUntil < nearestExpiry) {
        nearestExpiry = activeUntil;
      }
    }

    if (nearestExpiry == null) {
      return;
    }

    final delayMs = (nearestExpiry - now + 120)
        .clamp(120, emergencyStatusHoldMs)
        .toInt();

    _emergencyExpiryTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) {
        return;
      }

      setState(() {});
      _syncEmergencyExpiryTimer();
    });
  }

  String _emergencyAcknowledgeLabel(AppStrings strings) {
    return strings.choose(
      vi: "XÁC NHẬN",
      en: "ACKNOWLEDGE",
      zh: "确认",
      ko: "확인",
      ja: "確認",
      de: "BESTÄTIGEN",
      ru: "ПОДТВЕРДИТЬ",
      fr: "CONFIRMER",
      es: "CONFIRMAR",
      id: "KONFIRMASI",
      th: "ยืนยัน",
      ms: "SAHKAN",
      fil: "KUMPIRMAHIN",
      km: "បញ្ជាក់",
      my: "အတည်ပြုရန်",
      lo: "ຢືນຢັນ",
    );
  }

  String _emergencyAcknowledgeErrorText(AppStrings strings) {
    return strings.choose(
      vi: "Không thể xác nhận cảnh báo",
      en: "Could not acknowledge the alert",
      zh: "无法确认警报",
      ko: "경고를 확인할 수 없습니다",
      ja: "警報を確認できませんでした",
      de: "Warnung konnte nicht bestätigt werden",
      ru: "Не удалось подтвердить тревогу",
      fr: "Impossible de confirmer l’alerte",
      es: "No se pudo confirmar la alerta",
      id: "Peringatan tidak dapat dikonfirmasi",
      th: "ไม่สามารถยืนยันการแจ้งเตือนได้",
      ms: "Amaran tidak dapat disahkan",
      fil: "Hindi makumpirma ang alerto",
      km: "មិនអាចបញ្ជាក់ការជូនដំណឹងបានទេ",
      my: "သတိပေးချက်ကို အတည်မပြုနိုင်ပါ",
      lo: "ບໍ່ສາມາດຢືນຢັນການເຕືອນໄດ້",
      ta: "எச்சரிக்கையை உறுதிப்படுத்த முடியவில்லை",
      pt: "Não foi possível confirmar o alerta",
      tet: "La bele konfirma alerta",
    );
  }

  Future<void> _acknowledgeEmergency(
    String deviceId,
    Map<String, dynamic> device,
    AppStrings strings,
  ) async {
    final uid = _currentUid;
    final ownerUid = _ownerUid;
    final homeId = _homeId;
    final triggeredAt = _emergencyTriggeredAt(device);

    if (uid.isEmpty ||
        ownerUid.isEmpty ||
        homeId.isEmpty ||
        triggeredAt <= 0 ||
        !_isEmergencyAwaitingAcknowledgement(deviceId, device) ||
        _acknowledgingEmergencyDeviceIds.contains(deviceId)) {
      return;
    }

    setState(() {
      _acknowledgingEmergencyDeviceIds.add(deviceId);
    });

    try {
      await FirebaseDatabase.instance
          .ref(
            "accounts/$ownerUid/homes/$homeId/devices/$deviceId/"
            "emergencyAcknowledgements/$uid",
          )
          .set(triggeredAt);

      if (!mounted) {
        return;
      }

      setState(() {
        _locallyAcknowledgedEmergencyTriggers.add(
          _emergencyAcknowledgementKey(deviceId, triggeredAt),
        );
      });
      _syncSirenAlertPulse();
    } catch (_) {
      if (!mounted) {
        return;
      }

      showTopToast(
        context,
        _emergencyAcknowledgeErrorText(strings),
        color: SafeHomeColors.danger,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() {
          _acknowledgingEmergencyDeviceIds.remove(deviceId);
        });
      }
    }
  }

  Widget _emergencyAcknowledgeAction({
    required String deviceId,
    required Map<String, dynamic> device,
    required bool compact,
    required AppStrings strings,
    required Color pulseColor,
  }) {
    final loading = _acknowledgingEmergencyDeviceIds.contains(deviceId);
    final label = _emergencyAcknowledgeLabel(strings);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: pulseColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: loading
                ? null
                : () => _acknowledgeEmergency(deviceId, device, strings),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: compact ? 14 : 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: loading
                    ? Center(
                        child: SizedBox(
                          width: compact ? 11 : 12,
                          height: compact ? 11 : 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: pulseColor,
                          ),
                        ),
                      )
                    : Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 9.0 : 9.5,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: pulseColor,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getDeviceGroup(String type) {
    switch (type) {
      case "door":
      case "window":
      case "gate":
      case "lock":
      case "door_lock":
      case "motion":
      case "presence":
      case "vibration":
      case "glass_break":
        return "An ninh ra/vào";

      case "smoke":
      case "heat":
      case "carbon_monoxide":
      case "gas":
      case "water_leak":
      case "flood":
      case "sos":
        return "Nguy hiểm khẩn cấp";

      case "smart_plug":
      case "power_monitor":
      case "ups":
      case "siren":
      case "smart_valve":
      case "doorbell":
      case "keypad":
      case "repeater":
      case "hub":
      case "unknown":
        return "Điều khiển & hạ tầng";

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
      case "presence":
        return Icons.sensors_rounded;
      case "vibration":
        return Icons.vibration_rounded;
      case "glass_break":
        return Icons.broken_image_rounded;
      case "smoke":
        return Icons.local_fire_department_rounded;
      case "heat":
        return Icons.thermostat_rounded;
      case "carbon_monoxide":
        return Icons.dangerous_rounded;
      case "gas":
        return Icons.gas_meter_rounded;
      case "water_leak":
      case "flood":
        return Icons.water_damage_rounded;
      case "sos":
        return Icons.sos_rounded;
      case "smart_plug":
        return Icons.power_rounded;
      case "power_monitor":
        return Icons.flash_on_rounded;
      case "ups":
        return Icons.battery_charging_full_rounded;
      case "siren":
        return Icons.notifications_active_rounded;
      case "smart_valve":
        return Icons.water_drop_rounded;
      case "doorbell":
        return Icons.notifications_rounded;
      case "keypad":
        return Icons.grid_3x3_rounded;
      case "repeater":
        return Icons.wifi_tethering_rounded;
      case "hub":
        return Icons.router_rounded;
      default:
        return Icons.sensors_off_rounded;
    }
  }

  String getMainStatus(Map<String, dynamic> d, AppStrings strings) {
    final type = d["type"]?.toString().trim().toLowerCase() ?? "unknown";

    if (parseDeviceBool(d["tamper"]) == true) {
      return strings.t("Bị tháo");
    }

    switch (type) {
      case "smoke":
        final active = isEmergencyStatusActiveForCurrentUser(
          d,
          legacyActive: isActiveDeviceSignal(d["smoke"]),
        );

        return active ? strings.t("Có khói") : strings.t("Bình thường");

      case "heat":
        final active = isEmergencyStatusActiveForCurrentUser(
          d,
          legacyActive:
              isActiveDeviceSignal(d["heat"]) ||
              isActiveDeviceSignal(d["heat_alarm"]) ||
              isActiveDeviceSignal(d["high_temperature_alarm"]),
        );

        return active
            ? strings.t("Nhiệt độ nguy hiểm")
            : strings.t("Bình thường");

      case "carbon_monoxide":
        final active = isEmergencyStatusActiveForCurrentUser(
          d,
          legacyActive:
              isActiveDeviceSignal(d["carbon_monoxide"]) ||
              isActiveDeviceSignal(d["co_alarm"]),
        );

        return active
            ? strings.t("Phát hiện khí CO")
            : strings.t("Không phát hiện khí CO");

      case "sos":
        return isSosActive(d)
            ? strings.t("Đã kích hoạt")
            : strings.t("Sẵn sàng");

      case "gas":
        final active = isEmergencyStatusActiveForCurrentUser(
          d,
          legacyActive:
              isActiveDeviceSignal(d["gas"]) ||
              isActiveDeviceSignal(d["gas_alarm"]),
        );

        return active ? strings.t("Rò rỉ gas") : strings.t("Bình thường");

      case "water_leak":
      case "flood":
        final active = isEmergencyStatusActiveForCurrentUser(
          d,
          legacyActive:
              isActiveDeviceSignal(d["water_leak"]) ||
              isActiveDeviceSignal(d["leak"]) ||
              isActiveDeviceSignal(d["water"]),
        );

        return active
            ? strings.t("Phát hiện ngập nước")
            : strings.t("Bình thường");

      case "motion":
        final active =
            isActiveDeviceSignal(d["occupancy"]) ||
            isActiveDeviceSignal(d["motion"]);

        return active
            ? strings.t("Phát hiện chuyển động")
            : strings.t("Không có chuyển động");

      case "presence":
        final active =
            isActiveDeviceSignal(d["presence"]) ||
            isActiveDeviceSignal(d["occupancy"]);

        return active
            ? strings.t("Phát hiện hiện diện")
            : strings.t("Không phát hiện hiện diện");

      case "vibration":
        final active = isVibrationEventActive(d);

        return active
            ? strings.t("Phát hiện rung/chấn động")
            : strings.t("Không có rung bất thường");

      case "glass_break":
        final active =
            isActiveDeviceSignal(d["glass_break"]) ||
            isActiveDeviceSignal(d["broken_glass"]) ||
            isRecentDeviceEvent(d);

        return active
            ? strings.t("Phát hiện kính vỡ")
            : strings.t("Không có cảnh báo kính vỡ");

      case "lock":
      case "door_lock":
        return normalizeDeviceLockState(d) == "unlocked"
            ? strings.t("Khóa đang mở")
            : strings.t("Khóa đang đóng");

      case "door":
      case "window":
      case "gate":
        final contact = parseDeviceBool(d["contact"]);
        final status = d["status"]?.toString().trim().toLowerCase() ?? "";

        return contact == true || status == "closed" || status == "locked"
            ? strings.t("Đang đóng")
            : strings.t("Đang mở");

      case "smart_plug":
        return normalizeDeviceSwitchState(d) == "on"
            ? strings.t("Đang bật")
            : strings.t("Đang tắt");

      case "power_monitor":
        return strings.t("Đang theo dõi điện năng");

      case "ups":
        final mainsPower = parseDeviceBool(
          d["mains_power"] ?? d["ac_connected"] ?? d["input_power"],
        );

        return mainsPower == false
            ? strings.t("Đang dùng nguồn dự phòng")
            : strings.t("Nguồn điện bình thường");

      case "siren":
        final active =
            isActiveDeviceSignal(d["alarm"]) ||
            normalizeDeviceSwitchState(d) == "on";

        return active ? strings.t("Còi đang bật") : strings.t("Còi sẵn sàng");

      case "smart_valve":
        return normalizeDeviceSwitchState(d) == "on"
            ? strings.t("Van đang mở")
            : strings.t("Van đã đóng");

      case "doorbell":
      case "keypad":
      case "repeater":
      case "hub":
        return strings.t("Đang hoạt động");

      default:
        return strings.t("Chưa nhận diện");
    }
  }

  String getTimeText(Map<String, dynamic> d, AppStrings strings) {
    final value = formatAgo(d["last_event"], strings);

    if (value == "--") {
      return strings.t("Chưa có cập nhật");
    }

    return strings.updatedAgoText(value);
  }

  Color getAccentColor(Map<String, dynamic> d) {
    final evaluation = evaluateDeviceStatus(d, securityMode: securityMode);

    final level = evaluation["level"]?.toString() ?? "safe";

    if (level == "emergency") {
      return SafeHomeColors.emergency;
    }

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

  Map<String, Map<String, int>> _copyDeviceOrderMap(
    Map<String, Map<String, int>> source,
  ) {
    return source.map(
      (sectionKey, sectionOrders) =>
          MapEntry(sectionKey, Map<String, int>.from(sectionOrders)),
    );
  }

  bool _sameDeviceOrder(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) {
      return false;
    }

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  Map<String, int> _effectiveSectionOrders(String sectionKey) {
    return <String, int>{
      ...?_deviceOrderMap[sectionKey],
      ...?_localDeviceOrderMap[sectionKey],
      ...?_optimisticDeviceOrderMap[sectionKey],
    };
  }

  String _sectionKeyForGroup(String groupName) {
    switch (groupName) {
      case "An ninh ra/vào":
        return "access";
      case "Nguy hiểm khẩn cấp":
        return "emergency";
      case "Điều khiển & hạ tầng":
        return "infrastructure";
      case "Môi trường":
        return "environment";
      default:
        return "other";
    }
  }

  int _deviceOrderOf(String sectionKey, String deviceId, int fallbackIndex) {
    return _effectiveSectionOrders(sectionKey)[deviceId] ??
        (1000000 + fallbackIndex);
  }

  String _deviceSortName(MapEntry<String, dynamic> entry) {
    final d = safeMap(entry.value);
    final name = d["name"]?.toString().trim() ?? "";

    return name.isNotEmpty ? name.toLowerCase() : entry.key.toLowerCase();
  }

  void _sortDeviceEntries(
    String sectionKey,
    List<MapEntry<String, dynamic>> entries,
  ) {
    final fallbackIndexes = <String, int>{};
    final sectionOrders = _effectiveSectionOrders(sectionKey);

    for (var i = 0; i < entries.length; i++) {
      fallbackIndexes[entries[i].key] = i;
    }

    entries.sort((a, b) {
      final aOrder = sectionOrders[a.key];
      final bOrder = sectionOrders[b.key];

      if (aOrder != null || bOrder != null) {
        final orderCompare =
            _deviceOrderOf(
              sectionKey,
              a.key,
              fallbackIndexes[a.key] ?? 0,
            ).compareTo(
              _deviceOrderOf(sectionKey, b.key, fallbackIndexes[b.key] ?? 0),
            );

        if (orderCompare != 0) {
          return orderCompare;
        }
      }

      final nameCompare = _deviceSortName(a).compareTo(_deviceSortName(b));

      if (nameCompare != 0) {
        return nameCompare;
      }

      return a.key.compareTo(b.key);
    });
  }

  bool get _canReorderDevices => _currentUid.isNotEmpty && _homeId.isNotEmpty;

  String _deviceOrderPath(String sectionKey, String deviceId) {
    return "accounts/$_currentUid/$_deviceOrderRoot/$_homeId/$sectionKey/$deviceId";
  }

  GlobalKey _sectionGridKey(String sectionKey) {
    return _sectionGridKeys.putIfAbsent(
      sectionKey,
      () => GlobalKey(debugLabel: "device_grid_$sectionKey"),
    );
  }

  void _clearDeviceDragState() {
    _deviceDropTimer?.cancel();
    _deviceDropTimer = null;
    _draggingDeviceId = null;
    _draggingSectionKey = null;
    _draggingSectionOrder = null;
    _draggingCardOffset = Offset.zero;
    _draggingPointerOffset = Offset.zero;
    _draggingDeviceDropping = false;
  }

  double _deviceGridItemHeight(
    bool compact,
    List<MapEntry<String, dynamic>> entries,
    AppStrings strings,
  ) {
    // Font Myanmar có phần glyph cao hơn một chút. Chừa riêng 1 px để
    // tránh RenderFlex overflow 0.x px mà không làm thay đổi UI ngôn ngữ khác.
    final localeHeightExtra = strings.isBurmese ? 1.0 : 0.0;

    final hasActiveSiren = entries.any((entry) {
      final device = safeMap(entry.value);
      final type = device["type"]?.toString() ?? "";

      return type == "siren" &&
          (isActiveDeviceSignal(device["alarm"]) ||
              normalizeDeviceSwitchState(device) == "on");
    });
    if (hasActiveSiren) {
      return (compact ? 106.0 : 114.0) + localeHeightExtra;
    }

    // Nút xác nhận thay thế đúng vùng trạng thái phía dưới, không được
    // làm thay đổi chiều cao của ô thiết bị khi xuất hiện hoặc biến mất.
    // Giữ card gọn như layout cũ nhưng chừa dư rất nhẹ
    // để Column bên trong không bị overflow 0.x pixels.
    return (compact ? 70.0 : 75.0) + localeHeightExtra;
  }

  Offset _deviceGridOffsetForIndex({
    required int index,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
  }) {
    return Offset(
      (index % 2) * (itemWidth + spacing),
      (index ~/ 2) * (itemHeight + spacing),
    );
  }

  int _nearestDeviceGridIndex({
    required Offset pointer,
    required int itemCount,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
  }) {
    if (itemCount <= 1) {
      return 0;
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;

    for (var i = 0; i < itemCount; i++) {
      final topLeft = _deviceGridOffsetForIndex(
        index: i,
        itemWidth: itemWidth,
        itemHeight: itemHeight,
        spacing: spacing,
      );

      final center = topLeft + Offset(itemWidth / 2, itemHeight / 2);
      final distance = (center - pointer).distance;

      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  List<MapEntry<String, dynamic>> _dragPreviewEntries(
    String sectionKey,
    List<MapEntry<String, dynamic>> entries,
  ) {
    final dragOrder = _draggingSectionOrder;

    if (_draggingSectionKey != sectionKey || dragOrder == null) {
      return entries;
    }

    final byId = {for (final entry in entries) entry.key: entry};

    final ordered = <MapEntry<String, dynamic>>[];

    for (final id in dragOrder) {
      final entry = byId.remove(id);

      if (entry != null) {
        ordered.add(entry);
      }
    }

    ordered.addAll(byId.values);
    return ordered;
  }

  void _startDeviceDrag({
    required String sectionKey,
    required List<MapEntry<String, dynamic>> entries,
    required String deviceId,
    required int index,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
    required LongPressStartDetails details,
  }) {
    if (!_canReorderDevices || entries.length <= 1) {
      return;
    }

    final gridKey = _sectionGridKey(sectionKey);
    final renderObject = gridKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final pointer = renderObject.globalToLocal(details.globalPosition);
    final itemOffset = _deviceGridOffsetForIndex(
      index: index,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      spacing: spacing,
    );

    _deviceDropTimer?.cancel();
    _deviceDropTimer = null;

    setState(() {
      _draggingSectionKey = sectionKey;
      _draggingDeviceId = deviceId;
      _draggingSectionOrder = entries.map((entry) => entry.key).toList();
      _draggingPointerOffset = pointer - itemOffset;
      _draggingCardOffset = itemOffset;
      _draggingDeviceDropping = false;
    });
  }

  void _updateDeviceDrag({
    required String sectionKey,
    required int itemCount,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
    required LongPressMoveUpdateDetails details,
  }) {
    final draggingDeviceId = _draggingDeviceId;
    final dragOrder = _draggingSectionOrder;

    if (draggingDeviceId == null ||
        dragOrder == null ||
        _draggingSectionKey != sectionKey ||
        _draggingDeviceDropping) {
      return;
    }

    final gridKey = _sectionGridKey(sectionKey);
    final renderObject = gridKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final pointer = renderObject.globalToLocal(details.globalPosition);
    final cardOffset = pointer - _draggingPointerOffset;
    final targetIndex = _nearestDeviceGridIndex(
      pointer: pointer,
      itemCount: itemCount,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      spacing: spacing,
    );

    final nextOrder = List<String>.from(dragOrder);
    nextOrder.remove(draggingDeviceId);

    final insertIndex = targetIndex.clamp(0, nextOrder.length);
    nextOrder.insert(insertIndex, draggingDeviceId);

    if (_sameStringList(nextOrder, dragOrder) &&
        (cardOffset - _draggingCardOffset).distance < 0.5) {
      return;
    }

    setState(() {
      _draggingCardOffset = cardOffset;
      _draggingSectionOrder = nextOrder;
    });
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  Future<void> _finishDeviceDrag(
    String sectionKey, {
    required double itemWidth,
    required double itemHeight,
    required double spacing,
  }) async {
    final finalOrder = _draggingSectionOrder;
    final draggingDeviceId = _draggingDeviceId;
    final draggingSectionKey = _draggingSectionKey;

    if (finalOrder == null ||
        draggingDeviceId == null ||
        draggingSectionKey != sectionKey) {
      if (mounted) {
        setState(_clearDeviceDragState);
      }

      return;
    }

    final finalIndex = finalOrder.indexOf(draggingDeviceId);
    final finalOffset = finalIndex < 0
        ? _draggingCardOffset
        : _deviceGridOffsetForIndex(
            index: finalIndex,
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            spacing: spacing,
          );

    final updatedOptimisticOrder = _copyDeviceOrderMap(
      _optimisticDeviceOrderMap,
    );
    final updatedLocalOrder = _copyDeviceOrderMap(_localDeviceOrderMap);
    final sectionOrder = Map<String, int>.from(
      _effectiveSectionOrders(sectionKey),
    );

    for (var i = 0; i < finalOrder.length; i++) {
      sectionOrder[finalOrder[i]] = i * 10;
    }

    updatedOptimisticOrder[sectionKey] = sectionOrder;
    updatedLocalOrder[sectionKey] = sectionOrder;

    if (mounted) {
      setState(() {
        _optimisticDeviceOrderMap = updatedOptimisticOrder;
        _localDeviceOrderMap = updatedLocalOrder;
        _draggingCardOffset = finalOffset;
        _draggingDeviceDropping = true;
      });

      _deviceDropTimer?.cancel();
      _deviceDropTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted ||
            _draggingDeviceId != draggingDeviceId ||
            _draggingSectionKey != sectionKey) {
          return;
        }

        setState(_clearDeviceDragState);
      });
    }

    unawaited(
      _saveLocalDeviceOrder(
        uid: _currentUid,
        homeId: _homeId,
        orderMap: updatedLocalOrder,
      ),
    );

    final updates = <String, Object?>{};

    for (var i = 0; i < finalOrder.length; i++) {
      updates[_deviceOrderPath(sectionKey, finalOrder[i])] = i * 10;
    }

    try {
      await FirebaseDatabase.instance.ref().update(updates);
    } catch (_) {
      // Nếu Firebase Rules chưa mở deviceOrder, thứ tự vẫn được giữ local
      // trên máy này bằng SharedPreferences.
    }
  }

  void _cancelDeviceDrag() {
    if (!mounted) {
      return;
    }

    setState(_clearDeviceDragState);
  }

  List<MapEntry<String, dynamic>> _groupEntries(String groupName) {
    final sectionKey = _sectionKeyForGroup(groupName);
    final entries = devices.entries.where((entry) {
      final d = safeMap(entry.value);
      final type = d["type"]?.toString() ?? "door";

      if (getDeviceGroup(type) != groupName) {
        return false;
      }

      if (selectedRoomId == "overview") {
        return true;
      }

      final roomId = d["roomId"]?.toString() ?? "unassigned";

      return roomId == selectedRoomId;
    }).toList();

    _sortDeviceEntries(sectionKey, entries);

    return entries;
  }

  Future<void> _confirmMuteHomeSiren(AppStrings strings) async {
    if (_mutingHomeSiren || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.confirmStopSirenTitle()),
          content: Text(strings.confirmStopSirenBody()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.t("HỦY")),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.volume_off_rounded),
              label: Text(strings.stopSirenLabel()),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _mutingHomeSiren = true;
    });

    final muted = await NotificationService.muteHomeSiren(
      homeId: _homeId,
      hubId: _hubId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _mutingHomeSiren = false;
    });

    if (muted) {
      showTopToast(
        context,
        strings.homeSirenMutedMessage(),
        color: SafeHomeColors.safe,
        icon: Icons.volume_off_rounded,
      );
      return;
    }

    showTopToast(
      context,
      strings.sirenStopUnavailableMessage(),
      color: SafeHomeColors.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  Widget _sirenStopAction({
    required bool compact,
    required AppStrings strings,
  }) {
    final label = _sirenStopButtonText(strings);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: SafeHomeColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _mutingHomeSiren
                ? null
                : () => _confirmMuteHomeSiren(strings),
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: compact ? 18 : 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_mutingHomeSiren)
                      SizedBox(
                        width: compact ? 11 : 12,
                        height: compact ? 11 : 12,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.7,
                        ),
                      )
                    else
                      Icon(
                        Icons.volume_off_rounded,
                        size: compact ? 12 : 13,
                        color: SafeHomeColors.danger,
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: compact ? 9.0 : 9.5,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: SafeHomeColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sirenStopButtonText(AppStrings strings) {
    return strings.choose(
      vi: "TẮT CÒI BÁO ĐỘNG",
      en: "STOP ALARM SIREN",
      zh: "关闭警报器",
      ko: "경보 사이렌 끄기",
      ja: "警報サイレン停止",
      de: "ALARMSIRENE STOPPEN",
      ru: "ВЫКЛЮЧИТЬ СИРЕНУ",
      fr: "ARRÊTER LA SIRÈNE",
      es: "DETENER LA SIRENA",
      id: "MATIKAN SIRENE ALARM",
      th: "ปิดไซเรนเตือนภัย",
      ms: "HENTIKAN SIREN PENGGERA",
      fil: "PATAYIN ANG ALARM SIREN",
      km: "បិទស៊ីរ៉ែនរោទិ៍",
      my: "အချက်ပေးဥဩ ပိတ်ရန်",
      lo: "ຢຸດສຽງໄຊເຣນສັນຍານເຕືອນໄພ",
      ta: "அலாரம் சைரனை நிறுத்து",
      pt: "PARAR SIRENE DO ALARME",
      tet: "PARA SIRENE ALARME",
    );
  }

  Widget _crossedAlarmPolicyIcon({
    required IconData icon,
    required double size,
    required Color color,
  }) {
    return SizedBox(
      width: size + 3,
      height: size + 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size, color: color),
          Transform.rotate(
            angle: -0.78,
            child: Container(
              width: size + 2,
              height: 1.8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 0.6,
                    spreadRadius: 0.3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _deviceAlarmPolicyIndicator({
    required String deviceId,
    required Map<String, dynamic> device,
    required bool compact,
  }) {
    final deviceType =
        device["type"]?.toString().trim().toLowerCase() ?? "unknown";

    if (!supportsDeviceAlarmPolicy(deviceType)) {
      return null;
    }

    final settings = DeviceAlarmPolicySettings.fromDevice(
      device: device,
      deviceType: deviceType,
    );
    final realDeviceId =
        device["_deviceId"]?.toString().trim().isNotEmpty == true
        ? device["_deviceId"].toString().trim()
        : deviceId;
    final personalFullscreenEnabled = resolvePersonalFullscreenEnabled(
      customRules: widget.personalAlarmRules,
      deviceId: realDeviceId,
      fallback: settings.fullscreenEnabled,
    );
    final iconSize = compact ? 15.0 : 16.0;

    if (!settings.enabled) {
      return Icon(
        Icons.shield_outlined,
        size: iconSize,
        color: SafeHomeColors.textSecondary.withValues(alpha: 0.72),
      );
    }

    if (settings.physicalSirenEnabled && personalFullscreenEnabled) {
      return Icon(
        Icons.shield_rounded,
        size: iconSize,
        color: SafeHomeColors.safe,
      );
    }

    if (!settings.physicalSirenEnabled && !personalFullscreenEnabled) {
      // Chỉ còn cảnh báo thông thường trong ứng dụng: dùng biểu tượng
      // thông báo dạng tin nhắn để không bị nhầm với còi vật lý.
      return Icon(
        Icons.sms_outlined,
        size: iconSize,
        color: SafeHomeColors.info,
      );
    }

    if (!settings.physicalSirenEnabled) {
      return _crossedAlarmPolicyIcon(
        icon: Icons.campaign_rounded,
        size: iconSize,
        color: SafeHomeColors.warning,
      );
    }

    return _crossedAlarmPolicyIcon(
      icon: Icons.smartphone_rounded,
      size: iconSize,
      color: SafeHomeColors.warning,
    );
  }

  Widget _deviceCard({
    required String id,
    required Map<String, dynamic> d,
    required bool compact,
    required AppStrings strings,
  }) {
    final type = d["type"]?.toString() ?? "door";
    final sirenIsOn = type == "siren" && _isSirenActive(d);
    final connectionStatus = getConnectionStatus(d);
    final connectionColor = getConnectionColor(connectionStatus);
    final connectionDescription = getConnectionDescription(
      d,
      connectionStatus,
      strings,
    );
    final accentColor = getAccentColor(d);
    final alarmPolicyIndicator = _deviceAlarmPolicyIndicator(
      deviceId: id,
      device: d,
      compact: compact,
    );
    final trailingIndicatorColumnWidth = compact ? 18.0 : 20.0;
    final showEmergencyAcknowledge = _isEmergencyAwaitingAcknowledgement(id, d);
    final emergencyIsActive = _isEmergencyDeviceActiveForUi(id, d);
    final emergencyPulseColor = _sirenAlertPulseDanger
        ? SafeHomeColors.danger
        : SafeHomeColors.warning;

    final baseCardStatusColor =
        accentColor == SafeHomeColors.danger || connectionStatus == "off"
        ? SafeHomeColors.danger
        : connectionStatus == "warn"
        ? SafeHomeColors.warning
        : accentColor;
    final cardStatusColor = emergencyIsActive
        ? emergencyPulseColor
        : baseCardStatusColor;
    final effectiveAccentColor = emergencyIsActive
        ? emergencyPulseColor
        : accentColor;
    final cardBackgroundColor = emergencyIsActive
        ? emergencyPulseColor.withValues(
            alpha: _sirenAlertPulseDanger ? 0.20 : 0.15,
          )
        : SafeHomeColors.surface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => onTapDevice(id),
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          padding: EdgeInsets.fromLTRB(
            compact ? 9 : 10,
            compact ? 8 : 9,
            compact ? 9 : 10,
            compact ? 8 : 9,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: cardStatusColor.withValues(
                alpha: emergencyIsActive ? 0.95 : 0.62,
              ),
              width: emergencyIsActive ? 1.5 : 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: cardStatusColor.withValues(
                  alpha: emergencyIsActive ? 0.20 : 0.055,
                ),
                blurRadius: emergencyIsActive ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeInOut,
                        width: compact ? 34 : 36,
                        height: compact ? 34 : 36,
                        decoration: BoxDecoration(
                          color: emergencyIsActive
                              ? effectiveAccentColor.withValues(alpha: 0.20)
                              : getIconBackground(d),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getDeviceIcon(type),
                          size: compact ? 18 : 19,
                          color: effectiveAccentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                fontSize: compact ? 13.8 : 14.5,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: emergencyIsActive
                                    ? effectiveAccentColor
                                    : SafeHomeColors.textPrimary,
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
                                color: effectiveAccentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (alarmPolicyIndicator != null) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: trailingIndicatorColumnWidth,
                          height: compact ? 34 : 36,
                          child: Transform.translate(
                            offset: const Offset(2, 0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: alarmPolicyIndicator,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Giữ nguyên tổng chiều cao của card: giảm khoảng cách 1 px và
              // chuyển 1 px đó cho dòng cuối để font tiếng Việt/Myanmar không
              // bị cắt chân chữ.
              SizedBox(height: compact ? 3 : 4),
              SizedBox(
                height: compact ? 15 : 17,
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    reverseDuration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                        reverseCurve: Curves.easeInCubic,
                      );

                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.18),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: showEmergencyAcknowledge
                        ? KeyedSubtree(
                            key: ValueKey<String>(
                              "emergency-ack-$id-${_emergencyTriggeredAt(d)}",
                            ),
                            child: _emergencyAcknowledgeAction(
                              deviceId: id,
                              device: d,
                              compact: compact,
                              strings: strings,
                              pulseColor: emergencyPulseColor,
                            ),
                          )
                        : Center(
                            key: ValueKey<String>("device-time-$id"),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    getTimeText(d, strings),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    textHeightBehavior:
                                        const TextHeightBehavior(
                                          applyHeightToFirstAscent: true,
                                          applyHeightToLastDescent: true,
                                        ),
                                    style: TextStyle(
                                      fontSize: compact ? 9.8 : 10.4,
                                      height: 1.10,
                                      fontWeight: FontWeight.w500,
                                      color: SafeHomeColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: trailingIndicatorColumnWidth,
                                  child: Transform.translate(
                                    offset: const Offset(2, 0),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Tooltip(
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
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              if (sirenIsOn) ...[
                const SizedBox(height: 6),
                _sirenStopAction(compact: compact, strings: strings),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _infrastructureDeviceNeedsAttention(Map<String, dynamic> device) {
    final connectionStatus = getConnectionStatus(device);

    if (connectionStatus != "on") {
      return true;
    }

    final evaluation = evaluateDeviceStatus(device, securityMode: securityMode);

    return evaluation["level"]?.toString() == "warning" ||
        evaluation["level"]?.toString() == "danger";
  }

  String _infrastructureStatusSummary(
    List<MapEntry<String, dynamic>> entries,
    AppStrings strings,
  ) {
    final statuses = <String>[];

    for (final entry in entries) {
      final status = getMainStatus(safeMap(entry.value), strings).trim();

      if (status.isNotEmpty && !statuses.contains(status)) {
        statuses.add(status);
      }
    }

    final visibleStatuses = statuses.take(2).toList();
    var summary = visibleStatuses.isEmpty
        ? strings.t("Đang hoạt động")
        : visibleStatuses.join(" • ");

    if (statuses.length > visibleStatuses.length) {
      summary = "$summary • …";
    }

    return "$summary (${entries.length})";
  }

  String _infrastructureTypeKey(Map<String, dynamic> device) {
    final type = device["type"]?.toString().trim().toLowerCase() ?? "unknown";

    switch (type) {
      case "smart_plug":
      case "power_monitor":
      case "ups":
      case "siren":
      case "smart_valve":
      case "doorbell":
      case "keypad":
      case "repeater":
      case "hub":
        return type;
      default:
        return "unknown";
    }
  }

  String _infrastructureTypeTitle(String type, AppStrings strings) {
    switch (type) {
      case "smart_plug":
        return strings.t("Ổ điện thông minh");
      case "power_monitor":
        return strings.t("Đo điện năng");
      case "ups":
        return strings.t("Nguồn dự phòng UPS");
      case "siren":
        return strings.t("Còi báo động");
      case "smart_valve":
        return strings.t("Van thông minh");
      case "doorbell":
        return strings.t("Chuông cửa");
      case "keypad":
        return strings.t("Bàn phím an ninh");
      case "repeater":
        return strings.t("Bộ mở rộng sóng");
      case "hub":
        return strings.t("Hub trung tâm");
      default:
        return strings.choose(
          vi: "Thiết bị khác",
          en: "Other devices",
          zh: "其他设备",
          ko: "기타 기기",
          ja: "その他のデバイス",
          de: "Andere Geräte",
          ru: "Другие устройства",
          fr: "Autres appareils",
          es: "Otros dispositivos",
          id: "Perangkat lainnya",
          th: "อุปกรณ์อื่นๆ",
          ms: "Peranti lain",
          fil: "Iba pang device",
          km: "ឧបករណ៍ផ្សេងទៀត",
          my: "အခြားစက်များ",
          lo: "ອຸປະກອນອື່ນ",
          ta: "மற்ற சாதனங்கள்",
          pt: "Outros dispositivos",
          tet: "Dispozitivu seluk",
        );
    }
  }

  List<MapEntry<String, List<MapEntry<String, dynamic>>>>
  _groupInfrastructureEntriesByType(List<MapEntry<String, dynamic>> entries) {
    final groups = <String, List<MapEntry<String, dynamic>>>{};

    for (final entry in entries) {
      final type = _infrastructureTypeKey(safeMap(entry.value));
      groups.putIfAbsent(type, () => <MapEntry<String, dynamic>>[]).add(entry);
    }

    const preferredOrder = <String>[
      "repeater",
      "siren",
      "hub",
      "ups",
      "smart_plug",
      "power_monitor",
      "smart_valve",
      "doorbell",
      "keypad",
      "unknown",
    ];

    final result = <MapEntry<String, List<MapEntry<String, dynamic>>>>[];

    for (final type in preferredOrder) {
      final typeEntries = groups.remove(type);

      if (typeEntries != null && typeEntries.isNotEmpty) {
        result.add(MapEntry(type, typeEntries));
      }
    }

    for (final entry in groups.entries) {
      if (entry.value.isNotEmpty) {
        result.add(entry);
      }
    }

    return result;
  }

  String _infrastructureSignalGrade(List<MapEntry<String, dynamic>> entries) {
    int? weakest;

    for (final entry in entries) {
      final device = safeMap(entry.value);
      final value = int.tryParse(device["linkquality"]?.toString() ?? "");

      if (value == null || value <= 0) {
        continue;
      }

      weakest = weakest == null || value < weakest ? value : weakest;
    }

    if (weakest != null && weakest < 40) {
      return "weak";
    }

    if (weakest != null && weakest >= 100) {
      return "good";
    }

    return "normal";
  }

  String _infrastructureSignalText(
    List<MapEntry<String, dynamic>> entries,
    AppStrings strings,
  ) {
    final grade = _infrastructureSignalGrade(entries);
    final count = entries.length;

    final text = switch (grade) {
      "good" => strings.choose(
        vi: "Tín hiệu tốt",
        en: "Good signal",
        zh: "信号良好",
        ko: "신호 좋음",
        ja: "信号良好",
        de: "Gutes Signal",
        ru: "Хороший сигнал",
        fr: "Bon signal",
        es: "Señal buena",
        id: "Sinyal baik",
        th: "สัญญาณดี",
        ms: "Isyarat baik",
        fil: "Magandang signal",
        km: "សញ្ញាល្អ",
        my: "အချက်ပြကောင်း",
        lo: "ສັນຍານດີ",
        ta: "சிக்னல் நன்றாக உள்ளது",
        pt: "Sinal bom",
        tet: "Sinal di'ak",
      ),
      "weak" => strings.choose(
        vi: "Tín hiệu yếu",
        en: "Weak signal",
        zh: "信号较弱",
        ko: "신호 약함",
        ja: "信号が弱い",
        de: "Schwaches Signal",
        ru: "Слабый сигнал",
        fr: "Signal faible",
        es: "Señal débil",
        id: "Sinyal lemah",
        th: "สัญญาณอ่อน",
        ms: "Isyarat lemah",
        fil: "Mahinang signal",
        km: "សញ្ញាខ្សោយ",
        my: "အချက်ပြအားနည်း",
        lo: "ສັນຍານອ່ອນ",
        ta: "சிக்னல் பலவீனமாக உள்ளது",
        pt: "Sinal fraco",
        tet: "Sinal fraku",
      ),
      _ => strings.choose(
        vi: "Tín hiệu trung bình",
        en: "Average signal",
        zh: "信号一般",
        ko: "신호 보통",
        ja: "信号は普通",
        de: "Mittleres Signal",
        ru: "Средний сигнал",
        fr: "Signal moyen",
        es: "Señal media",
        id: "Sinyal sedang",
        th: "สัญญาณปานกลาง",
        ms: "Isyarat sederhana",
        fil: "Katamtamang signal",
        km: "សញ្ញាមធ្យម",
        my: "အချက်ပြအသင့်အတင့်",
        lo: "ສັນຍານປານກາງ",
        ta: "சிக்னல் நடுத்தரமாக உள்ளது",
        pt: "Sinal médio",
        tet: "Sinal moderadu",
      ),
    };

    return "$text ($count)";
  }

  Color _infrastructureSignalColor(List<MapEntry<String, dynamic>> entries) {
    switch (_infrastructureSignalGrade(entries)) {
      case "good":
        return SafeHomeColors.safe;
      case "weak":
        return SafeHomeColors.warning;
      default:
        return SafeHomeColors.textSecondary;
    }
  }

  String _sirenReadinessText({
    required bool hasAttention,
    required int count,
    required AppStrings strings,
  }) {
    final text = hasAttention
        ? strings.choose(
            vi: "Còi cần kiểm tra",
            en: "Siren needs attention",
            zh: "警报器需要检查",
            ko: "사이렌 점검 필요",
            ja: "サイレンの確認が必要",
            de: "Sirene prüfen",
            ru: "Сирена требует проверки",
            fr: "Sirène à vérifier",
            es: "Sirena por revisar",
            id: "Sirene perlu diperiksa",
            th: "ควรตรวจสอบไซเรน",
            ms: "Siren perlu diperiksa",
            fil: "Kailangang suriin ang sirena",
            km: "ត្រូវពិនិត្យស៊ីរ៉ែន",
            my: "ဆိုင်ရင်ကို စစ်ဆေးရန်လိုသည်",
            lo: "ສຽງໄຊເຣນຕ້ອງການກວດສອບ",
            ta: "சைரன் சரிபார்க்கப்பட வேண்டும்",
            pt: "A sirene precisa ser verificada",
            tet: "Sirene presiza verifikasaun",
          )
        : strings.choose(
            vi: "Còi đang sẵn sàng",
            en: "Siren ready",
            zh: "警报器已就绪",
            ko: "사이렌 준비됨",
            ja: "サイレン準備完了",
            de: "Sirene bereit",
            ru: "Сирена готова",
            fr: "Sirène prête",
            es: "Sirena lista",
            id: "Sirene siap",
            th: "ไซเรนพร้อมใช้งาน",
            ms: "Siren sedia",
            fil: "Handa ang sirena",
            km: "ស៊ីរ៉ែនរួចរាល់",
            my: "ဆိုင်ရင် အသင့်ဖြစ်နေသည်",
            lo: "ສຽງໄຊເຣນພ້ອມໃຊ້ງານ",
            ta: "சைரன் தயாராக உள்ளது",
            pt: "Sirene pronta",
            tet: "Sirene prontu",
          );

    return "$text ($count)";
  }

  String _sirenOperatingStatusText(
    bool sirenIsOn,
    int sirenCount,
    AppStrings strings,
  ) {
    if (sirenIsOn) {
      return _sirenAlertStatusText(strings);
    }

    final text = strings.choose(
      vi: "Còi đang tắt",
      en: "Siren off",
      zh: "警报器已关闭",
      ko: "사이렌 꺼짐",
      ja: "サイレン停止中",
      de: "Sirene aus",
      ru: "Сирена выключена",
      fr: "Sirène arrêtée",
      es: "Sirena apagada",
      id: "Sirene mati",
      th: "ไซเรนปิดอยู่",
      ms: "Siren dimatikan",
      fil: "Naka-off ang sirena",
      km: "ស៊ីរ៉ែនបានបិទ",
      my: "ဆိုင်ရင် ပိတ်ထားသည်",
      lo: "ສຽງໄຊເຣນປິດຢູ່",
      ta: "சைரன் அணைக்கப்பட்டுள்ளது",
      pt: "Sirene desligada",
      tet: "Sirene mate",
    );

    return "$text ($sirenCount)";
  }

  Widget _infrastructureTypeGroupCard({
    required String type,
    required List<MapEntry<String, dynamic>> entries,
    required double itemWidth,
    required bool compact,
    required AppStrings strings,
  }) {
    final isSirenGroup = type == "siren";
    final sirenIsOn =
        isSirenGroup &&
        entries.any((entry) => _isSirenActive(safeMap(entry.value)));
    final hasAttention = entries.any(
      (entry) => _infrastructureDeviceNeedsAttention(safeMap(entry.value)),
    );
    final sirenHasReadinessIssue =
        isSirenGroup &&
        entries.any(
          (entry) => getConnectionStatus(safeMap(entry.value)) != "on",
        );
    final pulseColor = _sirenAlertPulseDanger
        ? SafeHomeColors.danger
        : SafeHomeColors.warning;
    final accentColor = sirenIsOn
        ? pulseColor
        : hasAttention
        ? SafeHomeColors.warning
        : SafeHomeColors.safe;
    final cardColor = sirenIsOn
        ? pulseColor.withValues(alpha: _sirenAlertPulseDanger ? 0.20 : 0.15)
        : SafeHomeColors.surface;
    final firstDevice = safeMap(entries.first.value);
    final primaryStatusText = isSirenGroup
        ? _sirenReadinessText(
            hasAttention: sirenHasReadinessIssue,
            count: entries.length,
            strings: strings,
          )
        : _infrastructureStatusSummary(entries, strings);
    final secondaryStatusText = isSirenGroup
        ? _sirenOperatingStatusText(sirenIsOn, entries.length, strings)
        : _infrastructureSignalText(entries, strings);
    final secondaryStatusColor = isSirenGroup
        ? sirenIsOn
              ? accentColor
              : SafeHomeColors.textSecondary
        : _infrastructureSignalColor(entries);

    void openGroup() {
      final groupDevices = <String, dynamic>{
        for (final entry in entries) entry.key: entry.value,
      };

      if (widget.onTapInfrastructureGroup != null) {
        widget.onTapInfrastructureGroup!(groupDevices);
        return;
      }

      onTapDevice(entries.first.key);
    }

    return SizedBox(
      width: itemWidth,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          height: compact ? 77 : 82,
          padding: EdgeInsets.fromLTRB(
            compact ? 9 : 10,
            compact ? 8 : 9,
            compact ? 9 : 10,
            compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: accentColor.withValues(alpha: sirenIsOn ? 0.95 : 0.62),
              width: sirenIsOn ? 1.5 : 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: sirenIsOn ? 0.20 : 0.055),
                blurRadius: sirenIsOn ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: InkWell(
                  onTap: openGroup,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeInOut,
                        width: compact ? 34 : 36,
                        height: compact ? 34 : 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: sirenIsOn ? 0.20 : 0.11,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getDeviceIcon(
                            type == "unknown"
                                ? _infrastructureTypeKey(firstDevice)
                                : type,
                          ),
                          size: compact ? 18 : 19,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _infrastructureTypeTitle(type, strings),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 13.8 : 14.5,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: sirenIsOn
                                    ? accentColor
                                    : SafeHomeColors.textPrimary,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              primaryStatusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 11.2 : 11.8,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: compact ? 18 : 20,
                child: sirenIsOn
                    ? _sirenStopAction(compact: compact, strings: strings)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          secondaryStatusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 9.8 : 10.4,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            color: secondaryStatusColor,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infrastructureTypeGrid({
    required List<MapEntry<String, List<MapEntry<String, dynamic>>>> groups,
    required double spacing,
    required double itemWidth,
    required bool compact,
    required AppStrings strings,
  }) {
    final rows = <Widget>[];

    for (var index = 0; index < groups.length; index += 2) {
      final firstGroup = groups[index];
      final hasSecondGroup = index + 1 < groups.length;
      final secondGroup = hasSecondGroup ? groups[index + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _infrastructureTypeGroupCard(
                type: firstGroup.key,
                entries: firstGroup.value,
                itemWidth: itemWidth,
                compact: compact,
                strings: strings,
              ),
              if (hasSecondGroup) ...[
                SizedBox(width: spacing),
                _infrastructureTypeGroupCard(
                  type: secondGroup!.key,
                  entries: secondGroup.value,
                  itemWidth: itemWidth,
                  compact: compact,
                  strings: strings,
                ),
              ],
            ],
          ),
        ),
      );

      if (index + 2 < groups.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  String _sirenAlertStatusText(AppStrings strings) {
    return strings.choose(
      vi: "Đang báo động",
      en: "Alarm active",
      zh: "警报正在响起",
      ko: "경보 작동 중",
      ja: "警報作動中",
      de: "Alarm aktiv",
      ru: "Тревога активна",
      fr: "Alarme active",
      es: "Alarma activa",
      id: "Alarm aktif",
      th: "สัญญาณเตือนทำงาน",
      ms: "Penggera aktif",
      fil: "Aktibo ang alarma",
      km: "សំឡេងរោទិ៍កំពុងដំណើរការ",
      my: "အချက်ပေးသံ လုပ်ဆောင်နေသည်",
      lo: "ສັນຍານເຕືອນໄພກຳລັງເຮັດວຽກ",
      ta: "அலாரம் செயல்பாட்டில் உள்ளது",
      pt: "Alarme ativo",
      tet: "Alarme ativu",
    );
  }

  Widget _deviceGridItem({
    required String sectionKey,
    required MapEntry<String, dynamic> entry,
    required double itemWidth,
    required bool compact,
    required AppStrings strings,
  }) {
    return SizedBox(
      width: itemWidth,
      child: _deviceCard(
        id: entry.key,
        d: safeMap(entry.value),
        compact: compact,
        strings: strings,
      ),
    );
  }

  Widget _animatedPositionedDeviceCard({
    required String sectionKey,
    required MapEntry<String, dynamic> entry,
    required int index,
    required double itemWidth,
    required double itemHeight,
    required double spacing,
    required bool compact,
    required AppStrings strings,
    required List<MapEntry<String, dynamic>> sourceEntries,
  }) {
    final deviceId = entry.key;
    final isDragging =
        _draggingSectionKey == sectionKey && _draggingDeviceId == deviceId;
    final safeIndex = index < 0 ? 0 : index;
    final isSectionDragging =
        _draggingSectionKey == sectionKey && _draggingDeviceId != null;
    final targetOffset = isDragging
        ? _draggingCardOffset
        : _deviceGridOffsetForIndex(
            index: safeIndex,
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            spacing: spacing,
          );

    final card = SizedBox(
      width: itemWidth,
      height: itemHeight,
      child: _deviceGridItem(
        sectionKey: sectionKey,
        entry: entry,
        itemWidth: itemWidth,
        compact: compact,
        strings: strings,
      ),
    );

    final wrappedCard = isDragging
        ? Transform.scale(
            scale: _draggingDeviceDropping ? 1.0 : 1.012,
            child: Material(
              color: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: _draggingDeviceDropping ? 0 : 7,
              shadowColor: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(17),
              child: card,
            ),
          )
        : card;

    return AnimatedPositioned(
      key: ValueKey("device_positioned_${sectionKey}_$deviceId"),
      duration: isDragging
          ? (_draggingDeviceDropping
                ? const Duration(milliseconds: 340)
                : Duration.zero)
          : isSectionDragging
          ? const Duration(milliseconds: 270)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: targetOffset.dx,
      top: targetOffset.dy,
      width: itemWidth,
      height: itemHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: isDragging
            ? null
            : (details) {
                _startDeviceDrag(
                  sectionKey: sectionKey,
                  entries: sourceEntries,
                  deviceId: deviceId,
                  index: index,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  spacing: spacing,
                  details: details,
                );
              },
        onLongPressMoveUpdate: (details) {
          _updateDeviceDrag(
            sectionKey: sectionKey,
            itemCount: sourceEntries.length,
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            spacing: spacing,
            details: details,
          );
        },
        onLongPressEnd: (_) {
          unawaited(
            _finishDeviceDrag(
              sectionKey,
              itemWidth: itemWidth,
              itemHeight: itemHeight,
              spacing: spacing,
            ),
          );
        },
        onLongPressCancel: _cancelDeviceDrag,
        child: wrappedCard,
      ),
    );
  }

  Widget _reorderableDeviceSection({
    required String groupName,
    required List<MapEntry<String, dynamic>> entries,
    required double spacing,
    required double itemWidth,
    required bool compact,
    required AppStrings strings,
  }) {
    final sectionKey = _sectionKeyForGroup(groupName);
    final canReorder = _canReorderDevices && entries.length > 1;
    final itemHeight = _deviceGridItemHeight(compact, entries, strings);
    final visibleEntries = canReorder
        ? _dragPreviewEntries(sectionKey, entries)
        : entries;
    final totalRows = (visibleEntries.length / 2).ceil();
    final sectionHeight = visibleEntries.isEmpty
        ? 0.0
        : (totalRows * itemHeight) + ((totalRows - 1) * spacing);
    final gridKey = _sectionGridKey(sectionKey);

    if (!canReorder) {
      return SizedBox(
        key: ValueKey(
          "device-section-static-${widget.homeId}-$selectedRoomId-$sectionKey",
        ),
        height: sectionHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < visibleEntries.length; index++)
              Positioned(
                left: _deviceGridOffsetForIndex(
                  index: index,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  spacing: spacing,
                ).dx,
                top: _deviceGridOffsetForIndex(
                  index: index,
                  itemWidth: itemWidth,
                  itemHeight: itemHeight,
                  spacing: spacing,
                ).dy,
                width: itemWidth,
                height: itemHeight,
                child: SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: _deviceGridItem(
                    sectionKey: sectionKey,
                    entry: visibleEntries[index],
                    itemWidth: itemWidth,
                    compact: compact,
                    strings: strings,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final activeDraggingDeviceId = _draggingSectionKey == sectionKey
        ? _draggingDeviceId
        : null;
    final paintEntries = <MapEntry<String, dynamic>>[
      ...visibleEntries.where((entry) => entry.key != activeDraggingDeviceId),
      if (activeDraggingDeviceId != null)
        ...visibleEntries.where((entry) => entry.key == activeDraggingDeviceId),
    ];

    return SizedBox(
      key: ValueKey(
        "device-section-animated-${widget.homeId}-$selectedRoomId-$sectionKey",
      ),
      height: sectionHeight,
      child: Stack(
        key: gridKey,
        clipBehavior: Clip.none,
        children: [
          for (final entry in paintEntries)
            _animatedPositionedDeviceCard(
              sectionKey: sectionKey,
              entry: entry,
              index: visibleEntries.indexWhere(
                (visibleEntry) => visibleEntry.key == entry.key,
              ),
              itemWidth: itemWidth,
              itemHeight: itemHeight,
              spacing: spacing,
              compact: compact,
              strings: strings,
              sourceEntries: entries,
            ),
        ],
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
      padding: const EdgeInsets.only(top: 0, bottom: 7),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
    final securityEntries = _groupEntries("An ninh ra/vào");
    final emergencyEntries = _groupEntries("Nguy hiểm khẩn cấp");
    final infrastructureEntries = _groupEntries("Điều khiển & hạ tầng");
    final infrastructureTypeGroups = _groupInfrastructureEntriesByType(
      infrastructureEntries,
    );

    return Column(
      children: [
        ?header,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final spacing = compact ? 10.0 : 14.0;
              final contentWidth = constraints.maxWidth - 24;
              final itemWidth = (contentWidth - spacing) / 2;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(12, 6, 12, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          padding: const EdgeInsets.only(bottom: 7),
                          child: _addDeviceButton(),
                        ),
                      ),
                    if (securityEntries.isEmpty)
                      _emptySecurityState(strings)
                    else
                      _reorderableDeviceSection(
                        groupName: "An ninh ra/vào",
                        entries: securityEntries,
                        spacing: spacing,
                        itemWidth: itemWidth,
                        compact: compact,
                        strings: strings,
                      ),
                    if (emergencyEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader(
                        title: strings.t("Nguy hiểm khẩn cấp"),
                        count: emergencyEntries.length,
                        showAddButton: false,
                      ),
                      _reorderableDeviceSection(
                        groupName: "Nguy hiểm khẩn cấp",
                        entries: emergencyEntries,
                        spacing: spacing,
                        itemWidth: itemWidth,
                        compact: compact,
                        strings: strings,
                      ),
                    ],
                    if (infrastructureEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader(
                        title: strings.t("Điều khiển & hạ tầng"),
                        count: infrastructureEntries.length,
                        showAddButton: false,
                      ),
                      _infrastructureTypeGrid(
                        groups: infrastructureTypeGroups,
                        spacing: spacing,
                        itemWidth: itemWidth,
                        compact: compact,
                        strings: strings,
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
