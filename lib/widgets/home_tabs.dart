import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../helpers/emergency_pulse_ticker.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';

class HomeTabs extends StatefulWidget {
  final Map<String, dynamic> homes;
  final List<String> homeOrder;
  final String selectedHome;
  final bool singleHomeIdentityEnabled;

  final Function(String) onSelect;
  final Future<void> Function(List<String>) onReorder;
  final Color Function(String) getHomeColor;
  final ScrollController controller;
  final Map<String, int> unreadChatByHome;
  final String currentUserName;
  final String currentUserEmail;

  const HomeTabs({
    this.singleHomeIdentityEnabled = true,
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

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  bool _emergencyPulseDanger = false;

  Map<String, dynamic> get homes => widget.homes;
  List<String> get homeOrder => widget.homeOrder;
  String get selectedHome => widget.selectedHome;
  bool get singleHomeIdentityEnabled => widget.singleHomeIdentityEnabled;
  Function(String) get onSelect => widget.onSelect;
  Future<void> Function(List<String>) get onReorder => widget.onReorder;
  Color Function(String) get getHomeColor => widget.getHomeColor;
  ScrollController get controller => widget.controller;
  Map<String, int> get unreadChatByHome => widget.unreadChatByHome;
  String get currentUserName => widget.currentUserName;
  String get currentUserEmail => widget.currentUserEmail;

  @override
  void initState() {
    super.initState();
    EmergencyPulseTicker.ensureStarted();
    _emergencyPulseDanger = EmergencyPulseTicker.phase.value;
    EmergencyPulseTicker.phase.addListener(_handleSharedEmergencyPulse);
    _syncEmergencyPulse();
  }

  @override
  void didUpdateWidget(covariant HomeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEmergencyPulse();
  }

  @override
  void dispose() {
    EmergencyPulseTicker.phase.removeListener(_handleSharedEmergencyPulse);
    super.dispose();
  }

  bool _hasEmergencyHome() {
    for (final homeId in homeOrder) {
      if (homes.containsKey(homeId) &&
          getHomeColor(homeId) == SafeHomeColors.emergency) {
        return true;
      }
    }

    return false;
  }

  void _handleSharedEmergencyPulse() {
    if (!mounted || !_hasEmergencyHome()) {
      return;
    }

    final next = EmergencyPulseTicker.phase.value;
    if (_emergencyPulseDanger == next) {
      return;
    }

    setState(() {
      _emergencyPulseDanger = next;
    });
  }

  void _syncEmergencyPulse() {
    _emergencyPulseDanger = _hasEmergencyHome()
        ? EmergencyPulseTicker.phase.value
        : false;
  }

  bool _isEmergencyHome(String homeId) {
    return getHomeColor(homeId) == SafeHomeColors.emergency;
  }

  Color _displayHomeColor(String homeId) {
    if (!_isEmergencyHome(homeId)) {
      return getHomeColor(homeId);
    }

    return _emergencyPulseDanger
        ? SafeHomeColors.danger
        : SafeHomeColors.warning;
  }

  Color _homeCardBackground(String homeId) {
    if (!_isEmergencyHome(homeId)) {
      return SafeHomeColors.surface;
    }

    return _displayHomeColor(
      homeId,
    ).withValues(alpha: _emergencyPulseDanger ? 0.20 : 0.15);
  }

  Future<void> _showSelectedHomeInfo({
    required BuildContext context,
    required String homeId,
    required Map<String, dynamic> home,
    required String displayName,
    required bool isShared,
  }) async {
    final address = home["address"]?.toString().trim() ?? "";

    var ownerName = isShared
        ? home["_ownerName"]?.toString().trim() ?? ""
        : currentUserName.trim();

    var ownerEmail = isShared
        ? home["_ownerEmail"]?.toString().trim() ?? ""
        : currentUserEmail.trim();

    if (isShared && (ownerName.isEmpty || ownerEmail.isEmpty)) {
      final ownerUid = home["_ownerUid"]?.toString().trim() ?? "";

      if (ownerUid.isNotEmpty) {
        try {
          final directorySnapshot = await FirebaseDatabase.instance
              .ref("userDirectory/$ownerUid")
              .get();

          final directory = directorySnapshot.value is Map
              ? Map<String, dynamic>.from(directorySnapshot.value as Map)
              : <String, dynamic>{};

          final loadedName = directory["name"]?.toString().trim() ?? "";

          final loadedEmail = directory["email"]?.toString().trim() ?? "";

          if (ownerName.isEmpty) {
            ownerName = loadedName;
          }

          if (ownerEmail.isEmpty) {
            ownerEmail = loadedEmail;
          }
        } catch (_) {
          // Thử dữ liệu thành viên bên dưới.
        }

        if (ownerName.isEmpty || ownerEmail.isEmpty) {
          try {
            final memberSnapshot = await FirebaseDatabase.instance
                .ref("sharedByHome/$homeId/$ownerUid")
                .get();

            final member = memberSnapshot.value is Map
                ? Map<String, dynamic>.from(memberSnapshot.value as Map)
                : <String, dynamic>{};

            if (ownerName.isEmpty) {
              ownerName = member["name"]?.toString().trim() ?? "";
            }

            if (ownerEmail.isEmpty) {
              ownerEmail = member["email"]?.toString().trim() ?? "";
            }
          } catch (_) {}
        }
      }
    }

    if (!context.mounted) {
      return;
    }

    final strings = AppStrings.of(context);

    final ownerDisplay = ownerName.isNotEmpty
        ? ownerName
        : ownerEmail.isNotEmpty
        ? ownerEmail
        : strings.t("Chưa có thông tin");

    SafeHomeNavigation.showModalSheet<void>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    border: Border.all(color: SafeHomeColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isShared ? Icons.share_rounded : Icons.home_rounded,
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
                        subtitle: ownerName.isNotEmpty && ownerEmail.isNotEmpty
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
        Icon(icon, size: 19, color: SafeHomeColors.primary),
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
              if (subtitle != null && subtitle.trim().isNotEmpty) ...[
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

  int _presenceCount(Map<String, dynamic> home, String key) {
    final presenceSummary = home["presenceSummary"];

    if (presenceSummary is! Map) {
      return 0;
    }

    return int.tryParse(presenceSummary[key]?.toString() ?? "") ?? 0;
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
    if (visibleHomes.length == 1 && !singleHomeIdentityEnabled) {
      return const SizedBox(height: 58);
    }
    if (visibleHomes.length == 1) {
      final homeId = visibleHomes.first;

      final home = Map<String, dynamic>.from(
        homes[homeId] ?? <String, dynamic>{},
      );

      final rawName = home["_customName"] ?? home["name"] ?? homeId;

      final displayName = rawName.toString().trim().isEmpty
          ? strings.t("Nhà chưa đặt tên")
          : rawName.toString().trim();

      final address = home["address"]?.toString().trim() ?? "";
      final isShared = home["_shared"] == true;
      final statusColor = _displayHomeColor(homeId);
      final unread = unreadChatByHome[homeId] ?? 0;

      final totalMemberCount = _presenceCount(home, "totalMemberCount");
      final showMemberBadge = totalMemberCount > 0;

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              _showSelectedHomeInfo(
                context: context,
                homeId: homeId,
                home: home,
                displayName: displayName,
                isShared: isShared,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOut,
              height: 58,
              padding: const EdgeInsets.fromLTRB(13, 7, 13, 7),
              decoration: BoxDecoration(
                color: _homeCardBackground(homeId),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.46),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isEmergencyHome(homeId)
                        ? statusColor.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.045),
                    blurRadius: _isEmergencyHome(homeId) ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: showMemberBadge || unread > 0 ? 52 : 0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isShared ? Icons.share_rounded : Icons.home_rounded,
                          size: 25,
                          color: statusColor,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 17,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                address.isNotEmpty
                                    ? address
                                    : isShared
                                    ? strings.t("Nhà được chia sẻ")
                                    : strings.t("Nhà của bạn"),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SafeHomeColors.textSecondary
                                      .withValues(alpha: 0.82),
                                  fontSize: 11,
                                  height: 1.05,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showMemberBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            totalMemberCount.toString(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 21,
                          minHeight: 21,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SafeHomeColors.danger,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: SafeHomeColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          unread > 99 ? "99+" : unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
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
            if (oldIndex < 0 || oldIndex >= visibleHomes.length) {
              return;
            }

            final reorderedHomes = List<String>.from(visibleHomes);

            final movedHome = reorderedHomes.removeAt(oldIndex);

            final insertIndex = newIndex.clamp(0, reorderedHomes.length);

            reorderedHomes.insert(insertIndex, movedHome);

            onReorder(reorderedHomes);
          },
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.035).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
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
            final statusColor = _displayHomeColor(homeId);

            final rawName = home["_customName"] ?? home["name"] ?? homeId;

            final displayName = rawName.toString().trim().isEmpty
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
                          homeId: homeId,
                          home: home,
                          displayName: displayName,
                          isShared: isShared,
                        );
                        return;
                      }

                      onSelect(homeId);
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      opacity: isSelected ? 1 : 0.48,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 176 : 142,
                        height: 52,
                        margin: const EdgeInsets.only(right: 8),
                        padding: EdgeInsets.fromLTRB(
                          isSelected ? 11 : 8,
                          4,
                          isSelected ? 15 : 12,
                          4,
                        ),
                        decoration: BoxDecoration(
                          color: _homeCardBackground(homeId),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(
                              alpha: isSelected ? 0.62 : 0.42,
                            ),
                            width: isSelected ? 1.35 : 0.9,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isEmergencyHome(homeId)
                                  ? statusColor.withValues(alpha: 0.20)
                                  : Colors.black.withValues(
                                      alpha: isSelected ? 0.065 : 0.025,
                                    ),
                              blurRadius: _isEmergencyHome(homeId)
                                  ? 16
                                  : isSelected
                                  ? 13
                                  : 7,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  isShared
                                      ? Icons.share_rounded
                                      : Icons.home_rounded,
                                  size: isSelected ? 24 : 21,
                                  color: statusColor,
                                ),
                                SizedBox(width: isSelected ? 10 : 8),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: isSelected ? 17 : 13,
                                          height: 1.05,
                                          fontWeight: isSelected
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
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: statusColor.withValues(
                                              alpha: 0.82,
                                            ),
                                            fontSize: isSelected ? 10.5 : 10,
                                            height: 1.05,
                                            fontWeight: FontWeight.w600,
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
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SafeHomeColors.danger,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: SafeHomeColors.surface,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SafeHomeColors.danger.withValues(
                                          alpha: 0.24,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    unread > 99 ? "99+" : unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
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
