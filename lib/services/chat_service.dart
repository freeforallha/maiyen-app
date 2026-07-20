import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';

class ChatTypingMember {
  const ChatTypingMember({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final int updatedAt;
}

class ChatService {
  static const int maxMessageLength = 1000;
  static const int typingStaleMillis = 12000;
  static const Map<String, String> _serverTimestamp = {".sv": "timestamp"};

  static Stream<DatabaseEvent> unreadCountersStream(String uid) {
    return FirebaseDatabase.instance.ref(FirebasePaths.chatUnread(uid)).onValue;
  }

  static Stream<DatabaseEvent> messagesStream(String homeId, {int limit = 80}) {
    return FirebaseDatabase.instance
        .ref(FirebasePaths.homeMessages(homeId))
        .orderByChild("time")
        .limitToLast(limit)
        .onValue;
  }

  static Stream<DatabaseEvent> typingStream(String homeId) {
    return FirebaseDatabase.instance
        .ref(FirebasePaths.homeTyping(homeId))
        .onValue;
  }

  static Future<String> sendMessage({
    required String homeId,
    required String uid,
    required String userName,
    required String userPhotoUrl,
    required String text,
    Map<String, String> mentions = const <String, String>{},
    String replyToMessageId = "",
    String replyToUid = "",
    String replyToName = "",
    String replyToText = "",
  }) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw ArgumentError("Message is empty");
    }

    if (trimmedText.length > maxMessageLength) {
      throw ArgumentError("Message is too long");
    }

    final messageRef = FirebaseDatabase.instance
        .ref(FirebasePaths.homeMessages(homeId))
        .push();

    final messageId = messageRef.key;

    if (messageId == null) {
      throw StateError("Could not create chat message id");
    }

    final normalizedMentions = <String, String>{};

    for (final entry in mentions.entries) {
      final mentionedUid = entry.key.trim();
      final mentionedName = _limited(entry.value, 80);

      if (mentionedUid.isEmpty || mentionedName.isEmpty) {
        continue;
      }

      normalizedMentions[mentionedUid] = mentionedName;
    }

    final messageData = <String, dynamic>{
      "uid": uid,
      "name": userName.trim(),
      "photoUrl": userPhotoUrl.trim(),
      "text": trimmedText,
      "time": _serverTimestamp,
    };

    if (normalizedMentions.isNotEmpty) {
      messageData["mentions"] = normalizedMentions;
    }

    final normalizedReplyMessageId = replyToMessageId.trim();

    if (normalizedReplyMessageId.isNotEmpty) {
      messageData["reply"] = {
        "messageId": normalizedReplyMessageId,
        "uid": replyToUid.trim(),
        "name": _limited(replyToName, 80),
        "text": _limited(replyToText, 180),
      };
    }

    await FirebaseDatabase.instance.ref().update({
      "${FirebasePaths.homeMessages(homeId)}/$messageId": messageData,
      FirebasePaths.homeLastRead(homeId, uid): _serverTimestamp,
      "${FirebasePaths.chatUnreadHome(uid, homeId)}/count": 0,
      "${FirebasePaths.chatUnreadHome(uid, homeId)}/lastReadAt":
          _serverTimestamp,
      "${FirebasePaths.chatUnreadHome(uid, homeId)}/updatedAt":
          _serverTimestamp,
    });

    return messageId;
  }

  static Future<void> markAsRead({
    required String homeId,
    required String uid,
    required int lastReadAt,
  }) async {
    if (lastReadAt <= 0) {
      return;
    }

    await FirebaseDatabase.instance.ref().update({
      FirebasePaths.homeLastRead(homeId, uid): lastReadAt,
      "${FirebasePaths.chatUnreadHome(uid, homeId)}/count": 0,
      "${FirebasePaths.chatUnreadHome(uid, homeId)}/lastReadAt": lastReadAt,
      "${FirebasePaths.chatUnreadHome(uid, homeId)}/updatedAt":
          _serverTimestamp,
    });
  }

  static Future<void> setTyping({
    required String homeId,
    required String uid,
    required String userName,
    required String userPhotoUrl,
    required bool isTyping,
  }) async {
    final ref = FirebaseDatabase.instance.ref(
      FirebasePaths.homeTypingMember(homeId, uid),
    );

    if (!isTyping) {
      await ref.remove();
      return;
    }

    await ref.set({
      "name": _limited(userName, 80),
      "photoUrl": _limited(userPhotoUrl, 500),
      "updatedAt": _serverTimestamp,
    });
  }

  static List<ChatTypingMember> activeTypingMembers({
    required dynamic typing,
    required String currentUid,
    DateTime? now,
  }) {
    if (typing == null || typing is! Map) return const [];

    final currentMillis = (now ?? DateTime.now()).millisecondsSinceEpoch;

    final staleBefore = currentMillis - typingStaleMillis;
    final typingMap = Map<String, dynamic>.from(typing);
    final members = <ChatTypingMember>[];

    for (final entry in typingMap.entries) {
      final memberUid = entry.key.toString();

      if (memberUid == currentUid || entry.value is! Map) {
        continue;
      }

      final member = Map<String, dynamic>.from(entry.value as Map);

      final updatedAt = _asMillis(member["updatedAt"]);

      if (updatedAt <= 0 || updatedAt < staleBefore) {
        continue;
      }

      members.add(
        ChatTypingMember(
          uid: memberUid,
          name: member["name"]?.toString() ?? "",
          photoUrl: member["photoUrl"]?.toString() ?? "",
          updatedAt: updatedAt,
        ),
      );
    }

    members.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return members;
  }

  static int unreadCounterCount(dynamic value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is double) {
      final count = value.toInt();
      return count < 0 ? 0 : count;
    }

    if (value is! Map) {
      return 0;
    }

    final data = Map<String, dynamic>.from(value);
    final count = int.tryParse(data["count"]?.toString() ?? "") ?? 0;

    return count < 0 ? 0 : count;
  }

  static int unreadCounterLastReadAt(dynamic value) {
    if (value is! Map) {
      return 0;
    }

    final data = Map<String, dynamic>.from(value);
    return _asMillis(data["lastReadAt"]);
  }

  static int _asMillis(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static String _limited(String value, int maxLength) {
    final trimmed = value.trim();

    if (trimmed.length <= maxLength) return trimmed;

    return trimmed.substring(0, maxLength);
  }
}
