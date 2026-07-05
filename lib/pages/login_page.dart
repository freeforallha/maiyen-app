import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_setup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auto_login_service.dart';
import '../safehome_theme.dart';
import 'package:safehome_app/helpers/debug_log.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirmPass = TextEditingController();

  bool isLogin = true;
  String error = "";
  bool loading = false;
  bool rememberLogin = true;

  Future<void> signInWithGoogle() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final credentialResult = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 20));

      final user = credentialResult.user;

      if (user == null) {
        throw Exception("Không thể đăng nhập bằng Google");
      }

      // Làm mới token trước khi AuthGate đọc Realtime Database.
      await user.getIdToken(true);

      // Google Sign-In không dùng mật khẩu đã lưu của tài khoản email trước đó.
      try {
        await AutoLoginService.clearLogin().timeout(
          const Duration(seconds: 10),
        );
      } catch (clearError) {
        safeDebugPrint("CLEAR_SAVED_LOGIN_AFTER_GOOGLE_ERROR: $clearError");
      }

      // Không đọc/ghi Database và không tự điều hướng tại đây.
      // AuthGate sẽ tự mở ProfileSetupPage hoặc HomePage theo UID mới.
    } on FirebaseAuthException catch (e) {
      safeDebugPrint("GOOGLE_LOGIN_FIREBASE_ERROR: ${e.code}");

      if (!mounted) return;

      setState(() {
        error = e.message ?? "Không thể đăng nhập bằng Google";
      });
    } catch (e) {
      safeDebugPrint("GOOGLE_LOGIN_ERROR");

      if (!mounted) return;

      setState(() {
        error = "Không thể đăng nhập bằng Google: $e";
      });
    } finally {
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
            decoration: const InputDecoration(hintText: "Nhập email của bạn"),
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

    try {
      final emailInput = email.text.trim();
      final passwordInput = pass.text.trim();

      if (emailInput.isEmpty || passwordInput.isEmpty) {
        throw Exception("Vui lòng nhập email và mật khẩu");
      }

      if (isLogin) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailInput,
              password: passwordInput,
            )
            .timeout(const Duration(seconds: 20));

        if (rememberLogin) {
          await AutoLoginService.saveLogin(
            email: emailInput,
          ).timeout(const Duration(seconds: 10));
        } else {
          await AutoLoginService.clearLogin().timeout(
            const Duration(seconds: 10),
          );
        }

        return;
      }

      if (passwordInput != confirmPass.text.trim()) {
        throw Exception("Mật khẩu xác nhận không khớp");
      }

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailInput,
            password: passwordInput,
          )
          .timeout(const Duration(seconds: 20));

      final user = cred.user;

      if (user == null) {
        throw Exception("Không thể tạo tài khoản");
      }

      await AutoLoginService.saveLogin(
        email: emailInput,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ProfileSetupPage(uid: user.uid, email: user.email ?? emailInput),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

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

      safeDebugPrint("EMAIL_LOGIN_FIREBASE_ERROR: ${e.code}");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst("Exception: ", "");
      });

      safeDebugPrint("EMAIL_LOGIN_ERROR");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    AutoLoginService.loadSavedLogin().then((saved) {
      if (!mounted) return;

      final savedEmail = saved["email"] ?? "";

      if (savedEmail.isNotEmpty) {
        setState(() {
          email.text = savedEmail;
          rememberLogin = true;
        });
      }
    });
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  Widget buildLogo() {
    return Image.asset(
      "assets/login.png",
      width: 180,
      height: 180,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafeHomeColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),

                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),

                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: SafeHomeColors.border),
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

                          if (!isLogin) ...[
                            const SizedBox(height: 10),

                            TextField(
                              controller: confirmPass,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Xác nhận mật khẩu",
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                          ],
                          if (isLogin)
                            CheckboxListTile(
                              value: rememberLogin,
                              onChanged: (value) {
                                setState(() {
                                  rememberLogin = value ?? true;
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text("Ghi nhớ tài khoản"),
                            ),
                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                error,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: SafeHomeColors.danger,
                                ),
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
                                  : Text(isLogin ? "Đăng nhập" : "Đăng ký mới"),
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
                                border: Border.all(color: Colors.grey.shade300),
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
                          const SizedBox(height: 12),

                          const SizedBox(height: 4),

                          TextButton(
                            onPressed: _showResetPasswordDialog,
                            child: const Text(
                              "Quên mật khẩu?",
                              style: TextStyle(color: SafeHomeColors.primary),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLogin = !isLogin;
                                error = "";

                                pass.clear();
                                confirmPass.clear();
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
