part of '../device_list.dart';

extension _Presentation on _DeviceListState {
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
              icon: const Icon(Icons.campaign_rounded),
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
        color: MaiYenColors.safe,
        icon: Icons.campaign_rounded,
      );
      return;
    }

    showTopToast(
      context,
      strings.sirenStopUnavailableMessage(),
      color: MaiYenColors.danger,
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
          color: MaiYenColors.danger.withValues(alpha: 0.10),
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
                        Icons.campaign_rounded,
                        size: compact ? 12 : 13,
                        color: MaiYenColors.danger,
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
                            color: MaiYenColors.danger,
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
    final personalPreferences = resolveDevicePersonalAlarmPreferences(
      customRules: widget.personalAlarmRules,
      deviceId: realDeviceId,
      legacyFullscreenEnabled: settings.fullscreenEnabled,
    );
    final effectiveNotificationEnabled = personalPreferences.followHomeSchedule
        ? settings.notificationEnabled
        : personalPreferences.notificationEnabled;
    final iconSize = compact ? 9.5 : 10.5;

    if (!settings.enabled) {
      return Icon(
        Icons.shield_outlined,
        size: compact ? 15 : 16,
        color: MaiYenColors.textSecondary.withValues(alpha: 0.72),
      );
    }

    Widget channelIcon({
      required bool enabled,
      required IconData activeIcon,
      required IconData inactiveIcon,
    }) {
      return Icon(
        enabled ? activeIcon : inactiveIcon,
        size: iconSize,
        color: enabled
            ? MaiYenColors.safe
            : MaiYenColors.textSecondary.withValues(alpha: 0.62),
      );
    }

    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return SizedBox(
      width: compact ? 16 : 18,
      height: compact ? 31 : 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          channelIcon(
            enabled: effectiveNotificationEnabled,
            activeIcon: Icons.notifications_active_rounded,
            inactiveIcon: Icons.notifications_off_rounded,
          ),
          channelIcon(
            enabled: settings.physicalSirenEnabled,
            activeIcon: Icons.campaign_rounded,
            inactiveIcon: Icons.volume_off_rounded,
          ),
          channelIcon(
            enabled: personalPreferences.fullscreenEnabled,
            activeIcon: isIos
                ? Icons.phone_iphone_rounded
                : Icons.phone_android_rounded,
            inactiveIcon: Icons.phonelink_erase_rounded,
          ),
        ],
      ),
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
        ? MaiYenColors.danger
        : MaiYenColors.warning;

    final baseCardStatusColor =
        accentColor == MaiYenColors.danger || connectionStatus == "off"
        ? MaiYenColors.danger
        : connectionStatus == "warn"
        ? MaiYenColors.warning
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
        : MaiYenColors.surface;

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
                                    : MaiYenColors.textPrimary,
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
                                      color: MaiYenColors.textSecondary,
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
        return MaiYenColors.safe;
      case "weak":
        return MaiYenColors.warning;
      default:
        return MaiYenColors.textSecondary;
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
        ? MaiYenColors.danger
        : MaiYenColors.warning;
    final accentColor = sirenIsOn
        ? pulseColor
        : hasAttention
        ? MaiYenColors.warning
        : MaiYenColors.safe;
    final cardColor = sirenIsOn
        ? pulseColor.withValues(alpha: _sirenAlertPulseDanger ? 0.20 : 0.15)
        : MaiYenColors.surface;
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
              : MaiYenColors.textSecondary
        : _infrastructureSignalColor(entries);
    // Đồng bộ đúng chiều cao với card thiết bị thường. Riêng Myanmar chừa
    // thêm 1 px giống _deviceGridItemHeight để tránh overflow phần glyph.
    final cardHeight =
        (compact ? 70.0 : 75.0) + (strings.isBurmese ? 1.0 : 0.0);

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
          height: cardHeight,
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
                                    : MaiYenColors.textPrimary,
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
              SizedBox(height: compact ? 3 : 4),
              SizedBox(
                height: compact ? 15 : 17,
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
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    final itemHeight =
        (compact ? 70.0 : 75.0) + (strings.isBurmese ? 1.0 : 0.0);
    final rowCount = groups.length <= 2 ? 1 : 2;
    final columnCount = _twoRowHorizontalColumnCount(groups.length);
    final sectionHeight = (rowCount * itemHeight) + ((rowCount - 1) * spacing);
    final sectionWidth =
        (columnCount * itemWidth) + ((columnCount - 1) * spacing);

    final content = SizedBox(
      width: sectionWidth,
      height: sectionHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < groups.length; index++)
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
              child: _infrastructureTypeGroupCard(
                type: groups[index].key,
                entries: groups[index].value,
                itemWidth: itemWidth,
                compact: compact,
                strings: strings,
              ),
            ),
        ],
      ),
    );

    if (groups.length <= 4) {
      return content;
    }

    return SizedBox(
      height: sectionHeight,
      child: _horizontalDeviceFade(
        child: SingleChildScrollView(
          key: PageStorageKey<String>(
            "infrastructure-horizontal-${widget.homeId}-$selectedRoomId",
          ),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 34),
          child: content,
        ),
      ),
    );
  }
}
