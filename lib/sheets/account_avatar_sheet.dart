import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/native_alarm_permission_service.dart';
class AccountAvatarSheet {
  static void showTopMessage(
      BuildContext context,
      String message, {
        Color color = Colors.red,
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
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
  static Future<void> _showDeleteConfirmDialog(
      BuildContext context,
      ) async {
    final passwordController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Xoá tài khoản"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hành động này sẽ xoá toàn bộ dữ liệu:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text("• Homes, Devices"),
              const Text("• Share / quyền truy cập"),
              const Text("• Tất cả dữ liệu liên quan"),
              const SizedBox(height: 12),
              const Text("Nhập mật khẩu để xác nhận:"),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Password",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Xoá"),
            ),
          ],
        );
      },
    );

    if (ok != true) {
      passwordController.dispose();
      return;
    }

    await _deleteAccount(
      context,
      passwordController.text.trim(),
    );
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

      final credential = EmailAuthProvider.credential(
        email: user.email!,
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
      // user là OWNER
      for (final homeId in ownHomes.keys) {
        final sharedSnap = await db.ref("sharedByHome/$homeId").get();

        if (sharedSnap.exists) {
          final sharedMap = Map<String, dynamic>.from(sharedSnap.value as Map);

          for (final memberUid in sharedMap.keys) {
            updates["accounts/$memberUid/sharedHomes/$homeId"] = null;
          }
        }

        updates["sharedByHome/$homeId"] = null;
        updates["homeChats/$homeId"] = null;
      }

      // user là MEMBER trong home người khác
      for (final homeId in sharedHomes.keys) {
        final sharedInfo = sharedHomes[homeId] is Map
            ? Map<String, dynamic>.from(sharedHomes[homeId])
            : <String, dynamic>{};

        final ownerUid = sharedInfo["ownerUid"];

        updates["sharedByHome/$homeId/$uid"] = null;

        if (ownerUid != null) {
          updates["accounts/$ownerUid/shareList/$homeId/$uid"] = null;
        }
      }

      // xoá account user cuối cùng, KHÔNG xoá accounts/$uid/homes/... riêng nữa
      updates["accounts/$uid"] = null;

      await db.ref().update(updates);

      await user.delete();

      if (!context.mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xoá tài khoản")),
      );
    } on FirebaseAuthException catch (e) {
      showTopMessage(context, "Xoá thất bại: ${e.message ?? 'Unknown error'}");
    } catch (e) {
      showTopMessage(context, "Lỗi xoá account: $e");
    }
  }

  static void show({
    required BuildContext context,
    required VoidCallback logout,
    required VoidCallback onEditProfile,
    required String userName,
    required String userGender,
    required String userDob,
    required String userPhone,
    required int inviteCount,
    required VoidCallback onShareRequests,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    Widget infoRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? "Chưa cập nhật" : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    Widget dangerTile({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
        builder: (ctx) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HANDLE
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // AVATAR
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                            (user?.photoURL?.isNotEmpty == true)
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: (user?.photoURL == null)
                                ? const Icon(
                              Icons.person,
                              size: 42,
                              color: Colors.grey,
                            )
                                : null,
                          ),

                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                onEditProfile();
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        user?.email ?? "No email",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "UID: ${user?.uid ?? 'Unknown'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // INFO BOX
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            infoRow("Tên", userName),
                            const SizedBox(height: 8),
                            infoRow("Giới tính", userGender),
                            const SizedBox(height: 8),
                            infoRow("Số điện thoại", userPhone),
                            const SizedBox(height: 8),
                            infoRow(
                              "Ngày sinh",
                              userDob.isNotEmpty ? userDob.split('T')[0] : "",
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.mail_rounded, color: Colors.orange),
                          ),
                          title: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Yêu cầu & lời mời",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (inviteCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "$inviteCount",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(ctx);
                            onShareRequests();
                          },
                        ),
                      ),

                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Colors.blue,
                            ),
                          ),
                          title: const Text(
                            "Cài đặt bảo mật",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            final canUse =
                            await NativeAlarmPermissionService.canUseFullScreenIntent();

                            if (!ctx.mounted) return;

                            showModalBottomSheet(
                              context: ctx,
                              builder: (_) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.security_rounded,
                                          size: 48,
                                          color: Colors.blue,
                                        ),

                                        const SizedBox(height: 12),

                                        const Text(
                                          "Cài đặt bảo mật",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        ListTile(
                                          leading: Icon(
                                            canUse
                                                ? Icons.check_circle
                                                : Icons.warning_amber_rounded,
                                            color: canUse
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          title: const Text(
                                            "Báo động toàn màn hình",
                                          ),
                                          subtitle: Text(
                                            canUse
                                                ? "Đã được cấp quyền"
                                                : "Chưa được cấp quyền",
                                          ),
                                          onTap: () async {
                                            await NativeAlarmPermissionService
                                                .openFullScreenIntentSettings();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // LOGOUT
                      dangerTile(
                        icon: Icons.logout_rounded,
                        title: "Đăng xuất",
                        onTap: () {
                          Navigator.pop(ctx);
                          logout();
                        },
                      ),

                      // DELETE
                      dangerTile(
                        icon: Icons.delete_forever_rounded,
                        title: "Xoá tài khoản",
                        onTap: () {
                          _showDeleteConfirmDialog(ctx);                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );
  }
}