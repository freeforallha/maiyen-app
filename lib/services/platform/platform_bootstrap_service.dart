import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'android/android_auto_away_foreground_task_service.dart';
import 'firebase_background_message_service.dart';

class PlatformBootstrapService {
  const PlatformBootstrapService._();

  static bool get _isAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> initializeBeforeFirebase() async {
    if (!_isAndroid) {
      return;
    }

    AndroidAutoAwayForegroundTaskService.initCommunicationPort();
    AndroidAutoAwayForegroundTaskService.initialize();

    // Do not block the first frame/GPS startup. The recovery path validates the
    // stored account/session before writing anything.
    unawaited(
      AndroidAutoAwayForegroundTaskService.recoverFromStoredConfig(
        event: 'app_start_recovery',
      ),
    );
  }

  static Future<void> activateAppCheck() async {
    if (!_isAndroid) {
      return;
    }

    await AndroidAutoAwayForegroundTaskService.activateAppCheck();
  }

  static void registerBackgroundHandlers() {
    if (kIsWeb) {
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(
      maiYenFirebaseMessagingBackgroundHandler,
    );
  }
}
