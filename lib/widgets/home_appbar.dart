import 'package:flutter/material.dart';

PreferredSizeWidget buildHomeAppBar({
  required VoidCallback onSchedule,
  required VoidCallback onRename,
  required VoidCallback onAddHome,
  required VoidCallback onDelete,
  required VoidCallback onSettings,
  required int inviteCount,
}) {
  return AppBar(
    title: Text("SafeHome"),
    actions: [
      IconButton(icon: Icon(Icons.schedule), onPressed: onSchedule),
      IconButton(icon: Icon(Icons.edit), onPressed: onRename),
      IconButton(icon: Icon(Icons.add_home), onPressed: onAddHome),
      IconButton(icon: Icon(Icons.delete), onPressed: onDelete),

      Stack(
        children: [
          IconButton(icon: Icon(Icons.settings_rounded), onPressed: onSettings),

          if (inviteCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$inviteCount",
                  style: TextStyle(
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
  );
}
