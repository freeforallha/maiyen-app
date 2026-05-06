import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SafeHomeApp());
}

// ================= ROOT =================
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

// ================= AUTH =================
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

// ================= LOGIN =================
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
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );

        final uid = cred.user!.uid;

        await FirebaseDatabase.instance.ref("accounts/$uid").set({
          "homes": {
            "home1": {"name": "Home 1", "devices": {}}
          },
          "alarm": {
            "enabled": false,
            "start": "23:00",
            "end": "06:00"
          }
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
              Text("SafeHome",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              TextField(
                  controller: email,
                  decoration: InputDecoration(labelText: "Email")),
              TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Password")),

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
                child: Text(isLogin
                    ? "Chưa có tài khoản? Đăng ký"
                    : "Đã có tài khoản? Đăng nhập"),
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

    return {
      "safe": issues.isEmpty,
      "issues": issues
    };
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

      if (homesData.isNotEmpty) {
        // luôn ưu tiên home đầu tiên khi mở app hoặc khi load lại data lần đầu
        selectedHome = homesData.keys.first;
      } else {
        selectedHome = "";
      }

      homeOrder = homesData.keys.toList();

      setState(() {
        homes = homesData;

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
      "time": DateTime.now().millisecondsSinceEpoch
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
              child: Text("Hủy")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text("Pair")),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Không")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("OK")),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text("OK")),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final id = "home_${DateTime.now().millisecondsSinceEpoch}";

    await FirebaseDatabase.instance
        .ref("accounts/$uid/homes/$id")
        .set({"name": name, "devices": {}});
  }

  // ================= RESTORED FULL FUNCTIONS =================

  void renameHome() async {
    final controller = TextEditingController(
        text: homes[selectedHome]?["name"] ?? selectedHome);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Home"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text("OK")),
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
        text: getDevices()[id]?["name"] ?? id);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Device"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text("OK")),
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
      "end": "${end.hour}:${end.minute}"
    });
  }

  Color getHomeColor(String h) {
    final dev = safeMap(homes[h]?["devices"]);
    final unsafe = isUnsafe(dev);
    final selected = h == selectedHome;

    if (selected) return unsafe ? Colors.red : Colors.green;
    return unsafe ? Colors.red.shade200 : Colors.green.shade200;
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
          Container(
            height: 70,
            child: Row(
              children: [

                // ================= ALL HOME (LEFT FIXED) =================
                Padding(
                  padding: EdgeInsets.only(left: 8, right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllHomePage(homes: homes),
                          ),
                        );
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),

                          // 🤍 trắng sáng nhẹ (clean premium)
                          color: Colors.white,

                          // 💡 bóng nhẹ để nổi lên nền
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Center(
                          child: Icon(
                            Icons.dashboard_rounded,
                            color: Colors.black87, // tương phản đẹp với nền trắng
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ================= HOME LIST (SCROLLABLE) =================
                Expanded(
                  child: ReorderableListView(
                    scrollDirection: Axis.horizontal,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = homeOrder.removeAt(oldIndex);
                        homeOrder.insert(newIndex, item);
                      });
                    },
                    children: homeOrder.map((h) {
                      return Container(
                        key: ValueKey(h),
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedHome = h),
                          child: Container(
                            width: 80,
                            height: 60,
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: getHomeColor(h),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              homes[h]?["name"] ?? h,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Builder(
                    builder: (_) {
                      final overall = getOverallStatus(devices);

                      return Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: overall["safe"]
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ===== STATUS =====
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        overall["safe"] ? Icons.verified : Icons.warning,
                                        color: overall["safe"] ? Colors.green : Colors.red,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        overall["safe"]
                                            ? "ĐÃ AN TOÀN"
                                            : "CHƯA AN TOÀN",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: overall["safe"] ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (!overall["safe"])
                                    ...overall["issues"].map<Widget>((e) => Text(
                                      "- $e",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    )),
                                ],
                              ),
                            ),

                            // ===== BUTTONS =====
                            Row(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: "pair",
                                  onPressed: showPairDialog,
                                  child: Icon(Icons.link),
                                ),
                                SizedBox(width: 8),
                                FloatingActionButton.small(
                                  heroTag: "qr",
                                  onPressed: scanQR,
                                  child: Icon(Icons.qr_code_scanner),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                if (pairingCountdown > 0)
                  Text("Pairing: $pairingCountdown s"),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),

                        // 📦 VIỀN TOÀN BỘ BẢNG DEVICE
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),

                        borderRadius: BorderRadius.circular(16),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          // ===== HEADER PANEL =====
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sensors, color: Colors.white70, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "DEVICES",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ===== DEVICE LIST =====
                          Expanded(
                            child: ListView(
                              children: devices.entries.map((e) {
                                final d = safeMap(e.value);

                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                                  decoration: BoxDecoration(
                                    color: getDeviceColor(d).withOpacity(0.9),

                                    borderRadius: BorderRadius.circular(12),

                                    // 👇 VIỀN TỪNG DEVICE
                                    border: Border.all(
                                      color: (d["status"] != "closed" || d["tamper"] == true)
                                          ? Colors.red.shade300
                                          : Colors.green.shade300,
                                      width: 1,
                                    ),
                                  ),

                                  child: ListTile(
                                    dense: true,

                                    title: Text(
                                      d["name"]?.toString() ?? e.key,
                                      style: TextStyle(fontSize: 13),
                                    ),

                                    subtitle: Text(
                                      "${d["status"] ?? "unknown"} | ${d["tamper"] == true ? "Tamper" : "Normal"}",
                                      style: TextStyle(fontSize: 11),
                                    ),

                                    onLongPress: () => renameDevice(e.key),

                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, size: 18),
                                      onPressed: () => deleteDevice(e.key),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ================= ALL HOME PAGE =================
class AllHomePage extends StatelessWidget {
  final Map<String, dynamic> homes;

  AllHomePage({required this.homes});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Homes")),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: GridView.builder(
          itemCount: homes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 👈 1 hàng 5 ô
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final e = homes.entries.elementAt(index);
            final homeId = e.key;
            final data = safeMap(e.value);
            final devices = safeMap(data["devices"]);
            final unsafe = isUnsafe(devices);

            return InkWell(
              onTap: () {
                Navigator.pop(context, homeId); // 👈 optional: quay lại chọn home
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: unsafe ? Colors.red.shade300 : Colors.green.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data["name"] ?? homeId,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      )
    );
  }
}