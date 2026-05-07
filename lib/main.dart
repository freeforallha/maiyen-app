import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../firebase_options.dart';
import 'all_home_page.dart';
import 'device_list.dart';
import 'home_tabs.dart';
import 'status_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLogin = true;
  String error = "";

  Future<void> submit() async {
    setState(() => error = "");
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
        final uid = cred.user!.uid;
        await FirebaseDatabase.instance.ref("accounts/$uid").set({
          "homes": {
            "home1": {"name": "Home 1", "devices": {}},
          },
          "alarm": {"enabled": false, "start": "23:00", "end": "06:00"},
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == "user-not-found") {
          error = "Sai tài khoản";
        } else if (e.code == "wrong-password") {
          error = "Sai mật khẩu";
        } else if (e.code == "email-already-in-use") {
          error = "Email đã tồn tại";
        } else if (e.code == "weak-password") {
          error = "Mật khẩu quá yếu";
        } else {
          error = e.message ?? "Lỗi đăng nhập";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 340,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SafeHome",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: pass,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),

              if (error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(error, style: TextStyle(color: Colors.red)),
                ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: submit,
                child: Text(isLogin ? "Login" : "Sign Up"),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    error = "";
                  });
                },
                child: Text(
                  isLogin
                      ? "Chưa có tài khoản? Đăng ký"
                      : "Đã có tài khoản? Đăng nhập",
                ),
              ),
            ],
          ),
        ),
      ),
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

    uid = FirebaseAuth.instance.currentUser!.uid;
    ref = FirebaseDatabase.instance.ref("accounts/$uid");

    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = safeMap(data);
      final homesData = safeMap(map["homes"]);

      setState(() {
        homes = homesData;

        final savedOrder = map["homeOrder"];

        if (savedOrder != null) {
          homeOrder = List<String>.from(savedOrder);

          // thêm home mới chưa có
          for (final id in homesData.keys) {
            if (!homeOrder.contains(id)) {
              homeOrder.add(id);
            }
          }
        } else {
          homeOrder = homesData.keys.toList();
        }

        // 🔥 FIX QUAN TRỌNG: chọn home đầu tiên theo ORDER
        if (homeOrder.isNotEmpty) {
          if (!homeOrder.contains(selectedHome)) {
            selectedHome = homeOrder.first; // 👈 HOME NGOÀI CÙNG BÊN PHẢI
          }
        } else {
          selectedHome = "";
        }

        final alarm = safeMap(map["alarm"]);
        alarmEnabled = alarm["enabled"] == true;
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

  // ================= PAIR DIALOG =================
  void showPairDialog() async {
    final controller = TextEditingController();

    final hubId = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Nhập HUB ID"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "vd: HUB_001"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text("Pair"),
          ),
        ],
      ),
    );

    if (hubId == null || hubId.trim().isEmpty) return;
    pairSensor(hubId.trim());
  }

  // ================= QR SCAN =================
  void scanQR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text("Scan QR HUB")),
          body: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final code = barcodes.first.rawValue;
              if (code == null) return;

              Navigator.pop(context);
              pairSensor(code);
            },
          ),
        ),
      ),
    );
  }

  Future<bool> confirm(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Không"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("OK"),
          ),
        ],
      ),
    );
    return result == true;
  }

  void deleteHome() async {
    if (!await confirm("Xóa Home?")) return;
    FirebaseDatabase.instance.ref("accounts/$uid/homes/$selectedHome").remove();
  }

  void deleteDevice(String id) async {
    if (!await confirm("Xóa Device?")) return;
    FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$selectedHome/devices/$id")
        .remove();
  }

  void logout() async {
    if (!await confirm("Đăng xuất?")) return;
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
    });
  }

  // ================= RESTORED FULL FUNCTIONS =================

  void renameHome() async {
    final controller = TextEditingController(
      text: homes[selectedHome]?["name"] ?? selectedHome,
    );

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

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$selectedHome/name")
        .set(name);
  }

  void renameDevice(String id) async {
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

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$selectedHome/devices/$id/name")
        .set(name);
  }

  void setAlarmSchedule() async {
    final s = await showTimePicker(context: context, initialTime: start);
    if (s != null) start = s;

    final e = await showTimePicker(context: context, initialTime: end);
    if (e != null) end = e;

    await FirebaseDatabase.instance.ref("accounts/$uid/alarm").update({
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
          IconButton(icon: Icon(Icons.logout), onPressed: logout),
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

            onOpenAllHome: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AllHomePage(homes: homes)),
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                StatusPanel(
                  overall: getOverallStatus(devices),
                  onPair: showPairDialog,
                  onQR: scanQR,
                ),
                if (pairingCountdown > 0) Text("Pairing: $pairingCountdown s"),
                DeviceList(
                  devices: devices,
                  onRename: renameDevice,
                  onDelete: deleteDevice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
