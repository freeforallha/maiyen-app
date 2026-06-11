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
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final items = Map<String, dynamic>.from(requests);
      final selected = <String>{};

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final list = items.entries.toList();

          Future<void> acceptOne(String requestKey, Map<String, dynamic> data) async {
            final homeId = data["homeId"]?.toString() ?? "";
            final targetUid = data["targetUid"]?.toString().isNotEmpty == true
                ? data["targetUid"].toString()
                : uid;
            final ownerUid = data["ownerUid"]?.toString() ?? "";

            if (homeId.isEmpty || targetUid.isEmpty || ownerUid.isEmpty) return;

            final type = data["type"]?.toString() ?? "share_request";

            if (type == "transfer_owner_request") {
              await ShareService.transferOwner(
                oldOwnerUid: data["oldOwnerUid"]?.toString() ?? "",
                newOwnerUid: data["newOwnerUid"]?.toString() ?? "",
                homeId: homeId,
              );
            } else {
              final account = await ShareService.loadAccount(targetUid);
              final profile = account["profile"] is Map
                  ? Map<String, dynamic>.from(account["profile"] as Map)
                  : <String, dynamic>{};

              final targetEmail = data["targetEmail"]?.toString().isNotEmpty == true
                  ? data["targetEmail"].toString()
                  : account["email"]?.toString() ?? "";

              final targetName = data["targetName"]?.toString().isNotEmpty == true
                  ? data["targetName"].toString()
                  : profile["name"]?.toString() ?? "";

              await FirebaseDatabase.instance
                  .ref(FirebasePaths.sharedHome(targetUid, homeId))
                  .set({
                "ownerUid": ownerUid,
                "role": "member",
              });

              await FirebaseDatabase.instance
                  .ref(FirebasePaths.sharedMember(homeId, targetUid))
                  .set({
                "role": "member",
                "email": targetEmail,
                "name": targetName,
                "sharedAt": DateTime.now().millisecondsSinceEpoch,
              });

              await FirebaseDatabase.instance
                  .ref("${FirebasePaths.shareList(ownerUid, homeId)}/$targetUid")
                  .set({
                "email": targetEmail,
                "name": targetName,
                "sharedAt": DateTime.now().millisecondsSinceEpoch,
              });

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

            await FirebaseDatabase.instance
                .ref("accounts/$uid/shareRequests/$requestKey")
                .remove();

            setSheetState(() {
              items.remove(requestKey);
              selected.remove(requestKey);
            });
          }

          Future<void> denyOne(String requestKey) async {
            await FirebaseDatabase.instance
                .ref("accounts/$uid/shareRequests/$requestKey")
                .remove();

            setSheetState(() {
              items.remove(requestKey);
              selected.remove(requestKey);
            });
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
                          "${list.length}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (list.isEmpty)
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
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final requestKey = list[i].key;
                            final data = Map<String, dynamic>.from(list[i].value);
                            final type = data["type"]?.toString() ?? "share_request";

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
                                        backgroundColor: type == "transfer_owner_request"
                                            ? Colors.purple.withValues(alpha: 0.12)
                                            : Colors.green.withValues(alpha: 0.12),
                                        child: Icon(
                                          type == "transfer_owner_request"
                                              ? Icons.admin_panel_settings_rounded
                                              : Icons.home_rounded,
                                          color: type == "transfer_owner_request"
                                              ? Colors.purple
                                              : Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                          onPressed: () => acceptOne(requestKey, data),
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