import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/safe_home_app.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
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

  late String currentReminderTitle;
  late String currentReminderBody;
  late String currentReminderItemsJson;
  late String currentAlarmBody;
  late String currentAlarmItemsJson;
  bool get isReminder => widget.silentMode;

  bool get isSafeReminder {
    if (!isReminder) {
      return false;
    }

    try {
      final decoded = jsonDecode(currentReminderItemsJson.trim());

      if (decoded is List && decoded.isNotEmpty) {
        return decoded.whereType<Map>().every((item) {
          final reasons = item["reasons"];

          if (reasons is! List) {
            return true;
          }

          return reasons.every(
            (reason) => reason?.toString().trim().isEmpty ?? true,
          );
        });
      }
    } catch (_) {}

    return currentReminderBody.contains("✅") &&
        !currentReminderBody.contains("⚠️");
  }

  String get reminderHomeName {
    final raw = currentReminderTitle.trim();
    final lower = raw.toLowerCase();

    if (raw.isEmpty || lower.contains("safehome")) {
      return "";
    }

    return raw;
  }

  @override
  void initState() {
    super.initState();

    currentReminderTitle = widget.title;
    currentReminderBody = widget.body;
    currentReminderItemsJson = widget.reminderItemsJson;
    currentAlarmBody = widget.body;
    currentAlarmItemsJson = widget.alarmItemsJson;
    if (widget.silentMode) {
      _loadLatestReminderSession();

      NotificationService.reminderRevision.addListener(
        _onReminderSessionChanged,
      );

      // Không xoá notification khi Reminder tự mở fullscreen.
      startSilentTimer();
    } else {
      _loadLatestAlarmSession();

      NotificationService.alarmRevision.addListener(_onAlarmSessionChanged);

      NotificationService.alarmResolvedRevision.addListener(_onAlarmResolved);

      _startAlarmMode();
    }
  }

  Future<void> _startAlarmMode() async {
    // Fullscreen đã mở thì huỷ cả notification ban đầu
    // và notification mở toàn màn hình.
    await NotificationService.stopAllAlarmNotifications();

    if (!mounted) return;

    await startAlarmSound();
  }

  void _onAlarmResolved() {
    if (!mounted ||
        widget.silentMode ||
        NotificationService.hasActiveAlarmIncidents) {
      return;
    }

    unawaited(_closeResolvedAlarm());
  }

  Future<void> _closeResolvedAlarm() async {
    timer?.cancel();
    await stopAlarmSound();

    if (!mounted) return;

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showAlarmActionError() {
    if (!mounted) return;

    showTopToast(
      context,
      AppStrings.of(context).alarmActionErrorMessage(),
      color: Colors.red,
      icon: Icons.wifi_off_rounded,
    );
  }

  void _loadLatestReminderSession() {
    final latestTitle = NotificationService.lastScheduleTitle.trim();

    final latestBody = NotificationService.lastScheduleBody.trim();

    final latestItems = NotificationService.lastReminderItemsJson.trim();

    if (latestTitle.isNotEmpty) {
      currentReminderTitle = latestTitle;
    }

    if (latestBody.isNotEmpty) {
      currentReminderBody = latestBody;
    }

    if (latestItems.isNotEmpty) {
      currentReminderItemsJson = latestItems;
    }
  }

  void _onReminderSessionChanged() {
    if (!mounted || !widget.silentMode) return;

    setState(() {
      _loadLatestReminderSession();

      // Reminder mới tới thì tính lại 10 phút.
      remainingSeconds = 600;
    });
  }

  void _loadLatestAlarmSession() {
    final latestBody = NotificationService.lastAlarmBody.trim();

    final latestItems = NotificationService.lastAlarmItemsJson.trim();

    if (latestBody.isNotEmpty) {
      currentAlarmBody = latestBody;
    }

    if (latestItems.isNotEmpty) {
      currentAlarmItemsJson = latestItems;
    }
  }

  void _onAlarmSessionChanged() {
    if (!mounted || widget.silentMode) return;

    setState(() {
      _loadLatestAlarmSession();
    });
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
    if (widget.silentMode) {
      NotificationService.reminderRevision.removeListener(
        _onReminderSessionChanged,
      );

      NotificationService.markReminderPageClosed();
    } else {
      NotificationService.alarmRevision.removeListener(_onAlarmSessionChanged);

      NotificationService.alarmResolvedRevision.removeListener(
        _onAlarmResolved,
      );

      NotificationService.markAlarmPageClosed();
    }

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

  Map<String, List<String>> buildReminderIssueMap(AppStrings strings) {
    final Map<String, List<String>> result = {};

    try {
      final raw = currentReminderItemsJson.trim();

      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;

            final data = Map<String, dynamic>.from(item);

            final homeName =
                data["homeName"]?.toString().trim().isNotEmpty == true
                ? data["homeName"].toString().trim()
                : strings.defaultHomeName();

            final rawReasons = data["reasons"];
            final reasons = <String>[];

            if (rawReasons is List) {
              for (final reason in rawReasons) {
                final text = reason?.toString().trim() ?? "";
                final translatedText = strings.statusText(text);

                if (translatedText.isNotEmpty &&
                    !reasons.contains(translatedText)) {
                  reasons.add(translatedText);
                }
              }
            }

            final homeReasons = result.putIfAbsent(homeName, () => []);

            if (reasons.isEmpty) {
              final safeReason = strings.safeReminderBody();

              if (!homeReasons.contains(safeReason)) {
                homeReasons.add(safeReason);
              }
            } else {
              for (final reason in reasons) {
                final translatedReason = strings.statusText(reason);

                if (!homeReasons.contains(translatedReason)) {
                  homeReasons.add(translatedReason);
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    if (result.isNotEmpty) {
      return result;
    }

    final homeName = reminderHomeName.isNotEmpty
        ? reminderHomeName
        : strings.defaultHomeName();

    if (isSafeReminder) {
      return {
        homeName: [strings.safeReminderBody()],
      };
    }

    final bodyText = strings.stripSafetyStatusText(currentReminderBody);

    return {
      homeName: [
        bodyText.isNotEmpty ? bodyText : strings.defaultUnsafeReminderReason(),
      ],
    };
  }

  List<Map<String, dynamic>> alarmItems() {
    try {
      final text = currentAlarmItemsJson.trim();
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
      currentAlarmBody,
      currentAlarmItemsJson,
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

  String alarmTitle(String type, AppStrings strings) {
    return strings.alarmCategoryTitle(type);
  }

  String fallbackReason(String type, AppStrings strings) {
    return strings.alarmFallbackReason(type);
  }

  Map<String, List<String>> buildAlarmIssueMap(
    String type,
    AppStrings strings,
  ) {
    final items = alarmItems();
    final Map<String, List<String>> result = {};

    for (final item in items) {
      final homeName = item["homeName"]?.toString().trim();
      final deviceName = item["deviceName"]?.toString().trim();
      final name = item["name"]?.toString().trim();
      final reason = item["reason"]?.toString().trim();
      final translatedReason = reason == null || reason.isEmpty
          ? ""
          : strings.statusText(reason);

      final realHomeName = homeName == null || homeName.isEmpty
          ? strings.defaultHomeName()
          : homeName;

      String text = "";

      if (deviceName != null && deviceName.isNotEmpty) {
        text = deviceName;
      } else if (name != null && name.isNotEmpty) {
        text = name;
      }

      if (translatedReason.isNotEmpty) {
        if (text.isEmpty) {
          text = translatedReason;
        } else if (translatedReason.toLowerCase().startsWith(
          "${text.toLowerCase()}:",
        )) {
          text = translatedReason;
        } else {
          text = "$text: $translatedReason";
        }
      }

      if (text.isEmpty) {
        text = fallbackReason(type, strings);
      }

      final homeReasons = result.putIfAbsent(realHomeName, () => []);

      if (!homeReasons.contains(text)) {
        homeReasons.add(text);
      }
    }

    if (result.isNotEmpty) return result;

    final body = currentAlarmBody.trim();
    if (body.isNotEmpty && body.length < 160) {
      return {
        "SafeHome": [strings.statusText(body)],
      };
    }

    return {
      "SafeHome": [fallbackReason(type, strings)],
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

    if (!widget.silentMode) {
      final acknowledged =
          await NotificationService.resolveActiveAlarmIncidents(
            action: 'check_home',
          );

      if (!acknowledged) {
        await startAlarmSound();
        _showAlarmActionError();
        return;
      }

      NotificationService.clearActiveAlarms();
      await NotificationService.stopAllAlarmNotifications();
    }

    if (!context.mounted) return;

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(MaterialPageRoute(builder: (_) => AuthGate()));
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

    await NotificationService.stopAllAlarmNotifications();
    await startAlarmSound();

    if (!context.mounted) return;

    final strings = AppStrings.of(context);

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(strings.t("Xác nhận tắt cảnh báo")),
          content: Text(strings.confirmStopAlarmBody()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.t("HỦY")),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.t("XÁC NHẬN")),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    timer?.cancel();
    await stopAlarmSound();

    final acknowledged = await NotificationService.resolveActiveAlarmIncidents(
      action: 'stop',
    );

    if (!acknowledged) {
      await startAlarmSound();
      _showAlarmActionError();
      return;
    }

    NotificationService.clearActiveAlarms();
    await NotificationService.stopAllAlarmNotifications();

    SystemNavigator.pop();
  }

  Widget _buildFadedScrollArea({required Widget child}) {
    return Expanded(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.08, 0.88, 1.0],
          ).createShader(bounds);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 40, 0, 46),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReminderUI(BuildContext context) {
    final strings = AppStrings.of(context);
    final safe = isSafeReminder;
    final issueMap = buildReminderIssueMap(strings);
    const reminderSubtitle = "SafeHome Security Reminder";

    final Color accent = safe ? Colors.green : Colors.orange;
    final Color bg1 = safe ? const Color(0xFF0E2B1A) : const Color(0xFF3A2508);

    final Color bg2 = safe ? const Color(0xFF163824) : const Color(0xFF4A2D08);

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
                  _buildFadedScrollArea(
                    child: Container(
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
                                ? strings.safeStatusTitle()
                                : strings.unsafeStatusTitle(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reminderSubtitle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            item,
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
                            strings.autoCloseAfter(formatRemainingTime()),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
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
                      label: Text(
                        strings.t("KIỂM TRA NHÀ"),
                        style: const TextStyle(
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
                      strings.t("ĐÓNG NHẮC NHỞ"),
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
    final strings = AppStrings.of(context);
    final type = alarmType();
    final issueMap = buildAlarmIssueMap(type, strings);
    final nextAlarmMap = buildNextAlarmMap();

    final isEmergency =
        type == 'sos' || type == 'smoke' || type == 'flood' || type == 'gas';

    final repeatText = isEmergency
        ? strings.alarmEmergencyEscalationText()
        : nextAlarmMap.isNotEmpty
        ? strings.alarmRepeatAtText(nextAlarmMap.values.first)
        : strings.alarmRepeatByScheduleText();

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
                _buildFadedScrollArea(
                  child: Container(
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
                          child: Icon(alarmIcon(type), color: accent, size: 52),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          alarmTitle(type, strings),
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
                          strings.t("SafeHome Security Alert"),
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
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                ),

                const SizedBox(height: 16),

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
                    label: Text(
                      strings.t("KIỂM TRA NHÀ"),
                      style: const TextStyle(
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
                  icon: const Icon(Icons.power_settings_new_rounded, size: 19),
                  label: Text(
                    strings.stopAlarmLabel(),
                    style: const TextStyle(
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
