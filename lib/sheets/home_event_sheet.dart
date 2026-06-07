import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void showHomeEventSheet({
  required BuildContext context,
  required String uid,
}) {
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
        return Icons.person_remove_alt_1_rounded;
      default:
        return Icons.notifications_rounded;
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
              const Text(
                "Thông báo Home",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref("accounts/$uid/notifications")
                      .orderByChild("time")
                      .limitToLast(50)
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
                      final ta = int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
                      final tb = int.tryParse(b["time"]?.toString() ?? "0") ?? 0;
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

                        return Container(
                          decoration: BoxDecoration(
                            color: read
                                ? Colors.grey.shade100
                                : Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Icon(
                              iconForType(type),
                              color: read ? Colors.grey : Colors.blue,
                            ),
                            title: Text(
                              item["title"]?.toString() ?? "Thông báo",
                              style: TextStyle(
                                fontWeight:
                                read ? FontWeight.w500 : FontWeight.w800,
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