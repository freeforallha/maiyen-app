import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../helpers/top_toast.dart';
import '../helpers/home_helper.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';
import '../services/home_realtime_coordinator.dart';
import 'package:safehome_app/helpers/debug_log.dart';

class AllHomePage extends StatefulWidget {
  final List<String> homeOrder;

  const AllHomePage({super.key, required this.homeOrder});

  @override
  State<AllHomePage> createState() => _AllHomePageState();
}

class _AllHomePageState extends State<AllHomePage> {
  AppStrings get _strings => AppStrings.of(context);
  Map<String, dynamic> homes = {};
  Map<String, int> unreadChatCounts = {};
  final HomeRealtimeCoordinator _homeRealtimeCoordinator =
      HomeRealtimeCoordinator();
  String _chatUnreadUid = "";
  final ValueNotifier<int> homesRevision = ValueNotifier<int>(0);

  Set<String> selectedHomes = {};

  Map<String, String> customNames = {};
  String search = "";
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  int summaryIndex = 0;
  Timer? summaryTimer;

  String selectedHomeCountText([int? count]) {
    final value = count ?? selectedHomes.length;

    return _strings.selectedHomesCountText(value);
  }

  List<String> buildAllHomeSummaries() {
    int safeCount = 0;
    int warningCount = 0;
    int dangerCount = 0;

    final dangerReasons = <String>{};
    final warningReasons = <String>{};

    for (final home in homes.values) {
      final status = getHomeOverallStatus(home);
      final level = status["level"]?.toString() ?? "safe";

      if (level == "danger") {
        dangerCount++;

        for (final item in (status["dangerIssues"] as List? ?? [])) {
          dangerReasons.add(_strings.statusText(item.toString()));
        }
      } else if (level == "warning") {
        warningCount++;

        for (final item in (status["warningIssues"] as List? ?? [])) {
          warningReasons.add(_strings.statusText(item.toString()));
        }
      } else {
        safeCount++;
      }
    }

    final summaries = <String>[];

    if (dangerCount > 0) {
      summaries.add(
        _strings.allHomeDangerCountText(
          dangerCount,
          reason: dangerReasons.isNotEmpty ? dangerReasons.first : "",
        ),
      );
    }

    if (warningCount > 0) {
      summaries.add(
        _strings.allHomeWarningCountText(
          warningCount,
          reason: warningReasons.isNotEmpty ? warningReasons.first : "",
        ),
      );
    }

    if (safeCount > 0) {
      summaries.add(_strings.allHomeSafeCountText(safeCount));
    }

    return summaries.isEmpty ? [_strings.t("🏡 Chưa có nhà nào")] : summaries;
  }

  void showAllHomeSummarySheet() {
    int sheetIndex = summaryIndex;
    Timer? sheetTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ValueListenableBuilder<int>(
          valueListenable: homesRevision,
          builder: (context, _, _) {
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
                  final status = getHomeOverallStatus(home);
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
                      ? _strings.t("Cần kiểm tra")
                      : _strings.statusText(issues[sheetIndex % issues.length]);

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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
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
                            _strings.t("Không có"),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
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
                        Text(
                          _strings.t("Tổng hợp trạng thái"),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _strings.monitoredHomesCountText(homes.length),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        section(
                          title: _strings.t("Không an toàn"),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                          items: dangerHomes,
                          compact: true,
                        ),
                        section(
                          title: _strings.t("Cần chú ý"),
                          icon: Icons.info_outline_rounded,
                          color: Colors.orange,
                          items: warningHomes,
                          compact: true,
                        ),
                        section(
                          title: _strings.t("An toàn"),
                          icon: Icons.check_circle_rounded,
                          color: SafeHomeColors.safe,
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
        );
      },
    ).whenComplete(() {
      sheetTimer?.cancel();
    });
  }

  StreamSubscription<DatabaseEvent>? ownHomesSubscription;
  StreamSubscription<DatabaseEvent>? sharedHomesSubscription;
  StreamSubscription<DatabaseEvent>? groupNamesSubscription;
  StreamSubscription<User?>? chatAuthSubscription;

  final Map<String, StreamSubscription<DatabaseEvent>> sharedHomeSubscriptions =
      {};

  void notifyHomesChanged() {
    if (!mounted) return;
    homesRevision.value = homesRevision.value + 1;
    syncChatUnreadCounts();
  }

  void syncChatUnreadCounts() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (!mounted || currentUid.isEmpty) {
      return;
    }

    if (_chatUnreadUid != currentUid) {
      _chatUnreadUid = currentUid;

      if (unreadChatCounts.isNotEmpty) {
        setState(() {
          unreadChatCounts = {};
        });
      }
    }

    _homeRealtimeCoordinator.syncHomeChatListeners(
      uid: currentUid,
      homes: homes,
      onUnreadChanged: (snapshot) {
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != currentUid) {
          return;
        }

        final nextCounts = snapshot.unreadByHome;
        final unchanged =
            nextCounts.length == unreadChatCounts.length &&
            nextCounts.entries.every(
              (entry) => unreadChatCounts[entry.key] == entry.value,
            );

        if (unchanged) {
          return;
        }

        setState(() {
          unreadChatCounts = nextCounts;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    summaryTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        summaryIndex++;
      });
    });
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;

    syncChatUnreadCounts();
    chatAuthSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (!mounted) return;

      if (user == null) {
        _homeRealtimeCoordinator.dispose();
        _chatUnreadUid = "";

        if (unreadChatCounts.isNotEmpty) {
          setState(() {
            unreadChatCounts = {};
          });
        }

        return;
      }

      syncChatUnreadCounts();
    });

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
          notifyHomesChanged();
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
                notifyHomesChanged();
              }
            }
          }

          for (final entry in sharedHomes.entries) {
            final homeId = entry.key.toString();
            final sharedInfo = safeMap(entry.value);

            final ownerUid = sharedInfo["ownerUid"]?.toString().trim() ?? "";

            final role = sharedInfo["role"]?.toString().trim() ?? "member";

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
                      notifyHomesChanged();

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
                    notifyHomesChanged();
                  },
                  onError: (Object error) {
                    safeDebugPrint("ALL_HOME_SHARED_HOME_ERROR: $error");
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

                  final ownerName = directory["name"]?.toString().trim() ?? "";

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
                  notifyHomesChanged();
                })
                .catchError((Object error) {
                  safeDebugPrint("ALL_HOME_USER_DIRECTORY_ERROR: $error");
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

      grouped.putIfAbsent(groupKey, () => []).add(homeId);
    }

    return grouped;
  }

  Future<void> renameGroup(String key) async {
    final oldName = customNames[key] ?? "";
    String inputName = oldName.trim();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_strings.t("Đổi tên nhóm")),
        content: TextFormField(
          initialValue: oldName,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: _strings.t("VD: Mr Chung")),
          onChanged: (value) {
            inputName = value.trim();
          },
          onFieldSubmitted: (_) {
            Navigator.pop(dialogContext, inputName);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, inputName);
            },
            child: Text(_strings.t("Lưu")),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      for (final id in selectedHomes) {
        homes.remove(id);
      }

      selectedHomes.clear();
    });

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;
    final newName = result.trim();

    final ref = FirebaseDatabase.instance.ref("accounts/$uid/groupNames/$key");

    if (newName.isEmpty) {
      await ref.remove();
    } else {
      await ref.set(newName);
    }
  }

  Widget buildSectionTitle(String groupKey, List<String> ids) {
    final isYourHomes = groupKey == "your_homes";

    String ownerText = "";

    if (!isYourHomes && ids.isNotEmpty) {
      final firstHome = safeMap(homes[ids.first]);
      ownerText = firstHome["_ownerEmail"]?.toString() ?? "Unknown";
    }

    final displayName =
        customNames[groupKey] ??
        (isYourHomes ? _strings.t("Nhà của tôi") : ownerText);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              final allSelected = ids.every(selectedHomes.contains);

              showModalBottomSheet(
                context: context,
                showDragHandle: false,
                backgroundColor: Colors.transparent,
                builder: (_) {
                  return SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      decoration: const BoxDecoration(
                        color: SafeHomeColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
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
                            leading: const Icon(
                              Icons.edit_rounded,
                              color: SafeHomeColors.info,
                            ),
                            title: Text(_strings.t("Đổi tên nhóm")),
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
                              color: SafeHomeColors.primary,
                            ),
                            title: Text(
                              allSelected
                                  ? _strings.t("Bỏ chọn toàn bộ nhóm")
                                  : _strings.t("Chọn toàn bộ nhóm"),
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
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: SafeHomeColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "(${ids.length})",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: SafeHomeColors.textSecondary,
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
              final unreadCount = unreadChatCounts[homeId] ?? 0;

              return SizedBox(
                width: 55,
                height: 55,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: buildHomeCard(context, homeId, data),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: buildUnreadChatBadge(unreadCount),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildUnreadChatBadge(int unreadCount) {
    return IgnorePointer(
      child: Container(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SafeHomeColors.danger,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SafeHomeColors.surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          unreadCount > 99 ? "99+" : unreadCount.toString(),
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget buildHomeCard(
    BuildContext context,
    String homeId,
    Map<String, dynamic> data,
  ) {
    final status = getHomeOverallStatus(data);
    final level = status["level"]?.toString() ?? "safe";
    final selected = selectedHomes.contains(homeId);

    final statusColor = level == "danger"
        ? SafeHomeColors.danger
        : level == "warning"
        ? SafeHomeColors.warning
        : SafeHomeColors.safe;

    final rawName = data["_customName"] ?? data["name"] ?? homeId;

    final displayName = rawName.toString().trim().isEmpty
        ? _strings.t("Nhà")
        : rawName.toString().trim();

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? SafeHomeColors.primarySoft : SafeHomeColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? SafeHomeColors.primary
                : statusColor.withValues(alpha: 0.68),
            width: selected ? 2.4 : 1.25,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 1,
                bottom: 1,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: SafeHomeColors.primary,
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

      bool isValidTime(String value) {
        return RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(value.trim());
      }

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
                    _strings.t("Giờ không hợp lệ"),
                    color: Colors.red,
                    icon: Icons.schedule_rounded,
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(value);
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
                            key: ValueKey("all_home_alarm_hour_$hourText"),
                            initialValue: hourText,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            maxLength: 2,
                            decoration: InputDecoration(
                              labelText: _strings.t("Giờ"),
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
                            key: ValueKey("all_home_alarm_minute_$minuteText"),
                            initialValue: minuteText,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 2,
                            decoration: InputDecoration(
                              labelText: _strings.t("Phút"),
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
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(_strings.t("Huỷ")),
                  ),
                  ElevatedButton(
                    onPressed: submit,
                    child: Text(_strings.t("OK")),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    String repeatLabel(int minutes) {
      if (minutes <= 0) {
        return _strings.t("Không lặp lại");
      }

      return _strings.minuteText(minutes);
    }

    Future<Map<String, dynamic>?> inputAlarmConfig() async {
      var start = "23:00";
      var end = "06:00";
      var repeatMinutes = 30;
      final selectedDays = <int>{1, 2, 3, 4, 5, 6, 7};

      final dayItems = [
        (
          value: 1,
          label: _strings.choose(
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
          ),
        ),
        (
          value: 2,
          label: _strings.choose(
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
          ),
        ),
        (
          value: 3,
          label: _strings.choose(
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
          ),
        ),
        (
          value: 4,
          label: _strings.choose(
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
          ),
        ),
        (
          value: 5,
          label: _strings.choose(
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
          ),
        ),
        (
          value: 6,
          label: _strings.choose(
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
          ),
        ),
        (
          value: 7,
          label: _strings.choose(
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
          ),
        ),
      ];

      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (innerContext, setSheetState) {
              Future<void> chooseTime(bool isStart) async {
                final picked = await inputTime(
                  isStart
                      ? _strings.t("Giờ bắt đầu Alarm")
                      : _strings.t("Giờ kết thúc Alarm"),
                  isStart ? start : end,
                );

                if (picked == null || !sheetContext.mounted) {
                  return;
                }

                setSheetState(() {
                  if (isStart) {
                    start = picked;
                  } else {
                    end = picked;
                  }
                });
              }

              void toggleDay(int day) {
                setSheetState(() {
                  if (selectedDays.contains(day)) {
                    // Giữ tối thiểu một ngày để lịch Alarm luôn hợp lệ.
                    if (selectedDays.length > 1) {
                      selectedDays.remove(day);
                    }
                  } else {
                    selectedDays.add(day);
                  }
                });
              }

              Widget timeButton({
                required String label,
                required String value,
                required VoidCallback onTap,
              }) {
                return Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SafeHomeColors.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: SafeHomeColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            style: const TextStyle(
                              color: SafeHomeColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              Widget dayButton(int value, String label) {
                final selected = selectedDays.contains(value);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => toggleDay(value),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 42,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? SafeHomeColors.primary.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? SafeHomeColors.primary.withValues(alpha: 0.55)
                                : SafeHomeColors.border,
                            width: selected ? 1.3 : 1,
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
                                    ? SafeHomeColors.primary
                                    : SafeHomeColors.textPrimary,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SafeArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(innerContext).viewInsets.bottom,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(innerContext).size.height * 0.92,
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                                      _strings.t("Đặt Home Alarm"),
                                      style: const TextStyle(
                                        color: SafeHomeColors.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      selectedHomeCountText(),
                                      style: const TextStyle(
                                        color: SafeHomeColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              timeButton(
                                label: _strings.t("Bắt đầu"),
                                value: start,
                                onTap: () => chooseTime(true),
                              ),
                              const SizedBox(width: 10),
                              timeButton(
                                label: _strings.t("Kết thúc"),
                                value: end,
                                onTap: () => chooseTime(false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: SafeHomeColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SafeHomeColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _strings.t("Thời gian lặp lại"),
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
                                      value: repeatMinutes,
                                      isExpanded: true,
                                      alignment: Alignment.centerRight,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: SafeHomeColors.textSecondary,
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text(
                                            _strings.t("Không lặp lại"),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 15,
                                          child: Text(_strings.t("15 phút")),
                                        ),
                                        DropdownMenuItem(
                                          value: 30,
                                          child: Text(_strings.t("30 phút")),
                                        ),
                                        DropdownMenuItem(
                                          value: 60,
                                          child: Text(_strings.t("60 phút")),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) {
                                          return;
                                        }

                                        setSheetState(() {
                                          repeatMinutes = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
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
                                    _strings.t("Ngày trong tuần"),
                                    style: const TextStyle(
                                      color: SafeHomeColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Row(
                                  children: [
                                    dayButton(
                                      dayItems[0].value,
                                      dayItems[0].label,
                                    ),
                                    dayButton(
                                      dayItems[1].value,
                                      dayItems[1].label,
                                    ),
                                    dayButton(
                                      dayItems[2].value,
                                      dayItems[2].label,
                                    ),
                                    dayButton(
                                      dayItems[3].value,
                                      dayItems[3].label,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    dayButton(
                                      dayItems[4].value,
                                      dayItems[4].label,
                                    ),
                                    dayButton(
                                      dayItems[5].value,
                                      dayItems[5].label,
                                    ),
                                    dayButton(
                                      dayItems[6].value,
                                      dayItems[6].label,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: SafeHomeColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                final days = selectedDays.toList()..sort();

                                Navigator.pop(sheetContext, {
                                  "start": start,
                                  "end": end,
                                  "repeatMinutes": repeatMinutes,
                                  "days": days,
                                });
                              },
                              icon: const Icon(Icons.done_all_rounded),
                              label: Text(_strings.t("Xác nhận")),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (actionSheetContext) {
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
                  title: Text(_strings.t("Đặt Home Reminder")),
                  subtitle: Text(selectedHomeCountText()),
                  onTap: () => Navigator.pop(actionSheetContext, "reminder"),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shield_moon_rounded,
                    color: Colors.red,
                  ),
                  title: Text(_strings.t("Đặt Home Alarm")),
                  subtitle: Text(selectedHomeCountText()),
                  onTap: () => Navigator.pop(actionSheetContext, "alarm"),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    if (!mounted) return;

    // Chờ bottom sheet đóng hoàn toàn trước khi mở dialog kế tiếp.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final isReminderAction = action == "reminder";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmDialogContext) => AlertDialog(
        title: Text(
          isReminderAction
              ? _strings.t("Xác nhận thay đổi Reminder")
              : _strings.t("Xác nhận thay đổi Alarm"),
        ),
        content: Text(
          isReminderAction
              ? _strings.t(
                  "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.",
                )
              : _strings.t(
                  "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.",
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmDialogContext, false),
            child: Text(_strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(confirmDialogContext, true),
            child: Text(_strings.t("Tiếp tục")),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Tránh mở dialog chọn giờ khi dialog xác nhận vẫn đang chạy animation đóng.
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;
    final updates = <String, dynamic>{};

    int updatedHomes = 0;
    int updatedDevices = 0;
    int skippedHomes = 0;
    int selectedAlarmRepeatMinutes = 30;

    if (action == "reminder") {
      final time = await inputTime(_strings.t("Giờ Reminder"), "22:30");
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

        currentNotifications.add({"enabled": true, "time": time});

        updates["accounts/$ownerUid/homes/$homeId/schedules/notifications"] =
            currentNotifications;

        updatedHomes++;
      }
    }

    if (action == "alarm") {
      final alarmConfig = await inputAlarmConfig();
      if (alarmConfig == null) return;

      final repeatMinutes =
          (alarmConfig["repeatMinutes"] as num?)?.toInt() ?? 30;

      selectedAlarmRepeatMinutes = repeatMinutes;

      final alarmData = {
        "enabled": true,
        "start": alarmConfig["start"]?.toString() ?? "23:00",
        "end": alarmConfig["end"]?.toString() ?? "06:00",
        "repeatMinutes": repeatMinutes,
        "days": List<int>.from(
          alarmConfig["days"] as List? ?? const [1, 2, 3, 4, 5, 6, 7],
        ),
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

          final isSecurity = isSecurityDeviceType(type);

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
    if (!mounted) return;
    if (updates.isEmpty) {
      showTopToast(
        context,
        _strings.t("Không có nhà nào đủ điều kiện để cài"),
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    await FirebaseDatabase.instance.ref().update(updates);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_strings.t("Cài đặt hoàn tất")),
        content: Text(
          action == "reminder"
              ? _strings.allHomeReminderAppliedText(updatedHomes, skippedHomes)
              : _strings.allHomeAlarmAppliedText(
                  updatedDevices: updatedDevices,
                  updatedHomes: updatedHomes,
                  repeatLabel: repeatLabel(selectedAlarmRepeatMinutes),
                  skippedHomes: skippedHomes,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_strings.t("OK")),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDeleteSelected() async {
    final sharedCount = selectedHomes.where((id) {
      final home = safeMap(homes[id]);

      return home["_shared"] == true;
    }).length;

    final ownCount = selectedHomes.length - sharedCount;

    String message = "";

    if (sharedCount > 0 && ownCount > 0) {
      message = _strings.t(
        "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.",
      );
    } else if (sharedCount > 0) {
      message = _strings.t("Bạn sẽ rời khỏi các nhà được chia sẻ.");
    } else {
      message = _strings.t("Các nhà đã chọn sẽ bị xoá vĩnh viễn.");
    }

    final confirmOk = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
                      ? _strings.t("Xác nhận rời nhà")
                      : _strings.t("Xác nhận xoá nhà"),
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
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(_strings.t("Huỷ")),
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
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(_strings.t("Tiếp tục")),
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
    if (!mounted) return;

    String inputPassword = "";

    final passwordOk = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final passwordOk = inputPassword.trim().isNotEmpty;

            Future<void> submit() async {
              if (!passwordOk) return;

              try {
                final user = FirebaseAuth.instance.currentUser;
                final userEmail = user?.email;

                if (user == null || userEmail == null || userEmail.isEmpty) {
                  if (!sheetContext.mounted) return;

                  showTopToast(
                    sheetContext,
                    _strings.t("Không tìm thấy tài khoản"),
                    color: Colors.red,
                    icon: Icons.error_outline_rounded,
                  );
                  return;
                }

                final credential = EmailAuthProvider.credential(
                  email: userEmail,
                  password: inputPassword.trim(),
                );

                await user.reauthenticateWithCredential(credential);

                if (!sheetContext.mounted) return;

                Navigator.pop(sheetContext, true);
              } catch (e) {
                if (!sheetContext.mounted) return;

                showTopToast(
                  sheetContext,
                  _strings.t("Sai mật khẩu"),
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                );
              }
            }

            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.red,
                          size: 44,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _strings.t("Nhập mật khẩu"),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          autofocus: true,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: _strings.t("Mật khẩu tài khoản"),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            inputPassword = value.trim();
                            setSheetState(() {});
                          },
                          onFieldSubmitted: (_) => submit(),
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
                                  ? _strings.t("Rời khỏi nhà")
                                  : _strings.t("Xoá nhà"),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sharedCount > 0 && ownCount == 0
                                  ? Colors.orange
                                  : Colors.red,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                            ),
                            onPressed: passwordOk ? submit : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (passwordOk != true) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);

      final isShared = home["_shared"] == true;

      if (isShared) {
        final ownerUid = home["_ownerUid"];

        await FirebaseDatabase.instance
            .ref("accounts/$uid/sharedHomes/$homeId")
            .remove();

        await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId/$uid")
            .remove();

        await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareList/$homeId/$uid")
            .remove();
      } else {
        final sharedSnap = await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId")
            .get();

        final sharedUsers = sharedSnap.value is Map
            ? Map<String, dynamic>.from(sharedSnap.value as Map)
            : <String, dynamic>{};

        final updates = <String, Object?>{
          "accounts/$uid/homes/$homeId": null,
          "accounts/$uid/shareList/$homeId": null,
        };

        for (final memberUid in sharedUsers.keys) {
          updates["accounts/$memberUid/sharedHomes/$homeId"] = null;
          updates["sharedByHome/$homeId/$memberUid"] = null;
        }

        await FirebaseDatabase.instance.ref().update(updates);
      }
    }

    if (!mounted) return;

    setState(() {
      selectedHomes.clear();
    });

    showTopToast(
      context,
      sharedCount > 0 && ownCount == 0
          ? _strings.t("Đã rời khỏi nhà")
          : _strings.t("Đã cập nhật"),
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedHomes();

    return Scaffold(
      backgroundColor: SafeHomeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 54,

        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: _strings.t("Quay lại"),
            onPressed: () {
              Navigator.maybePop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style:
                IconButton.styleFrom(
                  foregroundColor: SafeHomeColors.textPrimary,
                  backgroundColor: Colors.transparent,
                  shape: const CircleBorder(),
                ).copyWith(
                  overlayColor: WidgetStatePropertyAll(
                    SafeHomeColors.primary.withValues(alpha: 0.10),
                  ),
                ),
          ),
        ),

        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: _strings.t("Tìm nhà..."),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  setState(() {
                    search = value.toLowerCase().trim();
                  });
                },
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: showAllHomeSummarySheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        children: [
                          TextSpan(
                            text: "Safe",
                            style: TextStyle(color: SafeHomeColors.primary),
                          ),
                          TextSpan(
                            text: "All",
                            style: TextStyle(color: SafeHomeColors.textPrimary),
                          ),
                          TextSpan(
                            text: "Home",
                            style: TextStyle(color: SafeHomeColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

        actions: [
          IconButton(
            tooltip: isSearching
                ? _strings.t("Đóng tìm kiếm")
                : _strings.t("Tìm nhà"),
            icon: Icon(
              isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 23,
            ),
            style:
                IconButton.styleFrom(
                  foregroundColor: SafeHomeColors.textPrimary,
                  backgroundColor: Colors.transparent,
                  shape: const CircleBorder(),
                ).copyWith(
                  overlayColor: WidgetStatePropertyAll(
                    SafeHomeColors.primary.withValues(alpha: 0.10),
                  ),
                ),
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
              tooltip: _strings.t("Bỏ chọn"),
              icon: const Icon(Icons.deselect_rounded, size: 22),
              style:
                  IconButton.styleFrom(
                    foregroundColor: SafeHomeColors.danger,
                    backgroundColor: Colors.transparent,
                    shape: const CircleBorder(),
                  ).copyWith(
                    overlayColor: WidgetStatePropertyAll(
                      SafeHomeColors.danger.withValues(alpha: 0.10),
                    ),
                  ),
              onPressed: () {
                setState(() {
                  selectedHomes.clear();
                });
              },
            ),

          const SizedBox(width: 6),
        ],
      ),

      body: Stack(
        children: [
          Container(
            color: SafeHomeColors.background,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                6,
                12,
                selectedHomes.isEmpty ? 16 : 370,
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
                        title: Text(
                          _strings.t("Đặt Reminder / Alarm nhà đã chọn"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(selectedHomeCountText()),
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
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          _strings.t("Chia sẻ nhà đã chọn"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(selectedHomeCountText()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          String targetEmailText = "";
                          final currentUser = FirebaseAuth.instance.currentUser;

                          if (currentUser == null) {
                            return;
                          }

                          final ownerUid = currentUser.uid;

                          final qrData =
                              "safehome_join_multi|$ownerUid|${selectedHomes.join(",")}";

                          final targetEmail = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (sheetContext) {
                              return StatefulBuilder(
                                builder: (context, setSheetState) {
                                  final bottomInset = MediaQuery.of(
                                    sheetContext,
                                  ).viewInsets.bottom;
                                  final keyboardOpen = bottomInset > 0;
                                  final qrSize = keyboardOpen ? 140.0 : 190.0;
                                  final emailOk = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(targetEmailText);

                                  return SafeArea(
                                    child: AnimatedPadding(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      padding: EdgeInsets.only(
                                        bottom: bottomInset,
                                      ),
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              MediaQuery.of(
                                                sheetContext,
                                              ).size.height *
                                              0.92,
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          20,
                                          20,
                                          20,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(26),
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                _strings.t(
                                                  "Chia sẻ nhà đã chọn",
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              Text(
                                                _strings.t(
                                                  "Hoặc quét QR để xin gia nhập các nhà đã chọn",
                                                ),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              QrImageView(
                                                data: qrData,
                                                version: QrVersions.auto,
                                                size: qrSize,
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                selectedHomeCountText(),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              TextFormField(
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                textInputAction:
                                                    TextInputAction.done,
                                                decoration: InputDecoration(
                                                  prefixIcon: const Icon(
                                                    Icons.email_rounded,
                                                  ),
                                                  labelText: _strings.t(
                                                    "Email người nhận",
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      Colors.grey.shade100,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  setSheetState(() {
                                                    targetEmailText = value
                                                        .trim()
                                                        .toLowerCase();
                                                  });
                                                },
                                                onFieldSubmitted: (_) {
                                                  if (!emailOk) {
                                                    return;
                                                  }

                                                  FocusManager
                                                      .instance
                                                      .primaryFocus
                                                      ?.unfocus();

                                                  Navigator.pop(
                                                    sheetContext,
                                                    targetEmailText,
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 18),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            SafeHomeColors
                                                                .primary,
                                                        foregroundColor:
                                                            Colors.white,
                                                        disabledBackgroundColor:
                                                            Colors
                                                                .grey
                                                                .shade300,
                                                        disabledForegroundColor:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.share_rounded,
                                                  ),
                                                  label: Text(
                                                    _strings.t("Chia sẻ"),
                                                  ),
                                                  onPressed: emailOk
                                                      ? () {
                                                          FocusManager
                                                              .instance
                                                              .primaryFocus
                                                              ?.unfocus();

                                                          Navigator.pop(
                                                            sheetContext,
                                                            targetEmailText,
                                                          );
                                                        }
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );

                          if (targetEmail == null || targetEmail.isEmpty) {
                            return;
                          }

                          final directorySnap = await FirebaseDatabase.instance
                              .ref("userDirectory")
                              .orderByChild("email")
                              .equalTo(targetEmail)
                              .limitToFirst(1)
                              .get();

                          String? targetUid;

                          if (directorySnap.value is Map) {
                            final directory = Map<String, dynamic>.from(
                              directorySnap.value as Map,
                            );

                            if (directory.isNotEmpty) {
                              targetUid = directory.keys.first.toString();
                            }
                          }
                          if (!context.mounted) return;

                          if (targetUid == null) {
                            showTopToast(
                              context,
                              _strings.t("Email chưa đăng ký"),
                              color: Colors.red,
                              icon: Icons.error_outline_rounded,
                            );
                            return;
                          }

                          final myUid = currentUser.uid;
                          int skipped = 0;

                          for (final homeId in selectedHomes) {
                            final home = safeMap(homes[homeId]);
                            final role = home["_role"]?.toString() ?? "member";

                            final canShare =
                                home["_shared"] != true ||
                                role == "owner" ||
                                role == "admin";

                            if (!canShare) {
                              skipped++;
                              continue;
                            }

                            await FirebaseDatabase.instance
                                .ref(
                                  "accounts/$targetUid/shareRequests/$homeId",
                                )
                                .set({
                                  "ownerUid": myUid,
                                  "homeId": homeId,
                                  "ownerEmail":
                                      FirebaseAuth
                                          .instance
                                          .currentUser
                                          ?.email ??
                                      "",
                                  "time": DateTime.now().millisecondsSinceEpoch,
                                });

                            await FirebaseDatabase.instance
                                .ref(
                                  "accounts/$myUid/shareList/$homeId/$targetUid",
                                )
                                .set({
                                  "email": targetEmail,
                                  "sharedAt":
                                      DateTime.now().millisecondsSinceEpoch,
                                });
                          }
                          if (!context.mounted) return;

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(_strings.t("Chia sẻ hoàn tất")),
                              content: Text(
                                _strings.allHomeShareResultText(skipped),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(_strings.t("OK")),
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
                        title: Text(
                          _strings.t("Mở danh sách chia sẻ nhà"),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(selectedHomeCountText()),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;

                          if (currentUser == null) {
                            return;
                          }

                          final uid = currentUser.uid;

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
                              _strings.t(
                                "Không có nhà nào bạn có quyền quản lý",
                              ),
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
                                          MediaQuery.of(context).size.height *
                                          0.8,
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

                                        final value = snap.data?.value;
                                        final raw = value is Map
                                            ? Map<String, dynamic>.from(value)
                                            : <String, dynamic>{};

                                        return ListView(
                                          children: ownHomes.map((homeId) {
                                            final home = safeMap(homes[homeId]);
                                            final homeName =
                                                home["name"]?.toString() ??
                                                homeId;
                                            final users = safeMap(raw[homeId]);

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  if (users.isEmpty)
                                                    Text(
                                                      _strings.t(
                                                        "Chưa share cho ai",
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ...users.entries.map((e) {
                                                    final targetUid = e.key;
                                                    final data =
                                                        Map<
                                                          String,
                                                          dynamic
                                                        >.from(e.value);

                                                    final email =
                                                        data["email"] ??
                                                        "Unknown";

                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey
                                                            .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                      child: ListTile(
                                                        dense: true,
                                                        leading:
                                                            const CircleAvatar(
                                                              radius: 16,
                                                              child: Icon(
                                                                Icons.person,
                                                                size: 18,
                                                              ),
                                                            ),
                                                        title: Text(email),
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_rounded,
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
                                                              users.remove(
                                                                targetUid,
                                                              );
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
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          _strings.t("Xoá các nhà đã chọn?"),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        subtitle: Text(selectedHomeCountText()),
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
    chatAuthSubscription?.cancel();
    _homeRealtimeCoordinator.dispose();
    unreadChatCounts.clear();

    for (final sub in sharedHomeSubscriptions.values) {
      sub.cancel();
    }

    sharedHomeSubscriptions.clear();
    summaryTimer?.cancel();
    searchController.dispose();

    homesRevision.dispose();
    super.dispose();
  }
}
