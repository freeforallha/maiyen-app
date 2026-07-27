import 'package:flutter/services.dart';
import '../../../config/maiyen_identifiers.dart';

class AndroidAlarmPermissionService {
  static const MethodChannel _channel = MethodChannel(
    MaiYenIdentifiers.androidNativeAlarmPermissionChannel,
  );

  static Future<bool> canUseFullScreenIntent() async {
    final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
    return result ?? false;
  }

  static Future<void> openFullScreenIntentSettings() async {
    await _channel.invokeMethod('openFullScreenIntentSettings');
  }
}
