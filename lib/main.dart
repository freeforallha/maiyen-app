import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app/safe_home_app.dart';
import 'helpers/debug_log.dart';
import 'services/notification_service.dart';
import 'services/platform/platform_bootstrap_service.dart';

Future<FirebaseApp>? _firebaseInitialization;
bool _deferredStartupScheduled = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await _initializeFirebaseForStartup(
    timeout: const Duration(seconds: 4),
    label: 'STARTUP_FIREBASE_INIT',
  );

  if (firebaseReady) {
    runApp(SafeHomeApp());
    _scheduleDeferredStartupInit();
    return;
  }

  runApp(const _StartupFallbackApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_finishFirebaseStartupAfterFirstFrame());
  });
}

Future<FirebaseApp> _ensureFirebaseInitialized() {
  if (Firebase.apps.isNotEmpty) {
    return Future.value(Firebase.app());
  }

  return _firebaseInitialization ??= Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<bool> _initializeFirebaseForStartup({
  required Duration timeout,
  required String label,
}) async {
  try {
    await _ensureFirebaseInitialized().timeout(timeout);
    return true;
  } on TimeoutException catch (error) {
    safeDebugPrint('$label TIMEOUT: $error');
    return false;
  } catch (error) {
    _firebaseInitialization = null;
    safeDebugPrint('$label ERROR: $error');
    return false;
  }
}

Future<void> _finishFirebaseStartupAfterFirstFrame() async {
  while (true) {
    final ready = await _initializeFirebaseForStartup(
      timeout: const Duration(seconds: 12),
      label: 'POST_FRAME_FIREBASE_INIT',
    );

    if (ready) {
      runApp(SafeHomeApp());
      _scheduleDeferredStartupInit();
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2));
  }
}

void _scheduleDeferredStartupInit() {
  if (_deferredStartupScheduled) {
    return;
  }

  _deferredStartupScheduled = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      PlatformBootstrapService.registerBackgroundHandlers();
    } catch (error) {
      safeDebugPrint('STARTUP_BACKGROUND_HANDLER_ERROR: $error');
    }

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

class _StartupFallbackApp extends StatelessWidget {
  const _StartupFallbackApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeHomeSplash(),
    );
  }
}
