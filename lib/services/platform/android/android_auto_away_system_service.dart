import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidAutoAwaySystemService {
  const AndroidAutoAwaySystemService._();

  static const MethodChannel _channel = MethodChannel(
    'safehome/native_alarm_permission',
  );

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } catch (error) {
      debugPrint('AUTO_AWAY_BATTERY_CHECK_ERROR: $error');
      return false;
    }
  }

  static Future<bool> isBackgroundRestricted() async {
    try {
      return await _channel.invokeMethod<bool>('isBackgroundRestricted') ??
          true;
    } catch (error) {
      debugPrint('AUTO_AWAY_BACKGROUND_CHECK_ERROR: $error');
      return true;
    }
  }

  static Future<bool> isBootReceiverConfirmed() async {
    try {
      return await _channel.invokeMethod<bool>('isBootReceiverConfirmed') ??
          false;
    } catch (error) {
      debugPrint('AUTO_AWAY_AUTOSTART_CHECK_ERROR: $error');
      return false;
    }
  }
}
