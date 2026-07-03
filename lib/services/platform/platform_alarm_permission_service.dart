import 'package:flutter/foundation.dart';

import 'android/android_alarm_permission_service.dart';

class PlatformAlarmPermissionService {
  const PlatformAlarmPermissionService._();

  static bool get isSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<bool> canUseFullScreenIntent() async {
    if (!isSupported) {
      return false;
    }

    return AndroidAlarmPermissionService.canUseFullScreenIntent();
  }

  static Future<void> openFullScreenIntentSettings() async {
    if (!isSupported) {
      return;
    }

    await AndroidAlarmPermissionService.openFullScreenIntentSettings();
  }
}
