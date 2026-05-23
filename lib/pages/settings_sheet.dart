import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showSettingsSheet({
  required String homeId,
  required BuildContext context,
  required VoidCallback onShareRequests,
  required VoidCallback onShare,
  required VoidCallback onShareList,
  required VoidCallback onLogout,
  required VoidCallback onAlarm,
  required VoidCallback onRenameHome,
  required VoidCallback onDeleteHome,
  required int inviteCount,
  required VoidCallback onTransferOwner,
}) {
  final user = FirebaseAuth.instance.currentUser;

  Widget tile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                "HomeID: $homeId",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // ===== HOME SETTINGS =====

            tile(
              icon: Icons.schedule,
              title: "Giờ báo động",
              color: Colors.deepPurple,
              onTap: onAlarm,
            ),

            tile(
              icon: Icons.edit,
              title: "Sửa tên nhà",
              color: Colors.teal,
              onTap: onRenameHome,
            ),

            // ===== SHARE =====
            tile(
              icon: Icons.share_rounded,
              title: "Chia sẻ nhà",
              color: Colors.blue,
              onTap: onShare,
            ),

            tile(
              icon: Icons.people_alt_rounded,
              title: "Thành viên trong nhà",
              color: Colors.green,
              onTap: onShareList,
            ),

            // ===== INVITE =====
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mail_rounded, color: Colors.orange),
                ),
                title: Row(
                  children: [
                    const Text(
                      "Lời mời gia nhập",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (inviteCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$inviteCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onShareRequests,
              ),
            ),
            tile(
              icon: Icons.swap_horiz,
              title: "Chuyển quyền chủ nhà",
              color: Colors.purple,
              onTap: onTransferOwner,
            ),
            const SizedBox(height: 8),

            tile(
              icon: Icons.delete_forever,
              title: "Xoá Nhà",
              color: Colors.red,
              onTap: onDeleteHome,
            ),

          ],
        ),
      );
    },
  );
}