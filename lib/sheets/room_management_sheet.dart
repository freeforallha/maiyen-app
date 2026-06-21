import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> showRoomManagementSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
}) {
  final homeRef = FirebaseDatabase.instance.ref(
    "accounts/$ownerUid/homes/$homeId",
  );

  final roomsRef = homeRef.child("rooms");

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
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

              final unassignedEntry = rooms.entries
                  .where((entry) => entry.key == "unassigned")
                  .toList();

              final normalEntries = rooms.entries
                  .where((entry) => entry.key != "unassigned")
                  .toList()
                ..sort((a, b) {
                  final ao = a.value is Map ? (a.value["order"] ?? 999) : 999;
                  final bo = b.value is Map ? (b.value["order"] ?? 999) : 999;
                  return ao.compareTo(bo);
                });

              Future<void> renameRoom(
                  String roomId,
                  Map<String, dynamic> room,
                  ) async {
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
                          Navigator.pop(context, controller.text.trim());
                        },
                        child: const Text("Lưu"),
                      ),
                    ],
                  ),
                );

                if (newName == null || newName.isEmpty) return;

                await roomsRef.child(roomId).update({
                  "name": newName,
                });
              }

              Future<void> deleteRoom(String roomId) async {
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

                  if (device["roomId"] == roomId) {
                    updates["devices/${deviceEntry.key}/roomId"] =
                    "unassigned";
                  }
                }

                updates["rooms/$roomId"] = null;

                await homeRef.update(updates);
              }

              Future<void> addRoom(
                  List<MapEntry<dynamic, dynamic>> allEntries,
                  ) async {
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
                          Navigator.pop(context, controller.text.trim());
                        },
                        child: const Text("Thêm"),
                      ),
                    ],
                  ),
                );

                if (roomName == null || roomName.isEmpty) return;

                final normalized = roomName.trim().toLowerCase();

                for (final entry in allEntries) {
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

                final roomId = "room_${DateTime.now().millisecondsSinceEpoch}";

                await roomsRef.child(roomId).set({
                  "name": roomName,
                  "icon": "room",
                  "order": normalEntries.length + 1,
                });
              }

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

                  ...unassignedEntry.map((entry) {
                    final room = entry.value is Map
                        ? Map<String, dynamic>.from(entry.value)
                        : <String, dynamic>{};

                    return ListTile(
                      leading: const Icon(Icons.home_work_rounded),
                      title: Text(room["name"]?.toString() ?? entry.key),
                      subtitle: const Text("Phòng mặc định"),
                    );
                  }),

                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: normalEntries.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex--;

                        final items = [...normalEntries];
                        final moved = items.removeAt(oldIndex);
                        items.insert(newIndex, moved);

                        final updates = <String, Object?>{};

                        for (var i = 0; i < items.length; i++) {
                          updates["${items[i].key}/order"] = i + 1;
                        }

                        await roomsRef.update(updates);
                      },
                      itemBuilder: (context, index) {
                        final entry = normalEntries[index];
                        final room = entry.value is Map
                            ? Map<String, dynamic>.from(entry.value)
                            : <String, dynamic>{};

                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(entry.key),
                          index: index,
                          child: Material(
                            color: Colors.white,
                            child: ListTile(
                              leading:
                              const Icon(Icons.drag_handle_rounded),
                              title: Text(
                                room["name"]?.toString() ?? entry.key,
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == "rename") {
                                    await renameRoom(entry.key, room);
                                  }

                                  if (value == "delete") {
                                    await deleteRoom(entry.key);
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => addRoom([
                        ...unassignedEntry,
                        ...normalEntries,
                      ]),
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