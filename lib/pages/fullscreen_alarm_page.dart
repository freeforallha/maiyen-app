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

  bool get isSafeReminder =>
      isReminder && widget.body.toUpperCase().contains("ĐÃ AN TOÀN");

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
        "SafeHome": ["Hãy an tâm nghỉ ngơi"],
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
            result[homeName] = reasons.isEmpty ? ["Có mục cần kiểm tra"] : reasons;

            if (reasonsRaw is List && reasonsRaw.length > 4) {
              result[homeName]!.add("...");
            }
          }
        }

        if (result.isNotEmpty) return result;
      } catch (_) {}
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

  List<Map<String, dynamic>> alarmItems() {
    try {
      final text = widget.alarmItemsJson.trim();
      if (text.isEmpty) return [];

      final decoded = jsonDecode(text);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String detectTypeFromText(String text) {
    final t = text.toLowerCase();

    if (t.contains("sos")) return "sos";
    if (t.contains("smoke") || t.contains("khói") || t.contains("cháy")) {
      return "smoke";
    }
    if (t.contains("flood") || t.contains("ngập") || t.contains("nước")) {
      return "flood";
    }
    if (t.contains("gas") || t.contains("khí")) return "gas";

    if (t.contains("door") ||
        t.contains("cửa") ||
        t.contains("window") ||
        t.contains("gate") ||
        t.contains("lock") ||
        t.contains("mở") ||
        t.contains("tháo")) {
      return "door";
    }

    return "security";
  }

  String alarmType() {
    final items = alarmItems();

    for (final item in items) {
      final type = item["type"]?.toString().trim().toLowerCase();

      if (type != null && type.isNotEmpty) {
        if (type == "sos") return "sos";
        if (type == "smoke") return "smoke";
        if (type == "flood") return "flood";
        if (type == "gas") return "gas";
        if (type == "door" ||
            type == "window" ||
            type == "gate" ||
            type == "lock") {
          return "door";
        }
      }
    }

    final allText = [
      widget.title,
      widget.body,
      widget.alarmItemsJson,
    ].join(" ");

    return detectTypeFromText(allText);
  }

  IconData alarmIcon(String type) {
    switch (type) {
      case "sos":
        return Icons.sos_rounded;
      case "smoke":
        return Icons.local_fire_department_rounded;
      case "flood":
        return Icons.water_drop_rounded;
      case "gas":
        return Icons.gas_meter_rounded;
      case "door":
        return Icons.sensor_door_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String alarmTitle(String type) {
    switch (type) {
      case "sos":
        return "CẢNH BÁO SOS";
      case "smoke":
        return "CẢNH BÁO KHÓI / CHÁY";
      case "flood":
        return "CẢNH BÁO NGẬP NƯỚC";
      case "gas":
        return "CẢNH BÁO RÒ KHÍ";
      case "door":
        return "CẢNH BÁO CỬA";
      default:
        return "CẢNH BÁO AN NINH";
    }
  }

  String fallbackReason(String type) {
    switch (type) {
      case "sos":
        return "Có nút SOS vừa được kích hoạt";
      case "smoke":
        return "Có dấu hiệu khói hoặc cháy";
      case "flood":
        return "Có dấu hiệu ngập nước";
      case "gas":
        return "Có dấu hiệu rò khí";
      case "door":
        return "Có cửa đang mở hoặc thiết bị bị tháo";
      default:
        return "Có thiết bị đang cảnh báo";
    }
  }

  Map<String, List<String>> buildAlarmIssueMap(String type) {
    final items = alarmItems();
    final Map<String, List<String>> result = {};

    for (final item in items) {
      final homeName = item["homeName"]?.toString().trim();
      final deviceName = item["deviceName"]?.toString().trim();
      final name = item["name"]?.toString().trim();
      final reason = item["reason"]?.toString().trim();

      final realHomeName =
      homeName == null || homeName.isEmpty ? "Nhà" : homeName;

      String text = "";

      if (deviceName != null && deviceName.isNotEmpty) {
        text = deviceName;
      } else if (name != null && name.isNotEmpty) {
        text = name;
      }

      if (reason != null && reason.isNotEmpty) {
        if (text.isEmpty) {
          text = reason;
        } else if (reason.toLowerCase().startsWith(text.toLowerCase())) {
          text = reason;
        } else {
          text = "$text: $reason";
        }
      }

      if (text.isEmpty) {
        text = fallbackReason(type);
      }

      result.putIfAbsent(realHomeName, () => []);

      if (!result[realHomeName]!.contains(text)) {
        result[realHomeName]!.add(text);
      }
    }

    if (result.isNotEmpty) return result;

    final body = widget.body.trim();
    if (body.isNotEmpty && body.length < 160) {
      return {
        "SafeHome": [body],
      };
    }

    return {
      "SafeHome": [fallbackReason(type)],
    };
  }

  Map<String, String> buildNextAlarmMap() {
    final Map<String, String> result = {};

    for (final item in alarmItems()) {
      final homeName = item["homeName"]?.toString().trim();
      final nextAlarm = item["nextAlarm"]?.toString().trim();

      if (nextAlarm == null || nextAlarm.isEmpty) continue;
      if (nextAlarm == "không lặp lại") continue;

      final key = homeName == null || homeName.isEmpty ? "SafeHome" : homeName;

      result[key] = nextAlarm;
    }

    return result;
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

    await localNotif.cancel(999999);
    await startAlarmSound();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("Xác nhận tắt cảnh báo"),
          content: const Text(
            "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?",
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

  Widget _buildReminderUI(BuildContext context) {
    final safe = isSafeReminder;
    final issueMap = buildReminderIssueMap();

    final Color accent = safe ? Colors.green : Colors.orange;
    final Color bg1 = safe
        ? const Color(0xFF0E2B1A)
        : const Color(0xFF3A2508);

    final Color bg2 = safe
        ? const Color(0xFF163824)
        : const Color(0xFF4A2D08);

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
                      color: Colors.white,
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
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accent.withValues(alpha: 0.22),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            safe
                                ? Icons.verified_user_rounded
                                : Icons.warning_amber_rounded,
                            color: accent,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          safe
                              ? "ĐÃ AN TOÀN"
                              : "CẦN KIỂM TRA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "SafeHome Security Reminder",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: issueMap.entries.map((entry) {
                              return Container(
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
                                          "• $item",
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
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
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

  Widget _buildAlarmUI(BuildContext context) {
    final type = alarmType();
    debugPrint("ALARM JSON = ${widget.alarmItemsJson}");
    final issueMap = buildAlarmIssueMap(type);
    final nextAlarmMap = buildNextAlarmMap();

    final repeatText = nextAlarmMap.isNotEmpty
        ? "Báo lại lúc ${nextAlarmMap.values.first} nếu vấn đề chưa được xử lý."
        : "Sẽ báo lại theo lịch alarm đã cài nếu vấn đề chưa được xử lý.";

    final Color bgColor = switch (type) {
      "sos" => const Color(0xFF3A0508),
      "smoke" => const Color(0xFF321006),
      "flood" => const Color(0xFF061B33),
      "gas" => const Color(0xFF2A1233),
      "door" => const Color(0xFF2A0A0A),
      _ => const Color(0xFF161616),
    };

    final Color accent = switch (type) {
      "sos" => const Color(0xFFE11D48),
      "smoke" => const Color(0xFFF97316),
      "flood" => const Color(0xFF0284C7),
      "gas" => const Color(0xFF9333EA),
      "door" => const Color(0xFFDC2626),
      _ => const Color(0xFFEF4444),
    };

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
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          alarmIcon(type),
                          color: accent,
                          size: 52,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        alarmTitle(type),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "SafeHome Security Alert",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.065),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: issueMap.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...entry.value.map(
                                        (reason) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: accent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              reason,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 16,
                                                height: 1.25,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              color: Colors.grey.shade700,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                repeatText,
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
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
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(
                    Icons.power_settings_new_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    "TẮT CẢNH BÁO",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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

  @override
  Widget build(BuildContext context) {
    if (isReminder) {
      return _buildReminderUI(context);
    }

    return _buildAlarmUI(context);
  }
}