import 'package:flutter/material.dart';

PreferredSizeWidget buildHomeAppBar({
  required VoidCallback onSchedule,
  required VoidCallback onRename,
  required VoidCallback onAddHome,
  required VoidCallback onDelete,
  required VoidCallback onSettings,
}) {
  return AppBar(
    title: Text("SafeHome"),

    actions: [
      IconButton(icon: Icon(Icons.schedule), onPressed: onSchedule),

      IconButton(icon: Icon(Icons.edit), onPressed: onRename),

      IconButton(icon: Icon(Icons.add_home), onPressed: onAddHome),

      IconButton(icon: Icon(Icons.delete), onPressed: onDelete),

      IconButton(icon: Icon(Icons.settings_rounded), onPressed: onSettings),
    ],
  );
}
