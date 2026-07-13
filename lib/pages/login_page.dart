import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_setup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auto_login_service.dart';
import '../services/platform/platform_auto_away_task_service.dart';
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
        throw Exception(strings.t("Không thể đăng nhập bằng Google"));
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
        error = strings.sanitizeUserMessage(
          e.message ?? "",
          fallback: strings.t("Không thể đăng nhập bằng Google"),
        );
      });
    } catch (e) {
      safeDebugPrint("GOOGLE_LOGIN_ERROR");

      if (!mounted) return;

      setState(() {
        error = strings.t("Không thể đăng nhập bằng Google");
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
    final strings = AppStrings.of(context);
    String inputEmail = "";

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final emailInput = inputEmail.trim();

            Future<void> submit() async {
              if (emailInput.isEmpty) return;

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: emailInput,
                );

                if (!mounted || !dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                setState(() {
                  error = strings.t("Đã gửi email khôi phục");
                });
              } catch (_) {
                if (!mounted) return;

                setState(() {
                  error = strings.t("Không gửi được email");
                });
              }
            }

            return AlertDialog(
              title: Text(strings.t("Khôi phục mật khẩu")),
              content: TextFormField(
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: strings.t("Nhập email của bạn"),
                ),
                onChanged: (value) {
                  inputEmail = value.trim();
                  setDialogState(() {});
                },
                onFieldSubmitted: (_) => submit(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(strings.t("Huỷ")),
                ),
                ElevatedButton(
                  onPressed: emailInput.isEmpty ? null : submit,
                  child: Text(strings.t("Gửi")),
                ),
              ],
            );
          },
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
          error = strings.sanitizeUserMessage(
            e.message ?? "",
            fallback: strings.t("Lỗi đăng nhập"),
          );
        }
      });

      safeDebugPrint("EMAIL_LOGIN_FIREBASE_ERROR: ${e.code}");
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = strings.sanitizeUserMessage(
          e.toString().replaceFirst("Exception: ", ""),
          fallback: strings.t("Lỗi đăng nhập"),
        );
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

  String _languageSubtitle(String code) {
    switch (code) {
      case "vi":
        return "Vietnamese";
      case "en":
        return "English";
      case "zh":
        return "Chinese Simplified";
      case "ko":
        return "Korean";
      case "ja":
        return "Japanese";
      case "de":
        return "German";
      case "ru":
        return "Russian";
      case "fr":
        return "French";
      case "es":
        return "Spanish";
      case "id":
        return "Indonesian";
      case "th":
        return "Thai";
      case "ms":
        return "Malay";
      case "fil":
        return "Filipino";
      case "km":
        return "Khmer";
      default:
        return code;
    }
  }

  void _showLanguageSheet() {
    final strings = AppStrings.of(context);
    bool isSearching = false;
    String query = "";

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
            onTap: () async {
              await appLanguageController.setLanguageCode(code);
              await PlatformAutoAwayTaskService.refreshNotificationLanguage();

              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            },
          );
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final q = query.trim().toLowerCase();
            final visibleCodes = AppLanguageController.supportedCodes.where((
              code,
            ) {
              final title = AppLanguageController.languageLabels[code] ?? code;
              final subtitle = _languageSubtitle(code);

              if (q.isEmpty) {
                return true;
              }

              return code.toLowerCase().contains(q) ||
                  title.toLowerCase().contains(q) ||
                  subtitle.toLowerCase().contains(q);
            }).toList();
            final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
            final screenHeight = MediaQuery.sizeOf(sheetContext).height;
            final maxSheetHeight = screenHeight - bottomInset - 24;
            final constrainedMaxHeight = maxSheetHeight
                .clamp(320.0, screenHeight * 0.92)
                .toDouble();

            return AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constrainedMaxHeight),
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      decoration: const BoxDecoration(
                        color: SafeHomeColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
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
                              Expanded(
                                child: Text(
                                  strings.chooseLanguage,
                                  style: const TextStyle(
                                    color: SafeHomeColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: strings.t("Tìm ngôn ngữ"),
                                onPressed: () {
                                  setSheetState(() {
                                    isSearching = !isSearching;

                                    if (!isSearching) {
                                      query = "";
                                    }
                                  });
                                },
                                icon: Icon(
                                  isSearching
                                      ? Icons.close_rounded
                                      : Icons.search_rounded,
                                  color: SafeHomeColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (isSearching) ...[
                            const SizedBox(height: 10),
                            TextField(
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: strings.t("Tìm ngôn ngữ"),
                                prefixIcon: const Icon(Icons.search_rounded),
                                filled: true,
                                fillColor: SafeHomeColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                setSheetState(() {
                                  query = value;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 10),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: visibleCodes.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        child: Text(
                                          strings.t("Không có kết quả"),
                                          style: const TextStyle(
                                            color: SafeHomeColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : [
                                      for (final code in visibleCodes)
                                        option(
                                          code: code,
                                          title:
                                              AppLanguageController
                                                  .languageLabels[code] ??
                                              code,
                                          subtitle: _languageSubtitle(code),
                                        ),
                                    ],
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
                                decoration: InputDecoration(
                                  labelText: strings.t("Email"),
                                  prefixIcon: const Icon(Icons.email_rounded),
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextField(
                                controller: pass,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: strings.t("Mật khẩu"),
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
