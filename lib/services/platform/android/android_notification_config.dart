import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:safehome_app/localization/app_strings.dart';
import 'package:safehome_app/helpers/debug_log.dart';

class AndroidNotificationConfig {
  const AndroidNotificationConfig._();

  static const legacyAlarmChannelId = 'alarm_channel_silent_v3';
  static const alarmFullscreenChannelId = 'safehome_alarm_fullscreen_sound_v6';
  static const emergencyPriorityChannelId = 'safehome_emergency_priority_v2';
  static const scheduleFullscreenChannelId =
      'safehome_schedule_fullscreen_channel_v2';
  static const reminderPriorityChannelId = 'safehome_reminder_priority_v3';
  static const chatChannelId = 'safehome_chat_channel_v2';
  static const sensorNotificationChannelId = 'safehome_sensor_notification_v1';

  static const initializationSettings = AndroidInitializationSettings(
    'ic_stat_safehome',
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

    final legacyAlarmChannel = AndroidNotificationChannel(
      legacyAlarmChannelId,
      strings.alarmNotification,
      description: strings.androidLegacyAlarmChannelDescription(),
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

    await androidPlugin?.createNotificationChannel(legacyAlarmChannel);
    await androidPlugin?.createNotificationChannel(alarmFullscreenChannel);
    await androidPlugin?.createNotificationChannel(emergencyPriorityChannel);
    await androidPlugin?.createNotificationChannel(scheduleFullscreenChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(sensorNotificationChannel);
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

    await androidPlugin?.createNotificationChannel(alarmFullscreenChannel);
    await androidPlugin?.createNotificationChannel(emergencyPriorityChannel);
    await androidPlugin?.createNotificationChannel(reminderPriorityChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(sensorNotificationChannel);
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
        summaryText: 'SafeHome',
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
      enableVibration: true,
      onlyAlertOnce: false,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'SafeHome',
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
      tag: tag,
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
      tag: tag,
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
        summaryText: 'SafeHome',
      ),
    );
  }
}
