import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeNotificationService {
  static const int maxNotifications = 120;

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
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError(
        "Không có tài khoản Firebase Auth đang đăng nhập",
      );
    }

    final cleanTargetUid = uid.trim();
    final cleanHomeId = homeId.trim();

    if (cleanTargetUid.isEmpty || cleanHomeId.isEmpty) {
      throw ArgumentError(
        "Thông báo thiếu uid hoặc homeId",
      );
    }

    if (senderUid != null &&
        senderUid.trim().isNotEmpty &&
        senderUid.trim() != currentUid) {
      throw StateError(
        "senderUid không khớp tài khoản đang đăng nhập",
      );
    }

    if (actorUid != null &&
        actorUid.trim().isNotEmpty &&
        actorUid.trim() != currentUid) {
      throw StateError(
        "actorUid không khớp tài khoản đang đăng nhập",
      );
    }

    // Mọi thông báo gửi sang tài khoản khác đều đi qua backend.
    if (cleanTargetUid != currentUid) {
      var resolvedOwnerUid =
          ownerUid?.trim() ?? "";

      if (resolvedOwnerUid.isEmpty) {
        final ownHomeSnap = await FirebaseDatabase.instance
            .ref(
          "accounts/$currentUid/homes/$cleanHomeId",
        )
            .get();

        if (ownHomeSnap.exists) {
          resolvedOwnerUid = currentUid;
        }
      }

      if (resolvedOwnerUid.isEmpty) {
        final sharedOwnerSnap =
        await FirebaseDatabase.instance
            .ref(
          "accounts/$currentUid/sharedHomes/$cleanHomeId/ownerUid",
        )
            .get();

        resolvedOwnerUid =
            sharedOwnerSnap.value?.toString().trim() ??
                "";
      }

      if (resolvedOwnerUid.isEmpty) {
        throw StateError(
          "Không xác định được chủ nhà cho thông báo gửi sang tài khoản khác",
        );
      }

      await notifyHome(
        ownerUid: resolvedOwnerUid,
        homeId: cleanHomeId,
        recipientUid: cleanTargetUid,
        type: type,
        title: title,
        message: message,
        category: category,
        severity: severity,
        deviceId: deviceId,
        senderUid: currentUid,
        entityType: entityType,
        entityId: entityId,
        homeName: homeName,
        data: data,
        includeActor: false,
        writeHomeTimeline: false,
      );

      return;
    }

    final resolvedHomeName = await resolveHomeName(
      homeId: cleanHomeId,
      ownerUid: ownerUid,
      notificationUid: currentUid,
      providedHomeName: homeName,
    );

    final now =
        DateTime.now().millisecondsSinceEpoch;

    final listRef = FirebaseDatabase.instance.ref(
      "accounts/$currentUid/notifications",
    );

    final notificationRef = listRef.push();

    await notificationRef.set(
      _compact({
        "id": notificationRef.key,
        "type": type,
        "category": category,
        "severity": severity,
        "title": _cleanTitle(title),
        "message": message,
        "homeId": cleanHomeId,
        "ownerUid": ownerUid,
        "homeName": resolvedHomeName,
        "deviceId": deviceId,
        "senderUid": currentUid,
        "actorUid": currentUid,
        "entityType": entityType,
        "entityId": entityId ?? deviceId,
        "data": _withHomeName(
          data,
          resolvedHomeName,
        ),
        "time": now,
        "read": false,
      }),
    );

    await _cleanupOldNotifications(currentUid);
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
    String? recipientUid,
    Iterable<String>? recipientUids,
    bool includeActor = true,
    bool writeHomeTimeline = true,
  }) async {
    final cleanOwnerUid = ownerUid.trim();
    final cleanHomeId = homeId.trim();
    final cleanType = type.trim();
    final cleanCategory = category.trim();
    final cleanSeverity = severity.trim();
    final cleanMessage = message.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return;
    }

    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError(
        "Không có tài khoản Firebase Auth đang đăng nhập",
      );
    }

    if (senderUid != null &&
        senderUid.trim().isNotEmpty &&
        senderUid.trim() != currentUid) {
      throw StateError(
        "senderUid không khớp tài khoản đang đăng nhập",
      );
    }

    if (recipientUids != null) {
      throw StateError(
        "Kênh backend chỉ hỗ trợ một recipientUid",
      );
    }

    if (cleanType.isEmpty ||
        cleanCategory.isEmpty ||
        cleanSeverity.isEmpty ||
        cleanMessage.isEmpty) {
      throw ArgumentError(
        "Thông báo thiếu type, category, severity hoặc message",
      );
    }

    String? cleanOptional(String? value) {
      final clean = value?.trim() ?? "";

      return clean.isEmpty ? null : clean;
    }

    final cleanRecipientUid =
    cleanOptional(recipientUid);

    final isTargeted =
        cleanRecipientUid != null;

    final resolvedHomeName = await resolveHomeName(
      homeId: cleanHomeId,
      ownerUid: cleanOwnerUid,
      providedHomeName: homeName,
    );

    final now =
        DateTime.now().millisecondsSinceEpoch;

    final requestRef = FirebaseDatabase.instance
        .ref("home_notification_requests")
        .push();

    await requestRef.set(
      _compact({
        "status": "pending",
        "requestedBy": currentUid,
        "ownerUid": cleanOwnerUid,
        "homeId": cleanHomeId,
        "recipientUid": cleanRecipientUid,
        "type": cleanType,
        "category": cleanCategory,
        "severity": cleanSeverity,
        "title": _cleanTitle(title),
        "message": cleanMessage,
        "homeName": resolvedHomeName,
        "deviceId": cleanOptional(deviceId),
        "entityType": cleanOptional(entityType),
        "entityId": cleanOptional(
          entityId ?? deviceId,
        ),
        "data": _withHomeName(
          data,
          resolvedHomeName,
        ),
        "includeActor":
        isTargeted ? false : includeActor,
        "writeHomeTimeline":
        isTargeted ? false : writeHomeTimeline,
        "time": now,
      }),
    );
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

  static String _cleanTitle(String title) {
    final cleanTitle = title.trim();

    return cleanTitle.isNotEmpty ? cleanTitle : "Thông báo";
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
