import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../safehome_theme.dart';
import '../services/native_alarm_permission_service.dart';

class AccountAvatarSheet {
  static void showTopMessage(
    BuildContext context,
    String message, {
    Color color = SafeHomeColors.danger,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<Offset>(
              duration: const Duration(milliseconds: 250),
              tween: Tween(begin: const Offset(0, -1), end: Offset.zero),
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset.dy * 20),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.16),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  static Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final passwordController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: SafeHomeColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: SafeHomeColors.danger,
              size: 27,
            ),
          ),
          title: const Text(
            "Xoá tài khoản",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: SafeHomeColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hành động này sẽ xoá toàn bộ dữ liệu:",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SafeHomeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text("• Nhà và thiết bị"),
              const Text("• Chia sẻ và quyền truy cập"),
              const Text("• Toàn bộ dữ liệu liên quan"),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu xác nhận",
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Huỷ"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SafeHomeColors.danger,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Xoá tài khoản"),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      passwordController.dispose();
      return;
    }

    if (!context.mounted) {
      passwordController.dispose();
      return;
    }

    await _deleteAccount(context, passwordController.text.trim());

    passwordController.dispose();
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    String password,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final uid = user.uid;

    try {
      final db = FirebaseDatabase.instance;
      final userEmail = user.email;

      if (userEmail == null || userEmail.isEmpty) {
        showTopMessage(context, "Không tìm thấy email tài khoản");
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: userEmail,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final accountSnap = await db.ref("accounts/$uid").get();

      final accountData = accountSnap.value is Map
          ? Map<String, dynamic>.from(accountSnap.value as Map)
          : <String, dynamic>{};

      final ownHomes = accountData["homes"] is Map
          ? Map<String, dynamic>.from(accountData["homes"] as Map)
          : <String, dynamic>{};

      final sharedHomes = accountData["sharedHomes"] is Map
          ? Map<String, dynamic>.from(accountData["sharedHomes"] as Map)
          : <String, dynamic>{};

      final updates = <String, dynamic>{};

      for (final homeId in ownHomes.keys) {
        final sharedSnap = await db.ref("sharedByHome/$homeId").get();

        if (sharedSnap.exists && sharedSnap.value is Map) {
          final sharedMap = Map<String, dynamic>.from(sharedSnap.value as Map);

          for (final memberUid in sharedMap.keys) {
            updates["accounts/$memberUid/sharedHomes/$homeId"] = null;
          }
        }

        updates["sharedByHome/$homeId"] = null;
        updates["homeChats/$homeId"] = null;
      }

      for (final homeId in sharedHomes.keys) {
        final sharedInfo = sharedHomes[homeId] is Map
            ? Map<String, dynamic>.from(sharedHomes[homeId] as Map)
            : <String, dynamic>{};

        final ownerUid = sharedInfo["ownerUid"];

        updates["sharedByHome/$homeId/$uid"] = null;

        if (ownerUid != null) {
          updates["accounts/$ownerUid/shareList/$homeId/$uid"] = null;
        }
      }

      updates["accounts/$uid"] = null;

      await db.ref().update(updates);
      await user.delete();

      if (!context.mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xoá tài khoản")));
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      showTopMessage(context, "Xoá thất bại: ${e.message ?? 'Unknown error'}");
    } catch (e) {
      if (!context.mounted) return;

      showTopMessage(context, "Lỗi xoá tài khoản: $e");
    }
  }

  static Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final displayValue = value.trim().isEmpty ? "Chưa cập nhật" : value.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: SafeHomeColors.surfaceSoft,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SafeHomeColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: SafeHomeColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: SafeHomeColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SafeHomeColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _compactProfileInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final displayValue = value.trim().isEmpty ? "Chưa cập nhật" : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SafeHomeColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                      color: SafeHomeColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: displayValue,
                    style: const TextStyle(
                      color: SafeHomeColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
    bool destructive = false,
    double bottomSpacing = 9,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Material(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: destructive
                    ? SafeHomeColors.danger.withValues(alpha: 0.17)
                    : SafeHomeColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.028),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: destructive
                              ? SafeHomeColors.danger
                              : SafeHomeColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SafeHomeColors.textSecondary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showSecuritySheet(BuildContext context) async {
    final canUse = await NativeAlarmPermissionService.canUseFullScreenIntent();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (securityContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: SafeHomeColors.info.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 30,
                    color: SafeHomeColors.info,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Cài đặt bảo mật",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: SafeHomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SafeHomeColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              (canUse
                                      ? SafeHomeColors.safe
                                      : SafeHomeColors.warning)
                                  .withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          canUse
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: canUse
                              ? SafeHomeColors.safe
                              : SafeHomeColors.warning,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Báo động toàn màn hình",
                              style: TextStyle(
                                color: SafeHomeColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              canUse
                                  ? "Đã được cấp quyền"
                                  : "Chưa được cấp quyền",
                              style: TextStyle(
                                color: canUse
                                    ? SafeHomeColors.safe
                                    : SafeHomeColors.warning,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SafeHomeColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await NativeAlarmPermissionService.openFullScreenIntentSettings();
                    },
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text("Mở cài đặt hệ thống"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void show({
    required BuildContext context,
    required VoidCallback logout,
    required VoidCallback onEditProfile,
    required String userName,
    required String userGender,
    required String userDob,
    required String userPhone,
    required ValueNotifier<int> inviteCountNotifier,
    required VoidCallback onShareRequests,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL ?? "";

    final displayName = userName.trim().isNotEmpty
        ? userName.trim()
        : "Tài khoản SafeHome";

    final dob = userDob.trim().isNotEmpty ? userDob.split("T").first : "";

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
            ),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: SafeHomeColors.surface,
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: SafeHomeColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 104,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 72,
                                            height: 72,
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: SafeHomeColors.primarySoft,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: SafeHomeColors.primary
                                                    .withValues(alpha: 0.18),
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  SafeHomeColors.surfaceSoft,
                                              backgroundImage:
                                                  photoUrl.isNotEmpty
                                                  ? NetworkImage(photoUrl)
                                                  : null,
                                              child: photoUrl.isNotEmpty
                                                  ? null
                                                  : const Icon(
                                                      Icons.person_rounded,
                                                      size: 37,
                                                      color: SafeHomeColors
                                                          .textSecondary,
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Material(
                                              color: SafeHomeColors.primary,
                                              shape: const CircleBorder(),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.pop(sheetContext);
                                                  onEditProfile();
                                                },
                                                customBorder:
                                                    const CircleBorder(),
                                                child: const SizedBox(
                                                  width: 29,
                                                  height: 29,
                                                  child: Icon(
                                                    Icons.edit_rounded,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 9),
                                      Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: SafeHomeColors.textPrimary,
                                          fontSize: 15,
                                          height: 1.15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 25,
                                  thickness: 1,
                                  color: SafeHomeColors.border,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _compactProfileInfo(
                                        icon: Icons.email_outlined,
                                        label: "Email",
                                        value: user?.email ?? "",
                                      ),
                                      _compactProfileInfo(
                                        icon: Icons.person_outline_rounded,
                                        label: "Giới tính",
                                        value: userGender,
                                      ),
                                      _compactProfileInfo(
                                        icon: Icons.phone_outlined,
                                        label: "SĐT",
                                        value: userPhone,
                                      ),
                                      _compactProfileInfo(
                                        icon: Icons.cake_outlined,
                                        label: "Ngày sinh",
                                        value: dob,
                                      ),
                                      _compactProfileInfo(
                                        icon: Icons.fingerprint_rounded,
                                        label: "UID",
                                        value: user?.uid ?? "",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _actionTile(
                          icon: Icons.mail_rounded,
                          title: "Yêu cầu & lời mời",
                          subtitle: "Xem lời mời chia sẻ và xin gia nhập",
                          color: SafeHomeColors.warning,
                          trailing: ValueListenableBuilder<int>(
                            valueListenable: inviteCountNotifier,
                            builder: (_, inviteCount, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (inviteCount > 0)
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 22,
                                        minHeight: 22,
                                      ),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SafeHomeColors.danger,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        inviteCount > 99
                                            ? "99+"
                                            : "$inviteCount",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  if (inviteCount > 0) const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: SafeHomeColors.textSecondary,
                                  ),
                                ],
                              );
                            },
                          ),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            onShareRequests();
                          },
                        ),

                        _actionTile(
                          icon: Icons.security_rounded,
                          title: "Cài đặt bảo mật",
                          subtitle: "Quyền báo động toàn màn hình",
                          color: SafeHomeColors.info,
                          onTap: () {
                            _showSecuritySheet(sheetContext);
                          },
                        ),

                        const SizedBox(height: 5),

                        _actionTile(
                          icon: Icons.logout_rounded,
                          title: "Đăng xuất",
                          subtitle: "Thoát tài khoản khỏi thiết bị này",
                          color: SafeHomeColors.warning,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            logout();
                          },
                        ),

                        _actionTile(
                          icon: Icons.delete_forever_rounded,
                          title: "Xoá tài khoản",
                          subtitle: "Xoá vĩnh viễn tài khoản và dữ liệu",
                          color: SafeHomeColors.danger,
                          destructive: true,
                          bottomSpacing: 0,
                          onTap: () {
                            _showDeleteConfirmDialog(sheetContext);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
