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
                      children: suggestions.take(3).map(suggestionChip).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: suggestions.skip(3).map(suggestionChip).toList(),
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
              ElevatedButton(
                onPressed: submit,
                child: Text(strings.t("OK")),
              ),
            ],
          );
        },
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
                  ko:
                      "Alarm이 나만 설정을 사용 중입니다.\n\n"
                      "이 계정에 설정된 개인 Alarm 일정에 따라 알림을 받습니다.",
                  ja:
                      "Alarm は「自分のみ」モードを使用しています。\n\n"
                      "このアカウントに設定された個人用 Alarm スケジュールに従って通知を受け取ります。",
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
                  ko:
                      "Alarm이 집 기준 설정을 사용 중입니다.\n\n"
                      "집 주인 또는 관리자가 설정한 공용 일정에 따라 알림을 받습니다.",
                  ja:
                      "Alarm は「家の設定」モードを使用しています。\n\n"
                      "所有者または管理者が設定した共有スケジュールに従って通知を受け取ります。",
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
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: SafeHomeColors.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.choose(
                  vi: "Tắt toàn bộ Alarm?",
                  en: "Turn off all Alarm?",
                  zh: "关闭全部 Alarm？",
                  ko: "모든 Alarm을 끄시겠습니까?",
                  ja: "すべての Alarm をオフにしますか？",
                ),
              ),
            ),
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
            zh: "此操作将关闭此家庭的所有 Alarm。你将不再在此手机上收到危险警报。",
            ko:
                "이 작업은 이 집의 모든 Alarm을 끕니다. "
                "이 휴대전화에서 위험 알림을 더 이상 받지 않습니다.",
            ja:
                "この操作により、この家のすべての Alarm がオフになります。"
                "この端末で危険通知を受け取れなくなります。",
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
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.t("Lưu ý tạm tắt Alarm")),
        content: Text(
          strings.choose(
            vi:
                "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị "
                "trong hôm nay...",
            en: "This action will change the alarm timing for some devices today...",
            zh: "此操作将更改今天部分设备的报警时间……",
            ko: "이 작업은 오늘 일부 기기의 Alarm 시간을 변경합니다...",
            ja: "この操作により、本日の一部デバイスの Alarm 時刻が変更されます...",
          ),
        ),
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
            Expanded(
              child: Text(
                strings.choose(
                  vi: "Bật Bảo vệ thủ công?",
                  en: "Turn on manual Guard mode?",
                  zh: "开启手动布防？",
                  ko: "수동 Guard 모드를 켜시겠습니까?",
                  ja: "手動 Guard モードをオンにしますか？",
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.choose(
            vi:
                "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n"
                "Tự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này "
                "không tự tắt khi có người về nhà và chỉ được tắt khi "
                "một thành viên có quyền chủ động chuyển về Bình thường.",
            en:
                "Security devices will be monitored immediately.\n\n"
                "Auto Guard when away will pause. This mode does not turn off "
                "automatically when someone comes home and must be switched "
                "back to Normal by a permitted member.",
            zh:
                "开启后，安全设备会立即开始监测。\n\n"
                "离家自动布防将暂停。有人回家时此模式不会自动关闭，"
                "只能由有权限的成员手动切换回普通模式。",
            ko:
                "켜면 보안 기기가 즉시 모니터링됩니다.\n\n"
                "외출 시 자동 Guard는 일시 중지됩니다. 이 모드는 "
                "누군가 집에 돌아와도 자동으로 꺼지지 않으며, 권한이 있는 "
                "구성원이 직접 Normal로 전환해야 합니다.",
            ja:
                "オンにすると、セキュリティデバイスはすぐに監視されます。\n\n"
                "外出時の自動 Guard は一時停止します。このモードは誰かが帰宅しても"
                "自動ではオフにならず、権限のあるメンバーが手動で Normal に戻す必要があります。",
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
                  vi: "Chuyển về Bình thường?",
                  en: "Switch to Normal?",
                  zh: "切换到普通模式？",
                  ko: "일반 모드로 전환할까요?",
                  ja: "通常モードに切り替えますか？",
                ),
              ),
            ),
          ],
        ),
        content: Text(
          strings.choose(
            vi:
                "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.",
            en:
                "Auto Guard when away is still enabled. If all members are still away, the system may turn Guard mode back on after a few minutes.",
            zh:
                "离家自动布防仍处于开启状态。如果所有成员仍在外出，系统可能会在几分钟后重新开启布防。",
            ko:
                "외출 시 자동 보호가 아직 켜져 있습니다. 모든 구성원이 아직 외출 중이면 몇 분 후 시스템이 보호 모드를 다시 켤 수 있습니다.",
            ja:
                "外出時の自動 Guard がまだ有効です。すべてのメンバーが外出中の場合、"
                "数分後にシステムが Guard モードを再びオンにすることがあります。",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: Text(
              strings.choose(
                vi: "Huỷ",
                en: "Cancel",
                zh: "取消",
                ko: "취소",
                ja: "キャンセル",
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(
              strings.choose(
                vi: "Vẫn chuyển về Bình thường",
                en: "Still switch to Normal",
                zh: "仍然切换到普通模式",
                ko: "그래도 일반 모드로 전환",
                ja: "それでも通常モードに切り替える",
              ),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
