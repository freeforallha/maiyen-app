import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../helpers/firebase_paths.dart';

import '../helpers/home_helper.dart';
import '../services/fcm_service.dart';
import '../services/firebase_security_test_service.dart';
import '../services/home_account_realtime_coordinator.dart';
import '../services/home_alarm_security_service.dart';
import '../services/home_auto_away_coordinator.dart';
import '../services/home_listener_service.dart';
import '../services/home_pairing_service.dart';
import '../services/home_realtime_coordinator.dart';
import '../services/home_selection_state_service.dart';
import '../services/home_service.dart';
import '../services/home_state_parser.dart';
import '../services/share_service.dart';
import '../services/notification_service.dart';
import '../widgets/home_tabs.dart';
import '../widgets/device_list.dart';
import 'all_home_page.dart';
import 'home/home_add_sheets.dart';
import 'home/home_alarm_menu_sheet.dart';
import 'home/home_alarm_pause_sheet.dart';
import 'home/home_auto_away_sheet.dart';
import 'home/home_alarm_formatters.dart';
import 'home/home_bottom_bar.dart';
import 'home/home_data_helpers.dart';
import 'home/home_delete_sheets.dart';
import 'home/home_dialogs.dart';
import 'home/home_header_bar.dart';
import 'home/home_management_sheets.dart';
import 'home/home_overview_header.dart';
import 'home/home_pair_sensor_sheet.dart';
import 'home/home_transfer_owner_sheets.dart';
import 'home/home_ui_coordinator.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/pair_dialog.dart';
import 'qr_scan_page.dart';
import '../helpers/top_toast.dart';
import '../services/home_notification_service.dart';
import '../services/auto_away_service.dart';
import '../services/session_logout_service.dart';
import '../safehome_theme.dart';
import '../localization/app_strings.dart';
import 'package:safehome_app/helpers/debug_log.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AppStrings get _strings => AppStrings.of(context);
  Map<String, dynamic> shareRequests = {};
  final ValueNotifier<int> inviteCountNotifier = ValueNotifier(0);
  int unreadChatCount = 0;
  Map<String, int> unreadChatByHome = {};
  int unreadHomeNotificationCount = 0;
  Map<String, String>? _pendingChatOpenRequest;
  bool _openingChatFromNotification = false;
  void openNotificationList(String deviceId) {
    HomeUiCoordinator.openDeviceNotificationList(
      context: context,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      deviceId: deviceId,
    );
  }

  void openDeviceDetailSheet({
    required String deviceId,
    required Map<String, dynamic> device,
  }) {
    HomeUiCoordinator.openDeviceDetail(
      context: context,
      deviceId: deviceId,
      device: device,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      onRename: canManageHome() ? () => renameDevice(deviceId) : null,
      onDelete: canManageHome() ? () => deleteDevice(deviceId) : null,
      onNotification: () => openNotificationList(deviceId),
    );
  }

  void openSelectedDeviceDetail(String deviceId) {
    openDeviceDetailSheet(
      deviceId: deviceId,
      device: safeMap(getDevices()[deviceId]),
    );
  }

  void openHomeChatSheetFor({
    required String homeId,
    required String homeName,
  }) {
    HomeUiCoordinator.openChat(
      context: context,
      homeId: homeId,
      homeName: homeName,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      ownerUid: getHomeOwnerUid(),
      canManageMembers: canManageHome(),
      isOwner: isOwner(),
    );
  }

  String uid = "";
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

      securityMode = currentHome["securityMode"]?.toString() == "armed"
          ? "armed"
          : "normal";

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

    openDeviceDetailSheet(deviceId: deviceId, device: device);
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

    openHomeChatSheetFor(homeId: homeId, homeName: getHomeDisplayName(homeId));

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
      openHomeChatSheetFor(
        homeId: selectedHome,
        homeName: getSelectedHomeDisplayName(),
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
  final HomeListenerService _homeListenerService = HomeListenerService();
  final HomeAccountRealtimeCoordinator _homeAccountRealtimeCoordinator =
      HomeAccountRealtimeCoordinator();
  final HomeAlarmSecurityService _homeAlarmSecurityService =
      HomeAlarmSecurityService();
  final HomeAutoAwayCoordinator _homeAutoAwayCoordinator =
      HomeAutoAwayCoordinator();
  final HomePairingService _homePairingService = HomePairingService();
  final HomeRealtimeCoordinator _homeRealtimeCoordinator =
      HomeRealtimeCoordinator();
  final HomeSelectionStateService _homeSelectionStateService =
      HomeSelectionStateService();
  final Set<String> _ownedHomeIds = <String>{};
  Map<String, dynamic> _sharedHomesSnapshot = {};
  Object? _savedHomeOrder;

  String selectedHome = "";
  String selectedRoomId = "overview";
  Map<String, dynamic> alarmSettings = {};
  Map<String, dynamic> customRulesByHome = {};
  Map<String, dynamic> homeEvents = {};

  Map<String, dynamic> alarmPauseToday = {};
  List<String> homeOrder = [];

  List<String> mergeVisibleHomeOrder(List<String> visibleOrder) {
    return HomeDataHelpers.mergeVisibleHomeOrder(
      visibleOrder: visibleOrder,
      homeOrder: homeOrder,
      homes: homes,
    );
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

  Future<String?> openTimeTextInput({
    required BuildContext context,
    required String title,
    required String initial,
  }) async {
    return showHomeTimeTextInputDialog(
      context: context,
      strings: _strings,
      title: title,
      initial: initial,
    );
  }

  Map<String, String> getHomeAlarmReminderInfo() {
    return HomeAlarmFormatters.getHomeAlarmReminderInfo(
      customRulesByHome: customRulesByHome,
      selectedHome: selectedHome,
      devices: getDevices(),
      start: start,
      end: end,
    );
  }

  Future<void> showAlarmReceiveReminder() async {
    var useCustomMode =
        safeMap(customRulesByHome[selectedHome])["mode"]?.toString() ==
        "custom";

    try {
      final modeSnapshot = await FirebaseDatabase.instance
          .ref(
            "accounts/$uid/customRules/"
            "$selectedHome/mode",
          )
          .get();

      useCustomMode = modeSnapshot.value?.toString() == "custom";
    } catch (error) {
      safeDebugPrint("READ_ALARM_MODE_FOR_REMINDER_ERROR: $error");
    }

    if (!mounted) {
      return;
    }

    await showAlarmReceiveReminderDialog(
      context: context,
      strings: _strings,
      useCustomMode: useCustomMode,
    );
  }

  Future<bool> confirmDisableAlarm() async {
    return showConfirmDisableAlarmDialog(context: context, strings: _strings);
  }

  Future<void> showAlarmPauseReminder() async {
    await showAlarmPauseReminderDialog(context: context, strings: _strings);
  }

  Future<void> openAlarmPauseSheetWithReminder() async {
    await showAlarmPauseReminder();

    if (!mounted) return;

    showAlarmPauseSheet();
  }

  String securityMode = "normal";

  bool get isArmedMode => securityMode == "armed";
  bool alarmEnabled = false;
  Future<bool> _confirmManualSecurityMode() async {
    return showConfirmManualSecurityModeDialog(
      context: context,
      strings: _strings,
    );
  }

  Future<bool> _reauthenticateForManualSecurityMode() async {
    var enteredPassword = "";
    var obscurePassword = true;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void submitPassword() {
              final cleanPassword = enteredPassword.trim();

              if (cleanPassword.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(cleanPassword);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(_strings.t("Xác nhận mật khẩu")),
              content: TextField(
                autofocus: true,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  enteredPassword = value;
                },
                onSubmitted: (_) {
                  submitPassword();
                },
                decoration: InputDecoration(
                  labelText: _strings.t("Mật khẩu tài khoản"),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(_strings.t("Huỷ")),
                ),
                FilledButton(
                  onPressed: submitPassword,
                  child: Text(_strings.t("Xác nhận")),
                ),
              ],
            );
          },
        );
      },
    );

    if (password == null || password.isEmpty) {
      return false;
    }

    final result = await _homeAlarmSecurityService
        .reauthenticateForManualSecurityMode(password: password);

    if (!mounted) {
      return false;
    }

    switch (result.status) {
      case HomeSecurityReauthStatus.success:
        return true;
      case HomeSecurityReauthStatus.cancelled:
        return false;
      case HomeSecurityReauthStatus.currentUserUnavailable:
        showTopToast(
          context,
          "Không thể xác nhận tài khoản hiện tại",
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return false;
      case HomeSecurityReauthStatus.wrongPassword:
        showTopToast(
          context,
          "Mật khẩu không đúng",
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return false;
      case HomeSecurityReauthStatus.failed:
        showTopToast(
          context,
          "Không thể xác nhận mật khẩu",
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );

        return false;
    }
  }

  int _normalizeSecurityModeRepeatMinutes(dynamic value) {
    return _homeAlarmSecurityService.normalizeSecurityModeRepeatMinutes(value);
  }

  Future<bool> setSecurityModeRepeatMinutes(int minutes) async {
    final homeId = selectedHome;
    final result = await _homeAlarmSecurityService.setSecurityModeRepeatMinutes(
      ownerUid: homeId.isEmpty ? "" : getHomeOwnerUid(),
      homeId: homeId,
      canManageHome: canManageHome(),
      minutes: minutes,
    );

    if (!mounted) {
      return result.status == HomeSecurityRepeatStatus.saved;
    }

    switch (result.status) {
      case HomeSecurityRepeatStatus.homeUnavailable:
        return false;
      case HomeSecurityRepeatStatus.noPermission:
        showTopToast(
          context,
          "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động",
          color: Colors.orange,
          icon: Icons.lock_outline_rounded,
        );
        return false;
      case HomeSecurityRepeatStatus.failed:
        if (mounted) {
          showTopToast(
            context,
            "Không lưu được thời gian lặp báo động",
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
        }
        return false;
      case HomeSecurityRepeatStatus.saved:
        if (!mounted) {
          return true;
        }

        final normalized = result.normalizedMinutes;

        setState(() {
          final cachedHome = safeMap(homes[homeId]);
          cachedHome["securityModeRepeatMinutes"] = normalized;
          homes[homeId] = cachedHome;
        });

        showTopToast(
          context,
          normalized == 0
              ? "Mode Bảo vệ sẽ chỉ báo động một lần"
              : "Mode Bảo vệ sẽ lặp báo động sau $normalized phút",
          color: SafeHomeColors.primary,
          icon: Icons.repeat_rounded,
        );

        return true;
    }
  }

  Future<void> setSecurityMode(String mode) async {
    final homeId = selectedHome;
    final currentHome = safeMap(homes[homeId]);
    final plan = _homeAlarmSecurityService.planSecurityModeChange(
      homeId: homeId,
      canManageHome: canManageHome(),
      mode: mode,
      currentHome: currentHome,
    );

    switch (plan.status) {
      case HomeSecurityModePlanStatus.homeUnavailable:
      case HomeSecurityModePlanStatus.unchanged:
        return;
      case HomeSecurityModePlanStatus.noPermission:
        showTopToast(
          context,
          "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ",
          color: Colors.orange,
          icon: Icons.lock_outline_rounded,
        );
        return;
      case HomeSecurityModePlanStatus.requiresManualConfirmation:
        final confirmed = await _confirmManualSecurityMode();

        if (!confirmed || !mounted) {
          return;
        }

        // Đợi dialog cảnh báo đóng hoàn toàn rồi mới mở dialog mật khẩu.
        await WidgetsBinding.instance.endOfFrame;

        if (!mounted) {
          return;
        }

        final passwordConfirmed = await _reauthenticateForManualSecurityMode();

        if (!passwordConfirmed || !mounted) {
          return;
        }
        break;
      case HomeSecurityModePlanStatus.ready:
        break;
    }

    final nextMode = plan.nextMode;

    if (nextMode == "normal" &&
        safeMap(currentHome["autoAway"])["enabled"] == true) {
      final confirmed = await showConfirmNormalModeWithAutoAwayDialog(
        context: context,
        strings: _strings,
      );

      if (!confirmed || !mounted) {
        return;
      }
    }

    final ownerUid = getHomeOwnerUid();
    final homeName = getHomeDisplayName(homeId);
    final actorName = userName.trim().isNotEmpty
        ? userName.trim()
        : FirebaseAuth.instance.currentUser?.email?.trim() ?? "Một thành viên";

    final saveResult = await _homeAlarmSecurityService.setSecurityMode(
      ownerUid: ownerUid,
      homeId: homeId,
      nextMode: nextMode,
    );

    if (!mounted) {
      return;
    }

    if (saveResult.status == HomeSecurityModeSaveStatus.failed) {
      showTopToast(
        context,
        "Không thể thay đổi chế độ nhà",
        color: Colors.red,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() {
      securityMode = nextMode;

      final cachedHome = safeMap(homes[homeId]);
      cachedHome["securityMode"] = nextMode;

      if (nextMode == "armed") {
        cachedHome["securityModeSource"] = "manual";
      } else {
        cachedHome.remove("securityModeSource");
      }

      homes[homeId] = cachedHome;
    });

    if (nextMode == "armed") {
      final notificationStatus = await _homeAlarmSecurityService
          .notifyManualSecurityModeEnabled(
            ownerUid: ownerUid,
            homeId: homeId,
            homeName: homeName,
            actorUid: uid,
            actorName: actorName,
            securityModeRepeatMinutes: plan.repeatMinutes,
          );

      if (notificationStatus == HomeSecurityNotificationStatus.failed) {
        if (mounted) {
          showTopToast(
            context,
            "Đã bật Bảo vệ nhưng chưa gửi được thông báo",
            color: Colors.orange,
            icon: Icons.notifications_off_outlined,
          );
        }

        return;
      }

      if (mounted) {
        showTopToast(
          context,
          "Đã bật Mode Bảo vệ thủ công",
          color: SafeHomeColors.danger,
          icon: Icons.shield_rounded,
        );
      }

      return;
    }

    if (mounted) {
      showTopToast(
        context,
        "Đã chuyển nhà về Bình thường",
        color: SafeHomeColors.safe,
        icon: Icons.home_rounded,
      );
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

    const radiusMeters = 150;

    await showHomeAutoAwaySheet(
      context: context,
      strings: _strings,
      initialEnabled: currentAutoAway["enabled"] == true,
      initialLatitude: readDouble(currentAutoAway["latitude"]),
      initialLongitude: readDouble(currentAutoAway["longitude"]),
      radiusMeters: radiusMeters,
      onCaptureLocation: () async {
        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();

          if (!serviceEnabled) {
            if (!mounted) {
              return null;
            }

            showTopToast(
              context,
              _strings.t("Hãy bật GPS để đặt vị trí nhà"),
              color: Colors.orange,
              icon: Icons.location_off_rounded,
            );

            await Geolocator.openLocationSettings();
            return null;
          }

          var permission = await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.denied) {
            if (!mounted) {
              return null;
            }

            showTopToast(
              context,
              _strings.t("Bạn chưa cấp quyền vị trí"),
              color: Colors.orange,
              icon: Icons.location_disabled_rounded,
            );
            return null;
          }

          if (permission == LocationPermission.deniedForever) {
            if (!mounted) {
              return null;
            }

            showTopToast(
              context,
              _strings.t("Hãy cấp quyền vị trí trong Cài đặt ứng dụng"),
              color: Colors.orange,
              icon: Icons.settings_rounded,
            );

            await Geolocator.openAppSettings();
            return null;
          }

          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            ),
          );

          if (!mounted) {
            return null;
          }

          return HomeAutoAwayLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        } catch (error) {
          if (!mounted) {
            return null;
          }

          showTopToast(
            context,
            _strings.sanitizeUserMessage(
              error.toString(),
              fallback: _strings.choose(
                vi: "Không lấy được vị trí hiện tại",
                en: "Could not get the current location",
                zh: "无法获取当前位置",
                ko: "현재 위치를 가져올 수 없습니다",
                ja: "現在地を取得できません",
              ),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return null;
        }
      },
      onSave: (data) async {
        if (data.enabled) {
          final hasBackgroundPermission =
              await AutoAwayService.ensureBackgroundPermission();

          if (!hasBackgroundPermission) {
            if (!mounted) {
              return false;
            }

            showTopToast(
              context,
              _strings.t(
                "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng",
              ),
              color: Colors.orange,
              icon: Icons.location_disabled_rounded,
            );

            await Geolocator.openAppSettings();
            return false;
          }
        }

        final hasLocation = data.latitude != null && data.longitude != null;
        final autoAwayData = <String, Object?>{
          "enabled": data.enabled,
          "radiusMeters": data.radiusMeters,
          "updatedAt": DateTime.now().millisecondsSinceEpoch,
          "updatedBy": uid,
        };

        if (hasLocation) {
          autoAwayData["latitude"] = data.latitude;
          autoAwayData["longitude"] = data.longitude;
        }

        try {
          await FirebaseDatabase.instance
              .ref("accounts/$ownerUid/homes/$homeId/autoAway")
              .set(autoAwayData);

          if (!mounted) {
            return false;
          }

          setState(() {
            final cachedHome = safeMap(homes[homeId]);
            cachedHome["autoAway"] = Map<String, Object?>.from(autoAwayData);
            homes[homeId] = cachedHome;
          });

          unawaited(
            AutoAwayService.syncForHomes(
              uid: uid,
              homes: homes,
              force: true,
            ).catchError((Object error) {
              safeDebugPrint("AUTO_AWAY_SYNC_AFTER_SAVE_ERROR: $error");
            }),
          );
          unawaited(_syncAutoAwayLocationMonitoring());

          unawaited(
            Future<void>.delayed(Duration.zero, () {
              if (!mounted || !pageContext.mounted) {
                return;
              }

              showTopToast(
                pageContext,
                data.enabled
                    ? _strings.t("Đã bật tự động Bảo vệ khi mọi người rời nhà")
                    : _strings.t("Đã tắt tự động Bảo vệ khi mọi người rời nhà"),
                color: SafeHomeColors.safe,
                icon: Icons.check_circle_rounded,
              );
            }),
          );
          return true;
        } catch (error) {
          if (!mounted) {
            return false;
          }

          showTopToast(
            context,
            _strings.sanitizeUserMessage(
              error.toString(),
              fallback: _strings.choose(
                vi: "Không lưu được cài đặt",
                en: "Could not save the setting",
                zh: "无法保存设置",
                ko: "설정을 저장할 수 없습니다",
                ja: "設定を保存できません",
              ),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        }
      },
    );
  }

  Future<bool> setAlarmEnabled(bool enabled) async {
    final homeId = selectedHome;
    final plan = _homeAlarmSecurityService.planAlarmEnabled(
      homeId: homeId,
      currentEnabled: alarmEnabled,
      nextEnabled: enabled,
    );

    switch (plan.status) {
      case HomeAlarmTogglePlanStatus.homeUnavailable:
        return false;
      case HomeAlarmTogglePlanStatus.unchanged:
        return true;
      case HomeAlarmTogglePlanStatus.requiresDisableConfirmation:
        final confirmed = await confirmDisableAlarm();

        if (!confirmed || !mounted) {
          return false;
        }
        break;
      case HomeAlarmTogglePlanStatus.ready:
        break;
    }

    final homeName = getHomeDisplayName(homeId);
    final result = await _homeAlarmSecurityService.setAlarmEnabled(
      uid: uid,
      homeId: homeId,
      enabled: enabled,
    );

    if (!mounted) {
      return result.status == HomeAlarmToggleSaveStatus.saved;
    }

    if (result.status == HomeAlarmToggleSaveStatus.failed) {
      if (mounted) {
        showTopToast(
          context,
          _strings.t("Không thể thay đổi trạng thái Alarm"),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
      }

      return false;
    }

    if (!mounted) {
      return true;
    }

    setState(() {
      alarmEnabled = enabled;
      alarmSettings[homeId] = {"enabled": enabled};
    });

    unawaited(
      _homeAlarmSecurityService
          .recordAlarmEnabledNotification(
            uid: uid,
            homeId: homeId,
            homeName: homeName,
            enabled: enabled,
            strings: _strings,
          )
          .catchError((Object error) {
            safeDebugPrint("ALARM_SETTING_NOTIFICATION_ERROR: $error");
          }),
    );

    if (enabled) {
      await showAlarmReceiveReminder();
    } else if (mounted) {
      showTopToast(
        context,
        _strings.t("Đã tắt toàn bộ Alarm của nhà"),
        color: SafeHomeColors.warning,
        icon: Icons.notifications_off_rounded,
      );
    }

    return true;
  }

  int pairingCountdown = 0;
  Timer? timer;

  // Firebase không phát sự kiện chỉ vì thời gian trôi qua.
  // Timer này buộc UI đánh giá lại tuổi heartbeat khi app đang mở.
  Timer? hubStatusRefreshTimer;
  // Android dùng foreground task độc lập để heartbeat vẫn chạy
  // khi app ở nền, tắt màn hình hoặc bị vuốt khỏi Recent Apps.
  // Các nền tảng khác giữ timer cũ.

  // ignore: unused_element
  bool _hasEnabledAutoAwayHome() {
    return _homeAutoAwayCoordinator.hasEnabledAutoAwayHome(homes);
  }

  // ignore: unused_element
  void _refreshAutoAwayPresenceNow({
    Position? position,
    String event = 'foreground_check',
  }) {
    if (!mounted) return;

    _homeAutoAwayCoordinator.refreshPresenceNow(
      uid: uid,
      homes: homes,
      position: position,
      event: event,
    );
  }

  // ignore: unused_element
  void _startAutoAwayPresenceRefreshTimer() {
    _homeAutoAwayCoordinator.startPresenceRefreshTimer(
      uid: uid,
      homesProvider: () => homes,
    );
  }

  Future<void> _syncAutoAwayLocationMonitoring() async {
    if (!mounted || uid.isEmpty) {
      return;
    }

    await _homeAutoAwayCoordinator.syncLocationMonitoring(
      uid: uid,
      homesProvider: () => homes,
    );
  }

  final ScrollController homeTabController = ScrollController();

  void startNotificationListener() {
    _homeRealtimeCoordinator.startNotificationUnreadListener(
      uid: uid,
      onUnreadChanged: (count) {
        if (!mounted) return;

        setState(() {
          unreadHomeNotificationCount = count;
        });
      },
    );
  }

  void startHomeEventsListener() {
    _homeRealtimeCoordinator.startHomeEventsListener(
      ownerUid: selectedHome.isEmpty ? "" : getHomeOwnerUid(),
      homeId: selectedHome,
      onHomeEventsChanged: (events) {
        if (!mounted) return;

        setState(() {
          homeEvents = events;
        });
      },
    );
  }

  void startAlarmPauseListener() {
    final homeId = selectedHome;

    _homeRealtimeCoordinator.startAlarmPauseListener(
      ownerUid: homeId.isEmpty ? "" : getHomeOwnerUid(),
      homeId: homeId,
      onSelectedHomeCleared: () {
        if (mounted && alarmPauseToday.isNotEmpty) {
          setState(() {
            alarmPauseToday = {};
          });
        }
      },
      onAlarmPauseChanged: (update) {
        if (!mounted || selectedHome != update.homeId) {
          return;
        }

        final pause = update.alarmPauseToday;

        setState(() {
          alarmPauseToday = pause;

          final cachedHome = safeMap(homes[update.homeId]);

          if (pause.isEmpty) {
            cachedHome.remove("alarmPauseToday");
          } else {
            cachedHome["alarmPauseToday"] = pause;
          }

          homes[update.homeId] = cachedHome;
        });
      },
    );
  }

  void syncHomeChatListeners() {
    if (!mounted || uid.isEmpty) return;

    _homeRealtimeCoordinator.syncHomeChatListeners(
      uid: uid,
      homes: homes,
      onUnreadChanged: (snapshot) {
        if (!mounted) return;

        final nextUnreadByHome = snapshot.unreadByHome;
        final nextTotal = snapshot.total;
        final unchanged =
            nextTotal == unreadChatCount &&
            nextUnreadByHome.length == unreadChatByHome.length &&
            nextUnreadByHome.entries.every(
              (entry) => unreadChatByHome[entry.key] == entry.value,
            );

        if (unchanged) {
          return;
        }

        setState(() {
          unreadChatByHome = nextUnreadByHome;
          unreadChatCount = nextTotal;
        });
      },
    );
  }

  void syncHomePresenceListeners() {
    // presenceSummary/memberPresenceStatus là dữ liệu chuẩn do backend ghi
    // tại accounts/{ownerUid}/homes/{homeId}. Home listener đã nhận realtime
    // dữ liệu này cho cả chủ nhà và nhà được chia sẻ.
    //
    // Không tự tổng hợp lại từ từng accounts/{memberUid}/homePresence ở app,
    // vì mỗi thiết bị có quyền đọc/cache/listener khác nhau và có thể hiển thị
    // số inside/outside/unknown không đồng nhất với Firebase.
    _homeRealtimeCoordinator.stopHomePresenceListeners();
  }

  void syncDeviceNotificationBridge() {
    if (!mounted) return;

    _homeRealtimeCoordinator.syncDeviceNotificationBridge(
      homes: homes,
      strings: _strings,
      homeNameForId: getHomeDisplayName,
      onDeviceNotification: (notification) {
        _recordDeviceNotification(
          homeId: notification.homeId,
          homeName: notification.homeName,
          deviceId: notification.deviceId,
          device: notification.device,
          deviceName: notification.deviceName,
          event: notification.event,
        );
      },
    );
  }

  void _recordDeviceNotification({
    required String homeId,
    required String homeName,
    required String deviceId,
    required Map<String, dynamic> device,
    required String deviceName,
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
          "deviceName": deviceName,
          "deviceType": device["type"]?.toString() ?? "",
        },
      ).catchError((_) {}),
    );
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

          return HomeAlarmFormatters.hasEnabledScheduleValue(customSnap.value);
        }
      }

      final homeSnap = await FirebaseDatabase.instance
          .ref(
            "accounts/${getHomeOwnerUid()}/homes/"
            "$selectedHome/schedules/notifications",
          )
          .get();

      return HomeAlarmFormatters.hasEnabledScheduleValue(homeSnap.value);
    } catch (_) {
      return false;
    }
  }

  String formatAlarmSchedules() {
    final text = HomeAlarmFormatters.formatAlarmSchedules(
      alarmEnabled: alarmEnabled,
      selectedHome: selectedHome,
      devices: getDevices(),
      customRulesByHome: customRulesByHome,
    );

    return _strings.t(text);
  }

  Map<String, dynamic> getDevices() {
    return HomeDataHelpers.getDevices(homes: homes, selectedHome: selectedHome);
  }

  Map<String, dynamic> getRooms() {
    return HomeDataHelpers.getRooms(homes: homes, selectedHome: selectedHome);
  }

  Map<String, dynamic>? getTemperatureDevice() {
    return HomeDataHelpers.getTemperatureDevice(devices: getDevices());
  }

  String getHomeEnvironmentText() {
    return HomeDataHelpers.getHomeEnvironmentText(devices: getDevices());
  }

  Future<Map<String, dynamic>> loadVisibleShareRequests() async {
    final snapshot = await FirebaseDatabase.instance
        .ref(FirebasePaths.shareRequests(uid))
        .get();

    return safeMap(snapshot.value);
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
      safeDebugPrint("SYNC_HOME_MEMBER_CONTACT_ERROR: $error");
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

  Object? _normalizeSavedHomeOrder(Object? rawOrder) {
    if (rawOrder is List) {
      return rawOrder
          .where((item) => item != null)
          .map((item) => item.toString())
          .toList();
    }

    if (rawOrder is Map) {
      final entries = rawOrder.entries.toList()
        ..sort((a, b) {
          final aIndex = int.tryParse(a.key.toString()) ?? 1 << 30;
          final bIndex = int.tryParse(b.key.toString()) ?? 1 << 30;
          return aIndex.compareTo(bIndex);
        });

      return entries
          .where((entry) => entry.value != null)
          .map((entry) => entry.value.toString())
          .toList();
    }

    return null;
  }

  Map<String, dynamic> _ownedHomesForState() {
    return _homeSelectionStateService.ownedHomesForState(
      ownedHomeIds: _ownedHomeIds,
      homes: homes,
    );
  }

  // ignore: unused_element
  Map<String, dynamic> _loadedSharedHomesForState() {
    return _homeSelectionStateService.loadedSharedHomesForState(
      sharedHomesSnapshot: _sharedHomesSnapshot,
      homes: homes,
    );
  }

  void _rebuildHomeOrderAndSelectionLocked() {
    final result = _homeSelectionStateService.rebuildHomeOrderAndSelection(
      savedHomeOrder: _savedHomeOrder,
      ownedHomeIds: _ownedHomeIds,
      sharedHomesSnapshot: _sharedHomesSnapshot,
      homes: homes,
      selectedHome: selectedHome,
      selectedRoomId: selectedRoomId,
      alarmSettings: alarmSettings,
    );

    homeOrder = result.homeOrder;
    selectedHome = result.selectedHome;
    selectedRoomId = result.selectedRoomId;
    securityMode = result.securityMode;
    alarmPauseToday = result.alarmPauseToday;
    alarmEnabled = result.alarmEnabled;
    start = result.start;
    end = result.end;
  }

  void _ensureSelectedHomeRoomModel() {
    if (!mounted || selectedHome.isEmpty || !canManageHome()) {
      return;
    }

    _homeSelectionStateService.ensureSelectedHomeRoomModel(
      selectedHome: selectedHome,
      canManageHome: canManageHome(),
      ownerUid: getHomeOwnerUid(),
    );
  }

  void _syncPhoneToCurrentHomes() {
    unawaited(
      syncMyPhoneToVisibleHomes(
        ownedHomes: _ownedHomesForState(),
        sharedHomes: _sharedHomesSnapshot,
        phone: userPhone,
      ),
    );
  }

  void _afterHomeStateChanged({
    bool syncAutoAway = false,
    bool syncPhone = false,
  }) {
    if (!mounted) return;

    _ensureSelectedHomeRoomModel();
    startHomeEventsListener();
    startAlarmPauseListener();
    syncHomeChatListeners();
    syncHomePresenceListeners();
    syncDeviceNotificationBridge();

    if (syncPhone) {
      _syncPhoneToCurrentHomes();
    }

    if (syncAutoAway) {
      unawaited(
        AutoAwayService.syncForHomes(uid: uid, homes: homes).catchError((
          Object error,
        ) {
          safeDebugPrint('AUTO_AWAY_HOME_STRUCTURE_SYNC_ERROR: $error');
        }),
      );
    }

    unawaited(_syncAutoAwayLocationMonitoring());
    unawaited(_tryOpenPendingChat());
  }

  String _autoAwayConfigSignature(Map<String, dynamic> home) {
    return _homeSelectionStateService.autoAwayConfigSignature(home);
  }

  void _handleOwnedHomeUpsert(String homeId, Map<String, dynamic> homeData) {
    if (!mounted || homeId.isEmpty) {
      return;
    }

    final previousHome = safeMap(homes[homeId]);
    final wasOwned = _ownedHomeIds.contains(homeId);
    final autoAwayChanged =
        !wasOwned ||
        _autoAwayConfigSignature(previousHome) !=
            _autoAwayConfigSignature(homeData);

    setState(() {
      _ownedHomeIds.add(homeId);
      homes[homeId] = homeData;
      _rebuildHomeOrderAndSelectionLocked();
    });

    _afterHomeStateChanged(syncAutoAway: autoAwayChanged, syncPhone: !wasOwned);
  }

  void _handleOwnedHomeRemoved(String homeId, Map<String, dynamic> homeData) {
    if (!mounted || homeId.isEmpty) {
      return;
    }

    setState(() {
      _ownedHomeIds.remove(homeId);

      if (safeMap(homes[homeId])['_shared'] != true) {
        homes.remove(homeId);
      }

      _rebuildHomeOrderAndSelectionLocked();
    });

    _afterHomeStateChanged(syncAutoAway: true, syncPhone: true);
  }

  void _handleSharedHomesSnapshot(Map<String, dynamic> nextSharedHomes) {
    if (!mounted) return;

    _sharedHomesSnapshot = nextSharedHomes;

    setState(() {
      homes.removeWhere((homeId, rawHome) {
        final home = safeMap(rawHome);
        return home['_shared'] == true && !nextSharedHomes.containsKey(homeId);
      });

      _rebuildHomeOrderAndSelectionLocked();
    });

    _homeListenerService.syncSharedHomes(
      sharedHomes: nextSharedHomes,
      onChanged: (homeId, home) {
        if (!mounted || !_sharedHomesSnapshot.containsKey(homeId)) {
          return;
        }

        final previousHome = safeMap(homes[homeId]);
        final wasLoaded = previousHome['_shared'] == true;
        final autoAwayChanged =
            !wasLoaded ||
            _autoAwayConfigSignature(previousHome) !=
                _autoAwayConfigSignature(home);

        setState(() {
          homes[homeId] = home;
          _rebuildHomeOrderAndSelectionLocked();
        });

        _afterHomeStateChanged(
          syncAutoAway: autoAwayChanged,
          syncPhone: !wasLoaded,
        );
      },
      onDeleted: (homeId) {
        if (!mounted || _ownedHomeIds.contains(homeId)) {
          return;
        }

        setState(() {
          homes.remove(homeId);
          _rebuildHomeOrderAndSelectionLocked();
        });

        _afterHomeStateChanged(syncAutoAway: true, syncPhone: true);
      },
    );

    _afterHomeStateChanged(syncPhone: true);
  }

  void _startAccountPathListeners() {
    _homeAccountRealtimeCoordinator.start(
      uid: uid,
      onProfileChanged: (profile) {
        if (!mounted) return;

        final nextPhone = profile['phone']?.toString() ?? '';
        final phoneChanged = nextPhone != userPhone;

        setState(() {
          userName = profile['name']?.toString() ?? '';
          userGender = profile['gender']?.toString() ?? '';
          userDob = profile['dob']?.toString() ?? '';
          userPhone = nextPhone;
          userPhotoUrl = profile['photoUrl']?.toString() ?? '';
        });

        if (phoneChanged) {
          _syncPhoneToCurrentHomes();
        }
      },
      onOwnedHomeAdded: _handleOwnedHomeUpsert,
      onOwnedHomeChanged: _handleOwnedHomeUpsert,
      onOwnedHomeRemoved: _handleOwnedHomeRemoved,
      onSharedHomesChanged: _handleSharedHomesSnapshot,
      onHomeOrderChanged: (rawOrder) {
        if (!mounted) return;

        _savedHomeOrder = _normalizeSavedHomeOrder(rawOrder);

        setState(_rebuildHomeOrderAndSelectionLocked);
        _afterHomeStateChanged();
      },
      onAlarmSettingsChanged: (settings) {
        if (!mounted) return;

        setState(() {
          alarmSettings = settings;
          alarmEnabled =
              selectedHome.isEmpty ||
              safeMap(alarmSettings[selectedHome])['enabled'] != false;
        });
      },
      onCustomRulesChanged: (rules) {
        if (!mounted) return;

        setState(() {
          customRulesByHome = rules;
        });
      },
      onShareRequestsChanged: (requests) {
        if (!mounted) return;

        setState(() {
          shareRequests = requests;
          inviteCountNotifier.value = requests.length;
        });
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      startHubStatusGracePeriod();
      unawaited(_syncAutoAwayLocationMonitoring());

      if (mounted) {
        setState(() {});
      }

      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Android giữ foreground task độc lập nên không dừng heartbeat ở đây.
      _homeAutoAwayCoordinator.stopPresenceRefreshTimerForBackgroundIfNeeded();
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
    AutoAwayService.activateForSignedInUser(uid);
    // Foreground task được đồng bộ sau khi listener tải danh sách nhà.

    // Chỉ cần đánh giá lại tuổi heartbeat định kỳ khi backend im lặng.
    // Realtime hubStatus vẫn cập nhật ngay qua listener từng nhà.
    hubStatusRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || homes.isEmpty) {
        return;
      }

      setState(() {});
    });

    NotificationService.chatOpenRequest.addListener(_handleChatOpenRequest);
    _handleChatOpenRequest();

    FCMService.setupFCM(uid: uid);
    FCMService.listenForeground(localNotif: localNotif);

    startNotificationListener();
    syncHomeChatListeners();
    _startAccountPathListeners();
  }

  Future<void> handleScannedQR(String code) async {
    final result = await _homePairingService.handleScannedQr(
      code: code,
      uid: uid,
      strings: _strings,
    );

    if (!mounted) return;

    switch (result.status) {
      case HomeScannedQrStatus.invalidJoinMulti:
        showTopToast(
          context,
          _strings.t("QR gia nhập nhiều nhà không hợp lệ"),
          color: Colors.red,
          icon: Icons.qr_code_scanner_rounded,
        );
        return;
      case HomeScannedQrStatus.ownerOfMultiHomes:
        showTopToast(
          context,
          _strings.t("Bạn đang là chủ các nhà này"),
          color: Colors.orange,
          icon: Icons.home_rounded,
        );
        return;
      case HomeScannedQrStatus.joinMultiSent:
        showTopToast(
          context,
          _strings.choose(
            vi: "Đã gửi yêu cầu gia nhập ${result.joinRequestCount} nhà",
            en: "Join requests sent for ${result.joinRequestCount} homes",
            ja: "${result.joinRequestCount} 件の家への参加リクエストを送信しました",
          ),
          color: SafeHomeColors.safe,
          icon: Icons.check_circle_rounded,
        );
        return;
      case HomeScannedQrStatus.invalidJoinSingle:
        showTopToast(
          context,
          _strings.t("QR gia nhập không hợp lệ"),
          color: Colors.red,
          icon: Icons.qr_code_rounded,
        );
        return;
      case HomeScannedQrStatus.ownerOfSingleHome:
        showTopToast(
          context,
          _strings.t("Bạn đang là chủ nhà này"),
          color: Colors.orange,
          icon: Icons.info_outline_rounded,
        );
        return;
      case HomeScannedQrStatus.joinSingleSent:
        showTopToast(
          context,
          _strings.t("Đã gửi yêu cầu gia nhập nhà"),
          color: SafeHomeColors.safe,
          icon: Icons.check_circle_rounded,
        );
        return;
      case HomeScannedQrStatus.pairHubId:
        pairSensor(result.hubId);
        showTopToast(
          context,
          _strings.t("QR này không phải mã xin gia nhập nhà"),
          color: Colors.red,
          icon: Icons.qr_code_2_rounded,
        );
        return;
    }
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

    final ownerUid = getHomeOwnerUid();
    final homeName = getSelectedHomeDisplayName();
    final result = await _homePairingService.startPairing(
      hubId: hubId,
      uid: uid,
      ownerUid: ownerUid,
      homeId: selectedHome,
      selectedRoomId: selectedRoomId,
      homeName: homeName,
      strings: _strings,
    );

    if (!mounted) return;

    setState(() => pairingCountdown = result.durationSeconds);

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
    final confirmOk = await showDeleteHomeConfirmSheet(
      context: context,
      strings: _strings,
    );

    if (!confirmOk) return;
    if (!mounted) return;

    final passwordOk = await showDeleteHomePasswordSheet(
      context: context,
      strings: _strings,
      onConfirmPassword: (sheetContext, password) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          final userEmail = user?.email;

          if (user == null || userEmail == null || userEmail.isEmpty) {
            if (!sheetContext.mounted) return false;

            showTopToast(
              sheetContext,
              _strings.t("Không tìm thấy tài khoản"),
              color: Colors.red,
              icon: Icons.error_outline_rounded,
            );
            return false;
          }

          final credential = EmailAuthProvider.credential(
            email: userEmail,
            password: password,
          );

          await user.reauthenticateWithCredential(credential);

          return true;
        } catch (_) {
          if (!sheetContext.mounted) return false;

          showTopToast(
            sheetContext,
            _strings.t("Sai mật khẩu"),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        }
      },
    );

    if (!passwordOk) return;

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
        ja: "「$deletedHomeName」を削除しました。",
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

    showJoinHomeQrSheet(context: context, strings: _strings, qrData: qrData);
  }

  void shareHome() async {
    final shareOwnerUid = getHomeOwnerUid();
    final qrData = "safehome_join|$shareOwnerUid|$selectedHome";

    final targetEmail = await showShareHomeSheet(
      context: context,
      strings: _strings,
      qrData: qrData,
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
        ja: "${userName.isNotEmpty ? userName : (myEmail ?? _strings.t("Một chủ nhà"))} が「$homeName」への参加に招待しました。",
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
    final targetEmail = await showTransferOwnerEmailSheet(
      context: context,
      strings: _strings,
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

    final ok = await showTransferOwnerConfirmSheet(
      context: context,
      strings: _strings,
      targetEmail: targetEmail,
    );

    if (!ok) return;
    if (!mounted) return;

    final password = await showTransferOwnerPasswordDialog(
      context: context,
      strings: _strings,
    );

    if (password == null) return;
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
        password: password,
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
        ja: "${userName.isNotEmpty ? userName : (myEmail ?? _strings.t("Một chủ nhà"))} が「$homeName」の所有権をあなたに譲渡したいと考えています。",
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
        ja: "「$homeName」の所有権譲渡リクエストを $targetEmail に送信しました。",
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
        _strings.sanitizeUserMessage(
          e.toString(),
          fallback: _strings.choose(
            vi: "Không gửi được yêu cầu xoá",
            en: "Could not send deletion request",
            zh: "无法发送删除请求",
            ko: "삭제 요청을 보낼 수 없습니다",
            ja: "削除リクエストを送信できません",
          ),
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
        zh: "SafeHome 正在从 \"$homeName\" 中移除 \"$deviceName\"。",
        ko: "SafeHome이 \"$homeName\"에서 \"$deviceName\"을(를) 삭제하는 중입니다.",
        ja: "SafeHome は「$homeName」から「$deviceName」を削除しています。",
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

    // Chặn timer cục bộ trước khi dọn foreground task và đăng xuất.
    _homeAutoAwayCoordinator.dispose();

    await SessionLogoutService.signOutCurrentUser();
  }

  Future<void> showAddHomeOptions() async {
    final result = await showAddHomeOptionsSheet(
      context: context,
      strings: _strings,
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
    final result = await showCreateHomeDialog(
      context: context,
      strings: _strings,
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
        ja: "家「$name」を作成しました。",
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

    final startTime = parseTime(
      alarmPauseToday["start"]?.toString(),
      const TimeOfDay(hour: 23, minute: 30),
    );

    final endTime = parseTime(
      alarmPauseToday["end"]?.toString(),
      const TimeOfDay(hour: 23, minute: 45),
    );

    final ownerUid = getHomeOwnerUid();

    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
    final showRemoveButton =
        alarmPauseToday.isNotEmpty && alarmPauseToday["date"] == today;

    String format(TimeOfDay time) {
      return "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
    }

    await showHomeAlarmPauseSheet(
      context: context,
      initialStartTime: startTime,
      initialEndTime: endTime,
      showRemoveButton: showRemoveButton,
      onPickTime: openTimeTextInput,
      onSave: (sheetContext, data) async {
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
          final alarmStart = firstAlarm["start"]?.toString() ?? "23:00";
          final alarmEnd = firstAlarm["end"]?.toString() ?? "06:00";

          final selectedStart = format(data.startTime);
          final selectedEnd = format(data.endTime);

          final startOk = isNowInRange(alarmStart, alarmEnd, selectedStart);

          final endOk = isNowInRange(alarmStart, alarmEnd, selectedEnd);

          if (!startOk || !endOk) {
            showTopToast(
              sheetContext,
              _strings.choose(
                vi: "Khoảng thời gian phải nằm trong khung Alarm ($alarmStart → $alarmEnd)",
                en: "The pause period must be within the Alarm schedule ($alarmStart → $alarmEnd)",
                ja: "一時停止期間は Alarm スケジュール（$alarmStart → $alarmEnd）内である必要があります",
              ),
              color: Colors.orange,
              icon: Icons.schedule_rounded,
            );

            return false;
          }
        }

        final now = DateTime.now();

        final date =
            "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

        final pauseStartText = format(data.startTime);
        final pauseEndText = format(data.endTime);
        final createdAt = DateTime.now().millisecondsSinceEpoch;

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
                "reason": data.reason,
                "createdByUid": uid,
                "createdByName": userName,
                "createdAt": createdAt,
              });
        } catch (e) {
          if (!sheetContext.mounted) return false;

          showTopToast(
            sheetContext,
            _strings.sanitizeUserMessage(
              e.toString(),
              fallback: _strings.choose(
                vi: "Không lưu được tạm tắt Alarm",
                en: "Unable to save the Alarm pause",
                zh: "无法保存 Alarm 暂停",
                ko: "Alarm 임시 중지를 저장할 수 없습니다",
                ja: "Alarm の一時停止を保存できません",
              ),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        }

        if (mounted) {
          setState(() {
            alarmPauseToday = {
              "date": date,
              "start": pauseStartText,
              "end": pauseEndText,
              "homeName": homeName,
              "reason": data.reason,
              "createdByUid": uid,
              "createdByName": userName,
              "createdAt": createdAt,
            };
          });
        }

        return true;
      },
      onRemove: (sheetContext) async {
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
                "createdAt": DateTime.now().millisecondsSinceEpoch,
              });
        } catch (e) {
          if (!sheetContext.mounted) return false;

          showTopToast(
            sheetContext,
            _strings.sanitizeUserMessage(
              e.toString(),
              fallback: _strings.choose(
                vi: "Không xoá được lịch tạm tắt Alarm",
                en: "Unable to delete the Alarm pause schedule",
                zh: "无法删除 Alarm 暂停计划",
                ko: "Alarm 임시 중지 일정을 삭제할 수 없습니다",
                ja: "Alarm の一時停止スケジュールを削除できません",
              ),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        }

        if (mounted) {
          setState(() {
            alarmPauseToday = {};
          });
        }

        return true;
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

    final result = await showRenameHomeSheet(
      context: context,
      strings: _strings,
      usePersonalName: usePersonalName,
      currentName: currentName,
      currentAddress: currentAddress,
    );

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
        ja: "$actorName が家の名前を「$newName」に更新し、住所を変更しました。",
      );
    } else if (nameChanged) {
      message = _strings.choose(
        vi: "$actorName đã đổi tên nhà thành \"$newName\".",
        en: "$actorName renamed the home to \"$newName\".",
        ja: "$actorName が家の名前を「$newName」に変更しました。",
      );
    } else {
      message = _strings.choose(
        vi: "$actorName đã cập nhật địa chỉ của nhà \"$newName\".",
        en: "$actorName updated the address of \"$newName\".",
        ja: "$actorName が「$newName」の住所を更新しました。",
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
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_strings.t("Thay tên")),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_strings.t("Hủy")),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(_strings.t("OK")),
            ),
          ],
        );
      },
    );

    controller.dispose();

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
        ja: "$actorName が「$homeName」でデバイス「$oldDeviceName」の名前を「$newName」に変更しました。",
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

    final result = await FirebaseSecurityTestService.run(
      ownerUid: ownerUid,
      homeId: homeId,
    );

    if (!mounted) return;

    switch (result.state) {
      case FirebaseSecurityTestState.homeUnavailable:
        showTopToast(
          context,
          _strings.t("Không đọc được dữ liệu nhà"),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return;
      case FirebaseSecurityTestState.noDevices:
        showTopToast(
          context,
          _strings.t("Nhà cần có ít nhất một thiết bị để test"),
          color: Colors.orange,
          icon: Icons.sensors_off_rounded,
        );
        return;
      case FirebaseSecurityTestState.completed:
        break;
    }

    final results = result.results;
    final passCount = result.passCount;

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
                "${_strings.choose(vi: "$passCount/${results.length} bài test đạt\n\n", en: "$passCount/${results.length} tests passed\n\n", ja: "$passCount/${results.length} 件のテストに合格\n\n")}$lines",
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
    return HomeDataHelpers.getHomeColor(
      homes: homes,
      homeId: h,
      selectedHome: selectedHome,
    );
  }

  void openHomeNotifications() {
    HomeUiCoordinator.openHomeNotificationList(
      context: context,
      uid: uid,
      homeNameForId: getHomeDisplayName,
      onTapNotification: openHomeNotificationTarget,
    );
  }

  void openScheduleNotificationSheet() {
    HomeUiCoordinator.openScheduleSheet(
      context: context,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      isShared: homes[selectedHome]?["_shared"] == true,
      type: "notification",
      canManageHome: canManageHome(),
    );
  }

  void openAlarmDeviceSheet() {
    HomeUiCoordinator.openAlarmDeviceSheet(
      context: context,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      devices: getDevices(),
      canManageHome: canManageHome(),
    );
  }

  void openSelectedHomeChat() {
    openHomeChatSheetFor(
      homeId: selectedHome,
      homeName: homes[selectedHome]?["name"]?.toString() ?? selectedHome,
    );
  }

  Future<void> openShareRequestsSheet() async {
    final changed = await HomeUiCoordinator.openShareRequests(
      context: context,
      requests: shareRequests,
      uid: uid,
    );

    if (changed == true) {
      await refreshShareRequests();
    }
  }

  Future<void> openShareListSheet() async {
    final selfLeft = await HomeUiCoordinator.openShareList(
      canManageMembers: canManageHome(),
      isOwner: isOwner(),
      context: context,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      homeName: homes[selectedHome]?["name"]?.toString() ?? selectedHome,
    );

    if (selfLeft == true && mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    }
  }

  void openAccountSheet() {
    HomeUiCoordinator.openAccount(
      context: context,
      logout: logout,
      userName: userName,
      userGender: userGender,
      userDob: userDob,
      userPhone: userPhone,
      inviteCountNotifier: inviteCountNotifier,
      onShareRequests: () {
        unawaited(openShareRequestsSheet());
      },
    );
  }

  void openRoomManagement() {
    HomeUiCoordinator.openRoomManagement(
      context: context,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
    );
  }

  void openAllDevicesFromSettings() {
    HomeUiCoordinator.openAllDevices(
      context: context,
      devices: getDevices(),
      onEmpty: () {
        showTopToast(
          context,
          _strings.t("Không có thiết bị"),
          color: Colors.orange,
          icon: Icons.sensors_off_rounded,
        );
      },
      onOpenDevice: (deviceId, device) {
        openDeviceDetailSheet(deviceId: deviceId, device: device);
      },
    );
  }

  void openSettingsCoordinator() {
    HomeUiCoordinator.openSettings(
      homeId: selectedHome,
      ownerUid: getHomeOwnerUid(),
      homeName: homes[selectedHome]?["name"]?.toString() ?? selectedHome,
      homeAddress: homes[selectedHome]?["address"]?.toString() ?? "",
      role: getMyRole(),
      onAllDevices: openAllDevicesFromSettings,
      onAccount: openAccountSheet,
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
                _strings.t("Chỉ chủ nhà mới được chuyển quyền"),
                color: Colors.orange,
                icon: Icons.admin_panel_settings_rounded,
              );
            },
      context: context,
      inviteCountNotifier: inviteCountNotifier,
      onShareRequests: () {
        unawaited(openShareRequestsSheet());
      },
      onShare: shareHome,
      onAutoAway: openAutoAwaySetup,
      onRooms: openRoomManagement,
      onShareList: () {
        unawaited(openShareListSheet());
      },
      onLogout: logout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = getDevices();
    const sectionGap = 6.0;
    final overviewOwnerUid = getHomeOwnerUid();
    final overviewHome = safeMap(homes[selectedHome]);
    final overviewRooms = getRooms();
    final overviewHomeName =
        homes[selectedHome]?["name"]?.toString() ?? _strings.t("Nhà");
    final overviewAlarmPauseText = (() {
      if (alarmPauseToday.isEmpty) {
        return "Tắt";
      }

      final now = DateTime.now();

      final today =
          "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

      if (alarmPauseToday["date"] != today) {
        return "Tắt";
      }

      final startText = alarmPauseToday["start"]?.toString().trim() ?? "";
      final endText = alarmPauseToday["end"]?.toString().trim() ?? "";

      if (startText.isEmpty || endText.isEmpty) {
        return "Tắt";
      }

      return "$startText → $endText";
    })();
    final overviewSecurityModeSource =
        overviewHome["securityModeSource"]?.toString().trim() ?? "";
    final overviewSecurityModeRepeatMinutes =
        _normalizeSecurityModeRepeatMinutes(
          overviewHome["securityModeRepeatMinutes"],
        );
    final overviewAlarmScheduleText = formatAlarmSchedules();
    final overviewEnvironmentText = getHomeEnvironmentText();
    final overviewOverall = getHomeOverallStatus(overviewHome);
    final overviewPairingCountdownText = _strings.choose(
      vi: "Đang ghép nối: $pairingCountdown giây",
      en: "Pairing: $pairingCountdown s",
      ja: "ペアリング中: $pairingCountdown 秒",
    );
    final canManageSelectedHome = canManageHome();
    const bottomBarHeight = 68.0;
    const bottomBarHorizontalInset = 12.0;
    const bottomBarBottomGap = 10.0;
    const deviceListBottomBreathingRoom = 24.0;
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    final bottomBarBottomInset = bottomSafeInset > bottomBarBottomGap
        ? bottomSafeInset
        : bottomBarBottomGap;
    final deviceListBottomPadding =
        bottomBarHeight + bottomBarBottomInset + deviceListBottomBreathingRoom;

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
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  HomeHeaderBar(
                    notificationTooltip: _strings.t("Thông báo Home"),
                    unreadHomeNotificationCount: unreadHomeNotificationCount,
                    onOpenHomeList: () async {
                      final selected = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllHomePage(homeOrder: homeOrder),
                        ),
                      );

                      if (selected == null || !homes.containsKey(selected)) {
                        return;
                      }

                      final currentHome = safeMap(homes[selected]);
                      final parsedAlarm = HomeStateParser.parseAlarm(
                        currentHome,
                      );

                      setState(() {
                        selectedHome = selected;

                        securityMode =
                            currentHome["securityMode"]?.toString() == "armed"
                            ? "armed"
                            : "normal";

                        alarmEnabled =
                            safeMap(alarmSettings[selected])["enabled"] !=
                            false;

                        start = parsedAlarm["start"];
                        end = parsedAlarm["end"];
                        alarmPauseToday = safeMap(
                          currentHome["alarmPauseToday"],
                        );
                      });

                      final index = homeOrder.indexOf(selected);

                      if (index != -1 && homeTabController.hasClients) {
                        homeTabController.animateTo(
                          index * 110,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      }

                      startHomeEventsListener();
                      startAlarmPauseListener();
                    },
                    onOpenNotifications: openHomeNotifications,
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
                        final parsedAlarm = HomeStateParser.parseAlarm(
                          currentHome,
                        );

                        setState(() {
                          selectedHome = h;

                          securityMode =
                              currentHome["securityMode"]?.toString() == "armed"
                              ? "armed"
                              : "normal";

                          alarmEnabled =
                              safeMap(alarmSettings[h])["enabled"] != false;

                          start = parsedAlarm["start"];
                          end = parsedAlarm["end"];
                          alarmPauseToday = safeMap(
                            currentHome["alarmPauseToday"],
                          );
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
                          bottomPadding: deviceListBottomPadding,
                          header: HomeOverviewHeader(
                            ownerUid: overviewOwnerUid,
                            homeId: selectedHome,
                            homeName: overviewHomeName,
                            alarmPauseText: overviewAlarmPauseText,
                            onAlarmPauseToday: () {
                              openAlarmPauseSheetWithReminder();
                            },
                            environmentText: overviewEnvironmentText,
                            homeEvents: homeEvents,
                            onEnvironmentTap: () {
                              final tempDevice = getTemperatureDevice();

                              if (tempDevice == null) return;

                              openDeviceDetailSheet(
                                deviceId: tempDevice["id"],
                                device: tempDevice["data"],
                              );
                            },
                            overall: overviewOverall,
                            securityMode: securityMode,
                            securityModeSource: overviewSecurityModeSource,
                            securityModeRepeatMinutes:
                                overviewSecurityModeRepeatMinutes,
                            onSecurityModeRepeatChanged: canManageSelectedHome
                                ? setSecurityModeRepeatMinutes
                                : null,
                            onSecurityModeChanged: setSecurityMode,
                            alarmEnabled: alarmEnabled,
                            onAlarmEnabledChanged: canManageSelectedHome
                                ? setAlarmEnabled
                                : null,
                            onScheduleNotification:
                                openScheduleNotificationSheet,
                            onScheduleAlarm: openAlarmDeviceSheet,
                            alarmStart: overviewAlarmScheduleText,
                            alarmEnd: "",
                            rooms: overviewRooms,
                            selectedRoomId: selectedRoomId,
                            onSelectRoom: (roomId) {
                              setState(() {
                                selectedRoomId = roomId;
                              });
                            },
                            onReorderRooms: (roomIds) async {
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
                            pairingCountdown: pairingCountdown,
                            pairingCountdownText: overviewPairingCountdownText,
                            sectionGap: sectionGap,
                          ),
                          isShared: homes[selectedHome]?["_shared"] == true,
                          ownerEmail:
                              homes[selectedHome]?["_ownerEmail"]?.toString() ??
                              "",
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

                            final result = await showHomePairSensorSheet(
                              context: context,
                              strings: _strings,
                            );

                            if (result == HomePairSensorMethod.scanQr) {
                              if (!context.mounted) return;

                              final code = await openQRScanner(context);

                              if (code != null) {
                                pairSensor(code);
                              }
                            }

                            if (result == HomePairSensorMethod.manualHubId) {
                              if (!context.mounted) return;

                              final hubId = await showPairDialog(context);

                              if (hubId == null || hubId.trim().isEmpty) return;

                              pairSensor(hubId.trim());
                            }
                          },
                          onTapDevice: openSelectedDeviceDetail,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: bottomBarHorizontalInset,
              right: bottomBarHorizontalInset,
              bottom: bottomBarBottomInset,
              child: HomeBottomBar(
                addHomeTooltip: _strings.t("Thêm Home"),
                unreadChatCount: unreadChatByHome[selectedHome] ?? 0,
                inviteCount: shareRequests.length,
                alarmEnabled: alarmEnabled,
                onAddHome: showAddHomeOptions,
                onOpenChat: openSelectedHomeChat,
                onOpenAlarm: () async {
                  final reminderEnabled = await hasEnabledReminderSchedule();

                  if (!context.mounted) return;

                  final alarmScheduleText =
                      formatAlarmSchedules().trim().isEmpty
                      ? _strings.t("Chưa thiết lập thời gian")
                      : formatAlarmSchedules();

                  await showHomeAlarmMenuSheet(
                    context: context,
                    strings: _strings,
                    alarmEnabled: alarmEnabled,
                    reminderEnabled: reminderEnabled,
                    alarmScheduleText: alarmScheduleText,
                    alarmPauseToday: alarmPauseToday,
                    onAlarmEnabledChanged: setAlarmEnabled,
                    onOpenAlarmSchedule: openAlarmDeviceSheet,
                    onOpenAlarmPause: () async {
                      await Future<void>.delayed(
                        const Duration(milliseconds: 120),
                      );

                      if (!mounted) return;

                      await openAlarmPauseSheetWithReminder();
                    },
                    onOpenReminderSchedule: openScheduleNotificationSheet,
                  );
                },
                onOpenSettings: openSettingsCoordinator,
              ),
            ),
          ],
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
    _homeAutoAwayCoordinator.dispose();
    _homeAccountRealtimeCoordinator.dispose();
    _homeRealtimeCoordinator.dispose();
    unawaited(_homeListenerService.dispose());
    homeTabController.dispose();
    super.dispose();
  }
}
