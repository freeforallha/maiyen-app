import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';

class ChatService {
  static Stream<DatabaseEvent> chatStream() {
    return FirebaseDatabase.instance
        .ref(FirebasePaths.homeChats())
        .onValue;
  }

  static Future<void> markAsRead({
    required String homeId,
    required String uid,
  }) async {
    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeLastRead(homeId, uid))
        .set(DateTime.now().millisecondsSinceEpoch);
  }
}