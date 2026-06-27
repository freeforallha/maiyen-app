import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/fullscreen_alarm_page.dart';
import '../pages/profile_setup_page.dart';
import '../services/notification_service.dart';
import '../services/auto_login_service.dart';
import '../safehome_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
GlobalKey<NavigatorState>();

class SafeHomeApp extends StatelessWidget {
  const SafeHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: SafeHomeTheme.light,
      home: const AlarmLaunchGate(),
    );
  }
}

class AlarmLaunchGate extends StatefulWidget {
  const AlarmLaunchGate({super.key});

  @override
  State<AlarmLaunchGate> createState() => _AlarmLaunchGateState();
}

class _AlarmLaunchGateState extends State<AlarmLaunchGate> {
  bool checked = false;
  bool isAlarmScreenLaunch = false;

  String payload = "";

  @override
  void initState() {
    super.initState();
    checkLaunch();
  }

  Future<void> checkLaunch() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final details = await localNotif.getNotificationAppLaunchDetails();

    payload = details?.notificationResponse?.payload ?? "";

    if (payload.startsWith("alarm_summary|")) {
      // Giữ nguyên payload.
    } else if (payload == "open_home") {
      // Không tự ép open_home thành alarm nữa.
      // Alarm thật đã có payload riêng: alarm hoặc alarm_summary|.
    }

    if (!mounted) return;

    setState(() {
      checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!checked) {
      return const SafeHomeSplash();
    }

    if (payload == "open_home") {
      return const AuthGate();
    }

    if (payload == "alarm") {
      return const FullscreenAlarmPage(
        title: "Báo động SafeHome",
        body: "Có cảnh báo an ninh cần kiểm tra ngay.",
      );
    }

    if (payload.startsWith("alarm_summary|")) {
      final parts = payload.split("|");

      final body = parts.length > 1
          ? Uri.decodeComponent(parts[1])
          : "Có cảnh báo cần kiểm tra";

      final alarmItems = parts.length > 2
          ? Uri.decodeComponent(parts[2])
          : "";

      return FullscreenAlarmPage(
        title: "🚨 SafeHome",
        body: body,
        alarmItemsJson: alarmItems,
      );
    }

    if (payload.startsWith("schedule_notification::")) {
      String title = NotificationService.lastScheduleTitle;
      String body = NotificationService.lastScheduleBody;
      String reminderItemsJson =
          NotificationService.lastReminderItemsJson;

      try {
        final raw = payload.replaceFirst(
          "schedule_notification::",
          "",
        );

        final data = Map<String, dynamic>.from(jsonDecode(raw));

        title = data["title"]?.toString() ?? title;
        body = data["body"]?.toString() ?? body;
        reminderItemsJson =
            data["reminderItems"]?.toString() ?? reminderItemsJson;
      } catch (_) {}

      return FullscreenAlarmPage(
        title: title,
        body: body,
        silentMode: true,
        reminderItemsJson: reminderItemsJson,
      );
    }

    if (payload == "schedule_notification" ||
        payload.startsWith("schedule_notification|")) {
      final body = payload.startsWith("schedule_notification|")
          ? payload.replaceFirst("schedule_notification|", "")
          : NotificationService.lastScheduleBody;

      return FullscreenAlarmPage(
        title: NotificationService.lastScheduleTitle,
        body: body,
        silentMode: true,
        reminderItemsJson: NotificationService.lastReminderItemsJson,
      );
    }

    return const AuthGate();
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool ready = false;
  User? user;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    user = FirebaseAuth.instance.currentUser;

    debugPrint("AUTH CHECK UID = ${user?.uid}");
    debugPrint("AUTH CHECK EMAIL = ${user?.email}");

    if (user == null) {
      try {
        debugPrint("TRY AUTO LOGIN...");

        user = await AutoLoginService.tryAutoLogin();

        debugPrint("AUTO LOGIN RESULT = ${user?.uid}");
      } catch (e) {
        debugPrint("AUTO LOGIN ERROR = $e");
      }
    }

    if (!mounted) return;

    setState(() {
      ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const SafeHomeSplash();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: user,
      builder: (context, snap) {
        final currentUser =
            snap.data ?? FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          return LoginPage();
        }

        return FutureBuilder<DatabaseEvent>(
          future: FirebaseDatabase.instance
              .ref("accounts/${currentUser.uid}/profile")
              .once(),
          builder: (context, profileSnap) {
            if (!profileSnap.hasData) {
              return const SafeHomeSplash();
            }

            final value = profileSnap.data!.snapshot.value;

            final profile = value is Map
                ? Map<String, dynamic>.from(value)
                : <String, dynamic>{};

            final name =
                profile["name"]?.toString().trim() ?? "";
            final gender =
                profile["gender"]?.toString().trim() ?? "";
            final phone =
                profile["phone"]?.toString().trim() ?? "";

            if (name.isEmpty || gender.isEmpty || phone.isEmpty) {
              return ProfileSetupPage(
                uid: currentUser.uid,
                email: currentUser.email ?? "",
              );
            }

            return HomePage();
          },
        );
      },
    );
  }
}

class SafeHomeSplash extends StatefulWidget {
  const SafeHomeSplash({super.key});

  @override
  State<SafeHomeSplash> createState() => _SafeHomeSplashState();
}

class _SafeHomeSplashState extends State<SafeHomeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fade = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    scale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHomeColors.background,
      body: FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: SafeHomeColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: SafeHomeColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 52,
                    color: SafeHomeColors.primary,
                  ),
                ),
                const SizedBox(height: 22),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                    children: [
                      TextSpan(
                        text: "Safe",
                        style: TextStyle(
                          color: SafeHomeColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: "Home",
                        style: TextStyle(
                          color: SafeHomeColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "An tâm hơn trong từng ngôi nhà",
                  style: TextStyle(
                    color: SafeHomeColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
