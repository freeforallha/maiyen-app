import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_setup_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auto_login_service.dart';
import '../services/platform/platform_auto_away_task_service.dart';
import '../services/session_logout_service.dart';
import '../services/single_device_session_service.dart';
import '../helpers/top_toast.dart';
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
  Future<bool>? _sessionConflictDialogFuture;
  bool _forcedLogoutNoticeCheckScheduled = false;

  Future<bool> _claimSessionAfterConfirmation(User user) async {
    var allowReplacingOtherInstallation =
        await SingleDeviceSessionService.hasActiveSessionOnAnotherInstallation(
          uid: user.uid,
        );

    if (allowReplacingOtherInstallation &&
        !await _confirmReplacingActiveSession()) {
      return false;
    }

    try {
      await SingleDeviceSessionService.claimForInteractiveLogin(
        uid: user.uid,
        allowReplacingOtherInstallation: allowReplacingOtherInstallation,
      );
      return true;
    } on ActiveSessionConflictException {
      if (allowReplacingOtherInstallation ||
          !await _confirmReplacingActiveSession()) {
        return false;
      }

      allowReplacingOtherInstallation = true;
      await SingleDeviceSessionService.claimForInteractiveLogin(
        uid: user.uid,
        allowReplacingOtherInstallation: true,
      );
      return true;
    }
  }

  Future<bool> _confirmReplacingActiveSession() {
    final running = _sessionConflictDialogFuture;

    if (running != null) {
      return running;
    }

    final future = _showSessionConflictDialog();
    _sessionConflictDialogFuture = future;

    return future.whenComplete(() {
      if (identical(_sessionConflictDialogFuture, future)) {
        _sessionConflictDialogFuture = null;
      }
    });
  }

  Future<bool> _showSessionConflictDialog() async {
    if (!mounted) {
      return false;
    }

    final strings = AppStrings.of(context);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(strings.accountInUseTitle),
            content: Text(strings.accountInUseMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.t("Huỷ")),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(strings.continueSignInLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _scheduleForcedLogoutNoticeCheck() {
    if (_forcedLogoutNoticeCheckScheduled) {
      return;
    }

    _forcedLogoutNoticeCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forcedLogoutNoticeCheckScheduled = false;

      if (!mounted || !SessionLogoutService.consumeForcedLogoutNotice()) {
        return;
      }

      final strings = AppStrings.of(context);
      showTopToast(
        context,
        strings.forcedRemoteSessionLogoutMessage,
        color: SafeHomeColors.danger,
        icon: Icons.logout_rounded,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    if (loading) return;

    final strings = AppStrings.of(context);
    var sessionClaimed = false;

    setState(() {
      loading = true;
      error = "";
    });

    SingleDeviceSessionService.prepareForInteractiveLogin();

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        SingleDeviceSessionService.cancelInteractiveLogin();
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

      sessionClaimed = await _claimSessionAfterConfirmation(user);

      if (!sessionClaimed) {
        return;
      }

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
      if (!sessionClaimed) {
        if (FirebaseAuth.instance.currentUser != null) {
          try {
            await SessionLogoutService.signOutCurrentUser();
          } catch (logoutError) {
            safeDebugPrint("GOOGLE_LOGIN_CLEANUP_SIGN_OUT_ERROR: $logoutError");
          }
        }

        SingleDeviceSessionService.cancelInteractiveLogin();
      }

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
    var sessionClaimed = false;

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
        SingleDeviceSessionService.prepareForInteractiveLogin();

        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailInput,
              password: passwordInput,
            )
            .timeout(const Duration(seconds: 20));

        final user = credential.user;

        if (user == null) {
          throw Exception(strings.t("Lỗi đăng nhập"));
        }

        await user.getIdToken(true);

        sessionClaimed = await _claimSessionAfterConfirmation(user);

        if (!sessionClaimed) {
          return;
        }

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

      SingleDeviceSessionService.prepareForInteractiveLogin();

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

      await user.getIdToken(true);

      sessionClaimed = await _claimSessionAfterConfirmation(user);

      if (!sessionClaimed) {
        return;
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
      if (!sessionClaimed) {
        if (FirebaseAuth.instance.currentUser != null) {
          try {
            await SessionLogoutService.signOutCurrentUser();
          } catch (logoutError) {
            safeDebugPrint("EMAIL_LOGIN_CLEANUP_SIGN_OUT_ERROR: $logoutError");
          }
        }

        SingleDeviceSessionService.cancelInteractiveLogin();
      }

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

    SessionLogoutService.forcedLogoutNoticeRevision.addListener(
      _scheduleForcedLogoutNoticeCheck,
    );
    _scheduleForcedLogoutNoticeCheck();

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
    SessionLogoutService.forcedLogoutNoticeRevision.removeListener(
      _scheduleForcedLogoutNoticeCheck,
    );
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
      case "my":
        return "Burmese • Myanmar";
      case "lo":
        return appLanguageController.languageCode == "vi" ? "Tiếng Lào" : "Lao";
      case "ta":
        return "Tamil • Singapore";
      case "pt":
        return "Portuguese • Timor-Leste";
      case "tet":
        return "Tetum • Timor-Leste";
      case "it":
        return "Italian • Italy";
      case "pl":
        return "Polish • Poland";
      case "nl":
        return "Dutch • Netherlands";
      case "cs":
        return "Czech • Czechia";
      case "sk":
        return "Slovak • Slovakia";
      case "uk":
        return "Ukrainian • Ukraine";
      case "ro":
        return "Romanian • Romania";
      case "hu":
        return "Hungarian • Hungary";
      case "bg":
        return "Bulgarian • Bulgaria";
      case "hr":
        return "Croatian • Croatia";
      case "sr":
        return "Serbian • Serbia";
      case "bs":
        return "Bosnian • Bosnia and Herzegovina";
      case "sl":
        return "Slovenian • Slovenia";
      case "mk":
        return "Macedonian • North Macedonia";
      case "sq":
        return "Albanian • Albania";
      case "el":
        return "Greek • Greece";
      case "tr":
        return "Turkish • Türkiye";
      case "sv":
        return "Swedish • Sweden";
      case "da":
        return "Danish • Denmark";
      case "nb":
        return "Norwegian Bokmål • Norway";
      case "fi":
        return "Finnish • Finland";
      case "is":
        return "Icelandic • Iceland";
      case "et":
        return "Estonian • Estonia";
      case "lv":
        return "Latvian • Latvia";
      case "lt":
        return "Lithuanian • Lithuania";
      case "ga":
        return "Irish • Ireland";
      case "mt":
        return "Maltese • Malta";
      case "be":
        return "Belarusian • Belarus";
      case "lb":
        return "Luxembourgish • Luxembourg";
      case "ca":
        return "Catalan • Andorra";
      case "cnr":
        return "Montenegrin • Montenegro";
      case "hy":
        return "Armenian • Armenia";
      case "ka":
        return "Georgian • Georgia";
      case "az":
        return "Azerbaijani • Azerbaijan";
      default:
        return code;
    }
  }

  String _languageSearchAliases(String code) {
    return switch (code) {
      "lo" => "lao tiếng lào ລາວ",
      "ta" => "tamil tiếng tamil தமிழ் singapore",
      "pt" => "portuguese tiếng bồ đào nha português timor leste",
      "tet" => "tetum tiếng tetum tetun timor leste",
      "it" => "italian italiano tiếng ý italy italia",
      "pl" => "polish polski tiếng ba lan poland polska",
      "nl" => "dutch nederlands tiếng hà lan netherlands nederland",
      "cs" => "czech čeština tiếng séc czechia česko",
      "sk" => "slovak slovenčina tiếng slovakia slovensko",
      "uk" => "ukrainian українська tiếng ukraina ukraine україна",
      "ro" => "romanian română tiếng rumani romania românia",
      "hu" => "hungarian magyar tiếng hungary magyarország",
      "bg" => "bulgarian български tiếng bulgaria българия",
      "hr" => "croatian hrvatski tiếng croatia hrvatska",
      "sr" => "serbian srpski tiếng serbia srbija",
      "bs" => "bosnian bosanski tiếng bosnia bosna hercegovina",
      "sl" => "slovenian slovenščina tiếng slovenia slovenija",
      "mk" => "macedonian македонски tiếng bắc macedonia severna makedonija",
      "sq" => "albanian shqip tiếng albania shqipëri",
      "el" => "greek ελληνικά tiếng hy lạp greece ελλάδα",
      "tr" => "turkish türkçe tiếng thổ nhĩ kỳ türkiye",
      "sv" => "swedish svenska tiếng thụy điển sweden sverige",
      "da" => "danish dansk tiếng đan mạch denmark danmark",
      "nb" => "norwegian norsk bokmål tiếng na uy norway norge",
      "fi" => "finnish suomi tiếng phần lan finland",
      "is" => "icelandic íslenska tiếng iceland iceland",
      "et" => "estonian eesti tiếng estonia estonia",
      "lv" => "latvian latviešu tiếng latvia latvija",
      "lt" => "lithuanian lietuvių tiếng litva lithuania lietuva",
      "ga" => "irish gaeilge tiếng ireland éire",
      "mt" => "maltese malti tiếng malta",
      "be" => "belarusian беларуская tiếng belarus беларусь",
      "lb" => "luxembourgish lëtzebuergesch tiếng luxembourg luxemburg",
      "ca" => "catalan català tiếng catalan andorra catalunya",
      "cnr" => "montenegrin crnogorski tiếng montenegro crna gora",
      "hy" => "armenian հայերեն tiếng armenia hayastan",
      "ka" => "georgian ქართული tiếng georgia sakartvelo",
      "az" => "azerbaijani azərbaycan dili tiếng azerbaijan azərbaycan",
      _ => "",
    };
  }

  String _languageFlag(String code) {
    return AppLanguageController.languageFlags[code] ?? "🌐";
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
            leading: SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  _languageFlag(code),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: SafeHomeColors.primary,
                  )
                : null,
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
              final aliases = _languageSearchAliases(code);

              if (q.isEmpty) {
                return true;
              }

              return code.toLowerCase().contains(q) ||
                  title.toLowerCase().contains(q) ||
                  subtitle.toLowerCase().contains(q) ||
                  aliases.contains(q);
            }).toList()
              ..sort((a, b) => _languageSubtitle(a).toLowerCase().compareTo(
                    _languageSubtitle(b).toLowerCase(),
                  ));
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
