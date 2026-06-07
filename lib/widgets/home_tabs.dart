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

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};

    final visibleHomes = homeOrder
        .where((h) => homes.containsKey(h))
        .where((h) => seen.add(h))
        .toList();

    return SizedBox(
      height: 62,
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
          padding: const EdgeInsets.only(left: 6, right: 80, top: 8, bottom: 8),
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
            final unread = unreadChatByHome[h] ?? 0;

            final baseColor = getHomeColor(h);

            return RepaintBoundary(
              key: ValueKey("home_tab_$h"),
              child: ReorderableDelayedDragStartListener(
                index: index,
                child: GestureDetector(
                  onTap: () => onSelect(h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: isSelected ? 158 : 138,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? baseColor
                          : baseColor.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white,
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
    );
  }
}