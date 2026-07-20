import 'package:flutter/material.dart';

import '../../widgets/room_tabs.dart';
import '../../widgets/status_panel.dart';

class HomeOverviewHeader extends StatelessWidget {
  const HomeOverviewHeader({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.homeName,
    required this.alarmPauseText,
    required this.onAlarmPauseToday,
    required this.environmentText,
    required this.homeEvents,
    required this.onEnvironmentTap,
    required this.overall,
    required this.securityMode,
    required this.securityModeSource,
    required this.securityModeRepeatMinutes,
    required this.onSecurityModeRepeatChanged,
    required this.onSecurityModeChanged,
    required this.onScheduleNotification,
    required this.onScheduleAlarm,
    required this.alarmStart,
    required this.alarmEnd,
    required this.rooms,
    required this.selectedRoomId,
    required this.onSelectRoom,
    required this.onReorderRooms,
    required this.pairingCountdown,
    required this.pairingCountdownText,
    required this.sectionGap,
  });

  final String ownerUid;
  final String homeId;
  final String homeName;
  final String alarmPauseText;
  final VoidCallback onAlarmPauseToday;
  final String environmentText;
  final Map<String, dynamic> homeEvents;
  final VoidCallback onEnvironmentTap;
  final Map<String, dynamic> overall;
  final String securityMode;
  final String securityModeSource;
  final int securityModeRepeatMinutes;
  final Future<bool> Function(int minutes)? onSecurityModeRepeatChanged;
  final ValueChanged<String> onSecurityModeChanged;
  final VoidCallback onScheduleNotification;
  final VoidCallback onScheduleAlarm;
  final String alarmStart;
  final String alarmEnd;
  final Map<String, dynamic> rooms;
  final String selectedRoomId;
  final ValueChanged<String> onSelectRoom;
  final Future<void> Function(List<String> roomIds) onReorderRooms;
  final int pairingCountdown;
  final String pairingCountdownText;
  final double sectionGap;

  String _statusPanelKey() {
    final issues = List<String>.from(overall["issues"] ?? const []);
    final safeSummary = List<String>.from(overall["safeSummary"] ?? const []);
    final presenceWarnings = List<String>.from(
      overall["presenceWarnings"] ?? const [],
    );

    return [
      "status",
      ownerUid,
      homeId,
      overall["level"]?.toString() ?? "",
      issues.join("|"),
      presenceWarnings.join("|"),
      safeSummary.join("|"),
    ].join("|");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StatusPanel(
          key: ValueKey(_statusPanelKey()),
          ownerUid: ownerUid,
          homeId: homeId,
          alarmPauseText: alarmPauseText,
          onAlarmPauseToday: onAlarmPauseToday,
          environmentText: environmentText,
          homeEvents: homeEvents,
          onEnvironmentTap: onEnvironmentTap,
          overall: overall,
          securityMode: securityMode,
          securityModeSource: securityModeSource,
          securityModeRepeatMinutes: securityModeRepeatMinutes,
          onSecurityModeRepeatChanged: onSecurityModeRepeatChanged,
          // Luôn nhận thao tác bấm.
          // setSecurityMode sẽ tự kiểm tra quyền
          // và báo rõ cho member.
          onSecurityModeChanged: onSecurityModeChanged,
          onPair: null,
          onQR: null,
          onScheduleNotification: onScheduleNotification,
          onScheduleAlarm: onScheduleAlarm,
          alarmStart: alarmStart,
          alarmEnd: alarmEnd,
        ),
        SizedBox(height: sectionGap),
        RoomTabs(
          rooms: rooms,
          homeName: homeName,
          selectedRoomId: selectedRoomId,
          onSelect: onSelectRoom,
          onReorder: onReorderRooms,
        ),
        if (pairingCountdown > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(pairingCountdownText),
          ),
      ],
    );
  }
}
