import 'package:flutter/material.dart';

class HomeTabs extends StatelessWidget {
  final Map<String, dynamic> homes;
  final List<String> homeOrder;
  final String selectedHome;

  final Function(String) onSelect;

  final Future<void> Function(int, int) onReorder;

  final Color Function(String) getHomeColor;

  final VoidCallback onOpenAllHome;
  final ScrollController controller;

  const HomeTabs({
    super.key,
    required this.homes,
    required this.homeOrder,
    required this.selectedHome,
    required this.onSelect,
    required this.onReorder,
    required this.getHomeColor,
    required this.onOpenAllHome,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      child: Row(
        children: [
          // ================= ALL HOME =================
          Padding(
            padding: EdgeInsets.only(left: 8, right: 8),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    onTap: onOpenAllHome,
                    child: Container(
                      width: 75,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueGrey.shade700,
                            Colors.blueGrey.shade900,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "ALL",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ================= HOME LIST =================
          Expanded(
            child: ReorderableListView(
              scrollController: controller,
              proxyDecorator: (child, index, animation) {
                return Material(color: Colors.transparent, child: child);
              },

              scrollDirection: Axis.horizontal,

              onReorder: onReorder,

              children: homeOrder.map((h) {
                return Container(
                  key: ValueKey(h),
                  margin: EdgeInsets.symmetric(horizontal: 6),

                  child: GestureDetector(
                    onTap: () => onSelect(h),

                    child: Opacity(
                      opacity: h == selectedHome ? 1.0 : 0.35,

                      child: Container(
                        width: 95,
                        height: 70,
                        alignment: Alignment.center,

                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: getHomeColor(h),

                          borderRadius: BorderRadius.circular(14),

                          border: h == selectedHome
                              ? Border.all(color: Colors.white, width: 2)
                              : null,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),

                        child: Builder(
                          builder: (_) {
                            final home = homes[h] ?? {};
                            final isShared = home["_shared"] == true;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Builder(
                                  builder: (_) {
                                    final displayName =
                                        home["_customName"] ??
                                        home["name"] ??
                                        h;

                                    return Text(
                                      displayName,

                                      textAlign: TextAlign.center,

                                      maxLines: 2,

                                      overflow: TextOverflow.ellipsis,

                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
                                ),

                                if (isShared) ...[
                                  SizedBox(height: 3),

                                  Icon(
                                    Icons.people,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
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
