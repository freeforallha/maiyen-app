import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../helpers/top_toast.dart';
import '../helpers/home_helper.dart';
class AllHomePage extends StatefulWidget {
  final List<String> homeOrder;

  const AllHomePage({super.key, required this.homeOrder});

  @override
  State<AllHomePage> createState() => _AllHomePageState();
}

class _AllHomePageState extends State<AllHomePage> {
  bool isAllSafe() {
    if (homes.isEmpty) return true;

    for (final home in homes.values) {
      final devices = safeMap(home["devices"]);

      final unsafe = devices.values.any(
            (d) => d["status"] != "closed" || d["tamper"] == true,
      );

      if (unsafe) return false;
    }

    return true;
  }
  Map<String, dynamic> homes = {};

  Set<String> selectedHomes = {};

  Map<String, String> customNames = {};
  String search = "";
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  int summaryIndex = 0;
  Timer? summaryTimer;

  Map<String, dynamic> safeMap(dynamic data) {

    if (data == null) return {};

    return Map<String, dynamic>.from(data as Map);
  }

  bool isUnsafe(Map dev) {
    return dev.values.any((d) {
      final status = d["status"]?.toString();

      final tamper = d["tamper"] == true;

      return status != "closed" || tamper;
    });
  }
  List<String> buildAllHomeSummaries() {
    int safeCount = 0;
    int warningCount = 0;
    int dangerCount = 0;

    final dangerReasons = <String>{};
    final warningReasons = <String>{};

    for (final home in homes.values) {
      final devices = safeMap(home["devices"]);
      final status = getOverallStatus(devices);
      final level = status["level"]?.toString() ?? "safe";

      if (level == "danger") {
        dangerCount++;

        for (final item in (status["dangerIssues"] as List? ?? [])) {
          dangerReasons.add(item.toString());
        }
      } else if (level == "warning") {
        warningCount++;

        for (final item in (status["warningIssues"] as List? ?? [])) {
          warningReasons.add(item.toString());
        }
      } else {
        safeCount++;
      }
    }

    final summaries = <String>[];

    if (dangerCount > 0) {
      summaries.add(
        "🚨 $dangerCount nhà không an toàn"
            "${dangerReasons.isNotEmpty ? " • ${dangerReasons.first}" : ""}",
      );
    }

    if (warningCount > 0) {
      summaries.add(
        "⚠️ $warningCount nhà cần chú ý"
            "${warningReasons.isNotEmpty ? " • ${warningReasons.first}" : ""}",
      );
    }

    if (safeCount > 0) {
      summaries.add("✅ $safeCount nhà an toàn");
    }

    return summaries.isEmpty ? ["🏡 Chưa có nhà nào"] : summaries;
  }
  void showAllHomeSummarySheet() {
    int sheetIndex = summaryIndex;
    Timer? sheetTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            sheetTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
              setSheetState(() {
                sheetIndex++;
              });
            });

            final safeHomes = <Map<String, dynamic>>[];
            final warningHomes = <Map<String, dynamic>>[];
            final dangerHomes = <Map<String, dynamic>>[];

            for (final entry in homes.entries) {
              final homeId = entry.key;
              final home = safeMap(entry.value);
              final name = home["name"]?.toString() ?? homeId;
              final status = getOverallStatus(safeMap(home["devices"]));
              final level = status["level"]?.toString() ?? "safe";

              final issues = level == "danger"
                  ? (status["dangerIssues"] as List? ?? [])
                  : level == "warning"
                  ? (status["warningIssues"] as List? ?? [])
                  : <dynamic>[];

              final item = {
                "id": homeId,
                "name": name,
                "issues": issues.map((e) => e.toString()).toList(),
              };

              if (level == "danger") {
                dangerHomes.add(item);
              } else if (level == "warning") {
                warningHomes.add(item);
              } else {
                safeHomes.add(item);
              }
            }

            Widget homeRow(Map<String, dynamic> item, Color color) {
              final homeId = item["id"]?.toString() ?? "";
              final name = item["name"]?.toString() ?? "";
              final issues = List<String>.from(item["issues"] ?? []);
              final message = issues.isEmpty
                  ? "Cần kiểm tra"
                  : issues[sheetIndex % issues.length];

              return InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context, homeId);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          child: Text(
                            message,
                            key: ValueKey("$homeId-$message"),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget section({
              required String title,
              required IconData icon,
              required Color color,
              required List<Map<String, dynamic>> items,
              required bool compact,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "$title (${items.length})",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Text(
                        "Không có",
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    else if (compact)
                      ...items.map((e) => homeRow(e, color))
                    else
                      Wrap(
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final homeId = item["id"]?.toString() ?? "";
                          final name = item["name"]?.toString() ?? "";

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pop(context, homeId);
                            },
                            child: Text(
                              index == items.length - 1 ? name : "$name, ",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Tổng hợp trạng thái",
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${homes.length} nhà đang được theo dõi",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    section(
                      title: "Không an toàn",
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                      items: dangerHomes,
                      compact: true,
                    ),
                    section(
                      title: "Cần chú ý",
                      icon: Icons.info_outline_rounded,
                      color: Colors.orange,
                      items: warningHomes,
                      compact: true,
                    ),
                    section(
                      title: "An toàn",
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                      items: safeHomes,
                      compact: false,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      sheetTimer?.cancel();
    });
  }
  StreamSubscription<DatabaseEvent>? ownHomesSubscription;
  StreamSubscription<DatabaseEvent>? sharedHomesSubscription;
  StreamSubscription<DatabaseEvent>? groupNamesSubscription;

  final Map<String, StreamSubscription<DatabaseEvent>> sharedHomeSubscriptions = {};
  @override
  @override
  void initState() {
    super.initState();
    summaryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        summaryIndex++;
      });
    });
    final uid = FirebaseAuth.instance.currentUser!.uid;

    ownHomesSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/homes")
        .onValue
        .listen((event) {
      final ownHomes = event.snapshot.value is Map
          ? Map<String, dynamic>.from(event.snapshot.value as Map)
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        homes.removeWhere((key, value) {
          final home = safeMap(value);
          return home["_shared"] != true;
        });

        for (final entry in ownHomes.entries) {
          homes[entry.key] = entry.value;
        }
      });
    });

    sharedHomesSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/sharedHomes")
        .onValue
        .listen((event) {
      final sharedHomes = event.snapshot.value is Map
          ? Map<String, dynamic>.from(event.snapshot.value as Map)
          : <String, dynamic>{};

      final activeIds = sharedHomes.keys.map((e) => e.toString()).toSet();

      for (final oldId in sharedHomeSubscriptions.keys.toList()) {
        if (!activeIds.contains(oldId)) {
          sharedHomeSubscriptions.remove(oldId)?.cancel();

          if (mounted) {
            setState(() {
              homes.remove(oldId);
            });
          }
        }
      }

      for (final entry in sharedHomes.entries) {
        final homeId = entry.key.toString();
        final sharedInfo = safeMap(entry.value);

        final ownerUid =
            sharedInfo["ownerUid"]?.toString().trim() ?? "";

        final role =
            sharedInfo["role"]?.toString().trim() ?? "member";

        if (ownerUid.isEmpty) {
          continue;
        }

        if (sharedHomeSubscriptions.containsKey(homeId)) {
          continue;
        }

        final sub = FirebaseDatabase.instance
            .ref("accounts/$ownerUid/homes/$homeId")
            .onValue
            .listen(
              (homeEvent) {
            final rawHome = homeEvent.snapshot.value;

            if (rawHome is! Map) {
              if (!mounted) return;

              setState(() {
                homes.remove(homeId);
              });

              return;
            }

            final newHome = {
              ...Map<String, dynamic>.from(rawHome),
              "_shared": true,
              "_ownerUid": ownerUid,
              "_ownerEmail": "",
              "_ownerName": "",
              "_ownerPhotoUrl": "",
              "_role": role,
            };

            if (!mounted) return;

            setState(() {
              homes[homeId] = newHome;
            });
          },
          onError: (Object error) {
            debugPrint(
              "ALL_HOME_SHARED_HOME_ERROR "
                  "$ownerUid/$homeId: $error",
            );
          },
        );

        sharedHomeSubscriptions[homeId] = sub;

        FirebaseDatabase.instance
            .ref("userDirectory/$ownerUid")
            .get()
            .then((directorySnap) {
          final directory = safeMap(directorySnap.value);

          final ownerEmail =
              directory["email"]?.toString().trim() ?? "";

          final ownerName =
              directory["name"]?.toString().trim() ?? "";

          final ownerPhotoUrl =
              directory["photoUrl"]?.toString().trim() ?? "";

          if (!mounted) return;

          setState(() {
            final currentHome = safeMap(homes[homeId]);

            if (currentHome.isEmpty) {
              return;
            }

            homes[homeId] = {
              ...currentHome,
              "_ownerEmail": ownerEmail,
              "_ownerName": ownerName,
              "_ownerPhotoUrl": ownerPhotoUrl,
              "_role": role,
            };
          });
        }).catchError((Object error) {
          debugPrint(
            "ALL_HOME_USER_DIRECTORY_ERROR "
                "$ownerUid: $error",
          );
        });
      }
    });

    groupNamesSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/groupNames")
        .onValue
        .listen((event) {
      final names = event.snapshot.value is Map
          ? Map<String, String>.from(event.snapshot.value as Map)
          : <String, String>{};

      if (!mounted) return;

      setState(() {
        customNames = names;
      });
    });
  }

  Map<String, List<String>> groupedHomes() {
    final Map<String, List<String>> grouped = {};
    final seen = <String>{};
    for (final homeId in widget.homeOrder) {
      if (seen.contains(homeId)) continue;
      seen.add(homeId);
      if (!homes.containsKey(homeId)) continue;
      final data = safeMap(homes[homeId]);
      final name = (data["name"] ?? homeId).toString().toLowerCase();

      if (search.isNotEmpty && !name.contains(search)) {
        continue;
      }

      final isShared = data["_shared"] == true;

      final groupKey = isShared
          ? (data["_ownerUid"] ?? "unknown_uid")
          : "your_homes";

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(homeId);
    }

    return grouped;
  }

  Future<void> renameGroup(String key) async {
    final controller = TextEditingController(text: customNames[key] ?? "");

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Đổi tên nhóm"),

        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "VD: Mr Chung"),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() {
      for (final id in selectedHomes) {
        homes.remove(id);
      }

      selectedHomes.clear();
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseDatabase.instance
        .ref("accounts/$uid/groupNames/$key")
        .set(result);
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }
  Widget buildSectionTitle(String groupKey, List<String> ids) {
    final isYourHomes = groupKey == "your_homes";

    String ownerText = "";
    if (!isYourHomes) {
      final firstHome = safeMap(homes[ids.first]);
      ownerText = firstHome["_ownerEmail"] ?? "Unknown";
    }

    final displayName =
        customNames[groupKey] ?? (isYourHomes ? "Nhà của tôi" : ownerText);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              final allSelected = ids.every(
                    (id) => selectedHomes.contains(id),
              );

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) {
                  return SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.edit_rounded,
                              color: Colors.blueAccent,
                            ),
                            title: const Text("Đổi tên nhóm"),
                            onTap: () {
                              Navigator.pop(context);
                              renameGroup(groupKey);
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              allSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: Colors.green,
                            ),
                            title: Text(
                              allSelected
                                  ? "Bỏ chọn toàn bộ nhóm"
                                  : "Chọn toàn bộ nhóm",
                            ),
                            onTap: () {
                              Navigator.pop(context);

                              setState(() {
                                if (allSelected) {
                                  selectedHomes.removeAll(ids);
                                } else {
                                  selectedHomes.addAll(ids);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 10),
              child: Row(
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "(${ids.length})",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ids.map((homeId) {
              final data = safeMap(homes[homeId]);

              return SizedBox(
                width: 55,
                height: 55,
                child: buildHomeCard(context, homeId, data),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildHomeCard(
    BuildContext context,
    String homeId,
    Map<String, dynamic> data,
  ) {
    final devices = safeMap(data["devices"]);

    final status = getOverallStatus(devices);

    final selected = selectedHomes.contains(homeId);
    return InkWell(
      onTap: () {
        if (selectedHomes.isNotEmpty) {
          setState(() {
            if (selected) {
              selectedHomes.remove(homeId);
            } else {
              selectedHomes.add(homeId);
            }
          });

          return;
        }

        Navigator.pop(context, homeId);
      },

      onLongPress: () {
        setState(() {
          selectedHomes.add(homeId);
        });
      },

      borderRadius: BorderRadius.circular(14),

      child: Container(
        decoration: BoxDecoration(
          color: status["level"] == "danger"
              ? Colors.red.shade300
              : status["level"] == "warning"
              ? Colors.orange.shade300
              : Colors.green.shade300,

          borderRadius: BorderRadius.circular(14),

          border: selected
              ? Border.all(color: Colors.blueAccent, width: 4)
              : null,
        ),

        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(6),

              child: SizedBox.expand(
                child: Center(
                  child: Text(
                    (data["name"] ?? homeId).toString(),

                    textAlign: TextAlign.center,

                    softWrap: true,

                    maxLines: 4,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> setSelectedHomesAlarm() async {
    Future<String?> inputTime(String title, String initial) async {
      final parts = initial.split(":");
      final h = TextEditingController(text: parts[0]);
      final m = TextEditingController(text: parts[1]);

      return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: h,
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Giờ"),
                ),
              ),
              const Text(" : "),
              Expanded(
                child: TextField(
                  controller: m,
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Phút"),
                ),
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
                    "${h.text.trim().padLeft(2, '0')}:${m.text.trim().padLeft(2, '0')}";
                Navigator.pop(context, value);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.orange,
                  ),
                  title: const Text("Đặt Home Reminder"),
                  subtitle: Text("${selectedHomes.length} nhà đã chọn"),
                  onTap: () => Navigator.pop(context, "reminder"),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shield_moon_rounded,
                    color: Colors.red,
                  ),
                  title: const Text("Đặt Home Alarm"),
                  subtitle: Text("${selectedHomes.length} nhà đã chọn"),
                  onTap: () => Navigator.pop(context, "alarm"),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận thay đổi"),
        content: const Text(
          "Thao tác này sẽ thay đổi Home Reminder/Alarm của các nhà đã chọn.\n\n"
              "Những thành viên đang sử dụng chế độ 'Theo nhà' sẽ bị ảnh hưởng.\n"
              "Các cài đặt Reminder/Alarm cá nhân (Riêng tôi) sẽ không bị thay đổi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Tiếp tục"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final updates = <String, dynamic>{};

    int updatedHomes = 0;
    int updatedDevices = 0;
    int skippedHomes = 0;

    if (action == "reminder") {
      final time = await inputTime("Giờ Reminder", "22:30");
      if (time == null) return;

      for (final homeId in selectedHomes) {
        final home = safeMap(homes[homeId]);
        final isShared = home["_shared"] == true;
        final role = home["_role"]?.toString() ?? "member";

        final canManage = !isShared || role == "owner" || role == "admin";

        if (!canManage) {
          skippedHomes++;
          continue;
        }

        final ownerUid = isShared ? home["_ownerUid"]?.toString() ?? uid : uid;
        final schedules = safeMap(home["schedules"]);
        final currentNotificationsRaw = schedules["notifications"];

        final currentNotifications = currentNotificationsRaw is List
            ? List<Map<String, dynamic>>.from(
          currentNotificationsRaw.map(
                (e) => Map<String, dynamic>.from(e),
          ),
        )
            : <Map<String, dynamic>>[];

        currentNotifications.add({
          "enabled": true,
          "time": time,
        });

        updates["accounts/$ownerUid/homes/$homeId/schedules/notifications"] =
            currentNotifications;

        updatedHomes++;
      }
    }

    if (action == "alarm") {
      final start = await inputTime("Giờ bắt đầu Alarm", "23:00");
      if (start == null) return;

      final end = await inputTime("Giờ kết thúc Alarm", "06:00");
      if (end == null) return;

      final alarmData = {
        "enabled": true,
        "start": start,
        "end": end,
        "repeatMinutes": 30,
      };

      for (final homeId in selectedHomes) {
        final home = safeMap(homes[homeId]);
        final isShared = home["_shared"] == true;
        final role = home["_role"]?.toString() ?? "member";

        final canManage = !isShared || role == "owner" || role == "admin";

        if (!canManage) {
          skippedHomes++;
          continue;
        }

        final ownerUid = isShared ? home["_ownerUid"]?.toString() ?? uid : uid;
        final devices = safeMap(home["devices"]);

        var homeUpdated = false;

        for (final entry in devices.entries) {
          final deviceId = entry.key;
          final device = safeMap(entry.value);
          final type = device["type"]?.toString();

          final isSecurity =
              type == "door" || type == "door_lock" || type == "motion";

          if (!isSecurity) continue;

          updates["accounts/$ownerUid/homes/$homeId/devices/$deviceId/alarm"] =
              alarmData;

          updatedDevices++;
          homeUpdated = true;
        }

        if (homeUpdated) {
          updatedHomes++;
        }
      }
    }

    if (updates.isEmpty) {
      showTopToast(
        context,
        "Không có nhà nào đủ điều kiện để cài",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    await FirebaseDatabase.instance.ref().update(updates);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cài đặt hoàn tất"),
        content: Text(
          action == "reminder"
              ? "Đã cài Reminder cho $updatedHomes nhà."
              "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}"
              : "Đã cài Alarm cho $updatedDevices thiết bị trong $updatedHomes nhà."
              "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

    Future<void> confirmDeleteSelected() async {
    final controller = TextEditingController();

    final sharedCount = selectedHomes.where((id) {
      final home = safeMap(homes[id]);

      return home["_shared"] == true;
    }).length;

    final ownCount = selectedHomes.length - sharedCount;

    String message = "";

    if (sharedCount > 0 && ownCount > 0) {
      message =
          "Các home của bạn sẽ bị xoá.\n"
          "Các home được chia sẻ sẽ được rời khỏi.";
    } else if (sharedCount > 0) {
      message = "Bạn sẽ rời khỏi các home được chia sẻ.";
    } else {
      message = "Các home đã chọn sẽ bị xoá vĩnh viễn.";
    }

    final confirmOk = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sharedCount > 0 && ownCount == 0
                      ? Icons.logout_rounded
                      : Icons.warning_amber_rounded,
                  color: sharedCount > 0 && ownCount == 0
                      ? Colors.orange
                      : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  sharedCount > 0 && ownCount == 0
                      ? "Xác nhận rời nhà"
                      : "Xác nhận xoá nhà",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Huỷ"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sharedCount > 0 && ownCount == 0
                              ? Colors.orange
                              : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Tiếp tục"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmOk != true) return;

    final passwordOk = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.red,
                  size: 44,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Nhập mật khẩu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu tài khoản",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      sharedCount > 0 && ownCount == 0
                          ? Icons.logout_rounded
                          : Icons.delete_forever_rounded,
                    ),
                    label: Text(
                      sharedCount > 0 && ownCount == 0
                          ? "Rời khỏi nhà"
                          : "Xoá nhà",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sharedCount > 0 && ownCount == 0
                          ? Colors.orange
                          : Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser!;

                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: controller.text.trim(),
                        );

                        await user.reauthenticateWithCredential(credential);

                        Navigator.pop(context, true);
                      } catch (e) {
                        showTopToast(
                          context,
                          "Sai mật khẩu",
                          color: Colors.red,
                          icon: Icons.error_outline_rounded,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (passwordOk != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);

      final isShared = home["_shared"] == true;
      // ===== HOME ĐƯỢC SHARE =====
      if (isShared) {
        final ownerUid = home["_ownerUid"];

        await FirebaseDatabase.instance
            .ref("accounts/$uid/sharedHomes/$homeId")
            .remove();

        await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId/$uid")
            .remove();

        // 🔥 remove khỏi share list của owner
        await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareList/$homeId/$uid")
            .remove();
      }
      // ===== HOME CỦA MÌNH =====
      else {
        final accountsSnap = await FirebaseDatabase.instance
            .ref("accounts")
            .get();

        if (accountsSnap.exists) {
          final accounts = Map<String, dynamic>.from(accountsSnap.value as Map);

          for (final entry in accounts.entries) {
            final otherUid = entry.key;

            await FirebaseDatabase.instance
                .ref("accounts/$otherUid/sharedHomes/$homeId")
                .remove();
          }
        }

        await FirebaseDatabase.instance
            .ref("accounts/$uid/homes/$homeId")
            .remove();
      }
    }

    setState(() {
      selectedHomes.clear();
    });

    showTopToast(
      context,
      sharedCount > 0 && ownCount == 0 ? "Đã rời khỏi home" : "Đã cập nhật",
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedHomes();

    return Scaffold(
      backgroundColor: const Color(0xFFDDF7E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Tìm home...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              search = value.toLowerCase().trim();
            });
          },
        )
            : InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: showAllHomeSummarySheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Text(
                buildAllHomeSummaries()[
                summaryIndex % buildAllHomeSummaries().length],
                key: ValueKey(
                  buildAllHomeSummaries()[
                  summaryIndex % buildAllHomeSummaries().length],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  search = "";
                  searchController.clear();
                }
              });
            },
          ),

          if (selectedHomes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => selectedHomes.clear());
              },
            ),
        ],
      ),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFDDF7E8),
                  Color(0xFFF1FCF5),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                10,
                selectedHomes.isEmpty ? 10 : 370,
              ),
              children: grouped.entries.map((entry) {
                final groupKey = entry.key;
                final ids = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle(groupKey, ids),
                    const SizedBox(height: 6),
                  ],
                );
              }).toList(),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 12,
            right: 12,
            bottom: selectedHomes.isEmpty ? -360 : 12,
            child: SafeArea(
              top: false,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selectedHomes.isEmpty ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: const Text(
                          "Đặt Reminder / Alarm nhà đã chọn",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("${selectedHomes.length} nhà đã chọn"),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: setSelectedHomesAlarm,
                      ),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.share_rounded, color: Colors.green),
                        ),
                        title: const Text(
                          "Chia sẻ nhà đã chọn",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("${selectedHomes.length} nhà đã chọn"),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final controller = TextEditingController();
                          final ownerUid = FirebaseAuth.instance.currentUser!.uid;

                          final qrData =
                              "safehome_join_multi|$ownerUid|${selectedHomes.join(",")}";

                          final targetEmail = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) {
                              return SafeArea(
                                child: Container(
                                  padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 20,
                                    bottom:
                                    MediaQuery.of(context).viewInsets.bottom + 20,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(26),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
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
                                      const Text(
                                        "Chia sẻ nhà đã chọn",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Text(
                                        "Hoặc quét QR để xin gia nhập các nhà đã chọn",
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 12),
                                      QrImageView(
                                        data: qrData,
                                        version: QrVersions.auto,
                                        size: 190,
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        "${selectedHomes.length} nhà đã chọn",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          prefixIcon:
                                          const Icon(Icons.email_rounded),
                                          labelText: "Email người nhận",
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.share_rounded),
                                          label: const Text("Chia sẻ"),
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              controller.text.trim().toLowerCase(),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (targetEmail == null || targetEmail.isEmpty) return;

                          final accountsSnap =
                          await FirebaseDatabase.instance.ref("accounts").get();

                          String? targetUid;

                          if (accountsSnap.exists) {
                            final accounts =
                            Map<String, dynamic>.from(accountsSnap.value as Map);

                            for (final entry in accounts.entries) {
                              final data = Map<String, dynamic>.from(entry.value);
                              final mail =
                              data["email"]?.toString().trim().toLowerCase();

                              if (mail == targetEmail) {
                                targetUid = entry.key;
                                break;
                              }
                            }
                          }

                          if (targetUid == null) {
                            showTopToast(
                              context,
                              "Email chưa đăng ký",
                              color: Colors.red,
                              icon: Icons.error_outline_rounded,
                            );
                            return;
                          }

                          final myUid = FirebaseAuth.instance.currentUser!.uid;
                          int skipped = 0;

                          for (final homeId in selectedHomes) {
                            final home = safeMap(homes[homeId]);
                            final role = home["_role"]?.toString() ?? "member";

                            final canShare = home["_shared"] != true ||
                                role == "owner" ||
                                role == "admin";

                            if (!canShare) {
                              skipped++;
                              continue;
                            }

                            await FirebaseDatabase.instance
                                .ref("accounts/$targetUid/shareRequests/$homeId")
                                .set({
                              "ownerUid": myUid,
                              "homeId": homeId,
                              "ownerEmail":
                              FirebaseAuth.instance.currentUser?.email ?? "",
                              "time": DateTime.now().millisecondsSinceEpoch,
                            });

                            await FirebaseDatabase.instance
                                .ref("accounts/$myUid/shareList/$homeId/$targetUid")
                                .set({
                              "email": targetEmail,
                              "sharedAt": DateTime.now().millisecondsSinceEpoch,
                            });
                          }

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Chia sẻ hoàn tất"),
                              content: Text(
                                skipped > 0
                                    ? "Đã chia sẻ các nhà bạn có quyền.\n\n$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ."
                                    : "Đã chia sẻ nhà thành công.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const Divider(height: 8),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        title: const Text(
                          "Mở List chia sẻ nhà",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("${selectedHomes.length} nhà đã chọn"),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final uid = FirebaseAuth.instance.currentUser!.uid;

                          final ownHomes = selectedHomes.where((id) {
                            final home = safeMap(homes[id]);
                            final role = home["role"]?.toString();

                            return home["_shared"] != true ||
                                role == "owner" ||
                                role == "admin";
                          }).toList();

                          if (ownHomes.isEmpty) {
                            showTopToast(
                              context,
                              "Không có nhà nào bạn có quyền quản lý",
                              color: Colors.orange,
                              icon: Icons.lock_rounded,
                            );
                            return;
                          }

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) {
                              return StatefulBuilder(
                                builder: (context, setSheetState) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    constraints: BoxConstraints(
                                      maxHeight:
                                      MediaQuery.of(context).size.height * 0.8,
                                    ),
                                    child: FutureBuilder(
                                      future: FirebaseDatabase.instance
                                          .ref("accounts/$uid/shareList")
                                          .get(),
                                      builder: (context, snap) {
                                        if (!snap.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final raw = snap.data!.value == null
                                            ? {}
                                            : Map<String, dynamic>.from(
                                          snap.data!.value as Map,
                                        );

                                        return ListView(
                                          children: ownHomes.map((homeId) {
                                            final home = safeMap(homes[homeId]);
                                            final homeName =
                                                home["name"]?.toString() ?? homeId;
                                            final users = safeMap(raw[homeId]);

                                            return Container(
                                              margin:
                                              const EdgeInsets.only(bottom: 16),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(18),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    homeName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  if (users.isEmpty)
                                                    const Text(
                                                      "Chưa share cho ai",
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ...users.entries.map((e) {
                                                    final targetUid = e.key;
                                                    final data =
                                                    Map<String, dynamic>.from(
                                                      e.value,
                                                    );

                                                    final email =
                                                        data["email"] ?? "Unknown";

                                                    return Container(
                                                      margin: const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        borderRadius:
                                                        BorderRadius.circular(14),
                                                      ),
                                                      child: ListTile(
                                                        dense: true,
                                                        leading: const CircleAvatar(
                                                          radius: 16,
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        title: Text(email),
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                            Icons.delete_rounded,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed: () async {
                                                            await FirebaseDatabase
                                                                .instance
                                                                .ref(
                                                              "accounts/$targetUid/sharedHomes/$homeId",
                                                            )
                                                                .remove();

                                                            await FirebaseDatabase
                                                                .instance
                                                                .ref(
                                                              "accounts/$uid/shareList/$homeId/$targetUid",
                                                            )
                                                                .remove();

                                                            setSheetState(() {
                                                              users.remove(targetUid);
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),

                      const Divider(height: 8),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.red),
                        ),
                        title: const Text(
                          "Xoá các nhà đã chọn ?",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Text("${selectedHomes.length} nhà đã chọn"),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: confirmDeleteSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    ownHomesSubscription?.cancel();
    sharedHomesSubscription?.cancel();
    groupNamesSubscription?.cancel();

    for (final sub in sharedHomeSubscriptions.values) {
      sub.cancel();
    }

    sharedHomeSubscriptions.clear();
    summaryTimer?.cancel();
    searchController.dispose();

    super.dispose();
  }
}
