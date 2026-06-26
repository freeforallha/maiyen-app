import 'package:flutter/material.dart';

class RoomTabs extends StatelessWidget {
  static const double _tabSpacing = 8;
  static const Duration _animationDuration = Duration(milliseconds: 220);

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

    final tabs = <Map<String, String>>[
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

    double tabWidth(Map<String, String> tab) {
      final selected = selectedRoomId == tab["id"];
      final nameLength = (tab["name"] ?? "").runes.length;
      final baseWidth = (nameLength * 8.2 + 34)
          .clamp(96.0, 132.0)
          .toDouble();

      return selected
          ? (baseWidth + 16).clamp(112.0, 150.0).toDouble()
          : baseWidth;
    }

    return SizedBox(
      height: 48,
      child: DragBoundary(
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.025, 0.94, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            dragBoundaryProvider: (context) => DragBoundary.forRectOf(context),
            itemExtentBuilder: (index, _) {
              if (index >= tabs.length) return null;
              return tabWidth(tabs[index]) + _tabSpacing;
            },
            itemCount: tabs.length,
            onReorderItem: (oldIndex, newIndex) async {
              if (oldIndex == 0 ||
                  oldIndex < 0 ||
                  oldIndex >= tabs.length) {
                return;
              }

              final movable = tabs.skip(1).toList();
              final moved = movable.removeAt(oldIndex - 1);
              var targetIndex = newIndex - 1;

              if (targetIndex < 0) {
                targetIndex = 0;
              } else if (targetIndex > movable.length) {
                targetIndex = movable.length;
              }

              movable.insert(targetIndex, moved);

              await onReorder(
                movable.map((tab) => tab["id"]!).toList(),
              );
            },
            proxyDecorator: _buildDragProxy,
            clipBehavior: Clip.hardEdge,
            autoScrollerVelocityScalar: 70,
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final roomId = tab["id"]!;
              final name = tab["name"]!;
              final selected = selectedRoomId == roomId;
              final width = tabWidth(tab);

              final tabChild = RepaintBoundary(
                key: ValueKey("room_tab_$roomId"),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!selected) {
                      onSelect(roomId);
                    }
                  },
                  child: AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    width: width,
                    margin: const EdgeInsets.only(right: _tabSpacing),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.black.withValues(alpha: 0.075)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? Colors.black.withValues(alpha: 0.10)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: _animationDuration,
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: selected ? 15 : 14,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: selected
                                ? Colors.black87
                                : Colors.black.withValues(alpha: 0.45),
                            height: 1,
                          ),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: _animationDuration,
                          curve: Curves.easeOutCubic,
                          width: selected ? 28 : 0,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (index == 0) {
                return tabChild;
              }

              return ReorderableDelayedDragStartListener(
                key: ValueKey("room_drag_$roomId"),
                index: index,
                child: tabChild,
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _buildDragProxy(
      Widget child,
      int index,
      Animation<double> animation,
      ) {
    final curved = animation.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final t = curved.value;

        return Transform.scale(
          scale: 1 + (0.035 * t),
          child: Material(
            color: Colors.transparent,
            elevation: 10 * t,
            shadowColor: Colors.black.withValues(alpha: 0.16 * t),
            borderRadius: BorderRadius.circular(18),
            child: child,
          ),
        );
      },
    );
  }
}
