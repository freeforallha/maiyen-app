part of '../home_page.dart';

extension _Realtime on _MaiYenState {
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

  bool _isAlarmPauseStillValid(Map<String, dynamic> pause) {
    if (pause.isEmpty) return false;
    final endAt = _resolveAlarmPauseEndAt(pause);
    return endAt != null && endAt > DateTime.now().millisecondsSinceEpoch;
  }

  void _clearAlarmPauseFromLocalState(String homeId) {
    if (!mounted || homeId.isEmpty) return;

    setState(() {
      if (selectedHome == homeId) {
        alarmPauseToday = {};
      }

      final cachedHome = safeMap(homes[homeId]);
      cachedHome.remove("alarmPauseToday");
      homes[homeId] = cachedHome;
    });
  }

  void _syncAlarmPauseExpiryTimer() {
    _alarmPauseExpiryTimer?.cancel();
    _alarmPauseExpiryTimer = null;

    final homeId = selectedHome;
    final endAt = _resolveAlarmPauseEndAt(alarmPauseToday);
    if (homeId.isEmpty || endAt == null || endAt <= 0) return;

    final delayMs = endAt - DateTime.now().millisecondsSinceEpoch;
    if (delayMs <= 0) {
      _clearAlarmPauseFromLocalState(homeId);
      return;
    }

    _alarmPauseExpiryTimer = Timer(
      Duration(milliseconds: delayMs + 120),
      () => _clearAlarmPauseFromLocalState(homeId),
    );
  }

  void startAlarmPauseListener() {
    final homeId = selectedHome;

    _homeRealtimeCoordinator.startAlarmPauseListener(
      ownerUid: homeId.isEmpty ? "" : getHomeOwnerUid(),
      homeId: homeId,
      onSelectedHomeCleared: () {
        _alarmPauseExpiryTimer?.cancel();
        _alarmPauseExpiryTimer = null;
        _clearAlarmPauseFromLocalState(homeId);
      },
      onAlarmPauseChanged: (update) {
        if (!mounted || selectedHome != update.homeId) {
          return;
        }

        final pause = update.alarmPauseToday;

        final effectivePause = _isAlarmPauseStillValid(pause)
            ? pause
            : <String, dynamic>{};

        setState(() {
          alarmPauseToday = effectivePause;

          final cachedHome = safeMap(homes[update.homeId]);

          if (effectivePause.isEmpty) {
            cachedHome.remove("alarmPauseToday");
          } else {
            cachedHome["alarmPauseToday"] = effectivePause;
          }

          homes[update.homeId] = cachedHome;
        });
        _syncAlarmPauseExpiryTimer();
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
    final eventType = event["type"] ?? "device_event";

    // Các trạng thái này do backend ghi để vẫn đầy đủ khi app đóng.
    // Không ghi thêm từ listener Flutter, tránh một sự kiện xuất hiện hai lần.
    if (const <String>{
      "device_added",
      "device_battery_low",
      "device_connection",
    }.contains(eventType)) {
      return;
    }

    unawaited(
      HomeNotificationService.addNotification(
        uid: uid,
        type: eventType,
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
          "type": event["type"] ?? "device_event",
          "event": event["event"] ?? event["type"] ?? "device_event",
          "closed": event["closed"],
          "availability": event["availability"],
          "condition": event["condition"],
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
        final rulesSnap = await FirebaseDatabase.instance
            .ref("accounts/$uid/customRules/$selectedHome")
            .get();
        final rules = safeMap(rulesSnap.value);
        final reminderMode =
            rules["reminderMode"]?.toString() ?? rules["mode"]?.toString();

        if (reminderMode == "custom") {
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

  String _hubUpdateNoticeOwnerUid(
    String homeId,
    Map<String, dynamic> home,
  ) {
    if (home['_shared'] == true) {
      return home['_ownerUid']?.toString().trim() ?? '';
    }

    final explicitOwnerUid = home['_ownerUid']?.toString().trim() ?? '';
    return explicitOwnerUid.isNotEmpty ? explicitOwnerUid : uid;
  }

  void _scheduleHubUpdateNoticeCheck() {
    for (final entry in homes.entries) {
      final homeId = entry.key;
      final home = safeMap(entry.value);
      final hubStatus = safeMap(home['hubStatus']);

      if (!hubStatus.containsKey('updateAvailable')) {
        continue;
      }

      final updateAvailable =
          parseDeviceBool(hubStatus['updateAvailable']) == true;
      final request = safeMap(home['hubUpdateRequest']);
      final requestStatus = request['status']?.toString().trim() ?? '';
      final requestPending =
          requestStatus == 'requested' || requestStatus == 'queued';

      if (!updateAvailable || requestPending) {
        unawaited(
          NotificationService.cancelHubUpdateNotification(homeId).catchError((
            Object error,
          ) {
            safeDebugPrint('HUB_UPDATE_NOTIFICATION_CANCEL_ERROR: $error');
          }),
        );
      }
    }

    _hubUpdateNoticeCoordinator.schedule(
      context: context,
      uid: uid,
      homes: homes,
      homeOrder: homeOrder,
      selectedHome: selectedHome,
      ownerUidForHome: _hubUpdateNoticeOwnerUid,
      homeNameForHome: getHomeDisplayName,
      selectHome: selectHomeFromNotification,
    );
  }

  void _afterHomeStateChanged({
    bool syncAutoAway = false,
    bool syncPhone = false,
  }) {
    if (!mounted) return;

    _scheduleHubUpdateNoticeCheck();

    // Các phần này cần cho trạng thái nhà chính, giữ chạy sớm.
    _ensureSelectedHomeRoomModel();
    startHomeEventsListener();
    startAlarmPauseListener();
    syncHomePresenceListeners();

    if (syncPhone) {
      _syncPhoneToCurrentHomes();
    }

    // Các listener phụ chỉ chạy sau khi MaiYen đã vẽ xong.
    // Mục tiêu: giảm đơ/trắng khi vừa login.
    if (!_secondaryHomeListenersReady) {
      return;
    }

    syncHomeChatListeners();
    syncDeviceNotificationBridge();

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
    unawaited(_tryOpenPendingHubUpdate());
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

}
