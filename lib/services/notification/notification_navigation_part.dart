part of '../notification_service.dart';

AppStrings get _strings =>
    AppStrings.fromLocale(appLanguageController.locale);

final ValueNotifier<Map<String, String>?> _notificationServiceChatOpenRequest =
    ValueNotifier<Map<String, String>?>(null);

final ValueNotifier<Map<String, String>?> _notificationServiceHubUpdateOpenRequest =
    ValueNotifier<Map<String, String>?>(null);

String _notificationServiceHubUpdatePayload({
  required String homeId,
  required String homeName,
  required String ownerUid,
  required String releaseId,
}) {
  return NotificationPayloadCodec.hubUpdatePayload(
    homeId: homeId,
    homeName: homeName,
    ownerUid: ownerUid,
    releaseId: releaseId,
  );
}

int _notificationServiceHubUpdateNotificationId(String homeId) {
  return NotificationPayloadCodec.hubUpdateNotificationId(homeId);
}

Future<void> _notificationServiceCancelHubUpdateNotification(String homeId) async {
  final cleanHomeId = homeId.trim();

  if (cleanHomeId.isEmpty) {
    return;
  }

  await localNotif.cancel(_notificationServiceHubUpdateNotificationId(cleanHomeId));
}

void _notificationServiceRequestOpenHubUpdate(Map<String, dynamic> rawData) {
  final homeId = rawData['homeId']?.toString().trim() ?? '';

  if (homeId.isEmpty) {
    return;
  }

  _notificationServiceHubUpdateOpenRequest.value = {
    'homeId': homeId,
    'homeName': rawData['homeName']?.toString().trim() ?? '',
    'ownerUid': rawData['ownerUid']?.toString().trim() ?? '',
    'releaseId': rawData['releaseId']?.toString().trim() ?? '',
    'nonce': DateTime.now().microsecondsSinceEpoch.toString(),
  };
}

bool _handleHubUpdatePayload(String payload) {
  final decoded = NotificationPayloadCodec.decodeHubUpdatePayload(payload);

  if (decoded == null) {
    return false;
  }

  _notificationServiceRequestOpenHubUpdate(decoded);
  return true;
}

String _notificationServiceHomeChatPayload({
  required String homeId,
  required String homeName,
  required String ownerUid,
  required String messageId,
}) {
  return NotificationPayloadCodec.homeChatPayload(
    homeId: homeId,
    homeName: homeName,
    ownerUid: ownerUid,
    messageId: messageId,
  );
}

int _notificationServiceHomeChatNotificationId(String homeId) {
  return NotificationPayloadCodec.homeChatNotificationId(homeId);
}

String _notificationServiceLocalizedExactTextOrRaw(String raw, AppStrings strings) {
  return NotificationPayloadCodec.localizedExactTextOrRaw(raw, strings);
}

String? _activeHomeChatId;

void _notificationServiceMarkHomeChatOpened(String homeId) {
  final cleanHomeId = homeId.trim();

  if (cleanHomeId.isEmpty) return;

  _activeHomeChatId = cleanHomeId;

  unawaited(localNotif.cancel(_notificationServiceHomeChatNotificationId(cleanHomeId)));
}

void _notificationServiceMarkHomeChatClosed(String homeId) {
  if (_activeHomeChatId == homeId.trim()) {
    _activeHomeChatId = null;
  }
}

void _notificationServiceRequestOpenHomeChat(Map<String, dynamic> rawData) {
  final homeId = rawData["homeId"]?.toString().trim() ?? "";

  if (homeId.isEmpty) return;

  _notificationServiceChatOpenRequest.value = {
    "homeId": homeId,
    "homeName": rawData["homeName"]?.toString().trim() ?? "",
    "ownerUid": rawData["ownerUid"]?.toString().trim() ?? "",
    "messageId": rawData["messageId"]?.toString().trim() ?? "",
    "nonce": DateTime.now().microsecondsSinceEpoch.toString(),
  };
}

bool _handleHomeChatPayload(String payload) {
  final decoded = NotificationPayloadCodec.decodeHomeChatPayload(payload);

  if (decoded == null) {
    return false;
  }

  _notificationServiceRequestOpenHomeChat(decoded);
  return true;
}
