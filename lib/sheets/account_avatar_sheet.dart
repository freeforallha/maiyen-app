import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../safehome_theme.dart';
import '../services/platform/platform_alarm_permission_service.dart';

class AccountAvatarSheet {
  static void showTopMessage(
    BuildContext context,
    String message, {
    Color color = SafeHomeColors.danger,
  }) {
    final overlay = Overlay.of(context);
    final safeMessage = AppStrings.of(context).sanitizeUserMessage(message);
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
                  safeMessage,
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
    final password = await SafeHomeNavigation.showModalSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _DeleteAccountConfirmSheet(),
    );

    if (password == null || password.trim().isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await _deleteAccount(context, password.trim());
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    String password,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final strings = AppStrings.of(context);

    if (user == null) return;

    final uid = user.uid;

    try {
      final db = FirebaseDatabase.instance;
      final userEmail = user.email;

      if (userEmail == null || userEmail.isEmpty) {
        showTopMessage(context, strings.t("Không tìm thấy tài khoản"));
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

      final rootContext = Navigator.of(context, rootNavigator: true).context;
      Navigator.of(context).pop();

      if (rootContext.mounted) {
        showTopMessage(
          rootContext,
          strings.t("Đã xoá tài khoản"),
          color: SafeHomeColors.success,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      final message =
          e.code == "wrong-password" ||
              e.code == "invalid-credential" ||
              e.code == "invalid-login-credentials"
          ? strings.t("Sai mật khẩu")
          : strings.genericOperationError;

      showTopMessage(context, "${strings.t("Xoá thất bại")}: $message");
    } catch (e) {
      if (!context.mounted) return;

      showTopMessage(
        context,
        strings.sanitizeUserMessage(
          e.toString(),
          fallback: strings.t("Lỗi xoá tài khoản"),
        ),
      );
    }
  }

  static Widget _compactProfileInfo({
    required AppStrings strings,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final displayValue = value.trim().isEmpty
        ? strings.t("Chưa cập nhật")
        : value.trim();

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
    if (!PlatformAlarmPermissionService.isSupported) {
      return;
    }

    final canUse =
        await PlatformAlarmPermissionService.canUseFullScreenIntent();

    if (!context.mounted) return;

    SafeHomeNavigation.pushChildPage<void>(
      context: context,
      routeName: "account_security",
      builder: (securityContext) {
        final strings = AppStrings.of(securityContext);

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
                Text(
                  strings.t("Cài đặt bảo mật"),
                  style: const TextStyle(
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
                            Text(
                              strings.t("Báo động toàn màn hình"),
                              style: const TextStyle(
                                color: SafeHomeColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              canUse
                                  ? strings.t("Đã được cấp quyền")
                                  : strings.t("Chưa được cấp quyền"),
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
                      await PlatformAlarmPermissionService.openFullScreenIntentSettings();
                    },
                    icon: const Icon(Icons.settings_rounded),
                    label: Text(strings.t("Mở cài đặt hệ thống")),
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

    final dob = userDob.trim().isNotEmpty ? userDob.split("T").first : "";
    int hiddenDeleteTapCount = 0;
    DateTime? lastHiddenDeleteTapAt;

    Future<void> handleHiddenDeleteTap(BuildContext sheetContext) async {
      final now = DateTime.now();

      // Không ấn liên tục thì bắt đầu đếm lại.
      final previousTapAt = lastHiddenDeleteTapAt;

      if (previousTapAt == null ||
          now.difference(previousTapAt) > const Duration(seconds: 2)) {
        hiddenDeleteTapCount = 0;
      }

      lastHiddenDeleteTapAt = now;
      hiddenDeleteTapCount++;

      if (hiddenDeleteTapCount < 5) {
        return;
      }

      hiddenDeleteTapCount = 0;
      lastHiddenDeleteTapAt = null;

      await _showDeleteConfirmDialog(sheetContext);
    }

    SafeHomeNavigation.pushChildPage<void>(
      context: context,
      routeName: "account",
      builder: (sheetContext) {
        final strings = AppStrings.of(sheetContext);
        final displayName = userName.trim().isNotEmpty
            ? userName.trim()
            : strings.t("Tài khoản cá nhân");

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
                                                onTap: onEditProfile,
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
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () async {
                                          await handleHiddenDeleteTap(
                                            sheetContext,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          child: Text(
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
                                        strings: strings,
                                        icon: Icons.email_outlined,
                                        label: "Email",
                                        value: user?.email ?? "",
                                      ),
                                      _compactProfileInfo(
                                        strings: strings,
                                        icon: Icons.person_outline_rounded,
                                        label: strings.t("Giới tính"),
                                        value: userGender,
                                      ),
                                      _compactProfileInfo(
                                        strings: strings,
                                        icon: Icons.phone_outlined,
                                        label: strings.t("SĐT"),
                                        value: userPhone,
                                      ),
                                      _compactProfileInfo(
                                        strings: strings,
                                        icon: Icons.cake_outlined,
                                        label: strings.t("Ngày sinh"),
                                        value: dob,
                                      ),
                                      _compactProfileInfo(
                                        strings: strings,
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
                          title: strings.t("Yêu cầu & lời mời"),
                          subtitle: strings.t(
                            "Xem lời mời chia sẻ và xin gia nhập",
                          ),
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
                          onTap: onShareRequests,
                        ),

                        if (PlatformAlarmPermissionService.isSupported)
                          _actionTile(
                            icon: Icons.security_rounded,
                            title: strings.t("Cài đặt bảo mật"),
                            subtitle: strings.t("Quyền báo động toàn màn hình"),
                            color: SafeHomeColors.info,
                            onTap: () async {
                              await _showSecuritySheet(sheetContext);
                            },
                          ),

                        const SizedBox(height: 5),

                        _actionTile(
                          icon: Icons.logout_rounded,
                          title: strings.t("Đăng xuất"),
                          subtitle: strings.t(
                            "Thoát tài khoản khỏi thiết bị này",
                          ),
                          color: SafeHomeColors.warning,
                          onTap: logout,
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

class _DeleteAccountConfirmSheet extends StatefulWidget {
  const _DeleteAccountConfirmSheet();

  @override
  State<_DeleteAccountConfirmSheet> createState() =>
      _DeleteAccountConfirmSheetState();
}

class _DeleteAccountConfirmSheetState
    extends State<_DeleteAccountConfirmSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      return;
    }

    _passwordFocusNode.unfocus();
    Navigator.of(context).pop(password);
  }

  void _cancel() {
    _passwordFocusNode.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return PopScope(
      canPop: !keyboardOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_passwordFocusNode.hasFocus) {
          _passwordFocusNode.unfocus();
        }
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: const BoxDecoration(
                  color: SafeHomeColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                    bottom: Radius.circular(22),
                  ),
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: SafeHomeColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: SafeHomeColors.danger.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: SafeHomeColors.danger,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          strings.t("Xoá tài khoản"),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: SafeHomeColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.t("Hành động này sẽ xoá toàn bộ dữ liệu:"),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: SafeHomeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("• ${strings.t("Nhà và thiết bị")}"),
                      Text("• ${strings.t("Chia sẻ và quyền truy cập")}"),
                      Text("• ${strings.t("Toàn bộ dữ liệu liên quan")}"),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: true,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: strings.t("Mật khẩu xác nhận"),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          filled: true,
                          fillColor: SafeHomeColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancel,
                              child: Text(strings.t("Huỷ")),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: SafeHomeColors.danger,
                              ),
                              onPressed: _submit,
                              child: Text(strings.t("Xoá tài khoản")),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
