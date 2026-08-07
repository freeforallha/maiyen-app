import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import '../pages/home/home_data_helpers.dart';
import '../helpers/emergency_pulse_ticker.dart';
import '../maiyen_theme.dart';
import '../localization/app_strings.dart';
import '../navigation/maiyen_navigation.dart';
import '../services/notification_service.dart';

part 'status_panel/status_panel_status_part.dart';
part 'status_panel/status_panel_security_part.dart';
part 'status_panel/status_panel_summary_part.dart';
part 'status_panel/status_panel_siren_part.dart';
part 'status_panel/status_panel_layout_part.dart';

class StatusPanel extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final Map<String, dynamic> overall;
  final VoidCallback? onPair;
  final VoidCallback? onQR;
  final String alarmStart;
  final String alarmEnd;
  final String environmentText;
  final Map<String, dynamic> homeEvents;
  final VoidCallback? onEnvironmentTap;
  final String securityMode;
  final ValueChanged<String>? onSecurityModeChanged;
  final String securityModeSource;
  final int securityModeRepeatMinutes;
  final Future<bool> Function(int minutes)? onSecurityModeRepeatChanged;

  final VoidCallback? onAlarmPauseToday;

  final VoidCallback? onScheduleNotification;
  final VoidCallback? onScheduleAlarm;
  final String alarmPauseText;

  const StatusPanel({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.overall,
    required this.onPair,
    required this.onQR,
    required this.alarmStart,
    required this.alarmEnd,
    required this.environmentText,
    required this.homeEvents,
    this.onEnvironmentTap,
    this.securityMode = "normal",
    this.securityModeSource = "",
    this.securityModeRepeatMinutes = 0,
    this.onSecurityModeChanged,
    this.onSecurityModeRepeatChanged,
    this.onAlarmPauseToday,
    this.onScheduleNotification,
    this.onScheduleAlarm,
    required this.alarmPauseText,
  });

  @override
  State<StatusPanel> createState() => _StatusPanelState();
}

class _StatusPanelState extends State<StatusPanel> {
  Timer? _timer;
  bool _emergencyPulseDanger = false;
  bool _mutingHomeSiren = false;
  AppStrings get _strings => AppStrings.of(context);
  int _broadcastIndex = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        _broadcastIndex++;
      });
    });

    EmergencyPulseTicker.ensureStarted();
    _emergencyPulseDanger = EmergencyPulseTicker.phase.value;
    EmergencyPulseTicker.phase.addListener(_handleSharedEmergencyPulse);
    _syncEmergencyPulse();
  }

  @override
  void didUpdateWidget(covariant StatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEmergencyPulse();
  }

  bool get _hasEmergencyStatus =>
      widget.overall["level"]?.toString() == "emergency";

  void _handleSharedEmergencyPulse() {
    if (!mounted || !_hasEmergencyStatus) {
      return;
    }

    final next = EmergencyPulseTicker.phase.value;
    if (_emergencyPulseDanger == next) {
      return;
    }

    setState(() {
      _emergencyPulseDanger = next;
    });
  }

  void _syncEmergencyPulse() {
    _emergencyPulseDanger = _hasEmergencyStatus
        ? EmergencyPulseTicker.phase.value
        : false;
  }

  @override
  void dispose() {
    EmergencyPulseTicker.phase.removeListener(_handleSharedEmergencyPulse);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildStatusPanel(context);
}
