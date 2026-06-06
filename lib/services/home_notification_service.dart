import 'package:firebase_database/firebase_database.dart';

class HomeNotificationService {
  static Future<void> addNotification({
    required String uid,
    required String type,
    required String title,
    required String message,
    required String homeId,
    String? deviceId,
  }) async {
    final ref = FirebaseDatabase.instance
        .ref("accounts/$uid/notifications")
        .push();

    await ref.set({
      "id": ref.key,
      "type": type,
      "title": title,
      "message": message,
      "homeId": homeId,
      "deviceId": deviceId,
      "time": DateTime.now().millisecondsSinceEpoch,
      "read": false,
    });
  }

  static Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await FirebaseDatabase.instance
        .ref("accounts/$uid/notifications/$notificationId/read")
        .set(true);
  }
}