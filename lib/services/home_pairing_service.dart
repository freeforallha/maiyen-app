import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../helpers/firebase_paths.dart';
import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import 'home_notification_service.dart';
import 'share_service.dart';

enum HomeScannedQrStatus {
  joinMultiSent,
  joinSingleSent,
  invalidJoinMulti,
  invalidJoinSingle,
  ownerOfMultiHomes,
  ownerOfSingleHome,
  pairHubId,
}

class HomeScannedQrResult {
  const HomeScannedQrResult({
    required this.status,
    this.joinRequestCount = 0,
    this.hubId = "",
  });

  final HomeScannedQrStatus status;
  final int joinRequestCount;
  final String hubId;
}

class HomePairingStartResult {
  const HomePairingStartResult({required this.durationSeconds});

  final int durationSeconds;
}

class HomePairingService {
  Future<HomeScannedQrResult> handleScannedQr({
    required String code,
    required String uid,
    required AppStrings strings,
  }) async {
    final value = code.trim();
    debugPrint("QR_DEBUG value=$value");

    if (value.startsWith("safehome_join_multi|")) {
      final parts = value.split("|");

      if (parts.length != 3) {
        return const HomeScannedQrResult(
          status: HomeScannedQrStatus.invalidJoinMulti,
        );
      }

      final ownerUid = parts[1];
      final homeIds = parts[2]
          .split(",")
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (ownerUid == uid) {
        return const HomeScannedQrResult(
          status: HomeScannedQrStatus.ownerOfMultiHomes,
        );
      }

      final myEmail = FirebaseAuth.instance.currentUser?.email
          ?.trim()
          .toLowerCase();

      final targetData = await ShareService.loadAccount(uid);
      final targetProfile = safeMap(targetData["profile"]);
      final requesterName =
          targetProfile["name"]?.toString().trim().isNotEmpty == true
          ? targetProfile["name"].toString().trim()
          : myEmail ?? strings.t("Một người dùng");

      for (final homeId in homeIds) {
        final homeName = await HomeNotificationService.resolveHomeName(
          homeId: homeId,
          ownerUid: ownerUid,
        );
        final requestKey = "${homeId}_$uid";
        final requestData = {
          "homeId": homeId,
          "homeName": homeName,
          "ownerUid": ownerUid,
          "targetUid": uid,
          "targetEmail": myEmail ?? "",
          "targetName": requesterName,
          "targetPhone": targetProfile["phone"]?.toString().trim() ?? "",
          "type": "join_request",
          "time": DateTime.now().millisecondsSinceEpoch,
        };

        final updates = <String, Object?>{
          "accounts/$ownerUid/shareRequests/$requestKey": requestData,
        };

        try {
          debugPrint("QR_JOIN_UPDATES=$updates");
          await FirebaseDatabase.instance.ref().update(updates);
          debugPrint("QR_JOIN_UPDATE_OK");
        } catch (e, st) {
          debugPrint("QR_JOIN_UPDATE_ERROR: $e");
          debugPrint("QR_JOIN_UPDATE_STACK: $st");
        }

        await HomeNotificationService.notifyHome(
          ownerUid: ownerUid,
          homeId: homeId,
          recipientUid: ownerUid,
          type: "join_request",
          title: strings.t("Yêu cầu gia nhập nhà"),
          message: strings.choose(
            vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
            en: "$requesterName requested to join \"$homeName\".",
          ),
          homeName: homeName,
          category: "member",
          severity: "info",
          entityType: "member",
          entityId: uid,
          includeActor: false,
          writeHomeTimeline: false,
        );
      }

      return HomeScannedQrResult(
        status: HomeScannedQrStatus.joinMultiSent,
        joinRequestCount: homeIds.length,
      );
    }

    if (value.startsWith("safehome_join|")) {
      final parts = value.split("|");

      if (parts.length != 3) {
        return const HomeScannedQrResult(
          status: HomeScannedQrStatus.invalidJoinSingle,
        );
      }

      final ownerUid = parts[1];
      final homeId = parts[2];

      if (ownerUid == uid) {
        return const HomeScannedQrResult(
          status: HomeScannedQrStatus.ownerOfSingleHome,
        );
      }

      final myEmail = FirebaseAuth.instance.currentUser?.email
          ?.trim()
          .toLowerCase();

      final targetData = await ShareService.loadAccount(uid);
      final targetProfile = safeMap(targetData["profile"]);
      final requesterName =
          targetProfile["name"]?.toString().trim().isNotEmpty == true
          ? targetProfile["name"].toString().trim()
          : myEmail ?? strings.t("Một người dùng");

      final requestKey = "${homeId}_$uid";
      final homeName = await HomeNotificationService.resolveHomeName(
        homeId: homeId,
        ownerUid: ownerUid,
      );

      final requestData = {
        "homeId": homeId,
        "homeName": homeName,
        "ownerUid": ownerUid,
        "targetUid": uid,
        "targetEmail": myEmail ?? "",
        "targetName": requesterName,
        "targetPhone": targetProfile["phone"]?.toString().trim() ?? "",
        "type": "join_request",
        "time": DateTime.now().millisecondsSinceEpoch,
      };

      final updates = <String, Object?>{
        "accounts/$ownerUid/shareRequests/$requestKey": requestData,
      };

      await FirebaseDatabase.instance.ref().update(updates);
      await HomeNotificationService.notifyHome(
        ownerUid: ownerUid,
        homeId: homeId,
        recipientUid: ownerUid,
        type: "join_request",
        title: strings.t("Yêu cầu gia nhập nhà"),
        message: strings.choose(
          vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
          en: "$requesterName requested to join \"$homeName\".",
        ),
        homeName: homeName,
        category: "member",
        severity: "info",
        entityType: "member",
        entityId: uid,
        includeActor: false,
        writeHomeTimeline: false,
      );

      return const HomeScannedQrResult(
        status: HomeScannedQrStatus.joinSingleSent,
      );
    }

    return HomeScannedQrResult(
      status: HomeScannedQrStatus.pairHubId,
      hubId: value,
    );
  }

  Future<HomePairingStartResult> startPairing({
    required String hubId,
    required String uid,
    required String ownerUid,
    required String homeId,
    required String selectedRoomId,
    required String homeName,
    required AppStrings strings,
  }) async {
    final requestId =
        "${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 4)}";

    await FirebaseDatabase.instance
        .ref(FirebasePaths.pairRequest(requestId))
        .set({
          "active": true,
          "hubId": hubId.trim(),
          "homeId": homeId,
          "ownerUid": ownerUid,
          "requestedBy": uid,
          "roomId": selectedRoomId == "overview"
              ? "unassigned"
              : selectedRoomId,
          "duration": 60,
          "time": DateTime.now().millisecondsSinceEpoch,
        });
    await HomeNotificationService.notifyHome(
      ownerUid: ownerUid,
      homeId: homeId,
      type: "pair_started",
      category: "device",
      title: strings.t("Đã mở chế độ thêm thiết bị"),
      message: strings.choose(
        vi: "Chế độ thêm thiết bị đã được mở trong nhà \"$homeName\" trong 60 giây.",
        en: "Device pairing was enabled in \"$homeName\" for 60 seconds.",
      ),
      homeName: homeName,
    );

    return const HomePairingStartResult(durationSeconds: 60);
  }
}
