import 'dart:async';
import 'package:flutter/material.dart';
import '../helpers/home_helper.dart';

class StatusPanel extends StatefulWidget {
  final Map<String, dynamic> overall;
  final VoidCallback? onPair;
  final VoidCallback? onQR;
  final String alarmStart;
  final String alarmEnd;
  final String environmentText;
  final Map<String, dynamic> homeEvents;
  final VoidCallback? onEnvironmentTap;

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
  int _broadcastIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _broadcastIndex++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showStatusSummary(BuildContext context) {
    final dangerIssues =
    List<String>.from(widget.overall["dangerIssues"] ?? const []);
    final warningIssues =
    List<String>.from(widget.overall["warningIssues"] ?? const []);
    final safeSummary =
    List<String>.from(widget.overall["safeSummary"] ?? const []);
    final events = widget.homeEvents.values
        .map((e) => safeMap(e))
        .toList();

    events.sort((a, b) {
      final ta = int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
      final tb = int.tryParse(b["time"]?.toString() ?? "0") ?? 0;
      return tb.compareTo(ta);
    });
    final recentEvents = events.take(20).toList();

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

    final aiSummary = <String>[];

    if (dangerIssues.isNotEmpty || warningIssues.isNotEmpty) {
      aiSummary.add("Nhà đang có dấu hiệu cần kiểm tra, bạn nên cẩn thận xem lại .");

      if (dangerIssues.isNotEmpty) {
        aiSummary.add("${dangerIssues.length} vấn đề đang cần xử lý ngay.");
      }

      if (warningIssues.isNotEmpty) {
        aiSummary.add("${warningIssues.length} dấu hiệu nên được kiểm tra thêm.");
      }

      if (openCount > 0) {
        aiSummary.add("Gần đây cửa đã được mở $openCount lần.");
      }
    } else {
      aiSummary.add("Nhà đang ổn, bạn có thể yên tâm.");

      if (recentEvents.isNotEmpty) {
        aiSummary.add("Hôm nay có ${recentEvents.length} hoạt động được ghi nhận.");
      }

      if (openCount > 0) {
        aiSummary.add("Cửa được sử dụng $openCount lần gần đây.");
      }

      if (smokeCount == 0 && sosCount == 0) {
        aiSummary.add("Không có dấu hiệu khói hoặc SOS bất thường.");
      }
    }

    if (aiSummary.length == 1) {
      aiSummary.add("Chưa có nhiều hoạt động mới để phân tích sâu hơn.");
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tổng hợp trạng thái nhà",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                if (dangerIssues.isNotEmpty) ...[
                  _sectionTitle("Cần xử lý ngay", Colors.red),
                  ...dangerIssues.map((e) => _issueRow(e, Colors.red)),
                  const SizedBox(height: 12),
                ],
                if (warningIssues.isNotEmpty) ...[
                  _sectionTitle("Cần kiểm tra", Colors.orange),
                  ...warningIssues.map((e) => _issueRow(e, Colors.orange)),
                  const SizedBox(height: 12),
                ],
                _sectionTitle("🤖 Đánh giá tự động", Colors.blue),

                ...aiSummary.map(
                      (e) => _issueRow(e, Colors.blue),
                ),

                const SizedBox(height: 12),

                _sectionTitle("📊 Tổng quan hôm nay", Colors.green),

                ...safeSummary.map(
                      (e) => _issueRow(e, Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  static Widget _issueRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.overall["level"]?.toString() ?? "safe";
    final issues = List<String>.from(widget.overall["issues"] ?? const []);
    final safeSummary =
    List<String>.from(widget.overall["safeSummary"] ?? const []);

    final allLines = issues.isNotEmpty ? issues : safeSummary;
    final firstLine = allLines.isNotEmpty ? allLines.first : "Chưa có dữ liệu";
    final rotatingLines = allLines.length > 1 ? allLines.skip(1).toList() : [];
    final secondLine = rotatingLines.isNotEmpty
        ? rotatingLines[_broadcastIndex % rotatingLines.length]
        : "Bấm vào để xem chi tiết";

    final isDanger = level == "danger";
    final isWarning = level == "warning";

    final statusColor = isDanger
        ? Colors.red.shade500
        : isWarning
        ? Colors.orange.shade500
        : Colors.green.shade500;

    final statusText = isDanger
        ? "CHƯA AN TOÀN"
        : isWarning
        ? "CẦN CHÚ Ý"
        : "ĐÃ AN TOÀN";

    final statusIcon = isDanger
        ? Icons.warning_rounded
        : isWarning
        ? Icons.info_rounded
        : Icons.verified_rounded;
    final alarmPauseSet = widget.alarmPauseText != "Chưa thiết lập";
    final alarmPauseColor = alarmPauseSet ? Colors.orange.shade700 : Colors.black54;
    final events = widget.homeEvents.values
        .map((e) => safeMap(e))
        .toList();

    events.sort((a, b) {
      final ta = int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
      final tb = int.tryParse(b["time"]?.toString() ?? "0") ?? 0;
      return tb.compareTo(ta);
    });

    final recentEvents = events.take(20).toList();

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

    String subtitle;

    if (issues.isNotEmpty) {
      subtitle = "Phát hiện ${issues.length} vấn đề cần xử lý";
    } else if (smokeCount > 0) {
      subtitle = "Hôm nay đã ghi nhận cảnh báo khói";
    } else if (sosCount > 0) {
      subtitle = "Hôm nay đã ghi nhận cảnh báo SOS";
    } else if (openCount > 0) {
      subtitle = "Hôm nay các cửa đã được sử dụng $openCount lần";
    } else if (recentEvents.isNotEmpty) {
      subtitle = "Đã ghi nhận ${recentEvents.length} hoạt động gần đây";
    } else {
      subtitle = "Ngôi nhà đang hoạt động ổn định";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => _showStatusSummary(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 23),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onEnvironmentTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Text(
                      "🌡 ${widget.environmentText.replaceAll("/", "|")}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onAlarmPauseToday,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Tạm dừng Alarm : ${widget.alarmPauseText}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: alarmPauseColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: issues.isNotEmpty
                            ? statusColor
                            : Colors.black54,
                      ),
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 7),
              _line(firstLine, issues.isNotEmpty),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: _line(
                        secondLine,
                        issues.isNotEmpty,
                        key: ValueKey(secondLine),
                      ),
                    ),
                  ),

                  Text(
                    "Chi tiết",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w800,
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

  Widget _line(String text, bool hasIssue, {Key? key}) {
    final level = widget.overall["level"]?.toString() ?? "safe";

    final color = level == "danger"
        ? Colors.red.shade500
        : level == "warning"
        ? Colors.orange.shade500
        : Colors.black54;

    return Text(
      "• $text",
      key: key,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 12,
        height: 1.25,
        color: hasIssue ? color : Colors.black54,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}