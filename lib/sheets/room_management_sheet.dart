import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> showRoomManagementSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
}) {
  final roomsRef = FirebaseDatabase.instance.ref(
    "accounts/$ownerUid/homes/$homeId/rooms",
  );

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StreamBuilder<DatabaseEvent>(
            stream: roomsRef.onValue,
            builder: (context, snapshot) {
              final raw = snapshot.data?.snapshot.value;
              final rooms = raw is Map ? Map<String, dynamic>.from(raw) : {};

              final entries = rooms.entries.toList()
                ..sort((a, b) {
                  final ao = (a.value is Map) ? (a.value["order"] ?? 999) : 999;
                  final bo = (b.value is Map) ? (b.value["order"] ?? 999) : 999;
                  return ao.compareTo(bo);
                });

              return Column(
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

                  const Row(
                    children: [
                      Icon(Icons.meeting_room_rounded, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        "Quản lý phòng",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ...entries.map((entry) {
                    final room = entry.value is Map
                        ? Map<String, dynamic>.from(entry.value)
                        : <String, dynamic>{};

                    return ListTile(
                      leading: const Icon(Icons.home_work_rounded),
                      title: Text(room["name"]?.toString() ?? entry.key),
                      subtitle: entry.key == "unassigned"
                          ? const Text("Phòng mặc định")
                          : null,
                      trailing: entry.key == "unassigned"
                          ? null
                          : PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == "rename") {
                            final controller = TextEditingController(
                              text: room["name"]?.toString() ?? "",
                            );

                            final newName = await showDialog<String>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Đổi tên phòng"),
                                content: TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    hintText: "Tên phòng",
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Huỷ"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        context,
                                        controller.text.trim(),
                                      );
                                    },
                                    child: const Text("Lưu"),
                                  ),
                                ],
                              ),
                            );

                            if (newName == null || newName.isEmpty) return;

                            await roomsRef.child(entry.key).update({
                              "name": newName,
                            });
                          }

                          if (value == "delete") {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Xoá phòng"),
                                content: const Text(
                                  "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("Huỷ"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("Xoá"),
                                  ),
                                ],
                              ),
                            );

                            if (ok != true) return;

                            final homeRef = FirebaseDatabase.instance.ref(
                              "accounts/$ownerUid/homes/$homeId",
                            );

                            final devicesSnap = await homeRef.child("devices").get();
                            final rawDevices = devicesSnap.value;
                            final devices = rawDevices is Map
                                ? Map<String, dynamic>.from(rawDevices)
                                : <String, dynamic>{};

                            final updates = <String, Object?>{};

                            for (final deviceEntry in devices.entries) {
                              final device = deviceEntry.value is Map
                                  ? Map<String, dynamic>.from(deviceEntry.value)
                                  : <String, dynamic>{};

                              if (device["roomId"] == entry.key) {
                                updates["devices/${deviceEntry.key}/roomId"] = "unassigned";
                              }
                            }

                            updates["rooms/${entry.key}"] = null;

                            await homeRef.update(updates);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: "rename",
                            child: Text("Đổi tên"),
                          ),
                          PopupMenuItem(
                            value: "delete",
                            child: Text("Xoá phòng"),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final controller = TextEditingController();

                        final roomName = await showDialog<String>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Thêm phòng"),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: "Ví dụ: Phòng khách",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Huỷ"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    controller.text.trim(),
                                  );
                                },
                                child: const Text("Thêm"),
                              ),
                            ],
                          ),
                        );

                        if (roomName == null || roomName.isEmpty) return;

                        final normalized = roomName.trim().toLowerCase();

                        for (final entry in entries) {
                          final room = entry.value is Map
                              ? Map<String, dynamic>.from(entry.value)
                              : <String, dynamic>{};

                          final existing =
                          (room["name"]?.toString() ?? "").trim().toLowerCase();

                          if (existing == normalized) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Tên phòng đã tồn tại"),
                              ),
                            );
                            return;
                          }
                        }

                        final roomId =
                            "room_${DateTime.now().millisecondsSinceEpoch}";

                        await roomsRef.child(roomId).set({
                          "name": roomName,
                          "icon": "room",
                          "order": DateTime.now().millisecondsSinceEpoch,
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Thêm phòng"),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}