import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';

Future<void> showRoomManagementSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
}) async {
  final strings = AppStrings.of(context);
  final currentUid = FirebaseAuth.instance.currentUser?.uid;

  if (currentUid == null || currentUid.isEmpty) {
    return;
  }

  if (currentUid != ownerUid) {
    final accessSnap = await FirebaseDatabase.instance
        .ref("accounts/$currentUid/sharedHomes/$homeId")
        .get();

    final access = accessSnap.value is Map
        ? Map<String, dynamic>.from(accessSnap.value as Map)
        : <String, dynamic>{};

    final sharedOwnerUid = access["ownerUid"]?.toString() ?? "";

    final role = access["role"]?.toString() ?? "member";

    if (sharedOwnerUid != ownerUid || role != "admin") {
      if (context.mounted) {
        showTopToast(
          context,
          strings.t("Bạn không có quyền quản lý phòng"),
          color: Colors.red,
          icon: Icons.lock_rounded,
        );
      }

      return;
    }
  }

  if (!context.mounted) return;

  final homeRef = FirebaseDatabase.instance.ref(
    "accounts/$ownerUid/homes/$homeId",
  );

  final roomsRef = homeRef.child("rooms");

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
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

              final normalEntries =
                  rooms.entries
                      .where((entry) => entry.key != "unassigned")
                      .toList()
                    ..sort((a, b) {
                      final ao = a.value is Map
                          ? (a.value["order"] ?? 999)
                          : 999;
                      final bo = b.value is Map
                          ? (b.value["order"] ?? 999)
                          : 999;
                      return ao.compareTo(bo);
                    });

              Future<void> renameRoom(
                  String roomId,
                  Map<String, dynamic> room,
                  ) async {
                final oldName = room["name"]?.toString() ?? "";
                String inputName = oldName.trim();

                final newName = await showDialog<String>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(strings.t("Đổi tên phòng")),
                    content: TextFormField(
                      initialValue: oldName,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: strings.t("Tên phòng"),
                      ),
                      onChanged: (value) {
                        inputName = value.trim();
                      },
                      onFieldSubmitted: (_) {
                        if (inputName.isEmpty) return;
                        Navigator.pop(dialogContext, inputName);
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(strings.t("Huỷ")),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (inputName.isEmpty) return;
                          Navigator.pop(dialogContext, inputName);
                        },
                        child: Text(strings.t("Lưu")),
                      ),
                    ],
                  ),
                );

                if (newName == null || newName.trim().isEmpty) return;

                await roomsRef.child(roomId).update({
                  "name": newName.trim(),
                });
              }

              Future<void> deleteRoom(String roomId) async {
                final ok = await showDialog<bool>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(strings.t("Xoá phòng")),
                    content: Text(
                      strings.t(
                        "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(strings.t("Huỷ")),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(strings.t("Xoá")),
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
                    updates["devices/${deviceEntry.key}/roomId"] = "unassigned";
                  }
                }

                updates["rooms/$roomId"] = null;

                await homeRef.update(updates);
              }

              Future<void> addRoom(
                  List<MapEntry<dynamic, dynamic>> allEntries,
                  ) async {
                String inputName = "";

                final roomName = await showDialog<String>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(strings.t("Thêm phòng")),
                    content: TextFormField(
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: strings.t("Ví dụ: Phòng khách"),
                      ),
                      onChanged: (value) {
                        inputName = value.trim();
                      },
                      onFieldSubmitted: (_) {
                        if (inputName.isEmpty) return;
                        Navigator.pop(dialogContext, inputName);
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(strings.t("Huỷ")),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (inputName.isEmpty) return;
                          Navigator.pop(dialogContext, inputName);
                        },
                        child: Text(strings.t("Thêm")),
                      ),
                    ],
                  ),
                );

                if (roomName == null || roomName.trim().isEmpty) return;

                final normalized = roomName.trim().toLowerCase();

                for (final entry in allEntries) {
                  final room = entry.value is Map
                      ? Map<String, dynamic>.from(entry.value)
                      : <String, dynamic>{};

                  final existing = (room["name"]?.toString() ?? "")
                      .trim()
                      .toLowerCase();

                  if (existing == normalized) {
                    if (!context.mounted) return;

                    showTopToast(
                      context,
                      strings.t("Tên phòng đã tồn tại"),
                      color: Colors.orange,
                      icon: Icons.info_rounded,
                    );
                    return;
                  }
                }

                final roomId = "room_${DateTime.now().millisecondsSinceEpoch}";

                await roomsRef.child(roomId).set({
                  "name": roomName.trim(),
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

                  Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        strings.t("Quản lý phòng"),
                        style: const TextStyle(
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
                      title: Text(
                        entry.key == "unassigned"
                            ? strings.t("Chưa phân phòng")
                            : room["name"]?.toString() ?? entry.key,
                      ),
                      subtitle: Text(strings.t("Phòng mặc định")),
                    );
                  }),

                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: normalEntries.length,
                      onReorderItem: (oldIndex, newIndex) async {
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
                              leading: const Icon(Icons.drag_handle_rounded),
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
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: "rename",
                                    child: Text(strings.t("Đổi tên")),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Text(strings.t("Xoá phòng")),
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
                      onPressed: () =>
                          addRoom([...unassignedEntry, ...normalEntries]),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(strings.t("Thêm phòng")),
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
