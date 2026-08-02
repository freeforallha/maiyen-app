part of '../notification_service.dart';

Future<void>? _initializationFuture;

Future<void> _notificationServiceInit() {
  final existingFuture = _initializationFuture;

  if (existingFuture != null) {
    return existingFuture;
  }

  late final Future<void> future;
  future = _initInternal().catchError((Object error, StackTrace stackTrace) {
    if (identical(_initializationFuture, future)) {
      _initializationFuture = null;
    }

    Error.throwWithStackTrace(error, stackTrace);
  });
  _initializationFuture = future;

  return future;
}

Future<void> _initInternal() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    criticalAlert: IosNotificationConfig.criticalAlertsEntitlementEnabled,
  );

  // [iOS] Tắt hiển thị APNs tự động khi app đang foreground.
  // onMessage bên dưới sẽ tạo đúng một local notification đã bản địa hoá.
  // Android không bị ảnh hưởng bởi tuỳ chọn này.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  await localNotif.initialize(
    const InitializationSettings(
      android: AndroidNotificationConfig.initializationSettings,
      iOS: IosNotificationConfig.initializationSettings,
    ),
    onDidReceiveNotificationResponse: (response) async {
      final payload = response.payload ?? '';

      if (_handleHubUpdatePayload(payload)) {
        return;
      }

      if (_handleHomeChatPayload(payload)) {
        return;
      }

      if (await _notificationServiceHandleAlarmNotificationPayload(payload)) {
        return;
      }

      if (payload.startsWith('alarm_summary|')) {
        final strings = _strings;
        final parts = payload.split('|');
        final rawBody = parts.length > 1
            ? Uri.decodeComponent(parts[1])
            : strings.alarmFallback;

        final alarmItems = parts.length > 2
            ? Uri.decodeComponent(parts[2])
            : '';
        final alarmData = {'body': rawBody, 'alarmItemsJson': alarmItems};

        final presentation = buildAlarmNotificationPresentation(
          alarmData,
          strings,
        );

        _notificationServiceOpenAlarmPage(
          title: presentation.title,
          body: presentation.body,
          alarmItemsJson: alarmItems,
        );

        return;
      }

      if (payload == 'alarm') {
        final strings = _strings;
        final alarmData = {
          'body': _notificationServiceLastAlarmBody,
          'alarmItemsJson': _notificationServiceLastAlarmItemsJson,
        };

        final presentation = buildAlarmNotificationPresentation(
          alarmData,
          strings,
        );

        _notificationServiceOpenAlarmPage(
          title: presentation.title,
          body: presentation.body,
          alarmItemsJson: _notificationServiceLastAlarmItemsJson,
        );

        return;
      }

      if (payload == 'open_home' ||
          payload == 'schedule_notification' ||
          payload.startsWith('schedule_notification::') ||
          payload.startsWith('schedule_notification|')) {
        await _notificationServiceStopReminderNotification();
        return;
      }
    },
  );

  final launchDetails = await localNotif.getNotificationAppLaunchDetails();

  if (launchDetails?.didNotificationLaunchApp == true) {
    final launchPayload = launchDetails?.notificationResponse?.payload ?? '';

    final handledHubUpdate = _handleHubUpdatePayload(launchPayload);
    final handledChat = handledHubUpdate
        ? false
        : _handleHomeChatPayload(launchPayload);

    final handledAlarm = handledHubUpdate || handledChat
        ? false
        : await _notificationServiceHandleAlarmNotificationPayload(
            launchPayload,
          );

    if (!handledHubUpdate &&
        !handledChat &&
        !handledAlarm &&
        (launchPayload == 'open_home' ||
            launchPayload == 'schedule_notification' ||
            launchPayload.startsWith('schedule_notification::') ||
            launchPayload.startsWith('schedule_notification|'))) {
      await _notificationServiceStopReminderNotification();
    }
  }

  await AndroidNotificationConfig.configure(localNotif, strings: _strings);
}
