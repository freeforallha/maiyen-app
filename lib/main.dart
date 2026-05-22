import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'helpers/home_helper.dart';
import 'pages/all_home_page.dart';
import 'pages/confirm_dialog.dart';
import 'pages/device_detail_sheet.dart';
import 'pages/login_page.dart';
import 'pages/notification_list_sheet.dart';
import 'pages/pair_dialog.dart';
import 'pages/qr_scan_page.dart';
import 'pages/settings_sheet.dart';
import 'pages/share_list_sheet.dart';
import 'pages/share_request_sheet.dart';
import 'services/fcm_service.dart';
import 'services/home_listener_service.dart';
import 'services/home_service.dart';
import 'services/notification_service.dart';
import 'widgets/device_list.dart';
import 'widgets/home_tabs.dart';
import 'widgets/status_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(SafeHomeApp());
}

class SafeHomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (!snap.hasData) return LoginPage();
        return HomePage();
      },
    );
  }
}

// ================= HOME =================
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> shareRequests = {};

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
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.home_rounded, color: Colors.blueAccent, size: 20),
          ),

          SizedBox(width: 10),

          Text(
            "SafeHome",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),

      centerTitle: false,

      elevation: 0,
    );
  }

  late String uid;
  late DatabaseReference ref;

  String getHomeOwnerUid() {
    final isShared = homes[selectedHome]?["_shared"] == true;

    if (isShared) {
      return homes[selectedHome]?["_ownerUid"] ?? uid;
    }

    return uid;
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

  Map<String, dynamic> getDevices() {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["devices"]);
  }

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser!.uid;
    FCMService.setupFCM(uid: uid);

    FCMService.listenForeground(localNotif: localNotif);
    ref = FirebaseDatabase.instance.ref("accounts/$uid");

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = safeMap(data);
      final homesData = safeMap(map["homes"]);
      final sharedHomes = safeMap(map["sharedHomes"]);
      final requests = safeMap(map["shareRequests"]);
      setState(() {
        shareRequests = requests;
        homes = homesData;
        HomeListenerService.loadSharedHomes(
          homes: homes,
          sharedHomes: sharedHomes,

          refresh: () {
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
  }

  void pairSensor(String hubId) {
    final isShared = homes[selectedHome]?["_shared"] == true;

    if (isShared) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không thể pair sensor vào Home được share"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

      await FirebaseDatabase.instance
          .ref("accounts/$uid/homeOrder")
          .set(homeOrder);

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

    // share
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
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Tên Home"),
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

    final id = "home_${DateTime.now().millisecondsSinceEpoch}";

    await HomeService.addHome(uid: uid, id: id, name: name);
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
            controller: homeTabController,
            homes: homes,
            homeOrder: homeOrder,
            selectedHome: selectedHome,

            onSelect: (h) {
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

            onDoubleTapHome: (h) async {
              setState(() {
                selectedHome = h;
              });

              showModalBottomSheet(
                context: context,

                builder: (_) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        ListTile(
                          leading: Icon(Icons.schedule),
                          title: Text("Giờ báo động"),

                          onTap: () {
                            Navigator.pop(context);
                            setAlarmSchedule();
                          },
                        ),

                        ListTile(
                          leading: Icon(Icons.edit),
                          title: Text("Sửa tên Home"),

                          onTap: () {
                            Navigator.pop(context);
                            renameHome();
                          },
                        ),

                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            "Xoá Home",
                            style: TextStyle(color: Colors.red),
                          ),

                          onTap: () {
                            Navigator.pop(context);
                            deleteHome();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },

            onOpenAllHome: () async {
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

                    duration: Duration(milliseconds: 300),

                    curve: Curves.easeOut,
                  );
                }
              }
            },
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

                    alarmStart: formatTime(
                      safeMap(
                        homes[selectedHome]?["_customAlarm"] ??
                            homes[selectedHome]?["alarm"],
                      )["start"]?.toString() ??
                          "--:--",
                    ),

                    alarmEnd: formatTime(
                      safeMap(
                        homes[selectedHome]?["_customAlarm"] ??
                            homes[selectedHome]?["alarm"],
                      )["end"]?.toString() ??
                          "--:--",
                    ),
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

              onRename: renameDevice,
              onDelete: deleteDevice,

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

                  onPressed: homes[selectedHome]?["_shared"] == true
                      ? null
                      : () async {
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
                        context: context,
                        inviteCount: shareRequests.length,

                        onShareRequests: () {
                          showShareRequestSheet(
                            context: context,
                            inviteCount: shareRequests.length,
                            requests: shareRequests,
                            uid: uid,
                          );
                        },

                        onShare: shareHome,

                        onShareList: () {
                          showShareListSheet(
                            context: context,
                            ownerUid: uid,
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
