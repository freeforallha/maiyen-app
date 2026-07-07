import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';

Future<String?> showAddHomeOptionsSheet({
  required BuildContext context,
  required AppStrings strings,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      Widget optionTile({
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required String value,
      }) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: SafeHomeColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(sheetContext).pop(value);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SafeHomeColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: SafeHomeColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: SafeHomeColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SafeHomeColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: SafeHomeColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SafeHomeColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.t("Thêm nhà"),
                  style: const TextStyle(
                    color: SafeHomeColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              optionTile(
                icon: Icons.add_home_work_rounded,
                title: strings.t("Tạo nhà mới"),
                subtitle: strings.t("Tạo một ngôi nhà mới của bạn"),
                color: SafeHomeColors.primary,
                value: "create",
              ),
              optionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: strings.t("Xin gia nhập nhà"),
                subtitle: strings.t("Quét mã QR được chủ nhà chia sẻ"),
                color: SafeHomeColors.info,
                value: "join",
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<Map<String, String>?> showCreateHomeDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  String inputName = "";
  String inputAddress = "";

  return showDialog<Map<String, String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final nameOk = inputName.trim().isNotEmpty;

          InputDecoration fieldDecoration(String label) {
            return InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            );
          }

          void submit() {
            if (!nameOk) return;

            Navigator.of(dialogContext).pop({
              "name": inputName.trim(),
              "address": inputAddress.trim(),
            });
          }

          return AlertDialog(
            title: Text(strings.t("Thêm nhà mới")),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: fieldDecoration(strings.t("Tên nhà")),
                  onChanged: (value) {
                    inputName = value.trim();
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: fieldDecoration(strings.t("Địa chỉ")),
                  onChanged: (value) {
                    inputAddress = value.trim();
                  },
                  onFieldSubmitted: (_) => submit(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(strings.t("Hủy")),
              ),
              ElevatedButton(
                onPressed: nameOk ? submit : null,
                child: Text(strings.t("OK")),
              ),
            ],
          );
        },
      );
    },
  );
}
