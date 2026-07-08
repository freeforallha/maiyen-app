import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../helpers/firebase_paths.dart';
import '../helpers/top_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_strings.dart';

class ScheduleSheet extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final bool isShared;
  final String type;
  final bool canManageHome;
  const ScheduleSheet({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.isShared,
    required this.type,
    required this.canManageHome,
  });

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  String get currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.ownerUid;

  bool get isSharedUser => currentUid != widget.ownerUid;
  String reminderMode = "home";
  List<Map<String, dynamic>> alarms = [];
  List<Map<String, dynamic>> notifications = [];

  DatabaseReference get ref {
    if (widget.type == "notification" &&
        isSharedUser &&
        reminderMode == "custom") {
      return FirebaseDatabase.instance.ref(
        "accounts/$currentUid/customRules/${widget.homeId}/notifications",
      );
    }

    return FirebaseDatabase.instance.ref(
      FirebasePaths.schedules(widget.ownerUid, widget.homeId),
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.type == "notification" && isSharedUser) {
      FirebaseDatabase.instance
          .ref("accounts/$currentUid/customRules/${widget.homeId}/mode")
          .get()
          .then((snap) {
            final value = snap.value?.toString();

            if (value == "custom" || value == "home") {
              setState(() {
                reminderMode = value == "custom" ? "custom" : "home";
              });
            }

            load();
          });
    } else {
      load();
    }
  }

  Future<void> load() async {
    final snap = await ref.get();

    if (!snap.exists) return;

    if (widget.type == "notification" &&
        isSharedUser &&
        reminderMode == "custom") {
      final data = Map<String, dynamic>.from(snap.value as Map);

      setState(() {
        notifications = List<Map<String, dynamic>>.from(
          (data["items"] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );
      });

      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);

    setState(() {
      alarms = List<Map<String, dynamic>>.from(
        (data["alarms"] ?? []).map((e) => Map<String, dynamic>.from(e)),
      );

      notifications = List<Map<String, dynamic>>.from(
        (data["notifications"] ?? []).map((e) => Map<String, dynamic>.from(e)),
      );
    });
  }

  Future<void> saveSchedules() async {
    final isCustomReminder =
        widget.type == "notification" &&
        isSharedUser &&
        reminderMode == "custom";

    if (!isCustomReminder && !widget.canManageHome) {
      if (mounted) {
        showTopToast(
          context,
          "Bạn không có quyền sửa lịch chung của nhà",
          color: Colors.red,
          icon: Icons.lock_rounded,
        );
      }

      return;
    }

    if (isCustomReminder) {
      await ref.set({"items": notifications});

      return;
    }

    await ref.update({"alarms": alarms, "notifications": notifications});
  }

  String repeatLabel(dynamic value) {
    final strings = AppStrings.of(context);
    final minutes = int.tryParse(value?.toString() ?? "0") ?? 0;

    if (minutes == 15) {
      return strings.t("Báo lại mỗi 15 phút");
    }
    if (minutes == 30) {
      return strings.t("Báo lại mỗi 30 phút");
    }
    if (minutes == 60) {
      return strings.t("Báo lại mỗi 1 giờ");
    }

    return strings.t("Không báo lại");
  }

  Future<int?> openRepeatInput({required int initial}) async {
    int selected = initial;
    final strings = AppStrings.of(context);

    return showDialog<int>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget option({required int value, required String title}) {
              final isSelected = selected == value;

              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? Colors.red : Colors.grey,
                ),
                title: Text(title),
                onTap: () {
                  setDialogState(() {
                    selected = value;
                  });
                },
              );
            }

            return AlertDialog(
              title: Text(
                strings.t("Báo lại khi vẫn chưa an toàn"),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  option(
                    value: 0,
                    title: strings.t("Không báo lại"),
                  ),
                  option(
                    value: 15,
                    title: strings.t("Mỗi 15 phút"),
                  ),
                  option(
                    value: 30,
                    title: strings.t("Mỗi 30 phút"),
                  ),
                  option(
                    value: 60,
                    title: strings.t("Mỗi 1 giờ"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.t("Huỷ")),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(strings.t("OK")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool isValidTime(String value) {
    final reg = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

    return reg.hasMatch(value.trim());
  }

  Future<String?> openTimeInput({
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
                          key: ValueKey("schedule_hour_$hourText"),
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
                          key: ValueKey("schedule_minute_$minuteText"),
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

  Future<void> addAlarm() async {
    final strings = AppStrings.of(context);
    final start = await openTimeInput(
      title: strings.t("Giờ bắt đầu Alarm"),
      initial: "23:00",
    );

    if (start == null) return;

    final end = await openTimeInput(
      title: strings.t("Giờ kết thúc Alarm"),
      initial: "06:00",
    );

    if (end == null) return;

    final repeatMinutes = await openRepeatInput(initial: 15);

    if (repeatMinutes == null) return;

    setState(() {
      alarms.add({
        "enabled": true,
        "start": start,
        "end": end,
        "repeatMinutes": repeatMinutes,
      });
    });

    saveSchedules();
  }

  Future<void> openReminderOptionSheet(int index) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
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
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(
                    AppStrings.of(context).t("Sửa giờ Reminder"),
                  ),
                  onTap: () => Navigator.pop(context, "edit"),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: Text(
                    AppStrings.of(context).t("Xoá Reminder"),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.pop(context, "delete"),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == "edit") {
      await editNotification(index);
      return;
    }

    if (action == "delete") {
      setState(() {
        notifications.removeAt(index);
      });

      await saveSchedules();
    }
  }

  Future<void> editAlarm(int index) async {
    final strings = AppStrings.of(context);
    final current = alarms[index];

    final start = await openTimeInput(
      title: strings.t("Sửa giờ bắt đầu Alarm"),
      initial: current["start"]?.toString() ?? "23:00",
    );

    if (start == null) return;

    final end = await openTimeInput(
      title: strings.t("Sửa giờ kết thúc Alarm"),
      initial: current["end"]?.toString() ?? "06:00",
    );

    if (end == null) return;

    final repeatMinutes = await openRepeatInput(
      initial: current["repeatMinutes"] ?? 15,
    );

    if (repeatMinutes == null) return;

    setState(() {
      alarms[index]["start"] = start;
      alarms[index]["end"] = end;
      alarms[index]["repeatMinutes"] = repeatMinutes;
    });

    saveSchedules();
  }

  Future<void> addNotification() async {
    final time = await openTimeInput(
      title: AppStrings.of(context).t("Giờ Reminder"),
      initial: "22:30",
    );

    if (time == null) return;

    setState(() {
      notifications.add({"enabled": true, "time": time});
    });

    saveSchedules();
  }

  Future<void> editNotification(int index) async {
    final current = notifications[index];

    final time = await openTimeInput(
      title: AppStrings.of(context).t("Sửa giờ Reminder"),
      initial: current["time"]?.toString() ?? "22:30",
    );

    if (time == null) return;

    setState(() {
      notifications[index]["time"] = time;
    });

    saveSchedules();
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 12),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isAlarm = widget.type == "alarm";
    final canEditAlarm = widget.canManageHome;
    final canEditCurrentReminder =
        widget.canManageHome || reminderMode == "custom";
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                isAlarm
                    ? strings.t("Hẹn giờ Alarm")
                    : strings.t("Hẹn giờ Reminder"),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isAlarm && isSharedUser) ...[
                const SizedBox(height: 14),

                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: "home",
                      label: Text(strings.t("Theo nhà")),
                      icon: const Icon(Icons.home_rounded),
                    ),
                    ButtonSegment(
                      value: "custom",
                      label: Text(strings.t("Riêng tôi")),
                      icon: const Icon(Icons.person_rounded),
                    ),
                  ],
                  selected: {reminderMode},
                  onSelectionChanged: (value) async {
                    final nextMode = value.first;

                    await FirebaseDatabase.instance
                        .ref(
                          "accounts/$currentUid/customRules/${widget.homeId}/mode",
                        )
                        .set(nextMode);

                    setState(() {
                      reminderMode = nextMode;

                      alarms.clear();
                      notifications.clear();
                    });

                    await load();
                  },
                ),

                const SizedBox(height: 10),

                Text(
                  reminderMode == "home"
                      ? strings.t("Đang sử dụng Reminder của chủ nhà")
                      : strings.t("Đang sử dụng Reminder riêng của bạn"),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              if (isAlarm) ...[
                sectionTitle("Alarm"),

                ...alarms.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),

                      title: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_moon_rounded,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${item["start"]} - ${item["end"]}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              repeatLabel(item["repeatMinutes"]),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: canEditAlarm ? () => editAlarm(i) : null,
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: canEditAlarm
                                ? () async {
                                    setState(() {
                                      alarms.removeAt(i);
                                    });

                                    saveSchedules();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canEditAlarm ? addAlarm : null,
                    icon: const Icon(Icons.add),
                    label: Text(
                      strings.t("Thêm khung giờ Alarm"),
                    ),
                  ),
                ),
              ],

              if (!isAlarm) ...[
                sectionTitle("Reminder"),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.t("Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn."),
                        ),
                      ),
                    ],
                  ),
                ),
                ...notifications.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      trailing: Switch(
                        value: item["enabled"] == true,
                        onChanged: canEditCurrentReminder
                            ? (v) async {
                                setState(() {
                                  notifications[i]["enabled"] = v;
                                });

                                saveSchedules();
                              }
                            : null,
                      ),
                      title: GestureDetector(
                        onTap: canEditCurrentReminder
                            ? () => openReminderOptionSheet(i)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item["time"]?.toString() ?? "--:--",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canEditCurrentReminder ? addNotification : null,
                    icon: const Icon(Icons.add),
                    label: Text(
                      strings.t("Thêm Reminder"),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
