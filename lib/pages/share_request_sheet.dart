import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void showShareRequestSheet({
  required BuildContext context,
  required Map<String, dynamic> requests,
  required String uid,
  required int inviteCount,
}) {
  showModalBottomSheet(
    context: context,

    builder: (_) {
      final list = requests.entries.toList();

      return Padding(
        padding: EdgeInsets.all(16),

        child: ListView.builder(
          itemCount: list.length,

          itemBuilder: (_, i) {
            final homeId = list[i].key;

            final data = Map<String, dynamic>.from(list[i].value);

            final ownerUid = data["ownerUid"] ?? "";

            final email = data["ownerEmail"] ?? "";

            return Card(
              child: ListTile(
                title: Text(email),

                subtitle: Text(homeId),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),

                      onPressed: () async {
                        await FirebaseDatabase.instance
                            .ref("accounts/$uid/shareRequests/$homeId")
                            .remove();

                        Navigator.pop(context);
                      },
                    ),

                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),

                      onPressed: () async {
                        await FirebaseDatabase.instance
                            .ref("accounts/$uid/sharedHomes/$homeId")
                            .set({"ownerUid": ownerUid});

                        await FirebaseDatabase.instance
                            .ref("accounts/$uid/shareRequests/$homeId")
                            .remove();

                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
