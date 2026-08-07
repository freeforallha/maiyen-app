part of '../notification_service.dart';

Future<void> _notificationServiceShowSensorNotification({
  required Map<String, dynamic> data,
}) async {
  final strings = _strings;
  final homeId = data['homeId']?.toString().trim() ?? '';
  final deviceId = data['deviceId']?.toString().trim() ?? '';
  final rawTitle = data['title']?.toString().trim() ?? '';
  final rawBody = data['body']?.toString().trim() ?? '';
  final title = rawTitle.isNotEmpty
      ? _notificationServiceLocalizedExactTextOrRaw(rawTitle, strings)
      : strings.t('Thông báo cảm biến');
  final body = rawBody.isNotEmpty
      ? _notificationServiceLocalizedExactTextOrRaw(rawBody, strings)
      : strings.t('Cảm biến vừa phát hiện một sự kiện.');
  final identity = '$homeId|$deviceId';

  final androidDetails = AndroidNotificationConfig.sensorNotificationDetails(
    title: title,
    body: body,
    strings: strings,
    tag: MaiYenIdentifiers.sensorNotificationTag(
      homeId: homeId,
      deviceId: deviceId,
    ),
  );

  final iosDetails = IosNotificationConfig.sensorDetails(data: data);

  await localNotif.show(
    _sensorNotificationId(identity),
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: 'sensor_notification::$homeId',
  );
}

int _sensorNotificationId(String identity) {
  var hash = 0;

  for (final codeUnit in identity.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }

  return 1200000 + (hash % 700000);
}

Future<void> _notificationServiceShowChatNotification({
  required Map<String, dynamic> data,
}) async {
  final strings = _strings;
  final homeId = data["homeId"]?.toString().trim() ?? "";

  if (homeId.isEmpty || _activeHomeChatId == homeId) {
    return;
  }

  final homeName = data["homeName"]?.toString().trim() ?? "";
  final senderName = data["senderName"]?.toString().trim() ?? "";
  final rawTitle = data["title"]?.toString().trim() ?? "";
  final rawBody = data["body"]?.toString().trim() ?? "";

  final unreadCount = int.tryParse(data["unreadCount"]?.toString() ?? "1") ?? 1;

  final title = rawTitle.isNotEmpty
      ? _notificationServiceLocalizedExactTextOrRaw(rawTitle, strings)
      : unreadCount > 1
      ? "${homeName.isNotEmpty ? homeName : "HomeChat"} · "
            "${strings.homeChatNewMessages(unreadCount)}"
      : homeName.isNotEmpty
      ? homeName
      : strings.homeChatTitle();

  final body = rawBody.isNotEmpty
      ? _notificationServiceLocalizedExactTextOrRaw(rawBody, strings)
      : senderName.isNotEmpty
      ? strings.homeChatSenderMessage(senderName)
      : strings.homeChatNewMessage();

  final androidDetails = AndroidNotificationConfig.chatDetails(
    title: title,
    body: body,
    strings: strings,
  );

  final iosDetails = IosNotificationConfig.chatDetails(homeId: homeId);

  final payload = _notificationServiceHomeChatPayload(
    homeId: homeId,
    homeName: homeName,
    ownerUid: data["ownerUid"]?.toString() ?? "",
    messageId: data["messageId"]?.toString() ?? "",
  );

  await localNotif.show(
    _notificationServiceHomeChatNotificationId(homeId),
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: payload,
  );
}

Future<void> _notificationServiceStopAlarmNotification() async {
  await localNotif.cancel(_notificationServiceAlarmNotificationId);
}

Future<void> _notificationServiceStopEmergencyNotification() async {
  await localNotif.cancel(_notificationServiceEmergencyNotificationId);
}

Future<void> _notificationServiceStopAllAlarmNotifications() async {
  await Future.wait([
    _notificationServiceStopAlarmNotification(),
    _notificationServiceStopEmergencyNotification(),
  ]);
}

Future<void> _notificationServiceStopReminderNotification() async {
  await localNotif.cancel(999998);
  _resetReminderSession();
}
