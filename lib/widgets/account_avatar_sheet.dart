import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
                      color: Colors.black.withOpacity(0.15),
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
      entry.remove();
    });
  }
  static Future<void> _showDeleteConfirmDialog(
      BuildContext context,
      String userName,
      String userGender,
      String userDob,
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

    if (ok != true) return;

    await _deleteAccount(
      context,
      passwordController.text.trim(),
    );
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

      // 1. Re-auth trước
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Xoá toàn bộ realtime DB
      await db.ref("accounts/$uid").remove();
      await db.ref("sharedByHome/$uid").remove();

      // 3. Xoá auth user
      await user.delete();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã xoá tài khoản"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showTopMessage(context, "Xoá thất bại: ${e.message ?? 'Unknown error'}");
    }
  }

  static void show({
    required BuildContext context,
    required VoidCallback logout,
    required String userName,
    required String userGender,
    required String userDob,
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
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: (user?.photoURL != null)
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: (user?.photoURL == null)
                            ? const Icon(Icons.person,
                            size: 42, color: Colors.grey)
                            : null,
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
                            infoRow(
                              "Ngày sinh",
                              userDob.isNotEmpty ? userDob.split('T')[0] : "",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

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
                          _showDeleteConfirmDialog(ctx, userName, userGender, userDob);
                        },
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