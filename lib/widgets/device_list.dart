import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/emergency_pulse_ticker.dart';
import '../helpers/home_helper.dart';
import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../maiyen_theme.dart';
import '../navigation/maiyen_navigation.dart';
import '../services/notification_service.dart';
import '../sheets/device_alarm_policy_sheet.dart';
import '../config/maiyen_identifiers.dart';

part 'device_list/device_list_status_part.dart';
part 'device_list/device_list_ordering_part.dart';
part 'device_list/device_list_presentation_part.dart';
part 'device_list/device_list_layout_part.dart';

class DeviceList extends StatefulWidget {
  final String homeId;
  final String ownerUid;
  final String hubId;
  final Map<String, dynamic> devices;
  final String selectedRoomId;
  final String securityMode;
  final Map<String, dynamic> personalAlarmRules;
  final bool isShared;
  final String ownerEmail;
  final Widget? header;
  final double bottomPadding;

  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;
  final void Function(Map<String, dynamic> devices)? onTapInfrastructureGroup;
  final VoidCallback onPairSensor;

  const DeviceList({
    this.header,
    super.key,
    required this.homeId,
    required this.ownerUid,
    required this.hubId,
    required this.devices,
    required this.isShared,
    required this.ownerEmail,
    required this.onRename,
    required this.onDelete,
    required this.onTapDevice,
    this.onTapInfrastructureGroup,
    required this.onPairSensor,
    required this.selectedRoomId,
    this.securityMode = "normal",
    this.personalAlarmRules = const <String, dynamic>{},
    this.bottomPadding = 28,
  });

  @override
  State<DeviceList> createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  StreamSubscription<DatabaseEvent>? _deviceOrderSubscription;
  final Map<String, GlobalKey> _sectionGridKeys = {};
  String? _draggingDeviceId;
  String? _draggingSectionKey;
  List<String>? _draggingSectionOrder;
  Offset _draggingCardOffset = Offset.zero;
  Offset _draggingPointerOffset = Offset.zero;
  bool _draggingDeviceDropping = false;
  bool _mutingHomeSiren = false;
  bool _sirenAlertPulseDanger = false;
  Timer? _deviceDropTimer;
  Timer? _emergencyExpiryTimer;
  final Set<String> _acknowledgingEmergencyDeviceIds = <String>{};
  final Set<String> _locallyAcknowledgedEmergencyTriggers = <String>{};
  Map<String, Map<String, int>> _deviceOrderMap = {};
  Map<String, Map<String, int>> _localDeviceOrderMap = {};
  Map<String, Map<String, int>> _optimisticDeviceOrderMap = {};

  Map<String, dynamic> get devices => widget.devices;
  String get selectedRoomId => widget.selectedRoomId;
  String get securityMode => widget.securityMode;
  Widget? get header => widget.header;
  double get bottomPadding => widget.bottomPadding;
  VoidCallback get onPairSensor => widget.onPairSensor;
  Function(String) get onTapDevice => widget.onTapDevice;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? "";
  String get _homeId => widget.homeId.trim();
  String get _ownerUid => widget.ownerUid.trim();
  String get _hubId => widget.hubId.trim();

  static const String _deviceOrderRoot = "deviceOrder";

  @override
  void initState() {
    super.initState();
    EmergencyPulseTicker.ensureStarted();
    _sirenAlertPulseDanger = EmergencyPulseTicker.phase.value;
    EmergencyPulseTicker.phase.addListener(_handleSharedEmergencyPulse);
    _startDeviceOrderListener();
    _syncSirenAlertPulse();
    _syncEmergencyExpiryTimer();
  }

  @override
  void didUpdateWidget(covariant DeviceList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.homeId != widget.homeId ||
        oldWidget.ownerUid != widget.ownerUid) {
      _deviceOrderMap = {};
      _localDeviceOrderMap = {};
      _optimisticDeviceOrderMap = {};
      _acknowledgingEmergencyDeviceIds.clear();
      _locallyAcknowledgedEmergencyTriggers.clear();
      _clearDeviceDragState();
      _startDeviceOrderListener();
    }

    _syncSirenAlertPulse();
    _syncEmergencyExpiryTimer();
  }

  @override
  void dispose() {
    EmergencyPulseTicker.phase.removeListener(_handleSharedEmergencyPulse);
    _deviceOrderSubscription?.cancel();
    _deviceDropTimer?.cancel();
    _emergencyExpiryTimer?.cancel();
    super.dispose();
  }

  bool get _canReorderDevices => _currentUid.isNotEmpty && _homeId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final securityEntries = _groupEntries("An ninh ra/vào");
    final emergencyEntries = _groupEntries("Nguy hiểm khẩn cấp");
    final infrastructureEntries = _groupEntries("Điều khiển & hạ tầng");
    final infrastructureTypeGroups = _groupInfrastructureEntriesByType(
      infrastructureEntries,
    );

    return Column(
      children: [
        ?header,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final spacing = compact ? 10.0 : 14.0;
              final contentWidth = constraints.maxWidth - 24;
              final itemWidth = (contentWidth - spacing) / 2;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(12, 6, 12, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (securityEntries.isNotEmpty)
                      _sectionHeader(
                        title: strings.t("An ninh ra/vào"),
                        count: securityEntries.length,
                        showAddButton: true,
                        onTap: () {
                          _openDeviceCategoryPage(
                            groupName: "An ninh ra/vào",
                            title: strings.t("An ninh ra/vào"),
                            entries: securityEntries,
                          );
                        },
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: _addDeviceButton(),
                        ),
                      ),
                    if (securityEntries.isEmpty)
                      _emptySecurityState(strings)
                    else
                      _reorderableDeviceSection(
                        groupName: "An ninh ra/vào",
                        entries: securityEntries,
                        spacing: spacing,
                        itemWidth: itemWidth,
                        compact: compact,
                        strings: strings,
                      ),
                    if (emergencyEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader(
                        title: strings.t("Nguy hiểm khẩn cấp"),
                        count: emergencyEntries.length,
                        showAddButton: false,
                        onTap: () {
                          _openDeviceCategoryPage(
                            groupName: "Nguy hiểm khẩn cấp",
                            title: strings.t("Nguy hiểm khẩn cấp"),
                            entries: emergencyEntries,
                          );
                        },
                      ),
                      _reorderableDeviceSection(
                        groupName: "Nguy hiểm khẩn cấp",
                        entries: emergencyEntries,
                        spacing: spacing,
                        itemWidth: itemWidth,
                        compact: compact,
                        strings: strings,
                      ),
                    ],
                    if (infrastructureEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader(
                        title: strings.t("Điều khiển & hạ tầng"),
                        count: infrastructureEntries.length,
                        showAddButton: false,
                        onTap: () {
                          _openDeviceCategoryPage(
                            groupName: "Điều khiển & hạ tầng",
                            title: strings.t("Điều khiển & hạ tầng"),
                            entries: infrastructureEntries,
                          );
                        },
                      ),
                      _infrastructureTypeGrid(
                        groups: infrastructureTypeGroups,
                        spacing: spacing,
                        itemWidth: itemWidth,
                        compact: compact,
                        strings: strings,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
