import 'package:flutter/material.dart';

Future<String?> showPairDialog(BuildContext context) async {
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (_) {
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),

          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.isEmpty) return;

              Navigator.pop(context, value);
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