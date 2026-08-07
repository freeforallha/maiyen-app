part of '../all_home_page.dart';

extension _AllHomeSharingPart on _AllHomeState {
  Future<void> _shareSelectedHomes() async {
    String targetEmailText = "";
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final ownerUid = currentUser.uid;

    final qrData = MaiYenIdentifiers.buildJoinMultipleHomesQr(
      ownerUid: ownerUid,
      homeIds: selectedHomes,
    );

    final targetEmail = await MaiYenNavigation.showModalSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final keyboardOpen = bottomInset > 0;
            final qrSize = keyboardOpen ? 140.0 : 190.0;
            final emailOk = RegExp(
              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
            ).hasMatch(targetEmailText);

            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _strings.t("Chia sẻ nhà đã chọn"),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _strings.t(
                            "Hoặc quét QR để xin gia nhập các nhà đã chọn",
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: qrSize,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          selectedHomeCountText(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_rounded),
                            labelText: _strings.t("Email người nhận"),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              targetEmailText = value.trim().toLowerCase();
                            });
                          },
                          onFieldSubmitted: (_) {
                            if (!emailOk) {
                              return;
                            }

                            FocusManager.instance.primaryFocus?.unfocus();

                            Navigator.pop(sheetContext, targetEmailText);
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MaiYenColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                            ),
                            icon: const Icon(Icons.share_rounded),
                            label: Text(_strings.t("Chia sẻ")),
                            onPressed: emailOk
                                ? () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();

                                    Navigator.pop(
                                      sheetContext,
                                      targetEmailText,
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (targetEmail == null || targetEmail.isEmpty) {
      return;
    }

    final directorySnap = await FirebaseDatabase.instance
        .ref("userDirectory")
        .orderByChild("email")
        .equalTo(targetEmail)
        .limitToFirst(1)
        .get();

    String? targetUid;

    if (directorySnap.value is Map) {
      final directory = Map<String, dynamic>.from(directorySnap.value as Map);

      if (directory.isNotEmpty) {
        targetUid = directory.keys.first.toString();
      }
    }
    if (!context.mounted) return;

    if (targetUid == null) {
      showTopToast(
        context,
        _strings.t("Email chưa đăng ký"),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final myUid = currentUser.uid;
    int skipped = 0;

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);
      final role = home["_role"]?.toString() ?? "member";

      final canShare =
          home["_shared"] != true || role == "owner" || role == "admin";

      if (!canShare) {
        skipped++;
        continue;
      }

      await FirebaseDatabase.instance
          .ref("accounts/$targetUid/shareRequests/$homeId")
          .set({
            "ownerUid": myUid,
            "homeId": homeId,
            "ownerEmail": FirebaseAuth.instance.currentUser?.email ?? "",
            "time": DateTime.now().millisecondsSinceEpoch,
          });

      await FirebaseDatabase.instance
          .ref("accounts/$myUid/shareList/$homeId/$targetUid")
          .set({
            "email": targetEmail,
            "sharedAt": DateTime.now().millisecondsSinceEpoch,
          });
    }
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_strings.t("Chia sẻ hoàn tất")),
        content: Text(_strings.allHomeShareResultText(skipped)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_strings.t("OK")),
          ),
        ],
      ),
    );
  }

  Future<void> _manageSelectedHomeShares() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;

    final ownHomes = selectedHomes.where((id) {
      final home = safeMap(homes[id]);
      final role = home["role"]?.toString();

      return home["_shared"] != true || role == "owner" || role == "admin";
    }).toList();

    if (ownHomes.isEmpty) {
      showTopToast(
        context,
        _strings.t("Không có nhà nào bạn có quyền quản lý"),
        color: Colors.orange,
        icon: Icons.lock_rounded,
      );
      return;
    }

    MaiYenNavigation.showModalSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: FutureBuilder(
                future: FirebaseDatabase.instance
                    .ref("accounts/$uid/shareList")
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final value = snap.data?.value;
                  final raw = value is Map
                      ? Map<String, dynamic>.from(value)
                      : <String, dynamic>{};

                  return ListView(
                    children: ownHomes.map((homeId) {
                      final home = safeMap(homes[homeId]);
                      final homeName = home["name"]?.toString() ?? homeId;
                      final users = safeMap(raw[homeId]);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              homeName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (users.isEmpty)
                              Text(
                                _strings.t("Chưa share cho ai"),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ...users.entries.map((e) {
                              final targetUid = e.key;
                              final data = Map<String, dynamic>.from(e.value);

                              final email = data["email"] ?? "Unknown";

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: const CircleAvatar(
                                    radius: 16,
                                    child: Icon(Icons.person, size: 18),
                                  ),
                                  title: Text(email),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await FirebaseDatabase.instance
                                          .ref(
                                            "accounts/$targetUid/sharedHomes/$homeId",
                                          )
                                          .remove();

                                      await FirebaseDatabase.instance
                                          .ref(
                                            "accounts/$uid/shareList/$homeId/$targetUid",
                                          )
                                          .remove();

                                      setSheetState(() {
                                        users.remove(targetUid);
                                      });
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
