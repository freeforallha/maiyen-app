import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../app/safe_home_app.dart';

class FullscreenAlarmPage extends StatelessWidget {
  final String title;
  final String body;
  final bool silentMode;

  final String uid;
  final String homeId;

  const FullscreenAlarmPage({
    super.key,
    required this.title,
    required this.body,
    this.silentMode = false,
    this.uid = "",
    this.homeId = "",
  });
  Future<void> muteRepeatForCurrentCycle(
      BuildContext context,
      ) async {
    if (uid.isEmpty || homeId.isEmpty) return;

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$homeId/alarmMute")
        .set({
      "muted": true,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Đã tắt báo lại trong chu kỳ hiện tại",
        ),
      ),
    );
  }
  void openHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthGate(),
      ),
    );
  }

  Future<void> confirmStopAlarm(BuildContext context) async {
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

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = silentMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFB00020);

    final icon = silentMode
        ? Icons.shield_moon_rounded
        : Icons.notifications_active_rounded;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 64,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  silentMode ? "SAFEHOME REMINDER" : "BÁO ĐỘNG SAFEHOME",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.35,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text(
                      "KIỂM TRA NHÀ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => openHome(context),
                  ),
                ),

                const SizedBox(height: 18),
                if (!silentMode && uid.isNotEmpty && homeId.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      icon: const Icon(Icons.notifications_off_rounded),
                      label: const Text(
                        "TẮT BÁO LẠI TRONG CHU KỲ NÀY",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => muteRepeatForCurrentCycle(context),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(
                    Icons.power_settings_new_rounded,
                    size: 18,
                  ),
                  label: Text(
                    silentMode ? "Đóng" : "Tắt cảnh báo",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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