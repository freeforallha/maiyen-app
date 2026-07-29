import 'package:flutter/material.dart';

import '../../maiyen_theme.dart';
import '../../widgets/maiyen_wordmark.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.notificationTooltip,
    required this.unreadHomeNotificationCount,
    required this.onOpenHomeList,
    required this.onOpenNotifications,
    required this.onOpenSystemHealth,
  });

  final String notificationTooltip;
  final int unreadHomeNotificationCount;
  final VoidCallback onOpenHomeList;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSystemHealth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: MaiYenColors.surface,
                borderRadius: BorderRadius.circular(11),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onOpenHomeList,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: MaiYenColors.border),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.035),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: MaiYenColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onOpenSystemHealth,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const MaiYenWordmark(
                    suffix: 'Yen',
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.1,
                    leafSize: 28,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onOpenNotifications,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    tooltip: notificationTooltip,
                    icon: const Icon(Icons.notifications_rounded, size: 21),
                    style:
                        IconButton.styleFrom(
                          foregroundColor: MaiYenColors.info,
                          backgroundColor: Colors.transparent,
                          shape: const CircleBorder(),
                        ).copyWith(
                          overlayColor: WidgetStatePropertyAll(
                            MaiYenColors.info.withValues(alpha: 0.10),
                          ),
                        ),
                  ),
                  if (unreadHomeNotificationCount > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MaiYenColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MaiYenColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unreadHomeNotificationCount > 99
                              ? "99+"
                              : unreadHomeNotificationCount.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
