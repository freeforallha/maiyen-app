import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void showShareRequestSheet({
  required BuildContext context,
  required Map<String, dynamic> requests,
  required String uid,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final selected = <String>{};
      final list = requests.entries.toList();

      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> acceptRequest({
            required String homeId,
            required String ownerUid,
          }) async {
            await FirebaseDatabase.instance
                .ref("accounts/$uid/sharedHomes/$homeId")
                .set({
              "ownerUid": ownerUid,
            });

            await FirebaseDatabase.instance
                .ref("sharedByHome/$homeId/$uid")
                .set(true);

            await FirebaseDatabase.instance
                .ref("accounts/$uid/shareRequests/$homeId")
                .remove();
          }

          Future<void> acceptSelected() async {
            for (final homeId in selected) {
              final raw = requests[homeId];

              if (raw == null) continue;

              final data = Map<String, dynamic>.from(raw);
              final ownerUid = data["ownerUid"]?.toString() ?? "";

              if (ownerUid.isEmpty) continue;

              await acceptRequest(
                homeId: homeId,
                ownerUid: ownerUid,
              );
            }

            Navigator.pop(context);
          }

          Future<void> denySelected() async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text("Từ chối lời mời?"),
                  content: const Text("Các lời mời đã chọn sẽ bị xoá."),
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
                );
              },
            );

            if (ok != true) return;

            for (final homeId in selected) {
              await FirebaseDatabase.instance
                  .ref("accounts/$uid/shareRequests/$homeId")
                  .remove();
            }

            Navigator.pop(context);
          }

          final maxHeight = MediaQuery.of(context).size.height * 0.75;
          final sheetHeight = list.isEmpty
              ? 210.0
              : (150.0 + list.length * 86.0).clamp(260.0, maxHeight);

          return SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: sheetHeight,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                ),
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

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(
                          Icons.mark_email_unread_rounded,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Lời mời chia sẻ (${list.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (selected.isNotEmpty)
                          Text(
                            "${selected.length} chọn",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (list.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Không có lời mời nào",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.done_all_rounded),
                            label: const Text("Chọn tất cả"),
                            onPressed: () {
                              setSheetState(() {
                                final allSelected =
                                    selected.length == list.length;

                                selected.clear();

                                if (!allSelected) {
                                  for (final e in list) {
                                    selected.add(e.key);
                                  }
                                }
                              });
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: "Từ chối",
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                            ),
                            onPressed:
                            selected.isEmpty ? null : denySelected,
                          ),
                          IconButton(
                            tooltip: "Chấp nhận",
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                            ),
                            onPressed:
                            selected.isEmpty ? null : acceptSelected,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Expanded(
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final homeId = list[i].key;
                            final data = Map<String, dynamic>.from(
                              list[i].value,
                            );

                            final ownerUid =
                                data["ownerUid"]?.toString() ?? "";
                            final email =
                                data["ownerEmail"]?.toString() ?? "Unknown";
                            final isSelected = selected.contains(homeId);

                            return Card(
                              color: isSelected
                                  ? Colors.blue.withValues(alpha: 0.08)
                                  : null,
                              child: ListTile(
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selected.remove(homeId);
                                    } else {
                                      selected.add(homeId);
                                    }
                                  });
                                },
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) {
                                    setSheetState(() {
                                      if (isSelected) {
                                        selected.remove(homeId);
                                      } else {
                                        selected.add(homeId);
                                      }
                                    });
                                  },
                                ),
                                title: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  homeId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await FirebaseDatabase.instance
                                            .ref(
                                          "accounts/$uid/shareRequests/$homeId",
                                        )
                                            .remove();

                                        Navigator.pop(context);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                      onPressed: ownerUid.isEmpty
                                          ? null
                                          : () async {
                                        await acceptRequest(
                                          homeId: homeId,
                                          ownerUid: ownerUid,
                                        );

                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}