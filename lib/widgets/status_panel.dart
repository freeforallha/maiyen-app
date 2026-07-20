import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import '../pages/home/home_data_helpers.dart';
import '../helpers/emergency_pulse_ticker.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../services/notification_service.dart';

class StatusPanel extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final Map<String, dynamic> overall;
  final VoidCallback? onPair;
  final VoidCallback? onQR;
  final String alarmStart;
  final String alarmEnd;
  final String environmentText;
  final Map<String, dynamic> homeEvents;
  final VoidCallback? onEnvironmentTap;
  final String securityMode;
  final ValueChanged<String>? onSecurityModeChanged;
  final String securityModeSource;
  final int securityModeRepeatMinutes;
  final Future<bool> Function(int minutes)? onSecurityModeRepeatChanged;

  final VoidCallback? onAlarmPauseToday;

  final VoidCallback? onScheduleNotification;
  final VoidCallback? onScheduleAlarm;
  final String alarmPauseText;

  const StatusPanel({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.overall,
    required this.onPair,
    required this.onQR,
    required this.alarmStart,
    required this.alarmEnd,
    required this.environmentText,
    required this.homeEvents,
    this.onEnvironmentTap,
    this.securityMode = "normal",
    this.securityModeSource = "",
    this.securityModeRepeatMinutes = 0,
    this.onSecurityModeChanged,
    this.onSecurityModeRepeatChanged,
    this.onAlarmPauseToday,
    this.onScheduleNotification,
    this.onScheduleAlarm,
    required this.alarmPauseText,
  });

  @override
  State<StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends State<StatusPanel> {
  Timer? _timer;
  bool _emergencyPulseDanger = false;
  bool _mutingHomeSiren = false;
  AppStrings get _strings => AppStrings.of(context);
  int _broadcastIndex = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        _broadcastIndex++;
      });
    });

    EmergencyPulseTicker.ensureStarted();
    _emergencyPulseDanger = EmergencyPulseTicker.phase.value;
    EmergencyPulseTicker.phase.addListener(_handleSharedEmergencyPulse);
    _syncEmergencyPulse();
  }

  @override
  void didUpdateWidget(covariant StatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEmergencyPulse();
  }

  bool get _hasEmergencyStatus =>
      widget.overall["level"]?.toString() == "emergency";

  void _handleSharedEmergencyPulse() {
    if (!mounted || !_hasEmergencyStatus) {
      return;
    }

    final next = EmergencyPulseTicker.phase.value;
    if (_emergencyPulseDanger == next) {
      return;
    }

    setState(() {
      _emergencyPulseDanger = next;
    });
  }

  void _syncEmergencyPulse() {
    _emergencyPulseDanger = _hasEmergencyStatus
        ? EmergencyPulseTicker.phase.value
        : false;
  }

  @override
  void dispose() {
    EmergencyPulseTicker.phase.removeListener(_handleSharedEmergencyPulse);
    _timer?.cancel();
    super.dispose();
  }

  Color _statusColor(String level) {
    if (level == "no_data") {
      return SafeHomeColors.textSecondary;
    }

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

  IconData _statusIcon(String level) {
    if (level == "no_data") {
      return Icons.remove_circle_outline_rounded;
    }

    if (level == "emergency") {
      return Icons.crisis_alert_rounded;
    }

    if (level == "danger") {
      return Icons.warning_amber_rounded;
    }

    if (level == "warning") {
      return Icons.info_outline_rounded;
    }

    return Icons.verified_rounded;
  }

  String _statusText(String level) {
    if (level == "no_data") {
      return "-------";
    }

    if (level == "emergency") {
      return _strings.emergencyStatusTitle();
    }

    if (level == "danger") {
      return _strings.t("CHƯA AN TOÀN");
    }

    if (level == "warning") {
      return _strings.t("CẦN CHÚ Ý");
    }

    return _strings.t("ĐÃ AN TOÀN");
  }

  List<Map<String, dynamic>> _sortedRecentEvents([
    Map<String, dynamic>? source,
  ]) {
    final events = (source ?? widget.homeEvents).values
        .map((item) => safeMap(item))
        .toList();

    events.sort((a, b) {
      final first = int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
      final second = int.tryParse(b["time"]?.toString() ?? "0") ?? 0;

      return second.compareTo(first);
    });

    return events.take(20).toList();
  }

  Map<String, int> _eventCounts(List<Map<String, dynamic>> recentEvents) {
    int openCount = 0;
    int smokeCount = 0;
    int sosCount = 0;

    for (final event in recentEvents) {
      final text = (event["text"] ?? "").toString().toLowerCase();

      if (text.contains("mở")) {
        openCount++;
      }

      if (text.contains("khói")) {
        smokeCount++;
      }

      if (text.contains("sos")) {
        sosCount++;
      }
    }

    return {"open": openCount, "smoke": smokeCount, "sos": sosCount};
  }

  List<String> _buildActionSuggestions({
    required AppStrings strings,
    required Map<String, dynamic> liveHome,
    required Map<String, dynamic> overall,
    required List<String> rawEmergencyIssues,
    required List<String> rawDangerIssues,
    required List<String> rawWarningIssues,
    required List<String> rawSafeSummary,
  }) {
    final hasDevices = overall["hasDevices"] == true;

    if (!hasDevices) {
      return [strings.statusAddFirstDeviceSuggestion()];
    }

    final suggestions = <String>[];

    void addSuggestion(String text) {
      final cleanText = text.trim();

      if (cleanText.isEmpty || suggestions.contains(cleanText)) {
        return;
      }

      if (suggestions.length >= 3) {
        return;
      }

      suggestions.add(cleanText);
    }

    bool containsAny(String source, List<String> keywords) {
      final normalized = source.toLowerCase();

      return keywords.any((keyword) {
        return normalized.contains(keyword.toLowerCase());
      });
    }

    bool hasEnabledScheduleValue(dynamic raw) {
      if (raw is List) {
        return raw.any(hasEnabledScheduleValue);
      }

      if (raw is Map) {
        if (raw["enabled"] == true) {
          return true;
        }

        return raw.values.any(hasEnabledScheduleValue);
      }

      return false;
    }

    bool hasEnabledDeviceAlarm(Map<String, dynamic> devices) {
      for (final rawDevice in devices.values) {
        final device = safeMap(rawDevice);
        final alarm = safeMap(device["alarm"]);

        if (alarm["enabled"] == true) {
          return true;
        }

        if (hasEnabledScheduleValue(device["alarms"])) {
          return true;
        }
      }

      return false;
    }

    final rawEmergencyText = rawEmergencyIssues.join("\n").toLowerCase();
    final rawDangerText = rawDangerIssues.join("\n").toLowerCase();
    final rawWarningText = rawWarningIssues.join("\n").toLowerCase();
    final rawSafeText = rawSafeSummary.join("\n").toLowerCase();
    final allRawText =
        "$rawEmergencyText\n$rawDangerText\n$rawWarningText\n$rawSafeText";

    final hasEmergencyIssue = containsAny(rawEmergencyText, const [
      "sos",
      "có khói",
      "rò rỉ gas",
      "phát hiện khí co",
      "phát hiện ngập nước",
      "nhiệt độ nguy hiểm",
      "phát hiện chập điện",
      "phát hiện quá dòng",
      "phát hiện quá áp",
      "thiết bị điện quá nhiệt",
    ]);

    final hasOpenIssue = containsAny("$rawDangerText\n$rawWarningText", const [
      "đang mở",
      "khóa đang mở",
    ]);

    final hasArmedOpenIssue = containsAny(rawDangerText, const [
      "đang mở khi nhà ở chế độ bảo vệ",
      "khóa đang mở khi nhà ở chế độ bảo vệ",
      "đang mở trong giờ báo động",
      "khóa đang mở trong giờ báo động",
    ]);

    final hasUnknownMemberLocation = containsAny(rawWarningText, const [
      "chưa xác định vị trí",
    ]);

    final hasDisconnectedDevice = containsAny(rawWarningText, const [
      "mất kết nối",
    ]);

    final hasLowBatteryDevice = containsAny(rawWarningText, const ["pin yếu"]);

    final noMemberInside = RegExp(
      r"thành viên(?: đang ở)? trong nhà:\s*0/",
    ).hasMatch(allRawText);

    final hasMemberInside = RegExp(
      r"thành viên(?: đang ở)? trong nhà:\s*[1-9][0-9]*/",
    ).hasMatch(allRawText);

    final isArmed = normalizeSecurityMode(liveHome["securityMode"]) == "armed";

    final devices = safeMap(liveHome["devices"]);
    final schedules = safeMap(liveHome["schedules"]);
    final homeAlarm = safeMap(liveHome["alarm"]);

    final hasReminderSchedule = hasEnabledScheduleValue(
      schedules["notifications"],
    );

    final hasAlarmSchedule =
        homeAlarm["enabled"] == true ||
        hasEnabledScheduleValue(schedules["alarms"]) ||
        hasEnabledDeviceAlarm(devices);

    if (hasEmergencyIssue) {
      addSuggestion(strings.statusEmergencyActionSuggestion());
    }

    if (hasOpenIssue && noMemberInside) {
      addSuggestion(strings.statusOpenHomeEmptySuggestion());
    }

    if (hasArmedOpenIssue) {
      addSuggestion(strings.statusArmedOpenSuggestion());
    }

    if (isArmed && hasMemberInside) {
      addSuggestion(strings.statusMemberInsideWhileArmedSuggestion());
    }

    if (hasUnknownMemberLocation) {
      addSuggestion(strings.statusUnknownLocationSuggestion());
    }

    if (hasDisconnectedDevice) {
      addSuggestion(strings.statusDisconnectedDeviceSuggestion());
    }

    if (hasLowBatteryDevice) {
      addSuggestion(strings.statusLowBatterySuggestion());
    }

    if (!hasReminderSchedule) {
      addSuggestion(strings.statusReminderMissingSuggestion());
    }

    if (!hasAlarmSchedule) {
      addSuggestion(strings.statusAlarmMissingSuggestion());
    }

    if (suggestions.isEmpty) {
      addSuggestion(strings.statusNoImmediateActionSuggestion());
    }

    return suggestions;
  }

  void _showSecurityModeOptions(BuildContext context) {
    final currentMode = normalizeSecurityMode(widget.securityMode);
    final allowedRepeatMinutes = <int>[0, 15, 30, 60];
    var localRepeatMinutes =
        allowedRepeatMinutes.contains(widget.securityModeRepeatMinutes)
        ? widget.securityModeRepeatMinutes
        : 0;
    var repeatSaving = false;

    SafeHomeNavigation.showModalSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setSheetState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                decoration: const BoxDecoration(
                  color: SafeHomeColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Text(
                      _strings.t('Chế độ nhà'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SafeHomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: currentMode == 'armed'
                          ? _strings.armedSecurityModeSourceLabel(
                              widget.securityModeSource,
                            )
                          : _strings.t('Bảo vệ'),
                      subtitle: _strings.t('Giám sát toàn diện'),
                      color: SafeHomeColors.danger,
                      selected: currentMode == 'armed',
                      trailing: Container(
                        width: 124,
                        height: 40,
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: SafeHomeColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: SafeHomeColors.primary.withValues(
                              alpha: 0.28,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (repeatSaving)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: localRepeatMinutes,
                                  isExpanded: true,
                                  isDense: true,
                                  borderRadius: BorderRadius.circular(14),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: SafeHomeColors.primary,
                                  ),
                                  items: allowedRepeatMinutes
                                      .map(
                                        (minutes) => DropdownMenuItem<int>(
                                          value: minutes,
                                          child: Text(
                                            minutes == 0
                                                ? _strings.t('Không lặp lại')
                                                : _strings.minuteText(minutes),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: SafeHomeColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged:
                                      widget.onSecurityModeRepeatChanged ==
                                              null ||
                                          repeatSaving
                                      ? null
                                      : (minutes) async {
                                          if (minutes == null ||
                                              minutes == localRepeatMinutes) {
                                            return;
                                          }

                                          setSheetState(() {
                                            repeatSaving = true;
                                          });

                                          final saved =
                                              await widget
                                                  .onSecurityModeRepeatChanged!(
                                                minutes,
                                              );

                                          if (!stateContext.mounted) {
                                            return;
                                          }

                                          setSheetState(() {
                                            if (saved) {
                                              localRepeatMinutes = minutes;
                                            }

                                            repeatSaving = false;
                                          });
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call('armed');
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: _strings.t('Bình thường'),
                      subtitle: currentMode == 'normal'
                          ? _strings.t('Đang được sử dụng')
                          : _strings.t(
                              'Sử dụng báo động theo lịch đã thiết lập',
                            ),
                      color: SafeHomeColors.textSecondary,
                      selectedColor: SafeHomeColors.textSecondary,
                      selected: currentMode == 'normal',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call('normal');
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.shield_outlined,
                      title: _strings.t('Không bảo vệ'),
                      subtitle: _strings.t(
                        'Chỉ gửi thông báo, không kích hoạt báo động',
                      ),
                      color: SafeHomeColors.textSecondary,
                      selected: currentMode == 'unprotected',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call('unprotected');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Color? selectedColor,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: selected
          ? SafeHomeColors.primary.withValues(alpha: 0.08)
          : SafeHomeColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? SafeHomeColors.primary.withValues(alpha: 0.42)
                  : SafeHomeColors.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? SafeHomeColors.primary.withValues(alpha: 0.14)
                      : color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? (selectedColor ?? SafeHomeColors.primary)
                      : color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: SafeHomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: SafeHomeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing],
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSummary(BuildContext context) {
    if (!mounted) {
      return;
    }

    final strings = AppStrings.of(context);

    SafeHomeNavigation.showModalSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
            ),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.t("Tổng hợp trạng thái nhà"),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: SafeHomeColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.insights_rounded,
                      color: SafeHomeColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(child: _buildLiveStatusSummaryList(strings)),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<DatabaseEvent>? _sharedOwnerUidStream() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (currentUid.isEmpty || widget.homeId.trim().isEmpty) {
      return null;
    }

    return FirebaseDatabase.instance
        .ref("accounts/$currentUid/sharedHomes/${widget.homeId}/ownerUid")
        .onValue;
  }

  String _fallbackOwnerUid() {
    final ownerUid = widget.ownerUid.trim();

    if (ownerUid.isNotEmpty) {
      return ownerUid;
    }

    return FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  Widget _buildLiveStatusSummaryList(AppStrings strings) {
    final ownerStream = _sharedOwnerUidStream();

    if (ownerStream == null) {
      return _buildOwnerHomeStream(_fallbackOwnerUid(), strings);
    }

    return StreamBuilder<DatabaseEvent>(
      stream: ownerStream,
      builder: (context, ownerSnapshot) {
        final sharedOwnerUid =
            ownerSnapshot.data?.snapshot.value?.toString().trim() ?? "";
        final resolvedOwnerUid = sharedOwnerUid.isNotEmpty
            ? sharedOwnerUid
            : _fallbackOwnerUid();

        return _buildOwnerHomeStream(resolvedOwnerUid, strings);
      },
    );
  }

  Widget _buildOwnerHomeStream(String ownerUid, AppStrings strings) {
    final cleanOwnerUid = ownerUid.trim();
    final cleanHomeId = widget.homeId.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return _summaryMessage(
        icon: Icons.home_work_outlined,
        text: strings.t("Chưa có dữ liệu trạng thái"),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      key: ValueKey("$cleanOwnerUid/$cleanHomeId"),
      stream: FirebaseDatabase.instance
          .ref("accounts/$cleanOwnerUid/homes/$cleanHomeId")
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _summaryMessage(
            icon: Icons.hourglass_empty_rounded,
            text: strings.loading,
          );
        }

        if (snapshot.hasError) {
          return _summaryMessage(
            icon: Icons.cloud_off_rounded,
            text: strings.t("Chưa có dữ liệu trạng thái"),
          );
        }

        final liveHome = safeMap(snapshot.data?.snapshot.value);

        if (liveHome.isEmpty) {
          return _summaryMessage(
            icon: Icons.home_work_outlined,
            text: strings.t("Chưa có dữ liệu trạng thái"),
          );
        }

        return _buildStatusSummarySections(liveHome, strings);
      },
    );
  }

  bool _isEnvironmentSummaryLine(String text) {
    final normalized = text.trim().toLowerCase();

    return normalized.startsWith("môi trường hiện tại:") ||
        normalized.startsWith("current environment:") ||
        normalized.startsWith("当前环境") ||
        normalized.startsWith("현재 환경:");
  }

  String _overviewEnvironmentLine({
    required Map<String, dynamic> liveOverall,
    required Map<String, dynamic> devices,
    required AppStrings strings,
  }) {
    if (liveOverall["hasEnvironmentDevice"] != true) {
      return "";
    }

    final panelEnvironment = widget.environmentText
        .replaceAll(" | ", " / ")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
    final fallbackEnvironment = HomeDataHelpers.getHomeEnvironmentText(
      devices: devices,
    ).trim();
    final environment = panelEnvironment.isNotEmpty
        ? panelEnvironment
        : fallbackEnvironment;

    if (environment.isEmpty) {
      return "";
    }

    return strings.statusText("Môi trường hiện tại: $environment");
  }

  Widget _buildStatusSummarySections(
    Map<String, dynamic> liveHome,
    AppStrings strings,
  ) {
    final liveOverall = getHomeOverallStatus(liveHome);

    final rawEmergencyIssues = List<String>.from(
      liveOverall["emergencyIssues"] ?? const [],
    );

    final rawDangerIssues = List<String>.from(
      liveOverall["dangerIssues"] ?? const [],
    );

    final rawWarningIssues = List<String>.from(
      liveOverall["warningIssues"] ?? const [],
    );

    final rawPresenceWarnings = List<String>.from(
      liveOverall["presenceWarnings"] ?? const [],
    );

    final emergencyIssues = rawEmergencyIssues.map(strings.statusText).toList();

    final dangerIssues = rawDangerIssues.map(strings.statusText).toList();

    final warningIssues = [
      ...rawWarningIssues,
      ...rawPresenceWarnings,
    ].map(strings.statusText).toList();

    final rawSafeSummary = List<String>.from(
      liveOverall["safeSummary"] ?? const [],
    );
    final safeSummary = rawSafeSummary
        .where((line) => !_isEnvironmentSummaryLine(line))
        .map(strings.statusText)
        .toList();

    final actionSuggestions = _buildActionSuggestions(
      strings: strings,
      liveHome: liveHome,
      overall: liveOverall,
      rawEmergencyIssues: rawEmergencyIssues,
      rawDangerIssues: rawDangerIssues,
      rawWarningIssues: [...rawWarningIssues, ...rawPresenceWarnings],
      rawSafeSummary: rawSafeSummary,
    );

    final normalizedLiveSecurityMode = normalizeSecurityMode(
      liveHome["securityMode"],
    );
    final liveSecurityMode = normalizedLiveSecurityMode == "armed"
        ? strings.t("Bảo vệ")
        : normalizedLiveSecurityMode == "unprotected"
        ? strings.t("Không bảo vệ")
        : strings.t("Bình thường");

    final devices = safeMap(liveHome["devices"]);
    final environmentLine = _overviewEnvironmentLine(
      liveOverall: liveOverall,
      devices: devices,
      strings: strings,
    );
    final overviewItems = <String>[
      strings.familyModeText(liveSecurityMode),
      if (environmentLine.isNotEmpty) environmentLine,
      ...safeSummary,
    ];

    return ListView(
      shrinkWrap: true,
      children: [
        if (emergencyIssues.isNotEmpty) ...[
          _summarySection(
            title: strings.emergencySectionTitle(),
            icon: Icons.crisis_alert_rounded,
            color: SafeHomeColors.emergency,
            items: emergencyIssues,
          ),
          const SizedBox(height: 12),
        ],
        if (dangerIssues.isNotEmpty) ...[
          _summarySection(
            title: strings.t("Cần xử lý ngay"),
            icon: Icons.warning_amber_rounded,
            color: SafeHomeColors.danger,
            items: dangerIssues,
          ),
          const SizedBox(height: 12),
        ],
        if (warningIssues.isNotEmpty) ...[
          _summarySection(
            title: strings.t("Cần kiểm tra"),
            icon: Icons.info_outline_rounded,
            color: SafeHomeColors.warning,
            items: warningIssues,
          ),
          const SizedBox(height: 12),
        ],
        _summarySection(
          title: strings.actionSuggestionTitle(),
          icon: Icons.tips_and_updates_rounded,
          color: SafeHomeColors.info,
          items: actionSuggestions,
        ),
        const SizedBox(height: 12),
        _summarySection(
          title: strings.t("Tổng quan hôm nay"),
          icon: Icons.bar_chart_rounded,
          color: SafeHomeColors.safe,
          items: overviewItems.isEmpty
              ? [strings.t("Chưa có dữ liệu tổng quan")]
              : overviewItems,
        ),
      ],
    );
  }

  Widget _summaryMessage({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: SafeHomeColors.textSecondary, size: 34),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SafeHomeColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _summarySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _summaryItem(text: item, color: color)),
        ],
      ),
    );
  }

  static Widget _summaryItem({required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 9),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: SafeHomeColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSirenActive(Map<String, dynamic> device) {
    return isActiveDeviceSignal(device["alarm"]) ||
        normalizeDeviceSwitchState(device) == "on";
  }

  bool _isSirenConnected(Map<String, dynamic> device) {
    final availability = normalizeAvailability(device["availability"]);

    if (availability != "online") {
      return false;
    }

    final lastSeen = parseLastSeen(device["last_seen"]);

    if (lastSeen == null) {
      return true;
    }

    final age = DateTime.now().toUtc().difference(lastSeen.toUtc());

    if (age.isNegative) {
      return true;
    }

    final maxAge = Duration(
      minutes: (heartbeatLimitHours("siren") * 60).round(),
    );

    return age <= maxAge;
  }

  Future<void> _muteHomeSiren() async {
    if (_mutingHomeSiren || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_strings.confirmStopSirenTitle()),
          content: Text(_strings.confirmStopSirenBody()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_strings.t("HỦY")),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.campaign_rounded),
              label: Text(_strings.stopSirenLabel()),
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
      homeId: widget.homeId,
      hubId: "",
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
        _strings.sirenMutedShortMessage(),
        color: SafeHomeColors.safe,
        icon: Icons.campaign_rounded,
      );
      return;
    }

    showTopToast(
      context,
      _strings.sirenStopUnavailableMessage(),
      color: SafeHomeColors.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  Widget _buildQuickSirenAction() {
    final cleanOwnerUid = widget.ownerUid.trim();
    final cleanHomeId = widget.homeId.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return _quickSirenButton(
        hasSiren: false,
        sirenActive: false,
        sirenConnected: false,
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance
          .ref("accounts/$cleanOwnerUid/homes/$cleanHomeId/devices")
          .onValue,
      builder: (context, snapshot) {
        final devices = safeMap(snapshot.data?.snapshot.value);
        var hasSiren = false;
        var sirenActive = false;
        var allSirensConnected = true;

        for (final value in devices.values) {
          final device = safeMap(value);
          final type = device["type"]?.toString().trim().toLowerCase();

          if (type != "siren") {
            continue;
          }

          hasSiren = true;

          if (!_isSirenConnected(device)) {
            allSirensConnected = false;
          }

          if (_isSirenActive(device)) {
            sirenActive = true;
          }
        }

        return _quickSirenButton(
          hasSiren: hasSiren,
          sirenActive: sirenActive,
          sirenConnected: hasSiren && allSirensConnected,
        );
      },
    );
  }

  void _showQuickSirenMessage({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    showTopToast(context, message, color: color, icon: icon);
  }

  Future<void> _handleQuickSirenTap({
    required bool hasSiren,
    required bool sirenActive,
    required bool sirenConnected,
  }) async {
    if (_mutingHomeSiren || !mounted) {
      return;
    }

    if (!hasSiren) {
      _showQuickSirenMessage(
        message: _strings.noPhysicalSirenMessage(),
        color: SafeHomeColors.textSecondary,
        icon: Icons.campaign_rounded,
      );
      return;
    }

    if (sirenActive) {
      await _muteHomeSiren();
      return;
    }

    if (!sirenConnected) {
      _showQuickSirenMessage(
        message: _strings.sirenConnectionIssueMessage(),
        color: SafeHomeColors.warning,
        icon: Icons.wifi_off_rounded,
      );
      return;
    }

    _showQuickSirenMessage(
      message: _strings.sirenReadyMessage(),
      color: SafeHomeColors.safe,
      icon: Icons.campaign_rounded,
    );
  }

  Widget _quickSirenButton({
    required bool hasSiren,
    required bool sirenActive,
    required bool sirenConnected,
  }) {
    final tooltip = !hasSiren
        ? _strings.noPhysicalSirenMessage()
        : sirenActive
        ? _strings.muteHomeSirenLabel()
        : !sirenConnected
        ? _strings.sirenConnectionIssueMessage()
        : _strings.sirenReadyMessage();

    return ValueListenableBuilder<bool>(
      valueListenable: EmergencyPulseTicker.phase,
      builder: (context, dangerPhase, child) {
        final color = !hasSiren
            ? SafeHomeColors.textSecondary
            : sirenActive
            ? (dangerPhase ? SafeHomeColors.danger : SafeHomeColors.warning)
            : !sirenConnected
            ? SafeHomeColors.warning
            : SafeHomeColors.safe;

        return Tooltip(
          message: tooltip,
          child: Semantics(
            button: true,
            enabled: !_mutingHomeSiren,
            label: tooltip,
            child: Material(
              color: color.withValues(alpha: hasSiren ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: _mutingHomeSiren
                    ? null
                    : () => _handleQuickSirenTap(
                        hasSiren: hasSiren,
                        sirenActive: sirenActive,
                        sirenConnected: sirenConnected,
                      ),
                borderRadius: BorderRadius.circular(9),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  width: 35,
                  height: 33,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: color.withValues(alpha: sirenActive ? 0.82 : 0.36),
                      width: sirenActive ? 1.15 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _mutingHomeSiren
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Icon(
                          !hasSiren
                              ? Icons.campaign_rounded
                              : sirenActive
                              ? Icons.campaign_rounded
                              : !sirenConnected
                              ? Icons.campaign_rounded
                              : Icons.campaign_rounded,
                          size: 22,
                          color: color,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvironmentAction(String environment) {
    if (environment.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: widget.onEnvironmentTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.thermostat_rounded,
              size: 15,
              color: SafeHomeColors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text(
              environment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.2,
                height: 1,
                fontWeight: FontWeight.w800,
                color: SafeHomeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.overall["level"]?.toString() ?? "no_data";

    final hasDevices = widget.overall["hasDevices"] == true;

    final noData = level == "no_data" || !hasDevices;
    final emergencyStatus = level == "emergency";

    final issues = List<String>.from(widget.overall["issues"] ?? const []);

    final safeSummary = List<String>.from(
      widget.overall["safeSummary"] ?? const [],
    );

    final allLines = issues.isNotEmpty ? issues : safeSummary;

    final normalizedSecurityMode = normalizeSecurityMode(widget.securityMode);
    final manualSecurityMode =
        normalizedSecurityMode == "armed" &&
        widget.securityModeSource == "manual";
    final unprotectedMode = normalizedSecurityMode == "unprotected";

    final manualSecurityModeText = _strings.t(
      "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường",
    );
    final unprotectedModeText = _strings.t(
      "Toàn bộ báo động của nhà đang tắt; hệ thống chỉ gửi thông báo.",
    );

    final normalFirstLine = allLines.isNotEmpty
        ? allLines.first
        : _strings.t("Chưa có dữ liệu trạng thái");

    final firstLine = noData
        ? _strings.t("Chưa đủ dữ liệu để đánh giá")
        : emergencyStatus
        ? normalFirstLine
        : unprotectedMode
        ? unprotectedModeText
        : manualSecurityMode
        ? manualSecurityModeText
        : normalFirstLine;

    final rotatingLines = noData
        ? <String>[]
        : emergencyStatus
        ? allLines.length > 1
              ? allLines.skip(1).toList()
              : <String>[]
        : unprotectedMode || manualSecurityMode
        ? allLines
        : allLines.length > 1
        ? allLines.skip(1).toList()
        : <String>[];

    final secondLine = rotatingLines.isNotEmpty
        ? rotatingLines[_broadcastIndex % rotatingLines.length]
        : _strings.t("Nhấn để xem chi tiết...");
    final displayFirstLine = _strings.statusText(firstLine);
    final displaySecondLine = _strings.statusText(secondLine);
    final displaySecondLineWithHint =
        displaySecondLine.endsWith("...") || displaySecondLine.endsWith("…")
        ? "$displaySecondLine →"
        : "$displaySecondLine... →";

    final emergencyPulseColor = _emergencyPulseDanger
        ? SafeHomeColors.danger
        : SafeHomeColors.warning;
    final statusColor = emergencyStatus
        ? emergencyPulseColor
        : _statusColor(level);
    final panelColor = emergencyStatus
        ? emergencyPulseColor.withValues(
            alpha: _emergencyPulseDanger ? 0.20 : 0.15,
          )
        : SafeHomeColors.surface;
    final statusIcon = _statusIcon(level);
    final statusText = _statusText(level);

    final rawAlarmScheduleText =
        widget.alarmStart.trim().isNotEmpty && widget.alarmStart != "Tắt"
        ? widget.alarmStart.trim()
        : "";

    final alarmScheduleSet = rawAlarmScheduleText.isNotEmpty;

    final alarmScheduleText = alarmScheduleSet
        ? rawAlarmScheduleText
        : _strings.t("Tắt");

    final alarmPauseText = widget.alarmPauseText.trim();

    final alarmPauseSet =
        alarmPauseText.isNotEmpty &&
        alarmPauseText != _strings.t("Tắt") &&
        alarmPauseText != _strings.t("Chưa thiết lập");

    final recentEvents = _sortedRecentEvents();
    final eventCounts = _eventCounts(recentEvents);

    final openCount = eventCounts["open"] ?? 0;
    final smokeCount = eventCounts["smoke"] ?? 0;
    final sosCount = eventCounts["sos"] ?? 0;

    String subtitle;

    if (noData) {
      subtitle = "";
    } else if (issues.isNotEmpty) {
      subtitle = _strings.detectedIssuesCountText(issues.length);
    } else if (smokeCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo khói");
    } else if (sosCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo SOS");
    } else if (openCount > 0) {
      subtitle = _strings.doorsUsedTodayText(openCount);
    } else if (recentEvents.isNotEmpty) {
      subtitle = _strings.recentActivitiesCountText(recentEvents.length);
    } else {
      subtitle = _strings.t("Ngôi nhà đang hoạt động ổn định");
    }

    final environment = widget.overall["hasEnvironmentDevice"] == true
        ? widget.environmentText
              .replaceAll("/", " | ")
              .replaceAll("  ", " ")
              .trim()
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatusSummary(context),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: statusColor.withValues(
                  alpha: emergencyStatus ? 0.95 : 0.62,
                ),
                width: emergencyStatus ? 1.5 : 1.15,
              ),
              boxShadow: [
                BoxShadow(
                  color: emergencyStatus
                      ? statusColor.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.035),
                  blurRadius: emergencyStatus ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 19),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: statusColor,
                            ),
                          ),
                        ),
                        _buildEnvironmentAction(environment),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 43),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.2,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: issues.isNotEmpty
                              ? statusColor
                              : SafeHomeColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(right: 43),
                      child: _statusLine(
                        text: displayFirstLine,
                        color: emergencyStatus
                            ? statusColor
                            : manualSecurityMode
                            ? SafeHomeColors.danger
                            : issues.isNotEmpty
                            ? statusColor
                            : SafeHomeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Row(
                        key: ValueKey(displaySecondLine),
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: issues.isNotEmpty
                                  ? statusColor
                                  : SafeHomeColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              displaySecondLineWithHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.15,
                                color: issues.isNotEmpty
                                    ? statusColor
                                    : SafeHomeColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: _alarmStatusItem(
                            icon: normalizedSecurityMode == "unprotected"
                                ? Icons.shield_outlined
                                : Icons.shield_rounded,
                            value: normalizedSecurityMode == "armed"
                                ? _strings.t("Bảo vệ")
                                : normalizedSecurityMode == "unprotected"
                                ? _strings.t("Không bảo vệ")
                                : _strings.t("Bình thường"),
                            secondaryValue: normalizedSecurityMode == "armed"
                                ? _strings.armedSecurityModeSourceDetailLabel(
                                    widget.securityModeSource,
                                  )
                                : null,
                            active: normalizedSecurityMode != "normal",
                            activeColor: normalizedSecurityMode == "unprotected"
                                ? SafeHomeColors.warning
                                : SafeHomeColors.danger,
                            onTap: () => _showSecurityModeOptions(context),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: SafeHomeColors.border,
                        ),
                        Expanded(
                          child: _alarmStatusItem(
                            icon: Icons.crisis_alert_rounded,
                            value: alarmScheduleText,
                            active: alarmScheduleSet,
                            activeColor: SafeHomeColors.primary,
                            onTap: widget.onScheduleAlarm,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: SafeHomeColors.border,
                        ),
                        Expanded(
                          child: _alarmStatusItem(
                            icon: Icons.pause_circle_outline_rounded,
                            value: alarmPauseSet
                                ? alarmPauseText
                                : _strings.t("Tắt"),
                            active: alarmPauseSet,
                            activeColor: SafeHomeColors.warning,
                            onTap: widget.onAlarmPauseToday,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(top: 23, right: 0, child: _buildQuickSirenAction()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alarmStatusItem({
    required IconData icon,
    required String value,
    String? secondaryValue,
    required bool active,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    final color = active ? activeColor : SafeHomeColors.textSecondary;
    final cleanSecondaryValue = secondaryValue?.trim() ?? "";
    final displayValue = cleanSecondaryValue.isEmpty
        ? value
        : "$value - $cleanSecondaryValue";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.9,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine({
    Key? key,
    required String text,
    required Color color,
    Widget? trailing,
  }) {
    return Row(
      key: key,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              height: 1.15,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}
