import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:maiyen_app/localization/app_strings.dart';
import 'package:maiyen_app/localization/hub_update_strings.dart';
import 'package:maiyen_app/helpers/debug_log.dart';

import '../../../config/brand_config.dart';
import '../../../config/maiyen_identifiers.dart';

class AndroidNotificationConfig {
  const AndroidNotificationConfig._();

  // FLAG_INSISTENT: lặp âm thanh của notification cho tới khi notification
  // bị hủy. Đây là lớp âm thanh dự phòng khi Flutter Activity chưa mở được.
  static const int _notificationFlagInsistent = 0x00000004;
  static const RawResourceAndroidNotificationSound _alarmSirenSound =
      RawResourceAndroidNotificationSound('alarm_siren');

  static const alarmChannelId =
      MaiYenIdentifiers.androidAlarmChannelId;
  static const alarmFullscreenChannelId =
      MaiYenIdentifiers.androidAlarmFullscreenChannelId;
  static const emergencyPriorityChannelId =
      MaiYenIdentifiers.androidEmergencyPriorityChannelId;
  static const scheduleFullscreenChannelId =
      MaiYenIdentifiers.androidScheduleFullscreenChannelId;
  static const reminderPriorityChannelId =
      MaiYenIdentifiers.androidReminderPriorityChannelId;
  static const chatChannelId =
      MaiYenIdentifiers.androidChatChannelId;
  static const sensorNotificationChannelId =
      MaiYenIdentifiers.androidSensorNotificationChannelId;
  static const hubUpdateChannelId = 'maiyen_hub_updates_v1';

  static const initializationSettings = AndroidInitializationSettings(
    MaiYenIdentifiers.androidNotificationIconName,
  );

  static bool get isAndroid => Platform.isAndroid;

  static Future<void> configure(
    FlutterLocalNotificationsPlugin localNotif, {
    required AppStrings strings,
  }) async {
    if (!isAndroid) {
      return;
    }

    final androidPlugin = localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final fullScreenPermission = await androidPlugin
        ?.requestFullScreenIntentPermission();

    safeDebugPrint('FULL_SCREEN_INTENT_PERMISSION: $fullScreenPermission');

    await createChannels(localNotif, strings: strings);
  }

  static Future<void> createChannels(
    FlutterLocalNotificationsPlugin localNotif, {
    required AppStrings strings,
  }) async {
    final androidPlugin = localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final alarmChannel = AndroidNotificationChannel(
      alarmChannelId,
      strings.alarmNotification,
      description: strings.androidAlarmChannelDescription(),
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    final alarmFullscreenChannel = AndroidNotificationChannel(
      alarmFullscreenChannelId,
      strings.androidAlarmFullscreenChannelName(),
      description: strings.androidAlarmFullscreenChannelDescription(),
      importance: Importance.max,
      playSound: true,
      sound: _alarmSirenSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );

    final emergencyPriorityChannel = AndroidNotificationChannel(
      emergencyPriorityChannelId,
      strings.androidEmergencyPriorityChannelName(),
      description: strings.androidEmergencyPriorityChannelDescription(),
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final scheduleFullscreenChannel = AndroidNotificationChannel(
      scheduleFullscreenChannelId,
      strings.androidScheduleFullscreenChannelName(),
      description: strings.androidScheduleFullscreenChannelDescription(),
      importance: Importance.max,
      playSound: false,
    );

    final reminderChannel = AndroidNotificationChannel(
      reminderPriorityChannelId,
      strings.androidReminderPriorityChannelName(),
      description: strings.androidReminderPriorityChannelDescription(),
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final chatChannel = AndroidNotificationChannel(
      chatChannelId,
      strings.homeChatTitle(),
      description: strings.androidHomeChatChannelDescription(),
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final sensorNotificationChannel = AndroidNotificationChannel(
      sensorNotificationChannelId,
      strings.t('Thông báo cảm biến'),
      description: strings.t(
        'Thông báo thông thường khi cảm biến phát hiện sự kiện.',
      ),
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final hubUpdateChannel = AndroidNotificationChannel(
      hubUpdateChannelId,
      strings.hubUpdateSectionTitle,
      description: strings.hubUpdateSectionTitle,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(alarmFullscreenChannel);
    await androidPlugin?.createNotificationChannel(emergencyPriorityChannel);
    await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(sensorNotificationChannel);
    await androidPlugin?.createNotificationChannel(hubUpdateChannel);
  }

  static Future<void> createBackgroundChannels(
    FlutterLocalNotificationsPlugin localNotif, {
    required AppStrings strings,
  }) async {
    final androidPlugin = localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final alarmFullscreenChannel = AndroidNotificationChannel(
      alarmFullscreenChannelId,
      strings.androidAlarmFullscreenChannelName(),
      description: strings.androidAlarmFullscreenChannelDescription(),
      importance: Importance.max,
      playSound: true,
      sound: _alarmSirenSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );

    final emergencyPriorityChannel = AndroidNotificationChannel(
      emergencyPriorityChannelId,
      strings.androidEmergencyPriorityChannelName(),
      description: strings.androidEmergencyPriorityChannelDescription(),
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final reminderPriorityChannel = AndroidNotificationChannel(
      reminderPriorityChannelId,
      strings.androidReminderPriorityChannelName(),
      description: strings.androidReminderPriorityChannelDescription(),
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final chatChannel = AndroidNotificationChannel(
      chatChannelId,
      strings.homeChatTitle(),
      description: strings.androidHomeChatChannelDescription(),
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final sensorNotificationChannel = AndroidNotificationChannel(
      sensorNotificationChannelId,
      strings.t('Thông báo cảm biến'),
      description: strings.t(
        'Thông báo thông thường khi cảm biến phát hiện sự kiện.',
      ),
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final hubUpdateChannel = AndroidNotificationChannel(
      hubUpdateChannelId,
      strings.hubUpdateSectionTitle,
      description: strings.hubUpdateSectionTitle,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(alarmFullscreenChannel);
    await androidPlugin?.createNotificationChannel(emergencyPriorityChannel);
    await androidPlugin?.createNotificationChannel(reminderPriorityChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(sensorNotificationChannel);
    await androidPlugin?.createNotificationChannel(hubUpdateChannel);
  }

  static AndroidNotificationDetails hubUpdateDetails({
    required String title,
    required String body,
    required AppStrings strings,
    required bool critical,
  }) {
    return AndroidNotificationDetails(
      hubUpdateChannelId,
      strings.hubUpdateSectionTitle,
      channelDescription: strings.hubUpdateSectionTitle,
      visibility: NotificationVisibility.public,
      importance: Importance.high,
      priority: critical ? Priority.max : Priority.high,
      category: AndroidNotificationCategory.status,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: BrandConfig.appName,
      ),
    );
  }

  static AndroidNotificationDetails priorityAlarmDetails({
    required String title,
    required String body,
    required AppStrings strings,
  }) {
    return AndroidNotificationDetails(
      emergencyPriorityChannelId,
      strings.androidEmergencyPriorityChannelName(),
      channelDescription: strings.androidEmergencyPriorityChannelDescription(),
      visibility: NotificationVisibility.public,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
      fullScreenIntent: false,
      playSound: true,
      enableVibration: true,
      onlyAlertOnce: false,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: BrandConfig.appName,
      ),
    );
  }

  static AndroidNotificationDetails fullscreenAlarmDetails({
    required String title,
    required String body,
    required AppStrings strings,
  }) {
    return AndroidNotificationDetails(
      alarmFullscreenChannelId,
      strings.androidAlarmFullscreenChannelName(),
      channelDescription: strings.androidAlarmFullscreenChannelDescription(),
      visibility: NotificationVisibility.public,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
      fullScreenIntent: true,
      playSound: true,
      sound: _alarmSirenSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      additionalFlags: Int32List.fromList(
        const <int>[_notificationFlagInsistent],
      ),
      enableVibration: true,
      onlyAlertOnce: false,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: BrandConfig.appName,
      ),
    );
  }

  static AndroidNotificationDetails chatDetails({
    required String title,
    required String body,
    required AppStrings strings,
    String? tag,
  }) {
    return AndroidNotificationDetails(
      chatChannelId,
      strings.homeChatTitle(),
      channelDescription: strings.androidHomeChatChannelDescription(),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );
  }

  static AndroidNotificationDetails sensorNotificationDetails({
    required String title,
    required String body,
    required AppStrings strings,
    String? tag,
  }) {
    return AndroidNotificationDetails(
      sensorNotificationChannelId,
      strings.t('Thông báo cảm biến'),
      channelDescription: strings.t(
        'Thông báo thông thường khi cảm biến phát hiện sự kiện.',
      ),
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.status,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
    );
  }

  static AndroidNotificationDetails reminderDetails({
    required String title,
    required String body,
    required String bigText,
    required AppStrings strings,
  }) {
    return AndroidNotificationDetails(
      reminderPriorityChannelId,
      strings.androidReminderPriorityChannelName(),
      channelDescription: strings.androidReminderPriorityChannelDescription(),
      visibility: NotificationVisibility.public,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.reminder,
      autoCancel: false,
      ongoing: true,
      fullScreenIntent: false,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        bigText,
        contentTitle: title,
        summaryText: BrandConfig.appName,
      ),
    );
  }
}
