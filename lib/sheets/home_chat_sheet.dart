import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'share_list_sheet.dart';
import '../helpers/firebase_paths.dart';
void showHomeChatSheet({
  required BuildContext context,
  required String homeId,
  required String userName,
  required String userPhotoUrl,
  required String ownerUid,
  required bool canManageMembers,
  required bool isOwner,
}) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final controller = TextEditingController();
  final chatRef = FirebaseDatabase.instance.ref(FirebasePaths.homeMessages(homeId));
  final readRef = FirebaseDatabase.instance
      .ref(FirebasePaths.homeLastRead(homeId, user.uid));

  readRef.set(DateTime.now().millisecondsSinceEpoch);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded),

                  const SizedBox(width: 10),

                  const Text(
                    "Chat trong nhà",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    tooltip: "Xem thành viên",
                    icon: const Icon(Icons.people_alt_rounded),
                    onPressed: () {
                      showShareListSheet(
                        context: context,
                        ownerUid: ownerUid,
                        homeId: homeId,
                        canManageMembers: canManageMembers,
                        isOwner: isOwner,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: chatRef.orderByChild("time").limitToLast(80).onValue,
                  builder: (context, snapshot) {
                    final data = snapshot.data?.snapshot.value;

                    if (data == null) {
                      return Center(
                        child: Text(
                          "Chưa có tin nhắn",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final map = Map<String, dynamic>.from(data as Map);
                    final messages = map.entries.toList()
                      ..sort((a, b) {
                        final av = Map<String, dynamic>.from(a.value);
                        final bv = Map<String, dynamic>.from(b.value);
                        return (av["time"] ?? 0).compareTo(bv["time"] ?? 0);
                      });

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: messages.length,
                      itemBuilder: (_, index) {
                        final msg =
                        Map<String, dynamic>.from(messages[index].value);

                        final isMe = msg["uid"] == user.uid;
                        final name = msg["name"]?.toString() ?? "User";
                        final text = msg["text"]?.toString() ?? "";
                        final photoUrl = msg["photoUrl"]?.toString() ?? "";
                        final time = msg["time"];
                        final timeText = formatChatTime(time);

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe)
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage: photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl.isEmpty
                                        ? const Icon(Icons.person, size: 15)
                                        : null,
                                  ),

                                if (!isMe) const SizedBox(width: 6),

                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                      MediaQuery.of(ctx).size.width * 0.68,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe)
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              text,
                                              style: const TextStyle(fontSize: 14),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              timeText,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) async {
                        final text = controller.text.trim();

                        if (text.isEmpty) return;

                        controller.clear();

                        await chatRef.push().set({
                          "uid": user.uid,
                          "name": userName,
                          "photoUrl": userPhotoUrl,
                          "text": text,
                          "time": DateTime.now().millisecondsSinceEpoch,
                        });

                        await readRef.set(
                          DateTime.now().millisecondsSinceEpoch,
                        );
                      },
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Nhắn gì đó...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;

                        controller.clear();

                        await chatRef.push().set({

                          "uid": user.uid,
                          "name": userName,
                          "photoUrl": userPhotoUrl,
                          "text": text,
                          "time": DateTime.now().millisecondsSinceEpoch,
                        });
                        await readRef.set(DateTime.now().millisecondsSinceEpoch);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    controller.dispose();
  });
}
String formatChatTime(dynamic ts) {
  if (ts == null) return "--:--";

  final dt = DateTime.fromMillisecondsSinceEpoch(
    int.tryParse(ts.toString()) ?? 0,
  );

  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');

  return "$hh:$mm";
}