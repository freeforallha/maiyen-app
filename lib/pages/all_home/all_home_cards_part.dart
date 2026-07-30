part of '../all_home_page.dart';

extension _AllHomeCardsPart on _AllHomeState {
  Widget buildSectionTitle(String groupKey, List<String> ids) {
    final isYourHomes = groupKey == "your_homes";

    String ownerText = "";

    if (!isYourHomes && ids.isNotEmpty) {
      final firstHome = safeMap(homes[ids.first]);
      ownerText = firstHome["_ownerEmail"]?.toString() ?? "Unknown";
    }

    final displayName =
        customNames[groupKey] ??
        (isYourHomes ? _strings.t("Nhà của tôi") : ownerText);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              final allSelected = ids.every(selectedHomes.contains);

              MaiYenNavigation.showModalSheet(
                context: context,
                showDragHandle: false,
                backgroundColor: Colors.transparent,
                builder: (_) {
                  return SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      decoration: const BoxDecoration(
                        color: MaiYenColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(26),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: MaiYenColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.edit_rounded,
                              color: MaiYenColors.info,
                            ),
                            title: Text(_strings.t("Đổi tên nhóm")),
                            onTap: () {
                              Navigator.pop(context);
                              renameGroup(groupKey);
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              allSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: MaiYenColors.primary,
                            ),
                            title: Text(
                              allSelected
                                  ? _strings.t("Bỏ chọn toàn bộ nhóm")
                                  : _strings.t("Chọn toàn bộ nhóm"),
                            ),
                            onTap: () {
                              Navigator.pop(context);

                              setState(() {
                                if (allSelected) {
                                  selectedHomes.removeAll(ids);
                                } else {
                                  selectedHomes.addAll(ids);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: MaiYenColors.textPrimary,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "(${ids.length})",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: MaiYenColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ids.map((homeId) {
              final data = safeMap(homes[homeId]);
              final unreadCount = unreadChatCounts[homeId] ?? 0;

              return SizedBox(
                width: 55,
                height: 55,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: buildHomeCard(context, homeId, data),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: buildUnreadChatBadge(unreadCount),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildUnreadChatBadge(int unreadCount) {
    return IgnorePointer(
      child: Container(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: MaiYenColors.danger,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: MaiYenColors.surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          unreadCount > 99 ? "99+" : unreadCount.toString(),
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget buildHomeCard(
    BuildContext context,
    String homeId,
    Map<String, dynamic> data,
  ) {
    final status = getHomeOverallStatus(data);
    final level = status["level"]?.toString() ?? "safe";
    final selected = selectedHomes.contains(homeId);

    final emergencyStatus = level == "emergency";
    final emergencyPulseColor = _emergencyPulseDanger
        ? MaiYenColors.danger
        : MaiYenColors.warning;
    final statusColor = emergencyStatus
        ? emergencyPulseColor
        : level == "danger"
        ? MaiYenColors.danger
        : level == "warning"
        ? MaiYenColors.warning
        : MaiYenColors.safe;
    final cardColor = emergencyStatus
        ? emergencyPulseColor.withValues(
            alpha: _emergencyPulseDanger ? 0.20 : 0.15,
          )
        : MaiYenColors.surface;

    final rawName = data["_customName"] ?? data["name"] ?? homeId;

    final displayName = rawName.toString().trim().isEmpty
        ? _strings.t("Nhà")
        : rawName.toString().trim();

    return InkWell(
      onTap: () {
        if (selectedHomes.isNotEmpty) {
          setState(() {
            if (selected) {
              selectedHomes.remove(homeId);
            } else {
              selectedHomes.add(homeId);
            }
          });

          return;
        }

        Navigator.pop(context, homeId);
      },
      onLongPress: () {
        setState(() {
          selectedHomes.add(homeId);
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration(milliseconds: emergencyStatus ? 420 : 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? MaiYenColors.primarySoft : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? MaiYenColors.primary
                : statusColor.withValues(alpha: emergencyStatus ? 0.95 : 0.68),
            width: selected
                ? 2.4
                : emergencyStatus
                ? 1.5
                : 1.25,
          ),
          boxShadow: [
            BoxShadow(
              color: emergencyStatus
                  ? statusColor.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.035),
              blurRadius: emergencyStatus ? 12 : 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 1,
                bottom: 1,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: MaiYenColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
