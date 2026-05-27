import 'package:flutter/material.dart';

import '../app/safe_home_app.dart';

class FullscreenAlarmPage extends StatelessWidget {
  final String title;
  final String body;
  final bool silentMode;

  const FullscreenAlarmPage({
    super.key,
    required this.title,
    required this.body,
    this.silentMode = false,
  });

  void close(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthGate(),
      ),
    );
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
                  silentMode
                      ? "SAFEHOME REMINDER"
                      : "BÁO ĐỘNG SAFEHOME",
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
                    onPressed: () => close(context),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(
                      silentMode
                          ? "ĐÓNG"
                          : "TẮT CẢNH BÁO",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => close(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}