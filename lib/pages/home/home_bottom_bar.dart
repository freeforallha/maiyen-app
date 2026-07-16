import 'package:flutter/material.dart';

import '../../safehome_theme.dart';

class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.addHomeTooltip,
    required this.unreadChatCount,
    required this.inviteCount,
    required this.onAddHome,
    required this.onOpenChat,
    required this.onOpenAlarm,
    required this.onOpenSettings,
  });

  final String addHomeTooltip;
  final int unreadChatCount;
  final int inviteCount;
  final VoidCallback onAddHome;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenAlarm;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: SafeHomeColors.surface.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SafeHomeColors.border, width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.075),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              minimumSize: const Size(46, 46),
              maximumSize: const Size(46, 46),
              padding: EdgeInsets.zero,
              foregroundColor: SafeHomeColors.textSecondary,
              backgroundColor: Colors.transparent,
              hoverColor: SafeHomeColors.primarySoft,
              highlightColor: SafeHomeColors.primarySoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                tooltip: addHomeTooltip,
                icon: const Icon(
                  Icons.add_home_work_rounded,
                  color: SafeHomeColors.primary,
                ),
                onPressed: onAddHome,
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_rounded,
                      color: SafeHomeColors.primary,
                    ),
                    onPressed: onOpenChat,
                  ),
                  if (unreadChatCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: SafeHomeColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: SafeHomeColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unreadChatCount > 99
                              ? "99+"
                              : unreadChatCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.crisis_alert_rounded,
                  color: SafeHomeColors.danger,
                ),
                onPressed: onOpenAlarm,
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: SafeHomeColors.textSecondary,
                    ),
                    onPressed: onOpenSettings,
                  ),
                  if (inviteCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
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
                          "$inviteCount",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
