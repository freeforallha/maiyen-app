import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import 'home_page.dart';

class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  bool saving = false;
  String error = "";

  Future<void> savePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pass = passController.text.trim();
    final confirm = confirmController.text.trim();

    if (pass.length < 6) {
      setState(() => error = "Mật khẩu tối thiểu 6 ký tự");
      return;
    }

    if (pass != confirm) {
      setState(() => error = "Mật khẩu nhập lại không khớp");
      return;
    }

    setState(() {
      saving = true;
      error = "";
    });

    try {
      final userEmail = user.email;

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception("Không tìm thấy email tài khoản");
      }

      final credential = EmailAuthProvider.credential(
        email: userEmail,
        password: pass,
      );

      await user.linkWithCredential(credential);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final strings = AppStrings.of(context);
      setState(() {
        error = strings.sanitizeUserMessage(
          e.message ?? "",
          fallback: strings.choose(
            vi: "Không đặt được mật khẩu",
            en: "Could not set password",
            zh: "无法设置密码",
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  void dispose() {
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo mật khẩu"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text(
              "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu mới"),
            ),

            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nhập lại mật khẩu"),
            ),

            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : savePassword,
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Hoàn tất"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
