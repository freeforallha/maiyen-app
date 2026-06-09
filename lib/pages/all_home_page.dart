import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../helpers/top_toast.dart';
class AllHomePage extends StatefulWidget {
  final List<String> homeOrder;

  const AllHomePage({super.key, required this.homeOrder});

  @override
  State<AllHomePage> createState() => _AllHomePageState();
}

class _AllHomePageState extends State<AllHomePage> {
  bool isAllSafe() {
    if (homes.isEmpty) return true;

    for (final home in homes.values) {
      final devices = safeMap(home["devices"]);

      final unsafe = devices.values.any(
            (d) => d["status"] != "closed" || d["tamper"] == true,
      );

      if (unsafe) return false;
    }

    return true;
  }
  Map<String, dynamic> homes = {};

  Set<String> selectedHomes = {};

  Map<String, String> customNames = {};
  String search = "";
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};

    return Map<String, dynamic>.from(data as Map);
  }

  bool isUnsafe(Map dev) {
    return dev.values.any((d) {
      final status = d["status"]?.toString();

      final tamper = d["tamper"] == true;

      return status != "closed" || tamper;
    });
  }

  late DatabaseReference ref;
  final List<StreamSubscription> listeners = [];
  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final sub = FirebaseDatabase.instance
        .ref("accounts/$uid")
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = Map<String, dynamic>.from(data as Map);
      customNames = Map<String, String>.from(map["groupNames"] ?? {});

      final ownHomes = Map<String, dynamic>.from(map["homes"] ?? {});
      final sharedHomes = Map<String, dynamic>.from(map["sharedHomes"] ?? {});

      final Map<String, dynamic> merged = {};
      final Set<String> addedHomeIds = {};

      // chỉ add home thật sự sở hữu
      ownHomes.forEach((key, value) {
        merged[key] = value;
        addedHomeIds.add(key);
      });

      setState(() {
        homes = merged;
      });

      // 🔥 shared homes listener FIX (KHÔNG tạo lại liên tục)
      sharedHomes.forEach((homeId, value) {
        if (addedHomeIds.contains(homeId)) return;
        addedHomeIds.add(homeId);
        final v = Map<String, dynamic>.from(value);
        final ownerUid = v["ownerUid"];

        if (ownerUid == null) return;

        FirebaseDatabase.instance.ref("accounts/$ownerUid/email").get().then((
          emailSnap,
        ) {
          final ownerEmail = emailSnap.value?.toString() ?? "Unknown";

          final sharedSub = FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId")
              .onValue
              .listen((e) {
            final d = e.snapshot.value;

            if (d == null) return;

            setState(() {
              homes[homeId] = {
                ...Map<String, dynamic>.from(d as Map),
                "_shared": true,
                "_ownerUid": ownerUid,
                "_ownerEmail": ownerEmail,
                "_role": v["role"] ?? "member",
              };
            });
          });

          listeners.add(sharedSub);
        });
      });
    });
    listeners.add(sub);
  }

  Map<String, List<String>> groupedHomes() {
    final Map<String, List<String>> grouped = {};
    final seen = <String>{};
    for (final homeId in widget.homeOrder) {
      if (seen.contains(homeId)) continue;
      seen.add(homeId);
      if (!homes.containsKey(homeId)) continue;
      final data = safeMap(homes[homeId]);
      final name = (data["name"] ?? homeId).toString().toLowerCase();

      if (search.isNotEmpty && !name.contains(search)) {
        continue;
      }

      final isShared = data["_shared"] == true;

      final groupKey = isShared
          ? (data["_ownerUid"] ?? "unknown_uid")
          : "your_homes";

      grouped.putIfAbsent(groupKey, () => []);
      grouped[groupKey]!.add(homeId);
    }

    return grouped;
  }

  Future<void> renameGroup(String key) async {
    final controller = TextEditingController(text: customNames[key] ?? "");

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Đổi tên nhóm"),

        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "VD: Mr Chung"),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() {
      for (final id in selectedHomes) {
        homes.remove(id);
      }

      selectedHomes.clear();
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseDatabase.instance
        .ref("accounts/$uid/groupNames/$key")
        .set(result);
  }

  Widget buildSectionTitle(String groupKey, List<String> ids) {
    final isYourHomes = groupKey == "your_homes";

    String ownerText = "";
    if (!isYourHomes) {
      final firstHome = safeMap(homes[ids.first]);

      ownerText = firstHome["_ownerEmail"] ?? "Unknown";
    }

    final displayName =
        customNames[groupKey] ?? (isYourHomes ? "Nhà của tôi" : ownerText);
    return Container(
      margin: EdgeInsets.only(top: 6, bottom: 8),

      padding: EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,

                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  Icons.other_houses_rounded,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      displayName,

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (!isYourHomes)
                      Text(
                        ownerText,

                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {
                  renameGroup(groupKey);
                },

                icon: Icon(Icons.edit_rounded, color: Colors.blueAccent),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    final allSelected = ids.every(
                      (id) => selectedHomes.contains(id),
                    );

                    if (allSelected) {
                      selectedHomes.removeAll(ids);
                    } else {
                      selectedHomes.addAll(ids);
                    }
                  });
                },

                icon: Icon(Icons.done_all_rounded, color: Colors.green),
              ),
            ],
          ),

          SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,

            physics: NeverScrollableScrollPhysics(),

            itemCount: ids.length,

            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 1,
            ),

            itemBuilder: (context, index) {
              final homeId = ids[index];

              final data = safeMap(homes[homeId]);

              return buildHomeCard(context, homeId, data);
            },
          ),
        ],
      ),
    );
  }

  Widget buildHomeCard(
    BuildContext context,
    String homeId,
    Map<String, dynamic> data,
  ) {
    final devices = safeMap(data["devices"]);

    final unsafe = isUnsafe(devices);

    final selected = selectedHomes.contains(homeId);

    return InkWell(
      onTap: () {
        if (selectedHomes.isNotEmpty) {
          setState(() {
            if (selected) {
              selectedHomes.remove(homeId);
            } else {
              selectedHomes.add(homeId);
            }
          });

          return;
        }

        Navigator.pop(context, homeId);
      },

      onLongPress: () {
        setState(() {
          selectedHomes.add(homeId);
        });
      },

      borderRadius: BorderRadius.circular(14),

      child: Container(
        decoration: BoxDecoration(
          color: unsafe ? Colors.red.shade300 : Colors.green.shade300,

          borderRadius: BorderRadius.circular(14),

          border: selected
              ? Border.all(color: Colors.blueAccent, width: 4)
              : null,
        ),

        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(6),

              child: SizedBox.expand(
                child: Center(
                  child: Text(
                    (data["name"] ?? homeId).toString(),

                    textAlign: TextAlign.center,

                    softWrap: true,

                    maxLines: 4,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> setSelectedHomesAlarm() async {
    Future<String?> inputTime(String title, String initial) async {
      final parts = initial.split(":");
      final h = TextEditingController(text: parts[0]);
      final m = TextEditingController(text: parts[1]);

      return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              Expanded(child: TextField(controller: h, maxLength: 2, decoration: const InputDecoration(labelText: "Giờ"))),
              const Text(" : "),
              Expanded(child: TextField(controller: m, maxLength: 2, decoration: const InputDecoration(labelText: "Phút"))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Huỷ")),
            ElevatedButton(
              onPressed: () {
                final value = "${h.text.trim().padLeft(2, '0')}:${m.text.trim().padLeft(2, '0')}";
                Navigator.pop(context, value);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    final start = await inputTime("Giờ bắt đầu Alarm", "23:00");
    if (start == null) return;

    final end = await inputTime("Giờ kết thúc Alarm", "06:00");
    if (end == null) return;

    final alarmData = {
      "enabled": true,
      "start": start,
      "end": end,
      "repeatMinutes": 30,
    };

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final updates = <String, dynamic>{};

    int updatedDevices = 0;
    int skippedHomes = 0;

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);
      final isShared = home["_shared"] == true;
      final role = home["_role"]?.toString() ?? "member";

      final canManage = !isShared || role == "owner" || role == "admin";

      if (!canManage) {
        skippedHomes++;
        continue;
      }

      final ownerUid = isShared ? home["_ownerUid"] : uid;
      final devices = safeMap(home["devices"]);

      for (final entry in devices.entries) {
        final deviceId = entry.key;
        final device = safeMap(entry.value);
        final type = device["type"]?.toString();

        final isSecurity =
            type == "door" || type == "door_lock" || type == "motion";

        if (!isSecurity) continue;

        updates["accounts/$ownerUid/homes/$homeId/devices/$deviceId/alarm"] =
            alarmData;

        updatedDevices++;
      }
    }

    if (updates.isEmpty) {
      showTopToast(
        context,
        "Không có thiết bị an ninh nào để cài alarm",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    await FirebaseDatabase.instance.ref().update(updates);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cài Alarm hoàn tất"),
        content: Text(
          "Đã cài alarm cho $updatedDevices thiết bị."
              "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

    Future<void> confirmDeleteSelected() async {
    final controller = TextEditingController();

    final sharedCount = selectedHomes.where((id) {
      final home = safeMap(homes[id]);

      return home["_shared"] == true;
    }).length;

    final ownCount = selectedHomes.length - sharedCount;

    String message = "";

    if (sharedCount > 0 && ownCount > 0) {
      message =
          "Các home của bạn sẽ bị xoá.\n"
          "Các home được chia sẻ sẽ được rời khỏi.";
    } else if (sharedCount > 0) {
      message = "Bạn sẽ rời khỏi các home được chia sẻ.";
    } else {
      message = "Các home đã chọn sẽ bị xoá vĩnh viễn.";
    }

    final ok = await showDialog<bool>(
      context: context,

      builder: (_) => AlertDialog(
        title: Text("Xác nhận"),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text(message),

            SizedBox(height: 14),

            TextField(
              controller: controller,
              obscureText: true,

              decoration: InputDecoration(
                hintText: "Mật khẩu",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),

            child: Text("Huỷ"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser!;

                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: controller.text.trim(),
                );

                await user.reauthenticateWithCredential(credential);

                Navigator.pop(context, true);
              } catch (e) {
                showTopToast(
                  context,
                  "Sai mật khẩu",
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                );
              }
            },

            child: Text(
              sharedCount > 0 && ownCount == 0 ? "Rời khỏi" : "Tiếp tục",
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);

      final isShared = home["_shared"] == true;
      // ===== HOME ĐƯỢC SHARE =====
      if (isShared) {
        final ownerUid = home["_ownerUid"];

        await FirebaseDatabase.instance
            .ref("accounts/$uid/sharedHomes/$homeId")
            .remove();

        await FirebaseDatabase.instance
            .ref("sharedByHome/$homeId/$uid")
            .remove();

        // 🔥 remove khỏi share list của owner
        await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareList/$homeId/$uid")
            .remove();
      }
      // ===== HOME CỦA MÌNH =====
      else {
        final accountsSnap = await FirebaseDatabase.instance
            .ref("accounts")
            .get();

        if (accountsSnap.exists) {
          final accounts = Map<String, dynamic>.from(accountsSnap.value as Map);

          for (final entry in accounts.entries) {
            final otherUid = entry.key;

            await FirebaseDatabase.instance
                .ref("accounts/$otherUid/sharedHomes/$homeId")
                .remove();
          }
        }

        await FirebaseDatabase.instance
            .ref("accounts/$uid/homes/$homeId")
            .remove();
      }
    }

    setState(() {
      selectedHomes.clear();
    });

    showTopToast(
      context,
      sharedCount > 0 && ownCount == 0 ? "Đã rời khỏi home" : "Đã cập nhật",
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedHomes();

    return Scaffold(
      backgroundColor: const Color(0xFFDDF7E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Tìm home...",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              search = value.toLowerCase().trim();
            });
          },
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "🏡",
              style: const TextStyle(fontSize: 26),
            ),

            const SizedBox(width: 8),

            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                children: [
                  TextSpan(
                    text: "Safe",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: "Home",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  search = "";
                  searchController.clear();
                }
              });
            },
          ),

          if (selectedHomes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => selectedHomes.clear());
              },
            ),
        ],
      ),

      bottomNavigationBar: selectedHomes.isEmpty
          ? null
          : SafeArea(
              child: Container(
                margin: EdgeInsets.all(12),

                padding: EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(22),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Icon(
                          Icons.schedule_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),

                      title: Text(
                        "Đặt báo thức nhà đã chọn",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("${selectedHomes.length} nhà đã chọn"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: setSelectedHomesAlarm,
                    ),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Icon(Icons.share_rounded, color: Colors.green),
                      ),

                      title: Text(
                        "Chia sẻ nhà đã chọn",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("${selectedHomes.length} nhà đã chọn"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: () async {
                        final controller = TextEditingController();
                        final ownerUid = FirebaseAuth.instance.currentUser!.uid;

                        final qrData =
                            "safehome_join_multi|$ownerUid|${selectedHomes.join(",")}";
                        final targetEmail = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) {
                            return SafeArea(
                              child: Container(
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                                ),
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
                                    const Text(
                                      "Chia sẻ nhà đã chọn",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Text(
                                      "Hoặc quét QR để xin gia nhập các nhà đã chọn",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    QrImageView(
                                      data: qrData,
                                      version: QrVersions.auto,
                                      size: 190,
                                    ),

                                    const SizedBox(height: 18),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${selectedHomes.length} nhà đã chọn",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.email_rounded),
                                        labelText: "Email người nhận",
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.share_rounded),
                                        label: const Text("Chia sẻ"),
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                            controller.text.trim().toLowerCase(),
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

                        if (targetEmail == null || targetEmail.isEmpty) return;

                        final accountsSnap = await FirebaseDatabase.instance
                            .ref("accounts")
                            .get();

                        String? targetUid;

                        if (accountsSnap.exists) {
                          final accounts = Map<String, dynamic>.from(
                            accountsSnap.value as Map,
                          );

                          for (final entry in accounts.entries) {
                            final data = Map<String, dynamic>.from(entry.value);

                            final mail = data["email"]
                                ?.toString()
                                .trim()
                                .toLowerCase();

                            if (mail == targetEmail) {
                              targetUid = entry.key;
                              break;
                            }
                          }
                        }

                        if (targetUid == null) {
                          showTopToast(
                            context,
                            "Email chưa đăng ký",
                            color: Colors.red,
                            icon: Icons.error_outline_rounded,
                          );
                          return;
                        }

                        final myUid = FirebaseAuth.instance.currentUser!.uid;

                        int skipped = 0;

                        for (final homeId in selectedHomes) {
                          final home = safeMap(homes[homeId]);

                          // chỉ share home own
                          final role = home["_role"]?.toString() ?? "member";

                          final canShare =
                              home["_shared"] != true ||
                                  role == "owner" ||
                                  role == "admin";

                          if (!canShare) {
                            skipped++;
                            continue;
                          }

                          await FirebaseDatabase.instance
                              .ref("accounts/$targetUid/shareRequests/$homeId")
                              .set({
                                "ownerUid": myUid,
                                "homeId": homeId,
                                "ownerEmail":
                                    FirebaseAuth.instance.currentUser?.email ??
                                    "",
                                "time": DateTime.now().millisecondsSinceEpoch,
                              });

                          // lưu share list
                          await FirebaseDatabase.instance
                              .ref(
                                "accounts/$myUid/shareList/$homeId/$targetUid",
                              )
                              .set({
                                "email": targetEmail,
                                "sharedAt":
                                    DateTime.now().millisecondsSinceEpoch,
                              });
                        }

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Chia sẻ hoàn tất"),
                            content: Text(
                              skipped > 0
                                  ? "Đã chia sẻ các nhà bạn có quyền.\n\n$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ."
                                  : "Đã chia sẻ nhà thành công.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    Divider(height: 8),

                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Icon(
                          Icons.people_alt_rounded,
                          color: Colors.orange,
                        ),
                      ),

                      title: Text(
                        "Mở List chia sẻ nhà",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("${selectedHomes.length} nhà đã chọn"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: () async {
                        final uid = FirebaseAuth.instance.currentUser!.uid;

                        final ownHomes = selectedHomes.where((id) {
                          final home = safeMap(homes[id]);
                          final role = home["role"]?.toString();

                          return home["_shared"] != true || role == "owner" || role == "admin";
                        }).toList();

                        if (ownHomes.isEmpty) {
                          showTopToast(
                            context,
                            "Không có nhà nào bạn có quyền quản lý",
                            color: Colors.orange,
                            icon: Icons.lock_rounded,
                          );

                          return;
                        }

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,

                          builder: (_) {
                            return StatefulBuilder(
                              builder: (context, setSheetState) {
                                return Container(
                                  padding: EdgeInsets.all(16),

                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                        0.8,
                                  ),

                                  child: FutureBuilder(
                                    future: FirebaseDatabase.instance
                                        .ref("accounts/$uid/shareList")
                                        .get(),

                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final raw = snap.data!.value == null
                                          ? {}
                                          : Map<String, dynamic>.from(
                                              snap.data!.value as Map,
                                            );

                                      return ListView(
                                        children: ownHomes.map((homeId) {
                                          final home = safeMap(homes[homeId]);

                                          final homeName =
                                              home["name"]?.toString() ??
                                              homeId;

                                          final users = safeMap(raw[homeId]);

                                          return Container(
                                            margin: EdgeInsets.only(bottom: 16),

                                            padding: EdgeInsets.all(14),

                                            decoration: BoxDecoration(
                                              color: Colors.white,

                                              borderRadius:
                                                  BorderRadius.circular(18),

                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),

                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,

                                              children: [
                                                Text(
                                                  homeName,

                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),

                                                SizedBox(height: 10),

                                                if (users.isEmpty)
                                                  Text(
                                                    "Chưa share cho ai",
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),

                                                ...users.entries.map((e) {
                                                  final targetUid = e.key;

                                                  final data =
                                                      Map<String, dynamic>.from(
                                                        e.value,
                                                      );

                                                  final email =
                                                      data["email"] ??
                                                      "Unknown";

                                                  return Container(
                                                    margin: EdgeInsets.only(
                                                      bottom: 8,
                                                    ),

                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,

                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),

                                                    child: ListTile(
                                                      dense: true,

                                                      leading: CircleAvatar(
                                                        radius: 16,

                                                        child: Icon(
                                                          Icons.person,
                                                          size: 18,
                                                        ),
                                                      ),

                                                      title: Text(email),

                                                      trailing: IconButton(
                                                        icon: Icon(
                                                          Icons.delete_rounded,
                                                          color: Colors.red,
                                                        ),

                                                        onPressed: () async {
                                                          await FirebaseDatabase
                                                              .instance
                                                              .ref(
                                                                "accounts/$targetUid/sharedHomes/$homeId",
                                                              )
                                                              .remove();

                                                          await FirebaseDatabase
                                                              .instance
                                                              .ref(
                                                                "accounts/$uid/shareList/$homeId/$targetUid",
                                                              )
                                                              .remove();

                                                          setSheetState(() {
                                                            users.remove(
                                                              targetUid,
                                                            );
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
                      },
                    ),

                    Divider(height: 8),

                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Icon(Icons.delete_rounded, color: Colors.red),
                      ),

                      title: Text(
                        "Xoá các nhà đã chọn ?",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),

                      subtitle: Text("${selectedHomes.length} nhà đã chọn"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: confirmDeleteSelected,
                    ),
                  ],
                ),
              ),
            ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDDF7E8),
              Color(0xFFF1FCF5),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: grouped.entries.map((entry) {
            final groupKey = entry.key;
            final ids = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle(groupKey, ids),
                const SizedBox(height: 6),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  @override
  void dispose() {
    for (final l in listeners) {
      l.cancel();
    }

    searchController.dispose();

    super.dispose();
  }
}
