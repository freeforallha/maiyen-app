import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../navigation/safehome_navigation.dart';

enum HomePairSensorMethod { scanQr, manualHubId }

Future<HomePairSensorMethod?> showHomePairSensorSheet({
  required BuildContext context,
  required AppStrings strings,
}) async {
  return SafeHomeNavigation.showModalSheet<HomePairSensorMethod>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.t("Quét QR"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(strings.t("Quét QR để thêm thiết bị")),
                  onPressed: () {
                    Navigator.pop(sheetContext, HomePairSensorMethod.scanQr);
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.keyboard),
                label: Text(strings.t("Nhập HUB ID thủ công")),
                onPressed: () {
                  Navigator.pop(sheetContext, HomePairSensorMethod.manualHubId);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
