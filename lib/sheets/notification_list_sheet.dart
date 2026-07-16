import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

class NotificationListSheet extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final String deviceId;

  const NotificationListSheet({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.deviceId,
  });

  @override
  State<NotificationListSheet> createState() => _NotificationListSheetState();
}

class _NotificationListSheetState extends State<NotificationListSheet> {
  static const int _pageSize = 10;

  late final DatabaseReference _ref;
  final ScrollController _scrollController = ScrollController();

  int _limit = _pageSize;
  bool _loadingOlder = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    _ref = FirebaseDatabase.instance.ref(
      "accounts/${widget.ownerUid}/homes/${widget.homeId}/"
      "devices/${widget.deviceId}/notifications",
    );

    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _loadingOlder || !_hasMore) {
      return;
    }

    final position = _scrollController.position;

    // Danh sách mới nhất nằm trên cùng. Khi người dùng vuốt lên
    // và tiến gần cuối danh sách, tải thêm 10 thông báo cũ.
    if (position.pixels < position.maxScrollExtent - 100) {
      return;
    }

    setState(() {
      _loadingOlder = true;
      _limit += _pageSize;
    });
  }

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  String formatTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}  "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }

  void _completePagination(bool nextHasMore) {
    if (_hasMore == nextHasMore && !_loadingOlder) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _hasMore = nextHasMore;
        _loadingOlder = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final query = _ref.orderByChild("time").limitToLast(_limit + 1);

    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(
                strings.notifications,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: query.onValue,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final event = snap.data;

                if (event == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = event.snapshot.value;

                if (data == null) {
                  if (snap.connectionState == ConnectionState.active) {
                    _completePagination(false);
                  }

                  return Center(
                    child: Text(
                      strings.t("Chưa có thông báo"),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final map = safeMap(data);
                final allItems = map.entries.toList();

                allItems.sort((a, b) {
                  final ta = safeMap(a.value)["time"] ?? 0;
                  final tb = safeMap(b.value)["time"] ?? 0;
                  return tb.compareTo(ta);
                });

                final nextHasMore = allItems.length > _limit;
                final visibleItems = nextHasMore
                    ? allItems.take(_limit).toList()
                    : allItems;

                if (snap.connectionState == ConnectionState.active) {
                  _completePagination(nextHasMore);
                }

                final showFooter = _loadingOlder || nextHasMore;

                return ListView.separated(
                  controller: _scrollController,
                  itemCount: visibleItems.length + (showFooter ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    if (i >= visibleItems.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: _loadingOlder
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  strings.t("Vuốt lên để tải thêm"),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      );
                    }

                    final item = safeMap(visibleItems[i].value);

                    final rawText = item["text"]?.toString() ?? "";
                    final type = item["type"]?.toString() ?? "";
                    final notificationItem = {
                      ...item,
                      "type": type,
                      "message": item["message"] ?? rawText,
                      "title": item["title"] ?? rawText,
                    };
                    final titleText = strings.notificationTitle(
                      notificationItem,
                      homeName: item["homeName"]?.toString() ?? "",
                    );
                    final text = strings.notificationMessage({
                      ...item,
                      "type": type,
                      "message": item["message"] ?? rawText,
                      "title": item["title"] ?? rawText,
                    }, homeName: item["homeName"]?.toString() ?? "");

                    final lower = "$rawText $text".toLowerCase();

                    final isSafe =
                        lower.contains("đóng") ||
                        lower.contains("bình thường") ||
                        lower.contains("đã tắt") ||
                        lower.contains("closed") ||
                        lower.contains("cleared") ||
                        lower.contains("online") ||
                        lower.contains("kết nối lại") ||
                        lower.contains("cập nhật");

                    final time =
                        int.tryParse(item["time"]?.toString() ?? "0") ?? 0;
                    final dt = DateTime.fromMillisecondsSinceEpoch(time);

                    IconData icon = Icons.notifications;
                    Color color = Colors.blueAccent;

                    if (type == "tamper") {
                      icon = Icons.warning_amber_rounded;
                      color = Colors.red;
                    } else if (type == "door" || type == "status") {
                      icon = Icons.sensor_door_rounded;
                      color = Colors.orange;
                    } else if (type == "motion") {
                      icon = Icons.directions_run_rounded;
                      color = Colors.deepPurple;
                    } else if (type == "battery") {
                      icon = Icons.battery_alert_rounded;
                      color = Colors.amber;
                    } else if (type == "heartbeat") {
                      icon = Icons.sync_rounded;
                      color = Colors.green;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(icon, color: color),
                      ),
                      title: Text(
                        titleText,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSafe ? Colors.black : Colors.red.shade300,
                        ),
                      ),
                      subtitle: Text(
                        "$text\n${formatTime(dt)}",
                        style: TextStyle(
                          color: isSafe ? Colors.grey : Colors.red.shade200,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
