part of '../home_page.dart';

extension _Navigation on _MaiYenState {
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
    Map<String, dynamic>? selectableDevices,
  }) {
    HomeUiCoordinator.openDeviceDetail(
      context: context,
      deviceId: deviceId,
      device: device,
      ownerUid: getHomeOwnerUid(),
      homeId: selectedHome,
      onRename: canManageHome() ? renameDevice : null,
      onDelete: canManageHome() ? deleteDevice : null,
      onNotification: openNotificationList,
      canManageAlarmPolicy: canManageHome(),
      selectableDevices: selectableDevices,
    );
  }

  void openSelectedDeviceDetail(String deviceId) {
    openDeviceDetailSheet(
      deviceId: deviceId,
      device: safeMap(getDevices()[deviceId]),
    );
  }

  void openInfrastructureDeviceDetail(
    Map<String, dynamic> infrastructureDevices,
  ) {
    if (infrastructureDevices.isEmpty) {
      return;
    }

    final firstEntry = infrastructureDevices.entries.first;

    openDeviceDetailSheet(
      deviceId: firstEntry.key,
      device: safeMap(firstEntry.value),
      selectableDevices: infrastructureDevices,
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

      securityMode = _homeAlarmSecurityService.normalizeSecurityMode(
        currentHome["securityMode"],
      );

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

  void _handleHubUpdateOpenRequest() {
    final request = NotificationService.hubUpdateOpenRequest.value;

    if (request == null) {
      return;
    }

    _pendingHubUpdateOpenRequest = Map<String, String>.from(request);
    unawaited(_tryOpenPendingHubUpdate());
  }

  Future<void> _tryOpenPendingHubUpdate() async {
    if (!mounted || _openingHubUpdateFromNotification) {
      return;
    }

    final request = _pendingHubUpdateOpenRequest;

    if (request == null) {
      return;
    }

    final currentRoute = ModalRoute.of(context);

    if (currentRoute != null && !currentRoute.isCurrent) {
      return;
    }

    final homeId = request['homeId']?.trim() ?? '';

    if (homeId.isEmpty || !homes.containsKey(homeId)) {
      return;
    }

    final home = safeMap(homes[homeId]);
    final storedOwnerUid = home['_ownerUid']?.toString().trim() ?? '';
    final ownerUid = storedOwnerUid.isNotEmpty ? storedOwnerUid : uid;

    if (ownerUid.isEmpty) {
      return;
    }

    _openingHubUpdateFromNotification = true;
    _pendingHubUpdateOpenRequest = null;
    NotificationService.hubUpdateOpenRequest.value = null;

    selectHomeFromNotification(homeId);

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));

    if (!mounted || selectedHome != homeId || !homes.containsKey(homeId)) {
      _openingHubUpdateFromNotification = false;
      return;
    }

    showHubInfoSheet(
      context: context,
      ownerUid: ownerUid,
      homeId: homeId,
      homeName: getHomeDisplayName(homeId),
    );

    _openingHubUpdateFromNotification = false;
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

  Future<void> showAlarmPauseReminder() async {
    await showAlarmPauseReminderDialog(context: context, strings: _strings);
  }

  Future<void> openAlarmPauseSheetWithReminder() async {
    final alarmScheduleText = formatAlarmSchedules().trim();
    final alarmScheduleConfigured =
        alarmScheduleText.isNotEmpty &&
        alarmScheduleText != _strings.t("Tắt") &&
        alarmScheduleText != _strings.t("Chưa thiết lập thời gian");

    if (!alarmScheduleConfigured) {
      showTopToast(
        context,
        _strings.choose(
          vi: "Chưa cài đặt báo động nào",
          en: "No alarm has been set",
          zh: "尚未设置任何警报",
          ko: "설정된 경보가 없습니다",
          ja: "警報は設定されていません",
          de: "Es ist kein Alarm eingerichtet",
          ru: "Ни одна тревога не настроена",
          fr: "Aucune alarme n’est configurée",
          es: "No hay ninguna alarma configurada",
          id: "Belum ada alarm yang diatur",
          th: "ยังไม่ได้ตั้งค่าสัญญาณเตือน",
          ms: "Tiada penggera ditetapkan",
          fil: "Wala pang nakatakdang alarma",
          km: "មិនទាន់បានកំណត់សំឡេងរោទិ៍ទេ",
          my: "အချက်ပေးစနစ် မသတ်မှတ်ရသေးပါ",
          lo: "ຍັງບໍ່ໄດ້ຕັ້ງຄ່າສັນຍານເຕືອນໄພ",
          ta: "எந்த அலாரமும் அமைக்கப்படவில்லை",
          pt: "Nenhum alarme foi configurado",
          tet: "Alarme ida seidauk tau",
        ),
        color: MaiYenColors.warning,
        icon: Icons.schedule_rounded,
      );
      return;
    }

    await showAlarmPauseReminder();

    if (!mounted) return;

    showAlarmPauseSheet();
  }

  Future<bool> _confirmManualSecurityMode() async {
    return showConfirmManualSecurityModeDialog(
      context: context,
      strings: _strings,
    );
  }

  Future<bool> _confirmUnprotectedMode() async {
    return showConfirmUnprotectedModeDialog(
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
          _strings.t("Không thể xác nhận tài khoản hiện tại"),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return false;
      case HomeSecurityReauthStatus.wrongPassword:
        showTopToast(
          context,
          _strings.t("Mật khẩu không đúng"),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );
        return false;
      case HomeSecurityReauthStatus.failed:
        showTopToast(
          context,
          _strings.t("Không thể xác nhận mật khẩu"),
          color: Colors.red,
          icon: Icons.error_outline_rounded,
        );

        return false;
    }
  }

}
