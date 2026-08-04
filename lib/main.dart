import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/maiyen_app.dart';
import 'firebase_options.dart';
import 'helpers/debug_log.dart';
import 'services/notification_service.dart';
import 'services/platform/platform_bootstrap_service.dart';

Future<FirebaseApp>? _firebaseInitialization;
bool _deferredStartupScheduled = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phải đăng ký trước runApp để Android có callback ngay cả khi tiến trình
  // được dựng lại chỉ để nhận FCM khi app đang background/terminated.
  try {
    PlatformBootstrapService.registerBackgroundHandlers();
  } catch (error) {
    safeDebugPrint('STARTUP_BACKGROUND_HANDLER_ERROR: $error');
  }

  // Chỉ gọi runApp đúng một lần trong toàn bộ vòng đời Flutter Engine.
  // Bootstrap widget luôn vẽ Splash ngay ở frame đầu rồi tự chuyển sang app
  // chính sau khi Firebase sẵn sàng.
  runApp(const _MaiYenBootstrapApp());
}

Future<FirebaseApp> _ensureFirebaseInitialized() {
  if (Firebase.apps.isNotEmpty) {
    return Future.value(Firebase.app());
  }

  return _firebaseInitialization ??= Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void _scheduleDeferredStartupInit() {
  if (_deferredStartupScheduled) {
    return;
  }

  _deferredStartupScheduled = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      _runDeferredStartupTask(
        label: 'PLATFORM_BOOTSTRAP_INIT',
        timeout: const Duration(seconds: 3),
        task: PlatformBootstrapService.initializeBeforeFirebase,
      ),
    );

    unawaited(
      _runDeferredStartupTask(
        label: 'APP_CHECK_ACTIVATE',
        timeout: const Duration(seconds: 5),
        task: PlatformBootstrapService.activateAppCheck,
      ),
    );

    unawaited(
      _runDeferredStartupTask(
        label: 'NOTIFICATION_INIT',
        timeout: const Duration(seconds: 8),
        task: NotificationService.init,
      ),
    );
  });
}

Future<void> _runDeferredStartupTask({
  required String label,
  required Duration timeout,
  required Future<void> Function() task,
}) async {
  try {
    await task().timeout(timeout);
  } on TimeoutException catch (error) {
    safeDebugPrint('$label TIMEOUT: $error');
  } catch (error) {
    safeDebugPrint('$label ERROR: $error');
  }
}

class _MaiYenBootstrapApp extends StatefulWidget {
  const _MaiYenBootstrapApp();

  @override
  State<_MaiYenBootstrapApp> createState() => _MaiYenBootstrapAppState();
}

class _MaiYenBootstrapAppState extends State<_MaiYenBootstrapApp> {
  bool _firebaseReady = false;
  bool _initializationRunning = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeFirebase());
    });
  }

  Future<void> _initializeFirebase() async {
    if (_firebaseReady || _initializationRunning) {
      return;
    }

    _initializationRunning = true;

    try {
      await _ensureFirebaseInitialized().timeout(const Duration(seconds: 12));

      if (!mounted) {
        return;
      }

      setState(() {
        _firebaseReady = true;
      });

      _retryTimer?.cancel();
      _retryTimer = null;
      _scheduleDeferredStartupInit();
    } on TimeoutException catch (error) {
      safeDebugPrint('POST_FRAME_FIREBASE_INIT TIMEOUT: $error');
      _scheduleRetry();
    } catch (error) {
      safeDebugPrint('POST_FRAME_FIREBASE_INIT ERROR: $error');

      // Chỉ xoá cache Future khi Firebase thực sự trả lỗi. Nếu chỉ timeout,
      // Future cũ vẫn có thể hoàn tất sau đó và lượt retry sẽ dùng lại an toàn.
      _firebaseInitialization = null;
      _scheduleRetry();
    } finally {
      _initializationRunning = false;
    }
  }

  void _scheduleRetry() {
    if (!mounted || _firebaseReady) {
      return;
    }

    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_initializeFirebase());
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_firebaseReady) {
      return const MaiYenApp();
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MaiYenSplash(),
    );
  }
}
