import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RoomTabs extends StatefulWidget {
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
  State<RoomTabs> createState() => _RoomTabsState();
}

class _RoomTabsState extends State<RoomTabs> {
  static const Duration _animationDuration = Duration(milliseconds: 220);

  late List<String> _roomOrder;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _roomOrder = _orderedRoomIds(widget.rooms);
  }

  @override
  void didUpdateWidget(covariant RoomTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    final incomingOrder = _orderedRoomIds(widget.rooms);

    if (_savingOrder) {
      if (listEquals(incomingOrder, _roomOrder)) {
        _savingOrder = false;
      }

      return;
    }

    if (!listEquals(incomingOrder, _roomOrder)) {
      _roomOrder = incomingOrder;
    }
  }

  List<String> _orderedRoomIds(Map<String, dynamic> rooms) {
    final entries = rooms.entries
        .where((entry) => entry.key != "unassigned")
        .toList()
      ..sort((a, b) {
        final aData = a.value is Map
            ? Map<String, dynamic>.from(a.value as Map)
            : <String, dynamic>{};

        final bData = b.value is Map
            ? Map<String, dynamic>.from(b.value as Map)
            : <String, dynamic>{};

        final aOrder = int.tryParse(aData["order"]?.toString() ?? "") ?? 999;
        final bOrder = int.tryParse(bData["order"]?.toString() ?? "") ?? 999;

        return aOrder.compareTo(bOrder);
      });

    return entries.map((entry) => entry.key.toString()).toList();
  }

  String _roomName(String roomId) {
    final raw = widget.rooms[roomId];

    final room = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final name = room["name"]?.toString().trim() ?? "";

    return name.isNotEmpty ? name : roomId;
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex == 0) return;

    final previousOrder = List<String>.from(_roomOrder);
    final movable = List<String>.from(_roomOrder);

    final moved = movable.removeAt(oldIndex - 1);
    var targetIndex = newIndex - 1;

    if (targetIndex < 0) {
      targetIndex = 0;
    } else if (targetIndex > movable.length) {
      targetIndex = movable.length;
    }

    movable.insert(targetIndex, moved);

    setState(() {
      _roomOrder = movable;
      _savingOrder = true;
    });

    try {
      await widget.onReorder(List<String>.from(movable));
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _roomOrder = previousOrder;
        _savingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Map<String, String>>[
      {
        "id": "overview",
        "name": widget.homeName.isNotEmpty ? widget.homeName : "Nhà",
      },
      ..._roomOrder
          .where((roomId) => widget.rooms.containsKey(roomId))
          .map(
            (roomId) => {
          "id": roomId,
          "name": _roomName(roomId),
        },
      ),
    ];

    return SizedBox(
      height: 42,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: tabs.length,
        onReorderItem: _handleReorder,
        proxyDecorator: _buildDragProxy,
        autoScrollerVelocityScalar: 70,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final roomId = tab["id"]!;
          final name = tab["name"]!;
          final selected = widget.selectedRoomId == roomId;

          final child = InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (!selected) {
                widget.onSelect(roomId);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.black87
                          : Colors.black.withValues(alpha: 0.45),
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeOutCubic,
                    height: 2,
                    width: selected
                        ? (name.runes.length * 8.5).clamp(22.0, 110.0).toDouble()
                        : 0,
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
            elevation: 8 * t,
            shadowColor: Colors.black.withValues(alpha: 0.14 * t),
            child: child,
          ),
        );
      },
    );
  }
}
