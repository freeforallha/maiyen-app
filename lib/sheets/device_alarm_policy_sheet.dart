import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/top_toast.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';

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

bool supportsDeviceAlarmPolicy(String deviceType) {
  final normalized = deviceType.trim().toLowerCase();
  return _emergencyAlarmDeviceTypes.contains(normalized) ||
      _securityAlarmDeviceTypes.contains(normalized);
}

bool isEmergencyAlarmPolicyDevice(String deviceType) {
  return _emergencyAlarmDeviceTypes.contains(deviceType.trim().toLowerCase());
}

class DeviceAlarmPolicySettings {
  final bool enabled;
  final bool physicalSirenEnabled;
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
      // Cảm biến khẩn cấp luôn tham gia Alarm.
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
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _DeviceAlarmPolicySheet(
        ownerUid: ownerUid,
        homeId: homeId,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        initialSettings: DeviceAlarmPolicySettings.fromDevice(
          device: device,
          deviceType: deviceType,
        ),
        canEdit: canEdit,
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
  final DeviceAlarmPolicySettings initialSettings;
  final bool canEdit;

  const _DeviceAlarmPolicySheet({
    required this.ownerUid,
    required this.homeId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.initialSettings,
    required this.canEdit,
  });

  @override
  State<_DeviceAlarmPolicySheet> createState() =>
      _DeviceAlarmPolicySheetState();
}

class _DeviceAlarmPolicySheetState
    extends State<_DeviceAlarmPolicySheet> {
  static const List<int> _standardDelayOptions = [0, 5, 10, 15, 30, 60, 90, 120];

  late bool _enabled;
  late bool _physicalSirenEnabled;
  late bool _fullscreenEnabled;
  late int _triggerDelaySeconds;
  bool _saving = false;

  bool get _isEmergency =>
      isEmergencyAlarmPolicyDevice(widget.deviceType);

  @override
  void initState() {
    super.initState();
    _enabled = _isEmergency ? true : widget.initialSettings.enabled;
    _physicalSirenEnabled = widget.initialSettings.physicalSirenEnabled;
    _fullscreenEnabled = widget.initialSettings.fullscreenEnabled;
    _triggerDelaySeconds = _isEmergency
        ? 0
        : widget.initialSettings.triggerDelaySeconds;
  }

  List<int> get _delayOptions {
    final options = <int>{
      ..._standardDelayOptions,
      _triggerDelaySeconds,
    }.where((value) => value >= 0 && value <= 120).toList()
      ..sort();

    return options;
  }

  Future<void> _save() async {
    if (!widget.canEdit || _saving) {
      return;
    }

    setState(() => _saving = true);

    final strings = AppStrings.of(context);
    final settings = DeviceAlarmPolicySettings(
      enabled: _isEmergency ? true : _enabled,
      physicalSirenEnabled: _physicalSirenEnabled,
      fullscreenEnabled: _fullscreenEnabled,
      triggerDelaySeconds: _isEmergency ? 0 : _triggerDelaySeconds,
    );

    try {
      await FirebaseDatabase.instance
          .ref(
            'accounts/${widget.ownerUid}/homes/${widget.homeId}/devices/${widget.deviceId}/alarmPolicy',
          )
          .set(settings.toFirebaseMap());

      if (!mounted) {
        return;
      }

      showTopToast(
        context,
        strings.t('Đã lưu cấu hình báo động'),
        color: SafeHomeColors.safe,
        icon: Icons.check_circle_rounded,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _saving = false);
      showTopToast(
        context,
        strings.t('Không thể lưu cấu hình báo động'),
        color: SafeHomeColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final controlsEnabled = widget.canEdit && !_saving;
    final dependentControlsEnabled =
        controlsEnabled && (_isEmergency || _enabled);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: SafeHomeColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: SafeHomeColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: SafeHomeColors.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
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
                          strings.t('Cấu hình báo động'),
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
              ),
              const SizedBox(height: 12),
              Text(
                strings.t(
                  'Điều khiển cách cảm biến này kích hoạt cảnh báo.',
                ),
                style: const TextStyle(
                  color: SafeHomeColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _policySwitchTile(
                icon: Icons.shield_rounded,
                title: strings.t('Tham gia báo động'),
                subtitle: strings.t(
                  _isEmergency
                      ? 'Cảm biến khẩn cấp luôn kích hoạt ngay lập tức.'
                      : 'Tắt để cảm biến không tạo Alarm.',
                ),
                value: _isEmergency ? true : _enabled,
                enabled: controlsEnabled && !_isEmergency,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 10),
              _policySwitchTile(
                icon: Icons.campaign_rounded,
                title: strings.t('Bật còi vật lý'),
                subtitle: strings.t('Cho phép kích hoạt còi trong nhà.'),
                value: _physicalSirenEnabled,
                enabled: dependentControlsEnabled,
                onChanged: (value) =>
                    setState(() => _physicalSirenEnabled = value),
              ),
              const SizedBox(height: 10),
              _policySwitchTile(
                icon: Icons.phone_android_rounded,
                title: strings.t('Đánh thức màn hình'),
                subtitle: strings.t(
                  'Hiển thị cảnh báo toàn màn hình trên điện thoại.',
                ),
                value: _fullscreenEnabled,
                enabled: dependentControlsEnabled,
                onChanged: (value) =>
                    setState(() => _fullscreenEnabled = value),
              ),
              const SizedBox(height: 10),
              _delayCard(
                strings: strings,
                enabled: dependentControlsEnabled && !_isEmergency,
              ),
              if (_isEmergency) ...[
                const SizedBox(height: 10),
                _noticeCard(
                  icon: Icons.bolt_rounded,
                  text: strings.t(
                    'Cảm biến khẩn cấp luôn kích hoạt ngay lập tức.',
                  ),
                  color: SafeHomeColors.danger,
                ),
              ],
              if (!widget.canEdit) ...[
                const SizedBox(height: 10),
                _noticeCard(
                  icon: Icons.lock_outline_rounded,
                  text: strings.t(
                    'Chỉ chủ nhà và quản trị viên có thể thay đổi cài đặt này.',
                  ),
                  color: SafeHomeColors.warning,
                ),
              ],
              const SizedBox(height: 20),
              if (widget.canEdit)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(strings.t('Lưu')),
                    style: FilledButton.styleFrom(
                      backgroundColor: SafeHomeColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _delayCard({
    required AppStrings strings,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SafeHomeColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: SafeHomeColors.warning,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('Độ trễ kích hoạt'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SafeHomeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.t('Chỉ áp dụng cho cảm biến an ninh.'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: SafeHomeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _isEmergency ? 0 : _triggerDelaySeconds,
              items: _delayOptions
                  .map(
                    (seconds) => DropdownMenuItem<int>(
                      value: seconds,
                      child: Text(
                        seconds == 0
                            ? strings.t('Ngay lập tức')
                            : '$seconds ${strings.t('giây')}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled
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

Widget _policySwitchTile({
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

Widget _noticeCard({
  required IconData icon,
  required String text,
  required Color color,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.16)),
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
              color: SafeHomeColors.textPrimary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

int _toBoundedDelay(dynamic value) {
  final parsed = value is num
      ? value.round()
      : int.tryParse(value?.toString() ?? '') ?? 0;
  return parsed.clamp(0, 120).toInt();
}
