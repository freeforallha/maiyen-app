import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'all_home_page.dart';
import 'device_list.dart';
import 'home_tabs.dart';
import 'pages/confirm_dialog.dart';
import 'pages/device_detail_sheet.dart';
import 'pages/login_page.dart';
import 'pages/pair_dialog.dart';
import 'pages/qr_scan_page.dart';
import 'pages/settings_sheet.dart';
import 'services/notification_service.dart';
import 'status_panel.dart';

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
  Future<void> setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    final token = await messaging.getToken();

    print("NEW FCM TOKEN: $token");

    if (token != null) {
      await FirebaseDatabase.instance.ref("accounts/$uid/fcmToken").set(token);
    }

    // token tự refresh
    messaging.onTokenRefresh.listen((newToken) async {
      print("REFRESH TOKEN: $newToken");

      await FirebaseDatabase.instance
          .ref("accounts/$uid/fcmToken")
          .set(newToken);
    });
  }

  void showDeviceMenu(String deviceId, Map d) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final status = d["status"]?.toString();
        final tamper = d["tamper"] == true;

        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d["name"] ?? deviceId,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == "closed" ? Icons.check_circle : Icons.cancel,
                    color: status == "closed" ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 6),
                  Text(status == "closed" ? "Đang Đóng" : "Đang Mở"),
                ],
              ),

              SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tamper ? Icons.warning : Icons.verified,
                    color: tamper ? Colors.red : Colors.green,
                  ),
                  SizedBox(width: 6),
                  Text(tamper ? "Bị tháo" : "Bình thường"),
                ],
              ),

              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      renameDevice(deviceId);
                    },
                    icon: Icon(Icons.edit),
                    label: Text("Rename"),
                  ),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      deleteDevice(deviceId);
                    },
                    icon: Icon(Icons.delete),
                    label: Text("Delete"),
                  ),
                ],
              ),
            ],
          ),
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

  Map<String, dynamic> getOverallStatus(Map<String, dynamic> devices) {
    List<String> issues = [];

    devices.forEach((id, raw) {
      final d = safeMap(raw);

      final name = d["name"]?.toString() ?? id;
      final status = d["status"]?.toString();
      final tamper = d["tamper"] == true;

      List<String> problem = [];

      if (status != "closed") {
        problem.add("Mở");
      }

      if (tamper) {
        problem.add("Bị tháo");
      }

      if (problem.isNotEmpty) {
        issues.add("$name: ${problem.join(" & ")}");
      }
    });

    return {"safe": issues.isEmpty, "issues": issues};
  }

  Map<String, dynamic> homes = {};
  String selectedHome = "";

  List<String> homeOrder = [];

  TimeOfDay start = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 6, minute: 0);

  bool alarmEnabled = false;

  int pairingCountdown = 0;
  Timer? timer;

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  Map<String, dynamic> getDevices() {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["devices"]);
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((message) {
      print("MESSAGE DATA: ${message.data}");
      print("MESSAGE NOTIF: ${message.notification}");
      final notif = message.notification;

      if (notif == null) return;

      localNotif.show(
        0,
        notif.title,
        notif.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            'Alarm',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
    uid = FirebaseAuth.instance.currentUser!.uid;
    setupFCM();
    ref = FirebaseDatabase.instance.ref("accounts/$uid");

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = safeMap(data);
      final homesData = safeMap(map["homes"]);
      final sharedHomes = safeMap(map["sharedHomes"]);
      setState(() {
        homes = homesData;
        for (final entry in sharedHomes.entries) {
          final homeId = entry.key;

          final ownerUid = safeMap(entry.value)["ownerUid"]?.toString();

          if (ownerUid == null) continue;

          FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId")
              .onValue
              .listen((sharedEvent) {
                final sharedData = sharedEvent.snapshot.value;

                // owner đã xóa home
                if (sharedData == null) {
                  setState(() {
                    homes.remove(homeId);
                    homeOrder.remove(homeId);

                    if (selectedHome == homeId) {
                      selectedHome = homeOrder.isNotEmpty
                          ? homeOrder.first
                          : "";
                    }
                  });

                  return;
                }

                final sharedHome = Map<String, dynamic>.from(sharedData as Map);

                setState(() {
                  FirebaseDatabase.instance
                      .ref("accounts/$ownerUid/email")
                      .get()
                      .then((emailSnap) {
                        final ownerEmail =
                            emailSnap.value?.toString() ?? "Unknown";

                        setState(() {
                          homes[homeId] = {
                            ...sharedHome,
                            "_shared": true,
                            "_ownerUid": ownerUid,
                            "_ownerEmail": ownerEmail,
                          };
                        });
                      });
                });
              });
        }

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

  bool isUnsafe(Map dev) {
    return dev.values.any((d) {
      final status = d["status"]?.toString();
      final tamper = d["tamper"] == true;
      return status != "closed" || tamper;
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
    if (!await showConfirmDialog(context, "Xóa Home?")) return;

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

    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$selectedHome/devices/$id")
        .remove();
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

    await FirebaseDatabase.instance.ref("accounts/$uid/homes/$id").set({
      "name": name,
      "devices": {},

      "alarm": {"enabled": false, "start": "23:00", "end": "06:00"},
    });
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

    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$selectedHome/name")
        .set(name);
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

    await FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$selectedHome/devices/$id/name")
        .set(name);
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

  Color getDeviceColor(Map d) {
    final status = d["status"]?.toString();
    final tamper = d["tamper"] == true;

    if (status != "closed" || tamper) return Colors.red.shade200;
    return Colors.green.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final devices = getDevices();
    final unsafe = isUnsafe(devices);

    return Scaffold(
      appBar: AppBar(
        title: Text("SafeHome"),
        actions: [
          IconButton(icon: Icon(Icons.schedule), onPressed: setAlarmSchedule),
          IconButton(icon: Icon(Icons.edit), onPressed: renameHome),
          IconButton(icon: Icon(Icons.add_home), onPressed: addHome),
          IconButton(icon: Icon(Icons.delete), onPressed: deleteHome),

          IconButton(
            icon: Icon(Icons.settings_rounded),
            onPressed: () {
              showSettingsSheet(
                context: context,
                onShare: shareHome,
                onLogout: logout,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          HomeTabs(
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
