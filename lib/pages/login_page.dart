import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_setup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool isLogin = true;
  String error = "";

  Future<void> signInWithGoogle() async {
    try {
      setState(() => error = "");

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e, stack) {
      setState(() {
        error = "Google login error: $e";
      });

      debugPrint("Google Sign-In ERROR: $e");
      debugPrint("Google Sign-In STACK: $stack");
    }
  }

  void _showResetPasswordDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Khôi phục mật khẩu"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Nhập email của bạn",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () async {
                final emailInput = controller.text.trim();
                if (emailInput.isEmpty) return;

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: emailInput,
                  );

                  if (!mounted) return;

                  Navigator.pop(context);

                  setState(() {
                    error = "Đã gửi email khôi phục";
                  });
                } catch (e) {
                  setState(() {
                    error = "Không gửi được email";
                  });
                }
              },
              child: const Text("Gửi"),
            ),
          ],
        );
      },
    );
  }

  Future<void> submit() async {
    setState(() => error = "");

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );

        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      final user = cred.user;

      if (user == null) {
        setState(() => error = "Không tạo được user");
        return;
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProfileSetupPage(
            uid: user.uid,
            email: email.text.trim().toLowerCase(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == "user-not-found") {
          error = "Sai tài khoản";
        } else if (e.code == "wrong-password") {
          error = "Sai mật khẩu";
        } else if (e.code == "email-already-in-use") {
          error = "Email đã tồn tại";
        } else if (e.code == "weak-password") {
          error = "Mật khẩu quá yếu";
        } else if (e.code == "invalid-credential") {
          error = "Sai email hoặc mật khẩu";
        } else {
          error = e.message ?? "Lỗi đăng nhập";
        }
      });
    } catch (e) {
      setState(() {
        error = "Lỗi hệ thống";
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "SafeHome",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),

                  TextField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                  ),

                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: submit,
                    child: Text(isLogin ? "Login" : "Sign Up"),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: signInWithGoogle,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 10,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "G",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                        error = "";
                      });
                    },
                    child: Text(
                      isLogin
                          ? "Chưa có tài khoản? Đăng ký"
                          : "Đã có tài khoản? Đăng nhập",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}