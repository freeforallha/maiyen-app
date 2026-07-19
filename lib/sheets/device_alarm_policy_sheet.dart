import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';
import '../navigation/safehome_navigation.dart';

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

const int deviceAlarmScheduleModelVersion = 2;

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
  final bool physicalSirenEnabled;

  /// Trường legacy dùng làm mặc định cho tài khoản chưa lưu tùy chọn cá nhân.
  final bool fullscreenEnabled;
  final int triggerDelaySeconds;

  const DeviceAlarmPolicySettings({
    required this.enabled,
    required this.physicalSirenEnabled,
    required this.fullscreenEnabled,
    required this.triggerDelaySeconds,
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
    final parsedDelay = _toBoundedDelay(policy['triggerDelaySeconds']);

    return DeviceAlarmPolicySettings(
      enabled: isEmergency ? true : policy['enabled'] != false,
      physicalSirenEnabled: policy['physicalSirenEnabled'] != false,
      fullscreenEnabled: policy['fullscreenEnabled'] != false,
      triggerDelaySeconds: isEmergency ? 0 : parsedDelay,
    );
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'enabled': enabled,
      'physicalSirenEnabled': physicalSirenEnabled,
      'fullscreenEnabled': fullscreenEnabled,
      'triggerDelaySeconds': triggerDelaySeconds,
    };
  }
}

class DevicePersonalAlarmPreferences {
  final bool fullscreenEnabled;
  final bool followHomeSchedule;
  final int scheduleModelVersion;

  const DevicePersonalAlarmPreferences({
    required this.fullscreenEnabled,
    this.followHomeSchedule = true,
    this.scheduleModelVersion = deviceAlarmScheduleModelVersion,
  });

  bool get usesUnifiedSchedules =>
      scheduleModelVersion >= deviceAlarmScheduleModelVersion;

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
      fullscreenEnabled: preferences['fullscreenEnabled'] is bool
          ? preferences['fullscreenEnabled'] == true
          : legacyFullscreenEnabled,
      followHomeSchedule: preferences['followHomeSchedule'] is bool
          ? preferences['followHomeSchedule'] == true
          : true,
      scheduleModelVersion: parsedVersion ?? 1,
    );
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'fullscreenEnabled': fullscreenEnabled,
      'followHomeSchedule': followHomeSchedule,
      'scheduleModelVersion': deviceAlarmScheduleModelVersion,
    };
  }
}

bool resolvePersonalFullscreenEnabled({
  required Map<String, dynamic> customRules,
  required String deviceId,
  required bool fallback,
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
    legacyFullscreenEnabled: fallback,
  ).fullscreenEnabled;
}

Map<String, dynamic> normalizeEffectivePersonalAlarmSchedule({
  required Map<String, dynamic> customDevice,
  required String legacyAlarmMode,
}) {
  final alarm = normalizeDeviceAlarmSchedule(customDevice['alarm']);
  final preferences = DevicePersonalAlarmPreferences.fromCustomDevice(
    customDevice: customDevice,
    legacyFullscreenEnabled: true,
  );

  // Ở dữ liệu cũ, lịch cá nhân chỉ có hiệu lực khi người dùng chọn
  // chế độ Riêng tôi. Không tự bật lại một lịch từng bị ẩn khi nâng cấp.
  if (!preferences.usesUnifiedSchedules &&
      legacyAlarmMode.trim().toLowerCase() != 'custom') {
    alarm['enabled'] = false;
  }

  return alarm;
}

Map<String, dynamic> defaultDeviceAlarmSchedule() {
  return {
    'enabled': false,
    'start': '23:00',
    'end': '06:00',
    'repeatMinutes': 30,
    'days': const [1, 2, 3, 4, 5, 6, 7],
  };
}

Map<String, dynamic> normalizeDeviceAlarmSchedule(Object? rawValue) {
  final alarm = Map<String, dynamic>.from(defaultDeviceAlarmSchedule());

  if (rawValue is Map) {
    alarm.addAll(Map<String, dynamic>.from(rawValue));
  } else if (rawValue is bool) {
    alarm['enabled'] = rawValue;
  }

  alarm['enabled'] = alarm['enabled'] == true;
  alarm['start'] = _normalizeClock(alarm['start'], fallback: '23:00');
  alarm['end'] = _normalizeClock(alarm['end'], fallback: '06:00');
  alarm['repeatMinutes'] = _normalizeRepeatMinutes(alarm['repeatMinutes']);
  alarm['days'] = _normalizeDays(alarm['days']);

  return alarm;
}

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
    routeName: "device_alarm_policy",
    builder: (_) {
      return _DeviceAlarmPolicySheet(
        ownerUid: ownerUid,
        homeId: homeId,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        initialDevice: Map<String, dynamic>.from(device),
        canEditCommon: canEdit,
      );
    },
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
  static const List<int> _delayOptions = [0, 5, 10, 15, 30, 60, 90, 120];
  static const List<int> _repeatOptions = [0, 15, 30, 60];

  late bool _enabled;
  late bool _physicalSirenEnabled;
  late bool _legacyFullscreenEnabled;
  late bool _personalFullscreenEnabled;
  late bool _followHomeSchedule;
  late int _triggerDelaySeconds;
  late Map<String, dynamic> _commonAlarm;
  late Map<String, dynamic> _personalAlarm;

  bool _loading = true;
  bool _saving = false;

  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.ownerUid;
  bool get _isEmergency => isEmergencyAlarmPolicyDevice(widget.deviceType);
  bool get _isSecurity => isSecurityAlarmPolicyDevice(widget.deviceType);
  bool get _globalEnabled => _isEmergency || _enabled;
  bool get _isHomeOwner => _currentUid == widget.ownerUid;

  @override
  void initState() {
    super.initState();
    final initialPolicy = DeviceAlarmPolicySettings.fromDevice(
      device: widget.initialDevice,
      deviceType: widget.deviceType,
    );
    _enabled = initialPolicy.enabled;
    _physicalSirenEnabled = initialPolicy.physicalSirenEnabled;
    _legacyFullscreenEnabled = initialPolicy.fullscreenEnabled;
    _personalFullscreenEnabled = initialPolicy.fullscreenEnabled;
    _followHomeSchedule = true;
    _triggerDelaySeconds = initialPolicy.triggerDelaySeconds;
    _commonAlarm = normalizeDeviceAlarmSchedule(widget.initialDevice['alarm']);
    _personalAlarm = normalizeDeviceAlarmSchedule(null);
    _load();
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
        _physicalSirenEnabled = policy.physicalSirenEnabled;
        _legacyFullscreenEnabled = policy.fullscreenEnabled;
        _triggerDelaySeconds = policy.triggerDelaySeconds;
        _commonAlarm = normalizeDeviceAlarmSchedule(device['alarm']);
        _personalAlarm = normalizeEffectivePersonalAlarmSchedule(
          customDevice: customDevice,
          legacyAlarmMode: legacyAlarmMode,
        );
        _personalFullscreenEnabled = personalPreferences.fullscreenEnabled;
        _followHomeSchedule = _isHomeOwner
            ? true
            : personalPreferences.followHomeSchedule;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _currentUid.isEmpty) return;

    setState(() => _saving = true);
    final strings = AppStrings.of(context);

    try {
      final updates = <String, Object?>{};
      final baseDevicePath =
          'accounts/${widget.ownerUid}/homes/${widget.homeId}/devices/${widget.deviceId}';
      final personalPath =
          'accounts/$_currentUid/customRules/${widget.homeId}/devices/${widget.deviceId}';

      if (widget.canEditCommon) {
        updates['$baseDevicePath/alarmPolicy'] = DeviceAlarmPolicySettings(
          enabled: _isEmergency ? true : _enabled,
          physicalSirenEnabled: _physicalSirenEnabled,
          // Giữ trường cũ làm mặc định cho tài khoản chưa mở bản app mới.
          fullscreenEnabled: _legacyFullscreenEnabled,
          triggerDelaySeconds: _isEmergency ? 0 : _triggerDelaySeconds,
        ).toFirebaseMap();

        if (_isSecurity) {
          updates['$baseDevicePath/alarm'] = normalizeDeviceAlarmSchedule(
            _commonAlarm,
          );
        }
      }

      if (_isSecurity) {
        updates['$personalPath/alarm'] = normalizeDeviceAlarmSchedule(
          _personalAlarm,
        );
      }

      updates['$personalPath/alarmPreferences'] =
          DevicePersonalAlarmPreferences(
            fullscreenEnabled: _personalFullscreenEnabled,
            followHomeSchedule: _isHomeOwner ? true : _followHomeSchedule,
          ).toFirebaseMap();

      await FirebaseDatabase.instance.ref().update(updates);

      if (!mounted) return;
      showTopToast(
        context,
        strings.t('Đã lưu cấu hình báo động'),
        color: SafeHomeColors.safe,
        icon: Icons.check_circle_rounded,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showTopToast(
        context,
        strings.t('Không thể lưu cấu hình báo động'),
        color: SafeHomeColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _pickTime({
    required Map<String, dynamic> alarm,
    required String field,
    required bool personal,
  }) async {
    final raw =
        alarm[field]?.toString() ??
        (field == 'start' ? '23:00' : '06:00').toString();
    final parts = raw.split(':');
    final initial = TimeOfDay(
      hour:
          int.tryParse(parts.firstOrNull ?? '') ?? (field == 'start' ? 23 : 6),
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );

    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null || !mounted) return;

    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() {
      final target = personal ? _personalAlarm : _commonAlarm;
      target[field] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: SafeHomeColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
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
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: _globalEnabled ? 1 : 0.48,
                            child: IgnorePointer(
                              ignoring: !_globalEnabled,
                              child: _scopeFrame(
                                icon: Icons.home_rounded,
                                title: strings.t('Chung cho nhà'),
                                subtitle: strings.t(
                                  'Áp dụng cho toàn bộ thành viên và có thể bật còi vật lý.',
                                ),
                                accentColor: SafeHomeColors.primary,
                                child: _commonSection(strings),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: _globalEnabled ? 1 : 0.48,
                            child: IgnorePointer(
                              ignoring: !_globalEnabled,
                              child: _scopeFrame(
                                icon: Icons.person_rounded,
                                title: strings.t('Cá nhân'),
                                subtitle: _isSecurity
                                    ? strings.t(
                                        'Lịch cá nhân hoạt động độc lập và không bật còi vật lý.',
                                      )
                                    : strings.t(
                                        'Cài đặt này chỉ áp dụng cho tài khoản của bạn.',
                                      ),
                                accentColor: SafeHomeColors.info,
                                child: _personalSection(strings),
                              ),
                            ),
                          ),
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
                          if (_isEmergency) ...[
                            const SizedBox(height: 12),
                            _noticeCard(
                              icon: Icons.bolt_rounded,
                              text: strings.t(
                                'Cảm biến khẩn cấp luôn kích hoạt ngay lập tức.',
                              ),
                              color: SafeHomeColors.danger,
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: Text(strings.t('Lưu')),
                              style: FilledButton.styleFrom(
                                backgroundColor: SafeHomeColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppStrings strings) {
    return Row(
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
      ],
    );
  }

  Widget _participationCard(AppStrings strings) {
    return _switchCard(
      icon: _globalEnabled ? Icons.shield_rounded : Icons.shield_outlined,
      title: strings.t('Tham gia hệ thống báo động'),
      subtitle: strings.t(
        _isEmergency
            ? 'Cảm biến khẩn cấp luôn tham gia hệ thống báo động.'
            : 'Tắt để thiết bị không tạo bất kỳ báo động nào.',
      ),
      value: _globalEnabled,
      enabled: widget.canEditCommon && !_isEmergency,
      onChanged: (value) => setState(() => _enabled = value),
    );
  }

  Widget _commonSection(AppStrings strings) {
    return Column(
      children: [
        if (_isSecurity) ...[
          _scheduleCard(
            strings: strings,
            title: strings.t('Lịch báo động chung'),
            alarm: _commonAlarm,
            enabled: widget.canEditCommon,
            personal: false,
          ),
          const SizedBox(height: 10),
        ],
        _switchCard(
          icon: Icons.campaign_rounded,
          title: strings.t('Bật còi vật lý'),
          subtitle: strings.t('Cho phép kích hoạt còi trong nhà.'),
          value: _physicalSirenEnabled,
          enabled: widget.canEditCommon,
          onChanged: (value) => setState(() => _physicalSirenEnabled = value),
        ),
        if (_isSecurity) ...[const SizedBox(height: 10), _delayCard(strings)],
      ],
    );
  }

  Widget _personalSection(AppStrings strings) {
    return Column(
      children: [
        if (_isSecurity && !_isHomeOwner) ...[
          _switchCard(
            icon: Icons.home_work_rounded,
            title: strings.t('Nhận cảnh báo theo lịch chung của nhà'),
            subtitle: strings.t(
              'Tắt để không nhận thông báo hoặc cảnh báo toàn màn hình từ lịch chung. Còi vật lý của nhà vẫn hoạt động.',
            ),
            value: _followHomeSchedule,
            enabled: true,
            onChanged: (value) => setState(() => _followHomeSchedule = value),
          ),
          const SizedBox(height: 10),
        ],
        if (_isSecurity) ...[
          _scheduleCard(
            strings: strings,
            title: strings.t('Lịch báo động cá nhân'),
            alarm: _personalAlarm,
            enabled: true,
            personal: true,
          ),
          const SizedBox(height: 10),
        ],
        _switchCard(
          icon: Icons.phone_android_rounded,
          title: strings.t('Đánh thức màn hình'),
          subtitle: strings.t(
            'Hiển thị cảnh báo toàn màn hình trên điện thoại của bạn.',
          ),
          value: _personalFullscreenEnabled,
          enabled: true,
          onChanged: (value) =>
              setState(() => _personalFullscreenEnabled = value),
        ),
      ],
    );
  }

  Widget _scopeFrame({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: icon,
            title: title,
            subtitle: subtitle,
            color: accentColor,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = SafeHomeColors.primary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SafeHomeColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: SafeHomeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scheduleCard({
    required AppStrings strings,
    required String title,
    required Map<String, dynamic> alarm,
    required bool enabled,
    required bool personal,
  }) {
    final scheduleEnabled = alarm['enabled'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 12),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: SafeHomeColors.primary,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SafeHomeColors.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: scheduleEnabled,
                onChanged: enabled
                    ? (value) => setState(() => alarm['enabled'] = value)
                    : null,
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: scheduleEnabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.55,
                child: Column(
                  children: [
                    const Divider(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _timeButton(
                            label: strings.t('Bắt đầu'),
                            value: alarm['start']?.toString() ?? '23:00',
                            onTap: () => _pickTime(
                              alarm: alarm,
                              field: 'start',
                              personal: personal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _timeButton(
                            label: strings.t('Kết thúc'),
                            value: alarm['end']?.toString() ?? '06:00',
                            onTap: () => _pickTime(
                              alarm: alarm,
                              field: 'end',
                              personal: personal,
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
                              alarm['repeatMinutes'],
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
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => alarm['repeatMinutes'] = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.t('Ngày trong tuần'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: SafeHomeColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _daySelector(strings, alarm),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _daySelector(AppStrings strings, Map<String, dynamic> alarm) {
    final selected = _normalizeDays(alarm['days']);

    Widget chip(int day) {
      final active = selected.contains(day);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            onTap: () {
              final next = List<int>.from(selected);
              if (active) {
                if (next.length == 1) return;
                next.remove(day);
              } else {
                next.add(day);
              }
              next.sort();
              setState(() => alarm['days'] = next);
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? SafeHomeColors.primary
                    : SafeHomeColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active
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
                    color: active ? Colors.white : SafeHomeColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SafeHomeColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SafeHomeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
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
  }

  Widget _switchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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

  Widget _delayCard(AppStrings strings) {
    final options = <int>{..._delayOptions, _triggerDelaySeconds}.toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            color: SafeHomeColors.warning,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              strings.t('Độ trễ kích hoạt'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: SafeHomeColors.textPrimary,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _triggerDelaySeconds,
              isDense: true,
              items: options
                  .map(
                    (seconds) => DropdownMenuItem<int>(
                      value: seconds,
                      child: Text(
                        seconds == 0
                            ? strings.t('Ngay lập tức')
                            : '$seconds ${strings.t('giây')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: widget.canEditCommon
                  ? (value) {
                      if (value != null) {
                        setState(() => _triggerDelaySeconds = value);
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _noticeCard({
  required IconData icon,
  required String text,
  required Color color,
}) {
  return Container(
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
}

int _toBoundedDelay(Object? raw) {
  final parsed = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  return (parsed ?? 0).clamp(0, 120).toInt();
}

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
  }
  days.sort();
  return days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : days;
}

String _shortDay(int day, AppStrings strings) {
  switch (day) {
    case 1:
      return strings.choose(
        vi: 'T2',
        en: 'Mon',
        zh: '周一',
        ko: '월',
        ja: '月',
        de: 'Mo',
        ru: 'Пн',
        fr: 'Lun',
        es: 'Lun',
        id: 'Sen',
        th: 'จ.',
        ms: 'Isn',
        fil: 'Lun',
        km: 'ច.',
        my: 'တနင်္လာ',
        lo: 'ຈ.',
        ta: 'திங்.',
        pt: 'seg.',
        tet: 'Seg.',
      );
    case 2:
      return strings.choose(
        vi: 'T3',
        en: 'Tue',
        zh: '周二',
        ko: '화',
        ja: '火',
        de: 'Di',
        ru: 'Вт',
        fr: 'Mar',
        es: 'Mar',
        id: 'Sel',
        th: 'อ.',
        ms: 'Sel',
        fil: 'Mar',
        km: 'អ.',
        my: 'အင်္ဂါ',
        lo: 'ອ.',
        ta: 'செவ்.',
        pt: 'ter.',
        tet: 'Ter.',
      );
    case 3:
      return strings.choose(
        vi: 'T4',
        en: 'Wed',
        zh: '周三',
        ko: '수',
        ja: '水',
        de: 'Mi',
        ru: 'Ср',
        fr: 'Mer',
        es: 'Mié',
        id: 'Rab',
        th: 'พ.',
        ms: 'Rab',
        fil: 'Miy',
        km: 'ព.',
        my: 'ဗုဒ္ဓဟူး',
        lo: 'ພ.',
        ta: 'புத.',
        pt: 'qua.',
        tet: 'Kua.',
      );
    case 4:
      return strings.choose(
        vi: 'T5',
        en: 'Thu',
        zh: '周四',
        ko: '목',
        ja: '木',
        de: 'Do',
        ru: 'Чт',
        fr: 'Jeu',
        es: 'Jue',
        id: 'Kam',
        th: 'พฤ.',
        ms: 'Kha',
        fil: 'Huw',
        km: 'ព្រ.',
        my: 'ကြာသပတေး',
        lo: 'ພຫ.',
        ta: 'வியா.',
        pt: 'qui.',
        tet: 'Kin.',
      );
    case 5:
      return strings.choose(
        vi: 'T6',
        en: 'Fri',
        zh: '周五',
        ko: '금',
        ja: '金',
        de: 'Fr',
        ru: 'Пт',
        fr: 'Ven',
        es: 'Vie',
        id: 'Jum',
        th: 'ศ.',
        ms: 'Jum',
        fil: 'Biy',
        km: 'សុ.',
        my: 'သောကြာ',
        lo: 'ສຸ.',
        ta: 'வெள்.',
        pt: 'sex.',
        tet: 'Ses.',
      );
    case 6:
      return strings.choose(
        vi: 'T7',
        en: 'Sat',
        zh: '周六',
        ko: '토',
        ja: '土',
        de: 'Sa',
        ru: 'Сб',
        fr: 'Sam',
        es: 'Sáb',
        id: 'Sab',
        th: 'ส.',
        ms: 'Sab',
        fil: 'Sab',
        km: 'សៅ.',
        my: 'စနေ',
        lo: 'ສ.',
        ta: 'சனி.',
        pt: 'sáb.',
        tet: 'Sáb.',
      );
    default:
      return strings.choose(
        vi: 'CN',
        en: 'Sun',
        zh: '周日',
        ko: '일',
        ja: '日',
        de: 'So',
        ru: 'Вс',
        fr: 'Dim',
        es: 'Dom',
        id: 'Min',
        th: 'อา.',
        ms: 'Ahd',
        fil: 'Lin',
        km: 'អា.',
        my: 'တနင်္ဂနွေ',
        lo: 'ອາ.',
        ta: 'ஞாயி.',
        pt: 'dom.',
        tet: 'Dom.',
      );
  }
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
