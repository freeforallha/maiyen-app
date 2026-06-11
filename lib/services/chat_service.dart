import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';

class ChatService {
  static const int maxMessageLength = 1000;
  static const Map<String, String> _serverTimestamp = {".sv": "timestamp"};

  static Stream<DatabaseEvent> homeChatStream(String homeId) {
    return FirebaseDatabase.instance
        .ref(FirebasePaths.homeChat(homeId))
        .onValue;
  }

  static Stream<DatabaseEvent> messagesStream(String homeId, {int limit = 80}) {
    return FirebaseDatabase.instance
        .ref(FirebasePaths.homeMessages(homeId))
        .orderByChild("time")
        .limitToLast(limit)
        .onValue;
  }

  static Future<void> sendMessage({
    required String homeId,
    required String uid,
    required String userName,
    required String userPhotoUrl,
    required String text,
  }) async {
    final trimmedText = text.trim();

    if (trimmedText.isEmpty) return;
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

    await FirebaseDatabase.instance.ref().update({
      "${FirebasePaths.homeMessages(homeId)}/$messageId": {
        "uid": uid,
        "name": userName.trim(),
        "photoUrl": userPhotoUrl.trim(),
        "text": trimmedText,
        "time": _serverTimestamp,
      },
      FirebasePaths.homeLastRead(homeId, uid): _serverTimestamp,
    });
  }

  static Future<void> markAsRead({
    required String homeId,
    required String uid,
  }) async {
    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeLastRead(homeId, uid))
        .set(_serverTimestamp);
  }

  static int unreadCount({required dynamic homeChat, required String uid}) {
    if (homeChat == null) return 0;
    if (homeChat is! Map) return 0;

    final chat = Map<String, dynamic>.from(homeChat);
    final messagesRaw = chat["messages"];

    if (messagesRaw == null) return 0;
    if (messagesRaw is! Map) return 0;

    final messages = Map<String, dynamic>.from(messagesRaw);
    final lastRead = _lastReadTime(chat["lastRead"], uid);
    var count = 0;

    for (final messageRaw in messages.values) {
      final message = Map<String, dynamic>.from(messageRaw as Map);
      final sender = message["uid"]?.toString() ?? "";
      final time = _asMillis(message["time"]);

      if (sender != uid && time > lastRead) {
        count++;
      }
    }

    return count;
  }

  static int _lastReadTime(dynamic lastReadRaw, String uid) {
    if (lastReadRaw == null) return 0;
    if (lastReadRaw is! Map) return 0;

    final lastRead = Map<String, dynamic>.from(lastReadRaw);
    return _asMillis(lastRead[uid]);
  }

  static int _asMillis(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }
}
