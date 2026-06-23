import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeNotificationService {
  static const int maxNotifications = 120;
  static const int maxHomeEvents = 240;

  static Future<void> addNotification({
    required String uid,
    required String type,
    required String title,
    required String message,
    required String homeId,
    String? deviceId,
    String category = "home",
    String severity = "info",
    String? senderUid,
    String? actorUid,
    String? entityType,
    String? entityId,
    String? ownerUid,
    String? homeName,
    Map<String, dynamic>? data,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final resolvedSenderUid = senderUid ?? currentUid ?? uid;
    final resolvedHomeName = await resolveHomeName(
      homeId: homeId,
      ownerUid: ownerUid,
      notificationUid: uid,
      providedHomeName: homeName,
    );
    final notificationData = _withHomeName(data, resolvedHomeName);
    final now = DateTime.now().millisecondsSinceEpoch;
    final listRef = FirebaseDatabase.instance.ref(
      "accounts/$uid/notifications",
    );
    final ref = listRef.push();

    await ref.set(
      _compact({
        "id": ref.key,
        "type": type,
        "category": category,
        "severity": severity,
        "title": _titleWithHomeName(title, resolvedHomeName),
        "message": message,
        "homeId": homeId,
        "homeName": resolvedHomeName,
        "deviceId": deviceId,
        "senderUid": resolvedSenderUid,
        "actorUid": actorUid ?? resolvedSenderUid,
        "entityType": entityType,
        "entityId": entityId ?? deviceId,
        "data": notificationData,
        "time": now,
        "read": false,
      }),
    );

    if (uid == currentUid) {
      await _cleanupOldNotifications(uid);
    }
  }

  static Future<void> notifyHome({
    required String ownerUid,
    required String homeId,
    required String type,
    required String title,
    required String message,
    String category = "home",
    String severity = "info",
    String? deviceId,
    String? senderUid,
    String? actorUid,
    String? entityType,
    String? entityId,
    String? homeName,
    Map<String, dynamic>? data,
    Iterable<String>? recipientUids,
    bool includeActor = true,
    bool writeHomeTimeline = true,
  }) async {
    if (ownerUid.isEmpty || homeId.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final resolvedSenderUid = senderUid ?? currentUid ?? ownerUid;
    final resolvedActorUid = actorUid ?? resolvedSenderUid;
    final recipients = recipientUids == null
        ? await homeRecipientUids(ownerUid: ownerUid, homeId: homeId)
        : recipientUids.toSet();
    final resolvedHomeName = await resolveHomeName(
      homeId: homeId,
      ownerUid: ownerUid,
      providedHomeName: homeName,
    );
    final notificationData = _withHomeName(data, resolvedHomeName);

    if (!includeActor) {
      recipients.remove(resolvedActorUid);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final root = FirebaseDatabase.instance.ref();
    final payload = _compact({
      "type": type,
      "category": category,
      "severity": severity,
      "title": _titleWithHomeName(title, resolvedHomeName),
      "message": message,
      "homeId": homeId,
      "homeName": resolvedHomeName,
      "deviceId": deviceId,
      "senderUid": resolvedSenderUid,
      "actorUid": resolvedActorUid,
      "entityType": entityType,
      "entityId": entityId ?? deviceId,
      "data": notificationData,
      "time": now,
      "read": false,
    });

    final updates = <String, Object?>{};

    if (writeHomeTimeline) {
      final eventRef = FirebaseDatabase.instance
          .ref("accounts/$ownerUid/homes/$homeId/events")
          .push();

      updates["accounts/$ownerUid/homes/$homeId/events/${eventRef.key}"] = {
        ...payload,
        "id": eventRef.key,
      };
    }

    for (final uid in recipients.where((value) => value.isNotEmpty)) {
      final notificationRef = FirebaseDatabase.instance
          .ref("accounts/$uid/notifications")
          .push();

      updates["accounts/$uid/notifications/${notificationRef.key}"] = {
        ...payload,
        "id": notificationRef.key,
      };
    }

    if (updates.isEmpty) return;

    try {
      await root.update(updates);
    } catch (_) {
      if (!writeHomeTimeline) rethrow;

      updates.removeWhere((path, _) => path.contains("/events/"));

      if (updates.isNotEmpty) {
        await root.update(updates);
      }
    }

    if (currentUid != null) {
      await _cleanupOldNotifications(currentUid);
    }

    if (currentUid == ownerUid) {
      await _cleanupOldHomeEvents(ownerUid: ownerUid, homeId: homeId);
    }
  }

  static Future<Set<String>> homeRecipientUids({
    required String ownerUid,
    required String homeId,
  }) async {
    final recipients = <String>{ownerUid};
    final snap = await FirebaseDatabase.instance
        .ref("sharedByHome/$homeId")
        .get();

    if (snap.value is! Map) return recipients;

    final shared = Map<String, dynamic>.from(snap.value as Map);

    for (final entry in shared.entries) {
      final uid = entry.key.toString();
      if (uid.isNotEmpty) {
        recipients.add(uid);
      }
    }

    return recipients;
  }

  static Future<String> resolveHomeName({
    required String homeId,
    String? ownerUid,
    String? notificationUid,
    String? providedHomeName,
  }) async {
    final provided = _cleanHomeName(providedHomeName);

    if (provided.isNotEmpty) return provided;

    final ownerName = await _readHomeName(ownerUid, homeId);

    if (ownerName.isNotEmpty) return ownerName;

    final accountName = await _readHomeName(notificationUid, homeId);

    if (accountName.isNotEmpty) return accountName;

    final sharedOwnerUid = await _readSharedOwnerUid(notificationUid, homeId);
    final sharedName = await _readHomeName(sharedOwnerUid, homeId);

    if (sharedName.isNotEmpty) return sharedName;

    return "Nhà chưa đặt tên";
  }

  static Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) async {
    await FirebaseDatabase.instance
        .ref("accounts/$uid/notifications/$notificationId/read")
        .set(true);
  }

  static Future<void> markAllAsRead({required String uid}) async {
    final snap = await FirebaseDatabase.instance
        .ref("accounts/$uid/notifications")
        .get();

    if (!snap.exists || snap.value is! Map) return;

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final updates = <String, Object?>{};

    for (final entry in raw.entries) {
      if (entry.value is! Map) continue;

      final data = Map<String, dynamic>.from(entry.value as Map);

      if (data["read"] != true) {
        updates["accounts/$uid/notifications/${entry.key}/read"] = true;
      }
    }

    if (updates.isNotEmpty) {
      await FirebaseDatabase.instance.ref().update(updates);
    }
  }

  static Future<void> clearAll({required String uid}) async {
    await FirebaseDatabase.instance.ref("accounts/$uid/notifications").remove();
  }

  static Future<void> _cleanupOldNotifications(String uid) async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref("accounts/$uid/notifications")
          .orderByChild("time")
          .get();

      if (!snap.exists || snap.value is! Map) return;

      final raw = Map<String, dynamic>.from(snap.value as Map);

      if (raw.length <= maxNotifications) return;

      final items = raw.entries.toList();

      items.sort((a, b) {
        if (a.value is! Map || b.value is! Map) return 0;

        final aData = Map<String, dynamic>.from(a.value as Map);
        final bData = Map<String, dynamic>.from(b.value as Map);

        final aTime = int.tryParse(aData["time"]?.toString() ?? "0") ?? 0;
        final bTime = int.tryParse(bData["time"]?.toString() ?? "0") ?? 0;

        return aTime.compareTo(bTime);
      });

      final removeCount = raw.length - maxNotifications;
      final updates = <String, Object?>{};

      for (int i = 0; i < removeCount; i++) {
        updates["accounts/$uid/notifications/${items[i].key}"] = null;
      }

      if (updates.isNotEmpty) {
        await FirebaseDatabase.instance.ref().update(updates);
      }
    } catch (_) {}
  }

  static Future<void> _cleanupOldHomeEvents({
    required String ownerUid,
    required String homeId,
  }) async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref("accounts/$ownerUid/homes/$homeId/events")
          .orderByChild("time")
          .get();

      if (!snap.exists || snap.value is! Map) return;

      final raw = Map<String, dynamic>.from(snap.value as Map);

      if (raw.length <= maxHomeEvents) return;

      final items = raw.entries.toList();

      items.sort((a, b) {
        if (a.value is! Map || b.value is! Map) return 0;

        final aData = Map<String, dynamic>.from(a.value as Map);
        final bData = Map<String, dynamic>.from(b.value as Map);

        final aTime = int.tryParse(aData["time"]?.toString() ?? "0") ?? 0;
        final bTime = int.tryParse(bData["time"]?.toString() ?? "0") ?? 0;

        return aTime.compareTo(bTime);
      });

      final removeCount = raw.length - maxHomeEvents;
      final updates = <String, Object?>{};

      for (int i = 0; i < removeCount; i++) {
        updates["accounts/$ownerUid/homes/$homeId/events/${items[i].key}"] =
            null;
      }

      if (updates.isNotEmpty) {
        await FirebaseDatabase.instance.ref().update(updates);
      }
    } catch (_) {}
  }

  static Map<String, dynamic> _compact(Map<String, dynamic> value) {
    final result = <String, dynamic>{};

    for (final entry in value.entries) {
      final entryValue = entry.value;

      if (entryValue == null) continue;

      if (entryValue is Map<String, dynamic>) {
        final compacted = _compact(entryValue);
        if (compacted.isNotEmpty) {
          result[entry.key] = compacted;
        }
      } else {
        result[entry.key] = entryValue;
      }
    }

    return result;
  }

  static Map<String, dynamic> _withHomeName(
    Map<String, dynamic>? data,
    String homeName,
  ) {
    final result = _compact(data ?? <String, dynamic>{});
    final existingHomeName = _cleanHomeName(result["homeName"]?.toString());

    result["homeName"] = existingHomeName.isNotEmpty
        ? existingHomeName
        : homeName;

    return result;
  }

  static String _titleWithHomeName(String title, String homeName) {
    final cleanTitle = title.trim().isNotEmpty ? title.trim() : "Thông báo";

    if (_containsHomeName(cleanTitle, homeName)) {
      return cleanTitle;
    }

    return "[$homeName] $cleanTitle";
  }

  static bool _containsHomeName(String text, String homeName) {
    return text.toLowerCase().contains(homeName.toLowerCase());
  }

  static String _cleanHomeName(String? value) {
    final name = value?.trim() ?? "";

    if (name.isEmpty) return "";
    if (name.startsWith("home_")) return "";

    return name;
  }

  static Future<String> _readHomeName(String? ownerUid, String homeId) async {
    if (ownerUid == null || ownerUid.isEmpty || homeId.isEmpty) return "";

    try {
      final snap = await FirebaseDatabase.instance
          .ref("accounts/$ownerUid/homes/$homeId/name")
          .get();

      return _cleanHomeName(snap.value?.toString());
    } catch (_) {
      return "";
    }
  }

  static Future<String> _readSharedOwnerUid(String? uid, String homeId) async {
    if (uid == null || uid.isEmpty || homeId.isEmpty) return "";

    try {
      final snap = await FirebaseDatabase.instance
          .ref("accounts/$uid/sharedHomes/$homeId/ownerUid")
          .get();

      return snap.value?.toString() ?? "";
    } catch (_) {
      return "";
    }
  }
}
