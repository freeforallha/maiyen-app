import 'dart:async';

import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';

class StatusPanel extends StatefulWidget {
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
  final bool alarmEnabled;
  final ValueChanged<bool>? onAlarmEnabledChanged;

  final VoidCallback? onAlarmPauseToday;

  final VoidCallback? onScheduleNotification;
  final VoidCallback? onScheduleAlarm;
  final String alarmPauseText;

  const StatusPanel({
    super.key,
    required this.overall,
    required this.onPair,
    required this.onQR,
    required this.alarmStart,
    required this.alarmEnd,
    required this.environmentText,
    required this.homeEvents,
    this.onEnvironmentTap,
    this.securityMode = "normal",
    this.onSecurityModeChanged,
    this.alarmEnabled = true,
    this.onAlarmEnabledChanged,
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _statusColor(String level) {
    if (level == "danger") {
      return SafeHomeColors.danger;
    }

    if (level == "warning") {
      return SafeHomeColors.warning;
    }

    return SafeHomeColors.safe;
  }

  IconData _statusIcon(String level) {
    if (level == "danger") {
      return Icons.warning_amber_rounded;
    }

    if (level == "warning") {
      return Icons.info_outline_rounded;
    }

    return Icons.verified_rounded;
  }

  String _statusText(String level) {
    if (level == "danger") {
      return _strings.t("CHƯA AN TOÀN");
    }

    if (level == "warning") {
      return _strings.t("CẦN CHÚ Ý");
    }

    return _strings.t("ĐÃ AN TOÀN");
  }

  List<Map<String, dynamic>> _sortedRecentEvents() {
    final events = widget.homeEvents.values
        .map((item) => safeMap(item))
        .toList();

    events.sort((a, b) {
      final first =
          int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
      final second =
          int.tryParse(b["time"]?.toString() ?? "0") ?? 0;

      return second.compareTo(first);
    });

    return events.take(20).toList();
  }

  Map<String, int> _eventCounts(
      List<Map<String, dynamic>> recentEvents,
      ) {
    int openCount = 0;
    int smokeCount = 0;
    int sosCount = 0;

    for (final event in recentEvents) {
      final text =
      (event["text"] ?? "").toString().toLowerCase();

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

    return {
      "open": openCount,
      "smoke": smokeCount,
      "sos": sosCount,
    };
  }

  List<String> _buildAutomaticSummary({
    required List<String> dangerIssues,
    required List<String> warningIssues,
    required List<Map<String, dynamic>> recentEvents,
    required Map<String, int> eventCounts,
  }) {
    final summary = <String>[];
    final openCount = eventCounts["open"] ?? 0;
    final smokeCount = eventCounts["smoke"] ?? 0;
    final sosCount = eventCounts["sos"] ?? 0;

    if (dangerIssues.isNotEmpty || warningIssues.isNotEmpty) {
      summary.add(
        _strings.t(
          "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.",
        ),
      );

      if (dangerIssues.isNotEmpty) {
        summary.add(
          _strings.choose(
            vi: "${dangerIssues.length} vấn đề đang cần xử lý ngay.",
            en: "${dangerIssues.length} issues require immediate action.",
          ),
        );
      }

      if (warningIssues.isNotEmpty) {
        summary.add(
          _strings.choose(
            vi: "${warningIssues.length} dấu hiệu nên được kiểm tra thêm.",
            en: "${warningIssues.length} items need further review.",
          ),
        );
      }

      if (openCount > 0) {
        summary.add(
          _strings.choose(
            vi: "Gần đây cửa đã được mở $openCount lần.",
            en: "Doors were opened $openCount times recently.",
          ),
        );
      }
    } else {
      summary.add(
        _strings.t(
          "Nhà đang hoạt động ổn định, bạn có thể yên tâm.",
        ),
      );

      if (recentEvents.isNotEmpty) {
        summary.add(
          _strings.choose(
            vi: "Có ${recentEvents.length} hoạt động gần đây được ghi nhận.",
            en: "${recentEvents.length} recent activities were recorded.",
          ),
        );
      }

      if (openCount > 0) {
        summary.add(
          _strings.choose(
            vi: "Cửa được sử dụng $openCount lần gần đây.",
            en: "Doors were used $openCount times recently.",
          ),
        );
      }

      if (smokeCount == 0 && sosCount == 0) {
        summary.add(
          _strings.t(
            "Không có dấu hiệu khói hoặc SOS bất thường.",
          ),
        );
      }
    }

    if (summary.length == 1) {
      summary.add(
        _strings.t(
          "Chưa có nhiều hoạt động mới để phân tích sâu hơn.",
        ),
      );
    }

    return summary;
  }
  void _showSecurityModeOptions(BuildContext context) {
    final isArmed = widget.securityMode == "armed";

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            decoration: const BoxDecoration(
              color: SafeHomeColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                const Text(
                  "Chế độ nhà",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: SafeHomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _actionTile(
                  icon: Icons.shield_rounded,
                  title: "Bình thường",
                  subtitle: isArmed
                      ? "Chuyển về sử dụng thông thường"
                      : "Đang được sử dụng",
                  color: SafeHomeColors.safe,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onSecurityModeChanged?.call("normal");
                  },
                ),
                const SizedBox(height: 8),
                _actionTile(
                  icon: Icons.shield_rounded,
                  title: "Bảo vệ",
                  subtitle: isArmed
                      ? "Đang được sử dụng"
                      : "Bật giám sát cửa và chuyển động",
                  color: SafeHomeColors.danger,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onSecurityModeChanged?.call("armed");
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showScheduleOptions(BuildContext context) {
    bool localAlarmEnabled = widget.alarmEnabled;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  18,
                ),
                decoration: const BoxDecoration(
                  color: SafeHomeColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
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
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: SafeHomeColors.primarySoft,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: SafeHomeColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _strings.t("An ninh ra/vào"),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: SafeHomeColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _strings.t(
                                  "Cài đặt cảnh báo cho nhà hiện tại",
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                  SafeHomeColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: SafeHomeColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SwitchListTile(
                        value: localAlarmEnabled,
                        activeThumbColor: SafeHomeColors.primary,
                        activeTrackColor: SafeHomeColors.primarySoft,
                        secondary: Icon(
                          localAlarmEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: localAlarmEnabled
                              ? SafeHomeColors.primary
                              : SafeHomeColors.textSecondary,
                        ),
                        title: Text(
                          _strings.t("Nhận cảnh báo Alarm"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          localAlarmEnabled
                              ? _strings.t("Đang bật cho tài khoản này")
                              : _strings.t("Đang tắt cho tài khoản này"),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            localAlarmEnabled = value;
                          });

                          widget.onAlarmEnabledChanged?.call(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.notifications_none_rounded,
                      title: _strings.t("Hẹn giờ Reminder"),
                      subtitle: _strings.t("Nhắc kiểm tra nhà theo thời gian"),
                      color: SafeHomeColors.warning,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onScheduleNotification?.call();
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.crisis_alert_rounded,
                      title: _strings.t("Hẹn giờ Alarm"),
                      subtitle: widget.alarmStart.trim().isEmpty
                          ? _strings.t("Chưa thiết lập")
                          : widget.alarmStart,
                      color: SafeHomeColors.danger,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onScheduleAlarm?.call();
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: SafeHomeColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SafeHomeColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: SafeHomeColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSummary(BuildContext context) {
    final dangerIssues = List<String>.from(
      widget.overall["dangerIssues"] ?? const [],
    ).map(_strings.statusText).toList();
    final warningIssues = List<String>.from(
      widget.overall["warningIssues"] ?? const [],
    ).map(_strings.statusText).toList();
    final safeSummary = List<String>.from(
      widget.overall["safeSummary"] ?? const [],
    ).map(_strings.statusText).toList();

    final recentEvents = _sortedRecentEvents();
    final eventCounts = _eventCounts(recentEvents);

    final automaticSummary = _buildAutomaticSummary(
      dangerIssues: dangerIssues,
      warningIssues: warningIssues,
      recentEvents: recentEvents,
      eventCounts: eventCounts,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              20,
            ),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
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
                        _strings.t("Tổng hợp trạng thái nhà"),
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
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (dangerIssues.isNotEmpty) ...[
                        _summarySection(
                          title: _strings.t("Cần xử lý ngay"),
                          icon: Icons.warning_amber_rounded,
                          color: SafeHomeColors.danger,
                          items: dangerIssues,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (warningIssues.isNotEmpty) ...[
                        _summarySection(
                          title: _strings.t("Cần kiểm tra"),
                          icon: Icons.info_outline_rounded,
                          color: SafeHomeColors.warning,
                          items: warningIssues,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _summarySection(
                        title: _strings.t("Đánh giá tự động"),
                        icon: Icons.auto_awesome_rounded,
                        color: SafeHomeColors.info,
                        items: automaticSummary,
                      ),
                      const SizedBox(height: 12),
                      _summarySection(
                        title: _strings.t("Tổng quan hôm nay"),
                        icon: Icons.bar_chart_rounded,
                        color: SafeHomeColors.safe,
                        items: safeSummary.isEmpty
                            ? [
                          _strings.t("Chưa có dữ liệu tổng quan"),
                        ]
                            : safeSummary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
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
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
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
          ...items.map(
                (item) => _summaryItem(
              text: item,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _summaryItem({
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(
              top: 6,
              right: 9,
            ),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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

  @override
  Widget build(BuildContext context) {
    final level =
        widget.overall["level"]?.toString() ?? "safe";

    final issues = List<String>.from(
      widget.overall["issues"] ?? const [],
    ).map(_strings.statusText).toList();

    final safeSummary = List<String>.from(
      widget.overall["safeSummary"] ?? const [],
    ).map(_strings.statusText).toList();

    final allLines = issues.isNotEmpty ? issues : safeSummary;

    final firstLine = allLines.isNotEmpty
        ? allLines.first
        : _strings.t("Chưa có dữ liệu trạng thái");

    final rotatingLines = allLines.length > 1
        ? allLines.skip(1).toList()
        : <String>[];

    final secondLine = rotatingLines.isNotEmpty
        ? rotatingLines[
    _broadcastIndex % rotatingLines.length
    ]
        : _strings.t("Hệ thống đang giám sát liên tục");

    final statusColor = _statusColor(level);
    final statusIcon = _statusIcon(level);
    final statusText = _statusText(level);

    final rawAlarmScheduleText =
    widget.alarmEnabled &&
        widget.alarmStart.trim().isNotEmpty &&
        widget.alarmStart != "Tắt"
        ? widget.alarmStart
        : "Tắt";

    final alarmScheduleSet = rawAlarmScheduleText != "Tắt";
    final alarmScheduleText = alarmScheduleSet
        ? rawAlarmScheduleText
        : _strings.t("Tắt");
    final alarmPauseSet =
        widget.alarmPauseText.trim().isNotEmpty &&
            widget.alarmPauseText != "Tắt";

    final recentEvents = _sortedRecentEvents();
    final eventCounts = _eventCounts(recentEvents);

    final openCount = eventCounts["open"] ?? 0;
    final smokeCount = eventCounts["smoke"] ?? 0;
    final sosCount = eventCounts["sos"] ?? 0;

    String subtitle;

    if (issues.isNotEmpty) {
      subtitle = _strings.choose(
        vi: "Phát hiện ${issues.length} vấn đề cần xử lý",
        en: "${issues.length} issues detected",
      );
    } else if (smokeCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo khói");
    } else if (sosCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo SOS");
    } else if (openCount > 0) {
      subtitle = _strings.choose(
        vi: "Hôm nay các cửa đã được sử dụng $openCount lần",
        en: "Doors were used $openCount times today",
      );
    } else if (recentEvents.isNotEmpty) {
      subtitle = _strings.choose(
        vi: "Đã ghi nhận ${recentEvents.length} hoạt động gần đây",
        en: "${recentEvents.length} recent activities recorded",
      );
    } else {
      subtitle = _strings.t("Ngôi nhà đang hoạt động ổn định");
    }

    final environment = widget.environmentText
        .replaceAll("/", " | ")
        .replaceAll("  ", " ")
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatusSummary(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              14,
              11,
              14,
              10,
            ),
            decoration: BoxDecoration(
              color: SafeHomeColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.11),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 19,
                    ),
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
                    InkWell(
                      onTap: widget.onEnvironmentTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 3,
                        ),
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
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
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
                const SizedBox(height: 5),
                _statusLine(
                  text: firstLine,
                  color: issues.isNotEmpty
                      ? statusColor
                      : SafeHomeColors.textSecondary,
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Row(
                    key: ValueKey(secondLine),
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
                          "$secondLine... →",
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
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _alarmStatusItem(
                        icon: Icons.shield_rounded,
                        value: widget.securityMode == "armed"
                            ? "Bảo vệ"
                            : "Bình thường",
                        active: widget.securityMode == "armed",
                        activeColor: SafeHomeColors.danger,
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
                            ? widget.alarmPauseText
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
          ),
        ),
      ),
    );
  }

  Widget _alarmStatusItem({
    required IconData icon,
    required String value,
    required bool active,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    final color = active
        ? activeColor
        : SafeHomeColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 5,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.9,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusLine({
    Key? key,
    required String text,
    required Color color,
  }) {
    return Row(
      key: key,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.15,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
