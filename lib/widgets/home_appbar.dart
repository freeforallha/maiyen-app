import 'package:flutter/material.dart';

PreferredSizeWidget buildHomeAppBar() {
  return AppBar(
    title: Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.home_rounded, color: Colors.blueAccent, size: 20),
        ),

        SizedBox(width: 10),

        Text(
          "SafeHome",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),

    centerTitle: false,
    elevation: 0,
  );
}
