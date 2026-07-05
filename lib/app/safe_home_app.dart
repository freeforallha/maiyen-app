import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/fullscreen_alarm_page.dart';
import '../pages/profile_setup_page.dart';
import '../services/notification_service.dart';
import '../services/account_session_service.dart';
import '../services/auto_away_service.dart';
import '../services/auto_login_service.dart';
import '../services/session_logout_service.dart';
import '../safehome_theme.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import 'package:safehome_app/helpers/debug_log.dart';
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SafeHomeApp extends StatefulWidget {
  const SafeHomeApp({super.key});

  @override
  State<SafeHomeApp> createState() => _SafeHomeAppState();
}

class _SafeHomeAppState extends State<SafeHomeApp>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSessionSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    appLanguageController.load();

    _authSessionSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen(
          (user) {
        if (user == null) {
          unawaited(AccountSessionService.deactivateLocal());
          return;
        }

        AutoAwayService.activateForSignedInUser(user.uid);

        unawaited(
          AccountSessionService.activate(
            uid: user.uid,
          ).catchError((Object error) {
            safeDebugPrint(
              'ACCOUNT_SESSION_ACTIVATE_ERROR: $error',
            );
          }),
        );
      },
      onError: (Object error) {
        safeDebugPrint(
          'ACCOUNT_SESSION_AUTH_LISTENER_ERROR: $error',
        );
      },
    );

    // Chỉ xoá Reminder khi app được mở mới hoàn toàn.
    // Không xoá khi chỉ bật lại màn hình.
    unawaited(NotificationService.stopReminderNotification());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    unawaited(AccountSessionService.updateLifecycle(state));

    if (state != AppLifecycleState.resumed) {
      return;
    }

    _activateResumeServices();
  }

  void _activateResumeServices() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    AutoAwayService.activateForSignedInUser(user.uid);

    unawaited(
      AccountSessionService.activate(uid: user.uid).catchError((Object error) {
        safeDebugPrint('ACCOUNT_SESSION_RESUME_ACTIVATE_ERROR: $error');
      }),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_authSessionSubscription?.cancel());
    super.dispose();
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
      safeDebugPrint("REMOVE_LEGACY_PASSWORD_ERROR: $error");
    }

    user = FirebaseAuth.instance.currentUser;

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
    await SessionLogoutService.signOutCurrentUser();
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
              safeDebugPrint("PROFILE_LOAD_ERROR: ${profileSnap.error}");

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

            return const LocationPermissionGate(
              child: HomePage(),
            );
          },
        );
      },
    );
  }
}
class LocationPermissionGate extends StatefulWidget {
  const LocationPermissionGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<LocationPermissionGate> createState() =>
      _LocationPermissionGateState();
}

class _LocationPermissionGateState
    extends State<LocationPermissionGate> {
  bool _checkStarted = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(_checkAlwaysLocationPermission());
    });
  }

  Future<void> _checkAlwaysLocationPermission() async {
    if (_checkStarted) return;

    _checkStarted = true;

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted ||
          permission == LocationPermission.always) {
        return;
      }

      await _showPermissionDialog(permission);
    } catch (error) {
      safeDebugPrint(
        "STARTUP_LOCATION_PERMISSION_ERROR: $error",
      );
    }
  }

  Future<void> _showPermissionDialog(
      LocationPermission permission,
      ) async {
    if (!mounted || _dialogOpen) return;

    _dialogOpen = true;

    final strings = AppStrings.of(context);

    final openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final currentlyWhileUsing =
            permission == LocationPermission.whileInUse;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: SafeHomeColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  strings.choose(
                    vi: "Cho phép vị trí luôn luôn",
                    en: "Always allow location",
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            currentlyWhileUsing
                ? strings.choose(
              vi: "SafeHome hiện chỉ được truy cập vị trí "
                  "khi bạn đang sử dụng ứng dụng.\n\n"
                  "Hãy chọn quyền Vị trí và chuyển sang "
                  "\"Luôn cho phép\" để tính năng tự động "
                  "Bảo vệ khi rời nhà hoạt động khi ứng dụng "
                  "đang chạy nền.",
              en: "SafeHome can currently access location only "
                  "while the app is in use.\n\n"
                  "Open Location permission and select "
                  "\"Allow all the time\" so automatic protection "
                  "continues working in the background.",
            )
                : strings.choose(
              vi: "SafeHome cần quyền vị trí "
                  "\"Luôn cho phép\" để nhận biết khi bạn "
                  "rời hoặc trở về nhà, kể cả khi ứng dụng "
                  "đang chạy nền.",
              en: "SafeHome needs always-on location permission "
                  "to detect when you leave or return home, "
                  "including while the app is in the background.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                strings.choose(
                  vi: "Để sau",
                  en: "Later",
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.settings_rounded),
              label: Text(
                strings.choose(
                  vi: "Mở cài đặt",
                  en: "Open settings",
                ),
              ),
            ),
          ],
        );
      },
    );

    _dialogOpen = false;

    if (openSettings == true) {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/login.png",
                    width: 280,
                    height: 220,
                    fit: BoxFit.contain,
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
