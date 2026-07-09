import 'package:flutter/foundation.dart';

import 'android/android_auto_away_foreground_task_service.dart';

class PlatformAutoAwayTaskService {
  const PlatformAutoAwayTaskService._();

  static bool get _isAndroid {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static void initialize() {
    if (!_isAndroid) {
      return;
    }

    AndroidAutoAwayForegroundTaskService.initialize();
  }

  static Future<void> syncForHomes({
    required String uid,
    required Map<String, dynamic> homes,
  }) async {
    if (!_isAndroid) {
      return;
    }

    await AndroidAutoAwayForegroundTaskService.syncForHomes(
      uid: uid,
      homes: homes,
    );
  }

  static Future<void> stop() async {
    if (!_isAndroid) {
      return;
    }

    await AndroidAutoAwayForegroundTaskService.stop();
  }

  static Future<void> refreshNotificationLanguage() async {
    if (!_isAndroid) {
      return;
    }

    await AndroidAutoAwayForegroundTaskService.refreshNotificationLanguage();
  }
}
