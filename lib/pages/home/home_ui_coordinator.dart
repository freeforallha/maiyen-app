import 'package:flutter/material.dart';

import '../../helpers/home_helper.dart';
import '../../sheets/account_avatar_sheet.dart';
import '../../sheets/alarm_device_sheet.dart';
import '../../sheets/all_devices_sheet.dart';
import '../../sheets/device_detail_sheet.dart';
import '../../sheets/home_chat_sheet.dart';
import '../../sheets/home_event_sheet.dart';
import '../../sheets/notification_list_sheet.dart' as notif_sheet;
import '../../sheets/room_management_sheet.dart';
import '../../sheets/schedule_sheet.dart';
import '../../sheets/settings_sheet.dart';
import '../../sheets/share_list_sheet.dart';
import '../../sheets/share_request_sheet.dart';
import '../edit_profile_page.dart';

class HomeUiCoordinator {
  static void openDeviceDetail({
    required BuildContext context,
    required String deviceId,
    required Map<String, dynamic> device,
    required String ownerUid,
    required String homeId,
    required VoidCallback? onRename,
    required VoidCallback? onDelete,
    required VoidCallback onNotification,
    required bool canManageAlarmPolicy,
  }) {
    showDeviceDetail(
      context: context,
      id: deviceId,
      d: device,
      ownerUid: ownerUid,
      homeId: homeId,
      onRename: onRename,
      onDelete: onDelete,
      onNotification: onNotification,
      canManageAlarmPolicy: canManageAlarmPolicy,
    );
  }

  static void openAllDevices({
    required BuildContext context,
    required Map<String, dynamic> devices,
    required VoidCallback onEmpty,
    required void Function(String deviceId, Map<String, dynamic> device)
    onOpenDevice,
  }) {
    if (devices.isEmpty) {
      onEmpty();
      return;
    }

    if (devices.length == 1) {
      final entry = devices.entries.first;

      Navigator.pop(context);

      onOpenDevice(entry.key.toString(), safeMap(entry.value));
      return;
    }

    showAllDevicesSheet(
      context: context,
      devices: devices,
      onTapDevice: (id) {
        onOpenDevice(id, safeMap(devices[id]));
      },
    );
  }

  static void openChat({
    required BuildContext context,
    required String homeId,
    required String homeName,
    required String userName,
    required String userPhotoUrl,
    required String ownerUid,
    required bool canManageMembers,
    required bool isOwner,
  }) {
    showHomeChatSheet(
      context: context,
      homeId: homeId,
      homeName: homeName,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      ownerUid: ownerUid,
      canManageMembers: canManageMembers,
      isOwner: isOwner,
    );
  }

  static void openDeviceNotificationList({
    required BuildContext context,
    required String ownerUid,
    required String homeId,
    required String deviceId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return notif_sheet.NotificationListSheet(
          ownerUid: ownerUid,
          homeId: homeId,
          deviceId: deviceId,
        );
      },
    );
  }

  static void openHomeNotificationList({
    required BuildContext context,
    required String uid,
    required String Function(String homeId) homeNameForId,
    required Future<void> Function(Map<String, dynamic> notification)
    onTapNotification,
  }) {
    showHomeEventSheet(
      context: context,
      uid: uid,
      homeNameForId: homeNameForId,
      onTapNotification: onTapNotification,
    );
  }

  static void openScheduleSheet({
    required BuildContext context,
    required String ownerUid,
    required String homeId,
    required bool isShared,
    required String type,
    required bool canManageHome,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleSheet(
        ownerUid: ownerUid,
        homeId: homeId,
        isShared: isShared,
        type: type,
        canManageHome: canManageHome,
      ),
    );
  }

  static void openAlarmDeviceSheet({
    required BuildContext context,
    required String ownerUid,
    required String homeId,
    required Map<String, dynamic> devices,
    required bool canManageHome,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlarmDeviceSheet(
        ownerUid: ownerUid,
        homeId: homeId,
        devices: devices,
        canManageHome: canManageHome,
      ),
    );
  }

  static void openAccount({
    required BuildContext context,
    required VoidCallback logout,
    required String userName,
    required String userGender,
    required String userDob,
    required String userPhone,
    required ValueNotifier<int> inviteCountNotifier,
    required VoidCallback onShareRequests,
  }) {
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
      onShareRequests: onShareRequests,
    );
  }

  static void openSettings({
    required BuildContext context,
    required String homeId,
    required String ownerUid,
    required String homeName,
    required String homeAddress,
    required String role,
    required VoidCallback onShareRequests,
    required VoidCallback onShare,
    required VoidCallback onShareList,
    required VoidCallback onRooms,
    required VoidCallback onAutoAway,
    required VoidCallback onLogout,
    required VoidCallback onRenameHome,
    required VoidCallback onSecurityTest,
    required VoidCallback onDeleteHome,
    required ValueNotifier<int> inviteCountNotifier,
    required VoidCallback onTransferOwner,
    required VoidCallback onAllDevices,
    required VoidCallback onAccount,
  }) {
    showSettingsSheet(
      homeId: homeId,
      ownerUid: ownerUid,
      homeName: homeName,
      homeAddress: homeAddress,
      role: role,
      onAllDevices: onAllDevices,
      onAccount: onAccount,
      onDeleteHome: onDeleteHome,
      onRenameHome: onRenameHome,
      onSecurityTest: onSecurityTest,
      onTransferOwner: onTransferOwner,
      context: context,
      inviteCountNotifier: inviteCountNotifier,
      onShareRequests: onShareRequests,
      onShare: onShare,
      onAutoAway: onAutoAway,
      onRooms: onRooms,
      onShareList: onShareList,
      onLogout: onLogout,
    );
  }

  static Future<bool?> openShareList({
    required BuildContext context,
    required bool canManageMembers,
    required bool isOwner,
    required String ownerUid,
    required String homeId,
    required String homeName,
  }) {
    return showShareListSheet(
      canManageMembers: canManageMembers,
      isOwner: isOwner,
      context: context,
      ownerUid: ownerUid,
      homeId: homeId,
      homeName: homeName,
    );
  }

  static Future<bool?> openShareRequests({
    required BuildContext context,
    required Map<String, dynamic> requests,
    required String uid,
  }) {
    return showShareRequestSheet(
      context: context,
      requests: requests,
      uid: uid,
    );
  }

  static void openRoomManagement({
    required BuildContext context,
    required String ownerUid,
    required String homeId,
  }) {
    showRoomManagementSheet(
      context: context,
      ownerUid: ownerUid,
      homeId: homeId,
    );
  }
}
