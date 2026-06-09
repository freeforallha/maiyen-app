import 'package:firebase_database/firebase_database.dart';

class HomeNotificationService {
  static const int maxNotifications = 60;

  static Future<void> addNotification({
    required String uid,
    required String type,
    required String title,
    required String message,
    required String homeId,
    String? deviceId,
  }) async {
    final listRef = FirebaseDatabase.instance
        .ref("accounts/$uid/notifications");

    final ref = listRef.push();
    final now = DateTime.now().millisecondsSinceEpoch;

    await ref.set({
      "id": ref.key,
      "type": type,
      "title": title,
      "message": message,
      "homeId": homeId,
      "deviceId": deviceId,
      "time": now,
      "read": false,
    });

    await _cleanupOldNotifications(uid);
  }

  static Future<void> _cleanupOldNotifications(String uid) async {
    final snap = await FirebaseDatabase.instance
        .ref("accounts/$uid/notifications")
        .orderByChild("time")
        .get();

    if (!snap.exists || snap.value is! Map) return;

    final raw = Map<String, dynamic>.from(snap.value as Map);

    if (raw.length <= maxNotifications) return;

    final items = raw.entries.toList();

    items.sort((a, b) {
      final aData = Map<String, dynamic>.from(a.value);
      final bData = Map<String, dynamic>.from(b.value);

      final aTime = int.tryParse(aData["time"]?.toString() ?? "0") ?? 0;
      final bTime = int.tryParse(bData["time"]?.toString() ?? "0") ?? 0;

      return aTime.compareTo(bTime);
    });

    final removeCount = raw.length - maxNotifications;
    final updates = <String, dynamic>{};

    for (int i = 0; i < removeCount; i++) {
      updates["accounts/$uid/notifications/${items[i].key}"] = null;
    }

    if (updates.isNotEmpty) {
      await FirebaseDatabase.instance.ref().update(updates);
    }
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