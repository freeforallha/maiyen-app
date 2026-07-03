import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';

Future<String?> showTransferOwnerEmailSheet({
  required BuildContext context,
  required AppStrings strings,
}) async {
  final controller = TextEditingController();

  try {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
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
                const SizedBox(height: 12),

                StatefulBuilder(
                  builder: (context, setEmailState) {
                    final email = controller.text.trim().toLowerCase();

                    final emailOk = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);

                    return TextField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setEmailState(() {}),
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
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    controller.text.trim().toLowerCase(),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<bool> showTransferOwnerConfirmSheet({
  required BuildContext context,
  required AppStrings strings,
  required String targetEmail,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
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
                strings.choose(
                  vi: "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n$targetEmail?",
                  en: "Transfer home ownership to:\n$targetEmail?",
                ),
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
                      onPressed: () => Navigator.pop(context, false),
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
                      onPressed: () => Navigator.pop(context, true),
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
  final passwordController = TextEditingController();

  try {
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.t("Xác nhận mật khẩu")),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: strings.t("Mật khẩu tài khoản"),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, passwordController.text.trim()),
            child: Text(strings.t("Xác nhận")),
          ),
        ],
      ),
    );
  } finally {
    passwordController.dispose();
  }
}
