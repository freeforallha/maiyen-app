import 'package:flutter/material.dart';

class HomeTabs extends StatelessWidget {
  static const double _selectedTabWidth = 158;
  static const double _normalTabWidth = 138;
  static const double _tabSpacing = 10;
  static const Duration _tabAnimationDuration = Duration(milliseconds: 220);

  final Map<String, dynamic> homes;
  final List<String> homeOrder;
  final String selectedHome;

  final Function(String) onSelect;
  final Future<void> Function(List<String>) onReorder;
  final Color Function(String) getHomeColor;
  final ScrollController controller;
  final Map<String, int> unreadChatByHome;

  const HomeTabs({
    super.key,
    required this.homes,
    required this.homeOrder,
    required this.selectedHome,
    required this.onSelect,
    required this.onReorder,
    required this.getHomeColor,
    required this.controller,
    required this.unreadChatByHome,
  });

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};

    final visibleHomes = homeOrder
        .where((h) => homes.containsKey(h))
        .where((h) => seen.add(h))
        .toList();

    return SizedBox(
      height: 62,
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
              stops: [0.0, 0.04, 0.86, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(
              left: 6,
              right: 80,
              top: 8,
              bottom: 8,
            ),
            scrollDirection: Axis.horizontal,
            buildDefaultDragHandles: false,
            scrollController: controller,
            dragBoundaryProvider: (context) => DragBoundary.forRectOf(context),
            itemExtentBuilder: (index, _) {
              if (index >= visibleHomes.length) return null;

              return (visibleHomes[index] == selectedHome
                      ? _selectedTabWidth
                      : _normalTabWidth) +
                  _tabSpacing;
            },
            itemCount: visibleHomes.length,
            onReorderItem: (oldIndex, newIndex) async {
              final nextVisibleOrder = _reorderedVisibleHomes(
                visibleHomes,
                oldIndex,
                newIndex,
              );

              if (nextVisibleOrder == null) return;

              await onReorder(nextVisibleOrder);
            },
            proxyDecorator: _buildDragProxy,
            clipBehavior: Clip.hardEdge,
            autoScrollerVelocityScalar: 70,
            itemBuilder: (context, index) {
              final h = visibleHomes[index];
              final isSelected = h == selectedHome;
              final home = Map<String, dynamic>.from(homes[h] ?? {});
              final unread = unreadChatByHome[h] ?? 0;

              final baseColor = getHomeColor(h);

              return RepaintBoundary(
                key: ValueKey("home_tab_$h"),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: GestureDetector(
                    onTap: () => onSelect(h),
                    child: AnimatedContainer(
                      duration: _tabAnimationDuration,
                      curve: Curves.easeOutCubic,
                      width: isSelected ? _selectedTabWidth : _normalTabWidth,
                      margin: const EdgeInsets.only(right: _tabSpacing),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? baseColor
                            : baseColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? baseColor.withValues(alpha: 0.90)
                              : baseColor.withValues(alpha: 0.35),
                          width: isSelected ? 2.2 : 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isSelected ? 0.10 : 0.04,
                            ),
                            blurRadius: isSelected ? 10 : 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    home["_shared"] == true
                                        ? Icons.people_alt_rounded
                                        : Icons.home_rounded,
                                    size: 17,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    home["_customName"] ?? home["name"] ?? h,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSelected ? 14 : 13,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (unread > 0)
                            Positioned(
                              right: -4,
                              top: -5,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unread > 99 ? "99+" : unread.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static List<String>? _reorderedVisibleHomes(
    List<String> visibleHomes,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 || oldIndex >= visibleHomes.length) {
      return null;
    }

    final reorderedHomes = List<String>.from(visibleHomes);
    final item = reorderedHomes.removeAt(oldIndex);
    var targetIndex = newIndex;

    if (targetIndex < 0) {
      targetIndex = 0;
    } else if (targetIndex > reorderedHomes.length) {
      targetIndex = reorderedHomes.length;
    }

    reorderedHomes.insert(targetIndex, item);
    return reorderedHomes;
  }

  static Widget _buildDragProxy(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));

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
            shadowColor: Colors.black.withValues(alpha: 0.18 * t),
            borderRadius: BorderRadius.circular(22),
            child: child,
          ),
        );
      },
    );
  }
}
