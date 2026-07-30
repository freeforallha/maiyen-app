part of '../device_list.dart';

extension _Status on _DeviceListState {
  bool _isSirenActive(Map<String, dynamic> device) {
    return isConfirmedSirenActiveForUi(device);
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
        .ref("accounts/$uid/${_DeviceListState._deviceOrderRoot}/$homeId")
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
    return MaiYenIdentifiers.deviceOrderStorageKey(
      uid: uid,
      homeId: homeId,
    );
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
        return MaiYenColors.safe;

      case "warn":
        return MaiYenColors.warning;

      case "off":
      default:
        return MaiYenColors.danger;
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
        color: MaiYenColors.danger,
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
        return Icons.campaign_rounded;
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
        if (!isSirenConnectedForUi(d)) {
          return strings.t("Thiết bị đang Offline");
        }

        return isConfirmedSirenActiveForUi(d)
            ? strings.t("Còi đang bật")
            : strings.t("Còi sẵn sàng");

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
      return MaiYenColors.emergency;
    }

    if (level == "danger") {
      return MaiYenColors.danger;
    }

    if (level == "warning") {
      return MaiYenColors.warning;
    }

    return MaiYenColors.safe;
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

}
