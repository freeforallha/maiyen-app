import 'package:flutter/material.dart';

import '../../helpers/top_toast.dart';
import '../../localization/app_strings.dart';
import '../../maiyen_theme.dart';
import '../../navigation/maiyen_navigation.dart';


int? _resolveAlarmPauseMenuEndAt(Map<String, dynamic> pause) {
  final directEndAt = int.tryParse(pause['endAt']?.toString() ?? '');
  if (directEndAt != null && directEndAt > 0) return directEndAt;

  final dateParts = (pause['date']?.toString() ?? '').split('-');
  final startParts = (pause['start']?.toString() ?? '').split(':');
  final endParts = (pause['end']?.toString() ?? '').split(':');
  if (dateParts.length != 3 ||
      startParts.length != 2 ||
      endParts.length != 2) {
    return null;
  }

  final values = <int?>[
    ...dateParts.map(int.tryParse),
    ...startParts.map(int.tryParse),
    ...endParts.map(int.tryParse),
  ];
  if (values.any((value) => value == null)) return null;

  final year = values[0]!;
  final month = values[1]!;
  final day = values[2]!;
  final startHour = values[3]!;
  final startMinute = values[4]!;
  final endHour = values[5]!;
  final endMinute = values[6]!;
  if (month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      startHour < 0 ||
      startHour > 23 ||
      startMinute < 0 ||
      startMinute > 59 ||
      endHour < 0 ||
      endHour > 23 ||
      endMinute < 0 ||
      endMinute > 59) {
    return null;
  }

  final startAt = DateTime(year, month, day, startHour, startMinute);
  var endAt = DateTime(year, month, day, endHour, endMinute);
  if (!endAt.isAfter(startAt)) {
    endAt = endAt.add(const Duration(days: 1));
  }
  return endAt.millisecondsSinceEpoch;
}

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
  await MaiYenNavigation.showModalSheet(
    context: context,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final alarmScheduleConfigured =
          alarmScheduleText.trim().isNotEmpty &&
          alarmScheduleText != strings.t('Tắt') &&
          alarmScheduleText != strings.t('Chưa thiết lập thời gian');
      final pauseEndAt = _resolveAlarmPauseMenuEndAt(alarmPauseToday);
      final pauseActive = alarmPauseToday.isNotEmpty &&
          (pauseEndAt == null ||
              pauseEndAt > DateTime.now().millisecondsSinceEpoch);

      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: const BoxDecoration(
            color: MaiYenColors.surface,
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
                  color: MaiYenColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.crisis_alert_rounded,
                  color: alarmScheduleConfigured
                      ? MaiYenColors.primary
                      : MaiYenColors.textSecondary.withValues(alpha: 0.45),
                ),
                title: Text(
                  strings.t('Hẹn giờ báo động'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: MaiYenColors.textPrimary,
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
                        ? MaiYenColors.textSecondary
                        : MaiYenColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: MaiYenColors.textSecondary,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onOpenAlarmSchedule();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.pause_circle_filled_rounded,
                  color: pauseActive
                      ? MaiYenColors.warning
                      : MaiYenColors.textSecondary.withValues(alpha: 0.45),
                ),
                title: Text(
                  strings.t('Tạm tắt báo động hôm nay'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: pauseActive
                        ? MaiYenColors.textPrimary
                        : MaiYenColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                subtitle: Text(
                  !pauseActive
                      ? strings.t('Chưa thiết lập')
                      : '${alarmPauseToday['start'] ?? '--:--'} → ${alarmPauseToday['end'] ?? '--:--'}'
                            '${(alarmPauseToday['reason'] ?? '').toString().isNotEmpty ? ' • ${strings.t(alarmPauseToday['reason'].toString())}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pauseActive
                        ? MaiYenColors.textSecondary
                        : MaiYenColors.textSecondary.withValues(alpha: 0.45),
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
                      color: MaiYenColors.warning,
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
                      ? MaiYenColors.primary
                      : MaiYenColors.textSecondary.withValues(alpha: 0.45),
                ),
                title: Text(
                  strings.t('Hẹn giờ nhắc nhở'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: reminderEnabled
                        ? MaiYenColors.textPrimary
                        : MaiYenColors.textSecondary.withValues(alpha: 0.55),
                  ),
                ),
                subtitle: Text(
                  reminderEnabled
                      ? strings.t('Đã thiết lập')
                      : strings.t('Chưa thiết lập'),
                  style: TextStyle(
                    color: reminderEnabled
                        ? MaiYenColors.textSecondary
                        : MaiYenColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: MaiYenColors.textSecondary,
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
