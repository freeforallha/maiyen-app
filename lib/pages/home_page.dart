import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../helpers/home_helper.dart';
import '../services/fcm_service.dart';
import '../services/home_listener_service.dart';
import '../services/home_service.dart';
import '../services/notification_service.dart';
import '../helpers/safe_home_app.dart';

import '../widgets/home_tabs.dart';
import '../widgets/device_list.dart';
import '../widgets/status_panel.dart';
import '../widgets/account_avatar_sheet.dart';
import 'all_home_page.dart';
import 'confirm_dialog.dart';
import 'device_detail_sheet.dart';
import 'notification_list_sheet.dart';
import 'pair_dialog.dart';
import 'qr_scan_page.dart';
import 'settings_sheet.dart';
import 'share_list_sheet.dart';
import 'share_request_sheet.dart';
import 'edit_profile_page.dart';
import 'home_chat_sheet.dart';
import 'schedule_sheet.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> shareRequests = {};
  int unreadChatCount = 0;
  Map<String, int> unreadChatByHome = {};
  void openNotificationList(String deviceId) {
    final ownerUid = getHomeOwnerUid();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return NotificationListSheet(
          ownerUid: ownerUid,
          homeId: selectedHome,
          deviceId: deviceId,
        );
      },
    );
  }

  PreferredSizeWidget buildSafeHomeAppBar() {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = userPhotoUrl.isNotEmpty ? userPhotoUrl : user?.photoURL;
    final devices = getDevices();

    // ===== SMART SAFE LOGIC =====
    final isSafe = !devices.values.any(
          (d) => d["status"] != "closed" || d["tamper"] == true,
    );

    return AppBar(
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.grid_view_rounded,
          color: Colors.black,
          size: 26,
        ),
        onPressed: () async {
          final selected = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => AllHomePage(homeOrder: homeOrder),
            ),
          );

          if (selected != null) {
            setState(() {
              selectedHome = selected;
            });

            final index = homeOrder.indexOf(selected);
            if (index != -1) {
              homeTabController.animateTo(
                index * 110,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        },
      ),

      // ===== TITLE SAFEHOME =====
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              children: [
                TextSpan(
                  text: "Safe",
                  style: TextStyle(
                    color: isSafe ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: "Home",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),

      // ===== AVATAR =====
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => AccountAvatarSheet.show(
              context: context,
              logout: logout,

              onEditProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      userName: userName,
                      userGender: userGender,
                      userDob: userDob,
                      userPhone: userPhone,
                    )
                  ),
                );
              },

              userName: userName,
              userGender: userGender,
              userDob: userDob,
              userPhone: userPhone,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (photoUrl != null)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null)
                      ? const Icon(Icons.person,
                      size: 18, color: Colors.black54)
                      : null,
                ),

                const SizedBox(height: 2),

                SizedBox(
                  width: 50,
                  child: Text(
                    userName.isNotEmpty ? userName : "User",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.0,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  late String uid;
  late DatabaseReference ref;
  String userName = "";
  String userGender = "";
  String userDob = "";
  String userPhone = "";
  String userPhotoUrl = "";

  String getHomeOwnerUid() {
    final isShared = homes[selectedHome]?["_shared"] == true;

    if (isShared) {
      return homes[selectedHome]?["_ownerUid"] ?? uid;
    }

    return uid;
  }
  String getMyRole() {
    final currentHome = homes[selectedHome];

    if (currentHome == null) return "member";

    if (currentHome["_shared"] != true) {
      return "owner";
    }

    return currentHome["_role"]?.toString() ?? "member";
  }

  bool isOwner() => getMyRole() == "owner";

  bool isAdmin() => getMyRole() == "admin";

  bool canManageHome() {
    final role = getMyRole();
    return role == "owner" || role == "admin";
  }

  Map<String, dynamic> homes = {};
  String selectedHome = "";

  List<String> homeOrder = [];

  TimeOfDay start = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 6, minute: 0);

  bool alarmEnabled = false;

  int pairingCountdown = 0;
  Timer? timer;
  final ScrollController homeTabController = ScrollController();

  String formatTime(String t) {
    final parts = t.split(":");
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;

    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }
  String formatAlarmSchedules() {
    final currentHome = safeMap(homes[selectedHome]);

    final schedules = safeMap(currentHome["schedules"]);

    final alarmsRaw = schedules["alarms"];

    if (alarmsRaw == null) return "--:--";

    final alarms = List<Map<String, dynamic>>.from(
      (alarmsRaw as List).map(
            (e) => Map<String, dynamic>.from(e),
      ),
    );

    final enabled = alarms
        .where((e) => e["enabled"] == true)
        .toList();

    if (enabled.isEmpty) {
      return "Chưa bật";
    }

    if (enabled.length == 1) {
      return "${enabled.first["start"]} - ${enabled.first["end"]}";
    }

    return "${enabled.length} khung giờ";
  }
  Map<String, dynamic> getDevices() {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["devices"]);
  }

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser!.uid;
    FCMService.setupFCM(uid: uid);

    FCMService.listenForeground(
      localNotif: localNotif,
      navigatorKey: appNavigatorKey,
    );
    ref = FirebaseDatabase.instance.ref("accounts/$uid");

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = safeMap(data);
      final homesData = safeMap(map["homes"]);
      final sharedHomes = safeMap(map["sharedHomes"]);
      final requests = safeMap(map["shareRequests"]);
      print("RAW USER DATA: $map");
      print("USER INFO KEYS: ${map.keys}");
      print("NAME FIELD: ${map["name"]}");
      setState(() {
        shareRequests = requests;
        final profile = safeMap(map["profile"]);

        userName = profile["name"]?.toString() ?? map["name"]?.toString() ?? "";
        userGender = profile["gender"]?.toString() ?? map["gender"]?.toString() ?? "";
        userDob = profile["dob"]?.toString() ?? map["dob"]?.toString() ?? "";
        userPhone = profile["phone"]?.toString() ?? map["phone"]?.toString() ?? "";
        userPhotoUrl = profile["photoUrl"]?.toString() ?? "";
        homes.removeWhere((key, value) {
          final home = safeMap(value);
          final isShared = home["_shared"] == true;

          return !isShared && !homesData.containsKey(key);
        });

// Cập nhật home chính chủ.
        for (final entry in homesData.entries) {
          homes[entry.key] = entry.value;
        }
        HomeListenerService.loadSharedHomes(
          homes: homes,
          sharedHomes: sharedHomes,

          refresh: () {
            if (!mounted) return;
            setState(() {});
          },

          onDeleted: (homeId) {
            setState(() {
              homes.remove(homeId);

              homeOrder.remove(homeId);

              if (selectedHome == homeId) {
                selectedHome = homeOrder.isNotEmpty ? homeOrder.first : "";
              }
            });
          },
        );
        final savedOrder = map["homeOrder"];

        if (savedOrder != null) {
          homeOrder = List<String>.from(savedOrder);

          // tất cả home hiện có
          final allHomeIds = {...homesData.keys, ...sharedHomes.keys};

          // xóa home không còn tồn tại
          homeOrder.removeWhere((id) => !allHomeIds.contains(id));

          // thêm home own mới
          for (final id in homesData.keys) {
            if (!homeOrder.contains(id)) {
              homeOrder.add(id);
            }
          }

          // thêm home shared mới
          for (final id in sharedHomes.keys) {
            if (!homeOrder.contains(id)) {
              homeOrder.add(id);
            }
          }
        } else {
          homeOrder = [...homesData.keys, ...sharedHomes.keys];
        }

        // 🔥 FIX QUAN TRỌNG: chọn home đầu tiên theo ORDER
        if (homeOrder.isNotEmpty) {
          if (!homeOrder.contains(selectedHome)) {
            selectedHome = homeOrder.first; // 👈 HOME NGOÀI CÙNG BÊN PHẢI
          }
        } else {
          selectedHome = "";
        }
        final currentHome = safeMap(homes[selectedHome]);

        final alarm = safeMap(
          currentHome["_customAlarm"] ?? currentHome["alarm"],
        );
        alarmEnabled = alarm["enabled"] == true;

        final startStr = alarm["start"]?.toString() ?? "23:00";
        final endStr = alarm["end"]?.toString() ?? "06:00";

        final s = startStr.split(":");
        final e = endStr.split(":");

        start = TimeOfDay(
          hour: int.tryParse(s[0]) ?? 23,
          minute: int.tryParse(s[1]) ?? 0,
        );

        end = TimeOfDay(
          hour: int.tryParse(e[0]) ?? 6,
          minute: int.tryParse(e[1]) ?? 0,
        );
      });
    });
    FirebaseDatabase.instance
        .ref("homeChats")
        .onValue
        .listen((event) {
      final data = event.snapshot.value;

      if (data == null) return;

      final allChats = Map<String, dynamic>.from(data as Map);

      int total = 0;
      final perHome = <String, int>{};

      for (final homeId in homes.keys){
        final home = allChats[homeId];

        if (home == null) continue;

        final map = Map<String, dynamic>.from(home);

        final messagesRaw = map["messages"];
        final readRaw = map["lastRead"];

        if (messagesRaw == null) continue;

        final messages = Map<String, dynamic>.from(messagesRaw);

        int lastRead = 0;

        if (readRaw != null) {
          final reads = Map<String, dynamic>.from(readRaw);

          lastRead = reads[uid] ?? 0;
        }

        int homeUnread = 0;

        for (final msg in messages.values) {
          final m = Map<String, dynamic>.from(msg);

          final time = m["time"] ?? 0;
          final sender = m["uid"] ?? "";


          if (sender != uid && time > lastRead) {
            total++;
            homeUnread++;
          }
        }if (homeUnread > 0) {
          perHome[homeId] = homeUnread;
        }
      }

      if (mounted) {
        setState(() {
          unreadChatCount = total;
          unreadChatByHome = perHome;
        });
      }
    });
  }

  void pairSensor(String hubId) {
    // 🔥 FIX: khai báo ownerUid đúng cách
    final ownerUid = getHomeOwnerUid();

    final requestId =
        "${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 4)}";

    FirebaseDatabase.instance.ref("pair_requests/$requestId").set({
      "active": true,
      "hubId": hubId.trim(),
      "homeId": selectedHome,
      "ownerUid": ownerUid, // ✔ giờ không lỗi nữa
      "requestedBy": uid,
      "duration": 60,
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    setState(() => pairingCountdown = 60);

    timer?.cancel();

    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (pairingCountdown <= 0) {
        t.cancel();
      } else {
        setState(() => pairingCountdown--);
      }
    });
  }

  void deleteHome() async {
    final isShared = homes[selectedHome]?["_shared"] == true;

    // ================= HOME SHARE =================
    if (isShared) {
      final ok = await showConfirmDialog(context, "Rời khỏi Home này?");
      if (!ok) return;

      final leavingHomeId = selectedHome;
      final ownerUid = homes[leavingHomeId]?["_ownerUid"];

      // xoá sharedHomes
      await FirebaseDatabase.instance
          .ref("accounts/$uid/sharedHomes/$leavingHomeId")
          .remove();

      // xoá sharedByHome
      await FirebaseDatabase.instance
          .ref("sharedByHome/$leavingHomeId/$uid")
          .remove();
      if (ownerUid != null) {
        await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareList/$leavingHomeId/$uid")
            .remove();
      }

      setState(() {
        homes.remove(leavingHomeId);
        homeOrder.remove(leavingHomeId);

        if (homeOrder.isNotEmpty) {
          selectedHome = homeOrder.first;
        } else {
          selectedHome = "";
        }
      });
      return;
    }

    // ================= HOME OWN =================
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,

      builder: (_) => AlertDialog(
        title: Text("Xác nhận xoá"),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text("Nhập mật khẩu tài khoản để xác nhận."),

            SizedBox(height: 14),

            TextField(
              controller: controller,
              obscureText: true,

              decoration: InputDecoration(
                hintText: "Password",
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

            child: Text("DELETE"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final sharedSnap = await FirebaseDatabase.instance
        .ref("sharedByHome/$selectedHome")
        .get();

    if (sharedSnap.exists) {
      final sharedMap = Map<String, dynamic>.from(sharedSnap.value as Map);

      for (final sharedUid in sharedMap.keys) {
        await FirebaseDatabase.instance
            .ref("accounts/$sharedUid/sharedHomes/$selectedHome")
            .remove();
      }
    }

    // remove global shared index
    await FirebaseDatabase.instance.ref("sharedByHome/$selectedHome").remove();

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$selectedHome")
        .remove();

    homeOrder.remove(selectedHome);

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homeOrder")
        .set(homeOrder);
  }

  void shareHome() async {
    final controller = TextEditingController();

    final targetEmail = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Share Home"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Email người nhận"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().toLowerCase()),
            child: Text("Share"),
          ),
        ],
      ),
    );

    if (targetEmail == null || targetEmail.isEmpty) return;


    // không share cho chính mình
    final myEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();

    if (targetEmail == myEmail) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể share cho chính bạn")));
      return;
    }

    // tìm uid theo email
    final accountsSnap = await FirebaseDatabase.instance.ref("accounts").get();

    String? targetUid;

    if (accountsSnap.exists) {
      final accounts = Map<String, dynamic>.from(accountsSnap.value as Map);

      for (final entry in accounts.entries) {
        final data = Map<String, dynamic>.from(entry.value);

        final mail = data["email"]?.toString().trim().toLowerCase();
        print("CHECK ACCOUNT EMAIL: $mail | TARGET: $targetEmail | UID: ${entry.key}");

        if (mail == targetEmail) {
          targetUid = entry.key;
          break;
        }
      }
    }

    if (targetUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email chưa đăng ký"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final targetSnap = await FirebaseDatabase.instance
        .ref("accounts/$targetUid")
        .get();

    final targetData = targetSnap.value == null
        ? {}
        : Map<String, dynamic>.from(targetSnap.value as Map);

    final targetProfile = targetData["profile"] == null
        ? {}
        : Map<String, dynamic>.from(targetData["profile"] as Map);

    await FirebaseDatabase.instance
        .ref("sharedByHome/$selectedHome/$targetUid")
        .set({
      "role": "member",
      "email": targetData["email"] ?? targetEmail,
      "name": targetProfile["name"] ?? targetData["name"] ?? "",
      "photoUrl": targetProfile["photoUrl"] ?? targetData["photoUrl"] ?? "",
      "sharedAt": DateTime.now().millisecondsSinceEpoch,
    });
    // share
    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/shareRequests/$selectedHome")
        .set({
      "ownerUid": uid,
      "homeId": selectedHome,
      "ownerEmail": myEmail,
      "time": DateTime.now().millisecondsSinceEpoch,
    });

    // lưu share list
    await FirebaseDatabase.instance
        .ref("accounts/$uid/shareList/$selectedHome/$targetUid")
        .set({
      "email": targetEmail,
      "sharedAt": DateTime.now().millisecondsSinceEpoch,
    });
    // ================= GLOBAL SHARED INDEX =================

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Đã share home")));
  }
  void transferOwner() async {
    final controller = TextEditingController();

    final targetEmail = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Chuyển quyền chủ nhà"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Email người nhận quyền",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim().toLowerCase(),
            ),
            child: Text("Tiếp tục"),
          ),
        ],
      ),
    );


    if (targetEmail == null || targetEmail.isEmpty) return;


    // ===== 1. FIND UID =====
    final snap = await FirebaseDatabase.instance.ref("accounts").get();
    if (!snap.exists) return;

    String? targetUid;

    final accounts = Map<String, dynamic>.from(snap.value as Map);

    for (final entry in accounts.entries) {
      final data = Map<String, dynamic>.from(entry.value);
      final email = data["email"]?.toString().toLowerCase();

      if (email == targetEmail) {
        targetUid = entry.key;
        break;
      }
    }

    if (targetUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không tìm thấy user"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ===== 2. CONFIRM =====
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Xác nhận"),
        content: Text("Chuyển quyền Home này cho $targetEmail ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("OK"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // ===== 3. TRANSFER OWNER =====
    final homeId = selectedHome;

// ===== 1. GET CURRENT HOME DATA =====
    final currentSnap = await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$homeId")
        .get();

    if (!currentSnap.exists) return;

    final homeData = Map<String, dynamic>.from(currentSnap.value as Map);

// ===== 2. UPDATE OWNER UID =====
    homeData["_ownerUid"] = targetUid;
    // xóa trạng thái shared cũ nếu có
    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/sharedHomes/$homeId")
        .remove();

// ===== 3. WRITE TO NEW OWNER =====
    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/homes/$homeId")
        .set(homeData);
    final targetOrderSnap = await FirebaseDatabase.instance
        .ref("accounts/$targetUid/homeOrder")
        .get();

    List<dynamic> targetOrder = [];

    if (targetOrderSnap.exists) {
      targetOrder = List<dynamic>.from(targetOrderSnap.value as List);
    }

    if (!targetOrder.contains(homeId)) {
      targetOrder.add(homeId);
    }

    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/homeOrder")
        .set(targetOrder);

// ===== 4. OLD OWNER -> MEMBER =====

// thêm vào sharedHomes
    await FirebaseDatabase.instance
        .ref("accounts/$uid/sharedHomes/$homeId")
        .set({
      "ownerUid": targetUid,
    });

// thêm vào sharedByHome
    final mySnap = await FirebaseDatabase.instance
        .ref("accounts/$uid")
        .get();

    final myData = mySnap.value is Map
        ? Map<String, dynamic>.from(mySnap.value as Map)
        : <String, dynamic>{};

    final myProfile = myData["profile"] is Map
        ? Map<String, dynamic>.from(myData["profile"] as Map)
        : <String, dynamic>{};

    await FirebaseDatabase.instance
        .ref("sharedByHome/$homeId/$uid")
        .set({
      "email": myData["email"] ?? "",
      "name": myProfile["name"] ?? "",
      "photoUrl": myProfile["photoUrl"] ?? "",
      "sharedAt": DateTime.now().millisecondsSinceEpoch,
    });

// xóa home own cũ
    await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$homeId")
        .remove();

    // ===== 4. UPDATE LOCAL =====
    setState(() {
      homes.remove(homeId);
      homeOrder.remove(homeId);

      if (homeOrder.isNotEmpty) {
        selectedHome = homeOrder.first;
      } else {
        selectedHome = "";
      }
    });
    await FirebaseDatabase.instance
        .ref("accounts/$uid/homeOrder")
        .set(homeOrder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (homeOrder.isNotEmpty) {
        final index = homeOrder.indexOf(selectedHome);
        if (index != -1) {
          homeTabController.jumpTo(index * 110);
        }
      }
    });
  }
  void deleteDevice(String id) async {
    if (!await showConfirmDialog(context, "Xóa Device?")) return;

    final ownerUid = getHomeOwnerUid();

    await HomeService.deleteDevice(
      ownerUid: ownerUid,
      homeId: selectedHome,
      deviceId: id,
    );
  }

  void logout() async {
    if (!await showConfirmDialog(context, "Đăng xuất?")) return;
    await FirebaseAuth.instance.signOut();
  }

  void addHome() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thêm nhà mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Tên nhà",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Địa chỉ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                "name": nameController.text.trim(),
                "address": addressController.text.trim(),
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (result == null) return;

    final name = result["name"] ?? "";
    final address = result["address"] ?? "";

    if (name.trim().isEmpty) return;

    final id = "home_${DateTime.now().millisecondsSinceEpoch}";

    await FirebaseDatabase.instance.ref("accounts/$uid/homes/$id").set({
      "name": name,
      "address": address,
      "_ownerUid": uid,
      "_shared": false,
      "devices": {},
      "alarm": {
        "enabled": false,
        "start": "23:00",
        "end": "06:00",
      },
    });

    homeOrder.add(id);

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homeOrder")
        .set(homeOrder);
  }

  // ================= RESTORED FULL FUNCTIONS =================

  void renameHome() async {
    final isShared = homes[selectedHome]?["_shared"] == true;

    final currentName = isShared
        ? (homes[selectedHome]?["_customName"] ??
        homes[selectedHome]?["name"] ??
        selectedHome)
        : (homes[selectedHome]?["name"] ?? selectedHome);

    final controller = TextEditingController(text: currentName);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Home"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("OK"),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    // HOME SHARE -> lưu riêng cho user hiện tại
    if (isShared) {
      await FirebaseDatabase.instance
          .ref("accounts/$uid/sharedHomes/$selectedHome/customName")
          .set(name);

      setState(() {
        homes[selectedHome]?["_customName"] = name;
      });

      return;
    }

    // HOME OWN
    final ownerUid = getHomeOwnerUid();

    await HomeService.renameHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      name: name,
    );
  }

  void renameDevice(String id) async {
    if (homes[selectedHome]?["_shared"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Home được share chỉ có quyền xem")),
      );
      return;
    }
    final controller = TextEditingController(
      text: getDevices()[id]?["name"] ?? id,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Device"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("OK"),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final ownerUid = getHomeOwnerUid();

    await HomeService.renameDevice(
      ownerUid: ownerUid,
      homeId: selectedHome,
      deviceId: id,
      name: name,
    );
  }
  void setNotificationSchedule() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 0),
    );

    if (t == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Đã chọn giờ Notification: ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
        ),
      ),
    );

    // Tạm thời chỉ set UI trước.
    // Bước sau mình sẽ nối lưu Firebase + backend gửi notification 23h.
  }
  void setAlarmSchedule() async {
    final s = await showTimePicker(context: context, initialTime: start);

    if (s != null) {
      setState(() {
        start = s;
      });
    }

    final e = await showTimePicker(context: context, initialTime: end);

    if (e != null) {
      setState(() {
        end = e;
      });
    }

    final isShared = homes[selectedHome]?["_shared"] == true;

    // HOME SHARE -> lưu alarm riêng
    if (isShared) {
      await FirebaseDatabase.instance
          .ref("accounts/$uid/sharedHomes/$selectedHome/alarm")
          .update({
        "enabled": true,
        "start":
        "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
        "end":
        "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
      });

      setState(() {
        homes[selectedHome]?["_customAlarm"] = {
          "enabled": true,
          "start": "${start.hour}:${start.minute}",
          "end": "${end.hour}:${end.minute}",
        };
      });

      return;
    }

    // HOME OWN
    final ownerUid = getHomeOwnerUid();

    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$selectedHome/alarm")
        .update({
      "enabled": true,
      "start": "${start.hour}:${start.minute}",
      "end": "${end.hour}:${end.minute}",
    });
    setState(() {
      homes[selectedHome]?["alarm"] = {
        "enabled": true,
        "start": "${start.hour}:${start.minute}",
        "end": "${end.hour}:${end.minute}",
      };

      alarmEnabled = true;
    });
  }

  Color getHomeColor(String h) {
    final dev = safeMap(homes[h]?["devices"]);
    final unsafe = isUnsafe(dev);
    final selected = h == selectedHome;

    if (selected) {
      return unsafe ? Colors.red.shade500 : Colors.green.shade500;
    }
    return unsafe ? Colors.red.shade300 : Colors.green.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final devices = getDevices();
    return Scaffold(
      appBar: buildSafeHomeAppBar(),
      body: Column(
        children: [
          HomeTabs(
            unreadChatByHome: unreadChatByHome,
            controller: homeTabController,
            homes: homes,
            homeOrder: homeOrder,
            selectedHome: selectedHome,

            onSelect: (h) {
              if (h == selectedHome) return;

              final currentHome = safeMap(homes[h]);

              final alarm = safeMap(
                currentHome["_customAlarm"] ?? currentHome["alarm"],
              );

              final startStr = alarm["start"]?.toString() ?? "23:00";
              final endStr = alarm["end"]?.toString() ?? "06:00";

              final s = startStr.split(":");
              final e = endStr.split(":");

              setState(() {
                selectedHome = h;

                alarmEnabled = alarm["enabled"] == true;

                start = TimeOfDay(
                  hour: int.tryParse(s[0]) ?? 23,
                  minute: int.tryParse(s[1]) ?? 0,
                );

                end = TimeOfDay(
                  hour: int.tryParse(e[0]) ?? 6,
                  minute: int.tryParse(e[1]) ?? 0,
                );
              });
            },


            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (newIndex > oldIndex) newIndex--;

                final item = homeOrder.removeAt(oldIndex);

                homeOrder.insert(newIndex, item);
              });

              await FirebaseDatabase.instance
                  .ref("accounts/$uid/homeOrder")
                  .set(homeOrder);
            },

            getHomeColor: getHomeColor,


          ),

          Expanded(
            child: DeviceList(
              devices: devices,

              header: Column(
                children: [
                  StatusPanel(
                    overall: getOverallStatus(devices),

                    onPair: null,
                    onQR: null,
                    onScheduleNotification: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) {
                          return ScheduleSheet(
                            ownerUid: getHomeOwnerUid(),
                            homeId: selectedHome,
                            isShared: homes[selectedHome]?["_shared"] == true,
                            type: "notification",
                          );
                        },
                      );
                    },

                    onScheduleAlarm: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) {
                          return ScheduleSheet(
                            ownerUid: getHomeOwnerUid(),
                            homeId: selectedHome,
                            isShared: homes[selectedHome]?["_shared"] == true,
                            type: "alarm",
                          );
                        },
                      );
                    },
                    alarmStart: formatAlarmSchedules(),
                    alarmEnd: "",
                  ),

                  if (pairingCountdown > 0)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text("Pairing: $pairingCountdown s"),
                    ),
                ],
              ),

              isShared: homes[selectedHome]?["_shared"] == true,

              ownerEmail:
              homes[selectedHome]?["_ownerEmail"]?.toString() ?? "",

              onRename: canManageHome()
                  ? renameDevice
                  : (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bạn không có quyền sửa thiết bị"),
                  ),
                );
              },

              onDelete: canManageHome()
                  ? deleteDevice
                  : (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bạn không có quyền xoá thiết bị"),
                  ),
                );
              },

              onTapDevice: (id) {
                showDeviceDetail(
                  context: context,
                  id: id,
                  d: safeMap(getDevices()[id]),
                  onRename: () => renameDevice(id),
                  onDelete: () => deleteDevice(id),
                  onNotification: () => openNotificationList(id),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.all(12),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              IconButton(icon: Icon(Icons.add_home), onPressed: addHome),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded),
                    onPressed: () {
                      showHomeChatSheet(
                        context: context,
                        homeId: selectedHome,
                        userName: userName,
                        userPhotoUrl: userPhotoUrl,
                      );
                    },
                  ),

                  if (unreadChatCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadChatCount > 99
                              ? "99+"
                              : unreadChatCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.blueAccent.withValues(alpha: 0.35),
                    ),
                  ],
                ),

                child: IconButton(
                  icon: Icon(Icons.qr_code_scanner, color: Colors.white),

                  onPressed: () async {
                    if (!canManageHome()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Bạn không có quyền pair thiết bị"),
                        ),
                      );
                      return;
                    }
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,

                      builder: (_) {
                        return SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(20),

                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Text(
                                  "Pair Sensor",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 20),

                                SizedBox(
                                  width: double.infinity,

                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.qr_code_scanner),
                                    label: Text("Scan QR Code"),

                                    onPressed: () async {
                                      Navigator.pop(context, "__SCAN__");
                                    },
                                  ),
                                ),

                                SizedBox(height: 10),

                                TextButton.icon(
                                  icon: Icon(Icons.keyboard),
                                  label: Text("Nhập HUB ID thủ công"),

                                  onPressed: () async {
                                    Navigator.pop(context, "__MANUAL__");
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    if (result == "__SCAN__") {
                      final code = await openQRScanner(context);

                      if (code != null) {
                        pairSensor(code);
                      }
                    }

                    if (result == "__MANUAL__") {
                      final hubId = await showPairDialog(context);

                      if (hubId == null || hubId.trim().isEmpty) return;

                      pairSensor(hubId.trim());
                    }
                  },
                ),
              ),

              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.settings_rounded),

                    onPressed: () {
                      showSettingsSheet(
                        homeId: selectedHome,
                        homeName:
                        homes[selectedHome]?["name"]?.toString() ?? selectedHome,
                        homeAddress:
                        homes[selectedHome]?["address"]?.toString() ?? "",

                        onTransferOwner: isOwner() ? transferOwner : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Chỉ chủ nhà mới được chuyển quyền")),
                          );
                        },
                        onRenameHome: canManageHome() ? renameHome : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Bạn không có quyền sửa tên nhà")),
                          );
                        },
                        onDeleteHome: isOwner() ? deleteHome : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Chỉ chủ nhà mới được xoá nhà")),
                          );
                        },                        context: context,
                        inviteCount: shareRequests.length,

                        onShareRequests: () {
                          showShareRequestSheet(
                            context: context,
                            inviteCount: shareRequests.length,
                            requests: shareRequests,
                            uid: uid,
                          );
                        },

                        onShare: canManageHome() ? shareHome : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Bạn không có quyền chia sẻ nhà")),
                          );
                        },
                        onShareList: () {
                          showShareListSheet(
                            canManageMembers: canManageHome(),
                            isOwner: isOwner(),
                            context: context,
                            ownerUid: getHomeOwnerUid(),
                            homeId: selectedHome,
                          );
                        },
                        onLogout: logout,
                      );
                    },
                  ),

                  if (shareRequests.length > 0)
                    Positioned(
                      right: 6,
                      top: 6,

                      child: Container(
                        padding: EdgeInsets.all(4),

                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),

                        child: Text(
                          "${shareRequests.length}",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}