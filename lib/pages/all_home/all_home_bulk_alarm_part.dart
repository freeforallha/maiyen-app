part of '../all_home_page.dart';

extension _AllHomeBulkAlarmPart on _AllHomeState {
  Future<void> setSelectedHomesAlarm() async {
    final action = await MaiYenNavigation.showModalSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (actionSheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.orange,
                  ),
                  title: Text(_strings.t("Đặt nhắc nhở cho nhà")),
                  subtitle: Text(selectedHomeCountText()),
                  onTap: () => Navigator.pop(actionSheetContext, "reminder"),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.shield_moon_rounded,
                    color: Colors.red,
                  ),
                  title: Text(_strings.t("Đặt báo động cho nhà")),
                  subtitle: Text(selectedHomeCountText()),
                  onTap: () => Navigator.pop(actionSheetContext, "alarm"),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    if (!mounted) return;

    // Chờ bottom sheet đóng hoàn toàn trước khi mở dialog kế tiếp.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    final isReminderAction = action == "reminder";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmDialogContext) => AlertDialog(
        title: Text(
          isReminderAction
              ? _strings.t("Xác nhận thay đổi nhắc nhở")
              : _strings.t("Xác nhận thay đổi báo động"),
        ),
        content: Text(
          isReminderAction
              ? _strings.t(
                  "Thao tác này sẽ thêm nhắc nhở cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng nhắc nhở 'Theo nhà' sẽ bị ảnh hưởng.\nNhắc nhở cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.",
                )
              : _strings.t(
                  "Thao tác này sẽ thay đổi lịch báo động của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng báo động 'Theo nhà' sẽ bị ảnh hưởng.\nBáo động cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.",
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmDialogContext, false),
            child: Text(_strings.t("Huỷ")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(confirmDialogContext, true),
            child: Text(_strings.t("Tiếp tục")),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Tránh mở dialog chọn giờ khi dialog xác nhận vẫn đang chạy animation đóng.
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    final uid = currentUser.uid;
    final updates = <String, dynamic>{};

    int updatedHomes = 0;
    int updatedDevices = 0;
    int skippedHomes = 0;
    int selectedAlarmRepeatMinutes = 30;

    if (action == "reminder") {
      final time = await _inputSelectedHomesAlarmTime(_strings.t("Giờ nhắc nhở"), "22:30");
      if (time == null) return;

      for (final homeId in selectedHomes) {
        final home = safeMap(homes[homeId]);
        final isShared = home["_shared"] == true;
        final role = home["_role"]?.toString() ?? "member";

        final canManage = !isShared || role == "owner" || role == "admin";

        if (!canManage) {
          skippedHomes++;
          continue;
        }

        final ownerUid = isShared ? home["_ownerUid"]?.toString() ?? uid : uid;
        final schedules = safeMap(home["schedules"]);
        final currentNotificationsRaw = schedules["notifications"];

        final currentNotifications = currentNotificationsRaw is List
            ? List<Map<String, dynamic>>.from(
                currentNotificationsRaw.map(
                  (e) => Map<String, dynamic>.from(e),
                ),
              )
            : <Map<String, dynamic>>[];

        currentNotifications.add({"enabled": true, "time": time});

        updates["accounts/$ownerUid/homes/$homeId/schedules/notifications"] =
            currentNotifications;

        updatedHomes++;
      }
    }

    if (action == "alarm") {
      final alarmConfig = await _inputSelectedHomesAlarmConfig();
      if (alarmConfig == null) return;

      final repeatMinutes =
          (alarmConfig["repeatMinutes"] as num?)?.toInt() ?? 30;

      selectedAlarmRepeatMinutes = repeatMinutes;

      final alarmData = {
        "enabled": true,
        "start": alarmConfig["start"]?.toString() ?? "23:00",
        "end": alarmConfig["end"]?.toString() ?? "06:00",
        "repeatMinutes": repeatMinutes,
        "days": List<int>.from(
          alarmConfig["days"] as List? ?? const [1, 2, 3, 4, 5, 6, 7],
        ),
      };

      for (final homeId in selectedHomes) {
        final home = safeMap(homes[homeId]);
        final isShared = home["_shared"] == true;
        final role = home["_role"]?.toString() ?? "member";

        final canManage = !isShared || role == "owner" || role == "admin";

        if (!canManage) {
          skippedHomes++;
          continue;
        }

        final ownerUid = isShared ? home["_ownerUid"]?.toString() ?? uid : uid;
        final devices = safeMap(home["devices"]);

        var homeUpdated = false;

        for (final entry in devices.entries) {
          final deviceId = entry.key;
          final device = safeMap(entry.value);
          final type = device["type"]?.toString();

          final isSecurity = isSecurityDeviceType(type);

          if (!isSecurity) continue;

          final devicePath =
              "accounts/$ownerUid/homes/$homeId/devices/$deviceId";

          final existingSchedules = safeMap(device["alarmSchedules"]);
          final duplicateScheduleIds = existingSchedules.entries
              .where((scheduleEntry) {
                final schedule = safeMap(scheduleEntry.value);
                return schedule["start"]?.toString() == alarmData["start"] &&
                    schedule["end"]?.toString() == alarmData["end"];
              })
              .map((scheduleEntry) => scheduleEntry.key)
              .toList(growable: false);
          final targetScheduleId = duplicateScheduleIds.isEmpty
              ? "quick_all_home"
              : duplicateScheduleIds.first;

          // Không tạo thêm node khi đã có lịch trùng hoàn toàn giờ. Nếu dữ
          // liệu cũ từng có nhiều bản trùng, giữ một bản và dọn các bản còn lại.
          updates["$devicePath/alarmSchedules/$targetScheduleId"] = alarmData;
          for (final duplicateId in duplicateScheduleIds.skip(1)) {
            updates["$devicePath/alarmSchedules/$duplicateId"] = null;
          }
          updates["$devicePath/alarm"] = null;

          updatedDevices++;
          homeUpdated = true;
        }

        if (homeUpdated) {
          updatedHomes++;
        }
      }
    }
    if (!mounted) return;
    if (updates.isEmpty) {
      showTopToast(
        context,
        _strings.t("Không có nhà nào đủ điều kiện để cài"),
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    await FirebaseDatabase.instance.ref().update(updates);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_strings.t("Cài đặt hoàn tất")),
        content: Text(
          action == "reminder"
              ? _strings.allHomeReminderAppliedText(updatedHomes, skippedHomes)
              : _strings.allHomeAlarmAppliedText(
                  updatedDevices: updatedDevices,
                  updatedHomes: updatedHomes,
                  repeatLabel: _selectedHomesAlarmRepeatLabel(selectedAlarmRepeatMinutes),
                  skippedHomes: skippedHomes,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_strings.t("OK")),
          ),
        ],
      ),
    );
  }
}
