import 'package:flutter/material.dart';

import '../../safehome_theme.dart';

class HomeHeaderBar extends StatelessWidget {
  const HomeHeaderBar({
    super.key,
    required this.notificationTooltip,
    required this.unreadHomeNotificationCount,
    required this.onOpenHomeList,
    required this.onOpenNotifications,
  });

  final String notificationTooltip;
  final int unreadHomeNotificationCount;
  final VoidCallback onOpenHomeList;
  final VoidCallback onOpenNotifications;

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
                color: SafeHomeColors.surface,
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
                      border: Border.all(color: SafeHomeColors.border),
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
                      color: SafeHomeColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
                children: [
                  TextSpan(
                    text: "Safe",
                    style: TextStyle(color: SafeHomeColors.primary),
                  ),
                  TextSpan(
                    text: "Home",
                    style: TextStyle(color: SafeHomeColors.textPrimary),
                  ),
                ],
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
                          foregroundColor: SafeHomeColors.info,
                          backgroundColor: Colors.transparent,
                          shape: const CircleBorder(),
                        ).copyWith(
                          overlayColor: WidgetStatePropertyAll(
                            SafeHomeColors.info.withValues(alpha: 0.10),
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
                          color: SafeHomeColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SafeHomeColors.surface,
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
