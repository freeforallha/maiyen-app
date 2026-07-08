import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';

Future<String?> showTransferOwnerEmailSheet({
  required BuildContext context,
  required AppStrings strings,
}) async {
  String inputEmail = "";

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final email = inputEmail.trim().toLowerCase();

                final emailOk = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(email);

                void submit() {
                  if (!emailOk) return;
                  Navigator.pop(sheetContext, email);
                }

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.t("Chuyển quyền chủ nhà"),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: strings.t("Email người nhận"),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: emailOk
                              ? IconButton(
                                  icon: const Icon(Icons.send_rounded),
                                  onPressed: submit,
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          inputEmail = value;
                          setSheetState(() {});
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

Future<bool> showTransferOwnerConfirmSheet({
  required BuildContext context,
  required AppStrings strings,
  required String targetEmail,
}) async {
  final result = await showModalBottomSheet<bool>(
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
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 46,
              ),

              const SizedBox(height: 12),

              Text(
                strings.t("Xác nhận chuyển quyền"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                strings.confirmTransferOwnerText(targetEmail),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: Text(strings.t("Hủy")),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: Text(strings.t("Chuyển")),
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

  return result ?? false;
}

Future<String?> showTransferOwnerPasswordDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  String inputPassword = "";

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final passwordOk = inputPassword.trim().isNotEmpty;

          void submit() {
            if (!passwordOk) return;
            Navigator.pop(dialogContext, inputPassword.trim());
          }

          return AlertDialog(
            title: Text(strings.t("Xác nhận mật khẩu")),
            content: TextFormField(
              autofocus: true,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: strings.t("Mật khẩu tài khoản"),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                inputPassword = value.trim();
                setDialogState(() {});
              },
              onFieldSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.t("Huỷ")),
              ),
              ElevatedButton(
                onPressed: passwordOk ? submit : null,
                child: Text(strings.t("Xác nhận")),
              ),
            ],
          );
        },
      );
    },
  );
}
