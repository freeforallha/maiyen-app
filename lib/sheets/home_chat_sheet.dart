import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'share_list_sheet.dart';
import '../services/chat_service.dart';
import '../services/home_notification_service.dart';
import '../helpers/firebase_paths.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/top_toast.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

void showHomeChatSheet({
  required BuildContext context,
  required String homeId,
  required String homeName,
  required String userName,
  required String userPhotoUrl,
  required String ownerUid,
  required bool canManageMembers,
  required bool isOwner,
}) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final controller = TextEditingController();
  final scrollController = ScrollController();
  final memberRoleCache = <String, String>{};
  final focusNode = FocusNode();

  bool showEmoji = false;

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> openCallMemberSheet({
    required BuildContext sheetContext,
    required String memberUid,
    required String name,
  }) async {
    if (memberUid.isEmpty) {
      showTopToast(
        sheetContext,
        "Không tìm thấy người dùng",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    String phone = "";

    try {
      final snap = await FirebaseDatabase.instance
          .ref(FirebasePaths.account(memberUid))
          .get();

      final account = snap.value is Map
          ? Map<String, dynamic>.from(snap.value as Map)
          : <String, dynamic>{};

      final profile = account["profile"] is Map
          ? Map<String, dynamic>.from(account["profile"] as Map)
          : <String, dynamic>{};

      phone =
          profile["phone"]?.toString() ?? account["phone"]?.toString() ?? "";
    } catch (e) {
      showTopToast(
        sheetContext,
        "Không đọc được số điện thoại",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (!sheetContext.mounted) return;

    showModalBottomSheet(
      context: sheetContext,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                if (phone.trim().isEmpty)
                  const Text("Thành viên này chưa có số điện thoại")
                else
                  ListTile(
                    leading: const Icon(
                      Icons.phone_rounded,
                      color: Colors.green,
                    ),
                    title: Text(phone),
                    subtitle: const Text("Gọi điện"),
                    onTap: () async {
                      final uri = Uri(
                        scheme: "tel",
                        path: phone.replaceAll(" ", ""),
                      );

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        showTopToast(
                          sheetContext,
                          "Không mở được ứng dụng gọi điện",
                          color: Colors.red,
                          icon: Icons.phone_disabled_rounded,
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> getMemberRole(String uid) async {
    if (uid == ownerUid) return "owner";

    if (memberRoleCache.containsKey(uid)) {
      return memberRoleCache[uid]!;
    }

    final snap = await FirebaseDatabase.instance
        .ref(FirebasePaths.sharedMember(homeId, uid))
        .get();

    final data = snap.value is Map
        ? Map<String, dynamic>.from(snap.value as Map)
        : <String, dynamic>{};

    final role = data["role"]?.toString() ?? "member";

    memberRoleCache[uid] = role;
    return role;
  }

  ChatService.markAsRead(homeId: homeId, uid: user.uid);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> sendCurrentMessage() async {
            final text = controller.text.trim();

            if (text.isEmpty) return;
            if (text.length > ChatService.maxMessageLength) {
              ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                const SnackBar(content: Text("Tin nhắn quá dài")),
              );
              return;
            }

            controller.clear();

            try {
              await ChatService.sendMessage(
                homeId: homeId,
                uid: user.uid,
                userName: userName,
                userPhotoUrl: userPhotoUrl,
                text: text,
              );

              final senderName = userName.trim().isNotEmpty
                  ? userName.trim()
                  : "Một thành viên";
              final preview = text.length > 90
                  ? "${text.substring(0, 90)}..."
                  : text;

              try {
                await HomeNotificationService.notifyHome(
                  ownerUid: ownerUid,
                  homeId: homeId,
                  type: "chat",
                  category: "chat",
                  title: "Tin nhắn mới",
                  message: "$senderName: $preview",
                  entityType: "chat",
                  entityId: homeId,
                  includeActor: false,
                );
              } catch (_) {}
            } catch (_) {
              controller.text = text;

              if (!ctx.mounted) return;

              ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                const SnackBar(content: Text("Không gửi được tin nhắn")),
              );
            }
          }

          final media = MediaQuery.of(ctx);
          final bottomInset = showEmoji
              ? media.padding.bottom
              : math.max(media.viewInsets.bottom, media.padding.bottom);
          final maxSheetHeight = math.max(
            0.0,
            media.size.height - media.padding.top - bottomInset - 12,
          );
          final targetSheetHeight =
              media.size.height * (showEmoji ? 0.86 : 0.72);
          final sheetHeight = math.min(targetSheetHeight, maxSheetHeight);

          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: sheetHeight,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              clipBehavior: Clip.antiAlias,
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

                      Expanded(
                        child: Text(
                          homeName.isNotEmpty ? homeName : "Chat trong nhà",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
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
                            homeName: homeName,
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
                      stream: ChatService.messagesStream(homeId),
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

                        scrollToBottom();

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final msg = Map<String, dynamic>.from(
                              messages[index].value,
                            );

                            final isMe = msg["uid"] == user.uid;
                            final name = msg["name"]?.toString() ?? "User";
                            final senderUid = msg["uid"]?.toString() ?? "";
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
                                      GestureDetector(
                                        onTap: () => openCallMemberSheet(
                                          sheetContext: ctx,
                                          memberUid:
                                              msg["uid"]?.toString() ?? "",
                                          name: name,
                                        ),
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundImage: photoUrl.isNotEmpty
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: photoUrl.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 15,
                                                )
                                              : null,
                                        ),
                                      ),
                                    if (!isMe) const SizedBox(width: 6),

                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(ctx).size.width *
                                              0.68,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe)
                                              FutureBuilder<String>(
                                                future: getMemberRole(
                                                  senderUid,
                                                ),
                                                builder: (context, roleSnap) {
                                                  final role =
                                                      roleSnap.data ?? "member";

                                                  final icon = role == "owner"
                                                      ? Icons
                                                            .workspace_premium_rounded
                                                      : role == "admin"
                                                      ? Icons
                                                            .admin_panel_settings_rounded
                                                      : Icons.person_rounded;

                                                  final color = role == "owner"
                                                      ? Colors.blue.shade700
                                                      : role == "admin"
                                                      ? Colors
                                                            .deepPurple
                                                            .shade700
                                                      : Colors
                                                            .blueGrey
                                                            .shade700;

                                                  return GestureDetector(
                                                    onTap: () =>
                                                        openCallMemberSheet(
                                                          sheetContext: ctx,
                                                          memberUid: senderUid,
                                                          name: name,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          icon,
                                                          size: 13,
                                                          color: color,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            name,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: color,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                SelectableText(
                                                  text,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
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
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        onPressed: () {
                          FocusScope.of(ctx).unfocus();

                          setState(() {
                            showEmoji = !showEmoji;
                          });
                        },
                      ),

                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => sendCurrentMessage(),
                          onTap: () {
                            if (showEmoji) {
                              setState(() {
                                showEmoji = false;
                              });
                            }
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
                          onPressed: sendCurrentMessage,
                        ),
                      ),
                    ],
                  ),
                  if (showEmoji)
                    Flexible(
                      flex: 2,
                      fit: FlexFit.loose,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final pickerHeight = math.min(
                            280.0,
                            constraints.maxHeight,
                          );

                          if (pickerHeight <= 0) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            height: pickerHeight,
                            child: EmojiPicker(
                              textEditingController: controller,
                              config: Config(
                                height: pickerHeight,
                                checkPlatformCompatibility: false,
                                emojiViewConfig: EmojiViewConfig(
                                  emojiSizeMax: 28,
                                  columns: 7,
                                  backgroundColor: Colors.white,
                                ),
                                categoryViewConfig: CategoryViewConfig(
                                  backgroundColor: Colors.white,
                                  iconColor: Colors.grey,
                                  iconColorSelected: Colors.blue,
                                ),
                                bottomActionBarConfig:
                                    const BottomActionBarConfig(
                                      backgroundColor: Colors.white,
                                      buttonColor: Colors.white,
                                      buttonIconColor: Colors.grey,
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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
