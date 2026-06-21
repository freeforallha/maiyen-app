import 'package:flutter/material.dart';

class RoomTabs extends StatelessWidget {
  final Map<String, dynamic> rooms;
  final String homeName;
  final String selectedRoomId;
  final ValueChanged<String> onSelect;
  final Future<void> Function(List<String>) onReorder;

  const RoomTabs({
    super.key,
    required this.rooms,
    required this.homeName,
    required this.selectedRoomId,
    required this.onSelect,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final roomEntries = rooms.entries
        .where((entry) => entry.key != "unassigned")
        .toList()
      ..sort((a, b) {
        final ao = a.value is Map ? (a.value["order"] ?? 999) : 999;
        final bo = b.value is Map ? (b.value["order"] ?? 999) : 999;
        return ao.compareTo(bo);
      });

    final tabs = [
      {
        "id": "overview",
        "name": homeName.isNotEmpty ? homeName : "Nhà",
      },
      ...roomEntries.map((entry) {
        final room = entry.value is Map
            ? Map<String, dynamic>.from(entry.value)
            : <String, dynamic>{};

        return {
          "id": entry.key.toString(),
          "name": room["name"]?.toString() ?? entry.key.toString(),
        };
      }),
    ];

    return SizedBox(
      height: 42,
      child: ReorderableListView.builder(
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            child: child,
          );
        },
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: tabs.length,
        onReorderItem: (oldIndex, newIndex) async {
          if (oldIndex == 0) return;

          final movable = tabs.sublist(1);

          final moved = movable.removeAt(oldIndex - 1);

          var targetIndex = newIndex - 1;

          if (targetIndex < 0) {
            targetIndex = 0;
          }

          if (targetIndex > movable.length) {
            targetIndex = movable.length;
          }

          movable.insert(targetIndex, moved);

          await onReorder(
            movable.map((e) => e["id"]!).toList(),
          );
        },
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final roomId = tab["id"]!;
          final selected = selectedRoomId == roomId;

          final child = InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelect(roomId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tab["name"]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.black87
                          : Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: 2,
                    width: selected ? tab["name"]!.length * 8.5 : 0,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (index == 0) {
            return Container(
              key: const ValueKey("room_tab_overview"),
              child: child,
            );
          }

          return ReorderableDelayedDragStartListener(
            key: ValueKey("room_tab_$roomId"),
            index: index,
            child: child,
          );
        },
      ),
    );
  }
}