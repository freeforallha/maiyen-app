import 'package:flutter/material.dart';

import '../safehome_theme.dart';
import '../localization/app_strings.dart';

class HomeTabs extends StatelessWidget {
  final Map<String, dynamic> homes;
  final List<String> homeOrder;
  final String selectedHome;

  final Function(String) onSelect;
  final Future<void> Function(List<String>) onReorder;
  final Color Function(String) getHomeColor;
  final ScrollController controller;
  final Map<String, int> unreadChatByHome;
  final String currentUserName;
  final String currentUserEmail;

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
    required this.currentUserName,
    required this.currentUserEmail,
  });

  void _showSelectedHomeInfo({
    required BuildContext context,
    required Map<String, dynamic> home,
    required String displayName,
    required bool isShared,
  }) {
    final strings = AppStrings.of(context);
    final address = home["address"]?.toString().trim() ?? "";

    final ownerName = isShared
        ? home["_ownerName"]?.toString().trim() ?? ""
        : currentUserName.trim();

    final ownerEmail = isShared
        ? home["_ownerEmail"]?.toString().trim() ?? ""
        : currentUserEmail.trim();

    final ownerDisplay = ownerName.isNotEmpty
        ? ownerName
        : ownerEmail.isNotEmpty
        ? ownerEmail
        : strings.t("Chưa có thông tin");

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              18,
            ),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: SafeHomeColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.04,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isShared
                            ? Icons.share_rounded
                            : Icons.home_rounded,
                        size: 34,
                        color: SafeHomeColors.primary,
                      ),
                      const SizedBox(height: 9),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SafeHomeColors.textPrimary,
                          fontSize: 19,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _homeInfoRow(
                        icon: Icons.location_on_outlined,
                        label: strings.t("Địa chỉ"),
                        value: address.isNotEmpty
                            ? address
                            : strings.t("Chưa cập nhật"),
                      ),
                      const SizedBox(height: 9),
                      _homeInfoRow(
                        icon: Icons.person_outline_rounded,
                        label: strings.t("Chủ nhà"),
                        value: ownerDisplay,
                        subtitle: ownerName.isNotEmpty &&
                            ownerEmail.isNotEmpty
                            ? ownerEmail
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _homeInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: SafeHomeColors.primary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: SafeHomeColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: SafeHomeColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null &&
                  subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SafeHomeColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final seen = <String>{};

    final visibleHomes = homeOrder
        .where((homeId) => homes.containsKey(homeId))
        .where(seen.add)
        .toList();

    if (visibleHomes.isEmpty) {
      return const SizedBox(height: 58);
    }

    return SizedBox(
      height: 58,
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
            stops: [0.0, 0.025, 0.93, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 3, 44, 3),
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          scrollController: controller,
          itemCount: visibleHomes.length,
          onReorderItem: (oldIndex, newIndex) {
            if (oldIndex < 0 ||
                oldIndex >= visibleHomes.length) {
              return;
            }

            final reorderedHomes =
            List<String>.from(visibleHomes);

            final movedHome =
            reorderedHomes.removeAt(oldIndex);

            final insertIndex = newIndex.clamp(
              0,
              reorderedHomes.length,
            );

            reorderedHomes.insert(
              insertIndex,
              movedHome,
            );

            onReorder(reorderedHomes);
          },
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1,
                  end: 1.035,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                ),
                child: child,
              ),
            );
          },
          itemBuilder: (context, index) {
            final homeId = visibleHomes[index];
            final isSelected = homeId == selectedHome;

            final home = Map<String, dynamic>.from(
              homes[homeId] ?? <String, dynamic>{},
            );

            final unread = unreadChatByHome[homeId] ?? 0;
            final statusColor = getHomeColor(homeId);

            final rawName =
                home["_customName"] ?? home["name"] ?? homeId;

            final displayName =
            rawName.toString().trim().isEmpty
                ? strings.t("Nhà chưa đặt tên")
                : rawName.toString().trim();

            final isShared = home["_shared"] == true;

            return RepaintBoundary(
              key: ValueKey("home_tab_$homeId"),
              child: ReorderableDelayedDragStartListener(
                index: index,
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: displayName,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isSelected) {
                        _showSelectedHomeInfo(
                          context: context,
                          home: home,
                          displayName: displayName,
                          isShared: isShared,
                        );
                        return;
                      }

                      onSelect(homeId);
                    },
                    child: AnimatedOpacity(
                      duration:
                      const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      opacity: isSelected ? 1 : 0.48,
                      child: AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 176 : 142,
                        margin:
                        const EdgeInsets.only(right: 8),
                        padding: EdgeInsets.fromLTRB(
                          isSelected ? 11 : 8,
                          5,
                          isSelected ? 15 : 12,
                          5,
                        ),
                        decoration: BoxDecoration(
                          color: SafeHomeColors.surface,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(
                              alpha:
                              isSelected ? 0.62 : 0.42,
                            ),
                            width:
                            isSelected ? 1.35 : 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withValues(
                                alpha:
                                isSelected ? 0.065 : 0.025,
                              ),
                              blurRadius:
                              isSelected ? 13 : 7,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isShared
                                      ? Icons.share_rounded
                                      : Icons.home_rounded,
                                  size:
                                  isSelected ? 24 : 21,
                                  color: statusColor,
                                ),
                                SizedBox(
                                  width:
                                  isSelected ? 10 : 8,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize:
                                          isSelected
                                              ? 17
                                              : 13,
                                          fontWeight:
                                          isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      if (isShared) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          strings.t("Nhà được chia sẻ"),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: statusColor
                                                .withValues(
                                              alpha: 0.82,
                                            ),
                                            fontSize:
                                            isSelected
                                                ? 10.5
                                                : 10,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (unread > 0)
                              Positioned(
                                right: -7,
                                top: -10,
                                child: Container(
                                  constraints:
                                  const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  alignment: Alignment.center,
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    SafeHomeColors.danger,
                                    borderRadius:
                                    BorderRadius.circular(
                                      999,
                                    ),
                                    border: Border.all(
                                      color:
                                      SafeHomeColors.surface,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SafeHomeColors
                                            .danger
                                            .withValues(
                                          alpha: 0.24,
                                        ),
                                        blurRadius: 8,
                                        offset:
                                        const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    unread > 99
                                        ? "99+"
                                        : unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight:
                                      FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
