import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'share_list_sheet.dart';
import '../services/chat_service.dart';
import '../services/home_notification_service.dart';
import '../services/notification_service.dart';
import '../helpers/firebase_paths.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/top_toast.dart';
import '../safehome_theme.dart';
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
  final scrollController = ScrollController(initialScrollOffset: 0);
  final memberRoleCache = <String, String>{};
  final focusNode = FocusNode();
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();
  final messageKeys = <String, GlobalKey>{};

  bool showEmoji = false;
  bool isSearching = false;
  String searchQuery = "";
  int activeSearchResult = 0;
  List<String> currentSearchResultIds = [];
  Timer? typingHeartbeatTimer;
  bool isTypingPresenceActive = false;
  bool isChatSheetClosed = false;
  bool initialMessagesLoaded = false;
  bool autoScrollReady = false;
  Timer? initialScrollUnlockTimer;
  bool unreadSnapshotStarted = false;
  bool showUnreadNotice = false;
  int initialUnreadCount = 0;
  int initialLastRead = 0;
  int previousMessageCount = 0;

  void writeTypingPresence(bool isTyping) {
    ChatService.setTyping(
      homeId: homeId,
      uid: user.uid,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      isTyping: isTyping,
    ).catchError((_) {});
  }

  void stopTypingHeartbeat() {
    typingHeartbeatTimer?.cancel();
    typingHeartbeatTimer = null;
  }

  void syncTypingPresence({bool forceWrite = false}) {
    if (isChatSheetClosed) return;

    final hasDraft = controller.text.trim().isNotEmpty;

    if (!hasDraft) {
      stopTypingHeartbeat();

      if (isTypingPresenceActive) {
        isTypingPresenceActive = false;
        writeTypingPresence(false);
      }

      return;
    }

    if (!isTypingPresenceActive || forceWrite) {
      isTypingPresenceActive = true;
      writeTypingPresence(true);
    }

    typingHeartbeatTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (isChatSheetClosed || controller.text.trim().isEmpty) {
        stopTypingHeartbeat();

        if (isTypingPresenceActive) {
          isTypingPresenceActive = false;
          writeTypingPresence(false);
        }

        return;
      }

      writeTypingPresence(true);
    });
  }

  void handleDraftChanged() {
    syncTypingPresence();
  }

  void clearTypingPresence() {
    isChatSheetClosed = true;
    stopTypingHeartbeat();
    controller.removeListener(handleDraftChanged);

    if (isTypingPresenceActive) {
      isTypingPresenceActive = false;
      writeTypingPresence(false);
    }
  }

  controller.addListener(handleDraftChanged);

  void animateToLatestMessage() {
    if (isChatSheetClosed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isChatSheetClosed || !scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void scrollToMessage(String messageId) {
    if (isChatSheetClosed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isChatSheetClosed) return;

      final targetContext = messageKeys[messageId]?.currentContext;

      if (targetContext == null || !targetContext.mounted) {
        return;
      }

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: 0.35,
      );
    });
  }

  TextSpan highlightedSpan(String source, TextStyle baseStyle) {
    final query = searchQuery.trim();

    if (!isSearching || query.isEmpty) {
      return TextSpan(text: source, style: baseStyle);
    }

    final lowerSource = source.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final matchIndex = lowerSource.indexOf(lowerQuery, start);

      if (matchIndex < 0) {
        spans.add(TextSpan(text: source.substring(start), style: baseStyle));
        break;
      }

      if (matchIndex > start) {
        spans.add(
          TextSpan(text: source.substring(start, matchIndex), style: baseStyle),
        );
      }

      spans.add(
        TextSpan(
          text: source.substring(matchIndex, matchIndex + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Colors.yellow.shade300,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

      start = matchIndex + query.length;
    }

    return TextSpan(children: spans);
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
          .ref("homeMemberContacts/$homeId/$memberUid/phone")
          .get();

      phone = snap.value?.toString().trim() ?? "";
    } catch (e) {
      if (!sheetContext.mounted) return;

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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_disabled_rounded,
                            color: Colors.orange,
                            size: 27,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "Chưa có số điện thoại",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "$name chưa cập nhật số điện thoại trong hồ sơ.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                sheetContext,
                                rootNavigator: true,
                              ).pop();
                            },
                            child: const Text("Đã hiểu"),
                          ),
                        ),
                      ],
                    ),
                  )
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
                        if (!sheetContext.mounted) return;

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

    final cachedRole = memberRoleCache[uid];

    if (cachedRole != null) {
      return cachedRole;
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

  NotificationService.markHomeChatOpened(homeId);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (!unreadSnapshotStarted) {
            unreadSnapshotStarted = true;

            unawaited(() async {
              try {
                final snapshot = await FirebaseDatabase.instance
                    .ref("homeChats/$homeId")
                    .get();

                final raw = snapshot.value is Map
                    ? Map<String, dynamic>.from(snapshot.value as Map)
                    : <String, dynamic>{};

                final lastReadRaw = raw["lastRead"];
                final lastReadMap = lastReadRaw is Map
                    ? Map<String, dynamic>.from(lastReadRaw)
                    : <String, dynamic>{};

                initialLastRead =
                    int.tryParse(lastReadMap[user.uid]?.toString() ?? "0") ?? 0;

                initialUnreadCount = ChatService.unreadCount(
                  homeChat: raw,
                  uid: user.uid,
                );
              } catch (_) {
                initialUnreadCount = 0;
                initialLastRead = 0;
              }

              try {
                await ChatService.markAsRead(homeId: homeId, uid: user.uid);
              } catch (_) {
                // Không để lỗi cập nhật trạng thái đọc làm hỏng Home Chat.
              }

              if (isChatSheetClosed || !ctx.mounted) {
                return;
              }

              setState(() {
                showUnreadNotice = initialUnreadCount > 0;
              });
            }());
          }

          void moveSearchResult(int delta) {
            if (currentSearchResultIds.isEmpty) {
              return;
            }

            final resultCount = currentSearchResultIds.length;
            final nextIndex =
                (activeSearchResult + delta + resultCount) % resultCount;

            setState(() {
              activeSearchResult = nextIndex;
            });

            scrollToMessage(currentSearchResultIds[nextIndex]);
          }

          void openSearch() {
            if (isChatSheetClosed || isSearching) {
              return;
            }

            setState(() {
              isSearching = true;
              showEmoji = false;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isChatSheetClosed || !ctx.mounted || !isSearching) {
                return;
              }

              searchFocusNode.requestFocus();
            });
          }

          void closeSearch() {
            if (isChatSheetClosed || !isSearching) {
              return;
            }

            searchFocusNode.unfocus();

            setState(() {
              isSearching = false;
              searchController.clear();
              searchQuery = "";
              activeSearchResult = 0;
              currentSearchResultIds = [];
            });

            animateToLatestMessage();
          }

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
              final messageId = await ChatService.sendMessage(
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
                  severity: "info",
                  title: "Tin nhắn mới trong $homeName",
                  message: "$senderName: $preview",
                  entityType: "chat",
                  entityId: messageId,
                  homeName: homeName,
                  includeActor: false,
                  writeHomeTimeline: false,
                  data: {
                    "messageId": messageId,
                    "senderName": senderName,
                    "text": text,
                  },
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

          final screenSize = MediaQuery.sizeOf(ctx);
          final sheetHeight = screenSize.height * (showEmoji ? 0.86 : 0.72);

          return PopScope<void>(
            canPop: !isSearching,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop || !isSearching) {
                return;
              }

              closeSearch();
            },
            child: SizedBox(
              height: sheetHeight,
              child: Scaffold(
                resizeToAvoidBottomInset: true,
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
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
                                homeName.isNotEmpty
                                    ? homeName
                                    : "Chat trong nhà",
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
                              tooltip: "Tìm kiếm tin nhắn",
                              icon: Icon(
                                isSearching
                                    ? Icons.search_off_rounded
                                    : Icons.search_rounded,
                              ),
                              onPressed: isSearching ? closeSearch : openSearch,
                            ),

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

                        if (isSearching) ...[
                          const SizedBox(height: 8),

                          TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            autofocus: false,
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                activeSearchResult = 0;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Tìm nội dung hoặc tên người gửi",
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: "Xoá từ khoá",
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        searchController.clear();

                                        setState(() {
                                          searchQuery = "";
                                          activeSearchResult = 0;
                                          currentSearchResultIds = [];
                                        });
                                      },
                                    ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          if (searchQuery.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentSearchResultIds.isEmpty
                                          ? "Không có kết quả"
                                          : "${activeSearchResult + 1}/"
                                                "${currentSearchResultIds.length} kết quả",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Kết quả trước",
                                    visualDensity: VisualDensity.compact,
                                    onPressed: currentSearchResultIds.isEmpty
                                        ? null
                                        : () => moveSearchResult(-1),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Kết quả tiếp theo",
                                    visualDensity: VisualDensity.compact,
                                    onPressed: currentSearchResultIds.isEmpty
                                        ? null
                                        : () => moveSearchResult(1),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

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
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              }

                              final map = Map<String, dynamic>.from(
                                data as Map,
                              );
                              final messages = map.entries.toList()
                                ..sort((a, b) {
                                  final av = Map<String, dynamic>.from(a.value);
                                  final bv = Map<String, dynamic>.from(b.value);
                                  return (av["time"] ?? 0).compareTo(
                                    bv["time"] ?? 0,
                                  );
                                });

                              final activeMessageIds = messages
                                  .map((entry) => entry.key.toString())
                                  .toSet();

                              messageKeys.removeWhere(
                                (messageId, _) =>
                                    !activeMessageIds.contains(messageId),
                              );

                              final normalizedQuery = searchQuery
                                  .trim()
                                  .toLowerCase();

                              final nextSearchResultIds = <String>[];

                              if (isSearching && normalizedQuery.isNotEmpty) {
                                for (final entry in messages) {
                                  final rawMessage = Map<String, dynamic>.from(
                                    entry.value,
                                  );

                                  final name =
                                      rawMessage["name"]
                                          ?.toString()
                                          .toLowerCase() ??
                                      "";

                                  final text =
                                      rawMessage["text"]
                                          ?.toString()
                                          .toLowerCase() ??
                                      "";

                                  if (name.contains(normalizedQuery) ||
                                      text.contains(normalizedQuery)) {
                                    nextSearchResultIds.add(
                                      entry.key.toString(),
                                    );
                                  }
                                }
                              }

                              final resultsChanged =
                                  nextSearchResultIds.length !=
                                      currentSearchResultIds.length ||
                                  nextSearchResultIds.asMap().entries.any(
                                    (entry) =>
                                        entry.value !=
                                        currentSearchResultIds[entry.key],
                                  );

                              if (resultsChanged) {
                                currentSearchResultIds = nextSearchResultIds;

                                if (currentSearchResultIds.isEmpty) {
                                  activeSearchResult = 0;
                                } else if (activeSearchResult >=
                                    currentSearchResultIds.length) {
                                  activeSearchResult =
                                      currentSearchResultIds.length - 1;
                                }

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (isChatSheetClosed || !ctx.mounted) {
                                    return;
                                  }

                                  setState(() {});

                                  if (currentSearchResultIds.isNotEmpty) {
                                    scrollToMessage(
                                      currentSearchResultIds[activeSearchResult],
                                    );
                                  }
                                });
                              }

                              var loadedUnreadCount = 0;

                              if (initialUnreadCount > 0) {
                                for (final entry in messages) {
                                  final rawMessage = Map<String, dynamic>.from(
                                    entry.value,
                                  );
                                  final senderUid =
                                      rawMessage["uid"]?.toString() ?? "";
                                  final messageTime =
                                      int.tryParse(
                                        rawMessage["time"]?.toString() ?? "0",
                                      ) ??
                                      0;

                                  if (senderUid != user.uid &&
                                      messageTime > initialLastRead) {
                                    loadedUnreadCount++;
                                  }
                                }
                              }

                              final hiddenUnreadCount = math.max(
                                0,
                                initialUnreadCount - loadedUnreadCount,
                              );

                              final unreadNoticeCount = hiddenUnreadCount > 0
                                  ? hiddenUnreadCount
                                  : initialUnreadCount > 8
                                  ? initialUnreadCount
                                  : 0;

                              if (!initialMessagesLoaded) {
                                initialMessagesLoaded = true;
                                previousMessageCount = messages.length;

                                initialScrollUnlockTimer ??= Timer(
                                  const Duration(milliseconds: 900),
                                  () {
                                    if (!isChatSheetClosed) {
                                      autoScrollReady = true;
                                    }
                                  },
                                );
                              } else if (!isSearching &&
                                  autoScrollReady &&
                                  messages.length > previousMessageCount &&
                                  scrollController.hasClients) {
                                final distanceFromBottom =
                                    scrollController.position.pixels -
                                    scrollController.position.minScrollExtent;

                                if (distanceFromBottom <= 140) {
                                  animateToLatestMessage();
                                }
                              }

                              previousMessageCount = messages.length;

                              return Column(
                                children: [
                                  if (showUnreadNotice && unreadNoticeCount > 0)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          showUnreadNotice = false;
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 9,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.mark_chat_unread_rounded,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Còn $unreadNoticeCount tin nhắn "
                                                "chưa đọc",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.close_rounded,
                                              size: 17,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: scrollController,
                                      reverse: true,
                                      padding: const EdgeInsets.only(bottom: 8),
                                      itemCount: messages.length,
                                      itemBuilder: (_, index) {
                                        final messageEntry =
                                            messages[messages.length -
                                                1 -
                                                index];
                                        final messageId = messageEntry.key
                                            .toString();

                                        final msg = Map<String, dynamic>.from(
                                          messageEntry.value,
                                        );

                                        final isMe = msg["uid"] == user.uid;
                                        final name =
                                            msg["name"]?.toString() ?? "User";
                                        final senderUid =
                                            msg["uid"]?.toString() ?? "";
                                        final text =
                                            msg["text"]?.toString() ?? "";
                                        final photoUrl =
                                            msg["photoUrl"]?.toString() ?? "";
                                        final time = msg["time"];
                                        final timeText = formatChatTime(time);

                                        return KeyedSubtree(
                                          key: messageKeys.putIfAbsent(
                                            messageId,
                                            () => GlobalKey(),
                                          ),
                                          child: Align(
                                            alignment: isMe
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  if (!isMe)
                                                    GestureDetector(
                                                      onTap: () =>
                                                          openCallMemberSheet(
                                                            sheetContext: ctx,
                                                            memberUid:
                                                                msg["uid"]
                                                                    ?.toString() ??
                                                                "",
                                                            name: name,
                                                          ),
                                                      child: CircleAvatar(
                                                        radius: 14,
                                                        backgroundImage:
                                                            photoUrl.isNotEmpty
                                                            ? NetworkImage(
                                                                photoUrl,
                                                              )
                                                            : null,
                                                        child: photoUrl.isEmpty
                                                            ? const Icon(
                                                                Icons.person,
                                                                size: 15,
                                                              )
                                                            : null,
                                                      ),
                                                    ),
                                                  if (!isMe)
                                                    const SizedBox(width: 6),

                                                  Flexible(
                                                    child: Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxWidth:
                                                                screenSize
                                                                    .width *
                                                                0.68,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 9,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isMe
                                                            ? Colors
                                                                  .blue
                                                                  .shade100
                                                            : Colors
                                                                  .grey
                                                                  .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (!isMe)
                                                            FutureBuilder<
                                                              String
                                                            >(
                                                              future:
                                                                  getMemberRole(
                                                                    senderUid,
                                                                  ),
                                                              builder: (context, roleSnap) {
                                                                final role =
                                                                    roleSnap
                                                                        .data ??
                                                                    "member";

                                                                final icon =
                                                                    role ==
                                                                        "owner"
                                                                    ? Icons
                                                                          .workspace_premium_rounded
                                                                    : role ==
                                                                          "admin"
                                                                    ? Icons
                                                                          .admin_panel_settings_rounded
                                                                    : Icons
                                                                          .person_rounded;

                                                                final color =
                                                                    role ==
                                                                        "owner"
                                                                    ? Colors
                                                                          .blue
                                                                          .shade700
                                                                    : role ==
                                                                          "admin"
                                                                    ? Colors
                                                                          .deepPurple
                                                                          .shade700
                                                                    : Colors
                                                                          .blueGrey
                                                                          .shade700;

                                                                return GestureDetector(
                                                                  onTap: () => openCallMemberSheet(
                                                                    sheetContext:
                                                                        ctx,
                                                                    memberUid:
                                                                        senderUid,
                                                                    name: name,
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Icon(
                                                                        icon,
                                                                        size:
                                                                            13,
                                                                        color:
                                                                            color,
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            4,
                                                                      ),
                                                                      Flexible(
                                                                        child: Text.rich(
                                                                          highlightedSpan(
                                                                            name,
                                                                            TextStyle(
                                                                              fontSize: 11,
                                                                              fontWeight: FontWeight.w800,
                                                                              color: color,
                                                                            ),
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              SelectableText.rich(
                                                                highlightedSpan(
                                                                  text,
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ),

                                                              const SizedBox(
                                                                height: 4,
                                                              ),

                                                              Text(
                                                                timeText,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
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
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        _TypingIndicator(
                          typingStream: ChatService.typingStream(homeId),
                          currentUid: user.uid,
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

                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: SafeHomeColors.safe,
                                elevation: 3,
                                shadowColor: SafeHomeColors.safe.withValues(
                                  alpha: 0.35,
                                ),
                                shape: const CircleBorder(
                                  side: BorderSide(
                                    color: SafeHomeColors.primaryDark,
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: sendCurrentMessage,
                                  customBorder: const CircleBorder(),
                                  child: const Center(
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
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
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() async {
    NotificationService.markHomeChatClosed(homeId);
    initialScrollUnlockTimer?.cancel();
    clearTypingPresence();
    searchFocusNode.unfocus();
    focusNode.unfocus();
    messageKeys.clear();

    await Future<void>.delayed(const Duration(milliseconds: 350));

    controller.dispose();
    searchController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    searchFocusNode.dispose();
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

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({
    required this.typingStream,
    required this.currentUid,
  });

  final Stream<DatabaseEvent> typingStream;
  final String currentUid;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> {
  Timer? _staleRefreshTimer;

  @override
  void initState() {
    super.initState();

    _staleRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _staleRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: widget.typingStream,
      builder: (context, snapshot) {
        final members = ChatService.activeTypingMembers(
          typing: snapshot.data?.snapshot.value,
          currentUid: widget.currentUid,
        );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: members.isEmpty
              ? const SizedBox.shrink(key: ValueKey("typing-empty"))
              : _buildIndicator(context, members),
        );
      },
    );
  }

  Widget _buildIndicator(BuildContext context, List<ChatTypingMember> members) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      key: ValueKey(members.map((member) => member.uid).join("|")),
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            _buildAvatars(members),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _typingLabel(members),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.more_horiz_rounded, color: colors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatars(List<ChatTypingMember> members) {
    final previewMembers = members.take(3).toList();

    return SizedBox(
      width: 24 + math.max(0, previewMembers.length - 1) * 14,
      height: 24,
      child: Stack(
        children: [
          for (var index = 0; index < previewMembers.length; index++)
            Positioned(
              left: index * 14,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.blueGrey.shade100,
                  backgroundImage: previewMembers[index].photoUrl.isNotEmpty
                      ? NetworkImage(previewMembers[index].photoUrl)
                      : null,
                  child: previewMembers[index].photoUrl.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: Colors.blueGrey.shade500,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _typingLabel(List<ChatTypingMember> members) {
    final names = members.map(_typingName).toList();

    if (names.length == 1) {
      return "${names.first} đang chuẩn bị gửi tin...";
    }

    if (names.length == 2) {
      return "${names[0]} và ${names[1]} đang chuẩn bị gửi tin...";
    }

    return "${names.first} và ${names.length - 1} người khác đang chuẩn bị gửi tin...";
  }

  String _typingName(ChatTypingMember member) {
    final name = member.name.trim();

    if (name.isEmpty) return "Một thành viên";

    return name;
  }
}
