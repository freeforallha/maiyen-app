import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'all_home_page.dart';
import 'device_list.dart';
import 'firebase_options.dart';
import 'helpers/home_helper.dart';
import 'home_tabs.dart';
import 'pages/confirm_dialog.dart';
import 'pages/device_detail_sheet.dart';
import 'pages/login_page.dart';
import 'pages/pair_dialog.dart';
import 'pages/qr_scan_page.dart';
import 'pages/settings_sheet.dart';
import 'services/fcm_service.dart';
import 'services/home_listener_service.dart';
import 'services/home_service.dart';
import 'services/notification_service.dart';
import 'status_panel.dart';
import 'widgets/home_appbar.dart';

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
  PreferredSizeWidget buildSafeHomeAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
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
      setState(() {
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
        final alarm = safeMap(currentHome["alarm"]);
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

    // Không cho pair vào home shared
    if (isShared) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không thể pair sensor vào Home được share"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    FirebaseDatabase.instance.ref("system/pairing").set({
      "active": true,
      "homeId": selectedHome,
      "hubId": hubId,
      "requestedBy": uid,
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

      await FirebaseDatabase.instance
          .ref("accounts/$uid/sharedHomes/$selectedHome")
          .remove();

      setState(() {
        homes.remove(selectedHome);
        homeOrder.remove(selectedHome);

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

    final accountsSnap = await FirebaseDatabase.instance.ref("accounts").get();

    if (accountsSnap.exists) {
      final accounts = Map<String, dynamic>.from(accountsSnap.value as Map);

      for (final entry in accounts.entries) {
        final otherUid = entry.key;

        await FirebaseDatabase.instance
            .ref("accounts/$otherUid/sharedHomes/$selectedHome")
            .remove();
      }
    }

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
    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/sharedHomes/$selectedHome")
        .set({"ownerUid": uid});

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
    final controller = TextEditingController(
      text: homes[selectedHome]?["name"] ?? selectedHome,
    );
    if (homes[selectedHome]?["_shared"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể sửa home được share")));
      return;
    }
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
    if (homes[selectedHome]?["_shared"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Home được share không thể sửa Alarm")),
      );
      return;
    }
    final s = await showTimePicker(context: context, initialTime: start);
    if (s != null) start = s;

    final e = await showTimePicker(context: context, initialTime: end);
    if (e != null) end = e;

    final ownerUid = getHomeOwnerUid();

    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$selectedHome/alarm")
        .update({
          "enabled": true,
          "start": "${start.hour}:${start.minute}",
          "end": "${end.hour}:${end.minute}",
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
    final unsafe = isUnsafe(devices);

    return Scaffold(
      appBar: buildHomeAppBar(
        onSchedule: setAlarmSchedule,
        onRename: renameHome,
        onAddHome: addHome,
        onDelete: deleteHome,

        onSettings: () {
          showSettingsSheet(
            context: context,
            onShare: shareHome,
            onLogout: logout,
          );
        },
      ),
      body: Column(
        children: [
          HomeTabs(
            controller: homeTabController,
            homes: homes,
            homeOrder: homeOrder,
            selectedHome: selectedHome,

            onSelect: (h) {
              setState(() => selectedHome = h);
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
            child: Column(
              children: [
                StatusPanel(
                  overall: getOverallStatus(devices),

                  onPair: homes[selectedHome]?["_shared"] == true
                      ? null
                      : () async {
                          final hubId = await showPairDialog(context);

                          if (hubId == null || hubId.trim().isEmpty) {
                            return;
                          }

                          pairSensor(hubId.trim());
                        },

                  onQR: homes[selectedHome]?["_shared"] == true
                      ? null
                      : () async {
                          final code = await openQRScanner(context);

                          if (code != null) {
                            pairSensor(code);
                          }
                        },
                ),
                if (pairingCountdown > 0) Text("Pairing: $pairingCountdown s"),
                DeviceList(
                  devices: devices,
                  onRename: renameDevice,
                  onDelete: deleteDevice,
                  onTapDevice: (id) {
                    showDeviceDetail(
                      context: context,
                      id: id,
                      d: safeMap(getDevices()[id]),
                      onRename: () => renameDevice(id),
                      onDelete: () => deleteDevice(id),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
