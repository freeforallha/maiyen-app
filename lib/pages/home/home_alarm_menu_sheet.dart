import 'package:flutter/material.dart';

import '../../helpers/top_toast.dart';
import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';
import '../../navigation/safehome_navigation.dart';

Future<void> showHomeAlarmMenuSheet({
  required BuildContext context,
  required AppStrings strings,
  required bool reminderEnabled,
  required String alarmScheduleText,
  required Map<String, dynamic> alarmPauseToday,
  required VoidCallback onOpenAlarmSchedule,
  required Future<void> Function() onOpenAlarmPause,
  required VoidCallback onOpenReminderSchedule,
}) async {
  await SafeHomeNavigation.showModalSheet(
    context: context,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final alarmScheduleConfigured =
          alarmScheduleText.trim().isNotEmpty &&
          alarmScheduleText != strings.t('Tắt') &&
          alarmScheduleText != strings.t('Chưa thiết lập thời gian');

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
                  color: alarmScheduleConfigured
                      ? SafeHomeColors.primary
                      : SafeHomeColors.textSecondary.withValues(alpha: 0.45),
                ),
                title: Text(
                  strings.t('Hẹn giờ báo động'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SafeHomeColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  alarmScheduleConfigured
                      ? alarmScheduleText
                      : strings.t('Chưa thiết lập thời gian'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: alarmScheduleConfigured
                        ? SafeHomeColors.textSecondary
                        : SafeHomeColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: SafeHomeColors.textSecondary,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onOpenAlarmSchedule();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.pause_circle_filled_rounded,
                  color: alarmPauseToday.isNotEmpty
                      ? SafeHomeColors.warning
                      : SafeHomeColors.textSecondary.withValues(alpha: 0.45),
                ),
                title: Text(
                  strings.t('Tạm tắt báo động hôm nay'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: alarmPauseToday.isNotEmpty
                        ? SafeHomeColors.textPrimary
                        : SafeHomeColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                subtitle: Text(
                  alarmPauseToday.isEmpty
                      ? strings.t('Chưa thiết lập')
                      : '${alarmPauseToday['start'] ?? '--:--'} → ${alarmPauseToday['end'] ?? '--:--'}'
                            '${(alarmPauseToday['reason'] ?? '').toString().isNotEmpty ? ' • ${strings.t(alarmPauseToday['reason'].toString())}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: alarmPauseToday.isNotEmpty
                        ? SafeHomeColors.textSecondary
                        : SafeHomeColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  if (!alarmScheduleConfigured) {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 120),
                    );

                    if (!context.mounted) return;

                    showTopToast(
                      context,
                      strings.choose(
                        vi: 'Chưa cài đặt báo động nào',
                        en: 'No alarm has been set',
                        zh: '尚未设置任何警报',
                        ko: '설정된 경보가 없습니다',
                        ja: '警報は設定されていません',
                        de: 'Es ist kein Alarm eingerichtet',
                        ru: 'Ни одна тревога не настроена',
                        fr: 'Aucune alarme n’est configurée',
                        es: 'No hay ninguna alarma configurada',
                        id: 'Belum ada alarm yang diatur',
                        th: 'ยังไม่ได้ตั้งค่าสัญญาณเตือน',
                        ms: 'Tiada penggera ditetapkan',
                        fil: 'Wala pang nakatakdang alarma',
                        km: 'មិនទាន់បានកំណត់សំឡេងរោទិ៍ទេ',
                        my: 'အချက်ပေးစနစ် မသတ်မှတ်ရသေးပါ',
                        lo: 'ຍັງບໍ່ໄດ້ຕັ້ງຄ່າສັນຍານເຕືອນໄພ',
                        ta: 'எந்த அலாரமும் அமைக்கப்படவில்லை',
                        pt: 'Nenhum alarme foi configurado',
                        tet: 'Alarme ida seidauk tau',
                      ),
                      color: SafeHomeColors.warning,
                      icon: Icons.schedule_rounded,
                    );
                    return;
                  }

                  await onOpenAlarmPause();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.notifications_active_rounded,
                  color: reminderEnabled
                      ? SafeHomeColors.primary
                      : SafeHomeColors.textSecondary.withValues(alpha: 0.45),
                ),
                title: Text(
                  strings.t('Hẹn giờ nhắc nhở'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: reminderEnabled
                        ? SafeHomeColors.textPrimary
                        : SafeHomeColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                subtitle: Text(
                  reminderEnabled
                      ? strings.t('Đã thiết lập')
                      : strings.t('Chưa thiết lập'),
                  style: TextStyle(
                    color: reminderEnabled
                        ? SafeHomeColors.textSecondary
                        : SafeHomeColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: SafeHomeColors.textSecondary,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onOpenReminderSchedule();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
