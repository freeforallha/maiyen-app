import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

Future<bool> showConfirmDialog(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final strings = AppStrings.of(dialogContext);

      return AlertDialog(
        title: Text(title),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: Text(
              strings.choose(vi: "Không", en: "No", zh: "否", ko: "아니요"),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(strings.t("OK")),
          ),
        ],
      );
    },
  );

  return result == true;
}
