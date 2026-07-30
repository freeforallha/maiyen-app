part of '../all_home_page.dart';

extension _SummaryRealtime on _AllHomeState {
  String selectedHomeCountText([int? count]) {
    final value = count ?? selectedHomes.length;

    return _strings.selectedHomesCountText(value);
  }

  List<String> buildAllHomeSummaries() {
    int safeCount = 0;
    int warningCount = 0;
    int dangerCount = 0;
    int emergencyCount = 0;

    final emergencyReasons = <String>{};
    final dangerReasons = <String>{};
    final warningReasons = <String>{};

    for (final home in homes.values) {
      final status = getHomeOverallStatus(home);
      final level = status["level"]?.toString() ?? "safe";

      if (level == "emergency") {
        emergencyCount++;

        for (final item in (status["emergencyIssues"] as List? ?? [])) {
          emergencyReasons.add(_strings.statusText(item.toString()));
        }
      } else if (level == "danger") {
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

    if (emergencyCount > 0) {
      summaries.add(
        _strings.allHomeEmergencyCountText(
          emergencyCount,
          reason: emergencyReasons.isNotEmpty ? emergencyReasons.first : "",
        ),
      );
    }

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

    MaiYenNavigation.showModalSheet(
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

                final normalHomes = <Map<String, dynamic>>[];
                final warningHomes = <Map<String, dynamic>>[];
                final dangerHomes = <Map<String, dynamic>>[];
                final emergencyHomes = <Map<String, dynamic>>[];

                for (final entry in homes.entries) {
                  final homeId = entry.key;
                  final home = safeMap(entry.value);
                  final name = home["name"]?.toString() ?? homeId;
                  final status = getHomeOverallStatus(home);
                  final level = status["level"]?.toString() ?? "safe";

                  final issues = level == "emergency"
                      ? (status["emergencyIssues"] as List? ?? [])
                      : level == "danger"
                      ? (status["dangerIssues"] as List? ?? [])
                      : level == "warning"
                      ? (status["warningIssues"] as List? ?? [])
                      : <dynamic>[];

                  final item = {
                    "id": homeId,
                    "name": name,
                    "issues": issues.map((e) => e.toString()).toList(),
                  };

                  if (level == "emergency") {
                    emergencyHomes.add(item);
                  } else if (level == "danger") {
                    dangerHomes.add(item);
                  } else if (level == "warning") {
                    warningHomes.add(item);
                  } else {
                    normalHomes.add(item);
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
                          title: _strings.emergencyStatusTitle(),
                          icon: Icons.crisis_alert_rounded,
                          color: MaiYenColors.emergency,
                          items: emergencyHomes,
                          compact: true,
                        ),
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
                          color: MaiYenColors.safe,
                          items: normalHomes,
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

  bool _hasEmergencyHome() {
    return homes.values.any((home) {
      return getHomeOverallStatus(safeMap(home))["level"]?.toString() ==
          "emergency";
    });
  }

  void _syncEmergencyPulse() {
    if (!_hasEmergencyHome()) {
      _emergencyPulseTimer?.cancel();
      _emergencyPulseTimer = null;
      _emergencyPulseDanger = false;
      return;
    }

    if (_emergencyPulseTimer != null) {
      return;
    }

    _emergencyPulseDanger = false;
    _emergencyPulseTimer = Timer.periodic(const Duration(milliseconds: 650), (
      _,
    ) {
      if (!mounted) {
        return;
      }

      if (!_hasEmergencyHome()) {
        _emergencyPulseTimer?.cancel();
        _emergencyPulseTimer = null;
        setState(() {
          _emergencyPulseDanger = false;
        });
        return;
      }

      setState(() {
        _emergencyPulseDanger = !_emergencyPulseDanger;
      });
    });
  }

  void notifyHomesChanged() {
    if (!mounted) return;
    homesRevision.value = homesRevision.value + 1;
    syncChatUnreadCounts();
    _syncEmergencyPulse();
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

}
