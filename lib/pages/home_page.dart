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
import '../services/auto_login_service.dart';
import '../sheets/room_management_sheet.dart';
import '../widgets/room_tabs.dart';
import '../safehome_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> shareRequests = {};
  final ValueNotifier<int> inviteCountNotifier = ValueNotifier(0);
  int unreadChatCount = 0;
  Map<String, int> unreadChatByHome = {};
  int unreadHomeNotificationCount = 0;
  Map<String, String>? _pendingChatOpenRequest;
  bool _openingChatFromNotification = false;
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

  String getSelectedHomeDisplayName() {
    return getHomeDisplayName(selectedHome);
  }

  String getHomeDisplayName(String homeId) {
    final home = safeMap(homes[homeId]);
    final rawName = home["_customName"] ?? home["name"] ?? "";
    final name = rawName.toString().trim();

    return name.isNotEmpty ? name : "Nhà chưa đặt tên";
  }

  void selectHomeFromNotification(String homeId) {
    if (homeId.isEmpty || !homes.containsKey(homeId)) return;

    final currentHome = safeMap(homes[homeId]);
    final parsedAlarm = HomeStateParser.parseAlarm(currentHome);

    setState(() {
      selectedHome = homeId;
      alarmEnabled = safeMap(alarmSettings[homeId])["enabled"] != false;
      start = parsedAlarm["start"];
      end = parsedAlarm["end"];
      alarmPauseToday = safeMap(currentHome["alarmPauseToday"]);
    });

    final index = homeOrder.indexOf(homeId);

    if (index != -1 && homeTabController.hasClients) {
      homeTabController.animateTo(
        index * 110,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }

    startHomeEventsListener();
  }

  void openDeviceFromNotification(String deviceId) {
    final devices = getDevices();
    final device = safeMap(devices[deviceId]);

    if (device.isEmpty) {
      showTopToast(
        context,
        "Không tìm thấy thiết bị trong nhà này",
        color: Colors.orange,
        icon: Icons.sensors_off_rounded,
      );
      return;
    }

    showDeviceDetail(
      context: context,
      id: deviceId,
      d: device,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      onRename: canManageHome() ? () => renameDevice(deviceId) : null,
      onDelete: canManageHome() ? () => deleteDevice(deviceId) : null,
      onNotification: () => openNotificationList(deviceId),
    );
  }

  void _handleChatOpenRequest() {
    final request = NotificationService.chatOpenRequest.value;

    if (request == null) return;

    _pendingChatOpenRequest =
    Map<String, String>.from(request);

    unawaited(_tryOpenPendingChat());
  }

  Future<void> _tryOpenPendingChat() async {
    if (!mounted || _openingChatFromNotification) {
      return;
    }

    final request = _pendingChatOpenRequest;

    if (request == null) return;

    final homeId = request["homeId"]?.trim() ?? "";

    if (homeId.isEmpty || !homes.containsKey(homeId)) {
      return;
    }

    _openingChatFromNotification = true;
    _pendingChatOpenRequest = null;
    NotificationService.chatOpenRequest.value = null;

    selectHomeFromNotification(homeId);

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted ||
        selectedHome != homeId ||
        !homes.containsKey(homeId)) {
      _openingChatFromNotification = false;
      return;
    }

    showHomeChatSheet(
      context: context,
      homeId: homeId,
      homeName: getHomeDisplayName(homeId),
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      ownerUid: getHomeOwnerUid(),
      canManageMembers: canManageHome(),
      isOwner: isOwner(),
    );

    _openingChatFromNotification = false;
  }

  Future<void> openHomeNotificationTarget(
      Map<String, dynamic> notification,
      ) async {
    final homeId = notification["homeId"]?.toString() ?? "";

    if (homeId.isEmpty || !homes.containsKey(homeId)) {
      showTopToast(
        context,
        "Không tìm thấy nhà của thông báo này",
        color: Colors.orange,
        icon: Icons.home_work_outlined,
      );
      return;
    }

    selectHomeFromNotification(homeId);

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    final type = notification["type"]?.toString() ?? "";
    final entityType = notification["entityType"]?.toString() ?? "";
    final deviceId = notification["deviceId"]?.toString().isNotEmpty == true
        ? notification["deviceId"].toString()
        : entityType == "device"
        ? notification["entityId"]?.toString() ?? ""
        : "";

    if (type == "chat" || entityType == "chat") {
      showHomeChatSheet(
        context: context,
        homeId: selectedHome,
        homeName: getSelectedHomeDisplayName(),
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        ownerUid: getHomeOwnerUid(),
        canManageMembers: canManageHome(),
        isOwner: isOwner(),
      );
      return;
    }

    if (deviceId.isNotEmpty) {
      openDeviceFromNotification(deviceId);
    }
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
  String selectedRoomId = "overview";
  Map<String, dynamic> alarmSettings = {};
  Map<String, dynamic> homeEvents = {};

  Map<String, dynamic> alarmPauseToday = {};
  final Map<String, Map<String, Map<String, dynamic>>>
  _deviceNotificationSnapshots = {};
  final Set<String> _deviceNotificationPrimedHomes = {};
  List<String> homeOrder = [];

  List<String> mergeVisibleHomeOrder(List<String> visibleOrder) {
    final visibleIds = visibleOrder.toSet();
    final nextOrder = <String>[];
    final seen = <String>{};
    var visibleIndex = 0;

    void addHomeId(String homeId) {
      if (seen.add(homeId)) {
        nextOrder.add(homeId);
      }
    }

    for (final homeId in homeOrder) {
      if (visibleIds.contains(homeId)) {
        if (visibleIndex < visibleOrder.length) {
          addHomeId(visibleOrder[visibleIndex]);
          visibleIndex++;
        }
      } else {
        addHomeId(homeId);
      }
    }

    while (visibleIndex < visibleOrder.length) {
      addHomeId(visibleOrder[visibleIndex]);
      visibleIndex++;
    }

    for (final homeId in homes.keys) {
      addHomeId(homeId);
    }

    return nextOrder;
  }

  Future<void> reorderHomeTabs(List<String> visibleOrder) async {
    final nextOrder = mergeVisibleHomeOrder(visibleOrder);

    setState(() {
      homeOrder = nextOrder;
    });

    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
        .set(nextOrder);
  }

  TimeOfDay start = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 6, minute: 0);

  String formatClock(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, "0");
    final minute = time.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }

  Future<String?> openTimeTextInput({
    required BuildContext context,
    required String title,
    required String initial,
  }) async {
    final parts = initial.split(":");

    final hourController = TextEditingController(text: parts[0]);

    final minuteController = TextEditingController(text: parts[1]);

    const suggestions = [
      ["23", "00"],
      ["00", "00"],
      ["01", "00"],
      ["04", "00"],
      ["05", "00"],
      ["06", "00"],
    ];

    bool isValidTime(String value) {
      final reg = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
      return reg.hasMatch(value.trim());
    }

    return showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hourController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: "Giờ",
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      ":",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: minuteController,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        labelText: "Phút",
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                children: [
                  Row(
                    children: suggestions.take(3).map((s) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ActionChip(
                              label: Center(child: Text("${s[0]}:${s[1]}")),
                              onPressed: () {
                                hourController.text = s[0];
                                minuteController.text = s[1];
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: suggestions.skip(3).map((s) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ActionChip(
                              label: Center(child: Text("${s[0]}:${s[1]}")),
                              onPressed: () {
                                hourController.text = s[0];
                                minuteController.text = s[1];
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () {
                final h = hourController.text.trim().padLeft(2, '0');
                final m = minuteController.text.trim().padLeft(2, '0');
                final value = "$h:$m";

                if (!isValidTime(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Giờ không hợp lệ"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Map<String, String> getHomeAlarmReminderInfo() {
    final devices = getDevices();

    for (final item in devices.values) {
      final device = safeMap(item);
      final alarm = safeMap(device["alarm"]);

      if (alarm["enabled"] == true) {
        return {
          "mode": "Theo nhà",
          "start": alarm["start"]?.toString() ?? "23:00",
          "end": alarm["end"]?.toString() ?? "06:00",
        };
      }
    }

    return {
      "mode": "Theo nhà",
      "start": formatClock(start),
      "end": formatClock(end),
    };
  }

  Future<void> showAlarmReceiveReminder() async {
    final info = getHomeAlarmReminderInfo();

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Lưu ý nhận cảnh báo Alarm"),
          content: Text(
            "Cảnh báo đang được cài đặt \"${info["mode"]}\" từ "
                "${info["start"]} → ${info["end"]}.\n\n"
                "Hãy kiểm tra kĩ để tránh cảnh báo làm phiền bạn.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đã hiểu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showAlarmPauseReminder() async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Lưu ý tạm tắt Alarm"),
          content: const Text(
            "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị "
                "trong hôm nay, reminder sẽ được báo đến các thành viên khác "
                "trong nhà. Khoảng tời gian tạm hoãn phải nằm trong khoảng thời gian đã được cài đặt của Alarm",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đã hiểu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> openAlarmPauseSheetWithReminder() async {
    await showAlarmPauseReminder();

    if (!mounted) return;

    showAlarmPauseSheet();
  }

  bool alarmEnabled = false;
  Future<void> setAlarmEnabled(bool enabled) async {
    final homeId = selectedHome;
    final homeName = getHomeDisplayName(homeId);

    setState(() {
      alarmEnabled = enabled;
      alarmSettings[homeId] = {"enabled": enabled};
    });

    await FirebaseDatabase.instance
        .ref("accounts/$uid/alarmSettings/$homeId/enabled")
        .set(enabled);
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "alarm_setting_changed",
      title: enabled ? "Đã bật Alarm" : "Đã tắt Alarm",
      message: enabled
          ? "Bạn đã bật Alarm cho nhà \"$homeName\"."
          : "Bạn đã tắt Alarm cho nhà \"$homeName\".",
      homeId: homeId,
      homeName: homeName,
    );
  }

  int pairingCountdown = 0;
  Timer? timer;
  final ScrollController homeTabController = ScrollController();
  StreamSubscription<DatabaseEvent>? accountSubscription;
  StreamSubscription<DatabaseEvent>? notificationSubscription;
  StreamSubscription<DatabaseEvent>? homeEventsSubscription;
  String _homeEventsListenKey = "";
  final Map<String, StreamSubscription<DatabaseEvent>> homeChatSubscriptions =
  {};

  void startNotificationListener() {
    notificationSubscription?.cancel();
    notificationSubscription = FirebaseDatabase.instance
        .ref("accounts/$uid/notifications")
        .onValue
        .listen((event) {
      final data = event.snapshot.value;
      var count = 0;

      if (data is Map) {
        final map = Map<String, dynamic>.from(data);

        for (final item in map.values) {
          if (item is! Map) continue;

          final notification = Map<String, dynamic>.from(item);

          if (notification["read"] != true) {
            count++;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        unreadHomeNotificationCount = count;
      });
    });
  }

  void startHomeEventsListener() {
    if (selectedHome.isEmpty) {
      homeEventsSubscription?.cancel();
      homeEventsSubscription = null;
      _homeEventsListenKey = "";
      return;
    }

    final ownerUid = getHomeOwnerUid();
    final listenKey = "$ownerUid/$selectedHome";

    if (_homeEventsListenKey == listenKey && homeEventsSubscription != null) {
      return;
    }

    homeEventsSubscription?.cancel();
    _homeEventsListenKey = listenKey;

    homeEventsSubscription = FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$selectedHome/events")
        .limitToLast(50)
        .onValue
        .listen((event) {
      if (!mounted) return;

      setState(() {
        homeEvents = safeMap(event.snapshot.value);
      });
    });
  }

  void syncHomeChatListeners() {
    if (!mounted) return;

    final activeHomeIds = homes.keys.where((id) => id.isNotEmpty).toSet();
    final removedHomeIds = homeChatSubscriptions.keys
        .where((homeId) => !activeHomeIds.contains(homeId))
        .toList();
    var changedUnread = false;

    for (final homeId in removedHomeIds) {
      homeChatSubscriptions.remove(homeId)?.cancel();
      changedUnread = unreadChatByHome.remove(homeId) != null || changedUnread;
    }

    for (final homeId in activeHomeIds) {
      if (homeChatSubscriptions.containsKey(homeId)) continue;

      homeChatSubscriptions[homeId] = ChatService.homeChatStream(homeId).listen(
            (event) {
          final unread = ChatService.unreadCount(
            homeChat: event.snapshot.value,
            uid: uid,
          );

          if (!mounted) return;

          setState(() {
            if (unread > 0) {
              unreadChatByHome[homeId] = unread;
            } else {
              unreadChatByHome.remove(homeId);
            }

            unreadChatCount = unreadChatByHome.values.fold<int>(
              0,
                  (total, count) => total + count,
            );
          });
        },
        onError: (_) {
          if (!mounted) return;

          setState(() {
            unreadChatByHome.remove(homeId);
            unreadChatCount = unreadChatByHome.values.fold<int>(
              0,
                  (total, count) => total + count,
            );
          });
        },
      );
    }

    if (changedUnread) {
      setState(() {
        unreadChatCount = unreadChatByHome.values.fold<int>(
          0,
              (total, count) => total + count,
        );
      });
    }
  }

  void syncDeviceNotificationBridge() {
    if (!mounted) return;

    final activeHomeIds = homes.keys.where((id) => id.isNotEmpty).toSet();

    _deviceNotificationSnapshots.removeWhere(
          (homeId, _) => !activeHomeIds.contains(homeId),
    );
    _deviceNotificationPrimedHomes.removeWhere(
          (homeId) => !activeHomeIds.contains(homeId),
    );

    for (final homeEntry in homes.entries) {
      final homeId = homeEntry.key.toString();
      final home = safeMap(homeEntry.value);
      final devices = safeMap(home["devices"]);
      final previousByDevice = _deviceNotificationSnapshots.putIfAbsent(
        homeId,
            () => <String, Map<String, dynamic>>{},
      );
      final homeWasPrimed = _deviceNotificationPrimedHomes.contains(homeId);
      final homeName = getHomeDisplayName(homeId);

      previousByDevice.removeWhere(
            (deviceId, _) => !devices.containsKey(deviceId),
      );

      for (final deviceEntry in devices.entries) {
        final deviceId = deviceEntry.key.toString();
        final device = safeMap(deviceEntry.value);
        final currentState = _deviceNotificationState(device);
        final previousState = previousByDevice[deviceId];

        previousByDevice[deviceId] = currentState;

        if (previousState == null) {
          if (homeWasPrimed) {
            _recordDeviceNotification(
              homeId: homeId,
              homeName: homeName,
              deviceId: deviceId,
              device: device,
              event: {
                "type": "device_added",
                "title": "Thiết bị mới",
                "message":
                "Thiết bị \"${_deviceName(deviceId, device)}\" đã xuất hiện trong \"$homeName\".",
                "severity": "info",
              },
            );
          }

          continue;
        }

        final event = _deviceNotificationEvent(
          homeName: homeName,
          deviceId: deviceId,
          device: device,
          previous: previousState,
          current: currentState,
        );

        if (event == null) continue;

        _recordDeviceNotification(
          homeId: homeId,
          homeName: homeName,
          deviceId: deviceId,
          device: device,
          event: event,
        );
      }

      _deviceNotificationPrimedHomes.add(homeId);
    }
  }

  Map<String, dynamic> _deviceNotificationState(Map<String, dynamic> device) {
    final battery = int.tryParse(device["battery"]?.toString() ?? "");
    final temperature = double.tryParse(
      device["temperature"]?.toString() ?? "",
    );
    final humidity = double.tryParse(device["humidity"]?.toString() ?? "");

    return {
      "availability": device["availability"]?.toString().toLowerCase() ?? "",
      "contact": device["contact"],
      "smoke": device["smoke"] == true,
      "tamper": device["tamper"] == true,
      "status": device["status"]?.toString() ?? "",
      "batteryLow": battery != null && battery <= 20,
      "sosActive": isSosActive(device),
      "temperatureHigh": temperature != null && temperature >= 34,
      "humidityHigh": humidity != null && humidity >= 80,
    };
  }

  Map<String, String>? _deviceNotificationEvent({
    required String homeName,
    required String deviceId,
    required Map<String, dynamic> device,
    required Map<String, dynamic> previous,
    required Map<String, dynamic> current,
  }) {
    final type = device["type"]?.toString() ?? "door";
    final name = _deviceName(deviceId, device);

    bool changed(String key) => previous[key] != current[key];

    if (changed("smoke")) {
      final active = current["smoke"] == true;
      return {
        "type": active ? "device_smoke" : "device_smoke_clear",
        "title": active ? "Cảnh báo khói" : "Khói đã an toàn",
        "message": active
            ? "\"$name\" phát hiện khói trong \"$homeName\"."
            : "\"$name\" đã trở lại trạng thái bình thường.",
        "severity": active ? "critical" : "success",
      };
    }

    if (changed("sosActive")) {
      final active = current["sosActive"] == true;
      return {
        "type": active ? "device_sos" : "device_sos_clear",
        "title": active ? "SOS được kích hoạt" : "SOS đã kết thúc",
        "message": active
            ? "\"$name\" vừa kích hoạt SOS trong \"$homeName\"."
            : "\"$name\" đã hết trạng thái SOS.",
        "severity": active ? "critical" : "success",
      };
    }

    if (changed("tamper")) {
      final active = current["tamper"] == true;
      return {
        "type": active ? "device_tamper" : "device_tamper_clear",
        "title": active ? "Thiết bị bị tháo" : "Tamper bình thường",
        "message": active
            ? "\"$name\" báo bị tháo/cạy trong \"$homeName\"."
            : "\"$name\" đã hết cảnh báo tháo/cạy.",
        "severity": active ? "critical" : "success",
      };
    }

    if (_isContactDevice(type) && changed("contact")) {
      final closed = current["contact"] == true;
      return {
        "type": "device_contact",
        "title": closed ? "Cửa đã đóng" : "Cửa đang mở",
        "message": closed
            ? "\"$name\" đã đóng trong \"$homeName\"."
            : "\"$name\" đang mở trong \"$homeName\".",
        "severity": closed ? "success" : "warning",
      };
    }

    if (previous["batteryLow"] != true && current["batteryLow"] == true) {
      return {
        "type": "device_battery_low",
        "title": "Pin yếu",
        "message": "\"$name\" trong \"$homeName\" đang yếu pin.",
        "severity": "warning",
      };
    }

    if (changed("availability")) {
      final availability = current["availability"]?.toString() ?? "";
      if (availability == "offline") {
        return {
          "type": "device_connection",
          "title": "Thiết bị offline",
          "message": "\"$name\" trong \"$homeName\" đã mất kết nối.",
          "severity": "warning",
        };
      }

      if (availability == "online") {
        return {
          "type": "device_connection",
          "title": "Thiết bị online",
          "message": "\"$name\" trong \"$homeName\" đã kết nối trở lại.",
          "severity": "success",
        };
      }
    }

    if (previous["temperatureHigh"] != true &&
        current["temperatureHigh"] == true) {
      return {
        "type": "device_environment",
        "title": "Nhiệt độ cao",
        "message": "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
        "severity": "warning",
      };
    }

    if (previous["humidityHigh"] != true && current["humidityHigh"] == true) {
      return {
        "type": "device_environment",
        "title": "Độ ẩm cao",
        "message": "\"$name\" ghi nhận độ ẩm cao trong \"$homeName\".",
        "severity": "warning",
      };
    }

    return null;
  }

  void _recordDeviceNotification({
    required String homeId,
    required String homeName,
    required String deviceId,
    required Map<String, dynamic> device,
    required Map<String, String> event,
  }) {
    unawaited(
      HomeNotificationService.addNotification(
        uid: uid,
        type: event["type"] ?? "device_event",
        category: "device",
        severity: event["severity"] ?? "info",
        title: event["title"] ?? "Cập nhật thiết bị",
        message: event["message"] ?? "",
        homeId: homeId,
        deviceId: deviceId,
        entityType: "device",
        entityId: deviceId,
        homeName: homeName,
        data: {
          "homeName": homeName,
          "deviceName": _deviceName(deviceId, device),
          "deviceType": device["type"]?.toString() ?? "",
        },
      ).catchError((_) {}),
    );
  }

  bool _isContactDevice(String type) {
    return type == "door" ||
        type == "window" ||
        type == "gate" ||
        type == "lock";
  }

  String _deviceName(String deviceId, Map<String, dynamic> device) {
    final name = device["name"]?.toString().trim() ?? "";
    return name.isNotEmpty ? name : deviceId;
  }

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

  Map<String, dynamic> getRooms() {
    final homeData = safeMap(homes[selectedHome]);
    return safeMap(homeData["rooms"]);
  }

  Map<String, dynamic>? getTemperatureDevice() {
    final devices = getDevices();

    for (final entry in devices.entries) {
      final d = safeMap(entry.value);

      if (d["type"] == "temperature") {
        return {"id": entry.key, "data": d};
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

  Future<Map<String, dynamic>> loadVisibleShareRequests({
    Map<String, dynamic>? accountData,
  }) async {
    final account = accountData ?? safeMap((await ref.get()).value);
    return safeMap(account["shareRequests"]);
  }
  Future<void> syncMyPhoneToVisibleHomes({
    required Map<String, dynamic> ownedHomes,
    required Map<String, dynamic> sharedHomes,
    required String phone,
  }) async {
    final homeIds = <String>{
      ...ownedHomes.keys.map((key) => key.toString()),
      ...sharedHomes.keys.map((key) => key.toString()),
    };

    if (homeIds.isEmpty) {
      return;
    }

    final cleanPhone = phone.trim();
    final updates = <String, Object?>{};

    for (final rawHomeId in homeIds) {
      final homeId = rawHomeId.trim();

      if (homeId.isEmpty) {
        continue;
      }

      updates[
      "homeMemberContacts/$homeId/$uid/phone"
      ] = cleanPhone;
    }

    if (updates.isEmpty) {
      return;
    }

    try {
      await FirebaseDatabase.instance
          .ref()
          .update(updates);
    } catch (error) {
      debugPrint(
        "SYNC_HOME_MEMBER_CONTACT_ERROR: $error",
      );
    }
  }
  Future<void> refreshShareRequests() async {
    final requests = await loadVisibleShareRequests();

    if (!mounted) return;

    setState(() {
      shareRequests = requests;
      inviteCountNotifier.value = requests.length;
    });
  }

  @override
  void initState() {
    super.initState();

    uid = FirebaseAuth.instance.currentUser!.uid;

    NotificationService.chatOpenRequest.addListener(
      _handleChatOpenRequest,
    );
    _handleChatOpenRequest();

    FCMService.setupFCM(uid: uid);

    FCMService.listenForeground(localNotif: localNotif);
    ref = FirebaseDatabase.instance.ref(FirebasePaths.account(uid));
    startNotificationListener();

    accountSubscription = ref.onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null) return;

      final map = safeMap(data);
      final homesData = safeMap(map["homes"]);
      final sharedHomes = safeMap(map["sharedHomes"]);
      final requests = await loadVisibleShareRequests(accountData: map);
      if (!mounted) return;

      final userAlarmSettings = safeMap(map["alarmSettings"]);
      setState(() {
        shareRequests = requests;
        inviteCountNotifier.value = requests.length;
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
          uid: uid,
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
              final currentHome = safeMap(homes[selectedHome]);
              alarmPauseToday = safeMap(currentHome["alarmPauseToday"]);
            });

            syncHomeChatListeners();
            syncDeviceNotificationBridge();
          },

          onDeleted: (homeId) {
            setState(() {
              homes.remove(homeId);

              homeOrder.remove(homeId);

              if (selectedHome == homeId) {
                selectedHome = homeOrder.isNotEmpty ? homeOrder.first : "";
              }
            });

            syncHomeChatListeners();
            _deviceNotificationSnapshots.remove(homeId);
            _deviceNotificationPrimedHomes.remove(homeId);
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
        if (selectedHome.isNotEmpty && canManageHome()) {
          unawaited(
            HomeService.ensureHomeRoomModel(
              ownerUid: getHomeOwnerUid(),
              homeId: selectedHome,
            ).catchError((Object error) {
              debugPrint("ENSURE_HOME_ROOM_MODEL_ERROR: $error");
            }),
          );
        }
        final currentHome = safeMap(homes[selectedHome]);

        alarmPauseToday = safeMap(currentHome["alarmPauseToday"]);

        final parsedAlarm = HomeStateParser.parseAlarm(currentHome);

        final userAlarmSetting = safeMap(map["alarmSettings"]?[selectedHome]);

        alarmEnabled = userAlarmSetting["enabled"] != false;
        start = parsedAlarm["start"];
        end = parsedAlarm["end"];
      });
      unawaited(
        syncMyPhoneToVisibleHomes(
          ownedHomes: homesData,
          sharedHomes: sharedHomes,
          phone: userPhone,
        ),
      );
      startHomeEventsListener();
      syncHomeChatListeners();
      syncDeviceNotificationBridge();
      unawaited(_tryOpenPendingChat());
    });
  }

  Future<void> handleScannedQR(String code) async {
    final value = code.trim();
    debugPrint("QR_DEBUG value=$value");
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
      final targetProfile = safeMap(targetData["profile"]);
      final requesterName =
      targetProfile["name"]?.toString().trim().isNotEmpty == true
          ? targetProfile["name"].toString().trim()
          : myEmail ?? "Một người dùng";

      for (final homeId in homeIds) {
        final homeName = await HomeNotificationService.resolveHomeName(
          homeId: homeId,
          ownerUid: ownerUid,
        );
        final requestKey = "${homeId}_$uid";
        final requestData = {
          "homeId": homeId,
          "homeName": homeName,
          "ownerUid": ownerUid,
          "targetUid": uid,
          "targetEmail": myEmail ?? "",
          "targetName": requesterName,
          "targetPhone": targetProfile["phone"]?.toString().trim() ?? "",
          "type": "join_request",
          "time": DateTime.now().millisecondsSinceEpoch,
        };

        final updates = <String, Object?>{
          "accounts/$ownerUid/shareRequests/$requestKey": requestData,
        };

        try {
          debugPrint("QR_JOIN_UPDATES=$updates");
          await FirebaseDatabase.instance.ref().update(updates);
          debugPrint("QR_JOIN_UPDATE_OK");
        } catch (e, st) {
          debugPrint("QR_JOIN_UPDATE_ERROR: $e");
          debugPrint("QR_JOIN_UPDATE_STACK: $st");
        }
        await HomeNotificationService.notifyHome(
          ownerUid: ownerUid,
          homeId: homeId,
          recipientUid: ownerUid,
          type: "join_request",
          title: "Yêu cầu gia nhập nhà",
          message: "$requesterName đang xin gia nhập nhà \"$homeName\".",
          homeName: homeName,
          category: "member",
          severity: "info",
          entityType: "member",
          entityId: uid,
          includeActor: false,
          writeHomeTimeline: false,
        );
      }

      if (!mounted) return;

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
      final targetProfile = safeMap(targetData["profile"]);
      final requesterName =
      targetProfile["name"]?.toString().trim().isNotEmpty == true
          ? targetProfile["name"].toString().trim()
          : myEmail ?? "Một người dùng";

      final requestKey = "${homeId}_$uid";
      final homeName = await HomeNotificationService.resolveHomeName(
        homeId: homeId,
        ownerUid: ownerUid,
      );

      final requestData = {
        "homeId": homeId,
        "homeName": homeName,
        "ownerUid": ownerUid,
        "targetUid": uid,
        "targetEmail": myEmail ?? "",
        "targetName": requesterName,
        "targetPhone": targetProfile["phone"]?.toString().trim() ?? "",
        "type": "join_request",
        "time": DateTime.now().millisecondsSinceEpoch,
      };

      final updates = <String, Object?>{
        "accounts/$ownerUid/shareRequests/$requestKey": requestData,
      };

      await FirebaseDatabase.instance.ref().update(updates);
      await HomeNotificationService.notifyHome(
        ownerUid: ownerUid,
        homeId: homeId,
        recipientUid: ownerUid,
        type: "join_request",
        title: "Yêu cầu gia nhập nhà",
        message: "$requesterName đang xin gia nhập nhà \"$homeName\".",
        homeName: homeName,
        category: "member",
        severity: "info",
        entityType: "member",
        entityId: uid,
        includeActor: false,
        writeHomeTimeline: false,
      );

      if (!mounted) return;

      showTopToast(
        context,
        "Đã gửi yêu cầu gia nhập nhà",
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );

      return;
    }

    pairSensor(value);
    showTopToast(
      context,
      "QR này không phải mã xin gia nhập nhà",
      color: Colors.red,
      icon: Icons.qr_code_2_rounded,
    );
  }

  void pairSensor(String hubId) async {
    if (!canManageHome()) {
      showTopToast(
        context,
        "Bạn không có quyền thêm thiết bị",
        color: Colors.orange,
        icon: Icons.lock_rounded,
      );
      return;
    }

    // 🔥 FIX: khai báo ownerUid đúng cách
    final ownerUid = getHomeOwnerUid();
    final homeName = getSelectedHomeDisplayName();

    final requestId =
        "${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 4)}";

    await FirebaseDatabase.instance
        .ref(FirebasePaths.pairRequest(requestId))
        .set({
      "active": true,
      "hubId": hubId.trim(),
      "homeId": selectedHome,
      "ownerUid": ownerUid,
      "requestedBy": uid,
      "roomId": selectedRoomId == "overview"
          ? "unassigned"
          : selectedRoomId,
      "duration": 60,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
    await HomeNotificationService.notifyHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      type: "pair_started",
      category: "device",
      title: "Đã mở chế độ thêm thiết bị",
      message:
      "Chế độ thêm thiết bị đã được mở trong nhà \"$homeName\" trong 60 giây.",
      homeName: homeName,
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
      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
      await Future.delayed(const Duration(milliseconds: 120));
      final leavingHomeId = selectedHome;

      await FirebaseDatabase.instance
          .ref("homeMemberContacts/$leavingHomeId/$uid")
          .remove();

      await ShareService.leaveSharedHome(
        uid: uid,
        ownerUid: "",
        homeId: leavingHomeId,
      );

      setState(() {
        homes.remove(leavingHomeId);
        homeOrder.remove(leavingHomeId);
        unreadChatByHome.remove(leavingHomeId);

        if (selectedHome == leavingHomeId) {
          selectedHome = homeOrder.isNotEmpty ? homeOrder.first : "";
        }
      });
      startHomeEventsListener();
      syncHomeChatListeners();
      return;
    }

    // ================= HOME OWN =================
    final controller = TextEditingController();

    final confirmOk = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Xác nhận xoá nhà",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Huỷ"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Tiếp tục"),
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

    if (confirmOk != true) return;
    if (!mounted) return;

    final passwordOk = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.red,
                  size: 44,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Nhập mật khẩu",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text("Xoá nhà"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser!;

                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: controller.text.trim(),
                        );

                        await user.reauthenticateWithCredential(credential);

                        if (!sheetContext.mounted) return;

                        Navigator.pop(sheetContext, true);
                      } catch (e) {
                        if (!sheetContext.mounted) return;

                        showTopToast(
                          sheetContext,
                          "Sai mật khẩu",
                          color: Colors.red,
                          icon: Icons.error_outline_rounded,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (passwordOk != true) return;

    final deletedHomeId = selectedHome;
    final deletedHomeName =
        homes[deletedHomeId]?["name"]?.toString() ?? deletedHomeId;

    await ShareService.deleteOwnedHome(ownerUid: uid, homeId: deletedHomeId);

    await HomeNotificationService.addNotification(
      uid: uid,
      type: "home_deleted",
      title: "Đã xoá nhà",
      message: "Bạn đã xoá nhà \"$deletedHomeName\".",
      homeId: deletedHomeId,
      homeName: deletedHomeName,
      entityType: "home",
      entityId: deletedHomeId,
    );

    homeOrder.remove(deletedHomeId);

    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
        .set(homeOrder);
  }

  void showJoinHomeQR() {
    final shareOwnerUid = getHomeOwnerUid();
    final qrData = "safehome_join|$shareOwnerUid|$selectedHome";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "QR của nhà này",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                QrImageView(data: qrData, version: QrVersions.auto, size: 220),
                const SizedBox(height: 12),
                const Text(
                  "Người khác quét mã này để gửi yêu cầu gia nhập nhà.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void shareHome() async {
    final controller = TextEditingController();
    final shareOwnerUid = getHomeOwnerUid();
    final qrData = "safehome_join|$shareOwnerUid|$selectedHome";

    final targetEmail = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final email = controller.text.trim().toLowerCase();
            final emailOk = RegExp(
              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
            ).hasMatch(email);

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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Chia sẻ nhà",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: "Quét QR để xin gia nhập nhà",
                          icon: const Icon(Icons.center_focus_strong_rounded),
                          onPressed: () async {
                            Navigator.pop(context, null);

                            final code = await openQRScanner(
                              context,
                              title: "Xin gia nhập nhà",
                              subtitle: "Quét mã QR chia sẻ nhà",
                            );

                            if (code != null) {
                              await handleScannedQR(code);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: "Email người nhận",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: emailOk
                            ? IconButton(
                          icon: const Icon(Icons.send_rounded),
                          onPressed: () {
                            Navigator.pop(context, email);
                          },
                        )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      "Mời thành viên bằng mã QR",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 12),

                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 180,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (targetEmail == null || targetEmail.isEmpty) return;
    if (!mounted) return;

    final myEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();
    final homeName = getSelectedHomeDisplayName();

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
      if (!mounted) return;

      showTopToast(
        context,
        "Email chưa đăng ký",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final targetData = await ShareService.loadDirectoryUser(targetUid);

    await ShareService.sendShareRequest(
      ownerUid: shareOwnerUid,
      targetUid: targetUid,
      homeId: selectedHome,
      homeName: homeName,
      ownerEmail: myEmail ?? "",
      targetData: targetData,
      targetEmail: targetEmail,
    );

    await HomeNotificationService.notifyHome(
      ownerUid: shareOwnerUid,
      homeId: selectedHome,
      recipientUid: targetUid,
      type: "share_request",
      title: "Lời mời chia sẻ nhà",
      message:
      "${userName.isNotEmpty ? userName : (myEmail ?? "Một chủ nhà")} đã mời bạn tham gia nhà \"$homeName\".",
      homeName: homeName,
      category: "member",
      severity: "info",
      entityType: "home",
      entityId: selectedHome,
      includeActor: false,
      writeHomeTimeline: false,
    );

    if (!mounted) return;

    showTopToast(
      context,
      "Đã share home",
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );
  }

  void transferOwner() async {
    final controller = TextEditingController();
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
                  "Chuyển quyền chủ nhà",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 18),
                const SizedBox(height: 12),

                StatefulBuilder(
                  builder: (context, setEmailState) {
                    final email = controller.text.trim().toLowerCase();

                    final emailOk = RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email);

                    return TextField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setEmailState(() {}),
                      decoration: InputDecoration(
                        labelText: "Email người nhận",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: emailOk
                            ? IconButton(
                          icon: const Icon(Icons.send_rounded),
                          onPressed: () {
                            Navigator.pop(
                              context,
                              controller.text.trim().toLowerCase(),
                            );
                          },
                        )
                            : null,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );

    if (targetEmail == null || targetEmail.isEmpty) return;
    if (!mounted) return;

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
    final targetUid = await ShareService.findUidByEmail(targetEmail);

    if (targetUid == null) {
      if (!mounted) return;

      showTopToast(
        context,
        "Không tìm thấy user",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // ===== 2. CONFIRM =====
    if (!mounted) return;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
    if (!mounted) return;

    final passwordController = TextEditingController();

    final passwordOk = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận mật khẩu"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Mật khẩu tài khoản",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Huỷ"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );

    if (passwordOk != true) return;
    final user = FirebaseAuth.instance.currentUser!;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      if (!mounted) return;

      showTopToast(
        context,
        "Sai mật khẩu",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    final homeId = selectedHome;
    final homeName = getHomeDisplayName(homeId);

    await FirebaseDatabase.instance
        .ref("accounts/$targetUid/shareRequests/transfer_${homeId}_$uid")
        .set({
      "type": "transfer_owner_request",
      "homeId": homeId,
      "oldOwnerUid": uid,
      "newOwnerUid": targetUid,
      "ownerEmail": myEmail ?? "",
      "targetEmail": targetEmail,
      "homeName": homeName,
      "time": DateTime.now().millisecondsSinceEpoch,
    });
    await HomeNotificationService.notifyHome(
      ownerUid: uid,
      homeId: homeId,
      recipientUid: targetUid,
      type: "transfer_owner_request",
      title: "Yêu cầu chuyển quyền chủ nhà",
      message:
      "${userName.isNotEmpty ? userName : (myEmail ?? "Một chủ nhà")} muốn chuyển quyền chủ nhà \"$homeName\" cho bạn.",
      homeName: homeName,
      category: "member",
      severity: "info",
      entityType: "home",
      entityId: homeId,
      includeActor: false,
      writeHomeTimeline: false,
    );
    await HomeNotificationService.addNotification(
      uid: uid,
      type: "transfer_owner_request",
      title: "Đã gửi yêu cầu chuyển quyền",
      message:
      "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"$homeName\" cho $targetEmail.",
      homeId: homeId,
      ownerUid: uid,
      homeName: homeName,
      entityType: "home",
      entityId: homeId,
    );

    if (!mounted) return;

    showTopToast(
      context,
      "Đã gửi yêu cầu chuyển quyền chủ nhà",
      color: Colors.green,
      icon: Icons.check_circle_rounded,
    );

    return;
  }

  void deleteDevice(String id) async {
    if (!canManageHome()) {
      showTopToast(
        context,
        "Bạn không có quyền xoá thiết bị",
        color: Colors.orange,
        icon: Icons.lock_rounded,
      );
      return;
    }

    if (!await showConfirmDialog(context, "Xóa Device?")) return;

    final ownerUid = getHomeOwnerUid();
    final homeName = getSelectedHomeDisplayName();
    final deviceName = getDevices()[id]?["name"]?.toString() ?? id;

    try {
      await FirebaseDatabase.instance
          .ref(
        "device_delete_requests/${DateTime.now().millisecondsSinceEpoch}_$id",
      )
          .set({
        "ownerUid": ownerUid,
        "homeId": selectedHome,
        "deviceId": id,
        "deviceName": deviceName,
        "requestedBy": uid,
        "time": DateTime.now().millisecondsSinceEpoch,
        "status": "pending",
      });

      if (!mounted) return;

      showTopToast(
        context,
        "Đã gửi yêu cầu xoá thiết bị",
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;

      showTopToast(
        context,
        "Không gửi được yêu cầu xoá: $e",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    await HomeNotificationService.notifyHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      type: "device_delete_requested",
      category: "device",
      severity: "warning",
      title: "Đang xoá thiết bị",
      message:
      "SafeHome đang xoá thiết bị \"$deviceName\" khỏi nhà \"$homeName\".",
      deviceId: id,
      entityType: "device",
      entityId: id,
      homeName: homeName,
    );
  }

  Future<void> logout() async {
    final confirmed = await showConfirmDialog(
      context,
      "Đăng xuất?",
    );

    if (!confirmed || !mounted) {
      return;
    }

    final navigator = Navigator.of(
      context,
      rootNavigator: true,
    );

    while (navigator.canPop()) {
      final didPop = await navigator.maybePop();

      if (!didPop) {
        break;
      }

      await WidgetsBinding.instance.endOfFrame;
    }

    await AutoLoginService.clearLogin();
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

    await HomeService.addHome(uid: uid, id: id, name: name, address: address);
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
      homeName: name,
      entityType: "home",
      entityId: id,
    );
  }

  // ================= RESTORED FULL FUNCTIONS =================
  int _timeToMin(String value) {
    final parts = value.split(":");

    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;

    return h * 60 + m;
  }

  bool isNowInRange(String startTime, String endTime, String checkTime) {
    final start = _timeToMin(startTime);
    final end = _timeToMin(endTime);
    final check = _timeToMin(checkTime);

    if (start > end) {
      return check >= start || check <= end;
    }

    return check >= start && check <= end;
  }

  void showAlarmPauseSheet() async {
    TimeOfDay parseTime(String? value, TimeOfDay fallback) {
      if (value == null || !value.contains(":")) {
        return fallback;
      }

      final parts = value.split(":");

      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? fallback.hour,
        minute: int.tryParse(parts[1]) ?? fallback.minute,
      );
    }

    TimeOfDay startTime = parseTime(
      alarmPauseToday["start"]?.toString(),
      const TimeOfDay(hour: 23, minute: 30),
    );

    TimeOfDay endTime = parseTime(
      alarmPauseToday["end"]?.toString(),
      const TimeOfDay(hour: 23, minute: 45),
    );

    String reason = "Về muộn";

    final ownerUid = getHomeOwnerUid();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String format(TimeOfDay t) {
              return "${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}";
            }

            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Text(
                      "⏸️ Tạm tắt Alarm hôm nay",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await openTimeTextInput(
                                context: context,
                                title: "Chọn giờ bắt đầu tạm tắt",
                                initial: format(startTime),
                              );

                              if (picked == null) return;

                              final parts = picked.split(":");

                              setSheetState(() {
                                startTime = TimeOfDay(
                                  hour:
                                  int.tryParse(parts[0]) ?? startTime.hour,
                                  minute:
                                  int.tryParse(parts[1]) ??
                                      startTime.minute,
                                );
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  const Text("Từ giờ"),
                                  const SizedBox(height: 6),
                                  Text(
                                    format(startTime),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await openTimeTextInput(
                                context: context,
                                title: "Chọn giờ kết thúc tạm tắt",
                                initial: format(endTime),
                              );

                              if (picked == null) return;

                              final parts = picked.split(":");

                              setSheetState(() {
                                endTime = TimeOfDay(
                                  hour: int.tryParse(parts[0]) ?? endTime.hour,
                                  minute:
                                  int.tryParse(parts[1]) ?? endTime.minute,
                                );
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  const Text("Đến giờ"),
                                  const SizedBox(height: 6),
                                  Text(
                                    format(endTime),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: ["Về muộn", "Ra ngoài", "Khác"].map((item) {
                        final selected = reason == item;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Text(item),
                              selected: selected,
                              onSelected: (_) {
                                setSheetState(() {
                                  reason = item;
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("Lưu"),
                        onPressed: () async {
                          final home = safeMap(homes[selectedHome]);
                          final homeName = getSelectedHomeDisplayName();
                          final devices = safeMap(home["devices"]);

                          Map<String, dynamic>? firstAlarm;

                          for (final d in devices.values) {
                            final device = safeMap(d);
                            final alarm = safeMap(device["alarm"]);

                            if (alarm["enabled"] == true) {
                              firstAlarm = alarm;
                              break;
                            }
                          }

                          if (firstAlarm != null) {
                            final alarmStart =
                                firstAlarm["start"]?.toString() ?? "23:00";
                            final alarmEnd =
                                firstAlarm["end"]?.toString() ?? "06:00";

                            final selectedStart = format(startTime);
                            final selectedEnd = format(endTime);

                            final startOk = isNowInRange(
                              alarmStart,
                              alarmEnd,
                              selectedStart,
                            );

                            final endOk = isNowInRange(
                              alarmStart,
                              alarmEnd,
                              selectedEnd,
                            );

                            if (!startOk || !endOk) {
                              showTopToast(
                                context,
                                "Khoảng thời gian phải nằm trong khung Alarm ($alarmStart → $alarmEnd)",
                                color: Colors.orange,
                                icon: Icons.schedule_rounded,
                              );

                              return;
                            }
                          }

                          final now = DateTime.now();

                          final date =
                              "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

                          final pauseStartText = format(startTime);
                          final pauseEndText = format(endTime);
                          final createdAt =
                              DateTime.now().millisecondsSinceEpoch;

                          try {
                            await FirebaseDatabase.instance
                                .ref(
                              "alarm_pause_requests/${DateTime.now().millisecondsSinceEpoch}_$uid",
                            )
                                .set({
                              "status": "pending",
                              "ownerUid": ownerUid,
                              "homeId": selectedHome,
                              "homeName": homeName,
                              "date": date,
                              "start": pauseStartText,
                              "end": pauseEndText,
                              "reason": reason,
                              "createdByUid": uid,
                              "createdByName": userName,
                              "createdAt": createdAt,
                            });
                          } catch (e) {
                            if (!context.mounted) return;

                            showTopToast(
                              context,
                              "Không lưu được tạm tắt Alarm: $e",
                              color: Colors.red,
                              icon: Icons.error_outline_rounded,
                            );
                            return;
                          }

                          if (mounted) {
                            setState(() {
                              alarmPauseToday = {
                                "date": date,
                                "start": pauseStartText,
                                "end": pauseEndText,
                                "homeName": homeName,
                                "reason": reason,
                                "createdByUid": uid,
                                "createdByName": userName,
                                "createdAt": createdAt,
                              };
                            });
                          }

                          if (!context.mounted) return;

                          Navigator.pop(context);
                        },
                      ),
                    ),

                    if (alarmPauseToday.isNotEmpty &&
                        alarmPauseToday["date"] ==
                            "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, "0")}-${DateTime.now().day.toString().padLeft(2, "0")}") ...[
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text("Xóa lịch tạm tắt"),
                          onPressed: () async {
                            try {
                              await FirebaseDatabase.instance
                                  .ref(
                                "alarm_pause_requests/${DateTime.now().millisecondsSinceEpoch}_$uid",
                              )
                                  .set({
                                "status": "pending",
                                "action": "remove",
                                "ownerUid": ownerUid,
                                "homeId": selectedHome,
                                "createdByUid": uid,
                                "createdByName": userName,
                                "createdAt":
                                DateTime.now().millisecondsSinceEpoch,
                              });
                            } catch (e) {
                              if (!context.mounted) return;

                              showTopToast(
                                context,
                                "Không xoá được lịch tạm tắt Alarm: $e",
                                color: Colors.red,
                                icon: Icons.error_outline_rounded,
                              );
                              return;
                            }

                            if (mounted) {
                              setState(() {
                                alarmPauseToday = {};
                              });
                            }

                            if (!context.mounted) return;

                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void renameHome() async {
    final isShared = homes[selectedHome]?["_shared"] == true;
    final usePersonalName = isShared && !canManageHome();

    final currentName = usePersonalName
        ? (homes[selectedHome]?["_customName"] ??
        homes[selectedHome]?["name"] ??
        selectedHome)
        : (homes[selectedHome]?["name"] ?? selectedHome);

    final controller = TextEditingController(text: currentName);

    final name = await showModalBottomSheet<String>(
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
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final textOk = controller.text.trim().isNotEmpty;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      color: Colors.blue,
                      size: 44,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Đổi tên nhà",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: controller,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: "Tên nhà",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: textOk
                            ? IconButton(
                          icon: const Icon(Icons.check_rounded),
                          onPressed: () {
                            Navigator.pop(
                              context,
                              controller.text.trim(),
                            );
                          },
                        )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Tên này sẽ hiển thị trên tất cả màn hình của nhà.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (name == null || name.trim().isEmpty) return;

    // HOME SHARE -> lưu riêng cho user hiện tại
    // Member dùng tên riêng; Owner/Admin sửa tên thật của nhà.
    if (usePersonalName) {
      await FirebaseDatabase.instance
          .ref("${FirebasePaths.sharedHome(uid, selectedHome)}/customName")
          .set(name);

      setState(() {
        homes[selectedHome]?["_customName"] = name;
      });

      return;
    }

    final ownerUid = getHomeOwnerUid();

    await HomeService.renameHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      name: name,
    );

    // Xóa tên riêng cũ của Admin để không che tên thật vừa đổi.
    if (isShared) {
      await FirebaseDatabase.instance
          .ref("${FirebasePaths.sharedHome(uid, selectedHome)}/customName")
          .remove();
    }

    if (mounted) {
      setState(() {
        homes[selectedHome]?["name"] = name;
        homes[selectedHome]?.remove("_customName");
      });
    }
    await HomeNotificationService.notifyHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      type: "home_renamed",
      category: "home",
      title: "Đã đổi tên nhà",
      message: "Nhà đã được đổi tên thành \"$name\".",
      entityType: "home",
      entityId: selectedHome,
      homeName: name,
    );
  }

  void renameDevice(String id) async {
    final oldDeviceName = getDevices()[id]?["name"]?.toString() ?? id;
    final controller = TextEditingController(text: oldDeviceName);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thay tên"),
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

    final newName = name.trim();

    if (newName == oldDeviceName.trim()) {
      return;
    }

    final ownerUid = getHomeOwnerUid();
    final homeName = getSelectedHomeDisplayName();
    final emailName = FirebaseAuth.instance.currentUser?.email
        ?.split("@")
        .first
        .trim() ??
        "";
    final actorName = userName.trim().isNotEmpty
        ? userName.trim()
        : emailName.isNotEmpty
        ? emailName
        : "Một thành viên";

    await HomeService.renameDevice(
      ownerUid: ownerUid,
      homeId: selectedHome,
      deviceId: id,
      name: newName,
    );

    await HomeNotificationService.notifyHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      type: "device_renamed",
      category: "device",
      severity: "info",
      title: "Đã đổi tên thiết bị",
      message:
      "$actorName đã đổi tên thiết bị \"$oldDeviceName\" thành \"$newName\" trong nhà \"$homeName\".",
      deviceId: id,
      entityType: "device",
      entityId: id,
      homeName: homeName,
      includeActor: true,
      data: {
        "actorName": actorName,
        "oldName": oldDeviceName,
        "newName": newName,
      },
    );
  }
  Future<void> runFirebaseSecurityTest() async {
    if (selectedHome.isEmpty) {
      showTopToast(
        context,
        "Chưa chọn nhà để kiểm tra",
        color: Colors.orange,
        icon: Icons.home_work_outlined,
      );
      return;
    }

    if (!isOwner()) {
      showTopToast(
        context,
        "Hãy thực hiện kiểm tra bằng tài khoản Owner",
        color: Colors.orange,
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    final ownerUid = getHomeOwnerUid();
    final homeId = selectedHome;

    final homeRef = FirebaseDatabase.instance.ref(
      "accounts/$ownerUid/homes/$homeId",
    );

    final homeSnap = await homeRef.get();

    if (!homeSnap.exists || homeSnap.value is! Map) {
      if (!mounted) return;

      showTopToast(
        context,
        "Không đọc được dữ liệu nhà",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final homeData = Map<String, dynamic>.from(
      homeSnap.value as Map,
    );

    final rawDevices = homeData["devices"];

    if (rawDevices is! Map || rawDevices.isEmpty) {
      if (!mounted) return;

      showTopToast(
        context,
        "Nhà cần có ít nhất một thiết bị để test",
        color: Colors.orange,
        icon: Icons.sensors_off_rounded,
      );
      return;
    }

    final devices = Map<String, dynamic>.from(rawDevices);
    final firstDeviceEntry = devices.entries.first;

    final deviceId = firstDeviceEntry.key.toString();
    final deviceData = firstDeviceEntry.value is Map
        ? Map<String, dynamic>.from(
      firstDeviceEntry.value as Map,
    )
        : <String, dynamic>{};

    final deviceRef = homeRef.child(
      "devices/$deviceId",
    );

    final results = <String, String>{};

    bool isPermissionDenied(Object error) {
      final text = error.toString().toLowerCase();

      return text.contains("permission-denied") ||
          text.contains("permission_denied") ||
          text.contains("permission denied");
    }

    Future<void> expectDenied({
      required String label,
      required Future<void> Function() action,
      Future<void> Function()? cleanup,
    }) async {
      try {
        await action();

        results[label] = "FAIL — Firebase cho phép ghi";

        if (cleanup != null) {
          try {
            await cleanup();
          } catch (error) {
            results[label] =
            "FAIL — ghi được, cleanup lỗi: $error";
          }
        }
      } catch (error) {
        if (isPermissionDenied(error)) {
          results[label] = "PASS";
        } else {
          results[label] = "ERROR — $error";
        }
      }
    }

    final testId =
    DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Không được ghi trực tiếp _ownerUid.
    await expectDenied(
      label: "_ownerUid",
      action: () async {
        await homeRef
            .child("_ownerUid")
            .set(ownerUid);
      },
    );

    // 2. Không được tạo event trực tiếp từ client.
    final eventTestRef = homeRef.child(
      "events/security_test_$testId",
    );

    await expectDenied(
      label: "events",
      action: () async {
        await eventTestRef.set({
          "type": "security_test",
          "time": DateTime.now().millisecondsSinceEpoch,
        });
      },
      cleanup: () async {
        await eventTestRef.remove();
      },
    );

    // 3. Không được ghi trực tiếp alarmPauseToday.
    final pauseExists =
        homeData.containsKey("alarmPauseToday") &&
            homeData["alarmPauseToday"] != null;

    final pauseTestValue = pauseExists
        ? homeData["alarmPauseToday"]
        : <String, dynamic>{
      "date": "security_test",
      "start": "00:00",
      "end": "00:01",
      "reason": "security_test",
    };

    await expectDenied(
      label: "alarmPauseToday",
      action: () async {
        await homeRef
            .child("alarmPauseToday")
            .set(pauseTestValue);
      },
      cleanup: pauseExists
          ? null
          : () async {
        await homeRef
            .child("alarmPauseToday")
            .remove();
      },
    );

    final fieldFallbackValues = <String, Object?>{
      "contact": false,
      "smoke": false,
      "tamper": false,
      "availability": "online",
      "battery": 100,
      "type": "door",
      "last_seen": DateTime.now().toIso8601String(),
    };

    // 4–10. Các trạng thái thiết bị chỉ backend được ghi.
    for (final entry in fieldFallbackValues.entries) {
      final field = entry.key;
      final fieldExists =
          deviceData.containsKey(field) &&
              deviceData[field] != null;

      final testValue = fieldExists
          ? deviceData[field]
          : entry.value;

      final fieldRef = deviceRef.child(field);

      await expectDenied(
        label: "device/$field",
        action: () async {
          await fieldRef.set(testValue);
        },
        cleanup: fieldExists
            ? null
            : () async {
          await fieldRef.remove();
        },
      );
    }

    // 11. Kiểm tra cổng ghi toàn bộ thiết bị.
    // Đây cũng là cổng mà thao tác remove() trực tiếp phải đi qua.
    final deviceRootTestData =
    Map<String, dynamic>.from(deviceData);

    deviceRootTestData["_securityTest"] = testId;

    await expectDenied(
      label: "device root / delete gate",
      action: () async {
        await deviceRef.set(deviceRootTestData);
      },
      cleanup: () async {
        await deviceRef
            .child("_securityTest")
            .remove();
      },
    );

    if (!mounted) return;

    final passCount = results.values
        .where((value) => value == "PASS")
        .length;

    final lines = results.entries.map((entry) {
      final icon = entry.value == "PASS" ? "✅" : "❌";

      return "$icon ${entry.key}: ${entry.value}";
    }).join("\n\n");

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            passCount == results.length
                ? "Firebase Rules: ĐẠT"
                : "Firebase Rules: CÓ LỖI",
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                "$passCount/${results.length} bài test đạt\n\n"
                    "$lines",
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }
  Color getHomeColor(String h) {
    final devices = safeMap(homes[h]?["devices"]);

    final overall = getOverallStatus(devices);
    final level = overall["level"]?.toString() ?? "safe";

    final selected = h == selectedHome;

    if (level == "danger") {
      return selected ? Colors.red.shade500 : Colors.red.shade400;
    }

    if (level == "warning") {
      return selected ? Colors.orange.shade500 : Colors.orange.shade400;
    }

    return selected ? Colors.green.shade500 : Colors.green.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final devices = getDevices();
    const sectionGap = 6.0;

    return Scaffold(
      extendBody: true,
      backgroundColor: SafeHomeColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.46, 1],
            colors: [
              Color(0xFFF3F8F5),
              SafeHomeColors.background,
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: SizedBox(
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: SafeHomeColors.surface,
                          borderRadius: BorderRadius.circular(11),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () async {
                              final selected =
                              await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AllHomePage(
                                    homeOrder: homeOrder,
                                  ),
                                ),
                              );

                              if (selected == null) return;

                              setState(() {
                                selectedHome = selected;
                              });

                              final index =
                              homeOrder.indexOf(selected);

                              if (index != -1 &&
                                  homeTabController.hasClients) {
                                homeTabController.animateTo(
                                  index * 110,
                                  duration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: SafeHomeColors.border,
                                ),
                                borderRadius:
                                BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.035,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: SafeHomeColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 29,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                          ),
                          children: [
                            TextSpan(
                              text: "Safe",
                              style: TextStyle(
                                color: SafeHomeColors.primary,
                              ),
                            ),
                            TextSpan(
                              text: "Home",
                              style: TextStyle(
                                color: SafeHomeColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                showHomeEventSheet(
                                  context: context,
                                  uid: uid,
                                  homeNameForId:
                                  getHomeDisplayName,
                                  onTapNotification:
                                  openHomeNotificationTarget,
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints:
                              const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              splashRadius: 18,
                              iconSize: 21,
                              tooltip: "Thông báo Home",
                              icon: const Icon(
                                Icons.notifications_rounded,
                                color: SafeHomeColors.info,
                              ),
                            ),
                            if (unreadHomeNotificationCount > 0)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  constraints:
                                  const BoxConstraints(
                                    minWidth: 17,
                                    minHeight: 17,
                                  ),
                                  alignment: Alignment.center,
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    SafeHomeColors.danger,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                      SafeHomeColors.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    unreadHomeNotificationCount >
                                        99
                                        ? "99+"
                                        : unreadHomeNotificationCount
                                        .toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      height: 1,
                                      fontWeight:
                                      FontWeight.w900,
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
              const SizedBox(height: sectionGap),

              Padding(
                padding: EdgeInsets.zero,
                child: HomeTabs(
                  unreadChatByHome: unreadChatByHome,
                  controller: homeTabController,
                  homes: homes,
                  homeOrder: homeOrder,
                  selectedHome: selectedHome,
                  onSelect: (h) {
                    if (h == selectedHome) return;

                    final currentHome = safeMap(homes[h]);
                    final parsedAlarm =
                    HomeStateParser.parseAlarm(currentHome);

                    setState(() {
                      selectedHome = h;
                      alarmEnabled =
                          safeMap(alarmSettings[h])["enabled"] !=
                              false;
                      start = parsedAlarm["start"];
                      end = parsedAlarm["end"];
                      alarmPauseToday = safeMap(
                        currentHome["alarmPauseToday"],
                      );
                    });

                    startHomeEventsListener();
                  },
                  onReorder: reorderHomeTabs,
                  getHomeColor: getHomeColor,
                ),
              ),
              const SizedBox(height: sectionGap),

              Expanded(
                child: Stack(
                  children: [
                    DeviceList(
                      devices: devices,
                      selectedRoomId: selectedRoomId,
                      header: Column(
                        children: [
                          StatusPanel(
                            alarmPauseText: (() {
                              if (alarmPauseToday.isEmpty) {
                                return "Chưa thiết lập";
                              }

                              final now = DateTime.now();

                              final today =
                                  "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

                              if (alarmPauseToday["date"] != today) {
                                return "Chưa thiết lập";
                              }

                              return "${alarmPauseToday["start"] ?? "--:--"} → "
                                  "${alarmPauseToday["end"] ?? "--:--"}"
                                  "${(alarmPauseToday["reason"] ?? "").toString().isNotEmpty ? " • ${alarmPauseToday["reason"]}" : ""}";
                            })(),
                            onAlarmPauseToday: () {
                              openAlarmPauseSheetWithReminder();
                            },
                            environmentText: getHomeEnvironmentText(),
                            homeEvents: homeEvents,
                            onEnvironmentTap: () {
                              final tempDevice = getTemperatureDevice();

                              if (tempDevice == null) return;

                              showDeviceDetail(
                                context: context,
                                id: tempDevice["id"],
                                d: tempDevice["data"],
                                ownerUid: getHomeOwnerUid(),
                                homeId: selectedHome,
                                onRename: canManageHome()
                                    ? () => renameDevice(tempDevice["id"])
                                    : null,
                                onDelete: canManageHome()
                                    ? () => deleteDevice(tempDevice["id"])
                                    : null,
                                onNotification: () =>
                                    openNotificationList(tempDevice["id"]),
                              );
                            },
                            overall: getOverallStatus(devices),
                            alarmEnabled: alarmEnabled,
                            onAlarmEnabledChanged: canManageHome()
                                ? setAlarmEnabled
                                : null,
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
                                  canManageHome: canManageHome(),
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
                                  canManageHome: canManageHome(),
                                ),
                              );
                            },
                            alarmStart: formatAlarmSchedules(),
                            alarmEnd: "",
                          ),
                          const SizedBox(height: sectionGap),

                          RoomTabs(
                            rooms: getRooms(),
                            homeName:
                            homes[selectedHome]?["name"]?.toString() ??
                                "Nhà",
                            selectedRoomId: selectedRoomId,
                            onSelect: (roomId) {
                              setState(() {
                                selectedRoomId = roomId;
                              });
                            },
                            onReorder: (roomIds) async {
                              if (!canManageHome()) {
                                showTopToast(
                                  context,
                                  "Bạn không có quyền sắp xếp phòng",
                                  color: Colors.orange,
                                  icon: Icons.lock_rounded,
                                );
                                return;
                              }

                              final ownerUid = getHomeOwnerUid();
                              final updates = <String, Object?>{};

                              for (var i = 0; i < roomIds.length; i++) {
                                updates["accounts/$ownerUid/homes/$selectedHome/rooms/${roomIds[i]}/order"] =
                                    i + 1;
                              }

                              if (updates.isNotEmpty) {
                                await FirebaseDatabase.instance.ref().update(
                                  updates,
                                );
                              }
                            },
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
                                          "Quét QR để thêm thiết bị",
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
                          if (!context.mounted) return;

                          final code = await openQRScanner(context);

                          if (code != null) {
                            pairSensor(code);
                          }
                        }

                        if (result == "__MANUAL__") {
                          if (!context.mounted) return;

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
                          ownerUid: getHomeOwnerUid(),
                          homeId: selectedHome,
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

      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: SafeHomeColors.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: SafeHomeColors.border,
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.075),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                minimumSize: const Size(46, 46),
                maximumSize: const Size(46, 46),
                padding: EdgeInsets.zero,
                foregroundColor: SafeHomeColors.textSecondary,
                backgroundColor: Colors.transparent,
                hoverColor: SafeHomeColors.primarySoft,
                highlightColor: SafeHomeColors.primarySoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                IconButton(
                  icon: const Icon(
                    Icons.add_home_work_rounded,
                    color: SafeHomeColors.primary,
                  ),
                  onPressed: addHome,
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_rounded,
                        color: SafeHomeColors.primary,
                      ),
                      onPressed: () {
                        showHomeChatSheet(
                          context: context,
                          homeId: selectedHome,
                          homeName:
                          homes[selectedHome]?["name"]?.toString() ??
                              selectedHome,
                          userName: userName,
                          userPhotoUrl: userPhotoUrl,
                          ownerUid: getHomeOwnerUid(),
                          canManageMembers: canManageHome(),
                          isOwner: isOwner(),
                        );
                      },
                    ),
                    if ((unreadChatByHome[selectedHome] ?? 0) > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: SafeHomeColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SafeHomeColors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            (unreadChatByHome[selectedHome] ?? 0) > 99
                                ? "99+"
                                : (unreadChatByHome[selectedHome] ?? 0)
                                .toString(),
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
                IconButton(
                  icon: Icon(
                    Icons.crisis_alert_rounded,
                    color: alarmEnabled
                        ? SafeHomeColors.danger
                        : SafeHomeColors.textSecondary,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      showDragHandle: false,
                      backgroundColor: Colors.transparent,
                      builder: (_) {
                        bool localAlarmEnabled = alarmEnabled;

                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return SafeArea(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  10,
                                  18,
                                  18,
                                ),
                                decoration: const BoxDecoration(
                                  color: SafeHomeColors.surface,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(26),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 5,
                                      margin: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SafeHomeColors.border,
                                        borderRadius:
                                        BorderRadius.circular(999),
                                      ),
                                    ),
                                    SwitchListTile(
                                      value: localAlarmEnabled,
                                      activeThumbColor: Colors.red,
                                      secondary: const Icon(
                                        Icons.crisis_alert_rounded,
                                        color: Colors.red,
                                      ),
                                      title: const Text(
                                        "Nhận cảnh báo Alarm",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        "Bật/tắt alarm cho tài khoản này",
                                      ),
                                      onChanged: (value) async {
                                        setModalState(() {
                                          localAlarmEnabled = value;
                                        });

                                        await setAlarmEnabled(value);

                                        if (value && context.mounted) {
                                          await showAlarmReceiveReminder();
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.pause_circle_filled_rounded,
                                        color: Colors.orange.shade700,
                                      ),
                                      title: const Text(
                                        "Tạm tắt Alarm hôm nay",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        alarmPauseToday.isEmpty
                                            ? "Chưa thiết lập"
                                            : "${alarmPauseToday["start"] ?? "--:--"} → ${alarmPauseToday["end"] ?? "--:--"}"
                                            "${(alarmPauseToday["reason"] ?? "").toString().isNotEmpty ? " • ${alarmPauseToday["reason"]}" : ""}",
                                      ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await Future<void>.delayed(
                                          const Duration(milliseconds: 120),
                                        );

                                        if (!mounted) return;

                                        await openAlarmPauseSheetWithReminder();
                                      },
                                    ),
                                    const Divider(),

                                    ListTile(
                                      leading: const Icon(
                                        Icons.notifications_active_rounded,
                                        color: Colors.orange,
                                      ),
                                      title: const Text("Hẹn giờ Reminder"),
                                      onTap: () {
                                        Navigator.pop(context);

                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => ScheduleSheet(
                                            ownerUid: getHomeOwnerUid(),
                                            homeId: selectedHome,
                                            isShared:
                                            homes[selectedHome]?["_shared"] ==
                                                true,
                                            type: "notification",
                                            canManageHome: canManageHome(),
                                          ),
                                        );
                                      },
                                    ),

                                    ListTile(
                                      leading: const Icon(
                                        Icons.shield_moon_rounded,
                                        color: Colors.deepPurple,
                                      ),
                                      title: const Text("Hẹn giờ Alarm"),
                                      onTap: () {
                                        Navigator.pop(context);

                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => AlarmDeviceSheet(
                                            ownerUid: getHomeOwnerUid(),
                                            homeId: selectedHome,
                                            devices: getDevices(),
                                            canManageHome: canManageHome(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.settings_rounded,
                        color: SafeHomeColors.textSecondary,
                      ),
                      onPressed: () {
                        showSettingsSheet(
                          homeId: selectedHome,
                          homeName:
                          homes[selectedHome]?["name"]?.toString() ??
                              selectedHome,
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
                                ownerUid: getHomeOwnerUid(),
                                homeId: selectedHome,
                                onRename: canManageHome()
                                    ? () => renameDevice(entry.key)
                                    : null,
                                onDelete: canManageHome()
                                    ? () => deleteDevice(entry.key)
                                    : null,
                                onNotification: () =>
                                    openNotificationList(entry.key),
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
                                  ownerUid: getHomeOwnerUid(),
                                  homeId: selectedHome,
                                  onRename: canManageHome()
                                      ? () => renameDevice(id)
                                      : null,
                                  onDelete: canManageHome()
                                      ? () => deleteDevice(id)
                                      : null,
                                  onNotification: () =>
                                      openNotificationList(id),
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
                              inviteCountNotifier: inviteCountNotifier,

                              onShareRequests: () async {
                                final changed = await showShareRequestSheet(
                                  context: context,
                                  requests: shareRequests,
                                  uid: uid,
                                );

                                if (changed == true) {
                                  await refreshShareRequests();
                                }
                              },
                            );
                          },
                          onDeleteHome: isOwner()
                              ? deleteHome
                              : () {
                            showTopToast(
                              context,
                              "Chỉ chủ nhà mới được xoá nhà",
                              color: Colors.orange,
                              icon: Icons.lock_rounded,
                            );
                          },
                          onRenameHome: renameHome,
                          onSecurityTest: runFirebaseSecurityTest,
                          onTransferOwner: isOwner()
                              ? transferOwner
                              : () {
                            showTopToast(
                              context,
                              "Chỉ chủ nhà mới được chuyển quyền",
                              color: Colors.orange,
                              icon: Icons.admin_panel_settings_rounded,
                            );
                          },
                          context: context,
                          inviteCountNotifier: inviteCountNotifier,
                          onShareRequests: () async {
                            final changed = await showShareRequestSheet(
                              context: context,
                              requests: shareRequests,
                              uid: uid,
                            );

                            if (changed == true) {
                              await refreshShareRequests();
                            }
                          },
                          onShare: shareHome,
                          onRooms: () {
                            showRoomManagementSheet(
                              context: context,
                              ownerUid: getHomeOwnerUid(),
                              homeId: selectedHome,
                            );
                          },
                          onShareList: () async {
                            final selfLeft = await showShareListSheet(
                              canManageMembers: canManageHome(),
                              isOwner: isOwner(),
                              context: context,
                              ownerUid: getHomeOwnerUid(),
                              homeId: selectedHome,
                              homeName:
                              homes[selectedHome]?["name"]?.toString() ??
                                  selectedHome,
                            );

                            if (selfLeft == true && context.mounted) {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).popUntil((route) => route.isFirst);
                            }
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
                          decoration: BoxDecoration(
                            color: SafeHomeColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SafeHomeColors.surface,
                              width: 1.5,
                            ),
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
    NotificationService.chatOpenRequest.removeListener(
      _handleChatOpenRequest,
    );
    timer?.cancel();
    accountSubscription?.cancel();
    notificationSubscription?.cancel();
    homeEventsSubscription?.cancel();
    for (final subscription in homeChatSubscriptions.values) {
      subscription.cancel();
    }
    homeChatSubscriptions.clear();
    homeTabController.dispose();
    super.dispose();
  }
}
