import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../helpers/top_toast.dart';
import '../safehome_theme.dart';
import 'package:safehome_app/helpers/debug_log.dart';
int _normalizeAlarmRepeatMinutes(Object? rawValue) {
  final value = rawValue is num
      ? rawValue.toInt()
      : int.tryParse(rawValue?.toString() ?? "");

  if (value == null) {
    return 30;
  }

  return const [0, 15, 30, 60].contains(value) ? value : 30;
}

String _alarmRepeatLabel(Object? rawValue) {
  final value = _normalizeAlarmRepeatMinutes(rawValue);
  return value == 0 ? "Không lặp lại" : "$value phút";
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
      final device = Map<String, dynamic>.from(entry.value);

      homeAlarms[deviceId] = Map<String, dynamic>.from(
        device["alarm"] ?? _defaultAlarm(),
      );
    }

    FirebaseDatabase.instance
        .ref("accounts/$currentUid/customRules/${widget.homeId}")
        .get()
        .then((snap) {
          if (!mounted) return;

          final data = snap.value;

          if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            final savedMode = map["mode"]?.toString();
            final customDevices = map["devices"];

            if (customDevices is Map) {
              for (final entry in customDevices.entries) {
                final deviceId = entry.key.toString();
                final deviceData = Map<String, dynamic>.from(
                  entry.value as Map,
                );

                if (deviceData["alarm"] is Map) {
                  customAlarms[deviceId] = Map<String, dynamic>.from(
                    deviceData["alarm"],
                  );
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
    };
  }

  bool isSecurityDevice(Map d) {
    final type = d["type"]?.toString();

    return type == "door" || type == "door_lock" || type == "motion";
  }

  Map<String, dynamic> alarmOf(String deviceId) {
    final source = mode == "custom"
        ? customAlarms[deviceId] ?? homeAlarms[deviceId]
        : homeAlarms[deviceId];

    return Map<String, dynamic>.from(source ?? _defaultAlarm());
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
        final updates = <String, Object?>{"mode": "custom"};

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

      await rulesRef.child("mode").set("home");

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
        "Không thể lưu chế độ Alarm",
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
          "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.",
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
          "Nhà chưa có thiết bị an ninh để áp dụng",
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

        updates[path] = Map<String, dynamic>.from(alarm);
      }

      await FirebaseDatabase.instance.ref().update(updates);

      if (!mounted) {
        return;
      }

      setState(() {
        for (final entry in securityEntries) {
          final deviceId = entry.key.toString();
          final copiedAlarm = Map<String, dynamic>.from(alarm);

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
    if (mode == "home" && !widget.canManageHome) {
      showTopToast(
        context,
        "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.",
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
        "Nhà chưa có thiết bị an ninh để áp dụng",
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
                    ? "Chọn giờ bắt đầu Alarm"
                    : "Chọn giờ kết thúc Alarm",
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
                    "Đã áp dụng Alarm cho ${securityEntries.length} thiết bị an ninh",
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
                  "Không thể áp dụng Alarm cho toàn bộ thiết bị",
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
                            color: SafeHomeColors.danger.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: SafeHomeColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Thiết lập nhanh Alarm",
                                style: TextStyle(
                                  color: SafeHomeColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Áp dụng cùng một lịch cho ${securityEntries.length} thiết bị an ninh",
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
                            label: "Bắt đầu",
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
                            label: "Kết thúc",
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
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
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
                              ? "Đang áp dụng..."
                              : "Áp dụng cho toàn bộ thiết bị",
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
          "Bạn không có quyền sửa lịch Alarm của nhà",
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

    await FirebaseDatabase.instance.ref(path).set(alarm);

    setState(() {
      if (mode == "custom") {
        customAlarms[deviceId] = alarm;
      } else {
        homeAlarms[deviceId] = alarm;
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
                      decoration: const InputDecoration(
                        labelText: "Giờ",
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
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
                    child: TextField(
                      controller: minuteController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: "Phút",
                        counterText: "",
                        border: OutlineInputBorder(),
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
                          child: ActionChip(
                            label: Text("${s[0]}:${s[1]}"),
                            onPressed: () {
                              hourController.text = s[0];
                              minuteController.text = s[1];
                            },
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
                          child: ActionChip(
                            label: Text("${s[0]}:${s[1]}"),
                            onPressed: () {
                              hourController.text = s[0];
                              minuteController.text = s[1];
                            },
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
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                    "${hourController.text.padLeft(2, '0')}:${minuteController.text.padLeft(2, '0')}";

                if (!isValidTime(value)) return;

                Navigator.pop(context, value);
              },
              child: const Text("OK"),
            ),
          ],
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
          ? "Chọn giờ bắt đầu Alarm"
          : "Chọn giờ kết thúc Alarm",
      initial: alarm[field]?.toString() ?? "23:00",
    );

    if (picked == null) return;

    final nextAlarm = Map<String, dynamic>.from(alarm);
    nextAlarm[field] = picked;

    await saveAlarm(deviceId, nextAlarm);
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              "Alarm thiết bị",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 14),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Chế độ áp dụng",
                style: TextStyle(
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
                    title: "Theo nhà",
                    subtitle:
                        "Dùng lịch chung do Chủ nhà hoặc "
                        "Quản trị viên thiết lập",
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
                    title: "Riêng tôi",
                    subtitle:
                        "Dùng lịch riêng chỉ áp dụng cho "
                        "tài khoản của bạn",
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
                "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch alarm.",
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
                      ? "Đang áp dụng..."
                      : "Thiết lập nhanh toàn bộ thiết bị",
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: SafeHomeColors.danger,
                  side: BorderSide(
                    color: SafeHomeColors.danger.withValues(alpha: 0.35),
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
                      color: Colors.red.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_moon_rounded,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 10),

                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    expandedDeviceId = expanded ? "" : deviceId;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device["name"]?.toString() ?? deviceId,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "${alarm["start"] ?? "23:00"} → ${alarm["end"] ?? "06:00"} • ${_alarmRepeatLabel(alarm["repeatMinutes"])}",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

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

                            IconButton(
                              icon: Icon(
                                expanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                              ),
                              onPressed: () {
                                setState(() {
                                  expandedDeviceId = expanded ? "" : deviceId;
                                });
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
                                  label: "Bắt đầu",
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
                                  label: "Kết thúc",
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
          const Expanded(
            child: Text(
              "Thời gian lặp lại",
              style: TextStyle(
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
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Không lặp lại")),
                  DropdownMenuItem(value: 15, child: Text("15 phút")),
                  DropdownMenuItem(value: 30, child: Text("30 phút")),
                  DropdownMenuItem(value: 60, child: Text("60 phút")),
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
    final accent = SafeHomeColors.danger;

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
