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
  bool initialUnreadSnapshotReady = false;
  bool showUnreadNotice = false;
  int initialUnreadCount = 0;
  int initialLastRead = 0;
  int lastMarkedReadMessageTime = 0;
  int previousMessageCount = 0;

  // Chỉ tải 15 tin gần nhất khi mở Chat.
  // Khi người dùng cuộn lên gần đầu danh sách, tải thêm từng 15 tin.
  int messageLimit = 15;
  bool hasMoreMessages = true;
  bool loadingOlderMessages = false;
  bool messagePaginationListenerAdded = false;

  String replyingToMessageId = "";
  Map<String, dynamic>? replyingToMessage;
  bool mentionMembersLoadStarted = false;
  List<_HomeChatMentionMember> mentionMembers = const [];
  bool showMentionSuggestions = false;
  String mentionQuery = "";
  int mentionStartIndex = -1;
  final selectedMentions = <String, String>{};
  StateSetter? chatSetState;

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

  void syncMentionStateFromDraft() {
    if (isChatSheetClosed) return;

    final selection = controller.selection;
    var nextShow = false;
    var nextQuery = "";
    var nextStart = -1;

    if (selection.isValid && selection.isCollapsed) {
      final cursor = selection.baseOffset;

      if (cursor >= 0 && cursor <= controller.text.length) {
        final beforeCursor = controller.text.substring(0, cursor);
        final match = RegExp(r'(^|\s)@([^\s@]*)$').firstMatch(
          beforeCursor,
        );

        if (match != null) {
          nextShow = true;
          nextQuery = match.group(2) ?? "";
          nextStart = match.start + (match.group(1)?.length ?? 0);
        }
      }
    }

    if (nextShow == showMentionSuggestions &&
        nextQuery == mentionQuery &&
        nextStart == mentionStartIndex) {
      return;
    }

    showMentionSuggestions = nextShow;
    mentionQuery = nextQuery;
    mentionStartIndex = nextStart;

    chatSetState?.call(() {});
  }

  void handleDraftChanged() {
    syncTypingPresence();
    syncMentionStateFromDraft();
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

  TextSpan highlightedSpan(
      String source,
      TextStyle baseStyle, {
        Map<String, String> mentions = const <String, String>{},
      }) {
    final query = searchQuery.trim();

    if (isSearching && query.isNotEmpty) {
      final lowerSource = source.toLowerCase();
      final lowerQuery = query.toLowerCase();
      final spans = <TextSpan>[];
      var start = 0;

      while (true) {
        final matchIndex = lowerSource.indexOf(lowerQuery, start);

        if (matchIndex < 0) {
          spans.add(
            TextSpan(
              text: source.substring(start),
              style: baseStyle,
            ),
          );
          break;
        }

        if (matchIndex > start) {
          spans.add(
            TextSpan(
              text: source.substring(start, matchIndex),
              style: baseStyle,
            ),
          );
        }

        spans.add(
          TextSpan(
            text: source.substring(
              matchIndex,
              matchIndex + query.length,
            ),
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

    final mentionNames = mentions.values
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    if (mentionNames.isEmpty) {
      return TextSpan(text: source, style: baseStyle);
    }

    final mentionPattern = RegExp(
      '@(?:${mentionNames.map(RegExp.escape).join('|')})'
      r'(?=$|[\s.,!?;:])',
      caseSensitive: false,
    );

    final spans = <TextSpan>[];
    var start = 0;

    for (final match in mentionPattern.allMatches(source)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: source.substring(start, match.start),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: source.substring(match.start, match.end),
          style: baseStyle.copyWith(
            color: SafeHomeColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

      start = match.end;
    }

    if (start < source.length) {
      spans.add(
        TextSpan(
          text: source.substring(start),
          style: baseStyle,
        ),
      );
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
  Future<List<_HomeChatMentionMember>> loadMentionMembers() async {
    final membersByUid = <String, _HomeChatMentionMember>{};

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("sharedByHome/$homeId")
          .get();

      final raw = snapshot.value;

      if (raw is Map) {
        final membersMap = Map<String, dynamic>.from(raw);

        for (final entry in membersMap.entries) {
          final memberUid = entry.key.toString().trim();

          if (memberUid.isEmpty ||
              memberUid == user.uid ||
              entry.value is! Map) {
            continue;
          }

          final memberData = Map<String, dynamic>.from(
            entry.value as Map,
          );

          final memberName =
              memberData["name"]?.toString().trim() ??
                  memberData["displayName"]?.toString().trim() ??
                  memberData["email"]?.toString().trim() ??
                  "";

          if (memberName.isEmpty) {
            continue;
          }

          membersByUid[memberUid] = _HomeChatMentionMember(
            uid: memberUid,
            name: memberName,
            photoUrl:
            memberData["photoUrl"]?.toString().trim() ?? "",
          );
        }
      }
    } catch (_) {
      // Vẫn tiếp tục thử tải hồ sơ Owner.
    }

    if (ownerUid.isNotEmpty &&
        ownerUid != user.uid &&
        !membersByUid.containsKey(ownerUid)) {
      try {
        final ownerSnapshot = await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/profile")
            .get();

        final rawOwner = ownerSnapshot.value;

        if (rawOwner is Map) {
          final ownerData = Map<String, dynamic>.from(rawOwner);

          final ownerName =
              ownerData["name"]?.toString().trim() ??
                  ownerData["email"]?.toString().trim() ??
                  "";

          if (ownerName.isNotEmpty) {
            membersByUid[ownerUid] = _HomeChatMentionMember(
              uid: ownerUid,
              name: ownerName,
              photoUrl:
              ownerData["photoUrl"]?.toString().trim() ?? "",
            );
          }
        }
      } catch (_) {}
    }

    final members = membersByUid.values.toList()
      ..sort(
            (a, b) => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
      );

    return members;
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
          chatSetState = setState;

          if (!messagePaginationListenerAdded) {
            messagePaginationListenerAdded = true;

            scrollController.addListener(() {
              if (isChatSheetClosed ||
                  !scrollController.hasClients ||
                  loadingOlderMessages ||
                  !hasMoreMessages) {
                return;
              }

              final position = scrollController.position;

              // List đang reverse: true. Cuộn lên phía tin cũ sẽ tiến
              // gần maxScrollExtent.
              if (position.pixels < position.maxScrollExtent - 120) {
                return;
              }

              loadingOlderMessages = true;
              messageLimit += 15;

              chatSetState?.call(() {});
            });
          }

          if (!mentionMembersLoadStarted) {
            mentionMembersLoadStarted = true;

            unawaited(() async {
              final loadedMembers = await loadMentionMembers();

              if (isChatSheetClosed || !ctx.mounted) {
                return;
              }

              setState(() {
                mentionMembers = loadedMembers;
              });
            }());
          }
          if (!unreadSnapshotStarted) {
            unreadSnapshotStarted = true;

            unawaited(() async {
              try {
                final results = await Future.wait([
                  FirebaseDatabase.instance
                      .ref(FirebasePaths.chatUnreadHome(user.uid, homeId))
                      .get(),
                  FirebaseDatabase.instance
                      .ref(FirebasePaths.homeLastRead(homeId, user.uid))
                      .get(),
                ]);

                final unreadRaw = results[0].value;
                final legacyLastRead =
                    int.tryParse(results[1].value?.toString() ?? "0") ?? 0;

                initialUnreadCount =
                    ChatService.unreadCounterCount(unreadRaw);
                initialLastRead = math.max(
                  ChatService.unreadCounterLastReadAt(unreadRaw),
                  legacyLastRead,
                ).toInt();
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
                initialUnreadSnapshotReady = true;
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
          void beginReply({
            required String messageId,
            required Map<String, dynamic> message,
          }) {
            final text = message["text"]?.toString().trim() ?? "";

            if (messageId.isEmpty || text.isEmpty) {
              return;
            }

            setState(() {
              replyingToMessageId = messageId;
              replyingToMessage = Map<String, dynamic>.from(message);
              showEmoji = false;
            });

            focusNode.requestFocus();
          }

          void cancelReply() {
            if (replyingToMessage == null) {
              return;
            }

            setState(() {
              replyingToMessageId = "";
              replyingToMessage = null;
            });
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

            final currentReplyId = replyingToMessageId;
            final currentReply = replyingToMessage == null
                ? null
                : Map<String, dynamic>.from(replyingToMessage!);

            final currentMentions = <String, String>{};

            for (final entry in selectedMentions.entries) {
              final mentionText = "@${entry.value}".toLowerCase();

              if (text.toLowerCase().contains(mentionText)) {
                currentMentions[entry.key] = entry.value;
              }
            }

            controller.clear();

            setState(() {
              replyingToMessageId = "";
              replyingToMessage = null;
              selectedMentions.clear();
              showMentionSuggestions = false;
              mentionQuery = "";
              mentionStartIndex = -1;
            });

            try {
              final messageId = await ChatService.sendMessage(
                homeId: homeId,
                uid: user.uid,
                userName: userName,
                userPhotoUrl: userPhotoUrl,
                text: text,
                mentions: currentMentions,
                replyToMessageId: currentReplyId,
                replyToUid: currentReply?["uid"]?.toString() ?? "",
                replyToName: currentReply?["name"]?.toString() ?? "",
                replyToText: currentReply?["text"]?.toString() ?? "",
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
                    "replyToMessageId": currentReplyId,
                    "mentionedUids": currentMentions.keys.join(","),
                  },
                );
              } catch (_) {}
            } catch (error) {
              debugPrint("HOME_CHAT_SEND_ERROR: $error");

              if (!isChatSheetClosed && ctx.mounted) {
                controller.text = text;
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );

                setState(() {
                  replyingToMessageId = currentReplyId;
                  replyingToMessage = currentReply;
                  selectedMentions
                    ..clear()
                    ..addAll(currentMentions);
                });

                ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                  const SnackBar(content: Text("Không gửi được tin nhắn")),
                );
              }
            }
          }

          void selectMention(_HomeChatMentionMember member) {
            final selection = controller.selection;
            final cursor = selection.isValid
                ? selection.baseOffset
                : controller.text.length;

            if (mentionStartIndex < 0 ||
                cursor < mentionStartIndex ||
                cursor > controller.text.length) {
              return;
            }

            final replacement = "@${member.name} ";
            final nextText = controller.text.replaceRange(
              mentionStartIndex,
              cursor,
              replacement,
            );
            final nextCursor = mentionStartIndex + replacement.length;

            selectedMentions[member.uid] = member.name;

            controller.value = TextEditingValue(
              text: nextText,
              selection: TextSelection.collapsed(offset: nextCursor),
            );

            setState(() {
              showMentionSuggestions = false;
              mentionQuery = "";
              mentionStartIndex = -1;
              showEmoji = false;
            });

            focusNode.requestFocus();
          }

          final mediaQuery = MediaQuery.of(context);
          final screenSize = mediaQuery.size;
          final keyboardVisible = mediaQuery.viewInsets.bottom > 0;

          final sheetHeight = screenSize.height *
              (keyboardVisible
                  ? 0.96
                  : showEmoji
                  ? 0.86
                  : 0.72);
          final normalizedMentionQuery = mentionQuery.trim().toLowerCase();

          final filteredMentionMembers = mentionMembers.where((member) {
            if (normalizedMentionQuery.isEmpty) {
              return true;
            }

            return member.name.toLowerCase().contains(
              normalizedMentionQuery,
            );
          }).take(8).toList();

          return PopScope<void>(
            canPop: !isSearching,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop || !isSearching) {
                return;
              }

              closeSearch();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
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
                            stream: ChatService.messagesStream(
                              homeId,
                              limit: messageLimit + 1,
                            ),
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

                              final allMessages = map.entries.toList()
                                ..sort((a, b) {
                                  final av = Map<String, dynamic>.from(a.value);
                                  final bv = Map<String, dynamic>.from(b.value);
                                  return (av["time"] ?? 0).compareTo(
                                    bv["time"] ?? 0,
                                  );
                                });

                              if (
                              initialUnreadSnapshotReady &&
                                  allMessages.isNotEmpty
                              ) {
                                final latestMessage =
                                Map<String, dynamic>.from(
                                  allMessages.last.value,
                                );
                                final latestMessageTime = int.tryParse(
                                  latestMessage["time"]?.toString() ?? "0",
                                ) ?? 0;

                                if (
                                latestMessageTime > 0 &&
                                    latestMessageTime > lastMarkedReadMessageTime
                                ) {
                                  lastMarkedReadMessageTime = latestMessageTime;

                                  unawaited(
                                    ChatService.markAsRead(
                                      homeId: homeId,
                                      uid: user.uid,
                                    ).catchError((_) {}),
                                  );
                                }
                              }

                              final nextHasMoreMessages =
                                  allMessages.length > messageLimit;

                              final messages = nextHasMoreMessages
                                  ? allMessages.sublist(
                                allMessages.length - messageLimit,
                              )
                                  : allMessages;

                              // Chỉ kết thúc trạng thái tải khi query mới đã
                              // thực sự active, tránh tăng limit liên tục khi
                              // StreamBuilder vẫn đang giữ snapshot cũ.
                              if (snapshot.connectionState ==
                                  ConnectionState.active) {
                                hasMoreMessages = nextHasMoreMessages;
                                loadingOlderMessages = false;
                              }

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
                                      itemCount: messages.length +
                                          (hasMoreMessages ? 1 : 0),
                                      itemBuilder: (_, index) {
                                        if (index >= messages.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                              bottom: 12,
                                            ),
                                            child: Center(
                                              child: TextButton.icon(
                                                onPressed: loadingOlderMessages
                                                    ? null
                                                    : () {
                                                  loadingOlderMessages =
                                                  true;
                                                  messageLimit += 15;
                                                  setState(() {});
                                                },
                                                icon: loadingOlderMessages
                                                    ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                  CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                                    : const Icon(
                                                  Icons.history_rounded,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  loadingOlderMessages
                                                      ? "Đang tải..."
                                                      : "Tải tin cũ hơn",
                                                ),
                                              ),
                                            ),
                                          );
                                        }

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
                                        final replyRaw = msg["reply"];

                                        final reply = replyRaw is Map
                                            ? Map<String, dynamic>.from(replyRaw)
                                            : <String, dynamic>{};

                                        final replyMessageId =
                                            reply["messageId"]?.toString().trim() ?? "";

                                        final replyName =
                                            reply["name"]?.toString().trim() ?? "";

                                        final replyText =
                                            reply["text"]?.toString().trim() ?? "";

                                        final mentionsRaw = msg["mentions"];
                                        final mentions = mentionsRaw is Map
                                            ? Map<String, String>.from(
                                          mentionsRaw.map(
                                                (key, value) => MapEntry(
                                              key.toString(),
                                              value.toString(),
                                            ),
                                          ),
                                        )
                                            : <String, String>{};

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
                                                    child: GestureDetector(
                                                      behavior: HitTestBehavior.opaque,
                                                      onTap: isMe
                                                          ? null
                                                          : () {
                                                        beginReply(
                                                          messageId: messageId,
                                                          message: msg,
                                                        );
                                                      },
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
                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                              children: [
                                                                if (replyMessageId.isNotEmpty) ...[
                                                                  GestureDetector(
                                                                    onTap: () => scrollToMessage(replyMessageId),
                                                                    child: Container(
                                                                      width: double.infinity,
                                                                      margin: const EdgeInsets.only(bottom: 7),
                                                                      padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white.withValues(alpha: 0.65),
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        border: const Border(
                                                                          left: BorderSide(
                                                                            color: SafeHomeColors.primary,
                                                                            width: 3,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            replyName.isNotEmpty
                                                                                ? replyName
                                                                                : "Một thành viên",
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: const TextStyle(
                                                                              color: SafeHomeColors.primary,
                                                                              fontSize: 11,
                                                                              fontWeight: FontWeight.w800,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 2),
                                                                          Text(
                                                                            replyText,
                                                                            maxLines: 2,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: const TextStyle(
                                                                              color: SafeHomeColors.textSecondary,
                                                                              fontSize: 11,
                                                                              height: 1.25,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],

                                                                Text.rich(
                                                                  highlightedSpan(
                                                                    text,
                                                                    const TextStyle(
                                                                      fontSize: 14,
                                                                    ),
                                                                    mentions:
                                                                    mentions,
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

                        if (showMentionSuggestions)
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                              maxHeight: 220,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: SafeHomeColors.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: filteredMentionMembers.isEmpty
                                ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                "Không tìm thấy thành viên phù hợp",
                                style: TextStyle(
                                  color:
                                  SafeHomeColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                                : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              itemCount:
                              filteredMentionMembers.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (_, index) {
                                final member =
                                filteredMentionMembers[index];

                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                    SafeHomeColors.primary
                                        .withValues(alpha: 0.10),
                                    backgroundImage:
                                    member.photoUrl.isNotEmpty
                                        ? NetworkImage(
                                      member.photoUrl,
                                    )
                                        : null,
                                    child: member.photoUrl.isEmpty
                                        ? const Icon(
                                      Icons.person_rounded,
                                      size: 19,
                                      color:
                                      SafeHomeColors.primary,
                                    )
                                        : null,
                                  ),
                                  title: Text(
                                    member.name,
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Nhắc đến trong tin nhắn",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  onTap: () =>
                                      selectMention(member),
                                );
                              },
                            ),
                          ),

                        if (replyingToMessage != null)
                          GestureDetector(
                            onTap: () {
                              if (replyingToMessageId.isNotEmpty) {
                                scrollToMessage(replyingToMessageId);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                              decoration: BoxDecoration(
                                color: SafeHomeColors.primary.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: SafeHomeColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Đang trả lời ${replyingToMessage?["name"]?.toString().trim().isNotEmpty == true ? replyingToMessage!["name"].toString().trim() : "một thành viên"}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: SafeHomeColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          replyingToMessage?["text"]?.toString() ?? "",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: SafeHomeColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: "Huỷ trả lời",
                                    visualDensity: VisualDensity.compact,
                                    onPressed: cancelReply,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 19,
                                      color: SafeHomeColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
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

class _HomeChatMentionMember {
  const _HomeChatMentionMember({
    required this.uid,
    required this.name,
    required this.photoUrl,
  });

  final String uid;
  final String name;
  final String photoUrl;
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
