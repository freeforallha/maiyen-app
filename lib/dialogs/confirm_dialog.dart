import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text("Không"),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text("OK"),
        ),
      ],
    ),
  );

  return result == true;
}
