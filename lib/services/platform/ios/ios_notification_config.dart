import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Cấu hình hiển thị notification riêng cho iOS.
///
/// Android vẫn dùng AndroidNotificationConfig và không đi qua file này.
class IosNotificationConfig {
  IosNotificationConfig._();

  /// Chỉ bật thành true sau khi Apple đã cấp Critical Alerts entitlement và
  /// capability đó đã được thêm vào Runner.entitlements trong Xcode.
  ///
  /// Có thể chuẩn bị build bằng:
  /// --dart-define=SAFEHOME_IOS_CRITICAL_ALERTS=true
  static const bool criticalAlertsEntitlementEnabled = bool.fromEnvironment(
    'SAFEHOME_IOS_CRITICAL_ALERTS',
    defaultValue: false,
  );

  static const String securityAlarmCategoryId =
      'SAFEHOME_SECURITY_ALARM';
  static const String emergencyAlarmCategoryId =
      'SAFEHOME_EMERGENCY_ALARM';
  static const String reminderCategoryId = 'SAFEHOME_REMINDER';
  static const String sensorCategoryId = 'SAFEHOME_SENSOR';
  static const String chatCategoryId = 'SAFEHOME_CHAT';

  static const DarwinInitializationSettings initializationSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: criticalAlertsEntitlementEnabled,
        defaultPresentAlert: false,
        defaultPresentBadge: false,
        defaultPresentSound: false,
      );

  static String _safeIdentifierPart(String value, {String fallback = 'all'}) {
    final clean = value.trim();

    if (clean.isEmpty) {
      return fallback;
    }

    return clean.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  }

  static DarwinNotificationDetails alarmDetails({
    required Map<String, dynamic> data,
    required bool playSound,
  }) {
    final eventCategory =
        data['eventCategory']?.toString().trim().toLowerCase() ?? '';
    final flowType =
        data['alarmFlowType']?.toString().trim().toLowerCase() ?? '';
    final alarmLevel =
        data['alarmLevel']?.toString().trim().toLowerCase() ?? '';
    final isEmergency =
        eventCategory == 'emergency' ||
        flowType == 'emergency' ||
        alarmLevel == 'emergency';
    final useCritical =
        isEmergency && criticalAlertsEntitlementEnabled && playSound;
    final homeId = _safeIdentifierPart(
      data['homeId']?.toString() ?? '',
      fallback: 'all',
    );

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
      sound: playSound ? 'default' : null,
      badgeNumber: 1,
      categoryIdentifier: isEmergency
          ? emergencyAlarmCategoryId
          : securityAlarmCategoryId,
      threadIdentifier: 'safehome_alarm_$homeId',
      interruptionLevel: useCritical
          ? InterruptionLevel.critical
          : InterruptionLevel.timeSensitive,
    );
  }

  static DarwinNotificationDetails sensorDetails({
    required Map<String, dynamic> data,
  }) {
    final homeId = _safeIdentifierPart(
      data['homeId']?.toString() ?? '',
      fallback: 'all',
    );

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: sensorCategoryId,
      threadIdentifier: 'safehome_sensor_$homeId',
      interruptionLevel: InterruptionLevel.active,
    );
  }

  static DarwinNotificationDetails chatDetails({
    required String homeId,
  }) {
    final safeHomeId = _safeIdentifierPart(homeId, fallback: 'all');

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: chatCategoryId,
      threadIdentifier: 'safehome_chat_$safeHomeId',
      interruptionLevel: InterruptionLevel.active,
    );
  }

  static const DarwinNotificationDetails reminderDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: reminderCategoryId,
        threadIdentifier: 'safehome_reminder',
        interruptionLevel: InterruptionLevel.active,
      );
}
