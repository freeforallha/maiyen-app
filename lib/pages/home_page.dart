import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../helpers/firebase_paths.dart';

import '../helpers/home_helper.dart';
import '../services/fcm_service.dart';
import '../services/home_listener_service.dart';
import '../services/home_service.dart';
import '../services/home_state_parser.dart';
import '../services/chat_service.dart';
import '../services/share_service.dart';
import '../services/notification_service.dart';
import '../widgets/home_tabs.dart';
import '../widgets/device_list.dart';
import '../widgets/status_panel.dart';
import '../sheets/account_avatar_sheet.dart';
import 'all_home_page.dart';
import '../dialogs/confirm_dialog.dart';
import '../sheets/device_detail_sheet.dart';
import '../sheets/notification_list_sheet.dart' as notif_sheet;
import '../dialogs/pair_dialog.dart';
import 'qr_scan_page.dart';
import '../sheets/settings_sheet.dart';
import '../sheets/share_list_sheet.dart';
import '../sheets/share_request_sheet.dart';
import 'edit_profile_page.dart';
import '../sheets/home_chat_sheet.dart';
import '../sheets/schedule_sheet.dart';
import '../sheets/all_devices_sheet.dart';

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
        return notif_sheet.NotificationListSheet(
          ownerUid: ownerUid,
          homeId: selectedHome,
          deviceId: deviceId,
        );
      },
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
  Map<String, dynamic> alarmSettings = {};
  List<String> homeOrder = [];

  TimeOfDay start = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 6, minute: 0);

  bool alarmEnabled = false;
  Future<void> setAlarmEnabled(bool enabled) async {
    final homeId = selectedHome;

    setState(() {
      alarmEnabled = enabled;
      alarmSettings[homeId] = {
        "enabled": enabled,
      };
    });

    await FirebaseDatabase.instance
        .ref("accounts/$uid/alarmSettings/$homeId/enabled")
        .set(enabled);
  }
  int pairingCountdown = 0;
  Timer? timer;
  final ScrollController homeTabController = ScrollController();
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

    final enabled = alarms.where((e) => e["enabled"] == true).toList();

    if (enabled.isEmpty) {
      return "Chưa bật";
    }

    String repeatText(dynamic value) {
      final minutes = int.tryParse(value?.toString() ?? "0") ?? 0;

      if (minutes == 15) return " • Lặp 15'";
      if (minutes == 30) return " • Lặp 30'";
      if (minutes == 60) return " • Lặp 1h";

      return " • Không lặp";
    }

    if (enabled.length == 1) {
      final item = enabled.first;

      return "${item["start"]} - ${item["end"]}${repeatText(item["repeatMinutes"])}";
    }

    return "${enabled.length} khung giờ";
  }
  Map<String, dynamic> getDevices() {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["devices"]);
  }
  Map<String, dynamic>? getTemperatureDevice() {
    final devices = getDevices();

    for (final entry in devices.entries) {
      final d = safeMap(entry.value);

      if (d["type"] == "temperature") {
        return {
          "id": entry.key,
          "data": d,
        };
      }
    }

    return null;
  }
  String getHomeEnvironmentText() {
    final devices = getDevices();

    for (final item in devices.values) {
      final d = safeMap(item);

      if (d["type"] == "temperature") {
        final temp = d["temperature"];
        final humidity = d["humidity"];

        final tempText = temp != null ? "$temp°C" : "--";
        final humidityText = humidity != null ? "$humidity%" : "--";

        return "$tempText / $humidityText";
      }
    }

    return "--°C / --%";
  }
  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser!.uid;
    FCMService.setupFCM(uid: uid);

    FCMService.listenForeground(
      localNotif: localNotif,
    );
    ref = FirebaseDatabase.instance.ref(FirebasePaths.account(uid));

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = safeMap(data);
      final homesData = safeMap(map["homes"]);
      final sharedHomes = safeMap(map["sharedHomes"]);
      final requests = safeMap(map["shareRequests"]);
      final userAlarmSettings = safeMap(map["alarmSettings"]);
      setState(() {
        shareRequests = requests;
        alarmSettings = userAlarmSettings;
        final profile = HomeStateParser.parseProfile(map);

        userName = profile["name"] ?? "";
        userGender = profile["gender"] ?? "";
        userDob = profile["dob"] ?? "";
        userPhone = profile["phone"] ?? "";
        userPhotoUrl = profile["photoUrl"] ?? "";
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
        homeOrder = HomeStateParser.parseHomeOrder(
          account: map,
          homesData: homesData,
          sharedHomes: sharedHomes,
          selectedHome: selectedHome,
        );

        // 🔥 FIX QUAN TRỌNG: chọn home đầu tiên theo ORDER
        if (homeOrder.isNotEmpty) {
          if (!homeOrder.contains(selectedHome)) {
            selectedHome = homeOrder.first; // 👈 HOME NGOÀI CÙNG BÊN PHẢI
          }
        } else {
          selectedHome = "";
        }
        final currentHome = safeMap(homes[selectedHome]);
        final parsedAlarm = HomeStateParser.parseAlarm(currentHome);

        final userAlarmSetting = safeMap(
          map["alarmSettings"]?[selectedHome],
        );

        alarmEnabled = userAlarmSetting["enabled"] != false;
        start = parsedAlarm["start"];
        end = parsedAlarm["end"];
      });
    });
    ChatService.chatStream().listen((event) {
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

    FirebaseDatabase.instance.ref(FirebasePaths.pairRequest(requestId)).set({
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
      if (ownerUid != null) {
        await ShareService.leaveSharedHome(
          uid: uid,
          ownerUid: ownerUid,
          homeId: leavingHomeId,
        );
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

    await ShareService.deleteOwnedHome(
      ownerUid: uid,
      homeId: selectedHome,
    );
    homeOrder.remove(selectedHome);

    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
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
    final targetUid = await ShareService.findUidByEmail(
      targetEmail,
    );
    if (targetUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email chưa đăng ký"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final targetData = await ShareService.loadAccount(
      targetUid,
    );

    await ShareService.sendShareRequest(
      ownerUid: uid,
      targetUid: targetUid,
      homeId: selectedHome,
      ownerEmail: myEmail ?? "",
      targetData: targetData,
      targetEmail: targetEmail,
    );

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

    final homeId = selectedHome;

    await ShareService.transferOwner(
      oldOwnerUid: uid,
      newOwnerUid: targetUid,
      homeId: homeId,
    );

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
        .ref(FirebasePaths.homeOrder(uid))
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

    await HomeService.addHome(
      uid: uid,
      id: id,
      name: name,
      address: address,
    );
    homeOrder.add(id);

    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
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
          .ref("${FirebasePaths.sharedHome(uid, selectedHome)}/customName")
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
        backgroundColor: const Color(0xFFF4F7FB),
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
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded),
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

                  Expanded(
                    child: HomeTabs(
                      unreadChatByHome: unreadChatByHome,
                      controller: homeTabController,
                      homes: homes,
                      homeOrder: homeOrder,
                      selectedHome: selectedHome,
                      onSelect: (h) {
                        if (h == selectedHome) return;

                        final currentHome = safeMap(homes[h]);
                        final parsedAlarm = HomeStateParser.parseAlarm(currentHome);

                        setState(() {
                          selectedHome = h;
                          alarmEnabled =
                              safeMap(alarmSettings[h])["enabled"] != false;
                          start = parsedAlarm["start"];
                          end = parsedAlarm["end"];
                        });
                      },
                      onReorder: (oldIndex, newIndex) async {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;

                          final item = homeOrder.removeAt(oldIndex);
                          homeOrder.insert(newIndex, item);
                        });

                        await FirebaseDatabase.instance
                            .ref(FirebasePaths.homeOrder(uid))
                            .set(homeOrder);
                      },
                      getHomeColor: getHomeColor,
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Stack(
                  children: [
                    DeviceList(
                      devices: devices,
                      header: Column(
                        children: [
                          StatusPanel(
                            environmentText: getHomeEnvironmentText(),
                            onEnvironmentTap: () {
                              final tempDevice = getTemperatureDevice();

                              if (tempDevice == null) return;

                              showDeviceDetail(
                                context: context,
                                id: tempDevice["id"],
                                d: tempDevice["data"],
                                onRename: () => renameDevice(tempDevice["id"]),
                                onDelete: () => deleteDevice(tempDevice["id"]),
                                onNotification: () =>
                                    openNotificationList(tempDevice["id"]),
                              );
                            },
                            overall: getOverallStatus(devices),
                            alarmEnabled: alarmEnabled,
                            onAlarmEnabledChanged: setAlarmEnabled,
                            onPair: null,
                            onQR: null,
                            onScheduleNotification: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ScheduleSheet(
                                  ownerUid: getHomeOwnerUid(),
                                  homeId: selectedHome,
                                  isShared:
                                  homes[selectedHome]?["_shared"] == true,
                                  type: "notification",
                                ),
                              );
                            },
                            onScheduleAlarm: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ScheduleSheet(
                                  ownerUid: getHomeOwnerUid(),
                                  homeId: selectedHome,
                                  isShared:
                                  homes[selectedHome]?["_shared"] == true,
                                  type: "alarm",
                                ),
                              );
                            },
                            alarmStart: formatAlarmSchedules(),
                            alarmEnd: "",
                          ),

                          if (pairingCountdown > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text("Pairing: $pairingCountdown s"),
                            ),
                        ],
                      ),
                      isShared: homes[selectedHome]?["_shared"] == true,
                      ownerEmail:
                      homes[selectedHome]?["_ownerEmail"]?.toString() ?? "",
                      onRename: canManageHome() ? renameDevice : (_) {},
                      onDelete: canManageHome() ? deleteDevice : (_) {},
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

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 95,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.88),
                                Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),


      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: 0),
              const Color(0xFFFFFFFF).withValues(alpha: 0.92),
              const Color(0xFFFFFFFF),
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        padding: const EdgeInsets.only(top: 22),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_rounded),
                  onPressed: () => AccountAvatarSheet.show(
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
                          ),
                        ),
                      );
                    },
                    userName: userName,
                    userGender: userGender,
                    userDob: userDob,
                    userPhone: userPhone,
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.add_home),
                  onPressed: addHome,
                ),

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
                          ownerUid: getHomeOwnerUid(),
                          canManageMembers: canManageHome(),
                          isOwner: isOwner(),
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
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
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
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Pair Sensor",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      label: const Text("Scan QR Code"),
                                      onPressed: () async {
                                        Navigator.pop(context, "__SCAN__");
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    icon: const Icon(Icons.keyboard),
                                    label: const Text("Nhập HUB ID thủ công"),
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
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () {
                        showSettingsSheet(
                          homeId: selectedHome,
                          homeName:
                          homes[selectedHome]?["name"]?.toString() ?? selectedHome,
                          homeAddress:
                          homes[selectedHome]?["address"]?.toString() ?? "",
                          onAllDevices: () {
                            showAllDevicesSheet(
                              context: context,
                              devices: getDevices(),
                            );
                          },
                          onTransferOwner: isOwner() ? transferOwner : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Chỉ chủ nhà mới được chuyển quyền"),
                              ),
                            );
                          },
                          onRenameHome: canManageHome() ? renameHome : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Bạn không có quyền sửa tên nhà"),
                              ),
                            );
                          },
                          onDeleteHome: isOwner() ? deleteHome : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Chỉ chủ nhà mới được xoá nhà"),
                              ),
                            );
                          },
                          context: context,
                          inviteCount: shareRequests.length,
                          onShareRequests: () {
                            showShareRequestSheet(
                              context: context,
                              requests: shareRequests,
                              uid: uid,
                            );
                          },
                          onShare: canManageHome() ? shareHome : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Bạn không có quyền chia sẻ nhà"),
                              ),
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
                    if (shareRequests.isNotEmpty)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${shareRequests.length}",
                            style: const TextStyle(
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
      ),
    );
  }
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}