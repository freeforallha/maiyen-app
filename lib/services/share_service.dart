import 'package:firebase_database/firebase_database.dart';
import '../services/home_notification_service.dart';
import '../helpers/firebase_paths.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareService {
  static final _db = FirebaseDatabase.instance;

  static Future<String?> findUidByEmail(String email) async {
    final targetEmail = email.trim().toLowerCase();

    final snap = await _db
        .ref("userDirectory")
        .orderByChild("email")
        .equalTo(targetEmail)
        .limitToFirst(1)
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError("Không có tài khoản Firebase Auth đang đăng nhập");
    }

    if (ownerUid.trim().isEmpty ||
        targetUid.trim().isEmpty ||
        homeId.trim().isEmpty) {
      throw ArgumentError("ownerUid, targetUid và homeId không được để trống");
    }

    if (targetUid == currentUid) {
      throw StateError("Không thể gửi lời mời cho chính mình");
    }

    if (currentUid != ownerUid) {
      final accessSnap = await _db
          .ref("accounts/$currentUid/sharedHomes/$homeId")
          .get();

      final access = accessSnap.value is Map
          ? Map<String, dynamic>.from(accessSnap.value as Map)
          : <String, dynamic>{};

      final sharedOwnerUid = access["ownerUid"]?.toString() ?? "";

      final role = access["role"]?.toString() ?? "member";

      if (sharedOwnerUid != ownerUid || role != "admin") {
        throw StateError("Bạn không có quyền chia sẻ nhà này");
      }
    }

    final homeSnap = await _db.ref(FirebasePaths.home(ownerUid, homeId)).get();

    if (!homeSnap.exists) {
      throw StateError("Không tìm thấy nhà cần chia sẻ");
    }

    final targetProfile = targetData["profile"] is Map
        ? Map<String, dynamic>.from(targetData["profile"] as Map)
        : targetData;

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
      "targetEmail": targetData["email"]?.toString().trim().isNotEmpty == true
          ? targetData["email"].toString().trim()
          : targetEmail.trim().toLowerCase(),
      "targetName": targetProfile["name"]?.toString().trim() ?? "",
      "targetPhotoUrl": targetProfile["photoUrl"]?.toString().trim() ?? "",
      "ownerEmail": ownerEmail.trim().toLowerCase(),
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final cleanOldOwnerUid = oldOwnerUid.trim();
    final cleanNewOwnerUid = newOwnerUid.trim();
    final cleanHomeId = homeId.trim();

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError(
        "Không có tài khoản Firebase Auth đang đăng nhập",
      );
    }

    if (cleanOldOwnerUid.isEmpty ||
        cleanNewOwnerUid.isEmpty ||
        cleanHomeId.isEmpty) {
      throw ArgumentError(
        "Thông tin chuyển quyền không hợp lệ",
      );
    }

    if (currentUid != cleanNewOwnerUid) {
      throw StateError(
        "Chỉ người nhận được chỉ định mới có thể nhận quyền chủ nhà",
      );
    }

    if (cleanOldOwnerUid == cleanNewOwnerUid) {
      throw StateError(
        "Không thể chuyển quyền cho chính chủ nhà hiện tại",
      );
    }

    final transferRequestKey =
        "transfer_${cleanHomeId}_$cleanOldOwnerUid";

    final transferRequestSnap = await _db
        .ref(
      "accounts/$cleanNewOwnerUid/shareRequests/$transferRequestKey",
    )
        .get();

    if (!transferRequestSnap.exists ||
        transferRequestSnap.value is! Map) {
      throw StateError(
        "Không tìm thấy yêu cầu chuyển quyền hợp lệ",
      );
    }

    final transferRequest = Map<String, dynamic>.from(
      transferRequestSnap.value as Map,
    );

    final isValidRequest =
        transferRequest["type"]?.toString() ==
            "transfer_owner_request" &&
            transferRequest["homeId"]?.toString() ==
                cleanHomeId &&
            transferRequest["oldOwnerUid"]?.toString() ==
                cleanOldOwnerUid &&
            transferRequest["newOwnerUid"]?.toString() ==
                cleanNewOwnerUid;

    if (!isValidRequest) {
      throw StateError(
        "Yêu cầu chuyển quyền không khớp",
      );
    }

    final requestRef = _db
        .ref("transfer_owner_accept_requests")
        .push();

    await requestRef.set({
      "status": "pending",
      "requestedByUid": currentUid,
      "oldOwnerUid": cleanOldOwnerUid,
      "newOwnerUid": cleanNewOwnerUid,
      "homeId": cleanHomeId,
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    for (var attempt = 0; attempt < 100; attempt++) {
      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      );

      final resultSnap = await requestRef.get();

      if (!resultSnap.exists) {
        throw StateError(
          "Yêu cầu nhận quyền đã bị xoá trước khi hoàn tất",
        );
      }

      final rawResult = resultSnap.value;

      if (rawResult is! Map) {
        continue;
      }

      final result = Map<String, dynamic>.from(rawResult);

      final status = result["status"]?.toString() ?? "";

      if (status == "completed") {
        return;
      }

      if (status == "rejected") {
        final error = result["error"]?.toString().trim() ?? "";

        throw StateError(
          error.isNotEmpty
              ? "Không thể chuyển quyền: $error"
              : "Backend đã từ chối yêu cầu chuyển quyền",
        );
      }
    }

    throw StateError(
      "Quá thời gian chờ backend chuyển quyền chủ nhà",
    );
  }

  static Future<void> leaveSharedHome({
    required String uid,
    required String ownerUid,
    required String homeId,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError("Không có tài khoản Firebase Auth đang đăng nhập");
    }

    if (uid != currentUid) {
      throw StateError("Không thể rời nhà thay cho tài khoản khác");
    }

    if (homeId.trim().isEmpty) {
      throw ArgumentError("homeId không được để trống");
    }

    final sharedHomeSnap = await _db
        .ref(FirebasePaths.sharedHome(currentUid, homeId))
        .get();

    if (!sharedHomeSnap.exists || sharedHomeSnap.value is! Map) {
      throw StateError("Không tìm thấy quyền truy cập nhà đã chia sẻ");
    }

    final sharedHomeData = Map<String, dynamic>.from(
      sharedHomeSnap.value as Map,
    );

    final realOwnerUid = sharedHomeData["ownerUid"]?.toString().trim() ?? "";

    if (realOwnerUid.isEmpty) {
      throw StateError("Không xác định được chủ nhà");
    }

    if (realOwnerUid == currentUid) {
      throw StateError("Chủ nhà không thể rời khỏi chính nhà của mình");
    }

    if (ownerUid.trim().isNotEmpty && ownerUid.trim() != realOwnerUid) {
      throw StateError("Thông tin chủ nhà không khớp");
    }

    final homeSnap = await _db
        .ref(FirebasePaths.home(realOwnerUid, homeId))
        .get();

    var homeName = "Nhà chưa đặt tên";

    if (homeSnap.value is Map) {
      final homeData = Map<String, dynamic>.from(homeSnap.value as Map);

      final resolvedName = homeData["name"]?.toString().trim() ?? "";

      if (resolvedName.isNotEmpty) {
        homeName = resolvedName;
      }
    }

    final userData = await loadAccount(currentUid);

    final userProfile = userData["profile"] is Map
        ? Map<String, dynamic>.from(userData["profile"] as Map)
        : <String, dynamic>{};

    final profileName = userProfile["name"]?.toString().trim() ?? "";

    final accountEmail = userData["email"]?.toString().trim() ?? "";

    final memberName = profileName.isNotEmpty
        ? profileName
        : accountEmail.isNotEmpty
        ? accountEmail
        : "Một thành viên";

    try {
      await HomeNotificationService.notifyHome(
        ownerUid: realOwnerUid,
        homeId: homeId,
        type: "member_leave",
        category: "member",
        severity: "warning",
        title: "Thành viên rời nhà",
        message: "$memberName đã rời khỏi nhà \"$homeName\".",
        entityType: "member",
        entityId: currentUid,
        homeName: homeName,
        includeActor: false,
      );
    } catch (_) {
      // Lỗi thông báo không được ngăn người dùng rời nhà.
    }

    await _db.ref().update({
      FirebasePaths.sharedHome(currentUid, homeId): null,
      FirebasePaths.sharedMember(homeId, currentUid): null,
      "${FirebasePaths.shareList(realOwnerUid, homeId)}/$currentUid": null,
    });
  }

  static Future<void> deleteOwnedHome({
    required String ownerUid,
    required String homeId,
  }) async {
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    final cleanHomeId = homeId.trim();

    if (currentUid == null || currentUid.isEmpty) {
      throw StateError(
        "Không có tài khoản Firebase Auth đang đăng nhập",
      );
    }

    if (ownerUid != currentUid) {
      throw StateError(
        "Chỉ chủ nhà mới được xoá nhà",
      );
    }

    if (cleanHomeId.isEmpty) {
      throw ArgumentError(
        "homeId không được để trống",
      );
    }

    final homeRef = _db.ref(
      FirebasePaths.home(
        currentUid,
        cleanHomeId,
      ),
    );

    final homeSnap = await homeRef.get();

    if (!homeSnap.exists ||
        homeSnap.value is! Map) {
      throw StateError(
        "Không tìm thấy nhà cần xoá",
      );
    }

    final homeData = Map<String, dynamic>.from(
      homeSnap.value as Map,
    );

    final storedOwnerUid =
        homeData["_ownerUid"]?.toString() ?? "";

    if (storedOwnerUid != currentUid) {
      throw StateError(
        "Tài khoản hiện tại không phải chủ nhà",
      );
    }

    final sharedSnap = await _db
        .ref(
      FirebasePaths.sharedByHome(
        cleanHomeId,
      ),
    )
        .get();

    if (sharedSnap.value is Map) {
      final sharedMap =
      Map<String, dynamic>.from(
        sharedSnap.value as Map,
      );

      for (final rawUid in sharedMap.keys) {
        final memberUid =
        rawUid.toString().trim();

        if (memberUid.isEmpty ||
            memberUid == currentUid) {
          continue;
        }

        await _db
            .ref(
          FirebasePaths.sharedHome(
            memberUid,
            cleanHomeId,
          ),
        )
            .remove();

        await _db
            .ref(
          FirebasePaths.sharedMember(
            cleanHomeId,
            memberUid,
          ),
        )
            .remove();
      }
    }

    await _db
        .ref(
      FirebasePaths.shareList(
        currentUid,
        cleanHomeId,
      ),
    )
        .remove();

    await homeRef.remove();
  }
}
