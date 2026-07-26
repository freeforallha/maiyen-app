import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../maiyen_theme.dart';
import 'device_alarm_policy_sheet.dart';
import '../navigation/maiyen_navigation.dart';

IconData _alarmDeviceIcon(Object? rawType) {
  final type = rawType?.toString().trim().toLowerCase() ?? "unknown";

  switch (type) {
    case "door":
      return Icons.sensor_door_rounded;
    case "window":
      return Icons.window_rounded;
    case "gate":
      return Icons.garage_rounded;
    case "lock":
    case "door_lock":
      return Icons.lock_rounded;
    case "motion":
      return Icons.directions_walk_rounded;
    case "presence":
      return Icons.sensors_rounded;
    case "vibration":
      return Icons.vibration_rounded;
    case "glass_break":
      return Icons.broken_image_rounded;
    case "smoke":
      return Icons.local_fire_department_rounded;
    case "heat":
      return Icons.thermostat_rounded;
    case "carbon_monoxide":
      return Icons.dangerous_rounded;
    case "gas":
      return Icons.gas_meter_rounded;
    case "water_leak":
    case "flood":
      return Icons.water_damage_rounded;
    case "sos":
      return Icons.sos_rounded;
    default:
      return Icons.sensors_rounded;
  }
}

int _normalizeAlarmRepeatMinutes(Object? rawValue) {
  final value = rawValue is num
      ? rawValue.toInt()
      : int.tryParse(rawValue?.toString() ?? "");

  if (value == null) {
    return 30;
  }

  return const [0, 15, 30, 60].contains(value) ? value : 30;
}

List<int> _normalizeAlarmDays(Object? rawValue) {
  final parsed = <int>[];

  if (rawValue is Iterable) {
    for (final item in rawValue) {
      final day = item is num
          ? item.toInt()
          : int.tryParse(item?.toString() ?? "");

      if (day != null && day >= 1 && day <= 7 && !parsed.contains(day)) {
        parsed.add(day);
      }
    }
  }

  parsed.sort();

  return parsed.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : parsed;
}

bool _hasSameAlarmScheduleTime(
  Map<String, dynamic> first,
  Map<String, dynamic> second,
) {
  return first['start']?.toString() == second['start']?.toString() &&
      first['end']?.toString() == second['end']?.toString();
}

String _upsertAlarmScheduleByTime(
  Map<String, Map<String, dynamic>> schedules,
  Map<String, dynamic> schedule,
  String fallbackId,
) {
  final duplicateIds = schedules.entries
      .where((entry) => _hasSameAlarmScheduleTime(entry.value, schedule))
      .map((entry) => entry.key)
      .toList(growable: false);
  final targetId = duplicateIds.isEmpty ? fallbackId : duplicateIds.first;

  for (final duplicateId in duplicateIds.skip(1)) {
    schedules.remove(duplicateId);
  }

  schedules[targetId] = Map<String, dynamic>.from(schedule);
  return targetId;
}

String _alarmWeekdayFullLabel(int day, AppStrings strings) {
  switch (day) {
    case 1:
      return strings.choose(
        vi: "Thứ 2",
        my: "တနင်္လာနေ့",
        fil: "Lunes",
        km: "ថ្ងៃចន្ទ",
        en: "Monday",
        zh: "星期一",
        ko: "월요일",
        ja: "月曜日",
        de: "Montag",
        ru: "Понедельник",
        fr: "Lundi",
        es: "Lunes",
        id: "Senin",
        th: "วันจันทร์",
        ms: "Isnin",
        lo: "ວັນຈັນ",
        ta: "திங்கட்கிழமை",
        pt: "segunda-feira",
        tet: "Segunda-feira",
      );
    case 2:
      return strings.choose(
        vi: "Thứ 3",
        my: "အင်္ဂါနေ့",
        fil: "Martes",
        km: "ថ្ងៃអង្គារ",
        en: "Tuesday",
        zh: "星期二",
        ko: "화요일",
        ja: "火曜日",
        de: "Dienstag",
        ru: "Вторник",
        fr: "Mardi",
        es: "Martes",
        id: "Selasa",
        th: "วันอังคาร",
        ms: "Selasa",
        lo: "ວັນອັງຄານ",
        ta: "செவ்வாய்க்கிழமை",
        pt: "terça-feira",
        tet: "Tersa-feira",
      );
    case 3:
      return strings.choose(
        vi: "Thứ 4",
        my: "ဗုဒ္ဓဟူးနေ့",
        fil: "Miyerkules",
        km: "ថ្ងៃពុធ",
        en: "Wednesday",
        zh: "星期三",
        ko: "수요일",
        ja: "水曜日",
        de: "Mittwoch",
        ru: "Среда",
        fr: "Mercredi",
        es: "Miércoles",
        id: "Rabu",
        th: "วันพุธ",
        ms: "Rabu",
        lo: "ວັນພຸດ",
        ta: "புதன்கிழமை",
        pt: "quarta-feira",
        tet: "Kuarta-feira",
      );
    case 4:
      return strings.choose(
        vi: "Thứ 5",
        my: "ကြာသပတေးနေ့",
        fil: "Huwebes",
        km: "ថ្ងៃព្រហស្បតិ៍",
        en: "Thursday",
        zh: "星期四",
        ko: "목요일",
        ja: "木曜日",
        de: "Donnerstag",
        ru: "Четверг",
        fr: "Jeudi",
        es: "Jueves",
        id: "Kamis",
        th: "วันพฤหัสบดี",
        ms: "Khamis",
        lo: "ວັນພະຫັດ",
        ta: "வியாழக்கிழமை",
        pt: "quinta-feira",
        tet: "Kinta-feira",
      );
    case 5:
      return strings.choose(
        vi: "Thứ 6",
        my: "သောကြာနေ့",
        fil: "Biyernes",
        km: "ថ្ងៃសុក្រ",
        en: "Friday",
        zh: "星期五",
        ko: "금요일",
        ja: "金曜日",
        de: "Freitag",
        ru: "Пятница",
        fr: "Vendredi",
        es: "Viernes",
        id: "Jumat",
        th: "วันศุกร์",
        ms: "Jumaat",
        lo: "ວັນສຸກ",
        ta: "வெள்ளிக்கிழமை",
        pt: "sexta-feira",
        tet: "Sesta-feira",
      );
    case 6:
      return strings.choose(
        vi: "Thứ 7",
        my: "စနေနေ့",
        fil: "Sabado",
        km: "ថ្ងៃសៅរ៍",
        en: "Saturday",
        zh: "星期六",
        ko: "토요일",
        ja: "土曜日",
        de: "Samstag",
        ru: "Суббота",
        fr: "Samedi",
        es: "Sábado",
        id: "Sabtu",
        th: "วันเสาร์",
        ms: "Sabtu",
        lo: "ວັນເສົາ",
        ta: "சனிக்கிழமை",
        pt: "sábado",
        tet: "Sábadu",
      );
    case 7:
      return strings.choose(
        vi: "Chủ nhật",
        my: "တနင်္ဂနွေနေ့",
        fil: "Linggo",
        km: "ថ្ងៃអាទិត្យ",
        en: "Sunday",
        zh: "星期日",
        ko: "일요일",
        ja: "日曜日",
        de: "Sonntag",
        ru: "Воскресенье",
        fr: "Dimanche",
        es: "Domingo",
        id: "Minggu",
        th: "วันอาทิตย์",
        ms: "Ahad",
        lo: "ວັນອາທິດ",
        ta: "ஞாயிற்றுக்கிழமை",
        pt: "domingo",
        tet: "Domingu",
      );
    default:
      return "";
  }
}

class AlarmDeviceSheet extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final Map<String, dynamic> devices;
  final bool canManageHome;

  const AlarmDeviceSheet({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.devices,
    required this.canManageHome,
  });

  @override
  State<AlarmDeviceSheet> createState() => _AlarmDeviceSheetState();
}

class _AlarmDeviceSheetState extends State<AlarmDeviceSheet> {
  Map<String, dynamic> devices = {};
  Map<String, dynamic> customDevices = {};
  String legacyAlarmMode = 'home';
  bool loading = true;
  bool applyingAll = false;

  String get currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.ownerUid;

  @override
  void initState() {
    super.initState();
    devices = Map<String, dynamic>.from(widget.devices);
    _reload();
  }

  Future<void> _reload() async {
    try {
      final results = await Future.wait<DataSnapshot>([
        FirebaseDatabase.instance
            .ref('accounts/${widget.ownerUid}/homes/${widget.homeId}/devices')
            .get(),
        FirebaseDatabase.instance
            .ref('accounts/$currentUid/customRules/${widget.homeId}')
            .get(),
      ]);

      if (!mounted) return;

      final rawDevices = results[0].value;
      final rawCustomHome = results[1].value;
      final customHome = rawCustomHome is Map
          ? Map<String, dynamic>.from(rawCustomHome)
          : const <String, dynamic>{};
      final rawCustomDevices = customHome['devices'];
      setState(() {
        if (rawDevices is Map) {
          devices = Map<String, dynamic>.from(rawDevices);
        }
        customDevices = rawCustomDevices is Map
            ? Map<String, dynamic>.from(rawCustomDevices)
            : {};
        legacyAlarmMode =
            (customHome['alarmMode'] ?? customHome['mode'] ?? 'home')
                .toString();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List<MapEntry<String, dynamic>> get securityDevices {
    return devices.entries.where((entry) {
      final value = entry.value;
      if (value is! Map) return false;
      return isSecurityDeviceType(value['type']);
    }).toList();
  }

  String _realDeviceId(String key, Map<String, dynamic> device) {
    final value = device['_deviceId']?.toString().trim() ?? '';
    return value.isEmpty ? key : value;
  }

  Map<String, Map<String, dynamic>> _commonSchedules(
    String key,
    Map<String, dynamic> device,
  ) {
    final policy = DeviceAlarmPolicySettings.fromDevice(
      device: device,
      deviceType: device['type']?.toString() ?? 'door',
    );
    return normalizeDeviceAlarmSchedules(
      rawSchedules: device['alarmSchedules'],
      legacyAlarm: device['alarm'],
      personal: false,
      legacyFullscreenEnabled: policy.fullscreenEnabled,
      legacyPhysicalSirenEnabled: policy.physicalSirenEnabled,
    );
  }

  Map<String, Map<String, dynamic>> _storedPersonalSchedules(
    String key,
    Map<String, dynamic> device,
  ) {
    final realId = _realDeviceId(key, device);
    final raw = customDevices[realId] ?? customDevices[key];
    final customDevice = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final policy = DeviceAlarmPolicySettings.fromDevice(
      device: device,
      deviceType: device['type']?.toString() ?? 'door',
    );
    return normalizeEffectivePersonalAlarmSchedules(
      customDevice: customDevice,
      legacyAlarmMode: legacyAlarmMode,
      legacyFullscreenEnabled: policy.fullscreenEnabled,
    );
  }

  DevicePersonalAlarmPreferences _personalPreferences(
    String key,
    Map<String, dynamic> device,
  ) {
    final realId = _realDeviceId(key, device);
    final raw = customDevices[realId] ?? customDevices[key];
    final customDevice = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final policy = DeviceAlarmPolicySettings.fromDevice(
      device: device,
      deviceType: device['type']?.toString() ?? 'door',
    );

    return DevicePersonalAlarmPreferences.fromCustomDevice(
      customDevice: customDevice,
      legacyFullscreenEnabled: policy.fullscreenEnabled,
    );
  }

  Map<String, Map<String, dynamic>> _effectivePersonalSchedules(
    String key,
    Map<String, dynamic> device,
  ) {
    final preferences = _personalPreferences(key, device);
    if (preferences.followHomeSchedule) {
      return cloneDeviceAlarmSchedules(_commonSchedules(key, device));
    }
    return _storedPersonalSchedules(key, device);
  }

  String _scheduleSummary(
    Map<String, Map<String, dynamic>> schedules,
    AppStrings strings,
  ) {
    final enabled = schedules.values
        .where((schedule) => schedule['enabled'] == true)
        .toList(growable: false);
    if (enabled.isEmpty) return strings.t('Chưa cài đặt');
    final first = enabled.first;
    final suffix = enabled.length > 1 ? ' (+${enabled.length - 1})' : '';
    return '${first['start']} → ${first['end']}$suffix';
  }

  Future<void> _openDeviceSettings(
    String key,
    Map<String, dynamic> device,
  ) async {
    final realId = _realDeviceId(key, device);
    await showDeviceAlarmPolicySheet(
      context: context,
      ownerUid: widget.ownerUid,
      homeId: widget.homeId,
      deviceId: realId,
      deviceName: device['name']?.toString().trim().isNotEmpty == true
          ? device['name'].toString().trim()
          : key,
      deviceType: device['type']?.toString() ?? 'door',
      device: device,
      canEdit: widget.canManageHome,
    );
    await _reload();
  }

  Future<void> _showQuickSetup({required bool personal}) async {
    final strings = AppStrings.of(context);

    if (!personal && !widget.canManageHome) {
      showTopToast(
        context,
        strings.t('Bạn không có quyền sửa lịch báo động của nhà'),
        color: MaiYenColors.danger,
        icon: Icons.lock_rounded,
      );
      return;
    }

    final entries = securityDevices;
    if (entries.isEmpty) {
      showTopToast(
        context,
        strings.t('Nhà chưa có thiết bị an ninh để áp dụng'),
        color: MaiYenColors.warning,
        icon: Icons.sensors_off_rounded,
      );
      return;
    }

    final draft = defaultDeviceAlarmSchedule(personal: personal);
    var commonParticipates = entries.every((entry) {
      final device = Map<String, dynamic>.from(entry.value as Map);
      return DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: device['type']?.toString() ?? 'door',
      ).enabled;
    });
    var commonNotificationEnabled = entries.every((entry) {
      final device = Map<String, dynamic>.from(entry.value as Map);
      return DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: device['type']?.toString() ?? 'door',
      ).notificationEnabled;
    });
    var commonPhysicalSirenEnabled = entries.every((entry) {
      final device = Map<String, dynamic>.from(entry.value as Map);
      return DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: device['type']?.toString() ?? 'door',
      ).physicalSirenEnabled;
    });
    var personalFollowsHomeAlarm = entries.every((entry) {
      final device = Map<String, dynamic>.from(entry.value as Map);
      return _personalPreferences(entry.key, device).followHomeSchedule;
    });
    var personalNotificationEnabled = entries.every((entry) {
      final device = Map<String, dynamic>.from(entry.value as Map);
      final preferences = _personalPreferences(entry.key, device);
      final policy = DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: device['type']?.toString() ?? 'door',
      );
      return preferences.followHomeSchedule
          ? policy.notificationEnabled
          : preferences.notificationEnabled;
    });
    var personalFullscreenEnabled = entries.every((entry) {
      final device = Map<String, dynamic>.from(entry.value as Map);
      return _personalPreferences(entry.key, device).fullscreenEnabled;
    });
    var saving = false;

    await MaiYenNavigation.showModalSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> chooseTime(String field) async {
              final raw =
                  draft[field]?.toString() ??
                  (field == 'start' ? '23:00' : '06:00').toString();
              final parts = raw.split(':');
              final selected = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.tryParse(parts.first) ?? 23,
                  minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                ),
              );
              if (selected == null) return;
              final value =
                  '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
              final otherField = field == 'start' ? 'end' : 'start';

              if (value == draft[otherField]?.toString()) {
                showTopToast(
                  context,
                  strings.t(
                    'Giờ bắt đầu và kết thúc không được trùng nhau',
                  ),
                  color: MaiYenColors.warning,
                  icon: Icons.schedule_rounded,
                );
                return;
              }

              setSheetState(() => draft[field] = value);
            }

            Future<void> apply() async {
              if (saving) return;

              if ((!personal || !personalFollowsHomeAlarm) &&
                  draft['enabled'] == true &&
                  draft['start']?.toString() == draft['end']?.toString()) {
                showTopToast(
                  context,
                  strings.t('Giờ bắt đầu và kết thúc không được trùng nhau'),
                  color: MaiYenColors.warning,
                  icon: Icons.schedule_rounded,
                );
                return;
              }

              setSheetState(() => saving = true);

              try {
                final updates = <String, Object?>{};
                final normalized = normalizeDeviceAlarmSchedule(
                  draft,
                  personal: personal,
                );
                final scheduleId =
                    'quick_${DateTime.now().microsecondsSinceEpoch}';

                for (final entry in entries) {
                  final key = entry.key;
                  final device = Map<String, dynamic>.from(entry.value as Map);
                  final realId = _realDeviceId(key, device);

                  if (personal) {
                    final basePath =
                        'accounts/$currentUid/customRules/${widget.homeId}/devices/$realId';
                    final policy = DeviceAlarmPolicySettings.fromDevice(
                      device: device,
                      deviceType: device['type']?.toString() ?? 'door',
                    );
                    final previousPreferences =
                        _personalPreferences(key, device);

                    if (personalFollowsHomeAlarm) {
                      // Không lưu bản sao lịch chung ở customRules. Backend và UI
                      // luôn lấy trực tiếp lịch mới nhất của nhà.
                      updates['$basePath/alarmSchedules'] = null;
                    } else {
                      final existing = previousPreferences.followHomeSchedule
                          ? <String, Map<String, dynamic>>{}
                          : _storedPersonalSchedules(key, device);
                      _upsertAlarmScheduleByTime(
                        existing,
                        normalized,
                        scheduleId,
                      );
                      updates['$basePath/alarmSchedules'] = {
                        for (final schedule in existing.entries)
                          schedule.key: deviceAlarmScheduleToFirebaseMap(
                            schedule.value,
                            personal: true,
                          ),
                      };
                    }

                    updates['$basePath/alarm'] = null;
                    updates['$basePath/alarmPreferences'] =
                        DevicePersonalAlarmPreferences(
                          notificationEnabled: personalFollowsHomeAlarm
                              ? policy.notificationEnabled
                              : personalNotificationEnabled,
                          fullscreenEnabled: personalFullscreenEnabled,
                          followHomeSchedule: personalFollowsHomeAlarm,
                        ).toFirebaseMap();
                    continue;
                  }

                  final existing = _commonSchedules(key, device);
                  _upsertAlarmScheduleByTime(
                    existing,
                    normalized,
                    scheduleId,
                  );
                  final basePath =
                      'accounts/${widget.ownerUid}/homes/${widget.homeId}/devices/$realId';
                  updates['$basePath/alarmSchedules'] = {
                    for (final schedule in existing.entries)
                      schedule.key: deviceAlarmScheduleToFirebaseMap(
                        schedule.value,
                        personal: false,
                      ),
                  };
                  updates['$basePath/alarm'] = null;

                  final policy = DeviceAlarmPolicySettings.fromDevice(
                    device: device,
                    deviceType: device['type']?.toString() ?? 'door',
                  );
                  updates['$basePath/alarmPolicy'] =
                      DeviceAlarmPolicySettings(
                        enabled: commonParticipates,
                        notificationEnabled: commonNotificationEnabled,
                        physicalSirenEnabled: commonPhysicalSirenEnabled,
                        // Fullscreen là lựa chọn cá nhân, giữ nguyên dữ liệu cũ.
                        fullscreenEnabled: policy.fullscreenEnabled,
                      ).toFirebaseMap();
                }

                await FirebaseDatabase.instance.ref().update(updates);
                if (!context.mounted) return;
                Navigator.of(context).pop();

                if (!mounted) return;

                showTopToast(
                  this.context,
                  strings.t('Đã áp dụng lịch báo động'),
                  color: MaiYenColors.safe,
                  icon: Icons.check_circle_rounded,
                );
                await _reload();
              } catch (_) {
                if (!context.mounted) return;
                setSheetState(() => saving = false);
                showTopToast(
                  context,
                  strings.t('Không thể lưu lịch báo động'),
                  color: MaiYenColors.danger,
                  icon: Icons.error_rounded,
                );
              }
            }

            Widget quickOptionSwitch({
              required IconData icon,
              required String title,
              required bool value,
              required ValueChanged<bool> onChanged,
              bool enabled = true,
            }) {
              return SwitchListTile.adaptive(
                value: value,
                onChanged: saving || !enabled ? null : onChanged,
                secondary: Icon(
                  icon,
                  color: value
                      ? MaiYenColors.primary
                      : MaiYenColors.textSecondary,
                ),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MaiYenColors.textPrimary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: MaiYenColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: MaiYenColors.border,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        personal
                            ? strings.t('Thiết lập nhanh lịch cá nhân')
                            : strings.t('Thiết lập nhanh lịch chung'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: MaiYenColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        personal
                            ? personalFollowsHomeAlarm
                                  ? strings.followHomeAlarmSyncNote
                                  : strings.t(
                                      'Lịch này chỉ áp dụng cho bạn và không bật còi vật lý.',
                                    )
                            : strings.t(
                                'Lịch này áp dụng cho toàn bộ thành viên trong nhà.',
                              ),
                        style: const TextStyle(
                          color: MaiYenColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: MaiYenColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: MaiYenColors.border),
                        ),
                        child: Column(
                          children: personal
                              ? [
                                  quickOptionSwitch(
                                    icon: Icons.home_work_outlined,
                                    title: strings.joinHomeSharedAlarm,
                                    value: personalFollowsHomeAlarm,
                                    onChanged: (value) => setSheetState(() {
                                      personalFollowsHomeAlarm = value;
                                      if (value) {
                                        personalNotificationEnabled =
                                            commonNotificationEnabled;
                                      }
                                    }),
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                  quickOptionSwitch(
                                    icon: Icons.notifications_active_outlined,
                                    title: strings.t('Thông báo báo động'),
                                    value: personalFollowsHomeAlarm
                                        ? commonNotificationEnabled
                                        : personalNotificationEnabled,
                                    enabled: !personalFollowsHomeAlarm,
                                    onChanged: (value) => setSheetState(
                                      () => personalNotificationEnabled = value,
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                  quickOptionSwitch(
                                    icon: Theme.of(context).platform ==
                                            TargetPlatform.iOS
                                        ? Icons.phone_iphone_rounded
                                        : Icons.phone_android_rounded,
                                    title: Theme.of(context).platform ==
                                            TargetPlatform.iOS
                                        ? strings.t('Cảnh báo trên iOS')
                                        : strings.t('Đánh thức màn hình'),
                                    value: personalFullscreenEnabled,
                                    onChanged: (value) => setSheetState(
                                      () => personalFullscreenEnabled = value,
                                    ),
                                  ),
                                ]
                              : [
                                  quickOptionSwitch(
                                    icon: Icons.shield_rounded,
                                    title: strings.t(
                                      'Tham gia hệ thống báo động',
                                    ),
                                    value: commonParticipates,
                                    onChanged: (value) => setSheetState(
                                      () => commonParticipates = value,
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                  quickOptionSwitch(
                                    icon: Icons.notifications_active_outlined,
                                    title: strings.t('Thông báo báo động'),
                                    value: commonNotificationEnabled,
                                    onChanged: (value) => setSheetState(
                                      () => commonNotificationEnabled = value,
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                  quickOptionSwitch(
                                    icon: Icons.campaign_rounded,
                                    title: strings.t('Bật còi vật lý'),
                                    value: commonPhysicalSirenEnabled,
                                    onChanged: (value) => setSheetState(
                                      () => commonPhysicalSirenEnabled = value,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (personal && personalFollowsHomeAlarm)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: MaiYenColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: MaiYenColors.primary.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lock_clock_rounded,
                                size: 20,
                                color: MaiYenColors.primary,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  strings.followHomeAlarmSyncNote,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: MaiYenColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        SwitchListTile.adaptive(
                          value: draft['enabled'] == true,
                          onChanged: saving
                              ? null
                              : (value) => setSheetState(
                                    () => draft['enabled'] = value,
                                  ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            personal
                                ? strings.t('Lịch báo động cá nhân')
                                : strings.t('Lịch báo động chung'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _AlarmMiniButton(
                                label: strings.t('Bắt đầu'),
                                value: draft['start']?.toString() ?? '23:00',
                                enabled: !saving,
                                onTap: () => chooseTime('start'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _AlarmMiniButton(
                                label: strings.t('Kết thúc'),
                                value: draft['end']?.toString() ?? '06:00',
                                enabled: !saving,
                                onTap: () => chooseTime('end'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AlarmRepeatDropdown(
                          value: _normalizeAlarmRepeatMinutes(
                            draft['repeatMinutes'],
                          ),
                          enabled: !saving,
                          onChanged: (value) => setSheetState(
                            () => draft['repeatMinutes'] = value,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AlarmWeekdaySelector(
                          days: _normalizeAlarmDays(draft['days']),
                          enabled: !saving,
                          onChanged: (days) => setSheetState(
                            () => draft['days'] = days,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving ? null : apply,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.done_all_rounded),
                          label: Text(
                            saving
                                ? strings.t('Đang áp dụng...')
                                : strings.t('Xác nhận'),
                          ),
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

  Future<void> _deleteAllSchedules() async {
    if (applyingAll) return;

    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteAllAlarmSchedules),
        content: Text(strings.deleteAllAlarmSchedulesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('Không')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: MaiYenColors.danger,
            ),
            child: Text(strings.t('Xóa')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => applyingAll = true);

    try {
      final updates = <String, Object?>{};

      for (final entry in securityDevices) {
        final key = entry.key;
        final device = Map<String, dynamic>.from(entry.value as Map);
        final realId = _realDeviceId(key, device);

        if (widget.canManageHome) {
          final commonPath =
              'accounts/${widget.ownerUid}/homes/${widget.homeId}/devices/$realId';
          updates['$commonPath/alarmSchedules'] = null;
          updates['$commonPath/alarm'] = null;
        }

        final personalPath =
            'accounts/$currentUid/customRules/${widget.homeId}/devices/$realId';
        updates['$personalPath/alarmSchedules'] = null;
        updates['$personalPath/alarm'] = null;
      }

      if (updates.isNotEmpty) {
        await FirebaseDatabase.instance.ref().update(updates);
      }

      if (!mounted) return;
      showTopToast(
        context,
        strings.allAlarmSchedulesDeleted,
        color: MaiYenColors.safe,
        icon: Icons.delete_sweep_rounded,
      );
      await _reload();
    } catch (_) {
      if (!mounted) return;
      showTopToast(
        context,
        strings.t('Không thể lưu lịch báo động'),
        color: MaiYenColors.danger,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => applyingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final entries = securityDevices;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: MaiYenColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: MaiYenColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              strings.t('Báo động thiết bị'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: MaiYenColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.followHomeAlarmSyncNote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: MaiYenColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: applyingAll
                        ? null
                        : () => _showQuickSetup(personal: false),
                    icon: const Icon(Icons.home_rounded, size: 19),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(strings.t('Cài nhanh chung')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: applyingAll
                        ? null
                        : () => _showQuickSetup(personal: true),
                    icon: const Icon(Icons.person_rounded, size: 19),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(strings.t('Cài nhanh cá nhân')),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.canManageHome) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: applyingAll ? null : _deleteAllSchedules,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                  label: Text(
                    strings.deleteAllAlarmSchedules,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: MaiYenColors.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Flexible(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : entries.isEmpty
                  ? Center(
                      child: Text(
                        strings.t('Nhà chưa có thiết bị an ninh'),
                        style: const TextStyle(
                          color: MaiYenColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (_, index) {
                        final key = entries[index].key;
                        final device = Map<String, dynamic>.from(
                          entries[index].value as Map,
                        );
                        final policy = DeviceAlarmPolicySettings.fromDevice(
                          device: device,
                          deviceType: device['type']?.toString() ?? 'door',
                        );
                        final common = _commonSchedules(key, device);
                        final personal = _effectivePersonalSchedules(key, device);
                        final commonEnabled = hasEnabledDeviceAlarmSchedules(common);
                        final personalEnabled = hasEnabledDeviceAlarmSchedules(personal);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: MaiYenColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: MaiYenColors.border),
                          ),
                          child: InkWell(
                            onTap: () => _openDeviceSettings(key, device),
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.all(13),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: MaiYenColors.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      _alarmDeviceIcon(device['type']),
                                      size: 22,
                                      color: MaiYenColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                device['name']?.toString() ??
                                                    key,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: MaiYenColors
                                                      .textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              policy.enabled
                                                  ? Icons.shield_rounded
                                                  : Icons.shield_outlined,
                                              size: 17,
                                              color: policy.enabled
                                                  ? MaiYenColors.safe
                                                  : MaiYenColors
                                                        .textSecondary,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        _scopeSummaryLine(
                                          icon: Icons.home_rounded,
                                          label: strings.t('Chung cho nhà'),
                                          value: _scheduleSummary(common, strings),
                                          active: commonEnabled,
                                        ),
                                        const SizedBox(height: 3),
                                        _scopeSummaryLine(
                                          icon: Icons.person_rounded,
                                          label: strings.t('Cá nhân'),
                                          value: _scheduleSummary(personal, strings),
                                          active: personalEnabled,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: MaiYenColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scopeSummaryLine({
    required IconData icon,
    required String label,
    required String value,
    required bool active,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: active ? MaiYenColors.primary : MaiYenColors.textSecondary,
        ),
        const SizedBox(width: 5),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: MaiYenColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active
                  ? MaiYenColors.textPrimary
                  : MaiYenColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlarmWeekdaySelector extends StatelessWidget {
  final List<int> days;
  final bool enabled;
  final ValueChanged<List<int>> onChanged;

  const _AlarmWeekdaySelector({
    required this.days,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final selectedDays = _normalizeAlarmDays(days);

    final dayItems = [
      for (var day = 1; day <= 7; day++)
        (value: day, label: _alarmWeekdayFullLabel(day, strings)),
    ];

    void toggleDay(int day) {
      if (!enabled) {
        return;
      }

      final nextDays = List<int>.from(selectedDays);

      if (nextDays.contains(day)) {
        if (nextDays.length == 1) {
          return;
        }

        nextDays.remove(day);
      } else {
        nextDays.add(day);
      }

      nextDays.sort();
      onChanged(nextDays);
    }

    Widget dayButton(int index) {
      final item = dayItems[index];

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _AlarmDayChip(
            label: item.label,
            selected: selectedDays.contains(item.value),
            enabled: enabled,
            onTap: () => toggleDay(item.value),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
      decoration: BoxDecoration(
        color: MaiYenColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaiYenColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(
              strings.t("Ngày trong tuần"),
              style: const TextStyle(
                color: MaiYenColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [dayButton(0), dayButton(1), dayButton(2), dayButton(3)],
          ),
          const SizedBox(height: 8),
          Row(children: [dayButton(4), dayButton(5), dayButton(6)]),
        ],
      ),
    );
  }
}

class _AlarmDayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AlarmDayChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = MaiYenColors.primary;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: enabled ? 0.13 : 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: enabled ? 0.65 : 0.28)
                : MaiYenColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected
                    ? activeColor.withValues(alpha: enabled ? 1 : 0.45)
                    : MaiYenColors.textSecondary.withValues(
                        alpha: enabled ? 1 : 0.45,
                      ),
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlarmRepeatDropdown extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _AlarmRepeatDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final normalizedValue = _normalizeAlarmRepeatMinutes(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: MaiYenColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaiYenColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.t("Thời gian lặp lại"),
              style: const TextStyle(
                color: MaiYenColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: normalizedValue,
                isExpanded: true,
                alignment: Alignment.centerRight,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: MaiYenColors.textSecondary,
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text(strings.t("Không lặp lại")),
                  ),
                  DropdownMenuItem(
                    value: 15,
                    child: Text(strings.t("15 phút")),
                  ),
                  DropdownMenuItem(
                    value: 30,
                    child: Text(strings.t("30 phút")),
                  ),
                  DropdownMenuItem(
                    value: 60,
                    child: Text(strings.t("60 phút")),
                  ),
                ],
                onChanged: enabled
                    ? (nextValue) {
                        if (nextValue != null) {
                          onChanged(nextValue);
                        }
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmMiniButton extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _AlarmMiniButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
