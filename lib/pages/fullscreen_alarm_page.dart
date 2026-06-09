import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/safe_home_app.dart';
import '../services/notification_service.dart';
class FullscreenAlarmPage extends StatefulWidget {
  final String title;
  final String body;
  final bool silentMode;
  final String alarmItemsJson;
  final String reminderItemsJson;
  const FullscreenAlarmPage({
    super.key,
    required this.title,
    required this.body,
    this.silentMode = false,
    this.reminderItemsJson = "",
    this.alarmItemsJson = "",
  });

  @override
  State<FullscreenAlarmPage> createState() => _FullscreenAlarmPageState();
}

class _FullscreenAlarmPageState extends State<FullscreenAlarmPage> {
  Timer? timer;
  int remainingSeconds = 600;

  final AudioPlayer alarmPlayer = AudioPlayer();

  bool get isReminder => widget.silentMode;
  bool get isSafeReminder => isReminder && widget.body.contains('ĐÃ AN TOÀN');

  @override
  @override
  void initState() {
    super.initState();

    if (widget.silentMode) {
      NotificationService.stopReminderNotification();
      startSilentTimer();
    } else {
      NotificationService.stopAlarmNotification();
      startAlarmSound();
    }
  }
  Widget _buildReminderUI(BuildContext context) {
    final bool safe = isSafeReminder;
    final issueMap = buildReminderIssueMap();
    final Color accent = safe ? Colors.green : Colors.orange;
    final Color bg1 = safe ? const Color(0xFFDDF7E8) : const Color(0xFFFFF3E0);
    final Color bg2 = safe ? const Color(0xFFF1FCF5) : const Color(0xFFFFFBF5);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg1,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg1, bg2, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Spacer(),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.14),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          safe ? "🏡" : "⚠️",
                          style: const TextStyle(fontSize: 46),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          safe ? "Nhà đã an toàn" : "Hãy kiểm tra lại",                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 8),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [


                              ...issueMap.entries.map(
                                    (entry) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      ...entry.value.map(
                                            (item) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            "- $item",
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Tự đóng sau ${formatRemainingTime()}",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text(
                        "KIỂM TRA NHÀ",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onPressed: () => openHome(context),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: closeReminder,
                    child: Text(
                      "ĐÓNG NHẮC NHỞ",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> startAlarmSound() async {
    await alarmPlayer.setReleaseMode(ReleaseMode.loop);
    await alarmPlayer.setVolume(1.0);
    await alarmPlayer.play(AssetSource('alarm.mp3'));
  }

  void startSilentTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds <= 1) {
        t.cancel();

        if (mounted) {
          SystemNavigator.pop();
        }

        return;
      }

      if (!mounted) return;

      setState(() {
        remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    alarmPlayer.stop();
    alarmPlayer.dispose();
    super.dispose();
  }

  String formatRemainingTime() {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Map<String, List<String>> buildReminderIssueMap() {
    if (isSafeReminder) {
      return {
        "SafeHome": ["Tất cả thiết bị đang ổn định"],
      };
    }

    final jsonText = widget.reminderItemsJson.trim();

    if (jsonText.isNotEmpty) {
      try {
        final List<dynamic> items = jsonDecode(jsonText);
        final Map<String, List<String>> result = {};

        for (final item in items) {
          if (item is! Map) continue;

          final homeName = item["homeName"]?.toString().trim();
          final reasonsRaw = item["reasons"];

          final reasons = reasonsRaw is List
              ? reasonsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .take(4)
              .toList()
              : <String>[];

          if (homeName != null && homeName.isNotEmpty) {
            result[homeName] = reasons.isEmpty
                ? ["Có mục cần kiểm tra"]
                : reasons;

            if (reasonsRaw is List && reasonsRaw.length > 4) {
              result[homeName]!.add("...");
            }
          }
        }

        if (result.isNotEmpty) return result;
      } catch (_) {
        // Nếu JSON lỗi thì fallback xuống body.
      }
    }

    final bodyText = widget.body
        .replaceAll("⚠️", "")
        .replaceAll("!", "")
        .replaceAll("CHƯA AN TOÀN", "")
        .replaceAll("ĐÃ AN TOÀN", "")
        .trim();

    final issues = bodyText
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(4)
        .toList();

    return {
      "Nhà": issues.isEmpty ? ["Có mục cần kiểm tra"] : issues,
    };
  }
  Map<String, List<String>> buildAlarmItems() {
    try {
      if (widget.alarmItemsJson.isEmpty) {
        return {};
      }

      final List<dynamic> items = jsonDecode(widget.alarmItemsJson);

      final Map<String, List<String>> result = {};

      for (final item in items) {
        final homeName = item["homeName"]?.toString() ?? "Nhà";
        final reason = item["reason"]?.toString() ?? "";

        result.putIfAbsent(homeName, () => []);

        if (!result[homeName]!.contains(reason)) {
          result[homeName]!.add(reason);
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }
  Map<String, String> buildNextAlarmMap() {
    try {
      if (widget.alarmItemsJson.isEmpty) {
        return {};
      }

      final List<dynamic> items = jsonDecode(widget.alarmItemsJson);

      final Map<String, String> result = {};

      for (final item in items) {
        final homeName = item["homeName"]?.toString() ?? "Nhà";
        final nextAlarm = item["nextAlarm"]?.toString() ?? "";

        if (nextAlarm.isNotEmpty) {
          result[homeName] = nextAlarm;
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }
  Future<void> stopAlarmSound() async {
    await alarmPlayer.stop();
    await localNotif.cancel(999999);
  }

  Future<void> openHome(BuildContext context) async {
    timer?.cancel();
    await stopAlarmSound();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthGate(),
      ),
          (route) => false,
    );
  }

  Future<void> closeReminder() async {
    timer?.cancel();
    await stopAlarmSound();
    SystemNavigator.pop();
  }

  Future<void> confirmStopAlarm(BuildContext context) async {
    if (widget.silentMode) {
      await closeReminder();
      return;
    }

    localNotif.cancel(999999);
    startAlarmSound();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Xác nhận tắt cảnh báo"),
          content: const Text(
            "Chỉ chủ nhà hoặc người có quyền mới nên tắt cảnh báo.\n\nBạn chắc chắn muốn tắt cảnh báo?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("HỦY"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("XÁC NHẬN"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    timer?.cancel();
    await stopAlarmSound();

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (isReminder) {
      return _buildReminderUI(context);
    }
    final Color bgColor = !isReminder
        ? const Color(0xFF7F1D1D)
        : isSafeReminder
        ? const Color(0xFF064E3B)
        : const Color(0xFF78350F);

    final Color cardColor = !isReminder
        ? const Color(0xFF991B1B)
        : isSafeReminder
        ? const Color(0xFF065F46)
        : const Color(0xFF92400E);

    final IconData icon = !isReminder
        ? Icons.crisis_alert_rounded
        : isSafeReminder
        ? Icons.verified_user_rounded
        : Icons.warning_amber_rounded;

    final String header = !isReminder
        ? "BÁO ĐỘNG KHẨN CẤP"
        : isSafeReminder
        ? "NHẮC NHỞ AN TOÀN"
        : "NHẮC NHỞ CẦN KIỂM TRA";

    final String mainTitle = !isReminder
        ? "SafeHome Alarm"
        : isSafeReminder
        ? "Nhà đã an toàn"
        : "Nhà chưa an toàn";

    final groupedItems = buildAlarmItems();
    final nextAlarmMap = buildNextAlarmMap();
    String repeatText;

    if (!isReminder && nextAlarmMap.isNotEmpty) {
      repeatText = "Nếu vấn đề không được xử lý, hệ thống sẽ tự động báo lại vào:\n\n${nextAlarmMap.entries.map((e) => "${e.key} → ${e.value}").join("\n")}";
    } else {
      repeatText = isReminder
          ? "Nếu vấn đề chưa được xử lý, nhắc nhở sẽ tiếp tục hiện lại theo lịch đã cài."
          : "Nếu vấn đề chưa được xử lý, cảnh báo sẽ tiếp tục hiện lại theo lịch đã cài.";
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        header,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        mainTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.fact_check_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Cần kiểm tra nhanh",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (groupedItems.isNotEmpty)
                              ...groupedItems.entries.map(
                                    (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      ...entry.value.map(
                                            (reason) => Padding(
                                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                                          child: Text(
                                            "• $reason",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...groupedItems.entries.expand(
                                    (entry) => entry.value.map(
                                      (reason) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      reason,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.repeat_rounded,
                              color: Colors.white70,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                repeatText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isReminder) ...[
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Tự đóng sau ${formatRemainingTime()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      "KIỂM TRA NHÀ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: () => openHome(context),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: Icon(
                    isReminder
                        ? Icons.close_rounded
                        : Icons.power_settings_new_rounded,
                    size: 19,
                  ),
                  label: Text(
                    isReminder ? "ĐÓNG NHẮC NHỞ" : "TẮT CẢNH BÁO",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => confirmStopAlarm(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}