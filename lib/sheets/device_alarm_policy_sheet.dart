import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../safehome_theme.dart';
import '../widgets/ios_alarm_platform_notice.dart';

const Set<String> _emergencyAlarmDeviceTypes = {
  'smoke',
  'heat',
  'carbon_monoxide',
  'gas',
  'water_leak',
  'flood',
  'sos',
};

const Set<String> _securityAlarmDeviceTypes = {
  'door',
  'window',
  'gate',
  'lock',
  'door_lock',
  'motion',
  'presence',
  'vibration',
  'glass_break',
};

const int deviceAlarmScheduleModelVersion = 7;

bool supportsDeviceAlarmPolicy(String deviceType) {
  final normalized = deviceType.trim().toLowerCase();
  return _emergencyAlarmDeviceTypes.contains(normalized) ||
      _securityAlarmDeviceTypes.contains(normalized);
}

bool isEmergencyAlarmPolicyDevice(String deviceType) {
  return _emergencyAlarmDeviceTypes.contains(deviceType.trim().toLowerCase());
}

bool isSecurityAlarmPolicyDevice(String deviceType) {
  return _securityAlarmDeviceTypes.contains(deviceType.trim().toLowerCase());
}

class DeviceAlarmPolicySettings {
  final bool enabled;
  final bool notificationEnabled;
  final bool physicalSirenEnabled;
  final bool fullscreenEnabled;

  const DeviceAlarmPolicySettings({
    required this.enabled,
    required this.notificationEnabled,
    required this.physicalSirenEnabled,
    required this.fullscreenEnabled,
  });

  factory DeviceAlarmPolicySettings.fromDevice({
    required Map<String, dynamic> device,
    required String deviceType,
  }) {
    final rawPolicy = device['alarmPolicy'];
    final policy = rawPolicy is Map
        ? Map<String, dynamic>.from(rawPolicy)
        : const <String, dynamic>{};
    final isEmergency = isEmergencyAlarmPolicyDevice(deviceType);

    return DeviceAlarmPolicySettings(
      enabled: isEmergency ? true : policy['enabled'] != false,
      // Dữ liệu cũ chưa có trường này luôn gửi thông báo.
      notificationEnabled: policy['notificationEnabled'] != false,
      physicalSirenEnabled: policy['physicalSirenEnabled'] != false,
      fullscreenEnabled: policy['fullscreenEnabled'] != false,
    );
  }

  Map<String, dynamic> toFirebaseMap() => {
    'enabled': enabled,
    'notificationEnabled': notificationEnabled,
    'physicalSirenEnabled': physicalSirenEnabled,
    'fullscreenEnabled': fullscreenEnabled,
  };
}

class DevicePersonalAlarmPreferences {
  final bool notificationEnabled;
  final bool fullscreenEnabled;
  final bool followHomeSchedule;
  final int scheduleModelVersion;

  const DevicePersonalAlarmPreferences({
    required this.notificationEnabled,
    required this.fullscreenEnabled,
    this.followHomeSchedule = true,
    this.scheduleModelVersion = deviceAlarmScheduleModelVersion,
  });

  bool get usesUnifiedSchedules => scheduleModelVersion >= 2;

  factory DevicePersonalAlarmPreferences.fromCustomDevice({
    required Map<String, dynamic> customDevice,
    required bool legacyFullscreenEnabled,
  }) {
    final raw = customDevice['alarmPreferences'];
    final preferences = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    final rawVersion = preferences['scheduleModelVersion'];
    final parsedVersion = rawVersion is num
        ? rawVersion.toInt()
        : int.tryParse(rawVersion?.toString() ?? '');

    return DevicePersonalAlarmPreferences(
      notificationEnabled: preferences['notificationEnabled'] is bool
          ? preferences['notificationEnabled'] == true
          : true,
      fullscreenEnabled: preferences['fullscreenEnabled'] is bool
          ? preferences['fullscreenEnabled'] == true
          : legacyFullscreenEnabled,
      followHomeSchedule: preferences['followHomeSchedule'] is bool
          ? preferences['followHomeSchedule'] == true
          : true,
      scheduleModelVersion: parsedVersion ?? 1,
    );
  }

  Map<String, dynamic> toFirebaseMap() => {
    'notificationEnabled': notificationEnabled,
    'fullscreenEnabled': fullscreenEnabled,
    'followHomeSchedule': followHomeSchedule,
    'scheduleModelVersion': deviceAlarmScheduleModelVersion,
  };
}

DevicePersonalAlarmPreferences resolveDevicePersonalAlarmPreferences({
  required Map<String, dynamic> customRules,
  required String deviceId,
  required bool legacyFullscreenEnabled,
}) {
  final rawDevices = customRules['devices'];
  final devices = rawDevices is Map
      ? Map<String, dynamic>.from(rawDevices)
      : const <String, dynamic>{};
  final rawDevice = devices[deviceId];
  final customDevice = rawDevice is Map
      ? Map<String, dynamic>.from(rawDevice)
      : const <String, dynamic>{};

  return DevicePersonalAlarmPreferences.fromCustomDevice(
    customDevice: customDevice,
    legacyFullscreenEnabled: legacyFullscreenEnabled,
  );
}

bool resolvePersonalFullscreenEnabled({
  required Map<String, dynamic> customRules,
  required String deviceId,
  required bool fallback,
}) {
  return resolveDevicePersonalAlarmPreferences(
    customRules: customRules,
    deviceId: deviceId,
    legacyFullscreenEnabled: fallback,
  ).fullscreenEnabled;
}

Map<String, dynamic> defaultDeviceAlarmSchedule({bool personal = false}) => {
  'enabled': true,
  'start': '23:00',
  'end': '06:00',
  'repeatMinutes': 30,
  'days': const [1, 2, 3, 4, 5, 6, 7],
};

Map<String, dynamic> normalizeDeviceAlarmSchedule(
  Object? rawValue, {
  bool personal = false,
}) {
  final raw = rawValue is Map
      ? Map<String, dynamic>.from(rawValue)
      : const <String, dynamic>{};
  final defaultSchedule = defaultDeviceAlarmSchedule(personal: personal);
  final enabled = rawValue is bool
      ? rawValue
      : rawValue == null
      ? false
      : raw['enabled'] == true;

  return {
    'enabled': enabled,
    'start': _normalizeClock(
      raw['start'] ?? defaultSchedule['start'],
      fallback: '23:00',
    ),
    'end': _normalizeClock(
      raw['end'] ?? defaultSchedule['end'],
      fallback: '06:00',
    ),
    'repeatMinutes': _normalizeRepeatMinutes(
      raw['repeatMinutes'] ?? defaultSchedule['repeatMinutes'],
    ),
    'days': _normalizeDays(raw['days'] ?? defaultSchedule['days']),
  };
}

Map<String, dynamic> deviceAlarmScheduleToFirebaseMap(
  Map<String, dynamic> schedule, {
  required bool personal,
}) {
  final normalized = normalizeDeviceAlarmSchedule(
    schedule,
    personal: personal,
  );

  return {
    'enabled': normalized['enabled'] == true,
    'start': normalized['start'],
    'end': normalized['end'],
    'repeatMinutes': normalized['repeatMinutes'],
    'days': normalized['days'],
  };
}

Map<String, Map<String, dynamic>> normalizeDeviceAlarmSchedules({
  required Object? rawSchedules,
  Object? legacyAlarm,
  required bool personal,
  bool legacyFullscreenEnabled = true,
  bool legacyPhysicalSirenEnabled = true,
  bool includeLegacy = true,
}) {
  final result = <String, Map<String, dynamic>>{};

  if (rawSchedules is Map) {
    for (final entry in rawSchedules.entries) {
      final id = entry.key.toString().trim();
      if (id.isEmpty || entry.value is! Map) continue;
      result[id] = normalizeDeviceAlarmSchedule(
        entry.value,
        personal: personal,
      );
    }
  } else if (rawSchedules is Iterable) {
    var index = 0;
    for (final item in rawSchedules) {
      if (item is! Map) continue;
      result['schedule_$index'] = normalizeDeviceAlarmSchedule(
        item,
        personal: personal,
      );
      index++;
    }
  }

  if (result.isEmpty && includeLegacy && legacyAlarm != null) {
    final migrated = normalizeDeviceAlarmSchedule(
      legacyAlarm,
      personal: personal,
    );
    if (migrated['enabled'] == true || legacyAlarm is Map) {
      result['legacy'] = migrated;
    }
  }

  return result;
}

Map<String, Map<String, dynamic>> normalizeEffectivePersonalAlarmSchedules({
  required Map<String, dynamic> customDevice,
  required String legacyAlarmMode,
  bool legacyFullscreenEnabled = true,
}) {
  final preferences = DevicePersonalAlarmPreferences.fromCustomDevice(
    customDevice: customDevice,
    legacyFullscreenEnabled: legacyFullscreenEnabled,
  );
  final schedules = normalizeDeviceAlarmSchedules(
    rawSchedules: customDevice['alarmSchedules'],
    legacyAlarm: customDevice['alarm'],
    personal: true,
    legacyFullscreenEnabled: preferences.fullscreenEnabled,
  );

  if (!preferences.usesUnifiedSchedules &&
      legacyAlarmMode.trim().toLowerCase() != 'custom') {
    for (final schedule in schedules.values) {
      schedule['enabled'] = false;
    }
  }
  return schedules;
}

Map<String, dynamic> normalizeEffectivePersonalAlarmSchedule({
  required Map<String, dynamic> customDevice,
  required String legacyAlarmMode,
}) {
  final schedules = normalizeEffectivePersonalAlarmSchedules(
    customDevice: customDevice,
    legacyAlarmMode: legacyAlarmMode,
  );
  if (schedules.isEmpty) {
    return normalizeDeviceAlarmSchedule(null, personal: true);
  }
  return schedules.values.firstWhere(
    (schedule) => schedule['enabled'] == true,
    orElse: () => schedules.values.first,
  );
}

bool hasEnabledDeviceAlarmSchedules(
  Map<String, Map<String, dynamic>> schedules,
) => schedules.values.any((schedule) => schedule['enabled'] == true);

Future<void> showDeviceAlarmPolicySheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required String deviceId,
  required String deviceName,
  required String deviceType,
  required Map<String, dynamic> device,
  required bool canEdit,
}) {
  return SafeHomeNavigation.pushChildPage<void>(
    context: context,
    routeName: 'device_alarm_policy',
    builder: (_) => _DeviceAlarmPolicySheet(
      ownerUid: ownerUid,
      homeId: homeId,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      initialDevice: Map<String, dynamic>.from(device),
      canEditCommon: canEdit,
    ),
  );
}

class _DeviceAlarmPolicySheet extends StatefulWidget {
  final String ownerUid;
  final String homeId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final Map<String, dynamic> initialDevice;
  final bool canEditCommon;

  const _DeviceAlarmPolicySheet({
    required this.ownerUid,
    required this.homeId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.initialDevice,
    required this.canEditCommon,
  });

  @override
  State<_DeviceAlarmPolicySheet> createState() =>
      _DeviceAlarmPolicySheetState();
}

class _DeviceAlarmPolicySheetState extends State<_DeviceAlarmPolicySheet> {
  static const List<int> _repeatOptions = [0, 15, 30, 60];

  late bool _enabled;
  late bool _notificationEnabled;
  late bool _physicalSirenEnabled;
  late bool _legacyFullscreenEnabled;
  late bool _personalNotificationEnabled;
  late bool _personalFullscreenEnabled;
  late bool _followHomeSchedule;
  late Map<String, Map<String, dynamic>> _commonSchedules;
  late Map<String, Map<String, dynamic>> _personalSchedules;

  final Set<String> _expandedScheduleKeys = <String>{};
  final Set<String> _deleteVisibleScheduleKeys = <String>{};

  Timer? _autoSaveTimer;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _saveAgain = false;

  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.ownerUid;
  bool get _isEmergency => isEmergencyAlarmPolicyDevice(widget.deviceType);
  bool get _isSecurity => isSecurityAlarmPolicyDevice(widget.deviceType);
  bool get _globalEnabled => _isEmergency || _enabled;

  @override
  void initState() {
    super.initState();
    final initialPolicy = DeviceAlarmPolicySettings.fromDevice(
      device: widget.initialDevice,
      deviceType: widget.deviceType,
    );
    _enabled = initialPolicy.enabled;
    _notificationEnabled = initialPolicy.notificationEnabled;
    _physicalSirenEnabled = initialPolicy.physicalSirenEnabled;
    _legacyFullscreenEnabled = initialPolicy.fullscreenEnabled;
    _personalNotificationEnabled = true;
    _personalFullscreenEnabled = initialPolicy.fullscreenEnabled;
    _followHomeSchedule = true;
    _commonSchedules = normalizeDeviceAlarmSchedules(
      rawSchedules: widget.initialDevice['alarmSchedules'],
      legacyAlarm: widget.initialDevice['alarm'],
      personal: false,
      legacyFullscreenEnabled: initialPolicy.fullscreenEnabled,
      legacyPhysicalSirenEnabled: initialPolicy.physicalSirenEnabled,
    );
    _personalSchedules = <String, Map<String, dynamic>>{};
    _load();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<DataSnapshot>([
        FirebaseDatabase.instance
            .ref(
              'accounts/${widget.ownerUid}/homes/${widget.homeId}/devices/${widget.deviceId}',
            )
            .get(),
        FirebaseDatabase.instance
            .ref('accounts/$_currentUid/customRules/${widget.homeId}')
            .get(),
      ]);
      if (!mounted) return;

      final rawDevice = results[0].value;
      final device = rawDevice is Map
          ? Map<String, dynamic>.from(rawDevice)
          : Map<String, dynamic>.from(widget.initialDevice);
      final policy = DeviceAlarmPolicySettings.fromDevice(
        device: device,
        deviceType: widget.deviceType,
      );
      final rawCustomHome = results[1].value;
      final customHome = rawCustomHome is Map
          ? Map<String, dynamic>.from(rawCustomHome)
          : const <String, dynamic>{};
      final rawCustomDevices = customHome['devices'];
      final customDevices = rawCustomDevices is Map
          ? Map<String, dynamic>.from(rawCustomDevices)
          : const <String, dynamic>{};
      final rawCustomDevice = customDevices[widget.deviceId];
      final customDevice = rawCustomDevice is Map
          ? Map<String, dynamic>.from(rawCustomDevice)
          : const <String, dynamic>{};
      final legacyAlarmMode =
          (customHome['alarmMode'] ?? customHome['mode'] ?? 'home').toString();
      final personalPreferences =
          DevicePersonalAlarmPreferences.fromCustomDevice(
            customDevice: customDevice,
            legacyFullscreenEnabled: policy.fullscreenEnabled,
          );

      setState(() {
        _enabled = policy.enabled;
        _notificationEnabled = policy.notificationEnabled;
        _physicalSirenEnabled = policy.physicalSirenEnabled;
        _legacyFullscreenEnabled = policy.fullscreenEnabled;
        _commonSchedules = normalizeDeviceAlarmSchedules(
          rawSchedules: device['alarmSchedules'],
          legacyAlarm: device['alarm'],
          personal: false,
          legacyFullscreenEnabled: policy.fullscreenEnabled,
          legacyPhysicalSirenEnabled: policy.physicalSirenEnabled,
        );
        _personalSchedules = normalizeEffectivePersonalAlarmSchedules(
          customDevice: customDevice,
          legacyAlarmMode: legacyAlarmMode,
          legacyFullscreenEnabled: policy.fullscreenEnabled,
        );
        _personalNotificationEnabled = personalPreferences.notificationEnabled;
        _personalFullscreenEnabled = personalPreferences.fullscreenEnabled;
        _followHomeSchedule = personalPreferences.followHomeSchedule;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _change(
    VoidCallback action, {
    bool immediate = false,
  }) {
    setState(action);
    _queueAutoSave(immediate: immediate);
  }

  void _queueAutoSave({bool immediate = false}) {
    if (_loading || _currentUid.isEmpty) return;

    _dirty = true;
    _autoSaveTimer?.cancel();

    if (immediate) {
      unawaited(_flushAutoSave());
      return;
    }

    _autoSaveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_flushAutoSave()),
    );
  }

  Future<bool> _flushAutoSave() async {
    if (_currentUid.isEmpty) return false;

    if (_saving) {
      _saveAgain = true;
      return true;
    }

    if (!_dirty) return true;

    _autoSaveTimer?.cancel();
    _dirty = false;
    if (mounted) setState(() => _saving = true);

    try {
      await FirebaseDatabase.instance.ref().update(_buildUpdates());
      return true;
    } catch (_) {
      _dirty = true;
      if (mounted) {
        showTopToast(
          context,
          AppStrings.of(context).t('Không thể lưu cấu hình báo động'),
          color: SafeHomeColors.danger,
          icon: Icons.error_rounded,
        );
      }
      return false;
    } finally {
      // Chỉ lưu lại ngay khi có thay đổi mới phát sinh trong lúc một lần lưu
      // đang chạy. Lỗi mạng giữ trạng thái _dirty để người dùng có thể thử lại,
      // nhưng không tự tạo vòng lặp ghi Firebase vô hạn.
      final runAgain = _saveAgain;
      _saveAgain = false;
      if (mounted) setState(() => _saving = false);
      if (runAgain && mounted) {
        _autoSaveTimer = Timer(
          const Duration(milliseconds: 120),
          () => unawaited(_flushAutoSave()),
        );
      }
    }
  }

  Map<String, Object?> _buildUpdates() {
    final updates = <String, Object?>{};
    final baseDevicePath =
        'accounts/${widget.ownerUid}/homes/${widget.homeId}/devices/${widget.deviceId}';
    final personalPath =
        'accounts/$_currentUid/customRules/${widget.homeId}/devices/${widget.deviceId}';

    if (widget.canEditCommon) {
      updates['$baseDevicePath/alarmPolicy'] = DeviceAlarmPolicySettings(
        enabled: _isEmergency ? true : _enabled,
        notificationEnabled: _notificationEnabled,
        physicalSirenEnabled: _physicalSirenEnabled,
        fullscreenEnabled: _legacyFullscreenEnabled,
      ).toFirebaseMap();

      if (_isSecurity) {
        updates['$baseDevicePath/alarmSchedules'] = _firebaseScheduleMap(
          _commonSchedules,
          personal: false,
        );
        updates['$baseDevicePath/alarm'] = null;
      }
    }

    if (_isSecurity) {
      updates['$personalPath/alarmSchedules'] = _firebaseScheduleMap(
        _personalSchedules,
        personal: true,
      );
      updates['$personalPath/alarm'] = null;
      updates['$personalPath/alarmPreferences'] =
          DevicePersonalAlarmPreferences(
            notificationEnabled: _personalNotificationEnabled,
            fullscreenEnabled: _personalFullscreenEnabled,
            followHomeSchedule: _followHomeSchedule,
          ).toFirebaseMap();
    } else {
      updates['$personalPath/alarmPreferences'] =
          DevicePersonalAlarmPreferences(
            notificationEnabled: _personalNotificationEnabled,
            fullscreenEnabled: _personalFullscreenEnabled,
            followHomeSchedule: _followHomeSchedule,
          ).toFirebaseMap();
    }

    return updates;
  }

  Future<bool> _handleWillPop() async {
    _autoSaveTimer?.cancel();

    while (_saving) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (!_dirty) return true;
    return _flushAutoSave();
  }

  Map<String, Object?>? _firebaseScheduleMap(
    Map<String, Map<String, dynamic>> schedules, {
    required bool personal,
  }) {
    if (schedules.isEmpty) return null;
    return {
      for (final entry in schedules.entries)
        entry.key: deviceAlarmScheduleToFirebaseMap(
          entry.value,
          personal: personal,
        ),
    };
  }

  String _newScheduleId() =>
      'schedule_${DateTime.now().microsecondsSinceEpoch}';

  String _scheduleUiKey(bool personal, String scheduleId) =>
      '${personal ? 'personal' : 'home'}:$scheduleId';

  void _addSchedule({required bool personal}) {
    final scheduleId = _newScheduleId();
    final uiKey = _scheduleUiKey(personal, scheduleId);

    _change(() {
      final schedules = personal ? _personalSchedules : _commonSchedules;
      final schedule = defaultDeviceAlarmSchedule(personal: personal);
      // Lịch mới phải được cấu hình xong rồi người dùng mới chủ động bật.
      schedule['enabled'] = false;
      schedules[scheduleId] = schedule;
      _expandedScheduleKeys.add(uiKey);
      _deleteVisibleScheduleKeys.remove(uiKey);
    }, immediate: true);
  }

  void _deleteSchedule({
    required bool personal,
    required String scheduleId,
  }) {
    final uiKey = _scheduleUiKey(personal, scheduleId);
    _change(() {
      final schedules = personal ? _personalSchedules : _commonSchedules;
      schedules.remove(scheduleId);
      _expandedScheduleKeys.remove(uiKey);
      _deleteVisibleScheduleKeys.remove(uiKey);
    }, immediate: true);
  }

  Future<void> _pickTime({
    required Map<String, dynamic> schedule,
    required String field,
  }) async {
    final raw = schedule[field]?.toString() ??
        (field == 'start' ? '23:00' : '06:00');
    final parts = raw.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? (field == 'start' ? 23 : 6),
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (selected == null || !mounted) return;

    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    final otherField = field == 'start' ? 'end' : 'start';

    if (value == schedule[otherField]?.toString()) {
      showTopToast(
        context,
        AppStrings.of(context).t(
          'Giờ bắt đầu và kết thúc không được trùng nhau',
        ),
        color: SafeHomeColors.warning,
        icon: Icons.schedule_rounded,
      );
      return;
    }

    _change(() => schedule[field] = value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.94,
        ),
        decoration: const BoxDecoration(
          color: SafeHomeColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 20 + bottomInset),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 56),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(strings),
                      const SizedBox(height: 18),
                      _participationCard(strings),
                      const SizedBox(height: 14),
                      _alarmChannelsCard(strings),
                      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                        const SizedBox(height: 10),
                        const IosAlarmPlatformNotice(),
                      ],
                      if (_isSecurity) ...[
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _globalEnabled ? 1 : 0.48,
                          child: IgnorePointer(
                            ignoring: !_globalEnabled,
                            child: Column(
                              children: [
                                _scheduleCollection(
                                  strings: strings,
                                  title: strings.t('Lịch chung cho nhà'),
                                  schedules: _commonSchedules,
                                  enabled: widget.canEditCommon,
                                  personal: false,
                                ),
                                const SizedBox(height: 14),
                                _scheduleCollection(
                                  strings: strings,
                                  title: strings.t('Lịch cho cá nhân tôi'),
                                  schedules: _personalSchedules,
                                  enabled: true,
                                  personal: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (!widget.canEditCommon) ...[
                        const SizedBox(height: 12),
                        _noticeCard(
                          icon: Icons.lock_outline_rounded,
                          text: strings.t(
                            'Chỉ chủ nhà và quản trị viên có thể thay đổi phần chung cho nhà.',
                          ),
                          color: SafeHomeColors.warning,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppStrings strings) => Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: SafeHomeColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.notifications_active_rounded,
          color: SafeHomeColors.danger,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.t('Báo động thiết bị'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: SafeHomeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.deviceName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SafeHomeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        child: _saving
            ? const SizedBox(
                key: ValueKey('saving'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.cloud_done_outlined,
                key: ValueKey('saved'),
                size: 20,
                color: SafeHomeColors.safe,
              ),
      ),
    ],
  );

  Widget _participationCard(AppStrings strings) => _switchCard(
    icon: _globalEnabled ? Icons.shield_rounded : Icons.shield_outlined,
    title: strings.t('Tham gia hệ thống báo động'),
    subtitle: strings.t(
      _isEmergency
          ? 'Cảm biến khẩn cấp luôn tham gia hệ thống báo động.'
          : 'Tắt để thiết bị không tạo bất kỳ báo động nào.',
    ),
    value: _globalEnabled,
    enabled: widget.canEditCommon && !_isEmergency,
    onChanged: (value) => _change(
      () => _enabled = value,
      immediate: true,
    ),
  );

  Widget _alarmChannelsCard(AppStrings strings) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    Widget sectionLabel({
      required IconData icon,
      required String title,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 3),
        child: Row(
          children: [
            Icon(icon, size: 17, color: SafeHomeColors.textSecondary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SafeHomeColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget channelSwitch({
      required IconData icon,
      required String title,
      String? subtitle,
      required bool value,
      required bool enabled,
      required ValueChanged<bool> onChanged,
    }) {
      return SwitchListTile.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        secondary: Icon(
          icon,
          color: value
              ? SafeHomeColors.primary
              : SafeHomeColors.textSecondary,
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: SafeHomeColors.textPrimary,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: SafeHomeColors.textSecondary,
                  ),
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
            child: Text(
              strings.t('Cài đặt báo động'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: SafeHomeColors.textPrimary,
              ),
            ),
          ),
          sectionLabel(
            icon: Icons.home_rounded,
            title: strings.t('Báo động chung'),
          ),
          channelSwitch(
            icon: Icons.notifications_active_outlined,
            title: strings.t('Thông báo báo động'),
            value: _notificationEnabled,
            enabled: widget.canEditCommon,
            onChanged: (value) => _change(
              () => _notificationEnabled = value,
              immediate: true,
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          channelSwitch(
            icon: Icons.campaign_rounded,
            title: strings.t('Bật còi vật lý'),
            subtitle: strings.physicalSirenSharedAlarmOnlyNote,
            value: _physicalSirenEnabled,
            enabled: widget.canEditCommon,
            onChanged: (value) => _change(
              () => _physicalSirenEnabled = value,
              immediate: true,
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          sectionLabel(
            icon: Icons.person_rounded,
            title: strings.t('Báo động cá nhân'),
          ),
          if (_isSecurity) ...[
            channelSwitch(
              icon: Icons.home_work_outlined,
              title: strings.joinHomeSharedAlarm,
              value: _followHomeSchedule,
              enabled: true,
              onChanged: (value) => _change(
                () => _followHomeSchedule = value,
                immediate: true,
              ),
            ),
            const Divider(height: 1, indent: 12, endIndent: 12),
          ],
          channelSwitch(
            icon: Icons.notifications_active_outlined,
            title: strings.t('Thông báo báo động'),
            value: _personalNotificationEnabled,
            enabled: true,
            onChanged: (value) => _change(
              () => _personalNotificationEnabled = value,
              immediate: true,
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          channelSwitch(
            icon: isIos
                ? Icons.phone_iphone_rounded
                : Icons.phone_android_rounded,
            title: isIos
                ? strings.t('Cảnh báo trên iOS')
                : strings.t('Đánh thức màn hình'),
            subtitle: strings.fullscreenPersonalAlarmOnlyNote,
            value: _personalFullscreenEnabled,
            enabled: true,
            onChanged: (value) => _change(
              () => _personalFullscreenEnabled = value,
              immediate: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCollection({
    required AppStrings strings,
    required String title,
    required Map<String, Map<String, dynamic>> schedules,
    required bool enabled,
    required bool personal,
  }) {
    final entries = schedules.entries.toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                personal ? Icons.person_rounded : Icons.home_rounded,
                size: 21,
                color: personal ? SafeHomeColors.info : SafeHomeColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SafeHomeColors.textPrimary,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: strings.t('Thêm'),
                onPressed: enabled
                    ? () => _addSchedule(personal: personal)
                    : null,
                icon: const Icon(Icons.add_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Text(
                strings.t('Thêm'),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: SafeHomeColors.textSecondary,
                ),
              ),
            )
          else
            ...entries.indexed.map((indexed) {
              final index = indexed.$1;
              final entry = indexed.$2;
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 5 : 9),
                child: _scheduleCard(
                  strings: strings,
                  scheduleId: entry.key,
                  schedule: entry.value,
                  enabled: enabled,
                  personal: personal,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _scheduleCard({
    required AppStrings strings,
    required String scheduleId,
    required Map<String, dynamic> schedule,
    required bool enabled,
    required bool personal,
  }) {
    final uiKey = _scheduleUiKey(personal, scheduleId);
    final expanded = _expandedScheduleKeys.contains(uiKey);
    final showDelete = _deleteVisibleScheduleKeys.contains(uiKey);
    final scheduleEnabled = schedule['enabled'] == true;

    return GestureDetector(
      onLongPress: enabled
          ? () => setState(() {
              if (showDelete) {
                _deleteVisibleScheduleKeys.remove(uiKey);
              } else {
                _deleteVisibleScheduleKeys.add(uiKey);
              }
            })
          : null,
      child: Container(
        key: ValueKey(uiKey),
        decoration: BoxDecoration(
          color: SafeHomeColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: showDelete
                ? SafeHomeColors.danger.withValues(alpha: 0.55)
                : SafeHomeColors.border,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() {
                if (expanded) {
                  _expandedScheduleKeys.remove(uiKey);
                } else {
                  _expandedScheduleKeys.add(uiKey);
                }
              }),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              schedule['start']?.toString() ?? '23:00',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: SafeHomeColors.textPrimary,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 7),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                              color: SafeHomeColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              schedule['end']?.toString() ?? '06:00',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: SafeHomeColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      child: showDelete
                          ? IconButton(
                              key: const ValueKey('delete'),
                              tooltip: strings.t('Xoá'),
                              onPressed: () => _deleteSchedule(
                                personal: personal,
                                scheduleId: scheduleId,
                              ),
                              icon: const Icon(Icons.delete_rounded),
                              color: SafeHomeColors.danger,
                              visualDensity: VisualDensity.compact,
                            )
                          : const SizedBox.shrink(key: ValueKey('no_delete')),
                    ),
                    Switch.adaptive(
                      value: scheduleEnabled,
                      onChanged: enabled
                          ? (value) {
                              if (value &&
                                  schedule['start']?.toString() ==
                                      schedule['end']?.toString()) {
                                showTopToast(
                                  context,
                                  strings.t(
                                    'Giờ bắt đầu và kết thúc không được trùng nhau',
                                  ),
                                  color: SafeHomeColors.warning,
                                  icon: Icons.schedule_rounded,
                                );
                                return;
                              }
                              _change(
                                () => schedule['enabled'] = value,
                                immediate: true,
                              );
                            }
                          : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: SafeHomeColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: IgnorePointer(
                ignoring: !enabled,
                child: Opacity(
                  opacity: enabled ? 1 : 0.55,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 8),
                        Text(
                          strings.t('Ngày trong tuần'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: SafeHomeColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _daySelector(strings, schedule),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _timeButton(
                                label: strings.t('Giờ bắt đầu'),
                                value:
                                    schedule['start']?.toString() ?? '23:00',
                                onTap: () => _pickTime(
                                  schedule: schedule,
                                  field: 'start',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _timeButton(
                                label: strings.t('Giờ kết thúc'),
                                value: schedule['end']?.toString() ?? '06:00',
                                onTap: () => _pickTime(
                                  schedule: schedule,
                                  field: 'end',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                strings.t('Lặp lại cảnh báo'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: SafeHomeColors.textPrimary,
                                ),
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _normalizeRepeatMinutes(
                                  schedule['repeatMinutes'],
                                ),
                                isDense: true,
                                items: _repeatOptions
                                    .map(
                                      (minutes) => DropdownMenuItem<int>(
                                        value: minutes,
                                        child: Text(
                                          minutes == 0
                                              ? strings.t('Không lặp lại')
                                              : strings.minuteText(minutes),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) {
                                  if (value == null) return;
                                  _change(
                                    () => schedule['repeatMinutes'] = value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _daySelector(AppStrings strings, Map<String, dynamic> schedule) {
    final selected = _normalizeDays(schedule['days']);

    Widget chip(int day) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () {
            final next = List<int>.from(selected);
            if (next.contains(day)) {
              if (next.length == 1) return;
              next.remove(day);
            } else {
              next.add(day);
            }
            next.sort();
            _change(() => schedule['days'] = next);
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected.contains(day)
                  ? SafeHomeColors.primary
                  : SafeHomeColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected.contains(day)
                    ? SafeHomeColors.primary
                    : SafeHomeColors.border,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _shortDay(day, strings),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected.contains(day)
                      ? Colors.white
                      : SafeHomeColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        Row(children: [chip(1), chip(2), chip(3), chip(4)]),
        const SizedBox(height: 6),
        Row(children: [chip(5), chip(6), chip(7)]),
      ],
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: SafeHomeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: SafeHomeColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _switchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: SafeHomeColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SafeHomeColors.border),
    ),
    child: SwitchListTile.adaptive(
      value: value,
      onChanged: enabled ? onChanged : null,
      secondary: Icon(
        icon,
        color: enabled
            ? SafeHomeColors.primary
            : SafeHomeColors.textSecondary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: SafeHomeColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12.5,
          color: SafeHomeColors.textSecondary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    ),
  );
}

Widget _noticeCard({
  required IconData icon,
  required String text,
  required Color color,
}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(13),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.09),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: color.withValues(alpha: 0.22)),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            height: 1.35,
            color: SafeHomeColors.textPrimary,
          ),
        ),
      ),
    ],
  ),
);


int _normalizeRepeatMinutes(Object? raw) {
  final parsed = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  return const [0, 15, 30, 60].contains(parsed) ? parsed! : 30;
}

String _normalizeClock(Object? raw, {required String fallback}) {
  final value = raw?.toString().trim() ?? '';
  return RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value)
      ? value
      : fallback;
}

List<int> _normalizeDays(Object? raw) {
  final days = <int>[];
  if (raw is Iterable) {
    for (final item in raw) {
      final value = item is num ? item.toInt() : int.tryParse(item.toString());
      if (value != null && value >= 1 && value <= 7 && !days.contains(value)) {
        days.add(value);
      }
    }
  } else if (raw is Map) {
    for (final item in raw.values) {
      final value = item is num ? item.toInt() : int.tryParse(item.toString());
      if (value != null && value >= 1 && value <= 7 && !days.contains(value)) {
        days.add(value);
      }
    }
  }
  days.sort();
  return days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : days;
}

String _shortDay(int day, AppStrings strings) {
  const vi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const zh = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  const ko = ['월', '화', '수', '목', '금', '토', '일'];
  const ja = ['月', '火', '水', '木', '金', '土', '日'];
  const de = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  const fr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  const es = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const id = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  const th = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  const ms = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];
  final i = (day - 1).clamp(0, 6).toInt();
  return strings.choose(
    vi: vi[i],
    en: en[i],
    zh: zh[i],
    ko: ko[i],
    ja: ja[i],
    de: de[i],
    ru: ru[i],
    fr: fr[i],
    es: es[i],
    id: id[i],
    th: th[i],
    ms: ms[i],
  );
}
