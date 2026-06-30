import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
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
import '../services/auto_away_service.dart';
import '../sheets/room_management_sheet.dart';
import '../widgets/room_tabs.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  AppStrings get _strings => AppStrings.of(context);
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

  String uid = "";
  DatabaseReference ref = FirebaseDatabase.instance.ref();
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

    return name.isNotEmpty ? name : _strings.t("Nhà chưa đặt tên");
  }

  void selectHomeFromNotification(String homeId) {
    if (homeId.isEmpty || !homes.containsKey(homeId)) return;

    final currentHome = safeMap(homes[homeId]);
    final parsedAlarm = HomeStateParser.parseAlarm(currentHome);

    setState(() {
      selectedHome = homeId;
      alarmEnabled = safeMap(alarmSettings[homeId])["enabled"] != false;
      securityMode = currentHome["securityMode"]?.toString() == "armed"
          ? "armed"
          : "normal";
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
    startAlarmPauseListener();
  }

  void openDeviceFromNotification(String deviceId) {
    final devices = getDevices();
    final device = safeMap(devices[deviceId]);

    if (device.isEmpty) {
      showTopToast(
        context,
        _strings.t("Không tìm thấy thiết bị trong nhà này"),
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

    _pendingChatOpenRequest = Map<String, String>.from(request);

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
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted || selectedHome != homeId || !homes.containsKey(homeId)) {
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
        _strings.t("Không tìm thấy nhà của thông báo này"),
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
  Map<String, dynamic> customRulesByHome = {};
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
                      decoration: InputDecoration(
                        labelText: _strings.t("Giờ"),
                        counterText: "",
                        border: const OutlineInputBorder(),
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
                      decoration: InputDecoration(
                        labelText: _strings.t("Phút"),
                        counterText: "",
                        border: const OutlineInputBorder(),
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
              child: Text(_strings.t("Huỷ")),
            ),
            ElevatedButton(
              onPressed: () {
                final h = hourController.text.trim().padLeft(2, '0');
                final m = minuteController.text.trim().padLeft(2, '0');
                final value = "$h:$m";

                if (!isValidTime(value)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_strings.t("Giờ không hợp lệ")),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context, value);
              },
              child: Text(_strings.t("OK")),
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
    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(_strings.t("Lưu ý khi bật Alarm")),
          content: Text(
            _strings.choose(
              vi:
              "Alarm đang được thiết lập theo cài đặt của nhà.\n\n"
                  "Hãy kiểm tra kỹ cấu hình để tránh cảnh báo làm phiền bạn.",
              en:
              "Alarm is using this home's settings.\n\n"
                  "Review the configuration to avoid unwanted alerts.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.t("Đã hiểu")),
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
          title: Text(_strings.t("Lưu ý tạm tắt Alarm")),
          content: Text(
            _strings.choose(
              vi:
              "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị "
                  "trong hôm nay, reminder sẽ được báo đến các thành viên khác "
                  "trong nhà. Khoảng thời gian tạm hoãn phải nằm trong khoảng thời gian đã được cài đặt của Alarm.",
              en:
              "This changes today's Alarm time for selected devices and notifies "
                  "other home members. The pause period must stay within the configured Alarm schedule.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_strings.t("Đã hiểu")),
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

  String securityMode = "normal";

  bool get isArmedMode => securityMode == "armed";
  bool alarmEnabled = false;
  Future<void> setSecurityMode(String mode) async {
    final homeId = selectedHome;

    if (homeId.isEmpty) return;

    final ownerUid = getHomeOwnerUid();
    final nextMode = mode == "armed" ? "armed" : "normal";
    final previousMode = securityMode;

    setState(() {
      securityMode = nextMode;

      final cachedHome = safeMap(homes[homeId]);
      cachedHome["securityMode"] = nextMode;
      cachedHome["securityModeSource"] = "manual";
      homes[homeId] = cachedHome;
    });

    try {
      await FirebaseDatabase.instance.ref().update({
        "accounts/$ownerUid/homes/$homeId/securityMode": nextMode,
        "accounts/$ownerUid/homes/$homeId/securityModeSource": "manual",
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        securityMode = previousMode;

        final cachedHome = safeMap(homes[homeId]);
        cachedHome["securityMode"] = previousMode;
        homes[homeId] = cachedHome;
      });

      showTopToast(
        context,
        _strings.t("Không thể thay đổi chế độ nhà"),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );

      debugPrint("SET_SECURITY_MODE_ERROR: $error");
    }
  }

  Future<void> openAutoAwaySetup() async {
    final homeId = selectedHome;

    if (homeId.isEmpty) {
      return;
    }

    if (!canManageHome()) {
      showTopToast(
        context,
        _strings.t("Bạn không có quyền thay đổi vị trí nhà"),
        color: Colors.orange,
        icon: Icons.lock_rounded,
      );
      return;
    }

    final ownerUid = getHomeOwnerUid();
    final currentHome = safeMap(homes[homeId]);
    final currentAutoAway = safeMap(currentHome["autoAway"]);
    final pageContext = context;

    double? readDouble(dynamic raw) {
      if (raw is num) {
        return raw.toDouble();
      }

      return double.tryParse(raw?.toString() ?? "");
    }

    var localEnabled = currentAutoAway["enabled"] == true;
    var latitude = readDouble(currentAutoAway["latitude"]);
    var longitude = readDouble(currentAutoAway["longitude"]);
    const radiusMeters = 150.0;
    var locating = false;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            final currentLatitude = latitude;
            final currentLongitude = longitude;
            final hasLocation =
                currentLatitude != null && currentLongitude != null;
            final locationText = hasLocation
                ? _strings.choose(
              vi:
              "Đã đặt vị trí nhà\n"
                  "${currentLatitude.toStringAsFixed(6)}, "
                  "${currentLongitude.toStringAsFixed(6)}",
              en:
              "Home location set\n"
                  "${currentLatitude.toStringAsFixed(6)}, "
                  "${currentLongitude.toStringAsFixed(6)}",
            )
                : _strings.t("Chưa đặt vị trí nhà");

            Future<void> captureCurrentLocation() async {
              if (locating) {
                return;
              }

              setSheetState(() {
                locating = true;
              });

              try {
                final serviceEnabled =
                await Geolocator.isLocationServiceEnabled();

                if (!serviceEnabled) {
                  if (!sheetContext.mounted) {
                    return;
                  }

                  showTopToast(
                    sheetContext,
                    _strings.t("Hãy bật GPS để đặt vị trí nhà"),
                    color: Colors.orange,
                    icon: Icons.location_off_rounded,
                  );

                  await Geolocator.openLocationSettings();
                  return;
                }

                var permission = await Geolocator.checkPermission();

                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                }

                if (permission == LocationPermission.denied) {
                  if (!sheetContext.mounted) {
                    return;
                  }

                  showTopToast(
                    sheetContext,
                    _strings.t("Bạn chưa cấp quyền vị trí"),
                    color: Colors.orange,
                    icon: Icons.location_disabled_rounded,
                  );
                  return;
                }

                if (permission == LocationPermission.deniedForever) {
                  if (!sheetContext.mounted) {
                    return;
                  }

                  showTopToast(
                    sheetContext,
                    _strings.t("Hãy cấp quyền vị trí trong Cài đặt ứng dụng"),
                    color: Colors.orange,
                    icon: Icons.settings_rounded,
                  );

                  await Geolocator.openAppSettings();
                  return;
                }

                final position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                    timeLimit: Duration(seconds: 20),
                  ),
                );

                if (!sheetContext.mounted) {
                  return;
                }

                setSheetState(() {
                  latitude = position.latitude;
                  longitude = position.longitude;
                });
              } catch (error) {
                if (!sheetContext.mounted) {
                  return;
                }

                showTopToast(
                  sheetContext,
                  _strings.choose(
                    vi: "Không lấy được vị trí hiện tại: $error",
                    en: "Could not get the current location: $error",
                  ),
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                );
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() {
                    locating = false;
                  });
                }
              }
            }

            Future<void> saveAutoAway() async {
              if (saving) {
                return;
              }

              if (localEnabled && !hasLocation) {
                showTopToast(
                  sheetContext,
                  _strings.t("Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ"),
                  color: Colors.orange,
                  icon: Icons.location_on_outlined,
                );
                return;
              }

              if (localEnabled) {
                final hasBackgroundPermission =
                await AutoAwayService.ensureBackgroundPermission();

                if (!hasBackgroundPermission) {
                  if (!sheetContext.mounted) {
                    return;
                  }

                  showTopToast(
                    sheetContext,
                    _strings.t(
                      "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng",
                    ),
                    color: Colors.orange,
                    icon: Icons.location_disabled_rounded,
                  );

                  await Geolocator.openAppSettings();
                  return;
                }
              }

              setSheetState(() {
                saving = true;
              });

              final data = <String, Object?>{
                "enabled": localEnabled,
                "radiusMeters": radiusMeters.round(),
                "updatedAt": DateTime.now().millisecondsSinceEpoch,
                "updatedBy": uid,
              };

              if (hasLocation) {
                data["latitude"] = latitude;
                data["longitude"] = longitude;
              }

              try {
                await FirebaseDatabase.instance
                    .ref("accounts/$ownerUid/homes/$homeId/autoAway")
                    .set(data);

                if (!mounted || !sheetContext.mounted) {
                  return;
                }

                setState(() {
                  final cachedHome = safeMap(homes[homeId]);
                  cachedHome["autoAway"] = Map<String, Object?>.from(data);
                  homes[homeId] = cachedHome;
                });

                unawaited(
                  AutoAwayService.syncForHomes(
                    uid: uid,
                    homes: homes,
                    force: true,
                  ).catchError((Object error) {
                    debugPrint("AUTO_AWAY_SYNC_AFTER_SAVE_ERROR: $error");
                  }),
                );

                Navigator.of(sheetContext).pop();

                showTopToast(
                  pageContext,
                  localEnabled
                      ? _strings.t(
                    "Đã bật tự động Bảo vệ khi mọi người rời nhà",
                  )
                      : _strings.t(
                    "Đã tắt tự động Bảo vệ khi mọi người rời nhà",
                  ),
                  color: SafeHomeColors.safe,
                  icon: Icons.check_circle_rounded,
                );
              } catch (error) {
                if (!sheetContext.mounted) {
                  return;
                }

                showTopToast(
                  sheetContext,
                  _strings.choose(
                    vi: "Không lưu được cài đặt: $error",
                    en: "Could not save the setting: $error",
                  ),
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                );
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() {
                    saving = false;
                  });
                }
              }
            }

            return SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 12,
                  bottom: MediaQuery.of(innerContext).viewInsets.bottom + 18,
                ),
                decoration: const BoxDecoration(
                  color: SafeHomeColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: SafeHomeColors.primarySoft,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: SafeHomeColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _strings.t("Tự động Bảo vệ khi rời nhà"),
                                style: const TextStyle(
                                  color: SafeHomeColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _strings.t("Bán kính bảo vệ mặc định: 150 m"),
                                style: const TextStyle(
                                  color: SafeHomeColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: localEnabled,
                          onChanged: (value) {
                            setSheetState(() {
                              localEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SafeHomeColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: SafeHomeColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasLocation
                                ? Icons.check_circle_rounded
                                : Icons.location_searching_rounded,
                            color: hasLocation
                                ? SafeHomeColors.safe
                                : SafeHomeColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationText,
                              style: const TextStyle(
                                color: SafeHomeColors.textPrimary,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: locating ? null : captureCurrentLocation,
                        icon: locating
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.my_location_rounded),
                        label: Text(
                          locating
                              ? _strings.t("Đang lấy vị trí...")
                              : _strings.t("Đặt vị trí nhà tại đây"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _strings.t(
                        "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SafeHomeColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : saveAutoAway,
                        icon: saving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          saving
                              ? _strings.t("Đang lưu...")
                              : _strings.t("Lưu cài đặt"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
      title: enabled ? _strings.t("Đã bật Alarm") : _strings.t("Đã tắt Alarm"),
      message: enabled
          ? _strings.choose(
        vi: "Bạn đã bật Alarm cho nhà \"$homeName\".",
        en: "You enabled Alarm for \"$homeName\".",
      )
          : _strings.choose(
        vi: "Bạn đã tắt Alarm cho nhà \"$homeName\".",
        en: "You disabled Alarm for \"$homeName\".",
      ),
      homeId: homeId,
      homeName: homeName,
    );
  }

  int pairingCountdown = 0;
  Timer? timer;

  // Firebase không phát sự kiện chỉ vì thời gian trôi qua.
  // Timer này buộc UI đánh giá lại tuổi heartbeat khi app đang mở.
  Timer? hubStatusRefreshTimer;

  final ScrollController homeTabController = ScrollController();
  StreamSubscription<DatabaseEvent>? accountSubscription;
  StreamSubscription<DatabaseEvent>? notificationSubscription;
  StreamSubscription<DatabaseEvent>? homeEventsSubscription;
  StreamSubscription<DatabaseEvent>? alarmPauseSubscription;
  String _homeEventsListenKey = "";
  String _alarmPauseListenKey = "";
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

  void startAlarmPauseListener() {
    if (selectedHome.isEmpty) {
      alarmPauseSubscription?.cancel();
      alarmPauseSubscription = null;
      _alarmPauseListenKey = "";

      if (mounted && alarmPauseToday.isNotEmpty) {
        setState(() {
          alarmPauseToday = {};
        });
      }

      return;
    }

    final homeId = selectedHome;
    final ownerUid = getHomeOwnerUid();
    final listenKey = "$ownerUid/$homeId";

    if (_alarmPauseListenKey == listenKey && alarmPauseSubscription != null) {
      return;
    }

    alarmPauseSubscription?.cancel();
    _alarmPauseListenKey = listenKey;

    alarmPauseSubscription = FirebaseDatabase.instance
        .ref("accounts/$ownerUid/homes/$homeId/alarmPauseToday")
        .onValue
        .listen(
          (event) {
        if (!mounted ||
            selectedHome != homeId ||
            _alarmPauseListenKey != listenKey) {
          return;
        }

        final pause = safeMap(event.snapshot.value);

        setState(() {
          alarmPauseToday = pause;

          final cachedHome = safeMap(homes[homeId]);

          if (pause.isEmpty) {
            cachedHome.remove("alarmPauseToday");
          } else {
            cachedHome["alarmPauseToday"] = pause;
          }

          homes[homeId] = cachedHome;
        });
      },
      onError: (Object error) {
        debugPrint("ALARM_PAUSE_LISTENER_ERROR: $error");
      },
    );
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
                "title": _strings.t("Thiết bị mới"),
                "message": _strings.choose(
                  vi: "Thiết bị \"${_deviceName(deviceId, device)}\" đã xuất hiện trong \"$homeName\".",
                  en: "Device \"${_deviceName(deviceId, device)}\" was added to \"$homeName\".",
                ),
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
      "temperatureHigh":
      temperature != null &&
          temperature > environmentWarningTemperatureC,
      "humidityHigh":
      humidity != null &&
          humidity >= environmentWarningHumidityPercent,
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
        "title": active
            ? _strings.t("Cảnh báo khói")
            : _strings.t("Khói đã an toàn"),
        "message": active
            ? _strings.choose(
          vi: "\"$name\" phát hiện khói trong \"$homeName\".",
          en: "\"$name\" detected smoke in \"$homeName\".",
        )
            : _strings.choose(
          vi: "\"$name\" đã trở lại trạng thái bình thường.",
          en: "\"$name\" has returned to normal.",
        ),
        "severity": active ? "critical" : "success",
      };
    }

    if (changed("sosActive")) {
      final active = current["sosActive"] == true;
      return {
        "type": active ? "device_sos" : "device_sos_clear",
        "title": active
            ? _strings.t("SOS được kích hoạt")
            : _strings.t("SOS đã kết thúc"),
        "message": active
            ? _strings.choose(
          vi: "\"$name\" vừa kích hoạt SOS trong \"$homeName\".",
          en: "\"$name\" triggered SOS in \"$homeName\".",
        )
            : _strings.choose(
          vi: "\"$name\" đã hết trạng thái SOS.",
          en: "\"$name\" is no longer in SOS state.",
        ),
        "severity": active ? "critical" : "success",
      };
    }

    if (changed("tamper")) {
      final active = current["tamper"] == true;
      return {
        "type": active ? "device_tamper" : "device_tamper_clear",
        "title": active
            ? _strings.t("Thiết bị bị tháo")
            : _strings.t("Tamper bình thường"),
        "message": active
            ? _strings.choose(
          vi: "\"$name\" báo bị tháo/cạy trong \"$homeName\".",
          en: "\"$name\" reported tampering in \"$homeName\".",
        )
            : _strings.choose(
          vi: "\"$name\" đã hết cảnh báo tháo/cạy.",
          en: "\"$name\" tamper alert has cleared.",
        ),
        "severity": active ? "critical" : "success",
      };
    }

    if (_isContactDevice(type) && changed("contact")) {
      final closed = current["contact"] == true;
      return {
        "type": "device_contact",
        "title": closed ? _strings.t("Cửa đã đóng") : _strings.t("Cửa đang mở"),
        "message": closed
            ? _strings.choose(
          vi: "\"$name\" đã đóng trong \"$homeName\".",
          en: "\"$name\" closed in \"$homeName\".",
        )
            : _strings.choose(
          vi: "\"$name\" đang mở trong \"$homeName\".",
          en: "\"$name\" is open in \"$homeName\".",
        ),
        "severity": closed ? "success" : "warning",
      };
    }

    if (previous["batteryLow"] != true && current["batteryLow"] == true) {
      return {
        "type": "device_battery_low",
        "title": _strings.t("Pin yếu"),
        "message": _strings.choose(
          vi: "\"$name\" trong \"$homeName\" đang yếu pin.",
          en: "\"$name\" in \"$homeName\" has a low battery.",
        ),
        "severity": "warning",
      };
    }

    if (changed("availability")) {
      final availability = current["availability"]?.toString() ?? "";
      if (availability == "offline") {
        return {
          "type": "device_connection",
          "title": _strings.t("Thiết bị offline"),
          "message": _strings.choose(
            vi: "\"$name\" trong \"$homeName\" đã mất kết nối.",
            en: "\"$name\" in \"$homeName\" went offline.",
          ),
          "severity": "warning",
        };
      }

      if (availability == "online") {
        return {
          "type": "device_connection",
          "title": _strings.t("Thiết bị online"),
          "message": _strings.choose(
            vi: "\"$name\" trong \"$homeName\" đã kết nối trở lại.",
            en: "\"$name\" in \"$homeName\" is back online.",
          ),
          "severity": "success",
        };
      }
    }

    if (previous["temperatureHigh"] != true &&
        current["temperatureHigh"] == true) {
      return {
        "type": "device_environment",
        "title": _strings.t("Nhiệt độ cao"),
        "message": _strings.choose(
          vi: "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
          en: "\"$name\" recorded a high temperature in \"$homeName\".",
        ),
        "severity": "warning",
      };
    }

    if (previous["humidityHigh"] != true && current["humidityHigh"] == true) {
      return {
        "type": "device_environment",
        "title": _strings.t("Độ ẩm cao"),
        "message": _strings.choose(
          vi: "\"$name\" ghi nhận độ ẩm cao trong \"$homeName\".",
          en: "\"$name\" recorded high humidity in \"$homeName\".",
        ),
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
        title: event["title"] ?? _strings.t("Cập nhật thiết bị"),
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

  bool _hasEnabledScheduleValue(dynamic raw) {
    if (raw is List) {
      return raw.any((item) {
        final schedule = safeMap(item);
        return schedule["enabled"] == true;
      });
    }

    if (raw is Map) {
      return raw.values.any((item) {
        final schedule = safeMap(item);
        return schedule["enabled"] == true;
      });
    }

    return false;
  }

  Future<bool> hasEnabledReminderSchedule() async {
    try {
      final isShared = homes[selectedHome]?["_shared"] == true;

      if (isShared) {
        final modeSnap = await FirebaseDatabase.instance
            .ref("accounts/$uid/customRules/$selectedHome/mode")
            .get();

        if (modeSnap.value?.toString() == "custom") {
          final customSnap = await FirebaseDatabase.instance
              .ref(
            "accounts/$uid/customRules/"
                "$selectedHome/notifications/items",
          )
              .get();

          return _hasEnabledScheduleValue(customSnap.value);
        }
      }

      final homeSnap = await FirebaseDatabase.instance
          .ref(
        "accounts/${getHomeOwnerUid()}/homes/"
            "$selectedHome/schedules/notifications",
      )
          .get();

      return _hasEnabledScheduleValue(homeSnap.value);
    } catch (_) {
      return false;
    }
  }

  String formatAlarmSchedules() {
    if (!alarmEnabled || selectedHome.isEmpty) {
      return "Tắt";
    }

    final devices = getDevices();
    final selectedRules = safeMap(customRulesByHome[selectedHome]);

    final useCustomMode = selectedRules["mode"]?.toString() == "custom";

    final customDevices = safeMap(selectedRules["devices"]);

    final intervals = <Map<String, int>>[];

    int? parseClock(dynamic raw) {
      final value = raw?.toString().trim() ?? "";
      final parts = value.split(":");

      if (parts.length != 2) {
        return null;
      }

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }

      return hour * 60 + minute;
    }

    String formatClock(int totalMinutes) {
      final normalized = ((totalMinutes % 1440) + 1440) % 1440;
      final hour = normalized ~/ 60;
      final minute = normalized % 60;

      return "${hour.toString().padLeft(2, "0")}:"
          "${minute.toString().padLeft(2, "0")}";
    }

    for (final entry in devices.entries) {
      final deviceId = entry.key.toString();
      final device = safeMap(entry.value);
      final realDeviceId = device["_deviceId"]?.toString() ?? deviceId;

      final homeAlarm = safeMap(device["alarm"]);
      final customDevice = safeMap(customDevices[realDeviceId]);
      final customAlarm = safeMap(customDevice["alarm"]);

      // Giống AlarmDeviceSheet:
      // mode Riêng tôi dùng custom nếu có,
      // nếu chưa có thì kế thừa lịch Theo nhà.
      final alarm = useCustomMode && customAlarm.isNotEmpty
          ? customAlarm
          : homeAlarm;

      if (alarm["enabled"] != true) {
        continue;
      }

      final startMinutes = parseClock(alarm["start"]);
      final endMinutes = parseClock(alarm["end"]);

      if (startMinutes == null || endMinutes == null) {
        continue;
      }

      intervals.add({"start": startMinutes, "end": endMinutes});
    }

    if (intervals.isEmpty) {
      return "Tắt";
    }

    if (intervals.length == 1) {
      final firstInterval = intervals.first;
      final start = firstInterval["start"];
      final end = firstInterval["end"];

      if (start == null || end == null) {
        return "Tắt";
      }

      return "${formatClock(start)} → ${formatClock(end)}";
    }

    // Tìm một khoảng liên tục ngắn nhất nhưng bao phủ toàn bộ
    // các lịch Alarm, kể cả lịch đi qua 00:00.
    int? bestStart;
    int? bestEnd;
    var bestSpan = 1 << 30;

    final candidateCuts = <int>{
      for (final interval in intervals)
        if (interval["start"] != null) interval["start"] as int,
      for (final interval in intervals)
        if (interval["end"] != null) interval["end"] as int,
    };

    for (final cut in candidateCuts) {
      var minStart = 1 << 30;
      var maxEnd = -(1 << 30);

      for (final interval in intervals) {
        final startMinutes = interval["start"];
        final endMinutes = interval["end"];

        if (startMinutes == null || endMinutes == null) {
          continue;
        }

        var duration = (endMinutes - startMinutes + 1440) % 1440;

        // Cùng giờ bắt đầu/kết thúc được hiểu là cả ngày.
        if (duration == 0) {
          duration = 1440;
        }

        final mappedStart = (startMinutes - cut + 1440) % 1440;
        final mappedEnd = mappedStart + duration;

        if (mappedStart < minStart) {
          minStart = mappedStart;
        }

        if (mappedEnd > maxEnd) {
          maxEnd = mappedEnd;
        }
      }

      final span = maxEnd - minStart;

      if (span < bestSpan) {
        bestSpan = span;
        bestStart = cut + minStart;
        bestEnd = cut + maxEnd;
      }
    }

    if (bestStart == null || bestEnd == null) {
      return "Tắt";
    }

    if (bestSpan >= 1440) {
      return "Cả ngày";
    }

    return "${formatClock(bestStart)} → "
        "${formatClock(bestEnd)}";
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

      updates["homeMemberContacts/$homeId/$uid/phone"] = cleanPhone;
    }

    if (updates.isEmpty) {
      return;
    }

    try {
      await FirebaseDatabase.instance.ref().update(updates);
    } catch (error) {
      debugPrint("SYNC_HOME_MEMBER_CONTACT_ERROR: $error");
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state != AppLifecycleState.resumed) {
      return;
    }

    startHubStatusGracePeriod();

    if (mounted) {
      setState(() {});
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startHubStatusGracePeriod();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    uid = currentUser.uid;

    hubStatusRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        if (!mounted || homes.isEmpty) {
          return;
        }

        setState(() {});
      },
    );

    NotificationService.chatOpenRequest.addListener(_handleChatOpenRequest);
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
      final userCustomRules = safeMap(map["customRules"]);

      setState(() {
        shareRequests = requests;
        inviteCountNotifier.value = requests.length;
        alarmSettings = userAlarmSettings;
        customRulesByHome = userCustomRules;
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
              securityMode = currentHome["securityMode"]?.toString() == "armed"
                  ? "armed"
                  : "normal";
              alarmPauseToday = safeMap(currentHome["alarmPauseToday"]);
            });

            syncHomeChatListeners();
            syncDeviceNotificationBridge();
            unawaited(
              AutoAwayService.syncForHomes(uid: uid, homes: homes).catchError((
                  Object error,
                  ) {
                debugPrint("AUTO_AWAY_SHARED_SYNC_ERROR: $error");
              }),
            );
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
        securityMode = currentHome["securityMode"]?.toString() == "armed"
            ? "armed"
            : "normal";
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
      startAlarmPauseListener();
      syncHomeChatListeners();
      syncDeviceNotificationBridge();
      unawaited(
        AutoAwayService.syncForHomes(uid: uid, homes: homes).catchError((
            Object error,
            ) {
          debugPrint("AUTO_AWAY_SYNC_ERROR: $error");
        }),
      );
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
          _strings.t("QR gia nhập nhiều nhà không hợp lệ"),
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
          _strings.t("Bạn đang là chủ các nhà này"),
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
          : myEmail ?? _strings.t("Một người dùng");

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
          title: _strings.t("Yêu cầu gia nhập nhà"),
          message: _strings.choose(
            vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
            en: "$requesterName requested to join \"$homeName\".",
          ),
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
        _strings.choose(
          vi: "Đã gửi yêu cầu gia nhập ${homeIds.length} nhà",
          en: "Join requests sent for ${homeIds.length} homes",
        ),
        color: SafeHomeColors.safe,
        icon: Icons.check_circle_rounded,
      );

      return;
    }
    if (value.startsWith("safehome_join|")) {
      final parts = value.split("|");

      if (parts.length != 3) {
        showTopToast(
          context,
          _strings.t("QR gia nhập không hợp lệ"),
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
          _strings.t("Bạn đang là chủ nhà này"),
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
          : myEmail ?? _strings.t("Một người dùng");

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
        title: _strings.t("Yêu cầu gia nhập nhà"),
        message: _strings.choose(
          vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
          en: "$requesterName requested to join \"$homeName\".",
        ),
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
        _strings.t("Đã gửi yêu cầu gia nhập nhà"),
        color: SafeHomeColors.safe,
        icon: Icons.check_circle_rounded,
      );

      return;
    }

    pairSensor(value);
    showTopToast(
      context,
      _strings.t("QR này không phải mã xin gia nhập nhà"),
      color: Colors.red,
      icon: Icons.qr_code_2_rounded,
    );
  }

  void pairSensor(String hubId) async {
    if (!canManageHome()) {
      showTopToast(
        context,
        _strings.t("Bạn không có quyền thêm thiết bị"),
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
      title: _strings.t("Đã mở chế độ thêm thiết bị"),
      message: _strings.choose(
        vi: "Chế độ thêm thiết bị đã được mở trong nhà \"$homeName\" trong 60 giây.",
        en: "Device pairing was enabled in \"$homeName\" for 60 seconds.",
      ),
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
      final ok = await showConfirmDialog(
        context,
        _strings.t("Rời khỏi Home này?"),
      );
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
                Text(
                  _strings.t("Xác nhận xoá nhà"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _strings.t(
                    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.",
                  ),
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
                        child: Text(_strings.t("Huỷ")),
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
                        child: Text(_strings.t("Tiếp tục")),
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
                Text(
                  _strings.t("Nhập mật khẩu"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _strings.t("Mật khẩu tài khoản"),
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
                    label: Text(_strings.t("Xoá nhà")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        final userEmail = user?.email;

                        if (user == null ||
                            userEmail == null ||
                            userEmail.isEmpty) {
                          if (!sheetContext.mounted) return;

                          showTopToast(
                            sheetContext,
                            _strings.t("Không tìm thấy tài khoản"),
                            color: Colors.red,
                            icon: Icons.error_outline_rounded,
                          );
                          return;
                        }

                        final credential = EmailAuthProvider.credential(
                          email: userEmail,
                          password: controller.text.trim(),
                        );

                        await user.reauthenticateWithCredential(credential);

                        if (!sheetContext.mounted) return;

                        Navigator.pop(sheetContext, true);
                      } catch (e) {
                        if (!sheetContext.mounted) return;

                        showTopToast(
                          sheetContext,
                          _strings.t("Sai mật khẩu"),
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
      title: _strings.t("Đã xoá nhà"),
      message: _strings.choose(
        vi: "Bạn đã xoá nhà \"$deletedHomeName\".",
        en: "You deleted \"$deletedHomeName\".",
      ),
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
                Text(
                  _strings.t("QR của nhà này"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                QrImageView(data: qrData, version: QrVersions.auto, size: 220),
                const SizedBox(height: 12),
                Text(
                  _strings.t(
                    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.",
                  ),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _strings.t("Chia sẻ nhà"),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: _strings.t("Email người nhận"),
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

                    Text(
                      _strings.t("Mời thành viên bằng mã QR"),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
        _strings.t("Không thể share cho chính bạn"),
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
        _strings.t("Email chưa đăng ký"),
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
      title: _strings.t("Lời mời chia sẻ nhà"),
      message: _strings.choose(
        vi: "${userName.isNotEmpty ? userName : (myEmail ?? _strings.t("Một chủ nhà"))} đã mời bạn tham gia nhà \"$homeName\".",
        en: "${userName.isNotEmpty ? userName : (myEmail ?? "A homeowner")} invited you to join \"$homeName\".",
      ),
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
      _strings.t("Đã share home"),
      color: SafeHomeColors.safe,
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
                Text(
                  _strings.t("Chuyển quyền chủ nhà"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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
                        labelText: _strings.t("Email người nhận"),
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
        _strings.t("Không thể chuyển quyền cho chính bạn"),
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
        _strings.t("Không tìm thấy user"),
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

                Text(
                  _strings.t("Xác nhận chuyển quyền"),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _strings.choose(
                    vi: "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n$targetEmail?",
                    en: "Transfer home ownership to:\n$targetEmail?",
                  ),
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
                        child: Text(_strings.t("Hủy")),
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
                        child: Text(_strings.t("Chuyển")),
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
        title: Text(_strings.t("Xác nhận mật khẩu")),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _strings.t("Mật khẩu tài khoản"),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_strings.t("Xác nhận")),
          ),
        ],
      ),
    );

    if (passwordOk != true) return;
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (user == null || userEmail == null || userEmail.isEmpty) {
      if (!mounted) return;

      showTopToast(
        context,
        _strings.t("Không tìm thấy tài khoản"),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: userEmail,
        password: passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      if (!mounted) return;

      showTopToast(
        context,
        _strings.t("Sai mật khẩu"),
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
      title: _strings.t("Yêu cầu chuyển quyền chủ nhà"),
      message: _strings.choose(
        vi: "${userName.isNotEmpty ? userName : (myEmail ?? _strings.t("Một chủ nhà"))} muốn chuyển quyền chủ nhà \"$homeName\" cho bạn.",
        en: "${userName.isNotEmpty ? userName : (myEmail ?? "A homeowner")} wants to transfer ownership of \"$homeName\" to you.",
      ),
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
      title: _strings.t("Đã gửi yêu cầu chuyển quyền"),
      message: _strings.choose(
        vi: "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"$homeName\" cho $targetEmail.",
        en: "You sent an ownership transfer request for \"$homeName\" to $targetEmail.",
      ),
      homeId: homeId,
      ownerUid: uid,
      homeName: homeName,
      entityType: "home",
      entityId: homeId,
    );

    if (!mounted) return;

    showTopToast(
      context,
      _strings.t("Đã gửi yêu cầu chuyển quyền chủ nhà"),
      color: SafeHomeColors.safe,
      icon: Icons.check_circle_rounded,
    );

    return;
  }

  void deleteDevice(String id) async {
    if (!canManageHome()) {
      showTopToast(
        context,
        _strings.t("Bạn không có quyền xoá thiết bị"),
        color: Colors.orange,
        icon: Icons.lock_rounded,
      );
      return;
    }

    if (!await showConfirmDialog(context, _strings.t("Xóa Device?"))) return;

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
        _strings.t("Đã gửi yêu cầu xoá thiết bị"),
        color: SafeHomeColors.safe,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;

      showTopToast(
        context,
        _strings.choose(
          vi: "Không gửi được yêu cầu xoá: $e",
          en: "Could not send deletion request: $e",
        ),
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
      title: _strings.t("Đang xoá thiết bị"),
      message: _strings.choose(
        vi: "SafeHome đang xoá thiết bị \"$deviceName\" khỏi nhà \"$homeName\".",
        en: "SafeHome is removing \"$deviceName\" from \"$homeName\".",
      ),
      homeName: homeName,
    );
  }

  Future<void> logout() async {
    final confirmed = await showConfirmDialog(
      context,
      _strings.t("Đăng xuất?"),
    );

    if (!confirmed || !mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);

    while (navigator.canPop()) {
      final didPop = await navigator.maybePop();

      if (!didPop) {
        break;
      }

      await WidgetsBinding.instance.endOfFrame;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null) {
      try {
        await FCMService.removeCurrentInstallationToken(uid: currentUid);
      } catch (error) {
        debugPrint("REMOVE_FCM_TOKEN_ON_LOGOUT_ERROR: $error");
      }
    }

    await AutoLoginService.clearLogin();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> showAddHomeOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget optionTile({
          required IconData icon,
          required String title,
          required String subtitle,
          required Color color,
          required String value,
        }) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: SafeHomeColors.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(sheetContext).pop(value);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: SafeHomeColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: SafeHomeColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: SafeHomeColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SafeHomeColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _strings.t("Thêm Home"),
                    style: const TextStyle(
                      color: SafeHomeColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                optionTile(
                  icon: Icons.add_home_work_rounded,
                  title: _strings.t("Tạo Home mới"),
                  subtitle: _strings.t("Tạo một ngôi nhà mới của bạn"),
                  color: SafeHomeColors.primary,
                  value: "create",
                ),
                optionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  title: _strings.t("Xin gia nhập Home"),
                  subtitle: _strings.t("Quét mã QR được chủ nhà chia sẻ"),
                  color: SafeHomeColors.info,
                  value: "join",
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == "create") {
      addHome();
      return;
    }

    if (result != "join") {
      return;
    }

    final code = await openQRScanner(context);

    if (!mounted || code == null || code.trim().isEmpty) {
      return;
    }

    final value = code.trim();

    if (!value.startsWith("safehome_join|") &&
        !value.startsWith("safehome_join_multi|")) {
      showTopToast(
        context,
        _strings.t("QR này không phải mã xin gia nhập Home"),
        color: Colors.orange,
        icon: Icons.qr_code_2_rounded,
      );
      return;
    }

    await handleScannedQR(value);
  }

  void addHome() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_strings.t("Thêm nhà mới")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: _strings.t("Tên nhà"),
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
                labelText: _strings.t("Địa chỉ"),
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
            child: Text(_strings.t("Hủy")),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                "name": nameController.text.trim(),
                "address": addressController.text.trim(),
              });
            },
            child: Text(_strings.t("OK")),
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
      title: _strings.t("Đã tạo nhà mới"),
      message: _strings.choose(
        vi: "Bạn đã tạo nhà \"$name\".",
        en: "You created the home \"$name\".",
      ),
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
                    Text(
                      _strings.t("⏸️ Tạm tắt Alarm hôm nay"),
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
                                title: _strings.t("Chọn giờ bắt đầu tạm tắt"),
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
                                  Text(_strings.t("Từ giờ")),
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
                                title: _strings.t("Chọn giờ kết thúc tạm tắt"),
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
                                  Text(_strings.t("Đến giờ")),
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
                              label: Text(_strings.t(item)),
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
                        label: Text(_strings.t("Lưu")),
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
                                _strings.choose(
                                  vi: "Khoảng thời gian phải nằm trong khung Alarm ($alarmStart → $alarmEnd)",
                                  en: "The pause period must be within the Alarm schedule ($alarmStart → $alarmEnd)",
                                ),
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
                              _strings.choose(
                                vi: "Không lưu được tạm tắt Alarm: $e",
                                en: "Unable to save the Alarm pause: $e",
                              ),
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
                          label: Text(_strings.t("Xóa lịch tạm tắt")),
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
                                _strings.choose(
                                  vi: "Không xoá được lịch tạm tắt Alarm: $e",
                                  en: "Unable to delete the Alarm pause schedule: $e",
                                ),
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
        .toString()
        : (homes[selectedHome]?["name"] ?? selectedHome).toString();

    final currentAddress = homes[selectedHome]?["address"]?.toString() ?? "";

    final nameController = TextEditingController(text: currentName);
    final addressController = TextEditingController(text: currentAddress);

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: SafeHomeColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  final nameOk = nameController.text.trim().isNotEmpty;

                  InputDecoration fieldDecoration({
                    required String label,
                    required IconData icon,
                    String? hint,
                  }) {
                    return InputDecoration(
                      labelText: label,
                      hintText: hint,
                      prefixIcon: Icon(icon, color: SafeHomeColors.primary),
                      filled: true,
                      fillColor: SafeHomeColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: SafeHomeColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: SafeHomeColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: SafeHomeColors.primary,
                          width: 1.5,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: SafeHomeColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: SafeHomeColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: SafeHomeColors.primary,
                            size: 31,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          usePersonalName
                              ? _strings.t("Đổi tên hiển thị")
                              : _strings.t("Cập nhật thông tin nhà"),
                          style: const TextStyle(
                            color: SafeHomeColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: nameController,
                          textInputAction: usePersonalName
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onChanged: (_) {
                            setSheetState(() {});
                          },
                          onSubmitted: (_) {
                            if (!usePersonalName || !nameOk) {
                              return;
                            }

                            Navigator.pop(sheetContext, {
                              "name": nameController.text.trim(),
                              "address": currentAddress,
                            });
                          },
                          decoration: fieldDecoration(
                            label: _strings.t("Tên nhà"),
                            icon: Icons.home_outlined,
                          ),
                        ),
                        if (!usePersonalName) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: addressController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            maxLines: 2,
                            minLines: 1,
                            onSubmitted: (_) {
                              if (!nameOk) {
                                return;
                              }

                              Navigator.pop(sheetContext, {
                                "name": nameController.text.trim(),
                                "address": addressController.text.trim(),
                              });
                            },
                            decoration: fieldDecoration(
                              label: _strings.t("Địa chỉ"),
                              icon: Icons.location_on_outlined,
                              hint: _strings.t("Nhập địa chỉ của nhà"),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: nameOk
                                ? () {
                              Navigator.pop(sheetContext, {
                                "name": nameController.text.trim(),
                                "address": usePersonalName
                                    ? currentAddress
                                    : addressController.text.trim(),
                              });
                            }
                                : null,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(
                              _strings.t("Lưu thay đổi"),
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: SafeHomeColors.primary,
                              disabledBackgroundColor: SafeHomeColors.border,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          usePersonalName
                              ? _strings.t(
                            "Tên này chỉ hiển thị riêng trên tài khoản của bạn.",
                          )
                              : _strings.t(
                            "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.",
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SafeHomeColors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    // Bottom sheet vẫn đang chạy animation đóng sau khi
    // Navigator.pop() trả kết quả. Không dispose controller ngay,
    // nếu không TextField có thể đọc controller đã dispose và gây
    // màn hình đỏ.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      nameController.dispose();
      addressController.dispose();
    });

    if (result == null) {
      return;
    }

    final newName = result["name"]?.trim() ?? "";
    final newAddress = result["address"]?.trim() ?? "";

    if (newName.isEmpty) {
      return;
    }

    if (usePersonalName) {
      if (newName == currentName.trim()) {
        return;
      }

      await FirebaseDatabase.instance
          .ref("${FirebasePaths.sharedHome(uid, selectedHome)}/customName")
          .set(newName);

      if (mounted) {
        setState(() {
          homes[selectedHome]?["_customName"] = newName;
        });
      }

      return;
    }

    final oldName =
        homes[selectedHome]?["name"]?.toString().trim() ?? selectedHome;
    final oldAddress = homes[selectedHome]?["address"]?.toString().trim() ?? "";

    final nameChanged = newName != oldName;
    final addressChanged = newAddress != oldAddress;

    if (!nameChanged && !addressChanged) {
      return;
    }

    final ownerUid = getHomeOwnerUid();

    if (nameChanged) {
      await HomeService.renameHome(
        ownerUid: ownerUid,
        homeId: selectedHome,
        name: newName,
      );
    }

    if (addressChanged) {
      await FirebaseDatabase.instance
          .ref("accounts/$ownerUid/homes/$selectedHome/address")
          .set(newAddress);
    }

    if (isShared && nameChanged) {
      await FirebaseDatabase.instance
          .ref("${FirebasePaths.sharedHome(uid, selectedHome)}/customName")
          .remove();
    }

    if (mounted) {
      setState(() {
        homes[selectedHome]?["name"] = newName;
        homes[selectedHome]?["address"] = newAddress;

        if (nameChanged) {
          homes[selectedHome]?.remove("_customName");
        }
      });
    }

    final actorName = userName.trim().isNotEmpty
        ? userName.trim()
        : _strings.t("Một thành viên");

    String message;

    if (nameChanged && addressChanged) {
      message = _strings.choose(
        vi: "$actorName đã cập nhật tên nhà thành \"$newName\" và thay đổi địa chỉ.",
        en: "$actorName updated the home name to \"$newName\" and changed its address.",
      );
    } else if (nameChanged) {
      message = _strings.choose(
        vi: "$actorName đã đổi tên nhà thành \"$newName\".",
        en: "$actorName renamed the home to \"$newName\".",
      );
    } else {
      message = _strings.choose(
        vi: "$actorName đã cập nhật địa chỉ của nhà \"$newName\".",
        en: "$actorName updated the address of \"$newName\".",
      );
    }

    await HomeNotificationService.notifyHome(
      ownerUid: ownerUid,
      homeId: selectedHome,
      type: "home_updated",
      category: "home",
      severity: "info",
      title: _strings.t("Đã cập nhật thông tin nhà"),
      message: message,
      entityType: "home",
      entityId: selectedHome,
      homeName: newName,
      includeActor: true,
      data: {
        "actorName": actorName,
        "oldName": oldName,
        "newName": newName,
        "oldAddress": oldAddress,
        "newAddress": newAddress,
      },
    );
  }

  void renameDevice(String id) async {
    final oldDeviceName = getDevices()[id]?["name"]?.toString() ?? id;
    final controller = TextEditingController(text: oldDeviceName);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_strings.t("Thay tên")),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_strings.t("Hủy")),
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
    final emailName =
        FirebaseAuth.instance.currentUser?.email?.split("@").first.trim() ?? "";
    final actorName = userName.trim().isNotEmpty
        ? userName.trim()
        : emailName.isNotEmpty
        ? emailName
        : _strings.t("Một thành viên");

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
      title: _strings.t("Đã đổi tên thiết bị"),
      message: _strings.choose(
        vi: "$actorName đã đổi tên thiết bị \"$oldDeviceName\" thành \"$newName\" trong nhà \"$homeName\".",
        en: "$actorName renamed device \"$oldDeviceName\" to \"$newName\" in \"$homeName\".",
      ),
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
        _strings.t("Chưa chọn nhà để kiểm tra"),
        color: Colors.orange,
        icon: Icons.home_work_outlined,
      );
      return;
    }

    if (!isOwner()) {
      showTopToast(
        context,
        _strings.t("Hãy thực hiện kiểm tra bằng tài khoản Owner"),
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
        _strings.t("Không đọc được dữ liệu nhà"),
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final homeData = Map<String, dynamic>.from(homeSnap.value as Map);

    final rawDevices = homeData["devices"];

    if (rawDevices is! Map || rawDevices.isEmpty) {
      if (!mounted) return;

      showTopToast(
        context,
        _strings.t("Nhà cần có ít nhất một thiết bị để test"),
        color: Colors.orange,
        icon: Icons.sensors_off_rounded,
      );
      return;
    }

    final devices = Map<String, dynamic>.from(rawDevices);
    final firstDeviceEntry = devices.entries.first;

    final deviceId = firstDeviceEntry.key.toString();
    final deviceData = firstDeviceEntry.value is Map
        ? Map<String, dynamic>.from(firstDeviceEntry.value as Map)
        : <String, dynamic>{};

    final deviceRef = homeRef.child("devices/$deviceId");

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
            results[label] = "FAIL — ghi được, cleanup lỗi: $error";
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

    final testId = DateTime.now().millisecondsSinceEpoch.toString();

    // 1. Không được ghi trực tiếp _ownerUid.
    await expectDenied(
      label: "_ownerUid",
      action: () async {
        await homeRef.child("_ownerUid").set(ownerUid);
      },
    );

    // 2. Không được tạo event trực tiếp từ client.
    final eventTestRef = homeRef.child("events/security_test_$testId");

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
        await homeRef.child("alarmPauseToday").set(pauseTestValue);
      },
      cleanup: pauseExists
          ? null
          : () async {
        await homeRef.child("alarmPauseToday").remove();
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
          deviceData.containsKey(field) && deviceData[field] != null;

      final testValue = fieldExists ? deviceData[field] : entry.value;

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
    final deviceRootTestData = Map<String, dynamic>.from(deviceData);

    deviceRootTestData["_securityTest"] = testId;

    await expectDenied(
      label: "device root / delete gate",
      action: () async {
        await deviceRef.set(deviceRootTestData);
      },
      cleanup: () async {
        await deviceRef.child("_securityTest").remove();
      },
    );

    if (!mounted) return;

    final passCount = results.values.where((value) => value == "PASS").length;

    final lines = results.entries
        .map((entry) {
      final icon = entry.value == "PASS" ? "✅" : "❌";

      return "$icon ${entry.key}: ${entry.value}";
    })
        .join("\n\n");

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            passCount == results.length
                ? _strings.t("Firebase Rules: ĐẠT")
                : _strings.t("Firebase Rules: CÓ LỖI"),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                _strings.choose(
                  vi: "$passCount/${results.length} bài test đạt\n\n",
                  en: "$passCount/${results.length} tests passed\n\n",
                ) +
                    "$lines",
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(_strings.t("Đóng")),
            ),
          ],
        );
      },
    );
  }

  Color getHomeColor(String h) {
    final home = safeMap(homes[h]);
    final overall = getHomeOverallStatus(home);

    final level = overall["level"]?.toString() ?? "safe";
    final selected = h == selectedHome;

    if (level == "danger") {
      return SafeHomeColors.danger;
    }

    if (level == "warning") {
      return SafeHomeColors.warning;
    }

    return selected ? SafeHomeColors.primary : SafeHomeColors.safe;
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
                              final selected = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AllHomePage(homeOrder: homeOrder),
                                ),
                              );

                              if (selected == null) return;

                              setState(() {
                                selectedHome = selected;
                              });

                              final index = homeOrder.indexOf(selected);

                              if (index != -1 && homeTabController.hasClients) {
                                homeTabController.animateTo(
                                  index * 110,
                                  duration: const Duration(milliseconds: 300),
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
                                borderRadius: BorderRadius.circular(11),
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
                              style: TextStyle(color: SafeHomeColors.primary),
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
                                  homeNameForId: getHomeDisplayName,
                                  onTapNotification: openHomeNotificationTarget,
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              tooltip: _strings.t("Thông báo Home"),
                              icon: const Icon(
                                Icons.notifications_rounded,
                                size: 21,
                              ),
                              style: IconButton.styleFrom(
                                foregroundColor: SafeHomeColors.info,
                                backgroundColor: Colors.transparent,
                                shape: const CircleBorder(),
                              ).copyWith(
                                overlayColor: WidgetStatePropertyAll(
                                  SafeHomeColors.info.withValues(alpha: 0.10),
                                ),
                              ),
                            ),
                            if (unreadHomeNotificationCount > 0)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 17,
                                    minHeight: 17,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
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
                                    unreadHomeNotificationCount > 99
                                        ? "99+"
                                        : unreadHomeNotificationCount
                                        .toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
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
                  currentUserName: userName,
                  currentUserEmail:
                  FirebaseAuth.instance.currentUser?.email ?? "",
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
                      alarmPauseToday = safeMap(currentHome["alarmPauseToday"]);
                    });

                    startHomeEventsListener();
                    startAlarmPauseListener();
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
                      securityMode: securityMode,
                      header: Column(
                        children: [
                          StatusPanel(
                            alarmPauseText: (() {
                              if (alarmPauseToday.isEmpty) {
                                return "Tắt";
                              }

                              final now = DateTime.now();

                              final today =
                                  "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

                              if (alarmPauseToday["date"] != today) {
                                return "Tắt";
                              }

                              final startText =
                                  alarmPauseToday["start"]?.toString().trim() ??
                                      "";
                              final endText =
                                  alarmPauseToday["end"]?.toString().trim() ??
                                      "";

                              if (startText.isEmpty || endText.isEmpty) {
                                return "Tắt";
                              }

                              return "$startText → $endText";
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
                            overall: getHomeOverallStatus(
                              safeMap(homes[selectedHome]),
                            ),

                            securityMode: securityMode,
                            onSecurityModeChanged: canManageHome()
                                ? setSecurityMode
                                : null,

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
                                _strings.t("Nhà"),
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
                                  _strings.t(
                                    "Bạn không có quyền sắp xếp phòng",
                                  ),
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
                              child: Text(
                                _strings.choose(
                                  vi: "Đang ghép nối: $pairingCountdown giây",
                                  en: "Pairing: $pairingCountdown s",
                                ),
                              ),
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
                            _strings.t("Bạn không có quyền thêm thiết bị"),
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
                                    Text(
                                      _strings.t("Quét QR"),
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
                                        label: Text(
                                          _strings.t(
                                            "Quét QR để thêm thiết bị",
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context, "__SCAN__");
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton.icon(
                                      icon: const Icon(Icons.keyboard),
                                      label: Text(
                                        _strings.t("Nhập HUB ID thủ công"),
                                      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: SafeHomeColors.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SafeHomeColors.border, width: 0.9),
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
                  tooltip: _strings.t("Thêm Home"),
                  icon: const Icon(
                    Icons.add_home_work_rounded,
                    color: SafeHomeColors.primary,
                  ),
                  onPressed: showAddHomeOptions,
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
                  onPressed: () async {
                    final reminderEnabled = await hasEnabledReminderSchedule();

                    if (!mounted) return;

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
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: SafeHomeColors.border,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.crisis_alert_rounded,
                                        color: localAlarmEnabled
                                            ? SafeHomeColors.primary
                                            : SafeHomeColors.textSecondary
                                            .withValues(alpha: 0.45),
                                      ),
                                      title: Text(
                                        _strings.t("Hẹn giờ Alarm"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: localAlarmEnabled
                                              ? SafeHomeColors.textPrimary
                                              : SafeHomeColors.textSecondary
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      subtitle: Text(
                                        localAlarmEnabled
                                            ? (formatAlarmSchedules()
                                            .trim()
                                            .isEmpty
                                            ? _strings.t(
                                          "Chưa thiết lập thời gian",
                                        )
                                            : formatAlarmSchedules())
                                            : _strings.t("Đang tắt"),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: localAlarmEnabled
                                              ? SafeHomeColors.textSecondary
                                              : SafeHomeColors.textSecondary
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      trailing: Switch(
                                        value: localAlarmEnabled,
                                        activeThumbColor:
                                        SafeHomeColors.primary,
                                        activeTrackColor: SafeHomeColors.primary
                                            .withValues(alpha: 0.28),
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
                                    ListTile(
                                      leading: Icon(
                                        Icons.pause_circle_filled_rounded,
                                        color: alarmPauseToday.isNotEmpty
                                            ? SafeHomeColors.warning
                                            : SafeHomeColors.textSecondary
                                            .withValues(alpha: 0.45),
                                      ),
                                      title: Text(
                                        _strings.t("Tạm tắt Alarm hôm nay"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: alarmPauseToday.isNotEmpty
                                              ? SafeHomeColors.textPrimary
                                              : SafeHomeColors.textSecondary
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      subtitle: Text(
                                        alarmPauseToday.isEmpty
                                            ? _strings.t("Chưa thiết lập")
                                            : "${alarmPauseToday["start"] ?? "--:--"} → ${alarmPauseToday["end"] ?? "--:--"}"
                                            "${(alarmPauseToday["reason"] ?? "").toString().isNotEmpty ? " • ${_strings.t(alarmPauseToday["reason"].toString())}" : ""}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: alarmPauseToday.isNotEmpty
                                              ? SafeHomeColors.textSecondary
                                              : SafeHomeColors.textSecondary
                                              .withValues(alpha: 0.45),
                                        ),
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
                                      leading: Icon(
                                        Icons.notifications_active_rounded,
                                        color: reminderEnabled
                                            ? SafeHomeColors.primary
                                            : SafeHomeColors.textSecondary
                                            .withValues(alpha: 0.45),
                                      ),
                                      title: Text(
                                        _strings.t("Hẹn giờ Reminder"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: reminderEnabled
                                              ? SafeHomeColors.textPrimary
                                              : SafeHomeColors.textSecondary
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      subtitle: Text(
                                        reminderEnabled
                                            ? _strings.t("Đã thiết lập")
                                            : _strings.t("Chưa thiết lập"),
                                        style: TextStyle(
                                          color: reminderEnabled
                                              ? SafeHomeColors.textSecondary
                                              : SafeHomeColors.textSecondary
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
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
                                _strings.t("Không có thiết bị"),
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
                              _strings.t("Chỉ chủ nhà mới được xoá nhà"),
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
                              _strings.t(
                                "Chỉ chủ nhà mới được chuyển quyền",
                              ),
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
                          onAutoAway: openAutoAwaySetup,
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
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.chatOpenRequest.removeListener(_handleChatOpenRequest);
    timer?.cancel();
    hubStatusRefreshTimer?.cancel();
    accountSubscription?.cancel();
    notificationSubscription?.cancel();
    homeEventsSubscription?.cancel();
    alarmPauseSubscription?.cancel();
    for (final subscription in homeChatSubscriptions.values) {
      subscription.cancel();
    }
    homeChatSubscriptions.clear();
    homeTabController.dispose();
    super.dispose();
  }
}
