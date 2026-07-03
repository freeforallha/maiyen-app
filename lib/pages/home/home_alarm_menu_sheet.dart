import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';

Future<void> showHomeAlarmMenuSheet({
  required BuildContext context,
  required AppStrings strings,
  required bool alarmEnabled,
  required bool reminderEnabled,
  required String alarmScheduleText,
  required Map<String, dynamic> alarmPauseToday,
  required Future<bool> Function(bool enabled) onAlarmEnabledChanged,
  required VoidCallback onOpenAlarmSchedule,
  required Future<void> Function() onOpenAlarmPause,
  required VoidCallback onOpenReminderSchedule,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) {
      bool localAlarmEnabled = alarmEnabled;

      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: const BoxDecoration(
                color: SafeHomeColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: SafeHomeColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.crisis_alert_rounded,
                      color: localAlarmEnabled
                          ? SafeHomeColors.primary
                          : SafeHomeColors.textSecondary.withValues(
                              alpha: 0.45,
                            ),
                    ),
                    title: Text(
                      strings.t("Hẹn giờ Alarm"),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: localAlarmEnabled
                            ? SafeHomeColors.textPrimary
                            : SafeHomeColors.textSecondary.withValues(
                                alpha: 0.55,
                              ),
                      ),
                    ),
                    subtitle: Text(
                      localAlarmEnabled
                          ? alarmScheduleText
                          : strings.t("Đang tắt"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: localAlarmEnabled
                            ? SafeHomeColors.textSecondary
                            : SafeHomeColors.textSecondary.withValues(
                                alpha: 0.45,
                              ),
                      ),
                    ),
                    trailing: Switch(
                      value: localAlarmEnabled,
                      activeThumbColor: SafeHomeColors.primary,
                      activeTrackColor: SafeHomeColors.primary.withValues(
                        alpha: 0.28,
                      ),
                      onChanged: (value) async {
                        final changed = await onAlarmEnabledChanged(value);

                        if (!context.mounted) {
                          return;
                        }

                        setModalState(() {
                          localAlarmEnabled = changed ? value : alarmEnabled;
                        });
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      onOpenAlarmSchedule();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.pause_circle_filled_rounded,
                      color: alarmPauseToday.isNotEmpty
                          ? SafeHomeColors.warning
                          : SafeHomeColors.textSecondary.withValues(
                              alpha: 0.45,
                            ),
                    ),
                    title: Text(
                      strings.t("Tạm tắt Alarm hôm nay"),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: alarmPauseToday.isNotEmpty
                            ? SafeHomeColors.textPrimary
                            : SafeHomeColors.textSecondary.withValues(
                                alpha: 0.55,
                              ),
                      ),
                    ),
                    subtitle: Text(
                      alarmPauseToday.isEmpty
                          ? strings.t("Chưa thiết lập")
                          : "${alarmPauseToday["start"] ?? "--:--"} → ${alarmPauseToday["end"] ?? "--:--"}"
                                "${(alarmPauseToday["reason"] ?? "").toString().isNotEmpty ? " • ${strings.t(alarmPauseToday["reason"].toString())}" : ""}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: alarmPauseToday.isNotEmpty
                            ? SafeHomeColors.textSecondary
                            : SafeHomeColors.textSecondary.withValues(
                                alpha: 0.45,
                              ),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);

                      await onOpenAlarmPause();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.notifications_active_rounded,
                      color: reminderEnabled
                          ? SafeHomeColors.primary
                          : SafeHomeColors.textSecondary.withValues(
                              alpha: 0.45,
                            ),
                    ),
                    title: Text(
                      strings.t("Hẹn giờ Reminder"),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: reminderEnabled
                            ? SafeHomeColors.textPrimary
                            : SafeHomeColors.textSecondary.withValues(
                                alpha: 0.55,
                              ),
                      ),
                    ),
                    subtitle: Text(
                      reminderEnabled
                          ? strings.t("Đã thiết lập")
                          : strings.t("Chưa thiết lập"),
                      style: TextStyle(
                        color: reminderEnabled
                            ? SafeHomeColors.textSecondary
                            : SafeHomeColors.textSecondary.withValues(
                                alpha: 0.45,
                              ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      onOpenReminderSchedule();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
