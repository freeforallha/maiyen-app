import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/fullscreen_alarm_page.dart';
import '../services/notification_service.dart';
import '../services/auto_login_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SafeHomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: AlarmLaunchGate(),
    );
  }
}

class AlarmLaunchGate extends StatefulWidget {
  @override
  State<AlarmLaunchGate> createState() => _AlarmLaunchGateState();
}

class _AlarmLaunchGateState extends State<AlarmLaunchGate> {
  bool checked = false;
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

    if (payload == "alarm") {
      return const FullscreenAlarmPage(
        title: "Báo động SafeHome",
        body: "Có cảnh báo an ninh cần kiểm tra ngay.",
      );
    }

    if (payload == "schedule_notification" ||
        payload.startsWith("schedule_notification|")) {
      final body = payload.startsWith("schedule_notification|")
          ? payload.replaceFirst("schedule_notification|", "")
          : NotificationService.lastScheduleBody;

      return FullscreenAlarmPage(
        title: "🏡 SafeHome",
        body: body,
        silentMode: true,
      );
    }

    return AuthGate();
  }
}

class AuthGate extends StatefulWidget {
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
        final currentUser = snap.data ?? FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          return LoginPage();
        }

        return HomePage();
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
  late AnimationController controller;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    fade = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
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
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home_rounded,
                size: 78,
                color: Colors.green,
              ),
              const SizedBox(height: 18),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    TextSpan(
                      text: "Safe",
                      style: TextStyle(color: Colors.green),
                    ),
                    TextSpan(
                      text: "Home",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}