import 'package:firebase_database/firebase_database.dart';

import '../helpers/firebase_paths.dart';

class ShareService {
  static final _db = FirebaseDatabase.instance;

  static Future<String?> findUidByEmail(String email) async {
    final snap = await _db.ref("accounts").get();

    if (!snap.exists) return null;

    final accounts = Map<String, dynamic>.from(
      snap.value as Map,
    );

    for (final entry in accounts.entries) {
      final data = Map<String, dynamic>.from(entry.value);

      final mail = data["email"]?.toString().trim().toLowerCase();

      if (mail == email.trim().toLowerCase()) {
        return entry.key;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>> loadAccount(String uid) async {
    final snap = await _db.ref(FirebasePaths.account(uid)).get();

    if (!snap.exists) {
      return {};
    }

    return Map<String, dynamic>.from(
      snap.value as Map,
    );
  }

  static Future<void> sendShareRequest({
    required String ownerUid,
    required String targetUid,
    required String homeId,
    required String ownerEmail,
    required Map<String, dynamic> targetData,
    required String targetEmail,
  }) async {
    final targetProfile = targetData["profile"] == null
        ? {}
        : Map<String, dynamic>.from(
      targetData["profile"] as Map,
    );

    await _db.ref(FirebasePaths.sharedMember(homeId, targetUid)).set({
      "role": "member",
      "email": targetData["email"] ?? targetEmail,
      "name": targetProfile["name"] ?? "",
      "photoUrl": targetProfile["photoUrl"] ?? "",
      "sharedAt": DateTime.now().millisecondsSinceEpoch,
    });

    await _db.ref(FirebasePaths.shareRequest(targetUid, homeId)).set({
      "ownerUid": ownerUid,
      "homeId": homeId,
      "ownerEmail": ownerEmail,
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    await _db
        .ref("${FirebasePaths.shareList(ownerUid, homeId)}/$targetUid")
        .set({
      "email": targetEmail,
      "sharedAt": DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> transferOwner({
    required String oldOwnerUid,
    required String newOwnerUid,
    required String homeId,
  }) async {
    final currentSnap = await _db.ref(FirebasePaths.home(oldOwnerUid, homeId))
        .get();

    if (!currentSnap.exists) {
      throw Exception("Không tìm thấy Home hiện tại");
    }

    final homeData = Map<String, dynamic>.from(
      currentSnap.value as Map,
    );

    homeData["_ownerUid"] = newOwnerUid;
    homeData["_shared"] = false;

    await _db.ref(FirebasePaths.sharedHome(newOwnerUid, homeId)).remove();

    await _db.ref(FirebasePaths.home(newOwnerUid, homeId)).set(homeData);

    final targetOrderSnap = await _db
        .ref(FirebasePaths.homeOrder(newOwnerUid))
        .get();

    List<dynamic> targetOrder = [];

    if (targetOrderSnap.exists && targetOrderSnap.value is List) {
      targetOrder = List<dynamic>.from(targetOrderSnap.value as List);
    }

    if (!targetOrder.contains(homeId)) {
      targetOrder.add(homeId);
    }

    await _db.ref(FirebasePaths.homeOrder(newOwnerUid)).set(targetOrder);

    await _db.ref(FirebasePaths.sharedHome(oldOwnerUid, homeId)).set({
      "ownerUid": newOwnerUid,
      "role": "member",
    });

    final oldOwnerData = await loadAccount(oldOwnerUid);

    final oldOwnerProfile = oldOwnerData["profile"] is Map
        ? Map<String, dynamic>.from(oldOwnerData["profile"] as Map)
        : <String, dynamic>{};

    await _db
        .ref(FirebasePaths.sharedMember(homeId, oldOwnerUid))
        .set({
      "role": "member",
      "email": oldOwnerData["email"] ?? "",
      "name": oldOwnerProfile["name"] ?? oldOwnerData["name"] ?? "",
      "photoUrl": oldOwnerProfile["photoUrl"] ?? oldOwnerData["photoUrl"] ?? "",
      "sharedAt": DateTime.now().millisecondsSinceEpoch,
    });

    await _db.ref(FirebasePaths.home(oldOwnerUid, homeId)).remove();
  }
  static Future<void> leaveSharedHome({
    required String uid,
    required String ownerUid,
    required String homeId,
  }) async {
    await _db.ref(FirebasePaths.sharedHome(uid, homeId)).remove();

    await _db.ref(FirebasePaths.sharedMember(homeId, uid)).remove();

    await _db.ref("${FirebasePaths.shareList(ownerUid, homeId)}/$uid").remove();
  }
  static Future<void> deleteOwnedHome({
    required String ownerUid,
    required String homeId,
  }) async {
    final sharedSnap = await _db
        .ref(FirebasePaths.sharedByHome(homeId))
        .get();

    if (sharedSnap.exists) {
      final sharedMap = Map<String, dynamic>.from(
        sharedSnap.value as Map,
      );

      for (final sharedUid in sharedMap.keys) {
        await _db
            .ref(FirebasePaths.sharedHome(sharedUid, homeId))
            .remove();
      }
    }

    await _db
        .ref(FirebasePaths.sharedByHome(homeId))
        .remove();

    await _db
        .ref(FirebasePaths.home(ownerUid, homeId))
        .remove();
  }
}