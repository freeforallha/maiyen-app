import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../safehome_theme.dart';
import '../localization/app_strings.dart';

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
  static const Duration _animationDuration =
  Duration(milliseconds: 220);

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

  List<String> _orderedRoomIds(
      Map<String, dynamic> rooms,
      ) {
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

        final aOrder =
            int.tryParse(aData["order"]?.toString() ?? "") ??
                999;
        final bOrder =
            int.tryParse(bData["order"]?.toString() ?? "") ??
                999;

        return aOrder.compareTo(bOrder);
      });

    return entries
        .map((entry) => entry.key.toString())
        .toList();
  }

  String _roomName(String roomId) {
    final raw = widget.rooms[roomId];

    final room = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final name = room["name"]?.toString().trim() ?? "";

    return name.isNotEmpty ? name : roomId;
  }

  Future<void> _handleReorder(
      int oldIndex,
      int newIndex,
      ) async {
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
      await widget.onReorder(
        List<String>.from(movable),
      );
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
    final strings = AppStrings.of(context);
    final tabs = <Map<String, String>>[
      {
        "id": "overview",
        "name": widget.homeName.trim().isNotEmpty
            ? widget.homeName.trim()
            : strings.t("Nhà"),
      },
      ..._roomOrder
          .where(widget.rooms.containsKey)
          .map(
            (roomId) => {
          "id": roomId,
          "name": _roomName(roomId),
        },
      ),
    ];

    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: Container(
              height: 1,
              color: SafeHomeColors.border,
            ),
          ),
          Positioned.fill(
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
                  stops: [0, 0.025, 0.95, 1],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  30,
                  0,
                ),
                itemCount: tabs.length,
                onReorderItem: _handleReorder,
                proxyDecorator: _buildDragProxy,
                autoScrollerVelocityScalar: 70,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final roomId = tab["id"]!;
                  final name = tab["name"]!;
                  final selected =
                      widget.selectedRoomId == roomId;

                  final tabContent = _RoomTabItem(
                    name: name,
                    selected: selected,
                    onTap: () {
                      if (!selected) {
                        widget.onSelect(roomId);
                      }
                    },
                  );

                  if (index == 0) {
                    return Container(
                      key: const ValueKey(
                        "room_tab_overview",
                      ),
                      margin:
                      const EdgeInsets.only(right: 2),
                      child: tabContent,
                    );
                  }

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey("room_tab_$roomId"),
                    index: index,
                    child: Container(
                      margin:
                      const EdgeInsets.only(right: 2),
                      child: tabContent,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
          scale: 1 + (0.025 * t),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: SafeHomeColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SafeHomeColors.primary.withValues(
                    alpha: 0.18,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.10 * t,
                    ),
                    blurRadius: 14 * t,
                    offset: Offset(0, 5 * t),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _RoomTabItem extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _RoomTabItem({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedOpacity(
            duration: _RoomTabsState._animationDuration,
            curve: Curves.easeOutCubic,
            opacity: selected ? 1 : 0.45,
            child: AnimatedContainer(
              duration:
              _RoomTabsState._animationDuration,
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(
                minWidth: 56,
                maxWidth: 132,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              color: Colors.transparent,
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: _RoomTabsState._animationDuration,
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: selected ? 16 : 13.5,
                  fontWeight: selected
                      ? FontWeight.w900
                      : FontWeight.w600,
                  color: selected
                      ? SafeHomeColors.textPrimary
                      : SafeHomeColors.textSecondary,
                  letterSpacing: selected ? -0.2 : -0.05,
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
