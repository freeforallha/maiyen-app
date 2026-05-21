import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> showShareListSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
}) async {
  final snap = await FirebaseDatabase.instance
      .ref("accounts/$ownerUid/shareList/$homeId")
      .get();

  final data = snap.value;

  final users = data == null ? {} : Map<String, dynamic>.from(data as Map);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,

    builder: (_) {
      return Container(
        padding: EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 46,
              height: 5,

              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            SizedBox(height: 18),

            Row(
              children: [
                Icon(Icons.people_alt_rounded),

                SizedBox(width: 10),

                Text(
                  "Shared Users",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            SizedBox(height: 18),

            if (users.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30),

                child: Text(
                  "Chưa share cho ai",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),

            ...users.entries.map((e) {
              final targetUid = e.key;

              final v = Map<String, dynamic>.from(e.value);

              final email = v["email"] ?? "Unknown";

              return Container(
                margin: EdgeInsets.only(bottom: 10),

                padding: EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    CircleAvatar(child: Icon(Icons.person)),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),

                      onPressed: () async {
                        // xóa shared home
                        await FirebaseDatabase.instance
                            .ref("accounts/$targetUid/sharedHomes/$homeId")
                            .remove();

                        // xóa sharedByHome
                        await FirebaseDatabase.instance
                            .ref("sharedByHome/$homeId/$targetUid")
                            .remove();

                        // xóa shareList
                        await FirebaseDatabase.instance
                            .ref(
                              "accounts/$ownerUid/shareList/$homeId/$targetUid",
                            )
                            .remove();

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Đã thu hồi quyền share")),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
