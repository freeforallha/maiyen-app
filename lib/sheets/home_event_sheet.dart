import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void showHomeEventSheet({
  required BuildContext context,
  required String uid,
}) {
  FirebaseDatabase.instance
      .ref("accounts/$uid/notifications")
      .get()
      .then((snap) async {
    if (!snap.exists || snap.value is! Map) return;

    final raw = Map<String, dynamic>.from(snap.value as Map);
    final updates = <String, dynamic>{};

    for (final entry in raw.entries) {
      final data = Map<String, dynamic>.from(entry.value);
      if (data["read"] != true) {
        updates["accounts/$uid/notifications/${entry.key}/read"] = true;
      }
    }

    if (updates.isNotEmpty) {
      await FirebaseDatabase.instance.ref().update(updates);
    }
  });

  String formatTime(dynamic value) {
    final ts = int.tryParse(value?.toString() ?? "0") ?? 0;
    if (ts <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inHours < 1) return "${diff.inMinutes} phút trước";
    if (diff.inDays < 1) return "${diff.inHours} giờ trước";
    return "${diff.inDays} ngày trước";
  }

  IconData iconForType(String type) {
    switch (type) {
      case "security":
        return Icons.security_rounded;
      case "chat":
        return Icons.chat_bubble_rounded;
      case "share_request":
        return Icons.mail_rounded;
      case "member_join":
        return Icons.person_add_alt_1_rounded;
      case "member_leave":
        return Icons.logout_rounded;
      case "share_request_accepted":
        return Icons.check_circle_rounded;
      case "share_request_denied":
        return Icons.cancel_rounded;
      case "join_request":
        return Icons.person_add_rounded;
      case "join_request_accepted":
        return Icons.how_to_reg_rounded;
      case "transfer_owner_request":
        return Icons.admin_panel_settings_rounded;
      case "transfer_owner_accepted":
        return Icons.workspace_premium_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color colorForType(String type) {
    switch (type) {
      case "share_request":
        return Colors.blue;
      case "share_request_accepted":
        return Colors.green;
      case "member_leave":
        return Colors.orange;
      case "share_request_denied":
        return Colors.red;
      case "join_request":
        return Colors.orange;
      case "join_request_accepted":
        return Colors.green;
      case "transfer_owner_request":
        return Colors.purple;
      case "transfer_owner_accepted":
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    const Text(
                      "Thông báo Home",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Xoá tất cả thông báo?"),
                            content: const Text(
                              "Toàn bộ thông báo Home sẽ bị xoá.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Huỷ"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Xoá"),
                              ),
                            ],
                          ),
                        );

                        if (ok == true) {
                          await FirebaseDatabase.instance
                              .ref("accounts/$uid/notifications")
                              .remove();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref("accounts/$uid/notifications")
                      .orderByChild("time")
                      .limitToLast(60)
                      .onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.snapshot.value == null) {
                      return const Center(
                        child: Text("Chưa có thông báo nào"),
                      );
                    }

                    final raw = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map,
                    );

                    final items = raw.values
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();

                    items.sort((a, b) {
                      final ta =
                          int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
                      final tb =
                          int.tryParse(b["time"]?.toString() ?? "0") ?? 0;
                      return tb.compareTo(ta);
                    });

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final type = item["type"]?.toString() ?? "system";
                        final read = item["read"] == true;

                        return Material(
                          color: read
                              ? Colors.grey.shade100
                              : Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: Icon(
                              iconForType(type),
                              color:
                              read ? Colors.grey : colorForType(type),
                            ),
                            title: Text(
                              item["title"]?.toString() ?? "Thông báo",
                              style: TextStyle(
                                fontWeight: read
                                    ? FontWeight.w500
                                    : FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              "${item["message"] ?? ""}\n${formatTime(item["time"])}",
                            ),
                            isThreeLine: true,
                            onTap: () async {
                              final id = item["id"]?.toString() ?? "";
                              if (id.isEmpty) return;

                              await FirebaseDatabase.instance
                                  .ref("accounts/$uid/notifications/$id/read")
                                  .set(true);
                            },
                          ),
                        );
                      },
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
}