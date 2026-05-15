import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showSettingsSheet({
  required BuildContext context,
  required VoidCallback onShareRequests,
  required VoidCallback onShare,
  required VoidCallback onShareList,
  required VoidCallback onLogout,
  required int inviteCount,
}) {
  final user = FirebaseAuth.instance.currentUser;
  Widget tile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),

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

        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),

        trailing: Icon(Icons.chevron_right_rounded),

        onTap: onTap,
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,

    builder: (_) {
      return Container(
        padding: EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 42,
              height: 5,

              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            SizedBox(height: 18),

            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withValues(alpha: 0.1),

              child: Icon(Icons.person, size: 30, color: Colors.blue),
            ),

            SizedBox(height: 12),

            Text(
              user?.email ?? "",

              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            SizedBox(height: 22),

            tile(
              icon: Icons.share_rounded,
              title: "Chia sẻ Home",
              color: Colors.blue,
              onTap: onShare,
            ),

            tile(
              icon: Icons.people_alt_rounded,
              title: "List chia sẻ",
              color: Colors.green,
              onTap: onShareList,
            ),

            Container(
              margin: EdgeInsets.only(bottom: 10),
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
                  child: Icon(Icons.mail_rounded, color: Colors.orange),
                ),

                title: Row(
                  children: [
                    Text(
                      "Lời mời share",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    if (inviteCount > 0) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$inviteCount",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),

                trailing: Icon(Icons.chevron_right_rounded),
                onTap: onShareRequests,
              ),
            ),
            tile(
              icon: Icons.logout_rounded,
              title: "Đăng xuất",
              color: Colors.red,
              onTap: onLogout,
            ),

            SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
