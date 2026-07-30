part of '../home_page.dart';

extension _Actions on _MaiYenState {
  Future<void> _startDeferredHomeStartup() async {
    if (_deferredHomeStartupStarted) {
      return;
    }

    _deferredHomeStartupStarted = true;

    // Chờ MaiYen vẽ frame đầu xong rồi mới bật các phần phụ.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted || uid.isEmpty) {
      return;
    }

    _secondaryHomeListenersReady = true;

    // Không nằm trên đường nhận alarm realtime.
    AutoAwayService.activateForSignedInUser(uid);

    hubStatusRefreshTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || homes.isEmpty) {
        return;
      }

      setState(() {});
      _scheduleHubUpdateNoticeCheck();
      unawaited(_tryOpenPendingHubUpdate());
    });

    NotificationService.chatOpenRequest.addListener(_handleChatOpenRequest);
    NotificationService.hubUpdateOpenRequest.addListener(
      _handleHubUpdateOpenRequest,
    );
    _handleChatOpenRequest();
    _handleHubUpdateOpenRequest();

    startNotificationListener();
    syncHomeChatListeners();
    syncDeviceNotificationBridge();

    unawaited(
      AutoAwayService.syncForHomes(uid: uid, homes: homes).catchError((
        Object error,
      ) {
        safeDebugPrint('AUTO_AWAY_HOME_STRUCTURE_SYNC_ERROR: $error');
      }),
    );

    unawaited(_syncAutoAwayLocationMonitoring());
    unawaited(_tryOpenPendingChat());
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
          _strings.joinRequestsSentMessage(result.joinRequestCount),
          color: MaiYenColors.safe,
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
          color: MaiYenColors.safe,
          icon: Icons.check_circle_rounded,
        );
        return;
      case HomeScannedQrStatus.pairHubId:
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
      message: _strings.homeDeletedMessage(deletedHomeName),
      homeId: deletedHomeId,
      homeName: deletedHomeName,
      entityType: "home",
      entityId: deletedHomeId,
      data: {"type": "home_deleted", "homeName": deletedHomeName},
    );

    homeOrder.remove(deletedHomeId);

    await FirebaseDatabase.instance
        .ref(FirebasePaths.homeOrder(uid))
        .set(homeOrder);
  }

  void showJoinHomeQR() {
    final shareOwnerUid = getHomeOwnerUid();
    final qrData = MaiYenIdentifiers.buildJoinHomeQr(
      ownerUid: shareOwnerUid,
      homeId: selectedHome,
    );

    showJoinHomeQrSheet(context: context, strings: _strings, qrData: qrData);
  }

  void shareHome() async {
    final shareOwnerUid = getHomeOwnerUid();
    final qrData = MaiYenIdentifiers.buildJoinHomeQr(
      ownerUid: shareOwnerUid,
      homeId: selectedHome,
    );

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
      message: _strings.shareInvitationMessage(
        actorName: userName.isNotEmpty
            ? userName
            : (myEmail ?? _strings.t("Một chủ nhà")),
        homeName: homeName,
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
      color: MaiYenColors.safe,
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
      message: _strings.ownershipTransferRequestMessage(
        actorName: userName.isNotEmpty
            ? userName
            : (myEmail ?? _strings.t("Một chủ nhà")),
        homeName: homeName,
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
      message: _strings.ownershipTransferRequestSentMessage(
        homeName: homeName,
        email: targetEmail,
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
      color: MaiYenColors.safe,
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
        color: MaiYenColors.safe,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;

      showTopToast(
        context,
        _strings.sanitizeUserMessage(
          e.toString(),
          fallback: _strings.t("Không gửi được yêu cầu xoá"),
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
      message: _strings.deviceDeleteInProgressMessage(
        deviceName: deviceName,
        homeName: homeName,
      ),
      homeName: homeName,
      deviceId: id,
      entityType: "device",
      entityId: id,
      data: {
        "type": "device_delete_requested",
        "deviceName": deviceName,
        "homeName": homeName,
      },
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

    final code = await openQRScanner(
      context,
      mode: MaiYenQrScanMode.joinHome,
    );

    if (!mounted || code == null || code.trim().isEmpty) {
      return;
    }

    final value = code.trim();

    if (!value.startsWith(MaiYenIdentifiers.joinHomeQrPrefix) &&
        !value.startsWith(
          MaiYenIdentifiers.joinMultipleHomesQrPrefix,
        )) {
      showTopToast(
        context,
        _strings.t("QR này không phải mã xin gia nhập nhà"),
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
      title: _strings.t("Đã tạo nhà"),
      message: _strings.homeCreatedMessage(name),
      homeId: id,
      homeName: name,
      entityType: "home",
      entityId: id,
      data: {"type": "home_created", "homeName": name},
    );
  }

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

    String format(TimeOfDay time) {
      return "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
    }

    bool isValidHHMM(String value) {
      return RegExp(r"^([01][0-9]|2[0-3]):[0-5][0-9]$").hasMatch(value);
    }

    int toMinutesFromText(String value) {
      final parts = value.split(":");

      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    TimeOfDay timeFromDateTime(DateTime value) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }

    DateTime dateOnly(DateTime value) {
      return DateTime(value.year, value.month, value.day);
    }

    DateTime dateAtTime(DateTime date, TimeOfDay time) {
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    String dateKey(DateTime value) {
      return "${value.year}-${value.month.toString().padLeft(2, "0")}-${value.day.toString().padLeft(2, "0")}";
    }

    List<int> normalizeAlarmDays(dynamic rawDays) {
      final days = <int>{};

      if (rawDays is List) {
        for (final rawDay in rawDays) {
          final day = int.tryParse(rawDay?.toString() ?? "");

          if (day != null && day >= 1 && day <= 7) {
            days.add(day);
          }
        }
      } else if (rawDays is Map) {
        for (final rawDay in rawDays.values) {
          final day = int.tryParse(rawDay?.toString() ?? "");

          if (day != null && day >= 1 && day <= 7) {
            days.add(day);
          }
        }
      }

      if (days.isEmpty) {
        return const [1, 2, 3, 4, 5, 6, 7];
      }

      final sorted = days.toList()..sort();

      return sorted;
    }

    bool intervalsOverlap(
      DateTime aStart,
      DateTime aEnd,
      DateTime bStart,
      DateTime bEnd,
    ) {
      return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
    }

    List<Map<String, dynamic>> enabledDeviceAlarms() {
      final home = safeMap(homes[selectedHome]);
      final devices = safeMap(home["devices"]);
      final alarms = <Map<String, dynamic>>[];

      for (final rawDevice in devices.values) {
        final device = safeMap(rawDevice);
        final schedules = normalizeDeviceAlarmSchedules(
          rawSchedules: device["alarmSchedules"],
          legacyAlarm: device["alarm"],
          personal: false,
        );

        for (final alarm in schedules.values) {
          final startText = alarm["start"]?.toString() ?? "";
          final endText = alarm["end"]?.toString() ?? "";

          if (alarm["enabled"] == true &&
              isValidHHMM(startText) &&
              isValidHHMM(endText) &&
              startText != endText) {
            alarms.add(alarm);
          }
        }
      }

      return alarms;
    }

    Map<String, dynamic>? findBestAlarmWindow(DateTime now) {
      final alarms = enabledDeviceAlarms();

      if (alarms.isEmpty) {
        return null;
      }

      Map<String, dynamic>? best;
      var bestRank = 999;
      var bestDistance = const Duration(days: 999);

      final today = dateOnly(now);

      for (final alarm in alarms) {
        final startText = alarm["start"]?.toString() ?? "23:00";
        final endText = alarm["end"]?.toString() ?? "06:00";
        final alarmDays = normalizeAlarmDays(alarm["days"]);
        final startMinutes = toMinutesFromText(startText);
        final endMinutes = toMinutesFromText(endText);

        for (var offset = -1; offset <= 7; offset++) {
          final startDate = today.add(Duration(days: offset));

          if (!alarmDays.contains(startDate.weekday)) {
            continue;
          }

          final alarmStartAt = startDate.add(Duration(minutes: startMinutes));
          var alarmEndAt = startDate.add(Duration(minutes: endMinutes));

          if (!alarmEndAt.isAfter(alarmStartAt)) {
            alarmEndAt = alarmEndAt.add(const Duration(days: 1));
          }

          final activeNow =
              !now.isBefore(alarmStartAt) && now.isBefore(alarmEndAt);
          final upcoming = alarmStartAt.isAfter(now);

          if (!activeNow && !upcoming) {
            continue;
          }

          final rank = activeNow ? 0 : 1;
          final distance = activeNow
              ? Duration.zero
              : alarmStartAt.difference(now);

          if (rank < bestRank ||
              (rank == bestRank && distance < bestDistance)) {
            bestRank = rank;
            bestDistance = distance;

            best = {
              "activeNow": activeNow,
              "start": startText,
              "end": endText,
              "alarmStartAt": alarmStartAt,
              "alarmEndAt": alarmEndAt,
            };
          }
        }
      }

      return best;
    }

    bool pauseOverlapsEnabledAlarm({
      required DateTime pauseStartAt,
      required DateTime pauseEndAt,
    }) {
      final alarms = enabledDeviceAlarms();
      final checkStartDate = dateOnly(
        pauseStartAt,
      ).subtract(const Duration(days: 1));

      for (final alarm in alarms) {
        final startText = alarm["start"]?.toString() ?? "23:00";
        final endText = alarm["end"]?.toString() ?? "06:00";
        final alarmDays = normalizeAlarmDays(alarm["days"]);
        final startMinutes = toMinutesFromText(startText);
        final endMinutes = toMinutesFromText(endText);

        for (var offset = 0; offset <= 3; offset++) {
          final startDate = checkStartDate.add(Duration(days: offset));

          if (!alarmDays.contains(startDate.weekday)) {
            continue;
          }

          final alarmStartAt = startDate.add(Duration(minutes: startMinutes));
          var alarmEndAt = startDate.add(Duration(minutes: endMinutes));

          if (!alarmEndAt.isAfter(alarmStartAt)) {
            alarmEndAt = alarmEndAt.add(const Duration(days: 1));
          }

          if (intervalsOverlap(
            pauseStartAt,
            pauseEndAt,
            alarmStartAt,
            alarmEndAt,
          )) {
            return true;
          }
        }
      }

      return false;
    }

    final now = DateTime.now();
    final defaultWindow = findBestAlarmWindow(now);
    final fallbackEndAt = now.add(const Duration(minutes: 30));

    TimeOfDay defaultStartTime;
    TimeOfDay defaultEndTime;

    if (defaultWindow == null) {
      defaultStartTime = timeFromDateTime(now);
      defaultEndTime = timeFromDateTime(fallbackEndAt);
    } else if (defaultWindow["activeNow"] == true) {
      final alarmEndAt = defaultWindow["alarmEndAt"] is DateTime
          ? defaultWindow["alarmEndAt"] as DateTime
          : fallbackEndAt;
      final suggestedEndAt = fallbackEndAt.isBefore(alarmEndAt)
          ? fallbackEndAt
          : alarmEndAt;

      defaultStartTime = timeFromDateTime(now);
      defaultEndTime = timeFromDateTime(suggestedEndAt);
    } else {
      defaultStartTime = parseTime(
        defaultWindow["start"]?.toString(),
        timeFromDateTime(now),
      );
      defaultEndTime = parseTime(
        defaultWindow["end"]?.toString(),
        timeFromDateTime(fallbackEndAt),
      );
    }

    final existingEndAt = _resolveAlarmPauseEndAt(alarmPauseToday);
    final hasActiveOrFuturePause =
        alarmPauseToday.isNotEmpty &&
        existingEndAt != null &&
        existingEndAt > DateTime.now().millisecondsSinceEpoch;

    final startTime = parseTime(
      alarmPauseToday["start"]?.toString(),
      defaultStartTime,
    );

    final endTime = parseTime(
      alarmPauseToday["end"]?.toString(),
      defaultEndTime,
    );

    final ownerUid = getHomeOwnerUid();
    final showRemoveButton = hasActiveOrFuturePause;

    await showHomeAlarmPauseSheet(
      context: context,
      initialStartTime: startTime,
      initialEndTime: endTime,
      showRemoveButton: showRemoveButton,
      onPickTime: openTimeTextInput,
      onSave: (sheetContext, data) async {
        final homeName = getSelectedHomeDisplayName();

        final pauseStartText = format(data.startTime);
        final pauseEndText = format(data.endTime);

        if (pauseStartText == pauseEndText) {
          showTopToast(
            sheetContext,
            _strings.t("Giờ bắt đầu và kết thúc không được trùng nhau"),
            color: Colors.orange,
            icon: Icons.schedule_rounded,
          );
          return false;
        }

        final saveNow = DateTime.now();
        final saveCurrentMinuteStart = DateTime(
          saveNow.year,
          saveNow.month,
          saveNow.day,
          saveNow.hour,
          saveNow.minute,
        );
        final saveNowMinutes = saveNow.hour * 60 + saveNow.minute;
        final pauseStartMinutes = toMinutesFromText(pauseStartText);
        final pauseEndMinutes = toMinutesFromText(pauseEndText);
        final isOvernightSelection = pauseStartMinutes > pauseEndMinutes;

        var effectivePauseStartText = pauseStartText;
        var pauseStartAt = dateAtTime(saveNow, data.startTime);
        final startWasPast = pauseStartAt.isBefore(saveCurrentMinuteStart);

        if (startWasPast) {
          if (!isOvernightSelection && pauseEndMinutes <= saveNowMinutes) {
            showTopToast(
              sheetContext,
              _strings.t("Giờ kết thúc phải sau thời điểm hiện tại"),
              color: Colors.orange,
              icon: Icons.schedule_rounded,
            );
            return false;
          }

          pauseStartAt = saveNow;
          effectivePauseStartText = format(timeFromDateTime(saveNow));
        } else if (pauseStartAt.isAtSameMomentAs(saveCurrentMinuteStart)) {
          pauseStartAt = saveNow;
          effectivePauseStartText = format(timeFromDateTime(saveNow));
        }

        var pauseEndAt = dateAtTime(pauseStartAt, data.endTime);

        if (!pauseEndAt.isAfter(pauseStartAt)) {
          pauseEndAt = pauseEndAt.add(const Duration(days: 1));
        }

        final duration = pauseEndAt.difference(pauseStartAt);

        if (duration.inMinutes <= 0 || duration.inHours > 24) {
          showTopToast(
            sheetContext,
            _strings.t("Khoảng tạm tắt không hợp lệ"),
            color: Colors.orange,
            icon: Icons.schedule_rounded,
          );
          return false;
        }

        if (!pauseOverlapsEnabledAlarm(
          pauseStartAt: pauseStartAt,
          pauseEndAt: pauseEndAt,
        )) {
          showTopToast(
            sheetContext,
            _strings.t(
              "Khoảng tạm tắt không trùng với lịch báo động nào đang bật",
            ),
            color: Colors.orange,
            icon: Icons.schedule_rounded,
          );
          return false;
        }

        final createdAt = DateTime.now().millisecondsSinceEpoch;
        final pauseDate = dateKey(pauseStartAt);
        final startAtMs = pauseStartAt.millisecondsSinceEpoch;
        final endAtMs = pauseEndAt.millisecondsSinceEpoch;

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
                "date": pauseDate,
                "start": effectivePauseStartText,
                "end": pauseEndText,
                "startAt": startAtMs,
                "endAt": endAtMs,
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
              fallback: _strings.t("Không lưu được tạm tắt báo động"),
            ),
            color: Colors.red,
            icon: Icons.error_outline_rounded,
          );
          return false;
        }

        if (mounted) {
          setState(() {
            alarmPauseToday = {
              "date": pauseDate,
              "start": effectivePauseStartText,
              "end": pauseEndText,
              "startAt": startAtMs,
              "endAt": endAtMs,
              "homeName": homeName,
              "reason": data.reason,
              "createdByUid": uid,
              "createdByName": userName,
              "createdAt": createdAt,
            };
          });
          _syncAlarmPauseExpiryTimer();
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
              fallback: _strings.t("Không xoá được lịch tạm tắt báo động"),
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
          _syncAlarmPauseExpiryTimer();
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

    message = _strings.homeInfoUpdatedMessage(
      actorName: actorName,
      newName: newName,
      nameChanged: nameChanged,
      addressChanged: addressChanged,
    );

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
        "type": "home_updated",
        "actorName": actorName,
        "oldName": oldName,
        "newName": newName,
        "oldAddress": oldAddress,
        "newAddress": newAddress,
        "homeName": newName,
      },
    );
  }

  void renameDevice(String id) async {
    final oldDeviceName = getDevices()[id]?["name"]?.toString() ?? id;
    String inputName = oldDeviceName.trim();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_strings.t("Thay tên")),
          content: TextFormField(
            initialValue: oldDeviceName,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (value) {
              inputName = value.trim();
            },
            onFieldSubmitted: (_) {
              if (inputName.isEmpty) return;
              Navigator.of(dialogContext).pop(inputName);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_strings.t("Hủy")),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputName.isEmpty) return;
                Navigator.of(dialogContext).pop(inputName);
              },
              child: Text(_strings.t("OK")),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
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

    try {
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
        message: _strings.deviceRenamedMessage(
          actorName: actorName,
          oldDeviceName: oldDeviceName,
          newName: newName,
          homeName: homeName,
        ),
        deviceId: id,
        entityType: "device",
        entityId: id,
        homeName: homeName,
        includeActor: true,
        data: {
          "type": "device_renamed",
          "actorName": actorName,
          "deviceName": newName,
          "oldDeviceName": oldDeviceName,
          "newDeviceName": newName,
          "oldName": oldDeviceName,
          "newName": newName,
          "homeName": homeName,
        },
      );
    } catch (e) {
      if (!mounted) return;

      showTopToast(
        context,
        _strings.sanitizeUserMessage(
          e.toString(),
          fallback: _strings.genericOperationError,
        ),
        color: Colors.red,
        icon: Icons.error_rounded,
      );
    }
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
                "${_strings.firebaseRulesPassedSummary(passCount: passCount, total: results.length)}$lines",
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

}
