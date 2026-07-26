import 'package:flutter/services.dart';
import '../../../config/legacy_identifiers.dart';

class AndroidAlarmPermissionService {
  static const MethodChannel _channel = MethodChannel(
    MaiYenLegacyIdentifiers.androidNativeAlarmPermissionChannel,
  );

  static Future<bool> canUseFullScreenIntent() async {
    final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
    return result ?? false;
  }

  static Future<void> openFullScreenIntentSettings() async {
    await _channel.invokeMethod('openFullScreenIntentSettings');
  }
}
