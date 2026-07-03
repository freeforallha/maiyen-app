import 'package:flutter/foundation.dart';

import 'android/android_auto_away_system_service.dart';

class PlatformAutoAwaySystemStatus {
  const PlatformAutoAwaySystemStatus({
    required this.batteryUnrestricted,
    required this.backgroundRestricted,
    required this.autoStartConfirmed,
  });

  final bool batteryUnrestricted;
  final bool backgroundRestricted;
  final bool autoStartConfirmed;
}

class PlatformAutoAwaySystemService {
  const PlatformAutoAwaySystemService._();

  static Future<PlatformAutoAwaySystemStatus> readSystemStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const PlatformAutoAwaySystemStatus(
        batteryUnrestricted: true,
        backgroundRestricted: false,
        autoStartConfirmed: true,
      );
    }

    return PlatformAutoAwaySystemStatus(
      batteryUnrestricted:
          await AndroidAutoAwaySystemService.isIgnoringBatteryOptimizations(),
      backgroundRestricted:
          await AndroidAutoAwaySystemService.isBackgroundRestricted(),
      autoStartConfirmed:
          await AndroidAutoAwaySystemService.isBootReceiverConfirmed(),
    );
  }
}
