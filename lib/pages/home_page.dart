import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../helpers/firebase_paths.dart';
import '../helpers/emergency_pulse_ticker.dart';

import '../helpers/home_helper.dart';
import '../services/fcm_service.dart';
import '../services/firebase_security_test_service.dart';
import '../services/home_account_realtime_coordinator.dart';
import '../services/home_alarm_security_service.dart';
import '../services/home_auto_away_coordinator.dart';
import '../services/home_listener_service.dart';
import '../services/home_pairing_service.dart';
import '../services/hub_update_notice_coordinator.dart';
import '../services/home_realtime_coordinator.dart';
import '../services/home_selection_state_service.dart';
import '../services/home_service.dart';
import '../services/home_state_parser.dart';
import '../services/share_service.dart';
import '../services/notification_service.dart';
import '../widgets/home_tabs.dart';
import '../widgets/device_list.dart';
import '../widgets/system_health_sheet.dart';
import '../sheets/device_alarm_policy_sheet.dart';
import '../sheets/hub_info_sheet.dart';
import 'all_home_page.dart';
import 'home/home_add_sheets.dart';
import 'home/home_alarm_menu_sheet.dart';
import 'home/home_alarm_pause_sheet.dart';
import 'home/home_auto_away_map_page.dart';
import 'home/home_auto_away_models.dart';
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
import '../services/system_usage_service.dart';
import '../maiyen_theme.dart';
import '../localization/app_strings.dart';
import 'package:maiyen_app/helpers/debug_log.dart';
import '../config/maiyen_identifiers.dart';

part 'home/home_page_navigation_part.dart';
part 'home/home_page_security_auto_away_part.dart';
part 'home/home_page_realtime_part.dart';
part 'home/home_page_actions_part.dart';

class MaiYen extends StatefulWidget {
  const MaiYen({super.key});

  @override
  State<MaiYen> createState() => _MaiYenState();
}

class _MaiYenState extends State<MaiYen> with WidgetsBindingObserver {
  AppStrings get _strings => AppStrings.of(context);
  Map<String, dynamic> shareRequests = {};
  final ValueNotifier<int> inviteCountNotifier = ValueNotifier(0);
  int unreadChatCount = 0;
  Map<String, int> unreadChatByHome = {};
  int unreadHomeNotificationCount = 0;
  Map<String, String>? _pendingChatOpenRequest;
  bool _openingChatFromNotification = false;
  Map<String, String>? _pendingHubUpdateOpenRequest;
  bool _openingHubUpdateFromNotification = false;
  final HubUpdateNoticeCoordinator _hubUpdateNoticeCoordinator =
      HubUpdateNoticeCoordinator();

  String uid = "";
  String userName = "";
  String userGender = "";
  String userDob = "";
  String userPhone = "";
  String userPhotoUrl = "";

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
  Timer? _alarmPauseExpiryTimer;
  List<String> homeOrder = [];

  TimeOfDay start = TimeOfDay(hour: 23, minute: 0);
  TimeOfDay end = TimeOfDay(hour: 6, minute: 0);

  String securityMode = "normal";

  bool get isArmedMode => securityMode == "armed";
  bool alarmEnabled = false;
  int pairingCountdown = 0;
  Timer? timer;

  // Firebase không phát sự kiện chỉ vì thời gian trôi qua.
  // Timer này buộc UI đánh giá lại tuổi heartbeat khi app đang mở.
  Timer? hubStatusRefreshTimer;
  bool _deferredHomeStartupStarted = false;
  bool _secondaryHomeListenersReady = false;
  bool _singleHomeIdentityReady = false;
  // Android dùng foreground task độc lập để heartbeat vẫn chạy
  // khi app ở nền, tắt màn hình hoặc bị vuốt khỏi Recent Apps.
  // Các nền tảng khác giữ timer cũ.

  // ignore: unused_element
  // ignore: unused_element
  // ignore: unused_element
  final ScrollController homeTabController = ScrollController();

  int? _resolveAlarmPauseEndAt(Map<String, dynamic> pause) {
    final directEndAt = int.tryParse(pause["endAt"]?.toString() ?? "");
    if (directEndAt != null && directEndAt > 0) {
      return directEndAt;
    }

    final dateParts = (pause["date"]?.toString() ?? "").split("-");
    final startParts = (pause["start"]?.toString() ?? "").split(":");
    final endParts = (pause["end"]?.toString() ?? "").split(":");
    if (dateParts.length != 3 ||
        startParts.length != 2 ||
        endParts.length != 2) {
      return null;
    }

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);
    if (year == null ||
        month == null ||
        day == null ||
        startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        startHour < 0 ||
        startHour > 23 ||
        endHour < 0 ||
        endHour > 23 ||
        startMinute < 0 ||
        startMinute > 59 ||
        endMinute < 0 ||
        endMinute > 59) {
      return null;
    }

    final startAt = DateTime(year, month, day, startHour, startMinute);
    var endAt = DateTime(year, month, day, endHour, endMinute);
    if (!endAt.isAfter(startAt)) {
      endAt = endAt.add(const Duration(days: 1));
    }
    return endAt.millisecondsSinceEpoch;
  }

  // ignore: unused_element
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      startHubStatusGracePeriod();
      _scheduleHubUpdateNoticeCheck();
      unawaited(_tryOpenPendingHubUpdate());
      unawaited(_syncAutoAwayLocationMonitoring());
      unawaited(SystemUsageService.recordAppOpen());
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
    unawaited(SystemUsageService.recordAppOpen());
    startHubStatusGracePeriod();

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    uid = currentUser.uid;

    // ALARM-CRITICAL:
    // Giữ FCM + foreground alarm listener chạy ngay, không defer.
    // Đây là đường nhận alarm khi app đang mở.
    unawaited(
      FCMService.setupFCM(uid: uid).catchError((Object error) {
        safeDebugPrint("FCM_SETUP_ERROR: $error");
      }),
    );
    FCMService.listenForeground();

    // Dữ liệu nhà chính vẫn cần chạy sớm để hiện UI.
    _startAccountPathListeners();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      setState(() {
        _singleHomeIdentityReady = true;
      });
    });
    // Các phần không trực tiếp quyết định tốc độ nhận Alarm chạy sau frame đầu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startDeferredHomeStartup());
    });
  }

  // ================= RESTORED FULL FUNCTIONS =================
  @override
  Widget build(BuildContext context) {
    final devices = getDevices();
    const sectionGap = 6.0;
    final overviewOwnerUid = getHomeOwnerUid();
    final overviewHome = safeMap(homes[selectedHome]);
    final overviewHubStatus = safeMap(overviewHome["hubStatus"]);
    final hubUpdateAttention =
        isOwner() &&
        parseDeviceBool(overviewHubStatus["updateAvailable"]) == true;
    final overviewRooms = getRooms();
    final overviewHomeName =
        homes[selectedHome]?["name"]?.toString() ?? _strings.t("Nhà");
    final overviewAlarmPauseText = (() {
      if (alarmPauseToday.isEmpty) {
        return _strings.t("Tắt");
      }

      final now = DateTime.now();

      final today =
          "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

      if (alarmPauseToday["date"] != today ||
          !_isAlarmPauseStillValid(alarmPauseToday)) {
        return _strings.t("Tắt");
      }

      final startText = alarmPauseToday["start"]?.toString().trim() ?? "";
      final endText = alarmPauseToday["end"]?.toString().trim() ?? "";

      if (startText.isEmpty || endText.isEmpty) {
        return _strings.t("Tắt");
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
    final overviewLevel =
        overviewOverall["level"]?.toString().trim() ?? "no_data";

    if (overviewLevel == "emergency") {
      EmergencyPulseTicker.ensureStarted();
    }
    final overviewPairingCountdownText = _strings.pairingCountdownText(
      pairingCountdown,
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
      backgroundColor: MaiYenColors.background,
      body: _HomeStatusBackground(
        level: overviewLevel,
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  HomeHeaderBar(
                    notificationTooltip: _strings.notifications,
                    unreadHomeNotificationCount: unreadHomeNotificationCount,
                    onOpenHomeList: () async {
                      final selected = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllHome(homeOrder: homeOrder),
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

                        securityMode = _homeAlarmSecurityService
                            .normalizeSecurityMode(currentHome["securityMode"]);

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
                    onOpenSystemHealth: () {
                      showSystemHealthSheet(
                        context: context,
                        ownerUid: getHomeOwnerUid(),
                        homeId: selectedHome,
                        securityMode: securityMode,
                        securityModeSource: overviewSecurityModeSource,
                      );
                    },
                    onOpenNotifications: openHomeNotifications,
                  ),
                  const SizedBox(height: sectionGap),

                  Padding(
                    padding: EdgeInsets.zero,
                    child: _SoftHomeTabsAppear(
                      animationKey: (() {
                        final visibleHomeCount = homeOrder
                            .where((homeId) => homes.containsKey(homeId))
                            .toSet()
                            .length;

                        if (visibleHomeCount <= 1 &&
                            !_singleHomeIdentityReady) {
                          return "single_wait";
                        }

                        return visibleHomeCount <= 1 ? "single" : "multi";
                      })(),
                      child: HomeTabs(
                        singleHomeIdentityEnabled: _singleHomeIdentityReady,
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

                            securityMode = _homeAlarmSecurityService
                                .normalizeSecurityMode(
                                  currentHome["securityMode"],
                                );

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
                  ),
                  const SizedBox(height: sectionGap),

                  Expanded(
                    child: Stack(
                      children: [
                        _SoftHomeContentAppear(
                          animationKey: selectedHome,
                          child: DeviceList(
                            homeId: selectedHome,
                            ownerUid: overviewOwnerUid,
                            hubId:
                                homes[selectedHome]?["hubId"]?.toString() ?? "",
                            devices: devices,
                            selectedRoomId: selectedRoomId,
                            securityMode: securityMode,
                            personalAlarmRules: safeMap(
                              customRulesByHome[selectedHome],
                            ),
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
                              pairingCountdownText:
                                  overviewPairingCountdownText,
                              sectionGap: sectionGap,
                            ),
                            isShared: homes[selectedHome]?["_shared"] == true,
                            ownerEmail:
                                homes[selectedHome]?["_ownerEmail"]
                                    ?.toString() ??
                                "",
                            onRename: canManageHome() ? renameDevice : (_) {},
                            onDelete: canManageHome() ? deleteDevice : (_) {},
                            onPairSensor: () async {
                              if (!canManageHome()) {
                                showTopToast(
                                  context,
                                  _strings.t(
                                    "Bạn không có quyền thêm thiết bị",
                                  ),
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

                                final code = await openQRScanner(
                                  context,
                                  mode: MaiYenQrScanMode.pairDevice,
                                );

                                if (code != null) {
                                  pairSensor(code);
                                }
                              }

                              if (result == HomePairSensorMethod.manualHubId) {
                                if (!context.mounted) return;

                                final hubId = await showPairDialog(context);

                                if (hubId == null || hubId.trim().isEmpty) {
                                  return;
                                }

                                pairSensor(hubId.trim());
                              }
                            },
                            onTapDevice: openSelectedDeviceDetail,
                            onTapInfrastructureGroup:
                                openInfrastructureDeviceDetail,
                          ),
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
                hubUpdateAttention: hubUpdateAttention,
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
                    reminderEnabled: reminderEnabled,
                    alarmScheduleText: alarmScheduleText,
                    alarmPauseToday: alarmPauseToday,
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
    NotificationService.hubUpdateOpenRequest.removeListener(
      _handleHubUpdateOpenRequest,
    );
    timer?.cancel();
    hubStatusRefreshTimer?.cancel();
    _alarmPauseExpiryTimer?.cancel();
    _homeAutoAwayCoordinator.dispose();
    _hubUpdateNoticeCoordinator.dispose();
    _homeAccountRealtimeCoordinator.dispose();
    _homeRealtimeCoordinator.dispose();
    unawaited(_homeListenerService.dispose());
    homeTabController.dispose();
    super.dispose();
  }
}

class _HomeStatusBackground extends StatelessWidget {
  const _HomeStatusBackground({required this.level, required this.child});

  static final ValueNotifier<bool> _steadyPhase = ValueNotifier<bool>(false);

  final String level;
  final Widget child;

  List<Color> _gradientColors(bool emergencyPhase) {
    switch (level) {
      case "warning":
        return const [Color(0xFFFFF6D8), Color(0xFFFFFAEC), Color(0xFFFFFFFF)];
      case "danger":
        return const [Color(0xFFFFECEA), Color(0xFFFFF5F3), Color(0xFFFFFFFF)];
      case "emergency":
        if (emergencyPhase) {
          return const [
            Color(0xFFFFEDBE),
            Color(0xFFFFF7DF),
            Color(0xFFFFFFFF),
          ];
        }

        return const [Color(0xFFFFE4E1), Color(0xFFFFF0ED), Color(0xFFFFFFFF)];
      case "safe":
        return const [
          Color(0xFFF3F8F5),
          MaiYenColors.background,
          Color(0xFFFFFFFF),
        ];
      default:
        return const [Color(0xFFF4F6F5), Color(0xFFF7F8F7), Color(0xFFFFFFFF)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseListenable = level == "emergency"
        ? EmergencyPulseTicker.phase
        : _steadyPhase;

    return ValueListenableBuilder<bool>(
      valueListenable: phaseListenable,
      child: child,
      builder: (context, emergencyPhase, staticChild) {
        return AnimatedContainer(
          duration: Duration(milliseconds: level == "emergency" ? 560 : 420),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.46, 1],
              colors: _gradientColors(emergencyPhase),
            ),
          ),
          child: staticChild,
        );
      },
    );
  }
}

class _SoftHomeContentAppear extends StatefulWidget {
  const _SoftHomeContentAppear({
    required this.animationKey,
    required this.child,
  });

  final String animationKey;
  final Widget child;

  @override
  State<_SoftHomeContentAppear> createState() => _SoftHomeContentAppearState();
}

class _SoftHomeContentAppearState extends State<_SoftHomeContentAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    _scale = Tween<double>(begin: 0.975, end: 1.0).animate(curve);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant _SoftHomeContentAppear oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationKey != widget.animationKey) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.topCenter,
        child: widget.child,
      ),
    );
  }
}

class _SoftHomeTabsAppear extends StatelessWidget {
  const _SoftHomeTabsAppear({required this.animationKey, required this.child});

  final String animationKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 880),
      reverseDuration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutQuart,
      switchOutCurve: Curves.easeOutQuart,

      // Không giữ widget cũ ở dưới nữa.
      // Như vậy khi chuyển 1 home -> nhiều home hoặc xoá ngược lại,
      // sẽ không còn lộ cái khung card cũ.
      layoutBuilder: (currentChild, previousChildren) {
        return currentChild ?? const SizedBox(height: 58);
      },

      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.10, 0),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        );
      },

      child: KeyedSubtree(
        key: ValueKey("home_tabs_mode_$animationKey"),
        child: child,
      ),
    );
  }
}
