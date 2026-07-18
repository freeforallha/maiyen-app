import 'package:flutter/material.dart';

import '../../helpers/top_toast.dart';
import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';

Future<String?> showHomeTimeTextInputDialog({
  required BuildContext context,
  required AppStrings strings,
  required String title,
  required String initial,
}) async {
  final parts = initial.split(":");

  String hourText = parts.isNotEmpty ? parts[0].padLeft(2, "0") : "00";
  String minuteText = parts.length > 1 ? parts[1].padLeft(2, "0") : "00";

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
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final h = hourText.trim().padLeft(2, "0");
            final m = minuteText.trim().padLeft(2, "0");
            final value = "$h:$m";

            if (!isValidTime(value)) {
              showTopToast(
                dialogContext,
                strings.t("Giờ không hợp lệ"),
                color: Colors.red,
                icon: Icons.schedule_rounded,
              );
              return;
            }

            Navigator.pop(dialogContext, value);
          }

          Widget suggestionChip(List<String> s) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: ActionChip(
                    label: Center(child: Text("${s[0]}:${s[1]}")),
                    onPressed: () {
                      setDialogState(() {
                        hourText = s[0];
                        minuteText = s[1];
                      });
                    },
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey("hour_$hourText"),
                        initialValue: hourText,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 2,
                        decoration: InputDecoration(
                          labelText: strings.t("Giờ"),
                          counterText: "",
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          hourText = value.trim();
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        ":",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey("minute_$minuteText"),
                        initialValue: minuteText,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 2,
                        decoration: InputDecoration(
                          labelText: strings.t("Phút"),
                          counterText: "",
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          minuteText = value.trim();
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  children: [
                    Row(
                      children: suggestions
                          .take(3)
                          .map(suggestionChip)
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: suggestions
                          .skip(3)
                          .map(suggestionChip)
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.t("Huỷ")),
              ),
              ElevatedButton(onPressed: submit, child: Text(strings.t("OK"))),
            ],
          );
        },
      );
    },
  );
}

Future<void> showAlarmPauseReminderDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.t("Lưu ý tạm tắt báo động")),
        content: Text(strings.alarmPauseReminderText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: SafeHomeColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(strings.t("Bật Bảo vệ thủ công?"))),
          ],
        ),
        content: Text(
          strings.t(
            "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: Text(strings.t("Huỷ")),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            icon: const Icon(Icons.shield_rounded),
            label: Text(strings.t("Xác nhận")),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

Future<bool> showConfirmUnprotectedModeDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: SafeHomeColors.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(strings.t("Bật Không bảo vệ?"))),
          ],
        ),
        content: Text(
          "${strings.t("Toàn bộ báo động của nhà đang tắt; hệ thống chỉ gửi thông báo.")}\n\n${strings.t("Chỉ Chủ nhà có thể bật chế độ này.")}",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: Text(strings.t("Huỷ")),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SafeHomeColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(strings.t("Tôi hiểu, tiếp tục")),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

Future<bool> showConfirmNormalModeWithAutoAwayDialog({
  required BuildContext context,
  required AppStrings strings,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: SafeHomeColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.choose(
                  vi: "Chuyển về chế độ bình thường",
                  en: "Switch to normal mode",
                  zh: "切换到普通模式",
                  ko: "일반 모드로 전환",
                  ja: "通常モードに切り替える",
                  de: "Zum Normalmodus wechseln",
                  ru: "Перейти в обычный режим",
                  fr: "Passer en mode normal",
                  es: "Cambiar al modo normal",
                  id: "Beralih ke Mode Normal",
                  th: "เปลี่ยนเป็นโหมดปกติ",
                  ms: "Tukar kepada Mod Normal",
                  fil: "Lumipat sa Normal na Mode",
                  km: "ប្ដូរទៅរបៀបធម្មតា",
                  my: "ပုံမှန်မုဒ်သို့ ပြောင်းရန်",
                  lo: "ປ່ຽນເປັນໂໝດປົກກະຕິ",
                  ta: "சாதாரண பயன்முறைக்கு மாறவும்",
                  pt: "Mudar para o modo normal",
                  tet: "Muda ba modu normal",
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.t(
            "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.",
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(strings.t("Huỷ")),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(strings.t("Đồng ý")),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
