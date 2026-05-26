import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> showShareListSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required bool canManageMembers,
  required bool isOwner,
}) async {
  final db = FirebaseDatabase.instance;

  final ownerSnap = await db.ref("accounts/$ownerUid").get();

  final ownerData = ownerSnap.value is Map
      ? Map<String, dynamic>.from(ownerSnap.value as Map)
      : <String, dynamic>{};

  final ownerProfile = ownerData["profile"] is Map
      ? Map<String, dynamic>.from(ownerData["profile"] as Map)
      : <String, dynamic>{};

  final ownerEmail = ownerData["email"]?.toString() ?? "Owner";
  final ownerName = ownerProfile["name"]?.toString() ?? "";
  final ownerPhotoUrl = ownerProfile["photoUrl"]?.toString() ?? "";

  final snap = await db.ref("sharedByHome/$homeId").get();

  final users = snap.value is Map
      ? Map<String, dynamic>.from(snap.value as Map)
      : <String, dynamic>{};

  Future<Map<String, dynamic>> loadMember(
      String memberUid,
      dynamic rawValue,
      ) async {
    final raw = rawValue is Map
        ? Map<String, dynamic>.from(rawValue)
        : <String, dynamic>{};

    final accountSnap = await db.ref("accounts/$memberUid").get();

    final account = accountSnap.value is Map
        ? Map<String, dynamic>.from(accountSnap.value as Map)
        : <String, dynamic>{};

    final profile = account["profile"] is Map
        ? Map<String, dynamic>.from(account["profile"] as Map)
        : <String, dynamic>{};

    final email =
        raw["email"]?.toString() ??
            account["email"]?.toString() ??
            "Unknown";

    final name =
    raw["name"]?.toString().isNotEmpty == true
        ? raw["name"].toString()
        : profile["name"]?.toString().isNotEmpty == true
        ? profile["name"].toString()
        : account["name"]?.toString().isNotEmpty == true
        ? account["name"].toString()
        : email;

    final photoUrl =
    raw["photoUrl"]?.toString().isNotEmpty == true
        ? raw["photoUrl"].toString()
        : profile["photoUrl"]?.toString() ?? "";

    return {
      "uid": memberUid,
      "email": email,
      "name": name,
      "photoUrl": photoUrl,
      "role": raw["role"]?.toString() ?? "member",
    };
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
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

            const SizedBox(height: 18),

            const Row(
              children: [
                Icon(Icons.people_alt_rounded),
                SizedBox(width: 10),
                Text(
                  "Thành viên trong nhà",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    backgroundImage: ownerPhotoUrl.isNotEmpty
                        ? NetworkImage(ownerPhotoUrl)
                        : null,
                    child: ownerPhotoUrl.isEmpty
                        ? const Icon(
                      Icons.home_rounded,
                      color: Colors.blue,
                    )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownerName.isNotEmpty ? ownerName : ownerEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ownerEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "OWNER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  "Chưa share cho ai",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),

            ...users.entries.map((e) {
              final targetUid = e.key;

              return FutureBuilder<Map<String, dynamic>>(
                future: loadMember(targetUid, e.value),
                builder: (context, snapshot) {
                  final member = snapshot.data ?? {};

                  final email = member["email"]?.toString() ?? "Loading...";
                  final name = member["name"]?.toString() ?? email;
                  final photoUrl = member["photoUrl"]?.toString() ?? "";
                  final role = member["role"]?.toString() ?? "member";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == "admin"
                                ? Colors.deepPurple.withValues(alpha: 0.12)
                                : Colors.blueGrey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: role == "admin" ? Colors.deepPurple : Colors.blueGrey,
                            ),
                          ),
                        ),
                        if (isOwner) ...[
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.manage_accounts_rounded),

                            onSelected: (value) async {
                              await db
                                  .ref("sharedByHome/$homeId/$targetUid/role")
                                  .set(value);

                              await db
                                  .ref("accounts/$targetUid/sharedHomes/$homeId/role")
                                  .set(value);

                              if (!context.mounted) return;

                              Navigator.pop(context);

                              showShareListSheet(
                                context: context,
                                ownerUid: ownerUid,
                                homeId: homeId,
                                canManageMembers: canManageMembers,
                                isOwner: isOwner,
                              );
                            },

                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: "member",
                                child: Text("Member"),
                              ),

                              const PopupMenuItem(
                                value: "admin",
                                child: Text("Admin"),
                              ),
                            ],
                          ),

                          const SizedBox(width: 4),
                        ],

                        const SizedBox(width: 6),
                        if (canManageMembers)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await db
                                .ref("accounts/$targetUid/sharedHomes/$homeId")
                                .remove();

                            await db
                                .ref("sharedByHome/$homeId/$targetUid")
                                .remove();

                            await db
                                .ref(
                              "accounts/$ownerUid/shareList/$homeId/$targetUid",
                            )
                                .remove();

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Đã thu hồi quyền share"),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      );
    },
  );
}