import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../helpers/top_toast.dart';
class AlarmDeviceSheet extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final Map<String, dynamic> devices;

  const AlarmDeviceSheet({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.devices,
  });

  @override
  State<AlarmDeviceSheet> createState() => _AlarmDeviceSheetState();
}

class _AlarmDeviceSheetState extends State<AlarmDeviceSheet> {
  Map<String, dynamic> devices = {};

  @override
  void initState() {
    super.initState();
    devices = Map<String, dynamic>.from(widget.devices);
  }

  bool isSecurityDevice(Map d) {
    final type = d["type"]?.toString();

    return type == "door" ||
        type == "door_lock" ||
        type == "motion";
  }

  Future<void> saveAlarm(
      String deviceId,
      Map<String, dynamic> alarm,
      ) async {
    final device = Map<String, dynamic>.from(
      devices[deviceId] ?? {},
    );

    final ownerUid =
        device["_ownerUid"]?.toString() ?? widget.ownerUid;

    final homeId =
        device["_homeId"]?.toString() ?? widget.homeId;

    final realDeviceId =
        device["_deviceId"]?.toString() ?? deviceId;

    await FirebaseDatabase.instance
        .ref(
      "accounts/$ownerUid/homes/$homeId/devices/$realDeviceId/alarm",
    )
        .set(alarm);
  }

  bool isValidTime(String value) {
    final reg = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return reg.hasMatch(value.trim());
  }

  Future<String?> openTimeInput({
    required String title,
    required String initial,
  }) async {
    final parts = initial.split(":");

    final hourController = TextEditingController(text: parts[0]);
    final minuteController = TextEditingController(text: parts[1]);

    const suggestions = [
      ["22", "00"],
      ["23", "00"],
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
              Wrap(
                spacing: 8,
                children: suggestions.map((s) {
                  return ActionChip(
                    label: Text("${s[0]}:${s[1]}"),
                    onPressed: () {
                      hourController.text = s[0];
                      minuteController.text = s[1];
                    },
                  );
                }).toList(),
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
                final h = hourController.text.trim().padLeft(2, '0');
                final m = minuteController.text.trim().padLeft(2, '0');
                final value = "$h:$m";

                if (!isValidTime(value)) {
                  showTopToast(
                    context,
                    "Giờ không hợp lệ",
                    color: Colors.red,
                    icon: Icons.error_outline_rounded,
                  );
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> editAlarm(
      String deviceId,
      Map<String, dynamic> device,
      ) async {
    final alarm = Map<String, dynamic>.from(
      device["alarm"] ??
          {
            "enabled": true,
            "start": "23:00",
            "end": "06:00",
            "repeatMinutes": 30,
          },
    );

    final start = await openTimeInput(
      title: "Giờ bắt đầu Alarm",
      initial: alarm["start"] ?? "23:00",
    );

    if (start == null) return;

    final end = await openTimeInput(
      title: "Giờ kết thúc Alarm",
      initial: alarm["end"] ?? "06:00",
    );

    if (end == null) return;

    int repeat = alarm["repeatMinutes"] ?? 30;

    final selectedRepeat = await showDialog<int>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Báo lại"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("15 phút"),
                onTap: () => Navigator.pop(context, 15),
              ),
              ListTile(
                title: const Text("30 phút"),
                onTap: () => Navigator.pop(context, 30),
              ),
              ListTile(
                title: const Text("60 phút"),
                onTap: () => Navigator.pop(context, 60),
              ),
            ],
          ),
        );
      },
    );

    if (selectedRepeat != null) {
      repeat = selectedRepeat;
    }

    alarm["start"] = start;
    alarm["end"] = end;
    alarm["repeatMinutes"] = repeat;

    await saveAlarm(deviceId, alarm);

    setState(() {
      devices[deviceId]["alarm"] = alarm;
    });
  }

  @override
  Widget build(BuildContext context) {
    final securityDevices = devices.entries.where((e) {
      return isSecurityDevice(
        Map<String, dynamic>.from(e.value),
      );
    }).toList();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Alarm Thiết Bị",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: securityDevices.length,
                itemBuilder: (_, index) {
                  final deviceId =
                      securityDevices[index].key;

                  final device =
                  Map<String, dynamic>.from(
                    securityDevices[index].value,
                  );

                  final alarm =
                  Map<String, dynamic>.from(
                    device["alarm"] ??
                        {
                          "enabled": false,
                          "start": "23:00",
                          "end": "06:00",
                          "repeatMinutes": 30,
                        },
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: Switch(
                        value: alarm["enabled"] == true,
                        onChanged: (v) async {
                          alarm["enabled"] = v;

                          await saveAlarm(deviceId, alarm);

                          setState(() {
                            devices[deviceId]["alarm"] = alarm;
                          });
                        },
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_moon_rounded,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  device["name"] ?? deviceId,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 34),
                            child: Text(
                              "${alarm["start"]} - ${alarm["end"]} • Báo lại ${alarm["repeatMinutes"]} phút",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => editAlarm(deviceId, device),
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
}