import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/safe_home_app.dart';
import '../services/notification_service.dart';

class FullscreenAlarmPage extends StatefulWidget {
  final String title;
  final String body;
  final bool silentMode;

  const FullscreenAlarmPage({
    super.key,
    required this.title,
    required this.body,
    this.silentMode = false,
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
  bool get isUnsafeReminder => isReminder && widget.body.contains('CHƯA AN TOÀN');

  @override
  void initState() {
    super.initState();

    if (widget.silentMode) {
      startSilentTimer();
    } else {
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

  Future<void> stopAlarmSound() async {
    await alarmPlayer.stop();
    await localNotif.cancel(999999);
  }

  Future<void> openHome(BuildContext context) async {
    timer?.cancel();
    await stopAlarmSound();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthGate(),
      ),
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

    final String buttonText = !isReminder ? "KIỂM TRA NGAY" : "KIỂM TRA NHÀ";

    final String closeText = !isReminder ? "TẮT CẢNH BÁO" : "ĐÓNG NHẮC NHỞ";

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
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
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
                        width: 96,
                        height: 96,
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
                          size: 56,
                        ),
                      ),

                      const SizedBox(height: 24),

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

                      const SizedBox(height: 16),

                      Text(
                        widget.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (isReminder) ...[
                        const SizedBox(height: 24),

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
                    label: Text(
                      buttonText,
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
                    closeText,
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