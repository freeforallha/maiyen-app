import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

Future<String?> showPairDialog(BuildContext context) {
  String hubId = "";

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final strings = AppStrings.of(dialogContext);

      return AlertDialog(
        title: const Text("Nhập HUB ID"),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: "VD: HUB_001",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            hubId = value.trim();
          },
          onSubmitted: (_) {
            if (hubId.isEmpty) return;
            Navigator.pop(dialogContext, hubId);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () {
              if (hubId.isEmpty) return;
              Navigator.pop(dialogContext, hubId);
            },
            child: const Text("Pair"),
          ),
        ],
      );
    },
  );
}