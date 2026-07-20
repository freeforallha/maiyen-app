import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
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
import '../services/single_device_session_service.dart';
import '../safehome_theme.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import 'package:safehome_app/helpers/debug_log.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class _TetumMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TetumMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == "tet";

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale("pt"));
  }

  @override
  bool shouldReload(_TetumMaterialLocalizationsDelegate old) => false;
}

class _TetumWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _TetumWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == "tet";

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return GlobalWidgetsLocalizations.delegate.load(const Locale("pt"));
  }

  @override
  bool shouldReload(_TetumWidgetsLocalizationsDelegate old) => false;
}

class _TetumCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TetumCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == "tet";

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale("pt"));
  }

  @override
  bool shouldReload(_TetumCupertinoLocalizationsDelegate old) => false;
}

bool _remoteSessionSignOutRunning = false;

Future<void> forceSignOutForRemoteSession() async {
  if (_remoteSessionSignOutRunning) {
    return;
  }

  _remoteSessionSignOutRunning = true;

  try {
    await SessionLogoutService.signOutCurrentUser(forcedByRemoteSession: true);
  } finally {
    _remoteSessionSignOutRunning = false;
  }
}

class SafeHomeApp extends StatefulWidget {
  const SafeHomeApp({super.key});

  @override
  State<SafeHomeApp> createState() => _SafeHomeAppState();
}

class _SafeHomeAppState extends State<SafeHomeApp> with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSessionSubscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    appLanguageController.load();

    _authSessionSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user == null) {
          unawaited(AccountSessionService.deactivateLocal());
          unawaited(SingleDeviceSessionService.stopActiveSessionListener());
          return;
        }
      },
      onError: (Object error) {
        safeDebugPrint('ACCOUNT_SESSION_AUTH_LISTENER_ERROR: $error');
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

    unawaited(_validateSessionOnResume());
  }

  Future<void> _validateSessionOnResume() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final result = await SingleDeviceSessionService.ensureValidSession(
        uid: user.uid,
        allowLegacyBootstrap: false,
      );

      final identity = result.identity;

      if (!result.isValid || identity == null) {
        await forceSignOutForRemoteSession();
        return;
      }

      await AccountSessionService.activate(
        uid: user.uid,
        sessionId: identity.sessionId,
      );

      SingleDeviceSessionService.startActiveSessionListener(
        uid: user.uid,
        onSessionRevoked: forceSignOutForRemoteSession,
      );

      AutoAwayService.activateForSignedInUser(user.uid);

      // [DÙNG CHUNG] Đối chiếu incident với Firebase mỗi khi app resume.
      // Đây là lớp bảo vệ bắt buộc cho iOS vì silent push có thể bị trì hoãn.
      await NotificationService.reconcileActiveAlarmIncidents();
    } catch (error) {
      safeDebugPrint('ACTIVE_SESSION_RESUME_CHECK_ERROR: $error');
    }
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
          supportedLocales: AppLanguageController.supportedLocales,
          localizationsDelegates: const [
            _TetumMaterialLocalizationsDelegate(),
            _TetumWidgetsLocalizationsDelegate(),
            _TetumCupertinoLocalizationsDelegate(),
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

  String _sessionFutureUid = "";
  Future<bool>? _sessionFuture;
  String _profileFutureUid = "";
  Future<DatabaseEvent>? _profileFuture;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    // Không chờ cố định 2 giây nữa.
    // Firebase Auth đã sẵn sàng sau Firebase.initializeApp().
    user = FirebaseAuth.instance.currentUser;

    if (mounted) {
      setState(() {
        ready = true;
      });
    }

    // Việc dọn mật khẩu legacy không cần chặn UI.
    unawaited(
      AutoLoginService.removeLegacyPassword().catchError((Object error) {
        safeDebugPrint("REMOVE_LEGACY_PASSWORD_ERROR: $error");
      }),
    );
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

  Future<bool> _ensureSessionReady(String uid) {
    final cleanUid = uid.trim();
    var future = _sessionFuture;

    if (future == null || _sessionFutureUid != cleanUid) {
      _sessionFutureUid = cleanUid;
      future = _ensureSessionReadyInternal(cleanUid);
      _sessionFuture = future;
    }

    return future;
  }

  Future<bool> _ensureSessionReadyInternal(String uid) async {
    if (uid.isEmpty) {
      return false;
    }

    final result = await SingleDeviceSessionService.ensureValidSession(
      uid: uid,
      allowLegacyBootstrap: true,
    );
    final identity = result.identity;

    if (!result.isValid || identity == null) {
      await forceSignOutForRemoteSession();
      return false;
    }

    await AccountSessionService.activate(
      uid: uid,
      sessionId: identity.sessionId,
    );

    SingleDeviceSessionService.startActiveSessionListener(
      uid: uid,
      onSessionRevoked: forceSignOutForRemoteSession,
    );

    AutoAwayService.activateForSignedInUser(uid);
    return true;
  }

  void _resetSessionAndProfileFutures() {
    _sessionFutureUid = "";
    _sessionFuture = null;
    _profileFutureUid = "";
    _profileFuture = null;
  }

  Widget _buildProfileLoadError(Object? error) {
    final strings = AppStrings.of(context);
    final message = strings.sanitizeUserMessage(
      error?.toString() ?? "",
      fallback: strings.t("Không thể tải dữ liệu tài khoản"),
    );

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
                Text(
                  strings.t("Không thể tải dữ liệu tài khoản"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SafeHomeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
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
                    label: Text(strings.t("Thử lại")),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _signOutAfterProfileError,
                  child: Text(strings.t("Đăng xuất")),
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

    return ValueListenableBuilder<bool>(
      valueListenable: SingleDeviceSessionService.interactiveLoginInProgress,
      builder: (context, interactiveLoginInProgress, _) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          initialData: user,
          builder: (context, snap) {
            final currentUser = snap.data ?? FirebaseAuth.instance.currentUser;

            if (currentUser == null || interactiveLoginInProgress) {
              _resetSessionAndProfileFutures();
              return const LoginPage();
            }

            return FutureBuilder<bool>(
              future: _ensureSessionReady(currentUser.uid),
              builder: (context, sessionSnap) {
                if (sessionSnap.connectionState == ConnectionState.waiting) {
                  return const SafeHomeSplash();
                }

                if (sessionSnap.hasError) {
                  safeDebugPrint(
                    "ACTIVE_SESSION_LOAD_ERROR: ${sessionSnap.error}",
                  );

                  return _buildProfileLoadError(sessionSnap.error);
                }

                if (sessionSnap.data != true) {
                  return const LoginPage();
                }

                return FutureBuilder<DatabaseEvent>(
                  future: _loadProfile(currentUser.uid),
                  builder: (context, profileSnap) {
                    if (profileSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const SafeHomeSplash();
                    }

                    if (profileSnap.hasError) {
                      safeDebugPrint(
                        "PROFILE_LOAD_ERROR: ${profileSnap.error}",
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

                    return const LocationPermissionGate(child: HomePage());
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class LocationPermissionGate extends StatefulWidget {
  const LocationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate> {
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

      if (!mounted || permission == LocationPermission.always) {
        return;
      }

      await _showPermissionDialog(permission);
    } catch (error) {
      safeDebugPrint("STARTUP_LOCATION_PERMISSION_ERROR: $error");
    }
  }

  Future<void> _showPermissionDialog(LocationPermission permission) async {
    if (!mounted || _dialogOpen) return;

    _dialogOpen = true;

    final strings = AppStrings.of(context);

    final openSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final currentlyWhileUsing = permission == LocationPermission.whileInUse;

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
              Expanded(child: Text(strings.t("Cho phép vị trí luôn luôn"))),
            ],
          ),
          content: Text(
            currentlyWhileUsing
                ? strings.t(
                    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.",
                  )
                : strings.t(
                    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.",
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(strings.t("Để sau")),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.settings_rounded),
              label: Text(strings.t("Mở cài đặt")),
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
