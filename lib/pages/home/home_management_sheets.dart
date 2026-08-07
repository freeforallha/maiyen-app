import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../localization/app_strings.dart';
import '../../navigation/maiyen_navigation.dart';
import '../../maiyen_theme.dart';

Future<Map<String, String>?> showRenameHomeSheet({
  required BuildContext context,
  required AppStrings strings,
  required bool usePersonalName,
  required String currentName,
  required String currentAddress,
}) async {
  String inputName = currentName.trim();
  String inputAddress = currentAddress.trim();

  return MaiYenNavigation.showModalSheet<Map<String, String>>(
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
              color: MaiYenColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final nameOk = inputName.trim().isNotEmpty;

                InputDecoration fieldDecoration({
                  required String label,
                  required IconData icon,
                  String? hint,
                }) {
                  return InputDecoration(
                    labelText: label,
                    hintText: hint,
                    prefixIcon: Icon(icon, color: MaiYenColors.primary),
                    filled: true,
                    fillColor: MaiYenColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: MaiYenColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: MaiYenColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: MaiYenColors.primary,
                        width: 1.5,
                      ),
                    ),
                  );
                }

                void submit() {
                  if (!nameOk) return;

                  Navigator.pop(sheetContext, {
                    "name": inputName.trim(),
                    "address": usePersonalName
                        ? currentAddress.trim()
                        : inputAddress.trim(),
                  });
                }

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: MaiYenColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: MaiYenColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: MaiYenColors.primary,
                          size: 31,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        usePersonalName
                            ? strings.t("Đổi tên hiển thị")
                            : strings.t("Cập nhật thông tin nhà"),
                        style: const TextStyle(
                          color: MaiYenColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        initialValue: currentName,
                        autofocus: true,
                        textInputAction: usePersonalName
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onChanged: (value) {
                          inputName = value.trim();
                          setSheetState(() {});
                        },
                        onFieldSubmitted: (_) {
                          if (usePersonalName) {
                            submit();
                          }
                        },
                        decoration: fieldDecoration(
                          label: strings.t("Tên nhà"),
                          icon: Icons.home_outlined,
                        ),
                      ),
                      if (!usePersonalName) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: currentAddress,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          maxLines: 2,
                          minLines: 1,
                          onChanged: (value) {
                            inputAddress = value.trim();
                          },
                          onFieldSubmitted: (_) => submit(),
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
                          onPressed: nameOk ? submit : null,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(
                            strings.t("Lưu thay đổi"),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: MaiYenColors.primary,
                            disabledBackgroundColor: MaiYenColors.border,
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
                          color: MaiYenColors.textSecondary,
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
}

Future<String?> showShareHomeSheet({
  required BuildContext context,
  required AppStrings strings,
  required String qrData,
}) async {
  String inputEmail = "";
  FocusManager.instance.primaryFocus?.unfocus();

  return MaiYenNavigation.pushChildPage<String>(
    context: context,
    routeName: "share_home",
    builder: (pageContext) {
      return StatefulBuilder(
        builder: (context, setPageState) {
          final email = inputEmail.trim().toLowerCase();
          final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

          void submit() {
            if (!emailOk) return;
            Navigator.pop(pageContext, email);
          }

          final bottomInset = MediaQuery.viewInsetsOf(pageContext).bottom;
          final keyboardOpen = bottomInset > 0;
          final qrSize = keyboardOpen ? 130.0 : 180.0;

          return ColoredBox(
            color: MaiYenColors.background,
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.share_rounded,
                          color: MaiYenColors.info,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strings.t("Chia sẻ nhà"),
                          style: const TextStyle(
                            color: MaiYenColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.t("Mời thành viên bằng mã QR"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: qrSize,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            strings.t("Hoặc"),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      autofocus: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {
                        inputEmail = value;
                        setPageState(() {});
                      },
                      onFieldSubmitted: (_) {
                        if (emailOk) submit();
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_rounded),
                        labelText: strings.t("Email người nhận"),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: emailOk ? submit : null,
                        icon: const Icon(Icons.share_rounded),
                        label: Text(strings.t("Chia sẻ")),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void showJoinHomeQrSheet({
  required BuildContext context,
  required AppStrings strings,
  required String qrData,
}) {
  MaiYenNavigation.showModalSheet(
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
