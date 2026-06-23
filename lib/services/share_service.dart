import 'package:firebase_database/firebase_database.dart';
import '../services/home_notification_service.dart';
import '../helpers/firebase_paths.dart';

class ShareService {
  static final _db = FirebaseDatabase.instance;

  static Future<String?> findUidByEmail(String email) async {
    final targetEmail = email.trim().toLowerCase();

    final snap = await _db
        .ref("userDirectory")
        .orderByChild("email")
        .equalTo(targetEmail)
        .get();

    if (!snap.exists || snap.value is! Map) {
      return null;
    }

    final users = Map<String, dynamic>.from(snap.value as Map);

    if (users.isEmpty) {
      return null;
    }

    return users.keys.first.toString();
  }

  static Future<Map<String, dynamic>> loadAccount(String uid) async {
    final snap = await _db.ref(FirebasePaths.account(uid)).get();

    if (!snap.exists) {
      return {};
    }

    return Map<String, dynamic>.from(snap.value as Map);
  }

  static Future<Map<String, dynamic>> loadDirectoryUser(String uid) async {
    final snap = await _db.ref("userDirectory/$uid").get();

    if (!snap.exists || snap.value is! Map) {
      return {};
    }

    return Map<String, dynamic>.from(snap.value as Map);
  }

  static Future<void> sendShareRequest({
    required String ownerUid,
    required String targetUid,
    required String homeId,
    String? homeName,
    required String ownerEmail,
    required Map<String, dynamic> targetData,
    required String targetEmail,
  }) async {
    final targetProfile = targetData["profile"] == null
        ? {}
        : Map<String, dynamic>.from(targetData["profile"] as Map);
    final resolvedHomeName = await HomeNotificationService.resolveHomeName(
      homeId: homeId,
      ownerUid: ownerUid,
      providedHomeName: homeName,
    );

    final requestData = {
      "type": "share_request",
      "ownerUid": ownerUid,
      "homeId": homeId,
      "homeName": resolvedHomeName,
      "targetUid": targetUid,
      "targetEmail": targetData["email"] ?? targetEmail,
      "targetName": targetProfile["name"] ?? "",
      "targetPhotoUrl": targetProfile["photoUrl"] ?? "",
      "ownerEmail": ownerEmail,
      "time": DateTime.now().millisecondsSinceEpoch,
    };

    await _db
        .ref(FirebasePaths.shareRequest(targetUid, homeId))
        .set(requestData);
  }

  static Future<void> transferOwner({
    required String oldOwnerUid,
    required String newOwnerUid,
    required String homeId,
  }) async {
    final currentSnap = await _db
        .ref(FirebasePaths.home(oldOwnerUid, homeId))
        .get();

    if (!currentSnap.exists) {
      throw Exception("Không tìm thấy Home hiện tại");
    }

    final homeData = Map<String, dynamic>.from(currentSnap.value as Map);

    homeData["_ownerUid"] = newOwnerUid;
    homeData["_shared"] = false;

    await _db.ref(FirebasePaths.sharedHome(newOwnerUid, homeId)).remove();

    await _db.ref(FirebasePaths.sharedMember(homeId, newOwnerUid)).remove();

    await _db
        .ref("${FirebasePaths.shareList(oldOwnerUid, homeId)}/$newOwnerUid")
        .remove();

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

    await _db.ref(FirebasePaths.sharedMember(homeId, oldOwnerUid)).set({
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
    final sharedHomeSnap = await _db
        .ref(FirebasePaths.sharedHome(uid, homeId))
        .get();

    String realOwnerUid = ownerUid;

    if (sharedHomeSnap.exists && sharedHomeSnap.value is Map) {
      final sharedHomeData = Map<String, dynamic>.from(
        sharedHomeSnap.value as Map,
      );

      final foundOwnerUid = sharedHomeData["ownerUid"]?.toString() ?? "";

      if (foundOwnerUid.isNotEmpty) {
        realOwnerUid = foundOwnerUid;
      }
    }

    if (realOwnerUid.isEmpty) return;

    final homeSnap = await _db
        .ref(FirebasePaths.home(realOwnerUid, homeId))
        .get();

    String homeName = "Nhà chưa đặt tên";
    final userData = await loadAccount(uid);

    final userProfile = userData["profile"] is Map
        ? Map<String, dynamic>.from(userData["profile"] as Map)
        : <String, dynamic>{};

    final memberName = userProfile["name"]?.toString().trim().isNotEmpty == true
        ? userProfile["name"].toString()
        : userData["email"]?.toString() ?? "Một thành viên";
    if (homeSnap.exists) {
      final homeData = Map<String, dynamic>.from(homeSnap.value as Map);

      final resolvedName = homeData["name"]?.toString().trim() ?? "";

      if (resolvedName.isNotEmpty) {
        homeName = resolvedName;
      }
    }
    print(
      "LEAVE_HOME_DEBUG uid=$uid ownerUid=$ownerUid realOwnerUid=$realOwnerUid homeId=$homeId",
    );
    await HomeNotificationService.notifyHome(
      ownerUid: realOwnerUid,
      homeId: homeId,
      type: "member_leave",
      category: "member",
      severity: "warning",
      title: "Thành viên rời nhà",
      message: "$memberName đã rời khỏi nhà \"$homeName\".",
      entityType: "member",
      entityId: uid,
      homeName: homeName,
      includeActor: false,
    );
    await _db.ref(FirebasePaths.sharedHome(uid, homeId)).remove();

    await _db.ref(FirebasePaths.sharedMember(homeId, uid)).remove();

    await _db
        .ref("${FirebasePaths.shareList(realOwnerUid, homeId)}/$uid")
        .remove();
  }

  static Future<void> deleteOwnedHome({
    required String ownerUid,
    required String homeId,
  }) async {
    final sharedSnap = await _db.ref(FirebasePaths.sharedByHome(homeId)).get();

    if (sharedSnap.exists) {
      final sharedMap = Map<String, dynamic>.from(sharedSnap.value as Map);

      for (final sharedUid in sharedMap.keys) {
        await _db.ref(FirebasePaths.sharedHome(sharedUid, homeId)).remove();
      }
    }

    await _db.ref(FirebasePaths.sharedByHome(homeId)).remove();

    await _db.ref(FirebasePaths.home(ownerUid, homeId)).remove();
  }
}
