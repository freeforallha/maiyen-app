class MaiYenIdentifiers {
  const MaiYenIdentifiers._();

  static const String brandToken = 'maiyen';
  static const String applicationId = 'com.myfamily.maiyen';

  // QR chia sẻ nhà.
  static const String joinHomeQrPrefix = 'maiyen_join|';
  static const String joinMultipleHomesQrPrefix = 'maiyen_join_multi|';
  static const String joinHomeQrFamilyPrefix = 'maiyen_join';

  static String buildJoinHomeQr({
    required String ownerUid,
    required String homeId,
  }) {
    return '$joinHomeQrPrefix$ownerUid|$homeId';
  }

  static String buildJoinMultipleHomesQr({
    required String ownerUid,
    required Iterable<String> homeIds,
  }) {
    return '$joinMultipleHomesQrPrefix$ownerUid|${homeIds.join(',')}';
  }

  // SharedPreferences và secure storage.
  static const String languageStorageKey = 'maiyen_language_code';
  static const String loginEmailStorageKey = 'maiyen_email';
  static const String installationIdStorageKey = 'maiyen_fcm_installation_id';
  static const String lastOpenAtStorageKey = 'maiyen_last_open_at';
  static const String previousOpenAtStorageKey = 'maiyen_previous_open_at';
  static const String pendingPresenceEventsStorageKey =
      'maiyen_pending_presence_events_v1';
  static const String autoAwayForegroundTaskConfigStorageKey =
      'maiyen_auto_away_foreground_task_config_v1';

  static String deviceOrderStorageKey({
    required String uid,
    required String homeId,
  }) {
    return 'maiyen_device_order_${uid}_$homeId';
  }

  static String activeSessionStorageKey(String uid) {
    return 'maiyen_active_session_id_${uid.trim()}';
  }

  static String interactiveLoginRequiredStorageKey(String uid) {
    return 'maiyen_interactive_login_required_${uid.trim()}';
  }

  // Auto Away và native bridge Android.
  static const String autoAwayGeofencePrefix = 'maiyen_auto_away_v1';
  static const String androidNativeAlarmPermissionChannel =
      'maiyen/native_alarm_permission';
  static const String androidAutoAwayLocationChannelId =
      'maiyen_auto_away_location_v1';

  // Android notification identifiers.
  static const String androidAlarmChannelId = 'maiyen_alarm_v1';
  static const String androidAlarmFullscreenChannelId =
      'maiyen_alarm_fullscreen_v2';
  static const String androidEmergencyPriorityChannelId =
      'maiyen_emergency_priority_v1';
  static const String androidSecurityPriorityChannelId =
      'maiyen_security_priority_v1';
  static const String androidAlarmRepeatChannelId = 'maiyen_alarm_repeat_v1';
  static const String androidScheduleFullscreenChannelId =
      'maiyen_schedule_fullscreen_v1';
  static const String androidReminderPriorityChannelId =
      'maiyen_reminder_priority_v1';
  static const String androidChatChannelId = 'maiyen_chat_v1';
  static const String androidSensorNotificationChannelId =
      'maiyen_sensor_notification_v1';
  static const String androidNotificationIconName = 'ic_stat_maiyen';

  static String sensorNotificationTag({
    required String homeId,
    required String deviceId,
  }) {
    return 'maiyen_sensor_${homeId}_$deviceId';
  }

  // iOS notification categories và thread identifiers.
  static const String iosCriticalAlertsDartDefine =
      'MAIYEN_IOS_CRITICAL_ALERTS';
  static const String iosSecurityAlarmCategoryId = 'MAIYEN_SECURITY_ALARM';
  static const String iosEmergencyAlarmCategoryId = 'MAIYEN_EMERGENCY_ALARM';
  static const String iosReminderCategoryId = 'MAIYEN_REMINDER';
  static const String iosSensorCategoryId = 'MAIYEN_SENSOR';
  static const String iosChatCategoryId = 'MAIYEN_CHAT';
  static const String iosReminderThreadId = 'maiyen_reminder';

  static String iosAlarmThreadId(String homeId) {
    return 'maiyen_alarm_$homeId';
  }

  static String iosSensorThreadId(String homeId) {
    return 'maiyen_sensor_$homeId';
  }

  static String iosChatThreadId(String safeIdentifier) {
    return 'maiyen_chat_$safeIdentifier';
  }
}
