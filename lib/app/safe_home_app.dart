import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/fullscreen_alarm_page.dart';
import '../pages/profile_setup_page.dart';
import '../services/notification_service.dart';
import '../services/auto_login_service.dart';
import '../services/fcm_service.dart';
import '../safehome_theme.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SafeHomeApp extends StatefulWidget {
  const SafeHomeApp({super.key});

  @override
  State<SafeHomeApp> createState() => _SafeHomeAppState();
}

class _SafeHomeAppState extends State<SafeHomeApp> {
  @override
  void initState() {
    super.initState();

    appLanguageController.load();

    // Chỉ xoá Reminder khi app được mở mới hoàn toàn.
    // Không xoá khi chỉ bật lại màn hình.
    unawaited(NotificationService.stopReminderNotification());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguageController,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          theme: SafeHomeTheme.light,
          locale: appLanguageController.locale,
          supportedLocales: const [Locale("vi"), Locale("en")],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AlarmLaunchGate(),
        );
      },
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
      // Giữ nguyên payload Alarm.
    } else if (payload == "open_home" ||
        payload == "schedule_notification" ||
        payload.startsWith("schedule_notification::") ||
        payload.startsWith("schedule_notification|")) {
      await NotificationService.stopReminderNotification();
      payload = "open_home";
    }

    if (!mounted) return;

    setState(() {
      checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (!checked) {
      return const SafeHomeSplash();
    }

    if (payload == "open_home") {
      return const AuthGate();
    }

    if (payload == "alarm") {
      return FullscreenAlarmPage(
        title: strings.alarmTitle,
        body: strings.alarmBody,
      );
    }

    if (payload.startsWith("alarm_summary|")) {
      final parts = payload.split("|");

      final body = parts.length > 1
          ? Uri.decodeComponent(parts[1])
          : strings.alarmFallback;

      final alarmItems = parts.length > 2 ? Uri.decodeComponent(parts[2]) : "";

      return FullscreenAlarmPage(
        title: "🚨 SafeHome",
        body: body,
        alarmItemsJson: alarmItems,
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

  String _profileFutureUid = "";
  Future<DatabaseEvent>? _profileFuture;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    // Xoá mật khẩu mà phiên bản app cũ từng lưu.
    // Firebase Auth tự duy trì phiên bằng token bảo mật của SDK.
    try {
      await AutoLoginService.removeLegacyPassword();
    } catch (error) {
      debugPrint("REMOVE_LEGACY_PASSWORD_ERROR: $error");
    }

    user = FirebaseAuth.instance.currentUser;

    debugPrint("AUTH CHECK UID = ${user?.uid}");
    debugPrint("AUTH CHECK EMAIL = ${user?.email}");

    if (!mounted) return;

    setState(() {
      ready = true;
    });
  }

  Future<DatabaseEvent> _loadProfile(String uid) {
    var future = _profileFuture;

    if (future == null || _profileFutureUid != uid) {
      _profileFutureUid = uid;
      future = FirebaseDatabase.instance
          .ref("accounts/$uid/profile")
          .once()
          .timeout(const Duration(seconds: 12));
      _profileFuture = future;
    }

    return future;
  }

  void _retryProfileLoad() {
    setState(() {
      _profileFutureUid = "";
      _profileFuture = null;
    });
  }

  Future<void> _signOutAfterProfileError() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null) {
      try {
        await FCMService.removeCurrentInstallationToken(uid: currentUid);
      } catch (error) {
        debugPrint("REMOVE_FCM_TOKEN_ON_SIGN_OUT_ERROR: $error");
      }
    }

    try {
      await AutoLoginService.clearLogin();
    } catch (_) {}

    await FirebaseAuth.instance.signOut();
  }

  Widget _buildProfileLoadError(Object? error) {
    return Scaffold(
      backgroundColor: SafeHomeColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 54,
                  color: SafeHomeColors.danger,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Không thể tải dữ liệu tài khoản",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SafeHomeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error?.toString() ?? "Lỗi không xác định",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SafeHomeColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retryProfileLoad,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Thử lại"),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _signOutAfterProfileError,
                  child: const Text("Đăng xuất"),
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
    if (!ready) {
      return const SafeHomeSplash();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: user,
      builder: (context, snap) {
        final currentUser = snap.data ?? FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          return const LoginPage();
        }

        return FutureBuilder<DatabaseEvent>(
          future: _loadProfile(currentUser.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const SafeHomeSplash();
            }

            if (profileSnap.hasError) {
              debugPrint(
                "PROFILE_LOAD_ERROR ${currentUser.uid}: ${profileSnap.error}",
              );

              return _buildProfileLoadError(profileSnap.error);
            }

            if (!profileSnap.hasData) {
              return _buildProfileLoadError(
                "Không nhận được dữ liệu từ Firebase",
              );
            }

            final profileEvent = profileSnap.data;

            if (profileEvent == null) {
              return _buildProfileLoadError(
                "Không nhận được dữ liệu từ Firebase",
              );
            }

            final value = profileEvent.snapshot.value;

            final profile = value is Map
                ? Map<String, dynamic>.from(value)
                : <String, dynamic>{};

            final name = profile["name"]?.toString().trim() ?? "";
            final gender = profile["gender"]?.toString().trim() ?? "";
            final phone = profile["phone"]?.toString().trim() ?? "";

            if (name.isEmpty || gender.isEmpty || phone.isEmpty) {
              return ProfileSetupPage(
                uid: currentUser.uid,
                email: currentUser.email ?? "",
              );
            }

            return const HomePage();
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

    fade = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    scale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

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
                    border: Border.all(color: SafeHomeColors.border),
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
                        style: TextStyle(color: SafeHomeColors.primary),
                      ),
                      TextSpan(
                        text: "Home",
                        style: TextStyle(color: SafeHomeColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of(context).splashTagline,
                  style: const TextStyle(
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
