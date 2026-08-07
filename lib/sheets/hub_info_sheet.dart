import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../config/brand_config.dart';
import '../config/system_version.dart';
import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import '../localization/hub_update_strings.dart';
import '../localization/system_version_strings.dart';
import '../navigation/maiyen_navigation.dart';
import '../maiyen_theme.dart';

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

String _hubInfoString(dynamic rawValue) {
  return rawValue?.toString().trim() ?? '';
}

bool _isHubUpdatePendingStatus(String status) {
  return status == 'requested' || status == 'queued';
}

Future<void> _requestHubUpdate({
  required BuildContext context,
  required AppStrings strings,
  required DatabaseReference homeRef,
  required String ownerUid,
  required String releaseId,
}) async {
  final currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

  if (currentUid.isEmpty || currentUid != ownerUid) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.hubUpdateOwnerOnlyText)));
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.system_update_alt_rounded,
              color: MaiYenColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(strings.hubUpdateConfirmTitle)),
          ],
        ),
        content: Text(strings.hubUpdateConfirmMessage(releaseId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('Hủy')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.download_rounded),
            label: Text(strings.hubUpdateButtonText),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    await homeRef.child('hubUpdateRequest').set({
      'releaseId': releaseId,
      'requestedBy': currentUid,
      'requestedAt': ServerValue.timestamp,
      'status': 'requested',
    });

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.hubUpdateRequestSentText)));
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.hubUpdateRequestFailedText)));
  }
}

void showHubInfoSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required String homeName,
}) {
  MaiYenNavigation.pushChildPage<void>(
    context: context,
    routeName: 'hub_info',
    builder: (pageContext) {
      final strings = AppStrings.of(pageContext);
      final homeRef = FirebaseDatabase.instance.ref(
        'accounts/$ownerUid/homes/$homeId',
      );

      return ColoredBox(
        color: MaiYenColors.background,
        child: StreamBuilder<DatabaseEvent>(
          stream: homeRef.onValue,
          builder: (context, snapshot) {
            final home = _hubInfoMap(snapshot.data?.snapshot.value);
            final hubStatus = _hubInfoMap(home['hubStatus']);
            final hubEvaluation = evaluateHubStatus(home);
            final versionInfo = HubSystemVersionInfo.fromHubStatus(hubStatus);

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
                ? MaiYenColors.textSecondary
                : online
                ? MaiYenColors.safe
                : MaiYenColors.danger;
            final statusIcon = !tracked || checking
                ? Icons.sync_rounded
                : online
                ? Icons.check_circle_rounded
                : Icons.cloud_off_rounded;

            String wifiText;
            Color wifiColor;

            if (wifiConnected == true) {
              wifiText = wifiSsid.isNotEmpty ? wifiSsid : strings.t('Online');
              wifiColor = MaiYenColors.safe;
            } else if (wifiConnected == false) {
              wifiText = strings.t('Offline');
              wifiColor = MaiYenColors.warning;
            } else {
              wifiText = strings.t('Chưa cập nhật');
              wifiColor = MaiYenColors.textSecondary;
            }

            final compatibility = versionInfo.compatibility;
            final compatibilityText = switch (compatibility) {
              ProtocolCompatibility.compatible =>
                strings.protocolCompatibleText,
              ProtocolCompatibility.incompatible =>
                strings.protocolIncompatibleText,
              ProtocolCompatibility.unknown => strings.t('Chưa cập nhật'),
            };
            final compatibilityColor = switch (compatibility) {
              ProtocolCompatibility.compatible => MaiYenColors.safe,
              ProtocolCompatibility.incompatible => MaiYenColors.danger,
              ProtocolCompatibility.unknown => MaiYenColors.textSecondary,
            };
            final compatibilityIcon = switch (compatibility) {
              ProtocolCompatibility.compatible => Icons.verified_rounded,
              ProtocolCompatibility.incompatible => Icons.error_outline_rounded,
              ProtocolCompatibility.unknown => Icons.help_outline_rounded,
            };

            String versionOrUnknown(String version) =>
                version.isEmpty ? strings.t('Chưa cập nhật') : version;

            final currentUid =
                FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
            final isOwner = currentUid.isNotEmpty && currentUid == ownerUid;

            final updateAgentStatus = _hubInfoString(
              hubStatus['updateAgentStatus'],
            );
            final updateAgentReady = updateAgentStatus == 'ready';
            final updateAvailable =
                parseDeviceBool(hubStatus['updateAvailable']) == true;
            final latestReleaseId = _hubInfoString(
              hubStatus['latestReleaseId'],
            );
            final latestBackendVersion = _hubInfoString(
              hubStatus['latestBackendVersion'],
            );
            final latestHubFirmwareVersion = _hubInfoString(
              hubStatus['latestHubFirmwareVersion'],
            );
            final latestReleaseCritical =
                parseDeviceBool(hubStatus['latestReleaseCritical']) == true;

            final updateRequest = _hubInfoMap(home['hubUpdateRequest']);
            final updateResult = _hubInfoMap(home['hubUpdateStatus']);

            final requestReleaseId = _hubInfoString(updateRequest['releaseId']);
            final requestStatus = _hubInfoString(updateRequest['status']);
            final resultReleaseId = _hubInfoString(updateResult['releaseId']);
            final resultStatus = _hubInfoString(updateResult['status']);

            const completedStatusVisibleDuration = Duration(minutes: 15);
            final now = DateTime.now();
            final requestFinishedAt = parseLastSeen(
              updateRequest['finishedAt'],
            )?.toLocal();
            final resultFinishedAt = parseLastSeen(
              updateResult['finishedAt'],
            )?.toLocal();

            bool isRecentCompletedStatus(String status, DateTime? finishedAt) {
              if (status != 'success' || finishedAt == null) {
                return false;
              }

              final age = now.difference(finishedAt);
              return !age.isNegative && age <= completedStatusVisibleDuration;
            }

            bool isRelevantFinalStatus(String status, DateTime? finishedAt) {
              if (status == 'success') {
                return isRecentCompletedStatus(status, finishedAt);
              }

              if (status == 'failed' || status == 'rejected') {
                return updateAvailable;
              }

              return false;
            }

            Map<String, dynamic> activeUpdate = <String, dynamic>{};
            String activeUpdateStatus = '';
            String activeUpdateReleaseId = '';

            if (requestReleaseId == latestReleaseId &&
                _isHubUpdatePendingStatus(requestStatus)) {
              activeUpdate = updateRequest;
              activeUpdateStatus = requestStatus;
              activeUpdateReleaseId = requestReleaseId;
            } else if (resultReleaseId == latestReleaseId &&
                isRelevantFinalStatus(resultStatus, resultFinishedAt)) {
              activeUpdate = updateResult;
              activeUpdateStatus = resultStatus;
              activeUpdateReleaseId = resultReleaseId;
            } else if (requestReleaseId == latestReleaseId &&
                isRelevantFinalStatus(requestStatus, requestFinishedAt)) {
              activeUpdate = updateRequest;
              activeUpdateStatus = requestStatus;
              activeUpdateReleaseId = requestReleaseId;
            }

            final updatePending = _isHubUpdatePendingStatus(activeUpdateStatus);
            final updateCompletedForLatest =
                activeUpdateStatus == 'success' &&
                activeUpdateReleaseId == latestReleaseId;

            late String updateTitle;
            late String updateDescription;
            late Color updateColor;
            late IconData updateIcon;

            if (!updateAgentReady) {
              updateTitle = strings.hubUpdateAgentUnavailableText;
              updateDescription = strings.hubUpdateAgentUnavailableText;
              updateColor = MaiYenColors.textSecondary;
              updateIcon = Icons.system_update_alt_rounded;
            } else {
              switch (activeUpdateStatus) {
                case 'requested':
                  updateTitle = strings.hubUpdateWaitingText;
                  updateDescription = strings.hubUpdateWaitingText;
                  updateColor = MaiYenColors.primary;
                  updateIcon = Icons.hourglass_top_rounded;
                  break;
                case 'queued':
                  updateTitle = strings.hubUpdateInstallingText;
                  updateDescription = strings.hubUpdateInstallingText;
                  updateColor = MaiYenColors.warning;
                  updateIcon = Icons.sync_rounded;
                  break;
                case 'success':
                  updateTitle = strings.hubUpdateSuccessText;
                  updateDescription = strings.hubUpdateSuccessText;
                  updateColor = MaiYenColors.safe;
                  updateIcon = Icons.check_circle_rounded;
                  break;
                case 'failed':
                  updateTitle = strings.hubUpdateFailedText;
                  updateDescription = strings.hubUpdateFailedText;
                  updateColor = MaiYenColors.danger;
                  updateIcon = Icons.error_outline_rounded;
                  break;
                case 'rejected':
                  updateTitle = strings.hubUpdateRejectedText;
                  updateDescription = strings.hubUpdateRejectedText;
                  updateColor = MaiYenColors.danger;
                  updateIcon = Icons.block_rounded;
                  break;
                default:
                  if (updateAvailable && latestReleaseId.isNotEmpty) {
                    updateTitle = strings.hubUpdateAvailableText(
                      latestReleaseId,
                    );
                    updateDescription = strings.hubUpdateAvailableText(
                      latestReleaseId,
                    );
                    updateColor = MaiYenColors.primary;
                    updateIcon = Icons.new_releases_rounded;
                  } else {
                    updateTitle = strings.hubUpdateUpToDateText;
                    updateDescription = strings.hubUpdateUpToDateText;
                    updateColor = MaiYenColors.safe;
                    updateIcon = Icons.verified_rounded;
                  }
              }
            }

            final updateDescriptionParts = <String>[updateDescription];

            if (updateAvailable && checking) {
              updateDescriptionParts.add(
                strings.t('Đang kiểm tra kết nối Hub'),
              );
            } else if (updateAvailable && tracked && !online) {
              updateDescriptionParts.add(strings.hubUpdateOfflineText);
            }

            if (updateAvailable && !isOwner) {
              updateDescriptionParts.add(strings.hubUpdateOwnerOnlyText);
            }

            updateDescription = updateDescriptionParts.join('\n');

            final updateError = _hubInfoString(
              activeUpdate['errorMessage'] ??
                  activeUpdate['errorCode'] ??
                  hubStatus['lastUpdateError'],
            );

            final showUpdateButton =
                isOwner && updateAvailable && latestReleaseId.isNotEmpty;
            final canRequestUpdate =
                showUpdateButton &&
                updateAgentReady &&
                online &&
                !updatePending &&
                !updateCompletedForLatest;
            final retryUpdate =
                activeUpdateStatus == 'failed' ||
                activeUpdateStatus == 'rejected';
            final updateButtonLabel = updatePending
                ? activeUpdateStatus == 'queued'
                      ? strings.hubUpdateInstallingText
                      : strings.hubUpdateWaitingText
                : retryUpdate
                ? strings.hubUpdateRetryButtonText
                : strings.hubUpdateButtonText;

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
                          color: MaiYenColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: MaiYenColors.primary,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${strings.t('Hub trung tâm')} ${BrandConfig.appName} (HUB)',
                              style: const TextStyle(
                                color: MaiYenColors.textPrimary,
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
                                color: MaiYenColors.textSecondary,
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
                                  color: MaiYenColors.textSecondary,
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
                        value: hubName.isEmpty
                            ? BrandConfig.defaultHubName
                            : hubName,
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
                  const SizedBox(height: 20),
                  Text(
                    strings.systemVersionsTitle,
                    style: const TextStyle(
                      color: MaiYenColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _HubInfoCard(
                    children: [
                      _HubInfoRow(
                        icon: Icons.phone_android_rounded,
                        label: strings.appVersionLabel,
                        value: SystemVersionConfig.appVersionDisplay,
                      ),
                      _HubInfoRow(
                        icon: Icons.dns_rounded,
                        label: strings.backendVersionLabel,
                        value: versionOrUnknown(versionInfo.backendVersion),
                      ),
                      _HubInfoRow(
                        icon: Icons.developer_board_rounded,
                        label: strings.hubFirmwareVersionLabel,
                        value: versionOrUnknown(versionInfo.hubFirmwareVersion),
                      ),
                      _HubInfoRow(
                        icon: Icons.lan_rounded,
                        label: strings.protocolVersionLabel,
                        value: versionOrUnknown(versionInfo.protocolVersion),
                      ),
                      _HubInfoRow(
                        icon: compatibilityIcon,
                        label: strings.protocolCompatibilityLabel,
                        value: compatibilityText,
                        valueColor: compatibilityColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.hubUpdateSectionTitle,
                    style: const TextStyle(
                      color: MaiYenColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _HubUpdateCard(
                    icon: updateIcon,
                    color: updateColor,
                    title: updateTitle,
                    description: updateDescription,
                    releaseId: latestReleaseId,
                    backendLabel: strings.backendVersionLabel,
                    backendVersion: latestBackendVersion,
                    firmwareLabel: strings.hubFirmwareVersionLabel,
                    firmwareVersion: latestHubFirmwareVersion,
                    critical: latestReleaseCritical,
                    criticalText: strings.hubUpdateCriticalText,
                    errorDetails: updateError,
                    showAction: showUpdateButton,
                    actionEnabled: canRequestUpdate,
                    actionPending: updatePending,
                    actionLabel: updateButtonLabel,
                    onAction: () {
                      _requestHubUpdate(
                        context: context,
                        strings: strings,
                        homeRef: homeRef,
                        ownerUid: ownerUid,
                        releaseId: latestReleaseId,
                      );
                    },
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

class _HubUpdateCard extends StatelessWidget {
  const _HubUpdateCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.releaseId,
    required this.backendLabel,
    required this.backendVersion,
    required this.firmwareLabel,
    required this.firmwareVersion,
    required this.critical,
    required this.criticalText,
    required this.errorDetails,
    required this.showAction,
    required this.actionEnabled,
    required this.actionPending,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String releaseId;
  final String backendLabel;
  final String backendVersion;
  final String firmwareLabel;
  final String firmwareVersion;
  final bool critical;
  final String criticalText;
  final String errorDetails;
  final bool showAction;
  final bool actionEnabled;
  final bool actionPending;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final hasVersionDetails =
        releaseId.isNotEmpty ||
        backendVersion.isNotEmpty ||
        firmwareVersion.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaiYenColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (critical) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MaiYenColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          criticalText,
                          style: const TextStyle(
                            color: MaiYenColors.danger,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    if (description.isNotEmpty && description != title) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          color: MaiYenColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasVersionDetails) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MaiYenColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  if (releaseId.isNotEmpty)
                    _HubUpdateVersionLine(label: 'Release', value: releaseId),
                  if (backendVersion.isNotEmpty)
                    _HubUpdateVersionLine(
                      label: backendLabel,
                      value: backendVersion,
                    ),
                  if (firmwareVersion.isNotEmpty)
                    _HubUpdateVersionLine(
                      label: firmwareLabel,
                      value: firmwareVersion,
                    ),
                ],
              ),
            ),
          ],
          if (errorDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: MaiYenColors.danger.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                errorDetails,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MaiYenColors.danger,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (showAction) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: actionEnabled ? onAction : null,
              icon: actionPending
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.system_update_alt_rounded),
              label: Text(
                actionLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HubUpdateVersionLine extends StatelessWidget {
  const _HubUpdateVersionLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: MaiYenColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: MaiYenColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubInfoCard extends StatelessWidget {
  const _HubInfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: MaiYenColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MaiYenColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, color: MaiYenColors.border),
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
      color: valueColor ?? MaiYenColors.textPrimary,
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
              color: MaiYenColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: MaiYenColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: MaiYenColors.textSecondary,
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
