import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/fullscreen_alarm_page.dart';
import '../services/notification_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
GlobalKey<NavigatorState>();

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
  bool openedByAlarm = false;

  @override
  void initState() {
    super.initState();
    checkLaunch();
  }

  Future<void> checkLaunch() async {
    final details = await localNotif.getNotificationAppLaunchDetails();

    final payload = details?.notificationResponse?.payload ?? "";

    setState(() {
      openedByAlarm = payload == "alarm";
      checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!checked) {
      return const SafeHomeSplash();
    }

    if (openedByAlarm) {
      return const FullscreenAlarmPage(
        title: "Báo động SafeHome",
        body: "Có cảnh báo an ninh cần kiểm tra ngay.",
      );
    }

    return AuthGate();
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snap) {
        return FutureBuilder(
          future: Future.delayed(
            const Duration(milliseconds: 1200),
          ),

          builder: (context, delaySnap) {
            if (delaySnap.connectionState != ConnectionState.done) {
              return const SafeHomeSplash();
            }

            if (!snap.hasData) return LoginPage();

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
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),

                    TextSpan(
                      text: "Home",
                      style: TextStyle(
                        color: Colors.black87,
                      ),
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