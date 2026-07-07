import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers/firebase_paths.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../services/share_service.dart';
import '../services/home_notification_service.dart';
import 'package:safehome_app/helpers/debug_log.dart';

Future<bool?> showShareRequestSheet({
  required BuildContext context,
  required Map<String, dynamic> requests,
  required String uid,
}) {
  final items = Map<String, dynamic>.from(requests);
  final selected = <String>{};
  final db = FirebaseDatabase.instance;

  final authenticatedUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  if (authenticatedUid.isEmpty || authenticatedUid != uid) {
    return Future<bool?>.value(false);
  }

  Future<bool> canHandleRequest(Map<String, dynamic> data) async {
    final type = data["type"]?.toString() ?? "share_request";
    final homeId = data["homeId"]?.toString() ?? "";

    if (type == "share_request") {
      return data["targetUid"]?.toString() == uid;
    }

    if (type == "transfer_owner_request") {
      return data["newOwnerUid"]?.toString() == uid;
    }

    if (type == "join_request") {
      final ownerUid = data["ownerUid"]?.toString() ?? "";

      if (ownerUid.isEmpty || homeId.isEmpty) {
        return false;
      }

      if (uid == ownerUid) {
        return true;
      }

      final accessSnap = await db
          .ref("accounts/$uid/sharedHomes/$homeId")
          .get();

      final access = accessSnap.value is Map
          ? Map<String, dynamic>.from(accessSnap.value as Map)
          : <String, dynamic>{};

      return access["ownerUid"]?.toString() == ownerUid &&
          access["role"]?.toString() == "admin";
    }

    return false;
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      Future<void> removeRequestFromAllApprovers({
        required String requestKey,
        required String ownerUid,
        required String homeId,
        required String currentUid,
        required bool syncApprovers,
      }) async {
        await FirebaseDatabase.instance
            .ref("accounts/$currentUid/shareRequests/$requestKey")
            .remove();
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final strings = AppStrings.of(context);

          Future<void> acceptOne(
            String requestKey,
            Map<String, dynamic> data,
          ) async {
            final canHandle = await canHandleRequest(data);

            if (!context.mounted) {
              return;
            }

            if (!canHandle) {
              showTopToast(
                context,
                strings.permissionDeniedMessage,
                color: Colors.red,
                icon: Icons.lock_rounded,
              );

              return;
            }
            final homeId = data["homeId"]?.toString() ?? "";
            final ownerUid = data["ownerUid"]?.toString().isNotEmpty == true
                ? data["ownerUid"].toString()
                : data["oldOwnerUid"]?.toString() ?? "";
            final fallbackTargetUid = requestKey.startsWith("${homeId}_")
                ? requestKey.substring(homeId.length + 1)
                : uid;
            final targetUid = data["targetUid"]?.toString().isNotEmpty == true
                ? data["targetUid"].toString()
                : fallbackTargetUid;

            if (homeId.isEmpty || targetUid.isEmpty || ownerUid.isEmpty) return;

            final homeName = await HomeNotificationService.resolveHomeName(
              homeId: homeId,
              ownerUid: ownerUid,
              providedHomeName: data["homeName"]?.toString(),
            );

            if (targetUid == ownerUid) {
              await removeRequestFromAllApprovers(
                requestKey: requestKey,
                ownerUid: ownerUid,
                homeId: homeId,
                currentUid: uid,
                syncApprovers: true,
              );

              setSheetState(() {
                items.remove(requestKey);
                selected.remove(requestKey);
              });

              return;
            }

            final type = data["type"]?.toString() ?? "share_request";
            if (type == "transfer_owner_request") {
              await ShareService.transferOwner(
                oldOwnerUid: data["oldOwnerUid"]?.toString() ?? "",
                newOwnerUid: data["newOwnerUid"]?.toString() ?? "",
                homeId: homeId,
              );
            } else {
              var targetEmail = data["targetEmail"]?.toString() ?? "";
              var targetName = data["targetName"]?.toString() ?? "";
              var targetPhotoUrl = data["targetPhotoUrl"]?.toString() ?? "";
              var targetPhone = data["targetPhone"]?.toString().trim() ?? "";

              if (targetUid == uid &&
                  (targetEmail.isEmpty ||
                      targetName.isEmpty ||
                      targetPhotoUrl.isEmpty ||
                      targetPhone.isEmpty)) {
                try {
                  final account = await ShareService.loadAccount(uid);
                  final profile = account["profile"] is Map
                      ? Map<String, dynamic>.from(account["profile"] as Map)
                      : <String, dynamic>{};

                  targetEmail = targetEmail.isNotEmpty
                      ? targetEmail
                      : account["email"]?.toString() ?? "";
                  targetName = targetName.isNotEmpty
                      ? targetName
                      : profile["name"]?.toString() ?? "";
                  targetPhotoUrl = targetPhotoUrl.isNotEmpty
                      ? targetPhotoUrl
                      : profile["photoUrl"]?.toString() ?? "";
                  targetPhone = targetPhone.isNotEmpty
                      ? targetPhone
                      : profile["phone"]?.toString().trim() ?? "";
                } catch (e) {
                  safeDebugPrint("LOAD_SELF_ACCOUNT_FOR_SHARE_ERROR: $e");
                }
              }

              final memberData = <String, Object?>{
                "role": "member",
                "email": targetEmail,
                "name": targetName,
                "sharedAt": DateTime.now().millisecondsSinceEpoch,
              };

              if (targetPhotoUrl.isNotEmpty) {
                memberData["photoUrl"] = targetPhotoUrl;
              }

              await FirebaseDatabase.instance
                  .ref(FirebasePaths.sharedHome(targetUid, homeId))
                  .set({"ownerUid": ownerUid, "role": "member"});

              await FirebaseDatabase.instance
                  .ref(FirebasePaths.sharedMember(homeId, targetUid))
                  .set(memberData);

              if (targetPhone.isNotEmpty) {
                await FirebaseDatabase.instance
                    .ref("homeMemberContacts/$homeId/$targetUid")
                    .set({"phone": targetPhone});
              }

              if (type == "join_request") {
                await FirebaseDatabase.instance
                    .ref(
                      "${FirebasePaths.shareList(ownerUid, homeId)}/$targetUid",
                    )
                    .set({
                      "email": targetEmail,
                      "name": targetName,
                      "sharedAt": DateTime.now().millisecondsSinceEpoch,
                    });
              }

              try {
                final memberName = targetName.trim().isNotEmpty
                    ? targetName.trim()
                    : targetEmail.trim().isNotEmpty
                    ? targetEmail.trim()
                    : "Một thành viên";

                await HomeNotificationService.notifyHome(
                  ownerUid: ownerUid,
                  homeId: homeId,
                  type: "member_join",
                  category: "member",
                  severity: "success",
                  title: "Thành viên mới",
                  message: "$memberName đã gia nhập nhà \"$homeName\".",
                  actorUid: targetUid,
                  entityType: "member",
                  entityId: targetUid,
                  homeName: homeName,
                );
              } catch (_) {}
            }

            await removeRequestFromAllApprovers(
              requestKey: requestKey,
              ownerUid: ownerUid,
              homeId: homeId,
              currentUid: uid,
              syncApprovers: true,
            );

            if (!context.mounted) {
              return;
            }

            setSheetState(() {
              items.remove(requestKey);
              selected.remove(requestKey);
            });

            if (items.isEmpty && context.mounted) {
              Navigator.pop(sheetContext, true);
              return;
            }
          }

          Future<void> denyOne(String requestKey) async {
            final data = Map<String, dynamic>.from(
              items[requestKey] ?? <String, dynamic>{},
            );

            final canHandle = await canHandleRequest(data);

            if (!context.mounted) {
              return;
            }

            if (!canHandle) {
              showTopToast(
                context,
                strings.permissionDeniedMessage,
                color: Colors.red,
                icon: Icons.lock_rounded,
              );

              return;
            }

            final homeId = data["homeId"]?.toString() ?? "";
            final ownerUid = data["ownerUid"]?.toString() ?? "";

            if (homeId.isNotEmpty && ownerUid.isNotEmpty) {
              await removeRequestFromAllApprovers(
                requestKey: requestKey,
                ownerUid: ownerUid,
                homeId: homeId,
                currentUid: uid,
                syncApprovers: true,
              );
            } else {
              await FirebaseDatabase.instance
                  .ref("accounts/$uid/shareRequests/$requestKey")
                  .remove();
            }

            if (!context.mounted) {
              return;
            }

            setSheetState(() {
              items.remove(requestKey);
              selected.remove(requestKey);
            });

            if (items.isEmpty && context.mounted) {
              Navigator.pop(sheetContext, true);
            }
          }

          return SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.82,
                ),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_rounded,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.t("Yêu cầu & lời mời"),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          "${items.length}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 46,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              strings.t("Không có yêu cầu hoặc lời mời nào"),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final list = items.entries.toList();
                            final requestKey = list[i].key;
                            final data = Map<String, dynamic>.from(
                              list[i].value,
                            );

                            final type =
                                data["type"]?.toString() ?? "share_request";

                            final isJoinRequest = type == "join_request";
                            final isTransferOwner =
                                type == "transfer_owner_request";

                            final targetEmail =
                                data["targetEmail"]?.toString().trim() ?? "";
                            final targetName =
                                data["targetName"]?.toString().trim() ?? "";
                            final ownerEmail =
                                data["ownerEmail"]?.toString().trim() ?? "";
                            final ownerName =
                                data["ownerName"]?.toString().trim() ?? "";

                            final rawHomeName =
                                data["homeName"]?.toString().trim() ?? "";

                            final homeName =
                                rawHomeName.isNotEmpty &&
                                    !rawHomeName.startsWith("home_")
                                ? rawHomeName
                                : strings.t("Nhà chưa đặt tên");

                            final Color color = isJoinRequest
                                ? Colors.orange
                                : isTransferOwner
                                ? Colors.purple
                                : Colors.green;

                            final IconData icon = isJoinRequest
                                ? Icons.person_add_alt_1_rounded
                                : isTransferOwner
                                ? Icons.admin_panel_settings_rounded
                                : Icons.home_work_rounded;

                            final String badgeText = isJoinRequest
                                ? strings.choose(
                                    vi: "Lời xin vào nhà",
                                    en: "Home join request",
                                    zh: "加入家庭请求",
                                  )
                                : isTransferOwner
                                ? strings.t("Chuyển quyền chủ nhà")
                                : strings.choose(
                                    vi: "Lời mời gia nhập",
                                    en: "Join invitation",
                                    zh: "加入邀请",
                                  );

                            late final String title;
                            late final String subtitle;

                            if (isJoinRequest) {
                              title = targetName.isNotEmpty
                                  ? targetName
                                  : targetEmail.isNotEmpty
                                  ? targetEmail
                                  : strings.choose(
                                      vi: "Một người dùng SafeHome",
                                      en: "A SafeHome user",
                                      zh: "一位 SafeHome 用户",
                                    );

                              subtitle =
                                  targetEmail.isNotEmpty &&
                                      targetName.isNotEmpty
                                  ? strings.choose(
                                      vi: "$targetEmail\nXin gia nhập \"$homeName\"",
                                      en: "$targetEmail\nRequests to join \"$homeName\"",
                                      zh: "$targetEmail\n申请加入“$homeName”",
                                    )
                                  : strings.choose(
                                      vi: "Xin gia nhập \"$homeName\"",
                                      en: "Requests to join \"$homeName\"",
                                      zh: "申请加入“$homeName”",
                                    );
                            } else if (isTransferOwner) {
                              title = strings.choose(
                                vi: "Nhận quyền chủ nhà",
                                en: "Receive home ownership",
                                zh: "接收屋主权限",
                              );
                              subtitle = strings.choose(
                                vi: "Bạn được mời nhận quyền nhà \"$homeName\"",
                                en: "You were invited to receive ownership of \"$homeName\"",
                                zh: "你被邀请接收“$homeName”的屋主权限",
                              );
                            } else {
                              title = ownerName.isNotEmpty
                                  ? ownerName
                                  : ownerEmail.isNotEmpty
                                  ? ownerEmail
                                  : strings.choose(
                                      vi: "Lời mời từ chủ nhà",
                                      en: "Invitation from the owner",
                                      zh: "来自屋主的邀请",
                                    );

                              subtitle =
                                  ownerEmail.isNotEmpty && ownerName.isNotEmpty
                                  ? strings.choose(
                                      vi: "$ownerEmail\nMời bạn gia nhập \"$homeName\"",
                                      en: "$ownerEmail\nInvites you to join \"$homeName\"",
                                      zh: "$ownerEmail\n邀请你加入“$homeName”",
                                    )
                                  : strings.choose(
                                      vi: "Mời bạn gia nhập \"$homeName\"",
                                      en: "Invites you to join \"$homeName\"",
                                      zh: "邀请你加入“$homeName”",
                                    );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: color.withValues(
                                          alpha: 0.12,
                                        ),
                                        child: Icon(icon, color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 7),
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              subtitle,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.35,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => denyOne(requestKey),
                                          child: Text(
                                            strings.choose(
                                              vi: "Từ chối",
                                              en: "Decline",
                                              zh: "拒绝",
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await acceptOne(requestKey, data);
                                            } catch (e) {
                                              safeDebugPrint(
                                                "ACCEPT_REQUEST_ERROR: $e",
                                              );

                                              if (!context.mounted) return;

                                              showTopToast(
                                                context,
                                                isJoinRequest
                                                    ? strings.choose(
                                                        vi: "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.",
                                                        en: "Could not accept the join request. Please try again.",
                                                        zh: "无法接受加入请求。请重试。",
                                                      )
                                                    : strings.choose(
                                                        vi: "Không thể chấp nhận lời mời. Vui lòng thử lại.",
                                                        en: "Could not accept the invitation. Please try again.",
                                                        zh: "无法接受邀请。请重试。",
                                                      ),
                                                color: Colors.red,
                                                icon: Icons.error_rounded,
                                              );
                                            }
                                          },
                                          child: Text(
                                            isJoinRequest
                                                ? strings.choose(
                                                    vi: "Cho phép",
                                                    en: "Allow",
                                                    zh: "允许",
                                                  )
                                                : strings.choose(
                                                    vi: "Chấp nhận",
                                                    en: "Accept",
                                                    zh: "接受",
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
