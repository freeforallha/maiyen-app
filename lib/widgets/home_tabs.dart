import 'package:flutter/material.dart';

class HomeTabs extends StatelessWidget {
  final Map<String, dynamic> homes;
  final List<String> homeOrder;
  final String selectedHome;

  final Function(String) onSelect;
  final Future<void> Function(int, int) onReorder;
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

  static const double itemWidth = 82;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};

    final visibleHomes = homeOrder
        .where((h) => homes.containsKey(h))
        .where((h) => seen.add(h))
        .toList();

    return SizedBox(
      height: 72,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        scrollController: controller,
        itemCount: visibleHomes.length,
        onReorderItem: onReorder,
        proxyDecorator: (child, index, animation) {
          return Material(
            color: Colors.transparent,
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final h = visibleHomes[index];
          final isSelected = h == selectedHome;
          final home = Map<String, dynamic>.from(homes[h] ?? {});

          return RepaintBoundary(
            key: ValueKey("home_tab_$h"),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: Container(
                width: itemWidth,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onSelect(h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: isSelected ? 1.0 : 0.45,
                        child: Stack(
                          children: [
                            Container(
                              width: itemWidth,
                              height: 66,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: getHomeColor(h),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                  color: Colors.white,
                                  width: 2,
                                )
                                    : null,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    home["_customName"] ?? home["name"] ?? h,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (home["_shared"] == true)
                                    const Icon(
                                      Icons.people,
                                      size: 11,
                                      color: Colors.white70,
                                    ),
                                ],
                              ),
                            ),

                            if ((unreadChatByHome[h] ?? 0) > 0)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadChatByHome[h]! > 99
                                        ? "99+"
                                        : unreadChatByHome[h].toString(),
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

                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        height: 2,
                        width: isSelected ? itemWidth * 0.5 : 0,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(20),
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
    );
  }
}