import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void showSettingsSheet({
  required BuildContext context,
  required VoidCallback onShare,
  required VoidCallback onLogout,
}) {
  final user = FirebaseAuth.instance.currentUser;

  showModalBottomSheet(
    context: context,
    builder: (_) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user?.email ?? "",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            ListTile(
              leading: Icon(Icons.share),
              title: Text("Share Home"),
              onTap: onShare,
            ),

            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: onLogout,
            ),
          ],
        ),
      );
    },
  );
}
