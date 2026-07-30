part of '../all_home_page.dart';

extension _AllHomeDeletePart on _AllHomeState {
  Future<void> confirmDeleteSelected() async {
    final sharedCount = selectedHomes.where((id) {
      final home = safeMap(homes[id]);

      return home["_shared"] == true;
    }).length;

    final ownCount = selectedHomes.length - sharedCount;

    String message = "";

    if (sharedCount > 0 && ownCount > 0) {
      message = _strings.t(
        "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.",
      );
    } else if (sharedCount > 0) {
      message = _strings.t("Bạn sẽ rời khỏi các nhà được chia sẻ.");
    } else {
      message = _strings.t("Các nhà đã chọn sẽ bị xoá vĩnh viễn.");
    }

    final confirmOk = await MaiYenNavigation.showModalSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sharedCount > 0 && ownCount == 0
                      ? Icons.logout_rounded
                      : Icons.warning_amber_rounded,
                  color: sharedCount > 0 && ownCount == 0
                      ? Colors.orange
                      : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  sharedCount > 0 && ownCount == 0
                      ? _strings.t("Xác nhận rời nhà")
                      : _strings.t("Xác nhận xoá nhà"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(_strings.t("Huỷ")),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sharedCount > 0 && ownCount == 0
                              ? Colors.orange
                              : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(_strings.t("Tiếp tục")),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmOk != true) return;
    if (!mounted) return;

    String inputPassword = "";

    final passwordOk = await MaiYenNavigation.showModalSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final passwordOk = inputPassword.trim().isNotEmpty;

            Future<void> submit() async {
              if (!passwordOk) return;

              try {
                final user = FirebaseAuth.instance.currentUser;
                final userEmail = user?.email;

                if (user == null || userEmail == null || userEmail.isEmpty) {
                  if (!sheetContext.mounted) return;

                  showTopToast(
                    sheetContext,
                    _strings.t("Không tìm thấy tài khoản"),
                    color: Colors.red,
                    icon: Icons.error_outline_rounded,
                  );
                  return;
                }

                final credential = EmailAuthProvider.credential(
                  email: userEmail,
                  password: inputPassword.trim(),
                );

                await user.reauthenticateWithCredential(credential);

                if (!sheetContext.mounted) return;

                Navigator.pop(sheetContext, true);
              } catch (e) {
                if (!sheetContext.mounted) return;

                showTopToast(
                  sheetContext,
                  _strings.t("Sai mật khẩu"),
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                );
              }
            }

            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.red,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _strings.t("Nhập mật khẩu"),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          autofocus: true,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: _strings.t("Mật khẩu tài khoản"),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            inputPassword = value.trim();
                            setSheetState(() {});
                          },
                          onFieldSubmitted: (_) => submit(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              sharedCount > 0 && ownCount == 0
                                  ? Icons.logout_rounded
                                  : Icons.delete_forever_rounded,
                            ),
                            label: Text(
                              sharedCount > 0 && ownCount == 0
                                  ? _strings.t("Rời khỏi nhà")
                                  : _strings.t("Xoá nhà"),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sharedCount > 0 && ownCount == 0
                                  ? Colors.orange
                                  : Colors.red,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                            ),
                            onPressed: passwordOk ? submit : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (passwordOk != true) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);

      final isShared = home["_shared"] == true;

      if (isShared) {
        final ownerUid = home["_ownerUid"];

        await FirebaseDatabase.instance
            .ref("accounts/$uid/sharedHomes/$homeId")
            .remove();

        await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId/$uid")
            .remove();

        await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareList/$homeId/$uid")
            .remove();
      } else {
        final sharedSnap = await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId")
            .get();

        final sharedUsers = sharedSnap.value is Map
            ? Map<String, dynamic>.from(sharedSnap.value as Map)
            : <String, dynamic>{};

        final updates = <String, Object?>{
          "accounts/$uid/homes/$homeId": null,
          "accounts/$uid/shareList/$homeId": null,
        };

        for (final memberUid in sharedUsers.keys) {
          updates["accounts/$memberUid/sharedHomes/$homeId"] = null;
          updates["sharedByHome/$homeId/$memberUid"] = null;
        }

        await FirebaseDatabase.instance.ref().update(updates);
      }
    }

    if (!mounted) return;

    setState(() {
      selectedHomes.clear();
    });

    showTopToast(
      context,
      sharedCount > 0 && ownCount == 0
          ? _strings.t("Đã rời khỏi nhà")
          : _strings.t("Đã cập nhật"),
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );
  }
}
