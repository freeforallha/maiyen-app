import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';

Future<Map<String, String>?> showRenameHomeSheet({
  required BuildContext context,
  required AppStrings strings,
  required bool usePersonalName,
  required String currentName,
  required String currentAddress,
}) async {
  final nameController = TextEditingController(text: currentName);
  final addressController = TextEditingController(text: currentAddress);

  final result = await showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final nameOk = nameController.text.trim().isNotEmpty;

                InputDecoration fieldDecoration({
                  required String label,
                  required IconData icon,
                  String? hint,
                }) {
                  return InputDecoration(
                    labelText: label,
                    hintText: hint,
                    prefixIcon: Icon(icon, color: SafeHomeColors.primary),
                    filled: true,
                    fillColor: SafeHomeColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: SafeHomeColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: SafeHomeColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: SafeHomeColors.primary,
                        width: 1.5,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: SafeHomeColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: SafeHomeColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: SafeHomeColors.primary,
                          size: 31,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        usePersonalName
                            ? strings.t("Đổi tên hiển thị")
                            : strings.t("Cập nhật thông tin nhà"),
                        style: const TextStyle(
                          color: SafeHomeColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: nameController,
                        textInputAction: usePersonalName
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onChanged: (_) {
                          setSheetState(() {});
                        },
                        onSubmitted: (_) {
                          if (!usePersonalName || !nameOk) {
                            return;
                          }

                          Navigator.pop(sheetContext, {
                            "name": nameController.text.trim(),
                            "address": currentAddress,
                          });
                        },
                        decoration: fieldDecoration(
                          label: strings.t("Tên nhà"),
                          icon: Icons.home_outlined,
                        ),
                      ),
                      if (!usePersonalName) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: addressController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          maxLines: 2,
                          minLines: 1,
                          onSubmitted: (_) {
                            if (!nameOk) {
                              return;
                            }

                            Navigator.pop(sheetContext, {
                              "name": nameController.text.trim(),
                              "address": addressController.text.trim(),
                            });
                          },
                          decoration: fieldDecoration(
                            label: strings.t("Địa chỉ"),
                            icon: Icons.location_on_outlined,
                            hint: strings.t("Nhập địa chỉ của nhà"),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: nameOk
                              ? () {
                                  Navigator.pop(sheetContext, {
                                    "name": nameController.text.trim(),
                                    "address": usePersonalName
                                        ? currentAddress
                                        : addressController.text.trim(),
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            strings.t("Lưu thay đổi"),
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: SafeHomeColors.primary,
                            disabledBackgroundColor: SafeHomeColors.border,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        usePersonalName
                            ? strings.t(
                                "Tên này chỉ hiển thị riêng trên tài khoản của bạn.",
                              )
                            : strings.t(
                                "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.",
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
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

  // Bottom sheet vẫn đang chạy animation đóng sau khi
  // Navigator.pop() trả kết quả. Không dispose controller ngay,
  // nếu không TextField có thể đọc controller đã dispose và gây
  // màn hình đỏ.
  Future<void>.delayed(const Duration(milliseconds: 350), () {
    nameController.dispose();
    addressController.dispose();
  });

  return result;
}

Future<String?> showShareHomeSheet({
  required BuildContext context,
  required AppStrings strings,
  required String qrData,
}) async {
  final controller = TextEditingController();

  final targetEmail = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final email = controller.text.trim().toLowerCase();
          final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.t("Chia sẻ nhà"),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setSheetState(() {}),
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
                                Navigator.pop(context, email);
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    strings.t("Mời thành viên bằng mã QR"),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  Future<void>.delayed(const Duration(milliseconds: 350), () {
    controller.dispose();
  });

  return targetEmail;
}

void showJoinHomeQrSheet({
  required BuildContext context,
  required AppStrings strings,
  required String qrData,
}) {
  showModalBottomSheet(
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
              Text(
                strings.t("QR của nhà này"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              QrImageView(data: qrData, version: QrVersions.auto, size: 220),
              const SizedBox(height: 12),
              Text(
                strings.t(
                  "Người khác quét mã này để gửi yêu cầu gia nhập nhà.",
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}
