import 'dart:convert';

import '../../localization/app_strings.dart';

class NotificationPayloadCodec {
  const NotificationPayloadCodec._();

  static String hubUpdatePayload({
    required String homeId,
    required String homeName,
    required String ownerUid,
    required String releaseId,
  }) {
    return encodePayload('hub_update', {
      'homeId': homeId,
      'homeName': homeName,
      'ownerUid': ownerUid,
      'releaseId': releaseId,
    });
  }

  static int hubUpdateNotificationId(String homeId) {
    return stableNotificationId(homeId, base: 910000, range: 40000);
  }

  static Map<String, dynamic>? decodeHubUpdatePayload(String payload) {
    return decodePayload('hub_update', payload);
  }

  static String homeChatPayload({
    required String homeId,
    required String homeName,
    required String ownerUid,
    required String messageId,
  }) {
    return encodePayload('home_chat', {
      'homeId': homeId,
      'homeName': homeName,
      'ownerUid': ownerUid,
      'messageId': messageId,
    });
  }

  static int homeChatNotificationId(String homeId) {
    return stableNotificationId(homeId, base: 200000, range: 700000);
  }

  static Map<String, dynamic>? decodeHomeChatPayload(String payload) {
    return decodePayload('home_chat', payload);
  }

  static String encodePayload(String prefix, Map<String, dynamic> data) {
    return '$prefix::${jsonEncode(data)}';
  }

  static Map<String, dynamic>? decodePayload(String prefix, String payload) {
    final marker = '$prefix::';

    if (!payload.startsWith(marker)) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload.substring(marker.length));

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static int stableNotificationId(
    String identity, {
    required int base,
    required int range,
  }) {
    var hash = 0;

    for (final codeUnit in identity.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return base + (hash % range);
  }

  static String localizedExactTextOrRaw(String raw, AppStrings strings) {
    final clean = raw.trim();

    if (clean.isEmpty) {
      return '';
    }

    final exact = strings.t(clean);
    if (exact != clean) {
      return exact;
    }

    const newMessageInPrefix = 'Tin nhắn mới trong ';
    if (clean.startsWith(newMessageInPrefix)) {
      final homeName = clean.replaceFirst(newMessageInPrefix, '').trim();
      if (homeName.isNotEmpty) {
        return strings.newMessageInHome(homeName);
      }
    }

    const sentMessageSuffix = ' đã gửi một tin nhắn';
    if (clean.endsWith(sentMessageSuffix)) {
      final senderName = clean.replaceFirst(sentMessageSuffix, '').trim();
      if (senderName.isNotEmpty) {
        return strings.homeChatSenderMessage(senderName);
      }
    }

    return strings.statusText(clean);
  }
}
