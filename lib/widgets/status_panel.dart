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

  List<String> _buildActionSuggestions({
    required AppStrings strings,
    required Map<String, dynamic> liveHome,
    required Map<String, dynamic> overall,
    required List<String> rawDangerIssues,
    required List<String> rawWarningIssues,
    required List<String> rawSafeSummary,
  }) {
    final hasDevices = overall["hasDevices"] == true;

    if (!hasDevices) {
      return [
        strings.choose(
          vi: "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.",
          en: "Add your first SafeHome device to start monitoring this home.",
          zh: "请先添加第一个 SafeHome 设备以开始监控家庭。",
          ko: "집 상태를 확인하려면 먼저 SafeHome 기기를 추가하세요.",
          ja: "家の見守りを始めるには、まず SafeHome デバイスを追加してください。",
        ),
      ];
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

    final rawDangerText = rawDangerIssues.join("\n").toLowerCase();
    final rawWarningText = rawWarningIssues.join("\n").toLowerCase();
    final rawSafeText = rawSafeSummary.join("\n").toLowerCase();
    final allRawText = "$rawDangerText\n$rawWarningText\n$rawSafeText";

    final hasEmergencyIssue = containsAny(
      rawDangerText,
      const [
        "sos",
        "có khói",
        "rò rỉ gas",
        "phát hiện khí co",
        "phát hiện ngập nước",
        "nhiệt độ nguy hiểm",
      ],
    );

    final hasOpenIssue = containsAny(
      "$rawDangerText\n$rawWarningText",
      const [
        "đang mở",
        "khóa đang mở",
      ],
    );

    final hasArmedOpenIssue = containsAny(
      rawDangerText,
      const [
        "đang mở khi nhà ở chế độ bảo vệ",
        "khóa đang mở khi nhà ở chế độ bảo vệ",
        "đang mở trong giờ alarm",
        "khóa đang mở trong giờ alarm",
      ],
    );

    final hasUnknownMemberLocation = containsAny(
      rawWarningText,
      const [
        "chưa xác định vị trí",
      ],
    );

    final hasDisconnectedDevice = containsAny(
      rawWarningText,
      const [
        "mất kết nối",
      ],
    );

    final hasLowBatteryDevice = containsAny(
      rawWarningText,
      const [
        "pin yếu",
      ],
    );

    final noMemberInside = RegExp(
      r"thành viên trong nhà:\s*0/",
    ).hasMatch(allRawText);

    final hasMemberInside = RegExp(
      r"thành viên trong nhà:\s*[1-9][0-9]*/",
    ).hasMatch(allRawText);

    final isArmed =
        normalizeSecurityMode(liveHome["securityMode"]) == "armed";

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
      addSuggestion(
        strings.choose(
          vi: "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.",
          en: "Check emergency alerts first, then contact household members if needed.",
          zh: "请先检查紧急警报，必要时联系家中成员。",
          ko: "긴급 경보를 먼저 확인하고, 필요하면 가족 구성원에게 연락하세요.",
          ja: "まず緊急アラートを確認し、必要なら家のメンバーに連絡してください。",
        ),
      );
    }

    if (hasOpenIssue && noMemberInside) {
      addSuggestion(
        strings.choose(
          vi: "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.",
          en: "No household member is home but a door or lock is open. Check it now.",
          zh: "家中没有成员，但门或锁处于打开状态，请立即检查。",
          ko: "집에 사람이 없는데 문이나 잠금장치가 열려 있습니다. 바로 확인하세요.",
          ja: "家に誰もいないのにドアまたは鍵が開いています。すぐ確認してください。",
        ),
      );
    }

    if (hasArmedOpenIssue) {
      addSuggestion(
        strings.choose(
          vi: "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.",
          en: "Check the open door or lock before keeping this home in Guard mode.",
          zh: "在保持防护模式前，请先检查打开的门或锁。",
          ko: "보호 모드를 유지하기 전에 열린 문이나 잠금장치를 먼저 확인하세요.",
          ja: "保護モードを維持する前に、開いているドアや鍵を確認してください。",
        ),
      );
    }

    if (isArmed && hasMemberInside) {
      addSuggestion(
        strings.choose(
          vi: "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.",
          en: "Someone may still be home. If so, switch back to Normal mode.",
          zh: "可能仍有人在家；如果属实，建议切回普通模式。",
          ko: "아직 집에 사람이 있을 수 있습니다. 그렇다면 일반 모드로 전환하세요.",
          ja: "まだ家に人がいる可能性があります。その場合は通常モードに戻してください。",
        ),
      );
    }

    if (hasUnknownMemberLocation) {
      addSuggestion(
        strings.choose(
          vi: "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.",
          en: "Some members have unknown location. Ask them to open the app or check location permission.",
          zh: "有成员位置未知，请提醒他们打开应用或检查定位权限。",
          ko: "위치를 알 수 없는 구성원이 있습니다. 앱을 열거나 위치 권한을 확인하도록 알려주세요.",
          ja: "位置が不明なメンバーがいます。アプリを開くか位置情報権限を確認してもらってください。",
        ),
      );
    }

    if (hasDisconnectedDevice) {
      addSuggestion(
        strings.choose(
          vi: "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.",
          en: "A device is disconnected. Check its battery, power, or placement.",
          zh: "有设备已断开连接，请检查电池、电源或摆放位置。",
          ko: "연결이 끊긴 기기가 있습니다. 배터리, 전원 또는 설치 위치를 확인하세요.",
          ja: "接続が切れているデバイスがあります。電池・電源・設置場所を確認してください。",
        ),
      );
    }

    if (hasLowBatteryDevice) {
      addSuggestion(
        strings.choose(
          vi: "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.",
          en: "A device has low battery. Replace it soon to avoid missed alerts.",
          zh: "有设备电量低，建议尽快更换电池以避免漏报。",
          ko: "배터리가 부족한 기기가 있습니다. 경보 누락을 막기 위해 빨리 교체하세요.",
          ja: "電池残量が少ないデバイスがあります。アラートを逃さないよう早めに交換してください。",
        ),
      );
    }

    if (!hasReminderSchedule) {
      addSuggestion(
        strings.choose(
          vi: "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.",
          en: "Reminder is not set. Create a schedule to check your home regularly.",
          zh: "尚未设置提醒，建议创建定期检查家庭的提醒。",
          ko: "리마인더가 설정되어 있지 않습니다. 집을 정기적으로 확인할 일정을 만들어 보세요.",
          ja: "リマインダーが未設定です。定期的に家を確認する予定を作成してください。",
        ),
      );
    }

    if (!hasAlarmSchedule) {
      addSuggestion(
        strings.choose(
          vi: "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.",
          en: "Alarm schedule is not set. Enable protection for times you are usually away.",
          zh: "尚未设置警报时间，建议在经常不在家的时段启用防护。",
          ko: "알람 일정이 설정되어 있지 않습니다. 자주 집을 비우는 시간대에 보호를 켜세요.",
          ja: "アラーム予定が未設定です。普段不在の時間帯に保護を有効にしてください。",
        ),
      );
    }

    if (suggestions.isEmpty) {
      addSuggestion(
        strings.choose(
          vi: "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.",
          en: "No immediate action is needed. Keep monitoring this home.",
          zh: "目前没有需要立即处理的事项，请继续关注家庭状态。",
          ko: "즉시 처리할 일은 없습니다. 집 상태를 계속 확인하세요.",
          ja: "すぐ対応が必要な項目はありません。家の状態を引き続き確認してください。",
        ),
      );
    }

    return suggestions;
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
          ? _strings.t("Không lặp lại")
          : _strings.choose(
              vi: "Lặp sau $minutes phút",
              en: "Repeat after $minutes minutes",
              zh: "$minutes 分钟后重复",
              ko: "$minutes분 후 반복",
              ja: "$minutes 分後に繰り返し",
            );
    }

    showModalBottomSheet<void>(
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
                      _strings.t("Chế độ nhà"),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: SafeHomeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: _strings.t("Bình thường"),
                      subtitle: isArmed
                          ? _strings.t("Chuyển về sử dụng thông thường")
                          : _strings.t("Đang được sử dụng"),
                      color: SafeHomeColors.safe,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call("normal");
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: _strings.t("Bảo vệ"),
                      subtitle: isArmed
                          ? _strings.choose(
                              vi: "Đang dùng • ${repeatText(localRepeatMinutes)}",
                              en: "Active • ${repeatText(localRepeatMinutes)}",
                              zh: "使用中 • ${repeatText(localRepeatMinutes)}",
                              ko: "사용 중 • ${repeatText(localRepeatMinutes)}",
                              ja: "有効 • ${repeatText(localRepeatMinutes)}",
                            )
                          : _strings.choose(
                              vi: "Giám sát an ninh • ${repeatText(localRepeatMinutes)}",
                              en: "Security monitoring • ${repeatText(localRepeatMinutes)}",
                              zh: "安全监测 • ${repeatText(localRepeatMinutes)}",
                              ko: "보안 모니터링 • ${repeatText(localRepeatMinutes)}",
                              ja: "セキュリティ監視 • ${repeatText(localRepeatMinutes)}",
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
                                  _strings.t("Lặp báo động khi sự cố vẫn còn"),
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
                            _strings.t("Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà."),
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
                              labelText: _strings.t("Thời gian lặp"),
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
                                          ? _strings.t("Không lặp lại")
                                          : _strings.choose(
                                              vi: "$minutes phút",
                                              en: "$minutes minutes",
                                              zh: "$minutes 分钟",
                                              ko: "$minutes분",
                                              ja: "$minutes 分",
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
    if (!mounted) {
      return;
    }

    final strings = AppStrings.of(context);

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
    final liveEvents = safeMap(liveHome["events"]);

    final rawDangerIssues = List<String>.from(
      liveOverall["dangerIssues"] ?? const [],
    );

    final rawWarningIssues = List<String>.from(
      liveOverall["warningIssues"] ?? const [],
    );

    final dangerIssues = rawDangerIssues.map(strings.statusText).toList();

    final warningIssues = rawWarningIssues.map(strings.statusText).toList();

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
      rawDangerIssues: rawDangerIssues,
      rawWarningIssues: rawWarningIssues,
      rawSafeSummary: rawSafeSummary,
    );

    final liveSecurityMode =
        normalizeSecurityMode(liveHome["securityMode"]) == "armed"
        ? strings.t("Bảo vệ")
        : strings.t("Bình thường");

    final devices = safeMap(liveHome["devices"]);
    final environmentLine = _overviewEnvironmentLine(
      liveOverall: liveOverall,
      devices: devices,
      strings: strings,
    );
    final overviewItems = <String>[
      strings.choose(
        vi: "Gia đình: $liveSecurityMode",
        en: "Home mode: $liveSecurityMode",
        zh: "家庭模式：$liveSecurityMode",
        ko: "집 모드: $liveSecurityMode",
        ja: "家のモード: $liveSecurityMode",
      ),
      if (environmentLine.isNotEmpty) environmentLine,
      ...safeSummary,
    ];

    return ListView(
      shrinkWrap: true,
      children: [
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
          title: strings.choose(
            vi: "Gợi ý xử lý",
            en: "Suggested actions",
            zh: "处理建议",
            ko: "처리 제안",
            ja: "対応の提案",
          ),
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

    final manualSecurityModeText = _strings.t("Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường");

    final normalFirstLine = allLines.isNotEmpty
        ? allLines.first
        : _strings.t("Chưa có dữ liệu trạng thái");

    final firstLine = noData
        ? _strings.t("Chưa đủ dữ liệu để đánh giá")
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
        : _strings.t("Nhấn để xem chi tiết...");
    final displayFirstLine = _strings.statusText(firstLine);
    final displaySecondLine = _strings.statusText(secondLine);
    final displaySecondLineWithHint =
        displaySecondLine.endsWith("...") || displaySecondLine.endsWith("…")
        ? "$displaySecondLine →"
        : "$displaySecondLine... →";

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
        ko: "${issues.length}개 문제를 처리해야 합니다",
        ja: "${issues.length} 件の問題に対応が必要です",
      );
    } else if (smokeCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo khói");
    } else if (sosCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo SOS");
    } else if (openCount > 0) {
      subtitle = _strings.choose(
        vi: "Hôm nay các cửa đã được sử dụng $openCount lần",
        en: "Doors were used $openCount times today",
        zh: "今天门被使用了 $openCount 次",
        ko: "오늘 문이 $openCount번 사용되었습니다",
        ja: "今日はドアが $openCount 回使用されました",
      );
    } else if (recentEvents.isNotEmpty) {
      subtitle = _strings.choose(
        vi: "Đã ghi nhận ${recentEvents.length} hoạt động gần đây",
        en: "${recentEvents.length} recent activities recorded",
        zh: "已记录 ${recentEvents.length} 条近期活动",
        ko: "최근 활동 ${recentEvents.length}개가 기록되었습니다",
        ja: "最近のアクティビティが ${recentEvents.length} 件記録されました",
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
                        icon: Icons.shield_rounded,
                        value: widget.securityMode == "armed"
                            ? _strings.t("Bảo vệ")
                            : _strings.t("Bình thường"),
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
