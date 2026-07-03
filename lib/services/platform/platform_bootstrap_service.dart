import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'android/android_auto_away_foreground_task_service.dart';
import 'android/android_background_notification_service.dart';

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
  }

  static Future<void> activateAppCheck() async {
    if (!_isAndroid) {
      return;
    }

    await AndroidAutoAwayForegroundTaskService.activateAppCheck();
  }

  static void registerBackgroundHandlers() {
    if (!_isAndroid) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
