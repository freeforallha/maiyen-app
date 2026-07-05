import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../pages/home/home_data_helpers.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';

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
  final bool alarmEnabled;
  final ValueChanged<bool>? onAlarmEnabledChanged;

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
    if (level == "no_data") {
      return SafeHomeColors.textSecondary;
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

  List<String> _buildAutomaticSummary({
    required Map<String, dynamic> overall,
    required List<String> dangerIssues,
    required List<String> warningIssues,
    required List<Map<String, dynamic>> recentEvents,
    required Map<String, int> eventCounts,
  }) {
    final hasDevices = overall["hasDevices"] == true;

    if (!hasDevices) {
      return [
        _strings.choose(
          vi: "Chưa có dữ liệu để đánh giá",
          en: "Not enough data to evaluate",
        ),
      ];
    }
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
        _strings.t("Nhà đang hoạt động ổn định, bạn có thể yên tâm."),
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

      final hasSmokeDevice = overall["hasSmokeDevice"] == true;

      final hasSosDevice = overall["hasSosDevice"] == true;

      if (hasSmokeDevice && smokeCount == 0) {
        summary.add(
          _strings.choose(
            vi: "Cảm biến khói chưa ghi nhận bất thường.",
            en: "The smoke sensor has not detected an issue.",
          ),
        );
      }

      if (hasSosDevice && sosCount == 0) {
        summary.add(
          _strings.choose(
            vi: "Thiết bị SOS chưa ghi nhận cảnh báo.",
            en: "The SOS device has not recorded an alert.",
          ),
        );
      }
    }

    if (summary.length == 1) {
      summary.add(
        _strings.t("Chưa có nhiều hoạt động mới để phân tích sâu hơn."),
      );
    }

    return summary;
  }

  void _showSecurityModeOptions(BuildContext context) {
    final isArmed = widget.securityMode == "armed";
    final allowedRepeatMinutes = <int>[0, 15, 30, 60];
    var localRepeatMinutes =
        allowedRepeatMinutes.contains(widget.securityModeRepeatMinutes)
        ? widget.securityModeRepeatMinutes
        : 0;
    var repeatSaving = false;

    String repeatText(int minutes) {
      return minutes == 0
          ? _strings.choose(vi: "Không lặp lại", en: "Do not repeat", zh: "不重复")
          : _strings.choose(
              vi: "Lặp sau $minutes phút",
              en: "Repeat after $minutes minutes",
              zh: "$minutes 分钟后重复",
            );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      _strings.choose(
                        vi: "Chế độ nhà",
                        en: "Home mode",
                        zh: "家庭模式",
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SafeHomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: _strings.choose(
                        vi: "Bình thường",
                        en: "Normal",
                        zh: "普通模式",
                      ),
                      subtitle: isArmed
                          ? _strings.choose(
                              vi: "Chuyển về sử dụng thông thường",
                              en: "Switch back to normal use",
                              zh: "切换回普通模式",
                            )
                          : _strings.choose(
                              vi: "Đang được sử dụng",
                              en: "Currently active",
                              zh: "当前使用中",
                            ),
                      color: SafeHomeColors.safe,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call("normal");
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: _strings.choose(
                        vi: "Bảo vệ",
                        en: "Guard",
                        zh: "布防",
                      ),
                      subtitle: isArmed
                          ? _strings.choose(
                              vi: "Đang dùng • ${repeatText(localRepeatMinutes)}",
                              en: "Active • ${repeatText(localRepeatMinutes)}",
                              zh: "使用中 • ${repeatText(localRepeatMinutes)}",
                            )
                          : _strings.choose(
                              vi: "Giám sát an ninh • ${repeatText(localRepeatMinutes)}",
                              en: "Security monitoring • ${repeatText(localRepeatMinutes)}",
                              zh: "安全监测 • ${repeatText(localRepeatMinutes)}",
                            ),
                      color: SafeHomeColors.danger,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call("armed");
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: SafeHomeColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.repeat_rounded,
                                size: 19,
                                color: SafeHomeColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _strings.choose(
                                    vi: "Lặp báo động khi sự cố vẫn còn",
                                    en: "Repeat Alarm while the issue remains",
                                    zh: "问题仍存在时重复 Alarm",
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: SafeHomeColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _strings.choose(
                              vi: "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.",
                              en: "Choose 0 to alert once. This setting applies to manual Guard mode and Auto Guard when away.",
                              zh: "选择 0 表示只提醒一次。此设置同时用于手动布防和离家自动布防。",
                            ),
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: SafeHomeColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: ValueKey<int>(localRepeatMinutes),
                            initialValue: localRepeatMinutes,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: SafeHomeColors.primary,
                            ),
                            decoration: InputDecoration(
                              labelText: _strings.choose(
                                vi: "Thời gian lặp",
                                en: "Repeat interval",
                                zh: "重复间隔",
                              ),
                              labelStyle: const TextStyle(
                                color: SafeHomeColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              prefixIcon: const Icon(
                                Icons.schedule_rounded,
                                color: SafeHomeColors.primary,
                              ),
                              suffixIcon: repeatSaving
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : null,
                              filled: true,
                              fillColor: SafeHomeColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: SafeHomeColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: SafeHomeColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: SafeHomeColors.border,
                                ),
                              ),
                            ),
                            items: allowedRepeatMinutes
                                .map(
                                  (minutes) => DropdownMenuItem<int>(
                                    value: minutes,
                                    child: Text(
                                      minutes == 0
                                          ? _strings.choose(
                                              vi: "Không lặp lại",
                                              en: "Do not repeat",
                                              zh: "不重复",
                                            )
                                          : _strings.choose(
                                              vi: "$minutes phút",
                                              en: "$minutes minutes",
                                              zh: "$minutes 分钟",
                                            ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: SafeHomeColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged:
                                widget.onSecurityModeRepeatChanged == null ||
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

                                    final saved = await widget
                                        .onSecurityModeRepeatChanged!(minutes);

                                    if (!sheetContext.mounted) {
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
                        ],
                      ),
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
            border: Border.all(color: SafeHomeColors.border),
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
                child: Icon(icon, color: color, size: 21),
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
    showModalBottomSheet<void>(
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
                Flexible(child: _buildLiveStatusSummaryList()),
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

  Widget _buildLiveStatusSummaryList() {
    final ownerStream = _sharedOwnerUidStream();

    if (ownerStream == null) {
      return _buildOwnerHomeStream(_fallbackOwnerUid());
    }

    return StreamBuilder<DatabaseEvent>(
      stream: ownerStream,
      builder: (context, ownerSnapshot) {
        final sharedOwnerUid =
            ownerSnapshot.data?.snapshot.value?.toString().trim() ?? "";
        final resolvedOwnerUid = sharedOwnerUid.isNotEmpty
            ? sharedOwnerUid
            : _fallbackOwnerUid();

        return _buildOwnerHomeStream(resolvedOwnerUid);
      },
    );
  }

  Widget _buildOwnerHomeStream(String ownerUid) {
    final cleanOwnerUid = ownerUid.trim();
    final cleanHomeId = widget.homeId.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return _summaryMessage(
        icon: Icons.home_work_outlined,
        text: _strings.t("Chưa có dữ liệu trạng thái"),
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
            text: _strings.loading,
          );
        }

        if (snapshot.hasError) {
          return _summaryMessage(
            icon: Icons.cloud_off_rounded,
            text: _strings.t("Chưa có dữ liệu trạng thái"),
          );
        }

        final liveHome = safeMap(snapshot.data?.snapshot.value);

        if (liveHome.isEmpty) {
          return _summaryMessage(
            icon: Icons.home_work_outlined,
            text: _strings.t("Chưa có dữ liệu trạng thái"),
          );
        }

        return _buildStatusSummarySections(liveHome);
      },
    );
  }

  Widget _buildStatusSummarySections(Map<String, dynamic> liveHome) {
    final liveOverall = getHomeOverallStatus(liveHome);
    final liveEvents = safeMap(liveHome["events"]);

    final dangerIssues = List<String>.from(
      liveOverall["dangerIssues"] ?? const [],
    ).map(_strings.statusText).toList();

    final warningIssues = List<String>.from(
      liveOverall["warningIssues"] ?? const [],
    ).map(_strings.statusText).toList();

    final safeSummary = List<String>.from(
      liveOverall["safeSummary"] ?? const [],
    ).map(_strings.statusText).toList();

    final recentEvents = _sortedRecentEvents(liveEvents);
    final eventCounts = _eventCounts(recentEvents);

    final automaticSummary = _buildAutomaticSummary(
      overall: liveOverall,
      dangerIssues: dangerIssues,
      warningIssues: warningIssues,
      recentEvents: recentEvents,
      eventCounts: eventCounts,
    );

    final liveSecurityMode =
        normalizeSecurityMode(liveHome["securityMode"]) == "armed"
        ? _strings.choose(vi: "Bảo vệ", en: "Guard", zh: "布防")
        : _strings.choose(vi: "Bình thường", en: "Normal", zh: "普通模式");

    final devices = safeMap(liveHome["devices"]);
    final overviewItems = <String>[
      _strings.choose(
        vi: "Chế độ nhà: $liveSecurityMode",
        en: "Home mode: $liveSecurityMode",
        zh: "家庭模式：$liveSecurityMode",
      ),
      if (liveOverall["hasEnvironmentDevice"] == true)
        _strings.statusText(
          "Môi trường hiện tại: ${HomeDataHelpers.getHomeEnvironmentText(devices: devices)}",
        ),
      ...safeSummary,
    ];

    return ListView(
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
          items: overviewItems.isEmpty
              ? [_strings.t("Chưa có dữ liệu tổng quan")]
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

  @override
  Widget build(BuildContext context) {
    final level = widget.overall["level"]?.toString() ?? "no_data";

    final hasDevices = widget.overall["hasDevices"] == true;

    final noData = level == "no_data" || !hasDevices;

    final issues = List<String>.from(widget.overall["issues"] ?? const []);

    final safeSummary = List<String>.from(
      widget.overall["safeSummary"] ?? const [],
    );

    final allLines = issues.isNotEmpty ? issues : safeSummary;

    final manualSecurityMode =
        widget.securityMode == "armed" && widget.securityModeSource == "manual";

    final manualSecurityModeText = _strings.choose(
      vi: "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường",
      en: "Manual Guard mode is on - switch to Normal to turn it off",
      zh: "手动布防已开启 - 切换到普通模式后关闭",
    );

    final normalFirstLine = allLines.isNotEmpty
        ? allLines.first
        : _strings.choose(
            vi: "Chưa có dữ liệu trạng thái",
            en: "No status data available",
            zh: "暂无状态数据",
          );

    final firstLine = noData
        ? _strings.choose(
            vi: "Chưa có dữ liệu để đánh giá",
            en: "Not enough data to evaluate",
            zh: "暂无足够数据可评估",
          )
        : manualSecurityMode
        ? manualSecurityModeText
        : normalFirstLine;

    final rotatingLines = noData
        ? <String>[]
        : manualSecurityMode
        ? allLines
        : allLines.length > 1
        ? allLines.skip(1).toList()
        : <String>[];

    final secondLine = rotatingLines.isNotEmpty
        ? rotatingLines[_broadcastIndex % rotatingLines.length]
        : _strings.t("Bấm vào để xem chi tiết");
    final displayFirstLine = _strings.statusText(firstLine);
    final displaySecondLine = _strings.statusText(secondLine);

    final statusColor = _statusColor(level);
    final statusIcon = _statusIcon(level);
    final statusText = _statusText(level);

    final rawAlarmScheduleText =
        widget.alarmEnabled &&
            widget.alarmStart.trim().isNotEmpty &&
            widget.alarmStart != "Tắt"
        ? widget.alarmStart.trim()
        : "";

    final alarmScheduleSet = rawAlarmScheduleText.isNotEmpty;

    final alarmScheduleText = alarmScheduleSet
        ? rawAlarmScheduleText
        : _strings.t("Tắt");

    final alarmPauseSet =
        widget.alarmPauseText.trim().isNotEmpty &&
        widget.alarmPauseText != "Tắt" &&
        widget.alarmPauseText != "Chưa thiết lập";

    final recentEvents = _sortedRecentEvents();
    final eventCounts = _eventCounts(recentEvents);

    final openCount = eventCounts["open"] ?? 0;
    final smokeCount = eventCounts["smoke"] ?? 0;
    final sosCount = eventCounts["sos"] ?? 0;

    String subtitle;

    if (noData) {
      subtitle = "";
    } else if (issues.isNotEmpty) {
      subtitle = _strings.choose(
        vi: "Phát hiện ${issues.length} vấn đề cần xử lý",
        en: "${issues.length} issues need attention",
        zh: "发现 ${issues.length} 个问题需要处理",
      );
    } else if (smokeCount > 0) {
      subtitle = _strings.choose(
        vi: "Hôm nay đã ghi nhận cảnh báo khói",
        en: "A smoke alert was recorded today",
        zh: "今天已记录烟雾警报",
      );
    } else if (sosCount > 0) {
      subtitle = _strings.choose(
        vi: "Hôm nay đã ghi nhận cảnh báo SOS",
        en: "An SOS alert was recorded today",
        zh: "今天已记录 SOS 警报",
      );
    } else if (openCount > 0) {
      subtitle = _strings.choose(
        vi: "Hôm nay các cửa đã được sử dụng $openCount lần",
        en: "Doors were used $openCount times today",
        zh: "今天门已使用 $openCount 次",
      );
    } else if (recentEvents.isNotEmpty) {
      subtitle = _strings.choose(
        vi: "Đã ghi nhận ${recentEvents.length} hoạt động gần đây",
        en: "${recentEvents.length} recent activities recorded",
        zh: "已记录 ${recentEvents.length} 条近期活动",
      );
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: BoxDecoration(
              color: SafeHomeColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: statusColor.withValues(alpha: 0.11)),
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
                    if (environment.isNotEmpty)
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
                  text: displayFirstLine,
                  color: manualSecurityMode
                      ? SafeHomeColors.danger
                      : issues.isNotEmpty
                      ? statusColor
                      : SafeHomeColors.textSecondary,
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
                          "$displaySecondLine... →",
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
                            ? _strings.choose(
                                vi: "Bảo vệ",
                                en: "Guard",
                                zh: "布防",
                              )
                            : _strings.choose(
                                vi: "Bình thường",
                                en: "Normal",
                                zh: "普通模式",
                              ),
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
    final color = active ? activeColor : SafeHomeColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: color),
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

  Widget _statusLine({Key? key, required String text, required Color color}) {
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
