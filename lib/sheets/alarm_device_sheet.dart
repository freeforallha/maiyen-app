import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';
import 'package:safehome_app/helpers/debug_log.dart';

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

String _alarmRepeatLabel(Object? rawValue, AppStrings strings) {
  final value = _normalizeAlarmRepeatMinutes(rawValue);
  return value == 0 ? strings.t("Không lặp lại") : strings.minuteText(value);
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
      );
    default:
      return "";
  }
}

String _alarmWeekdayShortLabel(int day, AppStrings strings) {
  switch (day) {
    case 1:
      return strings.choose(
        vi: "T2",
        my: "တနင်္လာ",
        fil: "Lun",
        km: "ច.",
        en: "Mon",
        zh: "周一",
        ko: "월",
        ja: "月",
        de: "Mo",
        ru: "Пн",
        fr: "Lun",
        es: "Lun",
        id: "Sen",
        th: "จ.",
        ms: "Isn",
        lo: "ຈ.",
      );
    case 2:
      return strings.choose(
        vi: "T3",
        my: "အင်္ဂါ",
        fil: "Mar",
        km: "អ.",
        en: "Tue",
        zh: "周二",
        ko: "화",
        ja: "火",
        de: "Di",
        ru: "Вт",
        fr: "Mar",
        es: "Mar",
        id: "Sel",
        th: "อ.",
        ms: "Sel",
        lo: "ອ.",
      );
    case 3:
      return strings.choose(
        vi: "T4",
        my: "ဗုဒ္ဓဟူး",
        fil: "Miy",
        km: "ព.",
        en: "Wed",
        zh: "周三",
        ko: "수",
        ja: "水",
        de: "Mi",
        ru: "Ср",
        fr: "Mer",
        es: "Mié",
        id: "Rab",
        th: "พ.",
        ms: "Rab",
        lo: "ພ.",
      );
    case 4:
      return strings.choose(
        vi: "T5",
        my: "ကြာသပတေး",
        fil: "Huw",
        km: "ព្រ.",
        en: "Thu",
        zh: "周四",
        ko: "목",
        ja: "木",
        de: "Do",
        ru: "Чт",
        fr: "Jeu",
        es: "Jue",
        id: "Kam",
        th: "พฤ.",
        ms: "Kha",
        lo: "ພຫ.",
      );
    case 5:
      return strings.choose(
        vi: "T6",
        my: "သောကြာ",
        fil: "Biy",
        km: "សុ.",
        en: "Fri",
        zh: "周五",
        ko: "금",
        ja: "金",
        de: "Fr",
        ru: "Пт",
        fr: "Ven",
        es: "Vie",
        id: "Jum",
        th: "ศ.",
        ms: "Jum",
        lo: "ສຸ.",
      );
    case 6:
      return strings.choose(
        vi: "T7",
        my: "စနေ",
        fil: "Sab",
        km: "សៅ.",
        en: "Sat",
        zh: "周六",
        ko: "토",
        ja: "土",
        de: "Sa",
        ru: "Сб",
        fr: "Sam",
        es: "Sáb",
        id: "Sab",
        th: "ส.",
        ms: "Sab",
        lo: "ສ.",
      );
    case 7:
      return strings.choose(
        vi: "CN",
        my: "တနင်္ဂနွေ",
        fil: "Lin",
        km: "អា.",
        en: "Sun",
        zh: "周日",
        ko: "일",
        ja: "日",
        de: "So",
        ru: "Вс",
        fr: "Dim",
        es: "Dom",
        id: "Min",
        th: "อา.",
        ms: "Ahd",
        lo: "ອາ.",
      );
    default:
      return "";
  }
}

String _alarmDaysLabel(Object? rawValue, AppStrings strings) {
  final days = _normalizeAlarmDays(rawValue);

  if (days.length == 7) {
    return strings.choose(
      vi: "Hằng ngày",
      my: "နေ့တိုင်း",
      fil: "Araw-araw",
      km: "រាល់ថ្ងៃ",
      en: "Every day",
      zh: "每天",
      ko: "매일",
      ja: "毎日",
      de: "Täglich",
      ru: "Каждый день",
      fr: "Tous les jours",
      es: "Todos los días",
      id: "Setiap hari",
      th: "ทุกวัน",
      ms: "Setiap hari",
      lo: "ທຸກມື້",
    );
  }

  return days
      .map((day) => _alarmWeekdayShortLabel(day, strings))
      .where((label) => label.isNotEmpty)
      .join(", ");
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
  Map<String, dynamic> homeAlarms = {};
  Map<String, dynamic> customAlarms = {};

  String mode = "home";
  String expandedDeviceId = "";
  bool savingMode = false;
  bool applyingAll = false;

  String get currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.ownerUid;

  bool get isSharedUser => currentUid != widget.ownerUid;

  @override
  void initState() {
    super.initState();

    devices = Map<String, dynamic>.from(widget.devices);

    for (final entry in devices.entries) {
      final deviceId = entry.key.toString();
      final rawDevice = entry.value;

      if (rawDevice is! Map) {
        continue;
      }

      final device = Map<String, dynamic>.from(rawDevice);

      homeAlarms[deviceId] = _readAlarmMap(device["alarm"]);
    }

    FirebaseDatabase.instance
        .ref("accounts/$currentUid/customRules/${widget.homeId}")
        .get()
        .then((snap) {
          if (!mounted) return;

          final data = snap.value;

          if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            final savedMode =
                map["alarmMode"]?.toString() ?? map["mode"]?.toString();
            final customDevices = map["devices"];

            if (customDevices is Map) {
              for (final entry in customDevices.entries) {
                final deviceId = entry.key.toString();
                final rawDeviceData = entry.value;

                if (rawDeviceData is! Map) {
                  continue;
                }

                final deviceData = Map<String, dynamic>.from(rawDeviceData);

                if (deviceData.containsKey("alarm")) {
                  customAlarms[deviceId] = _readAlarmMap(deviceData["alarm"]);
                }
              }
            }

            setState(() {
              if (savedMode == "custom" || savedMode == "home") {
                mode = savedMode == "custom" ? "custom" : "home";
              }
            });
          }
        });
  }

  Map<String, dynamic> _defaultAlarm() {
    return {
      "enabled": false,
      "start": "23:00",
      "end": "06:00",
      "repeatMinutes": 30,
      "days": const [1, 2, 3, 4, 5, 6, 7],
    };
  }

  Map<String, dynamic> _readAlarmMap(Object? rawValue) {
    final alarm = Map<String, dynamic>.from(_defaultAlarm());

    if (rawValue is Map) {
      alarm.addAll(Map<String, dynamic>.from(rawValue));
    } else if (rawValue is bool) {
      // Tương thích dữ liệu cũ từng lưu alarm dưới dạng true/false.
      alarm["enabled"] = rawValue;
    }

    alarm["repeatMinutes"] = _normalizeAlarmRepeatMinutes(
      alarm["repeatMinutes"],
    );

    alarm["days"] = _normalizeAlarmDays(alarm["days"]);

    return alarm;
  }

  bool isSecurityDevice(Map d) {
    return isSecurityDeviceType(d["type"]);
  }

  Map<String, dynamic> alarmOf(String deviceId) {
    final source = mode == "custom"
        ? customAlarms[deviceId] ?? homeAlarms[deviceId]
        : homeAlarms[deviceId];

    return _readAlarmMap(source);
  }

  Future<void> saveMode(String nextMode) async {
    if (savingMode || nextMode == mode) {
      return;
    }

    setState(() {
      savingMode = true;
    });

    final rulesRef = FirebaseDatabase.instance.ref(
      "accounts/$currentUid/customRules/${widget.homeId}",
    );

    try {
      if (nextMode == "custom") {
        final updates = <String, Object?>{"alarmMode": "custom"};

        final nextCustomAlarms = <String, dynamic>{};

        for (final entry in devices.entries) {
          final deviceId = entry.key.toString();
          final rawDevice = entry.value;

          if (rawDevice is! Map) {
            continue;
          }

          final device = Map<String, dynamic>.from(rawDevice);

          if (!isSecurityDevice(device)) {
            continue;
          }

          final rawRealDeviceId = device["_deviceId"]?.toString().trim() ?? "";

          final realDeviceId = rawRealDeviceId.isNotEmpty
              ? rawRealDeviceId
              : deviceId;

          final rawAlarm =
              customAlarms[deviceId] ??
              customAlarms[realDeviceId] ??
              homeAlarms[deviceId] ??
              homeAlarms[realDeviceId];

          final alarm = rawAlarm is Map
              ? Map<String, dynamic>.from(rawAlarm)
              : _defaultAlarm();

          nextCustomAlarms[deviceId] = Map<String, dynamic>.from(alarm);

          updates["devices/$realDeviceId/alarm"] = Map<String, dynamic>.from(
            alarm,
          );
        }

        await rulesRef.update(updates);

        if (!mounted) {
          return;
        }

        setState(() {
          customAlarms = nextCustomAlarms;
          mode = "custom";
          expandedDeviceId = "";
        });

        return;
      }

      await rulesRef.child("alarmMode").set("home");

      if (!mounted) {
        return;
      }

      setState(() {
        mode = "home";
        expandedDeviceId = "";
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      showTopToast(
        context,
        AppStrings.of(context).t("Không thể lưu chế độ báo động"),
        color: SafeHomeColors.danger,
        icon: Icons.error_rounded,
      );

      safeDebugPrint("SAVE_ALARM_MODE_ERROR: $error");
    } finally {
      if (mounted) {
        setState(() {
          savingMode = false;
        });
      }
    }
  }

  Map<String, dynamic> normalizeAlarmForSave(Map<String, dynamic> alarm) {
    final nextAlarm = Map<String, dynamic>.from(alarm);

    nextAlarm["days"] = _normalizeAlarmDays(nextAlarm["days"]);
    nextAlarm["repeatMinutes"] = _normalizeAlarmRepeatMinutes(
      nextAlarm["repeatMinutes"],
    );

    nextAlarm["start"] =
        (nextAlarm["start"]?.toString().trim().isNotEmpty == true)
        ? nextAlarm["start"].toString().trim()
        : "23:00";

    nextAlarm["end"] = (nextAlarm["end"]?.toString().trim().isNotEmpty == true)
        ? nextAlarm["end"].toString().trim()
        : "06:00";

    return nextAlarm;
  }

  Future<void> saveAlarmForAllSecurityDevices(
    Map<String, dynamic> alarm,
  ) async {
    if (applyingAll) {
      return;
    }

    if (mode == "home" && !widget.canManageHome) {
      if (mounted) {
        showTopToast(
          context,
          AppStrings.of(
            context,
          ).t("Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi."),
          color: SafeHomeColors.danger,
          icon: Icons.lock_rounded,
        );
      }
      return;
    }

    final securityEntries = devices.entries.where((entry) {
      final rawDevice = entry.value;
      return rawDevice is Map && isSecurityDevice(rawDevice);
    }).toList();

    if (securityEntries.isEmpty) {
      if (mounted) {
        showTopToast(
          context,
          AppStrings.of(context).t("Nhà chưa có thiết bị an ninh để áp dụng"),
          color: Colors.orange,
          icon: Icons.sensors_off_rounded,
        );
      }
      return;
    }

    setState(() {
      applyingAll = true;
    });

    try {
      final updates = <String, Object?>{};

      for (final entry in securityEntries) {
        final deviceId = entry.key.toString();
        final device = Map<String, dynamic>.from(entry.value as Map);
        final homeId = device["_homeId"]?.toString().trim().isNotEmpty == true
            ? device["_homeId"].toString().trim()
            : widget.homeId;
        final realDeviceId =
            device["_deviceId"]?.toString().trim().isNotEmpty == true
            ? device["_deviceId"].toString().trim()
            : deviceId;

        final path = mode == "custom"
            ? "accounts/$currentUid/customRules/$homeId/devices/$realDeviceId/alarm"
            : "accounts/${widget.ownerUid}/homes/$homeId/devices/$realDeviceId/alarm";

        updates[path] = normalizeAlarmForSave(alarm);
      }

      await FirebaseDatabase.instance.ref().update(updates);

      if (!mounted) {
        return;
      }

      setState(() {
        for (final entry in securityEntries) {
          final deviceId = entry.key.toString();
          final copiedAlarm = normalizeAlarmForSave(alarm);

          if (mode == "custom") {
            customAlarms[deviceId] = copiedAlarm;
          } else {
            homeAlarms[deviceId] = copiedAlarm;
          }
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          applyingAll = false;
        });
      }
    }
  }

  Future<void> showQuickAlarmForAllSheet() async {
    final strings = AppStrings.of(context);

    if (mode == "home" && !widget.canManageHome) {
      showTopToast(
        context,
        AppStrings.of(
          context,
        ).t("Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi."),
        color: SafeHomeColors.danger,
        icon: Icons.lock_rounded,
      );
      return;
    }

    final securityEntries = devices.entries.where((entry) {
      final rawDevice = entry.value;
      return rawDevice is Map && isSecurityDevice(rawDevice);
    }).toList();

    if (securityEntries.isEmpty) {
      showTopToast(
        context,
        AppStrings.of(context).t("Nhà chưa có thiết bị an ninh để áp dụng"),
        color: Colors.orange,
        icon: Icons.sensors_off_rounded,
      );
      return;
    }

    final draft = Map<String, dynamic>.from(
      alarmOf(securityEntries.first.key.toString()),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var saving = false;

        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            Future<void> chooseTime(String field) async {
              final picked = await openTimeTextInput(
                title: field == "start"
                    ? strings.t("Chọn giờ bắt đầu báo động")
                    : strings.t("Chọn giờ kết thúc báo động"),
                initial:
                    draft[field]?.toString() ??
                    (field == "start" ? "23:00" : "06:00"),
              );

              if (picked == null || !sheetContext.mounted) {
                return;
              }

              setSheetState(() {
                draft[field] = picked;
              });
            }

            Future<void> applyToAll() async {
              if (saving) {
                return;
              }

              setSheetState(() {
                saving = true;
              });

              try {
                await saveAlarmForAllSecurityDevices(draft);

                if (!sheetContext.mounted) {
                  return;
                }

                Navigator.of(sheetContext).pop();

                if (mounted) {
                  showTopToast(
                    context,
                    strings.alarmAppliedToSecurityDevicesText(
                      securityEntries.length,
                    ),
                    color: SafeHomeColors.success,
                    icon: Icons.check_circle_rounded,
                  );
                }
              } catch (error) {
                if (!sheetContext.mounted) {
                  return;
                }

                setSheetState(() {
                  saving = false;
                });

                showTopToast(
                  sheetContext,
                  strings.t("Không thể áp dụng báo động cho toàn bộ thiết bị"),
                  color: SafeHomeColors.danger,
                  icon: Icons.error_rounded,
                );

                safeDebugPrint("SAVE_ALL_SECURITY_ALARMS_ERROR: $error");
              }
            }

            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 12,
                  bottom: MediaQuery.of(innerContext).viewInsets.bottom + 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: SafeHomeColors.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: SafeHomeColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t("Đặt báo động cho nhà"),
                                style: const TextStyle(
                                  color: SafeHomeColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                strings
                                    .applySameAlarmScheduleToSecurityDevicesText(
                                      securityEntries.length,
                                    ),
                                style: const TextStyle(
                                  color: SafeHomeColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: draft["enabled"] == true,
                          onChanged: saving
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    draft["enabled"] = value;
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _AlarmMiniButton(
                            label: strings.t("Bắt đầu"),
                            value: draft["start"]?.toString() ?? "23:00",
                            enabled: !saving,
                            onTap: () {
                              chooseTime("start");
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AlarmMiniButton(
                            label: strings.t("Kết thúc"),
                            value: draft["end"]?.toString() ?? "06:00",
                            enabled: !saving,
                            onTap: () {
                              chooseTime("end");
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AlarmRepeatDropdown(
                      value: _normalizeAlarmRepeatMinutes(
                        draft["repeatMinutes"],
                      ),
                      enabled: !saving,
                      onChanged: (minute) {
                        setSheetState(() {
                          draft["repeatMinutes"] = minute;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _AlarmWeekdaySelector(
                      days: _normalizeAlarmDays(draft["days"]),
                      enabled: !saving,
                      onChanged: (days) {
                        setSheetState(() {
                          draft["days"] = days;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: SafeHomeColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: saving ? null : applyToAll,
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
                              ? strings.t("Đang áp dụng...")
                              : strings.t("Xác nhận"),
                        ),
                      ),
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

  Future<void> saveAlarm(String deviceId, Map<String, dynamic> alarm) async {
    if (mode == "home" && !widget.canManageHome) {
      if (mounted) {
        showTopToast(
          context,
          AppStrings.of(
            context,
          ).t("Bạn không có quyền sửa lịch báo động của nhà"),
          color: SafeHomeColors.danger,
          icon: Icons.lock_rounded,
        );
      }

      return;
    }

    final device = Map<String, dynamic>.from(devices[deviceId] ?? {});
    final homeId = device["_homeId"]?.toString() ?? widget.homeId;
    final realDeviceId = device["_deviceId"]?.toString() ?? deviceId;

    final path = mode == "custom"
        ? "accounts/$currentUid/customRules/$homeId/devices/$realDeviceId/alarm"
        : "accounts/${widget.ownerUid}/homes/$homeId/devices/$realDeviceId/alarm";

    final alarmToSave = normalizeAlarmForSave(alarm);

    await FirebaseDatabase.instance.ref(path).set(alarmToSave);

    setState(() {
      if (mode == "custom") {
        customAlarms[deviceId] = alarmToSave;
      } else {
        homeAlarms[deviceId] = alarmToSave;
      }
    });
  }

  TimeOfDay parseTime(String value) {
    final parts = value.split(":");

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 23,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, "0");
    final m = time.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  bool isValidTime(String value) {
    final reg = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return reg.hasMatch(value.trim());
  }

  Future<String?> openTimeTextInput({
    required String title,
    required String initial,
  }) async {
    final strings = AppStrings.of(context);
    final parts = initial.split(":");

    String hourText = parts.isNotEmpty ? parts[0].padLeft(2, "0") : "23";
    String minuteText = parts.length > 1 ? parts[1].padLeft(2, "0") : "00";

    const suggestions = [
      ["23", "00"],
      ["00", "00"],
      ["01", "00"],
      ["04", "00"],
      ["05", "00"],
      ["06", "00"],
    ];

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final value =
                  "${hourText.trim().padLeft(2, '0')}:${minuteText.trim().padLeft(2, '0')}";

              if (!isValidTime(value)) {
                showTopToast(
                  dialogContext,
                  strings.t("Giờ không hợp lệ"),
                  color: SafeHomeColors.danger,
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
                          key: ValueKey("alarm_hour_$hourText"),
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
                          key: ValueKey("alarm_minute_$minuteText"),
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

  Future<void> pickTime({
    required String deviceId,
    required Map<String, dynamic> alarm,
    required String field,
  }) async {
    final picked = await openTimeTextInput(
      title: field == "start"
          ? AppStrings.of(context).t("Chọn giờ bắt đầu báo động")
          : AppStrings.of(context).t("Chọn giờ kết thúc báo động"),
      initial: alarm[field]?.toString() ?? "23:00",
    );

    if (picked == null) return;

    final nextAlarm = Map<String, dynamic>.from(alarm);
    nextAlarm[field] = picked;

    await saveAlarm(deviceId, nextAlarm);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final securityDevices = devices.entries.where((e) {
      return isSecurityDevice(Map<String, dynamic>.from(e.value));
    }).toList();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.t("Báo động thiết bị"),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                strings.t("Chế độ áp dụng"),
                style: const TextStyle(
                  color: SafeHomeColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _AlarmModeCard(
                    title: strings.t("Theo nhà"),
                    subtitle: strings.t(
                      "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập",
                    ),
                    icon: Icons.home_rounded,
                    selected: mode == "home",
                    enabled: !savingMode,
                    onTap: () {
                      saveMode("home");
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlarmModeCard(
                    title: strings.t("Riêng tôi"),
                    subtitle: strings.t(
                      "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn",
                    ),
                    icon: Icons.person_rounded,
                    selected: mode == "custom",
                    enabled: !savingMode,
                    onTap: () {
                      saveMode("custom");
                    },
                  ),
                ),
              ],
            ),

            if (savingMode) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],

            if (mode == "home" && isSharedUser) ...[
              const SizedBox(height: 10),
              Text(
                strings.t(
                  "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch báo động.",
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: savingMode || applyingAll
                    ? null
                    : showQuickAlarmForAllSheet,
                icon: applyingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.tune_rounded),
                label: Text(
                  applyingAll
                      ? strings.t("Đang áp dụng...")
                      : strings.t("Thiết lập nhanh toàn bộ thiết bị"),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: SafeHomeColors.primary,
                  side: BorderSide(
                    color: SafeHomeColors.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: securityDevices.length,
                itemBuilder: (_, index) {
                  final deviceId = securityDevices[index].key;
                  final device = Map<String, dynamic>.from(
                    securityDevices[index].value,
                  );

                  final alarm = alarmOf(deviceId);
                  final readOnly =
                      mode == "home" && isSharedUser && !widget.canManageHome;
                  final expanded = expandedDeviceId == deviceId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SafeHomeColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: SafeHomeColors.primary.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedDeviceId = expanded ? "" : deviceId;
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: SafeHomeColors.primary
                                              .withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _alarmDeviceIcon(device["type"]),
                                          size: 21,
                                          color: SafeHomeColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              device["name"]?.toString() ??
                                                  deviceId,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color:
                                                    SafeHomeColors.textPrimary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "${alarm["start"] ?? "23:00"} → ${alarm["end"] ?? "06:00"} • ${_alarmDaysLabel(alarm["days"], strings)} • ${_alarmRepeatLabel(alarm["repeatMinutes"], strings)}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: SafeHomeColors
                                                    .textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: alarm["enabled"] == true,
                              onChanged: readOnly
                                  ? null
                                  : (v) async {
                                      final nextAlarm =
                                          Map<String, dynamic>.from(alarm);
                                      nextAlarm["enabled"] = v;
                                      await saveAlarm(deviceId, nextAlarm);
                                    },
                            ),
                          ],
                        ),

                        if (expanded) ...[
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _AlarmMiniButton(
                                  label: strings.t("Bắt đầu"),
                                  value: alarm["start"]?.toString() ?? "23:00",
                                  enabled: !readOnly,
                                  onTap: () => pickTime(
                                    deviceId: deviceId,
                                    alarm: alarm,
                                    field: "start",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _AlarmMiniButton(
                                  label: strings.t("Kết thúc"),
                                  value: alarm["end"]?.toString() ?? "06:00",
                                  enabled: !readOnly,
                                  onTap: () => pickTime(
                                    deviceId: deviceId,
                                    alarm: alarm,
                                    field: "end",
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          _AlarmRepeatDropdown(
                            value: _normalizeAlarmRepeatMinutes(
                              alarm["repeatMinutes"],
                            ),
                            enabled: !readOnly,
                            onChanged: (minute) async {
                              final nextAlarm = Map<String, dynamic>.from(
                                alarm,
                              );
                              nextAlarm["repeatMinutes"] = minute;

                              await saveAlarm(deviceId, nextAlarm);
                            },
                          ),

                          const SizedBox(height: 10),

                          _AlarmWeekdaySelector(
                            days: _normalizeAlarmDays(alarm["days"]),
                            enabled: !readOnly,
                            onChanged: (days) async {
                              final nextAlarm = Map<String, dynamic>.from(
                                alarm,
                              );
                              nextAlarm["days"] = days;

                              await saveAlarm(deviceId, nextAlarm);
                            },
                          ),
                        ],
                      ],
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
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(
              strings.t("Ngày trong tuần"),
              style: const TextStyle(
                color: SafeHomeColors.textPrimary,
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
    final activeColor = SafeHomeColors.primary;

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
                : SafeHomeColors.border,
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
                    : SafeHomeColors.textSecondary.withValues(
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
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.t("Thời gian lặp lại"),
              style: const TextStyle(
                color: SafeHomeColors.textPrimary,
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
                  color: SafeHomeColors.textSecondary,
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

class _AlarmModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AlarmModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = SafeHomeColors.primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.62,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 142),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.08)
                  : SafeHomeColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? accent : SafeHomeColors.border,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? accent.withValues(alpha: 0.12)
                            : SafeHomeColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: selected ? accent : SafeHomeColors.textSecondary,
                        size: 21,
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: const ValueKey("selected"),
                              color: accent,
                              size: 22,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              key: const ValueKey("unselected"),
                              color: SafeHomeColors.border,
                              size: 22,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: selected ? accent : SafeHomeColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SafeHomeColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
