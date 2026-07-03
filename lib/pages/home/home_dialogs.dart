import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';

Future<String?> showHomeTimeTextInputDialog({
  required BuildContext context,
  required AppStrings strings,
  required String title,
  required String initial,
}) async {
  final parts = initial.split(":");

  final hourController = TextEditingController(text: parts[0]);

  final minuteController = TextEditingController(text: parts[1]);

  const suggestions = [
    ["23", "00"],
    ["00", "00"],
    ["01", "00"],
    ["04", "00"],
    ["05", "00"],
    ["06", "00"],
  ];

  bool isValidTime(String value) {
    final reg = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return reg.hasMatch(value.trim());
  }

  return showDialog<String>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hourController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: strings.t("Giờ"),
                      counterText: "",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    ":",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: minuteController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: strings.t("Phút"),
                      counterText: "",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              children: [
                Row(
                  children: suggestions.take(3).map((s) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ActionChip(
                            label: Center(child: Text("${s[0]}:${s[1]}")),
                            onPressed: () {
                              hourController.text = s[0];
                              minuteController.text = s[1];
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: suggestions.skip(3).map((s) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: ActionChip(
                            label: Center(child: Text("${s[0]}:${s[1]}")),
                            onPressed: () {
                              hourController.text = s[0];
                              minuteController.text = s[1];
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () {
              final h = hourController.text.trim().padLeft(2, '0');
              final m = minuteController.text.trim().padLeft(2, '0');
              final value = "$h:$m";

              if (!isValidTime(value)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.t("Giờ không hợp lệ")),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, value);
            },
            child: Text(strings.t("OK")),
          ),
        ],
      );
    },
  );
}

Future<void> showAlarmReceiveReminderDialog({
  required BuildContext context,
  required AppStrings strings,
  required bool useCustomMode,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              useCustomMode ? Icons.person_rounded : Icons.home_rounded,
              color: SafeHomeColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(strings.t("Alarm đã được bật"))),
          ],
        ),
        content: Text(
          useCustomMode
              ? strings.choose(
                  vi:
                      "Alarm đang sử dụng chế độ Riêng tôi.\n\n"
                      "Bạn sẽ nhận cảnh báo theo lịch Alarm riêng "
                      "đã thiết lập cho tài khoản này.",
                  en:
                      "Alarm is using My settings.\n\n"
                      "You will receive alerts according to the "
                      "personal Alarm schedules for this account.",
                )
              : strings.choose(
                  vi:
                      "Alarm đang sử dụng chế độ Theo nhà.\n\n"
                      "Bạn sẽ nhận cảnh báo theo lịch Alarm chung "
                      "do Chủ nhà hoặc Quản trị viên thiết lập.",
                  en:
                      "Alarm is using Home settings.\n\n"
                      "You will receive alerts according to the "
                      "shared schedules configured by the owner "
                      "or an administrator.",
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(strings.t("Đã hiểu")),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmDisableAlarmDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: SafeHomeColors.danger),
            SizedBox(width: 10),
            Expanded(child: Text("Tắt toàn bộ Alarm?")),
          ],
        ),
        content: Text(
          strings.choose(
            vi:
                "Hành động này sẽ tắt toàn bộ báo động của nhà "
                "dưới mọi hình thức. Bạn sẽ không còn nhận được "
                "cảnh báo khi có nguy hiểm trên điện thoại nữa.",
            en:
                "This action will disable every Alarm for this "
                "home. You will no longer receive danger alerts "
                "on this phone.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(strings.t("Huỷ")),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SafeHomeColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(strings.t("Tắt Alarm")),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

Future<void> showAlarmPauseReminderDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.t("Lưu ý tạm tắt Alarm")),
        content: Text(
          strings.choose(
            vi:
                "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị "
                "trong hôm nay, reminder sẽ được báo đến các thành viên khác "
                "trong nhà. Khoảng thời gian tạm hoãn phải nằm trong khoảng thời gian đã được cài đặt của Alarm.",
            en:
                "This changes today's Alarm time for selected devices and notifies "
                "other home members. The pause period must stay within the configured Alarm schedule.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.t("Đã hiểu")),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmManualSecurityModeDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: SafeHomeColors.warning),
            SizedBox(width: 10),
            Expanded(child: Text("Bật Bảo vệ thủ công?")),
          ],
        ),
        content: const Text(
          "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n"
          "Tự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này "
          "không tự tắt khi có người về nhà và chỉ được tắt khi "
          "một thành viên có quyền chủ động chuyển về Bình thường.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text("Huỷ"),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            icon: const Icon(Icons.shield_rounded),
            label: const Text("Xác nhận"),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
