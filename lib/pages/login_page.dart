import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_setup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auto_login_service.dart';
import '../safehome_theme.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
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

    final strings = AppStrings.of(context);

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
        throw Exception(
          strings.choose(
            vi: "Không thể đăng nhập bằng Google",
            en: "Could not sign in with Google",
            zh: "无法使用 Google 登录",
          ),
        );
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
        error =
            e.message ??
            strings.choose(
              vi: "Không thể đăng nhập bằng Google",
              en: "Could not sign in with Google",
              zh: "无法使用 Google 登录",
            );
      });
    } catch (e) {
      safeDebugPrint("GOOGLE_LOGIN_ERROR");

      if (!mounted) return;

      setState(() {
        error = strings.choose(
          vi: "Không thể đăng nhập bằng Google: $e",
          en: "Could not sign in with Google: $e",
          zh: "无法使用 Google 登录：$e",
        );
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
          title: Text(AppStrings.of(context).t("Khôi phục mật khẩu")),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppStrings.of(context).t("Nhập email của bạn"),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.of(context).t("Huỷ")),
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
                    error = AppStrings.of(context).t("Đã gửi email khôi phục");
                  });
                } catch (e) {
                  setState(() {
                    error = AppStrings.of(context).t("Không gửi được email");
                  });
                }
              },
              child: Text(AppStrings.of(context).t("Gửi")),
            ),
          ],
        );
      },
    );
  }

  Future<void> submit() async {
    if (loading) return;

    final strings = AppStrings.of(context);

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final emailInput = email.text.trim();
      final passwordInput = pass.text.trim();

      if (emailInput.isEmpty || passwordInput.isEmpty) {
        throw Exception(strings.t("Vui lòng nhập email và mật khẩu"));
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
        throw Exception(strings.t("Mật khẩu xác nhận không khớp"));
      }

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailInput,
            password: passwordInput,
          )
          .timeout(const Duration(seconds: 20));

      final user = cred.user;

      if (user == null) {
        throw Exception(strings.t("Không thể tạo tài khoản"));
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
          error = strings.t("Sai tài khoản");
        } else if (e.code == "wrong-password") {
          error = strings.t("Sai mật khẩu");
        } else if (e.code == "email-already-in-use") {
          error = strings.t("Email đã tồn tại");
        } else if (e.code == "weak-password") {
          error = strings.t("Mật khẩu quá yếu");
        } else if (e.code == "invalid-credential") {
          error = strings.t("Sai email hoặc mật khẩu");
        } else {
          error = e.message ?? strings.t("Lỗi đăng nhập");
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

  void _showLanguageSheet() {
    final strings = AppStrings.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget option({
          required String code,
          required String title,
          required String subtitle,
        }) {
          final selected = appLanguageController.languageCode == code;

          return ListTile(
            leading: Icon(
              selected ? Icons.check_circle_rounded : Icons.language_rounded,
              color: selected
                  ? SafeHomeColors.primary
                  : SafeHomeColors.textSecondary,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: () {
              appLanguageController.setLanguageCode(code);
              Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: const BoxDecoration(
              color: SafeHomeColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: SafeHomeColors.primary,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      strings.chooseLanguage,
                      style: const TextStyle(
                        color: SafeHomeColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                option(code: "vi", title: "Tiếng Việt", subtitle: "Vietnamese"),
                option(code: "en", title: "English", subtitle: "Tiếng Anh"),
                option(code: "zh", title: "中文", subtitle: "Chinese Simplified"),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: SafeHomeColors.background,

      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
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
                                decoration: InputDecoration(
                                  labelText: strings.choose(
                                    vi: "Mật khẩu",
                                    en: "Password",
                                    zh: "密码",
                                  ),
                                  prefixIcon: const Icon(Icons.lock_rounded),
                                ),
                              ),

                              if (!isLogin) ...[
                                const SizedBox(height: 10),

                                TextField(
                                  controller: confirmPass,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: strings.t("Xác nhận mật khẩu"),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
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
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(strings.t("Ghi nhớ tài khoản")),
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
                                      : Text(
                                          isLogin
                                              ? strings.t("Đăng nhập")
                                              : strings.t("Đăng ký mới"),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
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
                              const SizedBox(height: 12),

                              const SizedBox(height: 4),

                              TextButton(
                                onPressed: _showResetPasswordDialog,
                                child: Text(
                                  strings.t("Quên mật khẩu?"),
                                  style: const TextStyle(
                                    color: SafeHomeColors.primary,
                                  ),
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
                                      ? strings.t("Chưa có tài khoản? Đăng ký")
                                      : strings.t("Đã có tài khoản? Đăng nhập"),
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
            Positioned(
              top: 8,
              right: 12,
              child: Material(
                color: SafeHomeColors.surface,
                borderRadius: BorderRadius.circular(999),
                child: IconButton(
                  tooltip: strings.language,
                  icon: const Icon(Icons.language_rounded),
                  color: SafeHomeColors.primary,
                  onPressed: _showLanguageSheet,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
