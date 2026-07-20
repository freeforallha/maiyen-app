import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helpers/firebase_paths.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../services/home_notification_service.dart';
import '../safehome_theme.dart';
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
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return null;
  }

  final myUid = currentUser.uid;
  final db = FirebaseDatabase.instance;
  final strings = AppStrings.of(context);

  final membersSnap = await db.ref(FirebasePaths.sharedByHome(homeId)).get();

  final membersData = membersSnap.value is Map
      ? Map<String, dynamic>.from(membersSnap.value as Map)
      : <String, dynamic>{};

  final ownerRaw = membersData[ownerUid] is Map
      ? Map<String, dynamic>.from(membersData[ownerUid] as Map)
      : <String, dynamic>{};

  final ownerDirectorySnap = await db.ref("userDirectory/$ownerUid").get();

  final ownerDirectory = ownerDirectorySnap.value is Map
      ? Map<String, dynamic>.from(ownerDirectorySnap.value as Map)
      : <String, dynamic>{};

  final directoryEmail = ownerDirectory["email"]?.toString().trim() ?? "";

  final rawEmail = ownerRaw["email"]?.toString().trim() ?? "";

  final ownerEmail = directoryEmail.isNotEmpty
      ? directoryEmail
      : rawEmail.isNotEmpty
      ? rawEmail
      : strings.t("Chủ nhà");

  final directoryName = ownerDirectory["name"]?.toString().trim() ?? "";

  final rawName = ownerRaw["name"]?.toString().trim() ?? "";

  final ownerName = directoryName.isNotEmpty
      ? directoryName
      : rawName.isNotEmpty
      ? rawName
      : ownerEmail;

  final directoryPhotoUrl = ownerDirectory["photoUrl"]?.toString().trim() ?? "";

  final rawPhotoUrl = ownerRaw["photoUrl"]?.toString().trim() ?? "";

  final ownerPhotoUrl = directoryPhotoUrl.isNotEmpty
      ? directoryPhotoUrl
      : rawPhotoUrl;

  var ownerPhone = ownerRaw["phone"]?.toString().trim() ?? "";

  try {
    final ownerContactSnap = await db
        .ref("homeMemberContacts/$homeId/$ownerUid/phone")
        .get();

    final contactPhone = ownerContactSnap.value?.toString().trim() ?? "";

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
        : strings.t("Không có email");

    final name = raw["name"]?.toString().trim().isNotEmpty == true
        ? raw["name"].toString().trim()
        : email;

    var phone = raw["phone"]?.toString().trim() ?? "";

    try {
      final phoneSnap = await db
          .ref("homeMemberContacts/$homeId/$memberUid/phone")
          .get();

      final contactPhone = phoneSnap.value?.toString().trim() ?? "";

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
        strings.t("Thành viên chưa cập nhật số điện thoại"),
        color: Colors.orange,
        icon: Icons.phone_disabled_rounded,
      );
      return;
    }

    final uri = Uri(scheme: "tel", path: cleanPhone.replaceAll(" ", ""));

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!callContext.mounted) return;

    showTopToast(
      callContext,
      strings.t("Không mở được ứng dụng gọi điện"),
      color: Colors.red,
      icon: Icons.phone_disabled_rounded,
    );
  }

  Color roleColor(String role) {
    if (role == "owner") return Colors.blue.shade700;
    if (role == "admin") return Colors.deepPurple.shade700;
    return Colors.blueGrey.shade700;
  }

  String roleLabel(String role) {
    if (role == "owner") return strings.owner;
    if (role == "admin") return strings.admin;
    return strings.member;
  }

  Widget memberOnlineDot(String memberUid) {
    return StreamBuilder<DatabaseEvent>(
      stream: db
          .ref(
            "accounts/$ownerUid/homes/$homeId/"
            "memberPresenceStatus/$memberUid",
          )
          .onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final status = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        // Online ở đây nghĩa là tài khoản vẫn còn phiên đăng nhập
        // hợp lệ. App chạy nền không bị hiểu nhầm thành đăng xuất.
        final online = status["online"] == true;

        return Tooltip(
          message: online ? "Online" : "Offline",
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: online
                  ? SafeHomeColors.safe
                  : SafeHomeColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget callActionButton({
    required BuildContext callContext,
    required String phone,
  }) {
    final hasPhone = phone.trim().isNotEmpty;

    return Tooltip(
      message: hasPhone
          ? strings.t("Gọi điện")
          : strings.t("Chưa có số điện thoại"),
      child: InkResponse(
        radius: 22,
        onTap: () {
          callPhone(callContext: callContext, phone: phone);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            hasPhone ? Icons.phone_rounded : Icons.phone_disabled_rounded,
            size: 23,
            color: hasPhone
                ? SafeHomeColors.safe
                : SafeHomeColors.textSecondary,
          ),
        ),
      ),
    );
  }

  if (!context.mounted) return null;

  return SafeHomeNavigation.pushChildPage<bool>(
    context: context,
    routeName: "home_members",
    builder: (sheetContext) {
      return ColoredBox(
        color: SafeHomeColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        homeName.isNotEmpty ? homeName : strings.homeMembers,
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
                                Flexible(
                                  child: Text(
                                    ownerName.isNotEmpty
                                        ? ownerName
                                        : ownerEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: roleColor("owner"),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                memberOnlineDot(ownerUid),
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
                        callActionButton(
                          callContext: sheetContext,
                          phone: ownerPhone,
                        ),

                      Container(
                        width: 72,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel("owner"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                          strings.t("Chưa share cho ai"),
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
                                : strings.t("Không có email");

                            final name =
                                member["name"]?.toString().trim().isNotEmpty ==
                                    true
                                ? member["name"].toString()
                                : email;

                            final photoUrl =
                                member["photoUrl"]?.toString() ?? "";

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
                                            Flexible(
                                              child: Text(
                                                targetUid == myUid
                                                    ? "$name (${strings.t("Bạn")})"
                                                    : name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: roleColor(role),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            memberOnlineDot(targetUid),
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
                                    callActionButton(
                                      callContext: sheetContext,
                                      phone: phone,
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
                                            strings.t(
                                              "Bạn không có quyền xoá thành viên này",
                                            ),
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
                                            strings.t(
                                              "Chỉ chủ nhà mới được thay đổi vai trò",
                                            ),
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
                                                    ? strings.t("Rời khỏi nhà?")
                                                    : strings.t(
                                                        "Xoá thành viên?",
                                                      ),
                                              ),
                                              content: Text(
                                                targetUid == myUid
                                                    ? strings.t(
                                                        "Bạn chắc chắn muốn rời khỏi nhà này?",
                                                      )
                                                    : strings
                                                          .confirmRemoveMemberFromHomeText(
                                                            name,
                                                          ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: Text(strings.t("Huỷ")),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: Text(
                                                    strings.t("Đồng ý"),
                                                  ),
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

                                            Navigator.of(
                                              sheetContext,
                                            ).pop(true);
                                            return;
                                          }

                                          if (!sheetContext.mounted) return;

                                          showTopToast(
                                            sheetContext,
                                            strings.t("Đã xoá thành viên"),
                                            color: Colors.green,
                                            icon: Icons.check_circle_rounded,
                                          );

                                          return;
                                        }

                                        if (!isOwner) return;

                                        if (value == role) {
                                          return;
                                        }

                                        final actorName =
                                            ownerName.trim().isNotEmpty
                                            ? ownerName.trim()
                                            : ownerEmail.trim().isNotEmpty
                                            ? ownerEmail.trim()
                                            : strings.t("Chủ nhà");

                                        await db.ref().update({
                                          "${FirebasePaths.sharedMember(homeId, targetUid)}/role":
                                              value,
                                          "${FirebasePaths.sharedHome(targetUid, homeId)}/role":
                                              value,
                                        });

                                        await HomeNotificationService.notifyHome(
                                          ownerUid: ownerUid,
                                          homeId: homeId,
                                          type: "member_role_changed",
                                          category: "member",
                                          severity: "info",
                                          title: strings
                                              .memberRoleChangedTitle(),
                                          message: strings
                                              .memberRoleChangedMessage(
                                                actorName: actorName,
                                                memberName: name,
                                                oldRole: role,
                                                newRole: value,
                                                homeName: homeName,
                                              ),
                                          entityType: "member",
                                          entityId: targetUid,
                                          homeName: homeName,
                                          includeActor: true,
                                          data: {
                                            "type": "member_role_changed",
                                            "actorName": actorName,
                                            "memberName": name,
                                            "memberUid": targetUid,
                                            "oldRole": role,
                                            "newRole": value,
                                            "homeName": homeName,
                                          },
                                        );
                                      },
                                      itemBuilder: (_) => [
                                        if (isOwner) ...[
                                          PopupMenuItem(
                                            value: "member",
                                            child: Text(strings.member),
                                          ),
                                          PopupMenuItem(
                                            value: "admin",
                                            child: Text(strings.admin),
                                          ),
                                        ],
                                        PopupMenuItem(
                                          value: "delete",
                                          child: Text(
                                            targetUid == myUid
                                                ? strings.t("Rời khỏi nhà")
                                                : strings.t("Xoá thành viên"),
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                      child: Container(
                                        width: 72,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: role == "admin"
                                              ? Colors.deepPurple.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.blueGrey.withValues(
                                                  alpha: 0.12,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          roleLabel(role),
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
                                      width: 72,
                                      height: 24,
                                      alignment: Alignment.center,
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
                                        roleLabel(role),
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
        ),
      );
    },
  );
}
