import 'package:flutter/services.dart';

class AndroidAlarmPermissionService {
  static const MethodChannel _channel = MethodChannel(
    'safehome/native_alarm_permission',
  );

  static Future<bool> canUseFullScreenIntent() async {
    final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
    return result ?? false;
  }

  static Future<void> openFullScreenIntentSettings() async {
    await _channel.invokeMethod('openFullScreenIntentSettings');
  }
}
