import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
            final deviceData = Map<String, dynamic>.from(entry.value as Map);

            if (deviceData["alarm"] is Map) {
              customAlarms[deviceId] =
              Map<String, dynamic>.from(deviceData["alarm"]);
            }
          }
        }

        setState(() {
          if (savedMode == "custom" || savedMode == "home") {
            mode = savedMode!;
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
    await FirebaseDatabase.instance
        .ref("accounts/$currentUid/customRules/${widget.homeId}/mode")
        .set(nextMode);
  }

  Future<void> saveAlarm(
      String deviceId,
      Map<String, dynamic> alarm,
      ) async {
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

  Future<void> pickTime({
    required String deviceId,
    required Map<String, dynamic> alarm,
    required String field,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: parseTime(alarm[field]?.toString() ?? "23:00"),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final nextAlarm = Map<String, dynamic>.from(alarm);
    nextAlarm[field] = formatTime(picked);

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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: "home",
                  label: Text("Theo nhà"),
                  icon: Icon(Icons.home_rounded),
                ),
                ButtonSegment(
                  value: "custom",
                  label: Text("Riêng tôi"),
                  icon: Icon(Icons.person_rounded),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) async {
                final nextMode = value.first;

                setState(() {
                  mode = nextMode;
                  expandedDeviceId = "";
                });

                await saveMode(nextMode);
              },
            ),

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
                      mode == "home" &&
                          isSharedUser &&
                          !widget.canManageHome;
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
                                    expandedDeviceId =
                                    expanded ? "" : deviceId;
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
                                      "${alarm["start"] ?? "23:00"} → ${alarm["end"] ?? "06:00"} • ${alarm["repeatMinutes"] ?? 30} phút",
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
                                  value:
                                  alarm["start"]?.toString() ?? "23:00",
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

                          Row(
                            children: [15, 30, 60].map((minute) {
                              final selected =
                                  alarm["repeatMinutes"] == minute;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: ChoiceChip(
                                    label: Text("$minute phút"),
                                    selected: selected,
                                    onSelected: readOnly
                                        ? null
                                        : (_) async {
                                      final nextAlarm =
                                      Map<String, dynamic>.from(
                                        alarm,
                                      );
                                      nextAlarm["repeatMinutes"] = minute;

                                      await saveAlarm(
                                        deviceId,
                                        nextAlarm,
                                      );
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
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