import 'package:flutter/material.dart';

Future<String?> showPairDialog(BuildContext context) async {
  final controller = TextEditingController();

  return await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Nhập HUB ID"),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: "vd: HUB_001"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, controller.text);
          },
          child: Text("Pair"),
        ),
      ],
    ),
  );
}
