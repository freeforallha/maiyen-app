import 'package:flutter/material.dart';

class HomeTabs extends StatelessWidget {
  final Map<String, dynamic> homes;
  final List<String> homeOrder;
  final String selectedHome;

  final Function(String) onSelect;
  final Future<void> Function(int, int) onReorder;
  final Color Function(String) getHomeColor;
  final ScrollController controller;

  const HomeTabs({
    super.key,
    required this.homes,
    required this.homeOrder,
    required this.selectedHome,
    required this.onSelect,
    required this.onReorder,
    required this.getHomeColor,
    required this.controller,
  });

  static const double itemWidth = 82;
  static const double itemHeight = 60;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // FIX TRỤC CHÍNH
        children: [


          // ================= HOME LIST =================
          Expanded(
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              scrollController: controller,
              onReorder: onReorder,
              proxyDecorator: (child, index, animation) {
                return Material(color: Colors.transparent, child: child);
              },
              children: homeOrder.map((h) {
                final isSelected = h == selectedHome;
                final home = homes[h] ?? {};

                return Container(
                  key: ValueKey(h),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onSelect(h),

                    child: Align(
                      alignment: Alignment.topCenter, // FIX TRỤC
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: isSelected ? 1.0 : 0.4,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: itemWidth,
                              height: itemHeight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 6),
                              decoration: BoxDecoration(
                                color: getHomeColor(h),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                    color: Colors.white, width: 2)
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
                                    home["_customName"] ??
                                        home["name"] ??
                                        h,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  if (home["_shared"] == true)
                                    const Icon(
                                      Icons.people,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // ================= INDICATOR =================
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(top: 6),
                            height: 3,
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
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}