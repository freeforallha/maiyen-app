import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helpers/firebase_paths.dart';
import '../helpers/top_toast.dart';
import '../services/home_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool?> showShareListSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required String homeName,
  required bool canManageMembers,
  required bool isOwner,
  VoidCallback? onSelfLeave,
}) async {
  final myUid = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseDatabase.instance;

  final membersSnap = await db
      .ref(FirebasePaths.sharedByHome(homeId))
      .get();

  final membersData = membersSnap.value is Map
      ? Map<String, dynamic>.from(
    membersSnap.value as Map,
  )
      : <String, dynamic>{};

  final ownerRaw = membersData[ownerUid] is Map
      ? Map<String, dynamic>.from(
    membersData[ownerUid] as Map,
  )
      : <String, dynamic>{};

  final ownerDirectorySnap = await db
      .ref("userDirectory/$ownerUid")
      .get();

  final ownerDirectory = ownerDirectorySnap.value is Map
      ? Map<String, dynamic>.from(
    ownerDirectorySnap.value as Map,
  )
      : <String, dynamic>{};

  final directoryEmail =
      ownerDirectory["email"]?.toString().trim() ?? "";

  final rawEmail =
      ownerRaw["email"]?.toString().trim() ?? "";

  final ownerEmail = directoryEmail.isNotEmpty
      ? directoryEmail
      : rawEmail.isNotEmpty
      ? rawEmail
      : "Chủ nhà";

  final directoryName =
      ownerDirectory["name"]?.toString().trim() ?? "";

  final rawName =
      ownerRaw["name"]?.toString().trim() ?? "";

  final ownerName = directoryName.isNotEmpty
      ? directoryName
      : rawName.isNotEmpty
      ? rawName
      : ownerEmail;

  final directoryPhotoUrl =
      ownerDirectory["photoUrl"]?.toString().trim() ?? "";

  final rawPhotoUrl =
      ownerRaw["photoUrl"]?.toString().trim() ?? "";

  final ownerPhotoUrl = directoryPhotoUrl.isNotEmpty
      ? directoryPhotoUrl
      : rawPhotoUrl;

  var ownerPhone = ownerRaw["phone"]?.toString().trim() ?? "";

  try {
    final ownerContactSnap = await db
        .ref("homeMemberContacts/$homeId/$ownerUid/phone")
        .get();

    final contactPhone =
        ownerContactSnap.value?.toString().trim() ?? "";

    if (contactPhone.isNotEmpty) {
      ownerPhone = contactPhone;
    }
  } catch (_) {
    // Dùng số dự phòng trong dữ liệu thành viên nếu có.
  }

  Future<Map<String, dynamic>> loadMember(
      String memberUid,
      dynamic rawValue,
      ) async {
    final raw = rawValue is Map
        ? Map<String, dynamic>.from(rawValue)
        : <String, dynamic>{};

    final email = raw["email"]?.toString().trim().isNotEmpty == true
        ? raw["email"].toString().trim()
        : "Không có email";

    final name = raw["name"]?.toString().trim().isNotEmpty == true
        ? raw["name"].toString().trim()
        : email;

    var phone = raw["phone"]?.toString().trim() ?? "";

    try {
      final phoneSnap = await db
          .ref("homeMemberContacts/$homeId/$memberUid/phone")
          .get();

      final contactPhone =
          phoneSnap.value?.toString().trim() ?? "";

      if (contactPhone.isNotEmpty) {
        phone = contactPhone;
      }
    } catch (_) {
      // Giữ số dự phòng trong sharedByHome nếu có.
    }

    return {
      "uid": memberUid,
      "email": email,
      "name": name,
      "photoUrl": raw["photoUrl"]?.toString() ?? "",
      "phone": phone,
      "role": raw["role"]?.toString() ?? "member",
    };
  }

  Future<void> callPhone({
    required BuildContext callContext,
    required String phone,
  }) async {
    final cleanPhone = phone.trim();

    if (cleanPhone.isEmpty) {
      showTopToast(
        callContext,
        "Thành viên chưa cập nhật số điện thoại",
        color: Colors.orange,
        icon: Icons.phone_disabled_rounded,
      );
      return;
    }

    final uri = Uri(
      scheme: "tel",
      path: cleanPhone.replaceAll(" ", ""),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!callContext.mounted) return;

    showTopToast(
      callContext,
      "Không mở được ứng dụng gọi điện",
      color: Colors.red,
      icon: Icons.phone_disabled_rounded,
    );
  }

  Color roleColor(String role) {
    if (role == "owner") return Colors.blue.shade700;
    if (role == "admin") return Colors.deepPurple.shade700;
    return Colors.blueGrey.shade700;
  }

  IconData roleIcon(String role) {
    if (role == "owner") return Icons.workspace_premium_rounded;
    if (role == "admin") return Icons.admin_panel_settings_rounded;
    return Icons.person_rounded;
  }

  if (!context.mounted) return null;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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

              const SizedBox(height: 18),

              Row(
                children: [
                  const Icon(Icons.people_alt_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      homeName.isNotEmpty ? homeName : "Thành viên trong nhà",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      backgroundImage: ownerPhotoUrl.isNotEmpty
                          ? NetworkImage(ownerPhotoUrl)
                          : null,
                      child: ownerPhotoUrl.isEmpty
                          ? const Icon(Icons.home_rounded, color: Colors.blue)
                          : null,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                roleIcon("owner"),
                                size: 15,
                                color: roleColor("owner"),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  ownerName.isNotEmpty ? ownerName : ownerEmail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: roleColor("owner"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ownerEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (ownerUid != myUid)
                      IconButton(
                        tooltip: ownerPhone.isNotEmpty
                            ? "Gọi điện"
                            : "Chưa có số điện thoại",
                        icon: Icon(
                          ownerPhone.isNotEmpty
                              ? Icons.phone_rounded
                              : Icons.phone_disabled_rounded,
                          color: ownerPhone.isNotEmpty
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                        onPressed: () => callPhone(
                          callContext: sheetContext,
                          phone: ownerPhone,
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "OWNER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              StreamBuilder<DatabaseEvent>(
                stream: db.ref(FirebasePaths.sharedByHome(homeId)).onValue,
                builder: (context, snapshot) {
                  final raw = snapshot.data?.snapshot.value;
                  final users = raw is Map
                      ? Map<String, dynamic>.from(raw)
                      : <String, dynamic>{};
                  users.remove(ownerUid);
                  if (users.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        "Chưa share cho ai",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: users.entries.map((e) {
                      final targetUid = e.key;

                      return FutureBuilder<Map<String, dynamic>>(
                        future: loadMember(targetUid, e.value),
                        builder: (context, snapshot) {
                          final rawMember = e.value is Map
                              ? Map<String, dynamic>.from(e.value as Map)
                              : <String, dynamic>{};

                          final member = snapshot.data ?? rawMember;

                          final email =
                          member["email"]?.toString().trim().isNotEmpty ==
                              true
                              ? member["email"].toString()
                              : "Không có email";

                          final name =
                          member["name"]?.toString().trim().isNotEmpty ==
                              true
                              ? member["name"].toString()
                              : email;

                          final photoUrl = member["photoUrl"]?.toString() ?? "";

                          final role = member["role"]?.toString() ?? "member";

                          final phone = member["phone"]?.toString() ?? "";
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            roleIcon(role),
                                            size: 15,
                                            color: roleColor(role),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              targetUid == myUid
                                                  ? "$name (Bạn)"
                                                  : name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: roleColor(role),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (targetUid != myUid)
                                  IconButton(
                                    tooltip: phone.isNotEmpty
                                        ? "Gọi điện"
                                        : "Chưa có số điện thoại",
                                    icon: Icon(
                                      phone.isNotEmpty
                                          ? Icons.phone_rounded
                                          : Icons.phone_disabled_rounded,
                                      color: phone.isNotEmpty
                                          ? Colors.green
                                          : Colors.grey.shade400,
                                    ),
                                    onPressed: () => callPhone(
                                      callContext: sheetContext,
                                      phone: phone,
                                    ),
                                  ),
                                if (targetUid == myUid ||
                                    isOwner ||
                                    (canManageMembers && role == "member"))
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      final canDeleteTarget =
                                          targetUid == myUid ||
                                              isOwner ||
                                              (canManageMembers &&
                                                  role == "member");

                                      if (value == "delete" &&
                                          !canDeleteTarget) {
                                        showTopToast(
                                          sheetContext,
                                          "Bạn không có quyền xoá thành viên này",
                                          color: Colors.orange,
                                          icon: Icons.lock_rounded,
                                        );
                                        return;
                                      }

                                      if ((value == "member" ||
                                          value == "admin") &&
                                          !isOwner) {
                                        showTopToast(
                                          sheetContext,
                                          "Chỉ chủ nhà mới được thay đổi vai trò",
                                          color: Colors.orange,
                                          icon: Icons.lock_rounded,
                                        );
                                        return;
                                      }
                                      if (value == "delete") {
                                        final ok = await showDialog<bool>(
                                          context: sheetContext,
                                          builder: (_) => AlertDialog(
                                            title: Text(
                                              targetUid == myUid
                                                  ? "Rời khỏi nhà?"
                                                  : "Xoá thành viên?",
                                            ),
                                            content: Text(
                                              targetUid == myUid
                                                  ? "Bạn chắc chắn muốn rời khỏi nhà này?"
                                                  : "Bạn chắc chắn muốn xoá $name khỏi nhà này?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Huỷ"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text("Đồng ý"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (ok != true) return;

                                        await db
                                            .ref(
                                          "homeMemberContacts/$homeId/$targetUid",
                                        )
                                            .remove();

                                        await db
                                            .ref(
                                          FirebasePaths.sharedHome(
                                            targetUid,
                                            homeId,
                                          ),
                                        )
                                            .remove();
                                        await db
                                            .ref(
                                          FirebasePaths.sharedMember(
                                            homeId,
                                            targetUid,
                                          ),
                                        )
                                            .remove();
                                        await db
                                            .ref(
                                          "accounts/$ownerUid/shareList/$homeId/$targetUid",
                                        )
                                            .remove();

                                        if (targetUid == myUid) {
                                          if (!sheetContext.mounted) return;

                                          Navigator.of(sheetContext).pop(true);
                                          return;
                                        }

                                        if (!sheetContext.mounted) return;

                                        showTopToast(
                                          sheetContext,
                                          "Đã xoá thành viên",
                                          color: Colors.green,
                                          icon: Icons.check_circle_rounded,
                                        );

                                        return;
                                      }

                                      if (!isOwner) return;

                                      await db.ref().update({
                                        "${FirebasePaths.sharedMember(homeId, targetUid)}/role":
                                        value,
                                        "${FirebasePaths.sharedHome(targetUid, homeId)}/role":
                                        value,
                                      });

                                      await HomeNotificationService.addNotification(
                                        uid: targetUid,
                                        type: "role_changed",
                                        title: "Quyền trong nhà đã thay đổi",
                                        message: value == "admin"
                                            ? "Bạn đã được nâng quyền thành Admin trong nhà \"$homeName\"."
                                            : "Quyền của bạn trong nhà \"$homeName\" đã được chuyển về Member.",
                                        homeId: homeId,
                                        ownerUid: ownerUid,
                                        homeName: homeName,
                                        category: "member",
                                        entityType: "member",
                                        entityId: targetUid,
                                      );
                                    },
                                    itemBuilder: (_) => [
                                      if (isOwner) ...[
                                        const PopupMenuItem(
                                          value: "member",
                                          child: Text("Member"),
                                        ),
                                        const PopupMenuItem(
                                          value: "admin",
                                          child: Text("Admin"),
                                        ),
                                      ],
                                      PopupMenuItem(
                                        value: "delete",
                                        child: Text(
                                          targetUid == myUid
                                              ? "Rời khỏi nhà"
                                              : "Xoá thành viên",
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: role == "admin"
                                            ? Colors.deepPurple.withValues(
                                          alpha: 0.12,
                                        )
                                            : Colors.blueGrey.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: role == "admin"
                                              ? Colors.deepPurple
                                              : Colors.blueGrey,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: role == "admin"
                                          ? Colors.deepPurple.withValues(
                                        alpha: 0.12,
                                      )
                                          : Colors.blueGrey.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: role == "admin"
                                            ? Colors.deepPurple
                                            : Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
