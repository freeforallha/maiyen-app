import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../config/legacy_identifiers.dart';

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
    MaiYenLegacyIdentifiers.iosCriticalAlertsDartDefine,
    defaultValue: false,
  );

  static const String securityAlarmCategoryId =
      MaiYenLegacyIdentifiers.iosSecurityAlarmCategoryId;
  static const String emergencyAlarmCategoryId =
      MaiYenLegacyIdentifiers.iosEmergencyAlarmCategoryId;
  static const String reminderCategoryId =
      MaiYenLegacyIdentifiers.iosReminderCategoryId;
  static const String sensorCategoryId =
      MaiYenLegacyIdentifiers.iosSensorCategoryId;
  static const String chatCategoryId =
      MaiYenLegacyIdentifiers.iosChatCategoryId;

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
      threadIdentifier: MaiYenLegacyIdentifiers.iosAlarmThreadId(homeId),
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
      threadIdentifier: MaiYenLegacyIdentifiers.iosSensorThreadId(homeId),
      interruptionLevel: InterruptionLevel.active,
    );
  }

  static DarwinNotificationDetails chatDetails({required String homeId}) {
    final safeIdentifier = _safeIdentifierPart(homeId, fallback: 'all');

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      categoryIdentifier: chatCategoryId,
      threadIdentifier: MaiYenLegacyIdentifiers.iosChatThreadId(safeIdentifier),
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
        threadIdentifier: MaiYenLegacyIdentifiers.iosReminderThreadId,
        interruptionLevel: InterruptionLevel.active,
      );
}
