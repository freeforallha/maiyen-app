import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/firebase_paths.dart';
import '../services/share_service.dart';
import '../services/home_notification_service.dart';

Future<bool?> showShareRequestSheet({
  required BuildContext context,
  required Map<String, dynamic> requests,
  required String uid,
}) {
  final items = Map<String, dynamic>.from(requests);
  final selected = <String>{};

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {

      Future<void> removeRequestFromAllApprovers({
        required String requestKey,
        required String ownerUid,
        required String homeId,
        required String currentUid,
        required bool syncApprovers,
      }) async {
        final updates = <String, Object?>{
          "accounts/$currentUid/shareRequests/$requestKey": null,
          "accounts/$ownerUid/shareRequests/$requestKey": null,
        };

        final snap = await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareRequests/$requestKey")
            .get();

        if (snap.value is Map) {
          final data = Map<String, dynamic>.from(snap.value as Map);
          final targetUid = data["targetUid"]?.toString() ?? "";

          if (targetUid.isNotEmpty) {
            updates["accounts/$targetUid/shareRequests/$requestKey"] = null;
          }
        }

        final sharedSnap = await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId")
            .get();

        final sharedMap = sharedSnap.value is Map
            ? Map<String, dynamic>.from(sharedSnap.value as Map)
            : <String, dynamic>{};

        for (final entry in sharedMap.entries) {
          final memberUid = entry.key.toString();
          final memberData = entry.value is Map
              ? Map<String, dynamic>.from(entry.value as Map)
              : <String, dynamic>{};

          if (memberData["role"] == "admin") {
            updates["accounts/$memberUid/shareRequests/$requestKey"] = null;
          }
        }

        await FirebaseDatabase.instance.ref().update(updates);
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> acceptOne(
            String requestKey,
            Map<String, dynamic> data,
          ) async {
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

              if (targetUid == uid &&
                  (targetEmail.isEmpty ||
                      targetName.isEmpty ||
                      targetPhotoUrl.isEmpty)) {
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
                } catch (e) {
                  debugPrint("LOAD_SELF_ACCOUNT_FOR_SHARE_ERROR: $e");
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
                await HomeNotificationService.addNotification(
                  uid: targetUid,
                  type: "join_request_accepted",
                  title: "Yêu cầu gia nhập được chấp nhận",
                  message: "Bạn đã được thêm vào nhà thành công.",
                  homeId: homeId,
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

            setSheetState(() {
              items.remove(requestKey);
              selected.remove(requestKey);
            });

            if (items.isEmpty && context.mounted) {
              Navigator.pop(context, true);
              return;
            }
          }

          Future<void> denyOne(String requestKey) async {
            final data = Map<String, dynamic>.from(items[requestKey] ?? {});
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

            setSheetState(() {
              items.remove(requestKey);
              selected.remove(requestKey);
            });

            if (items.isEmpty && context.mounted) {
              Navigator.pop(context, true);
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
                            "Lời mời chia sẻ",
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
                              "Không có lời mời nào",
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

                            final email = data["targetEmail"]?.toString() ?? "";
                            final name = data["targetName"]?.toString() ?? "";
                            final homeName =
                                data["homeName"]?.toString() ??
                                data["homeId"]?.toString() ??
                                "Home";

                            final title = type == "transfer_owner_request"
                                ? "Nhận quyền chủ nhà"
                                : (name.isNotEmpty ? name : "Lời mời chia sẻ");

                            final subtitle = type == "transfer_owner_request"
                                ? "Bạn được mời nhận quyền chủ nhà $homeName"
                                : email;

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
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            type == "transfer_owner_request"
                                            ? Colors.purple.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.green.withValues(
                                                alpha: 0.12,
                                              ),
                                        child: Icon(
                                          type == "transfer_owner_request"
                                              ? Icons
                                                    .admin_panel_settings_rounded
                                              : Icons.home_rounded,
                                          color:
                                              type == "transfer_owner_request"
                                              ? Colors.purple
                                              : Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
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
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
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
                                          child: const Text("Từ chối"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await acceptOne(requestKey, data);
                                            } catch (e, st) {
                                              debugPrint("ACCEPT_REQUEST_ERROR: $e");
                                              debugPrint("ACCEPT_REQUEST_STACK: $st");
                                              if (!context.mounted) return;

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Không thể chấp nhận lời mời. Vui lòng thử lại.",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text("Chấp nhận"),
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
