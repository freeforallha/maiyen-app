import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

Future<String?> showPairDialog(BuildContext context) async {
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final strings = AppStrings.of(dialogContext);

      return AlertDialog(
        title: const Text("Nhập HUB ID"),

        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: "VD: HUB_001",
            border: OutlineInputBorder(),
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t("Huỷ")),
          ),

          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isEmpty) return;

              Navigator.pop(dialogContext, value);
            },
            child: const Text("Pair"),
          ),
        ],
      );
    },
  );

  controller.dispose();

  return result;
}
