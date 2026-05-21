import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void showShareRequestSheet({
  required BuildContext context,
  required Map<String, dynamic> requests,
  required String uid,
  required int inviteCount,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,

    builder: (_) {
      final selected = <String>{};

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final list = requests.entries.toList();

          Future<void> acceptSelected() async {
            for (final homeId in selected) {
              final raw = requests[homeId];

              if (raw == null) continue;

              final data = Map<String, dynamic>.from(raw);

              final ownerUid = data["ownerUid"] ?? "";

              await FirebaseDatabase.instance
                  .ref("accounts/$uid/sharedHomes/$homeId")
                  .set({"ownerUid": ownerUid});

              await FirebaseDatabase.instance
                  .ref("sharedByHome/$homeId/$uid")
                  .set(true);

              await FirebaseDatabase.instance
                  .ref("accounts/$uid/shareRequests/$homeId")
                  .remove();
            }

            Navigator.pop(context);
          }

          Future<void> denySelected() async {
            final ok = await showDialog<bool>(
              context: context,

              builder: (_) => AlertDialog(
                title: Text("Từ chối tất cả?"),

                content: Text("Các lời mời đã chọn sẽ bị xoá."),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),

                    child: Text("No"),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),

                    onPressed: () => Navigator.pop(context, true),

                    child: Text("Yes"),
                  ),
                ],
              ),
            );

            if (ok != true) return;

            for (final homeId in selected) {
              await FirebaseDatabase.instance
                  .ref("accounts/$uid/shareRequests/$homeId")
                  .remove();
            }

            Navigator.pop(context);
          }

          return Padding(
            padding: EdgeInsets.all(16),

            child: Column(
              children: [
                // ===== TOP ACTIONS =====
                Row(
                  children: [
                    IconButton(
                      tooltip: "Chọn tất cả",

                      icon: Icon(Icons.done_all, color: Colors.blue),

                      onPressed: () {
                        setSheetState(() {
                          final allSelected = selected.length == list.length;

                          if (allSelected) {
                            selected.clear();
                          } else {
                            selected.clear();

                            for (final e in list) {
                              selected.add(e.key);
                            }
                          }
                        });
                      },
                    ),

                    IconButton(
                      tooltip: "Deny all",

                      icon: Icon(
                        Icons.close_fullscreen_rounded,
                        color: Colors.red,
                      ),

                      onPressed: selected.isEmpty ? null : denySelected,
                    ),

                    IconButton(
                      tooltip: "Accept all",

                      icon: Icon(Icons.check_circle, color: Colors.green),

                      onPressed: selected.isEmpty ? null : acceptSelected,
                    ),

                    Spacer(),

                    Text(
                      "${selected.length} selected",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,

                    itemBuilder: (_, i) {
                      final homeId = list[i].key;

                      final data = Map<String, dynamic>.from(list[i].value);

                      final ownerUid = data["ownerUid"] ?? "";

                      final email = data["ownerEmail"] ?? "";

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

                          title: Text(email),

                          subtitle: Text(homeId),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),

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
                                icon: Icon(Icons.check, color: Colors.green),

                                onPressed: () async {
                                  await FirebaseDatabase.instance
                                      .ref("accounts/$uid/sharedHomes/$homeId")
                                      .set({"ownerUid": ownerUid});

                                  await FirebaseDatabase.instance
                                      .ref("sharedByHome/$homeId/$uid")
                                      .set(true);

                                  await FirebaseDatabase.instance
                                      .ref(
                                        "accounts/$uid/shareRequests/$homeId",
                                      )
                                      .remove();

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
            ),
          );
        },
      );
    },
  );
}
