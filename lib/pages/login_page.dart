import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_setup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'set_password_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool isLogin = true;
  String error = "";
  bool loading = false;

  Future<void> signInWithGoogle() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = "";
    });
    try {
      setState(() => error = "");

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await FirebaseAuth.instance.signInWithCredential(credential);

      final user = cred.user;
      if (user == null) return;

      final hasPassword = user.providerData.any(
            (p) => p.providerId == "password",
      );

      if (!hasPassword) {
        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SetPasswordPage(),
          ),
        );

        return;
      }

      final ref = FirebaseDatabase.instance.ref("accounts/${user.uid}");
      final snap = await ref.get();

      if (!snap.exists) {
        await ref.set({
          "email": user.email ?? "",
          "profile": {
            "name": user.displayName ?? "",
            "gender": "",
            "dob": "",
            "phone": "",
            "photoUrl": user.photoURL ?? "",
          },
          "homes": {},
          "homeOrder": [],
          "shareRequests": {},
          "shareList": {},
          "sharedHomes": {},
        });
      } else {
        await ref.update({
          "email": user.email ?? "",
        });

        await ref.child("profile").update({
          "photoUrl": user.photoURL ?? "",
          "name": user.displayName ?? "",
        });
      }
    } catch (e, stack) {
      setState(() {
        error = "Google login error: $e";
      });

      debugPrint("Google Sign-In ERROR: $e");
      debugPrint("Google Sign-In STACK: $stack");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
    if (loading) return;

    setState(() {
      loading = true;
      error = "";
    });
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
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Widget buildLogo() {
    return Column(
      children: [
        const Icon(
          Icons.home_rounded,
          size: 76,
          color: Colors.green,
        ),

        const SizedBox(height: 10),

        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
            children: [
              TextSpan(
                text: "Safe",
                style: TextStyle(color: Colors.green),
              ),
              TextSpan(
                text: "Home",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),

                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),

                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildLogo(),

                          const SizedBox(height: 22),

                          TextField(
                            controller: email,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email_rounded),
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: pass,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_rounded),
                            ),
                          ),

                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                error,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: loading ? null : submit,
                              child: loading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                isLogin ? "Đăng nhập" : "Đăng ký mới",
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

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

                          const SizedBox(height: 4),

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
          },
        ),
      ),
    );
  }
}