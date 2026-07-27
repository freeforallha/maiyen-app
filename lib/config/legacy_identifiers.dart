/// Các định danh kỹ thuật cũ phải được giữ nguyên để MaiYen tiếp tục
/// tương thích với dữ liệu, thông báo và tác vụ nền đã được tạo bởi các bản
/// SafeHome trước đây.
///
/// Không đổi giá trị trong file này nếu chưa có migration đọc song song và
/// rollback tương ứng. Tên class dùng MaiYen để phần còn lại của mã nguồn không
/// tiếp tục phát tán tên thương hiệu cũ.
class MaiYenLegacyIdentifiers {
  const MaiYenLegacyIdentifiers._();

  static const String legacyBrandToken = 'safehome';
  static const String applicationId = 'com.myfamily.safehome';

  // QR chia sẻ nhà.
  static const String joinHomeQrPrefix = 'safehome_join|';
  static const String joinMultipleHomesQrPrefix = 'safehome_join_multi|';
  static const String joinHomeQrFamilyPrefix = 'safehome_join';

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
  static const String languageStorageKey = 'safehome_language_code';
  static const String loginEmailStorageKey = 'safehome_email';
  static const String legacyPasswordStorageKey = 'safehome_password';
  static const String installationIdStorageKey =
      'safehome_fcm_installation_id';
  static const String lastOpenAtStorageKey = 'safehome_last_open_at';
  static const String previousOpenAtStorageKey =
      'safehome_previous_open_at';
  static const String pendingPresenceEventsStorageKey =
      'safehome_pending_presence_events_v1';
  static const String autoAwayForegroundTaskConfigStorageKey =
      'safehome_auto_away_foreground_task_config_v1';

  static String deviceOrderStorageKey({
    required String uid,
    required String homeId,
  }) {
    return 'safehome_device_order_${uid}_$homeId';
  }

  static String activeSessionStorageKey(String uid) {
    return 'safehome_active_session_id_${uid.trim()}';
  }

  static String interactiveLoginRequiredStorageKey(String uid) {
    return 'safehome_interactive_login_required_${uid.trim()}';
  }

  // Auto Away và native bridge Android.
  static const String legacyAutoAwayGeofencePrefix = 'safehome_auto_away';
  static const String autoAwayGeofencePrefixV2 = 'safehome_auto_away_v2';
  static const String androidNativeAlarmPermissionChannel =
      'safehome/native_alarm_permission';
  static const String androidAutoAwayLocationChannelId =
      'safehome_auto_away_location_v1';

  // Android notification IDs. Các ID này không được đổi vì Android ghi nhớ
  // thiết lập âm thanh/quyền theo channel ID.
  static const String androidLegacyAlarmChannelId =
      'alarm_channel_silent_v3';
  static const String androidAlarmFullscreenChannelId =
      'safehome_alarm_fullscreen_sound_v6';
  static const String androidEmergencyPriorityChannelId =
      'safehome_emergency_priority_v2';
  static const String androidScheduleFullscreenChannelId =
      'safehome_schedule_fullscreen_channel_v2';
  static const String androidReminderPriorityChannelId =
      'safehome_reminder_priority_v3';
  static const String androidChatChannelId = 'safehome_chat_channel_v2';
  static const String androidSensorNotificationChannelId =
      'safehome_sensor_notification_v1';
  static const String androidNotificationIconName = 'ic_stat_safehome';

  static String sensorNotificationTag({
    required String homeId,
    required String deviceId,
  }) {
    return 'safehome_sensor_${homeId}_$deviceId';
  }

  // iOS notification categories và thread identifiers.
  static const String iosCriticalAlertsDartDefine =
      'SAFEHOME_IOS_CRITICAL_ALERTS';
  static const String iosSecurityAlarmCategoryId =
      'SAFEHOME_SECURITY_ALARM';
  static const String iosEmergencyAlarmCategoryId =
      'SAFEHOME_EMERGENCY_ALARM';
  static const String iosReminderCategoryId = 'SAFEHOME_REMINDER';
  static const String iosSensorCategoryId = 'SAFEHOME_SENSOR';
  static const String iosChatCategoryId = 'SAFEHOME_CHAT';
  static const String iosReminderThreadId = 'safehome_reminder';

  static String iosAlarmThreadId(String homeId) {
    return 'safehome_alarm_$homeId';
  }

  static String iosSensorThreadId(String homeId) {
    return 'safehome_sensor_$homeId';
  }

  static String iosChatThreadId(String safeIdentifier) {
    return 'safehome_chat_$safeIdentifier';
  }
}
