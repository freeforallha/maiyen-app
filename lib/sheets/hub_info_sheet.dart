import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../safehome_theme.dart';

Map<String, dynamic> _hubInfoMap(dynamic raw) {
  if (raw is! Map) {
    return <String, dynamic>{};
  }

  return raw.map<String, dynamic>(
    (key, value) => MapEntry(key.toString(), value),
  );
}

String _hubTypeText(Map<String, dynamic> hubStatus) {
  final model = hubStatus['hubModel']?.toString().trim() ?? '';

  if (model.isNotEmpty) {
    return model;
  }

  final rawType = hubStatus['hubType']?.toString().trim() ?? '';

  return switch (rawType) {
    'raspberry_pi' => 'Raspberry Pi',
    '' => '',
    _ => rawType,
  };
}

String _formatHubDateTime(dynamic rawValue) {
  final dateTime = parseLastSeen(rawValue)?.toLocal();

  if (dateTime == null) {
    return '';
  }

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return '${twoDigits(dateTime.day)}/${twoDigits(dateTime.month)}/'
      '${dateTime.year} ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}

void showHubInfoSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required String homeName,
}) {
  SafeHomeNavigation.pushChildPage<void>(
    context: context,
    routeName: 'hub_info',
    builder: (pageContext) {
      final strings = AppStrings.of(pageContext);
      final homeRef = FirebaseDatabase.instance.ref(
        'accounts/$ownerUid/homes/$homeId',
      );

      return ColoredBox(
        color: SafeHomeColors.background,
        child: StreamBuilder<DatabaseEvent>(
          stream: homeRef.onValue,
          builder: (context, snapshot) {
            final home = _hubInfoMap(snapshot.data?.snapshot.value);
            final hubStatus = _hubInfoMap(home['hubStatus']);
            final hubEvaluation = evaluateHubStatus(home);

            final hubId =
                (home['hubId'] ?? hubStatus['hubId'])?.toString().trim() ?? '';
            final tracked =
                hubId.isNotEmpty || hubEvaluation['tracked'] == true;
            final checking = hubEvaluation['checking'] == true;
            final online =
                tracked && hubEvaluation['online'] == true && !checking;

            final hubName = hubStatus['hubName']?.toString().trim() ?? '';
            final hubType = _hubTypeText(hubStatus);
            final wifiConnected = parseDeviceBool(hubStatus['wifiConnected']);
            final wifiSsid = hubStatus['wifiSsid']?.toString().trim() ?? '';
            final lastHeartbeat = _formatHubDateTime(
              hubStatus['lastHeartbeatAt'],
            );

            final statusText = !tracked
                ? strings.t('Hub chưa gửi trạng thái')
                : checking
                ? strings.t('Đang kiểm tra kết nối Hub')
                : online
                ? strings.t('Online')
                : strings.t('Offline');
            final statusColor = !tracked || checking
                ? SafeHomeColors.textSecondary
                : online
                ? SafeHomeColors.safe
                : SafeHomeColors.danger;
            final statusIcon = !tracked || checking
                ? Icons.sync_rounded
                : online
                ? Icons.check_circle_rounded
                : Icons.cloud_off_rounded;

            String wifiText;
            Color wifiColor;

            if (wifiConnected == true) {
              wifiText = wifiSsid.isNotEmpty ? wifiSsid : strings.t('Online');
              wifiColor = SafeHomeColors.safe;
            } else if (wifiConnected == false) {
              wifiText = strings.t('Offline');
              wifiColor = SafeHomeColors.warning;
            } else {
              wifiText = strings.t('Chưa cập nhật');
              wifiColor = SafeHomeColors.textSecondary;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SafeHomeColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: SafeHomeColors.primary,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${strings.t('Hub trung tâm')} SafeHome (HUB)',
                              style: const TextStyle(
                                color: SafeHomeColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              homeName.trim().isEmpty
                                  ? homeId
                                  : homeName.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SafeHomeColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('Tình trạng'),
                                style: const TextStyle(
                                  color: SafeHomeColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HubInfoCard(
                    children: [
                      _HubInfoRow(
                        icon: Icons.badge_outlined,
                        label: strings.t('Tên'),
                        value: hubName.isEmpty ? 'SafeHome HUB' : hubName,
                      ),
                      _HubInfoRow(
                        icon: Icons.memory_rounded,
                        label: strings.t('Loại thiết bị'),
                        value: hubType.isEmpty
                            ? strings.t('Chưa cập nhật')
                            : hubType,
                      ),
                      _HubInfoRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Device ID',
                        value: hubId.isEmpty
                            ? strings.t('Chưa cập nhật')
                            : hubId,
                        selectable: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HubInfoCard(
                    children: [
                      _HubInfoRow(
                        icon: wifiConnected == false
                            ? Icons.wifi_off_rounded
                            : Icons.wifi_rounded,
                        label: 'Wi-Fi',
                        value: wifiText,
                        valueColor: wifiColor,
                      ),
                      _HubInfoRow(
                        icon: Icons.schedule_rounded,
                        label: strings.t('Liên lạc cuối'),
                        value: lastHeartbeat.isEmpty
                            ? strings.t('Chưa cập nhật')
                            : lastHeartbeat,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _HubInfoCard extends StatelessWidget {
  const _HubInfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SafeHomeColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, color: SafeHomeColors.border),
          ],
        ],
      ),
    );
  }
}

class _HubInfoRow extends StatelessWidget {
  const _HubInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: valueColor ?? SafeHomeColors.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      height: 1.25,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SafeHomeColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: SafeHomeColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: SafeHomeColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                if (selectable)
                  SelectableText(value, style: valueStyle)
                else
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: valueStyle,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
