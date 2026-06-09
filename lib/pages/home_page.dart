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
import '../sheets/home_event_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../sheets/alarm_device_sheet.dart';
import '../helpers/top_toast.dart';
import '../services/home_notification_service.dart';
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> shareRequests = {};
  int unreadChatCount = 0;
  Map<String, int> unreadChatByHome = {};
  int unreadHomeNotificationCount = 0;
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
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "alarm_setting_changed",
      title: enabled ? "Đã bật Alarm" : "Đã tắt Alarm",
      message: enabled
          ? "Bạn đã bật Alarm cho nhà này."
          : "Bạn đã tắt Alarm cho nhà này.",
      homeId: homeId,
    );
  }
  int pairingCountdown = 0;
  Timer? timer;
  final ScrollController homeTabController = ScrollController();
  String formatAlarmSchedules() {
    final devices = getDevices();

    final securityDevices = devices.values.where((item) {
      final d = safeMap(item);
      final type = d["type"]?.toString();

      return type == "door" || type == "door_lock" || type == "motion";
    }).toList();

    final enabled = securityDevices.where((item) {
      final d = safeMap(item);
      final alarm = safeMap(d["alarm"]);

      return alarm["enabled"] == true;
    }).toList();

    if (enabled.isEmpty) {
      return "Chưa bật";
    }

    if (enabled.length == 1) {
      final d = safeMap(enabled.first);
      final alarm = safeMap(d["alarm"]);

      return "${alarm["start"] ?? "--:--"} - ${alarm["end"] ?? "--:--"}";
    }

    return "${enabled.length} thiết bị alarm";
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

            setState(() {
              homeOrder = HomeStateParser.parseHomeOrder(
                account: map,
                homesData: homesData,
                sharedHomes: sharedHomes,
                selectedHome: selectedHome,
              );

              if (homeOrder.isNotEmpty && !homeOrder.contains(selectedHome)) {
                selectedHome = homeOrder.first;
              }
            });
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
    });ChatService.chatStream().listen((event) {
      FirebaseDatabase.instance
          .ref("accounts/$uid/notifications")
          .onValue
          .listen((event) {
        final data = event.snapshot.value;

        int count = 0;

        if (data is Map) {
          final map = Map<String, dynamic>.from(data);

          for (final item in map.values) {
            final n = Map<String, dynamic>.from(item as Map);

            if (n["read"] != true) {
              count++;
            }
          }
        }

        if (!mounted) return;

        setState(() {
          unreadHomeNotificationCount = count;
        });
      });
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
  Future<void> handleScannedQR(String code) async {
    final value = code.trim();
    if (value.startsWith("safehome_join_multi|")) {
      final parts = value.split("|");

      if (parts.length != 3) {
        showTopToast(
          context,
          "QR gia nhập nhiều nhà không hợp lệ",
          color: Colors.red,
          icon: Icons.qr_code_scanner_rounded,
        );
        return;
      }

      final ownerUid = parts[1];
      final homeIds = parts[2]
          .split(",")
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (ownerUid == uid) {
        showTopToast(
          context,
          "Bạn đang là chủ các nhà này",
          color: Colors.orange,
          icon: Icons.home_rounded,
        );
        return;
      }

      final myEmail = FirebaseAuth.instance.currentUser?.email
          ?.trim()
          .toLowerCase();

      final targetData = await ShareService.loadAccount(uid);

      for (final homeId in homeIds) {
        await FirebaseDatabase.instance
            .ref("accounts/$ownerUid/shareRequests/${homeId}_$uid")
            .set({
          "homeId": homeId,
          "ownerUid": ownerUid,
          "targetUid": uid,
          "targetEmail": myEmail ?? "",
          "targetName": targetData["name"] ?? "",
          "targetPhone": targetData["phone"] ?? "",
          "type": "join_request",
          "time": DateTime.now().millisecondsSinceEpoch,
        });
        await HomeNotificationService.addNotification(
          uid: ownerUid,
          type: "join_request",
          title: "Yêu cầu gia nhập nhà",
          message:
          "${myEmail ?? "Một người dùng"} đang xin gia nhập một trong các nhà của bạn.",
          homeId: homeId,
        );
      }

      showTopToast(
        context,
        "Đã gửi yêu cầu gia nhập ${homeIds.length} nhà",
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );

      return;
    }
    if (value.startsWith("safehome_join|")) {
      final parts = value.split("|");

      if (parts.length != 3) {
        showTopToast(
          context,
          "QR gia nhập không hợp lệ",
          color: Colors.red,
          icon: Icons.qr_code_rounded,
        );
        return;
      }

      final ownerUid = parts[1];
      final homeId = parts[2];

      if (ownerUid == uid) {
        showTopToast(
          context,
          "Bạn đang là chủ nhà này",
          color: Colors.orange,
          icon: Icons.info_outline_rounded,
        );
        return;
      }

      final myEmail = FirebaseAuth.instance.currentUser?.email
          ?.trim()
          .toLowerCase();

      final targetData = await ShareService.loadAccount(uid);

      await FirebaseDatabase.instance
          .ref("accounts/$ownerUid/shareRequests/${homeId}_$uid")
          .set({
        "homeId": homeId,
        "ownerUid": ownerUid,
        "targetUid": uid,
        "targetEmail": myEmail ?? "",
        "targetName": targetData["name"] ?? "",
        "targetPhone": targetData["phone"] ?? "",
        "type": "join_request",
        "time": DateTime.now().millisecondsSinceEpoch,
      });
      await HomeNotificationService.addNotification(
        uid: ownerUid,
        type: "join_request",
        title: "Yêu cầu gia nhập nhà",
        message:
        "${myEmail ?? "Một người dùng"} đang xin gia nhập nhà \"$homeId\".",
        homeId: homeId,
      );
      showTopToast(
        context,
        "Đã gửi yêu cầu gia nhập nhà",
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );

      return;
    }

    pairSensor(value);
  }
  void pairSensor(String hubId) async {
    // 🔥 FIX: khai báo ownerUid đúng cách
    final ownerUid = getHomeOwnerUid();

    final requestId =
        "${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 4)}";

    await FirebaseDatabase.instance.ref(FirebasePaths.pairRequest(requestId)).set({      "active": true,
      "hubId": hubId.trim(),
      "homeId": selectedHome,
      "ownerUid": ownerUid, // ✔ giờ không lỗi nữa
      "requestedBy": uid,
      "duration": 60,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "pair_started",
      title: "Đã mở chế độ thêm thiết bị",
      message: "Bạn đã mở chế độ thêm thiết bị trong 60 giây.",
      homeId: selectedHome,
    );
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

      await ShareService.leaveSharedHome(
        uid: uid,
        ownerUid: "",
        homeId: leavingHomeId,
      );

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
                showTopToast(
                  context,
                  "Sai mật khẩu",
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                );
              }
            },

            child: Text("DELETE"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final deletedHomeId = selectedHome;
    final deletedHomeName =
        homes[deletedHomeId]?["name"]?.toString() ?? deletedHomeId;

    await ShareService.deleteOwnedHome(
      ownerUid: uid,
      homeId: deletedHomeId,
    );

    await HomeNotificationService.addNotification(
      uid: uid,
      type: "home_deleted",
      title: "Đã xoá nhà",
      message: "Bạn đã xoá nhà \"$deletedHomeName\".",
      homeId: deletedHomeId,
    );

    homeOrder.remove(deletedHomeId);

    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
        .set(homeOrder);
  }
  void shareHome() async {
    final controller = TextEditingController();
    final qrData = "safehome_join|$uid|$selectedHome";

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
                const Text(
                  "Chia sẻ nhà",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "Email người nhận",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  "Hoặc quét QR để xin gia nhập nhà",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180,
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        controller.text.trim().toLowerCase(),
                      );
                    },
                    child: const Text("Gửi lời mời"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (targetEmail == null || targetEmail.isEmpty) return;
    final myEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();

    if (targetEmail == myEmail) {
      showTopToast(
        context,
        "Không thể share cho chính bạn",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }


    final targetUid = await ShareService.findUidByEmail(targetEmail);

    if (targetUid == null) {
      showTopToast(
        context,
        "Email chưa đăng ký",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final targetData = await ShareService.loadAccount(targetUid);

    await ShareService.sendShareRequest(
      ownerUid: uid,
      targetUid: targetUid,
      homeId: selectedHome,
      ownerEmail: myEmail ?? "",
      targetData: targetData,
      targetEmail: targetEmail,
    );
    await HomeNotificationService.addNotification(
      uid: targetUid,
      type: "share_request",
      title: "Lời mời chia sẻ nhà",
      message:
      "${userName.isNotEmpty ? userName : (myEmail ?? "Một chủ nhà")} đã mời bạn tham gia nhà \"${homes[selectedHome]?["name"] ?? selectedHome}\".",
      homeId: selectedHome,
    );
    showTopToast(
      context,
      "Đã share home",
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );
  }
  void transferOwner() async {
    final controller = TextEditingController();
    final passwordController = TextEditingController();
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Chuyển quyền chủ nhà",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 18),
                const SizedBox(height: 12),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mật khẩu tài khoản",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "Email chủ nhà mới",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text("Tiếp tục"),
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
    final myEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();
    if (targetEmail == myEmail) {
      showTopToast(
        context,
        "Không thể chuyển quyền cho chính bạn",
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }
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
      showTopToast(
        context,
        "Không tìm thấy user",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // ===== 2. CONFIRM =====
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 46,
                ),

                const SizedBox(height: 12),

                const Text(
                  "Xác nhận chuyển quyền",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n$targetEmail ?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Hủy"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Chuyển"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok != true) return;
    final user = FirebaseAuth.instance.currentUser!;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      showTopToast(
        context,
        "Sai mật khẩu",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    final homeId = selectedHome;

    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/shareRequests/transfer_${homeId}_$uid")
        .set({
      "type": "transfer_owner_request",
      "homeId": homeId,
      "oldOwnerUid": uid,
      "newOwnerUid": targetUid,
      "ownerEmail": myEmail ?? "",
      "targetEmail": targetEmail,
      "homeName": homes[homeId]?["name"]?.toString() ?? homeId,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
    await HomeNotificationService.addNotification(
      uid: targetUid,
      type: "transfer_owner_request",
      title: "Yêu cầu chuyển quyền chủ nhà",
      message:
      "${userName.isNotEmpty ? userName : (myEmail ?? "Một chủ nhà")} muốn chuyển quyền chủ nhà \"${homes[homeId]?["name"] ?? homeId}\" cho bạn.",
      homeId: homeId,
    );
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "transfer_owner_request",
      title: "Đã gửi yêu cầu chuyển quyền",
      message:
      "Bạn đã gửi yêu cầu chuyển quyền chủ nhà cho $targetEmail.",
      homeId: homeId,
    );
    showTopToast(
      context,
      "Đã gửi yêu cầu chuyển quyền chủ nhà",
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );

    return;
      }
  void deleteDevice(String id) async {
    if (!await showConfirmDialog(context, "Xóa Device?")) return;

    final ownerUid = getHomeOwnerUid();
    final deviceName =
        getDevices()[id]?["name"]?.toString() ?? id;
    await HomeService.deleteDevice(
      ownerUid: ownerUid,
      homeId: selectedHome,
      deviceId: id,
    );
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "device_deleted",
      title: "Đã xoá thiết bị",
      message: "Bạn đã xoá thiết bị \"$deviceName\".",
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
              decoration: InputDecoration(
                labelText: "Tên nhà",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Địa chỉ",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
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

    final rawName = result["name"] ?? "";
    final address = result["address"] ?? "";

    if (rawName.trim().isEmpty) return;

    String makeUniqueHomeName(String baseName) {
      final existingNames = homes.values
          .map((h) => safeMap(h)["name"]?.toString().trim())
          .where((n) => n != null && n.isNotEmpty)
          .cast<String>()
          .toSet();

      if (!existingNames.contains(baseName)) {
        return baseName;
      }

      int index = 1;
      while (existingNames.contains("$baseName.$index")) {
        index++;
      }

      return "$baseName.$index";
    }

    final name = makeUniqueHomeName(rawName.trim());

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
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "home_created",
      title: "Đã tạo nhà mới",
      message: "Bạn đã tạo nhà \"$name\".",
      homeId: id,
    );
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
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "home_renamed",
      title: "Đã đổi tên nhà",
      message: "Bạn đã đổi tên nhà thành \"$name\".",
      homeId: selectedHome,
    );
  }

  void renameDevice(String id) async {
    if (homes[selectedHome]?["_shared"] == true) {
      showTopToast(
        context,
        "Home được share chỉ có quyền xem",
        color: Colors.orange,
        icon: Icons.lock_rounded,
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
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "device_renamed",
      title: "Đã đổi tên thiết bị",
      message: "Bạn đã đổi tên thiết bị thành \"$name\".",
      homeId: selectedHome,
      deviceId: id,
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
      extendBody: true,
      backgroundColor: Colors.transparent,
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
                          final item = homeOrder.removeAt(oldIndex);

                          if (newIndex > homeOrder.length) {
                            newIndex = homeOrder.length;
                          }

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
                                builder: (_) => AlarmDeviceSheet(
                                  ownerUid: getHomeOwnerUid(),
                                  homeId: selectedHome,
                                  devices: getDevices(),
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
                      onPairSensor: () async {
                        if (!canManageHome()) {
                          showTopToast(
                            context,
                            "Bạn không có quyền thêm thiết bị",
                            color: Colors.orange,
                            icon: Icons.lock_rounded,
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
                                      "Quét QR",
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
                                        label: const Text(
                                          "Quét QR để thêm thiết bị hoặc xin gia nhập",
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context, "__SCAN__");
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      icon: const Icon(Icons.keyboard),
                                      label: const Text("Nhập HUB ID thủ công"),
                                      onPressed: () {
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
                            await handleScannedQR(code);
                          }
                        }

                        if (result == "__MANUAL__") {
                          final hubId = await showPairDialog(context);

                          if (hubId == null || hubId.trim().isEmpty) return;

                          pairSensor(hubId.trim());
                        }
                      },
                      onTapDevice: (id) {
                        showDeviceDetail(
                          context: context,
                          id: id,
                          d: safeMap(getDevices()[id]),
                          onRename: canManageHome()
                              ? () => renameDevice(id)
                              : null,
                          onDelete: canManageHome()
                              ? () => deleteDevice(id)
                              : null,
                          onNotification: () => openNotificationList(id),
                        );
                      },
                    ),


                  ],
                ),
              ),
            ],
          ),
        ),
      ),


      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(top: 22),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [


                IconButton(
                  icon: const Icon(Icons.add_home),
                  onPressed: addHome,
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded),
                      onPressed: () {
                        showHomeEventSheet(
                          context: context,
                          uid: uid,
                        );
                      },
                    ),

                    if (unreadHomeNotificationCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadHomeNotificationCount > 99
                                ? "99+"
                                : unreadHomeNotificationCount.toString(),
                            textAlign: TextAlign.center,
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
                          role: getMyRole(),
                          onAllDevices: () {
                            final devices = getDevices();

                            if (devices.isEmpty) {
                              showTopToast(
                                context,
                                "Không có thiết bị",
                                color: Colors.orange,
                                icon: Icons.sensors_off_rounded,
                              );
                              return;
                            }

                            if (devices.length == 1) {
                              final entry = devices.entries.first;

                              Navigator.pop(context);

                              showDeviceDetail(
                                context: context,
                                id: entry.key,
                                d: safeMap(entry.value),
                                onRename: canManageHome()
                                    ? () => renameDevice(entry.key)
                                    : null,
                                onDelete: canManageHome()
                                    ? () => deleteDevice(entry.key)
                                    : null,
                                onNotification: () => openNotificationList(entry.key),
                              );

                              return;
                            }

                            showAllDevicesSheet(
                              context: context,
                              devices: devices,
                              onTapDevice: (id) {
                                showDeviceDetail(
                                  context: context,
                                  id: id,
                                  d: safeMap(getDevices()[id]),
                                  onRename: canManageHome()
                                      ? () => renameDevice(id)
                                      : null,
                                  onDelete: canManageHome()
                                      ? () => deleteDevice(id)
                                      : null,
                                  onNotification: () => openNotificationList(id),
                                );
                              },
                            );
                          },
                          onAccount: () {
                            AccountAvatarSheet.show(
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
                              inviteCount: shareRequests.length,

                              onShareRequests: () {
                                showShareRequestSheet(
                                  context: context,
                                  requests: shareRequests,
                                  uid: uid,
                                );
                              },
                            );
                          },
                          onDeleteHome: isOwner() ? deleteHome : () {
                            showTopToast(
                              context,
                              "Chỉ chủ nhà mới được xoá nhà",
                              color: Colors.orange,
                              icon: Icons.lock_rounded,
                            );
                          },
                          onRenameHome: canManageHome() ? renameHome : () {
                            showTopToast(
                              context,
                              "Bạn không có quyền sửa tên nhà",
                              color: Colors.orange,
                              icon: Icons.lock_rounded,
                            );
                          },
                          onTransferOwner: isOwner() ? transferOwner : () {
                            showTopToast(
                              context,
                              "Chỉ chủ nhà mới được chuyển quyền",
                              color: Colors.orange,
                              icon: Icons.admin_panel_settings_rounded,
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
                            showTopToast(
                              context,
                              "Bạn không có quyền chia sẻ nhà",
                              color: Colors.orange,
                              icon: Icons.lock_rounded,
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
                        right: 2,
                        top: 2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${shareRequests.length}",
                            textAlign: TextAlign.center,
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