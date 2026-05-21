import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'pages/share_list_sheet.dart';

class AllHomePage extends StatefulWidget {
  final List<String> homeOrder;

  const AllHomePage({super.key, required this.homeOrder});

  @override
  State<AllHomePage> createState() => _AllHomePageState();
}

class _AllHomePageState extends State<AllHomePage> {
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

  @override
  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseDatabase.instance.ref("accounts/$uid").onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = Map<String, dynamic>.from(data as Map);
      customNames = Map<String, String>.from(map["groupNames"] ?? {});

      final ownHomes = Map<String, dynamic>.from(map["homes"] ?? {});
      final sharedHomes = Map<String, dynamic>.from(map["sharedHomes"] ?? {});

      final Map<String, dynamic> merged = {};

      // chỉ add home thật sự sở hữu
      ownHomes.forEach((key, value) {
        if (!sharedHomes.containsKey(key)) {
          merged[key] = value;
        }
      });

      setState(() {
        homes = merged;
      });

      // 🔥 shared homes listener FIX (KHÔNG tạo lại liên tục)
      sharedHomes.forEach((homeId, value) {
        final v = Map<String, dynamic>.from(value);
        final ownerUid = v["ownerUid"];

        if (ownerUid == null) return;

        FirebaseDatabase.instance.ref("accounts/$ownerUid/email").get().then((
          emailSnap,
        ) {
          final ownerEmail = emailSnap.value?.toString() ?? "Unknown";

          FirebaseDatabase.instance
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
                  };
                });
              });
        });
      });
    });
  }

  Map<String, List<String>> groupedHomes() {
    final Map<String, List<String>> grouped = {};

    for (final homeId in widget.homeOrder) {
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
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  final c = TextEditingController(text: search);

                  return AlertDialog(
                    title: Text("Tìm Home"),
                    content: TextField(
                      controller: c,
                      decoration: InputDecoration(hintText: "Nhập tên home..."),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Huỷ"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            search = c.text.toLowerCase().trim();
                          });
                          Navigator.pop(context);
                        },
                        child: Text("OK"),
                      ),
                    ],
                  );
                },
              );
            },
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
        customNames[groupKey] ?? (isYourHomes ? "Your Homes" : ownerText);

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
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 23, minute: 0),
    );

    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 6, minute: 0),
    );

    if (end == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final updates = <String, dynamic>{};

    for (final homeId in selectedHomes) {
      final home = safeMap(homes[homeId]);

      final isShared = home["_shared"] == true;

      final alarmData = {
        "enabled": true,
        "start": "${start.hour}:${start.minute}",
        "end": "${end.hour}:${end.minute}",
      };

      // HOME SHARE
      if (isShared) {
        updates["accounts/$uid/sharedHomes/$homeId/alarm"] = alarmData;
      }
      // HOME OWN
      else {
        updates["accounts/$uid/homes/$homeId/alarm"] = alarmData;
      }
    }

    await FirebaseDatabase.instance.ref().update(updates);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Đã cập nhật Alarm")));
  }

  void openShareList(String homeId) {
    final home = safeMap(homes[homeId]);

    // home shared -> không có quyền
    if (home["_shared"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Home được share không có quyền quản lý Share List"),
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    showShareListSheet(context: context, ownerUid: uid, homeId: homeId);
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Sai mật khẩu"),
                    backgroundColor: Colors.red,
                  ),
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

      final isShared = home.containsKey("_ownerUid");
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sharedCount > 0 && ownCount == 0 ? "Đã rời khỏi home" : "Đã cập nhật",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedHomes();

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Tìm home...",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    search = value.toLowerCase().trim();
                  });
                },
              )
            : Text("Tất cả Home"),

        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  search = "";
                  searchController.clear();
                }
                isSearching = !isSearching;
              });
            },
          ),

          if (selectedHomes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close),
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
                        "Đặt báo thức các home",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("${selectedHomes.length} homes selected"),

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
                        "Chia sẻ các Home",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("${selectedHomes.length} homes selected"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: () async {
                        final controller = TextEditingController();

                        final targetEmail = await showDialog<String>(
                          context: context,

                          builder: (_) => AlertDialog(
                            title: Text("Chia sẻ Home"),

                            content: TextField(
                              controller: controller,

                              decoration: InputDecoration(
                                hintText: "Email người nhận",
                              ),
                            ),

                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),

                                child: Text("Huỷ"),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    controller.text.trim().toLowerCase(),
                                  );
                                },

                                child: Text("Chia sẻ"),
                              ),
                            ],
                          ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Email chưa đăng ký")),
                          );
                          return;
                        }

                        final myUid = FirebaseAuth.instance.currentUser!.uid;

                        for (final homeId in selectedHomes) {
                          final home = safeMap(homes[homeId]);

                          // chỉ share home own
                          if (home["_shared"] == true) continue;

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

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Đã chia sẻ homes")),
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
                        "Mở List chia sẻ Home",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("${selectedHomes.length} homes selected"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: () async {
                        final uid = FirebaseAuth.instance.currentUser!.uid;

                        final ownHomes = selectedHomes.where((id) {
                          final home = safeMap(homes[id]);

                          return home["_shared"] != true;
                        }).toList();

                        if (ownHomes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Không có home nào bạn sở hữu"),
                            ),
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
                        "Xoá các Home đã chọn ?",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),

                      subtitle: Text("${selectedHomes.length} homes selected"),

                      trailing: Icon(Icons.chevron_right_rounded),

                      onTap: confirmDeleteSelected,
                    ),
                  ],
                ),
              ),
            ),

      body: ListView(
        padding: EdgeInsets.all(10),

        children: grouped.entries.map((entry) {
          final groupKey = entry.key;

          final ids = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [buildSectionTitle(groupKey, ids), SizedBox(height: 6)],
          );
        }).toList(),
      ),
    );
  }
}
