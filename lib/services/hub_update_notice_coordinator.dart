import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import '../localization/hub_update_strings.dart';
import '../maiyen_theme.dart';
import '../sheets/hub_info_sheet.dart';
import 'package:maiyen_app/helpers/debug_log.dart';

typedef HubUpdateOwnerUidResolver =
    String Function(String homeId, Map<String, dynamic> home);
typedef HubUpdateHomeNameResolver = String Function(String homeId);
typedef HubUpdateHomeSelector = void Function(String homeId);

class HubUpdateNoticeCoordinator {
  static const String _preferencePrefix = 'maiyen_hub_update_notice_v1';

  bool _disposed = false;
  bool _checkScheduled = false;
  bool _checkRunning = false;
  bool _noticeShowing = false;

  void schedule({
    required BuildContext context,
    required String uid,
    required Map<String, dynamic> homes,
    required List<String> homeOrder,
    required String selectedHome,
    required HubUpdateOwnerUidResolver ownerUidForHome,
    required HubUpdateHomeNameResolver homeNameForHome,
    required HubUpdateHomeSelector selectHome,
  }) {
    if (_disposed ||
        !context.mounted ||
        uid.isEmpty ||
        homes.isEmpty ||
        _checkScheduled ||
        _checkRunning ||
        _noticeShowing) {
      return;
    }

    _checkScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;

      if (_disposed || !context.mounted) {
        return;
      }

      unawaited(
        _showIfNeeded(
          context: context,
          uid: uid,
          homes: homes,
          homeOrder: homeOrder,
          selectedHome: selectedHome,
          ownerUidForHome: ownerUidForHome,
          homeNameForHome: homeNameForHome,
          selectHome: selectHome,
        ),
      );
    });
  }

  Future<void> _showIfNeeded({
    required BuildContext context,
    required String uid,
    required Map<String, dynamic> homes,
    required List<String> homeOrder,
    required String selectedHome,
    required HubUpdateOwnerUidResolver ownerUidForHome,
    required HubUpdateHomeNameResolver homeNameForHome,
    required HubUpdateHomeSelector selectHome,
  }) async {
    if (_disposed ||
        !context.mounted ||
        _checkRunning ||
        _noticeShowing ||
        uid.isEmpty ||
        homes.isEmpty) {
      return;
    }

    _checkRunning = true;

    try {
      final currentRoute = ModalRoute.of(context);

      // Không chèn banner lên Alarm hoặc trang con đang mở. Timer ở HomePage
      // sẽ kiểm tra lại sau khi người dùng quay về trang chính.
      if (currentRoute != null && !currentRoute.isCurrent) {
        return;
      }

      final orderedHomeIds = <String>[
        if (selectedHome.isNotEmpty) selectedHome,
        ...homeOrder,
        ...homes.keys,
      ];
      final visitedHomeIds = <String>{};
      final preferences = await SharedPreferences.getInstance();

      if (_disposed || !context.mounted) {
        return;
      }

      for (final homeId in orderedHomeIds) {
        if (homeId.isEmpty ||
            !visitedHomeIds.add(homeId) ||
            !homes.containsKey(homeId)) {
          continue;
        }

        final home = safeMap(homes[homeId]);
        final hubStatus = safeMap(home['hubStatus']);
        final updateAvailable =
            parseDeviceBool(hubStatus['updateAvailable']) == true;
        final updateAgentStatus =
            hubStatus['updateAgentStatus']?.toString().trim() ?? '';
        final releaseId = hubStatus['latestReleaseId']?.toString().trim() ?? '';

        if (!updateAvailable ||
            updateAgentStatus != 'ready' ||
            releaseId.isEmpty ||
            _hasPendingRequest(home, releaseId)) {
          continue;
        }

        final ownerUid = ownerUidForHome(homeId, home).trim();

        // Chỉ chủ nhà được thấy thông báo có phiên bản Hub mới.
        // Member/Admin vẫn xem được trạng thái Hub khi được phép, nhưng
        // không bị làm phiền bởi banner yêu cầu xử lý của chủ nhà.
        if (ownerUid.isEmpty || ownerUid != uid.trim()) {
          continue;
        }

        final preferenceKey = '$_preferencePrefix.$uid.$ownerUid.$homeId';
        final seenReleaseId = preferences.getString(preferenceKey) ?? '';

        if (seenReleaseId == releaseId) {
          continue;
        }

        final homeName = homeNameForHome(homeId);
        final critical =
            parseDeviceBool(hubStatus['latestReleaseCritical']) == true;

        // Lưu ngay trước khi hiển thị để nhiều callback Firebase liên tiếp
        // không tạo banner trùng cho cùng một nhà và release.
        await preferences.setString(preferenceKey, releaseId);

        if (_disposed || !context.mounted) {
          return;
        }

        await _showNotice(
          context: context,
          homeId: homeId,
          ownerUid: ownerUid,
          homeName: homeName,
          releaseId: releaseId,
          critical: critical,
          selectHome: selectHome,
        );
        return;
      }
    } catch (error) {
      safeDebugPrint('HUB_UPDATE_NOTICE_ERROR: $error');
    } finally {
      _checkRunning = false;
    }
  }

  bool _hasPendingRequest(Map<String, dynamic> home, String releaseId) {
    final request = safeMap(home['hubUpdateRequest']);
    final requestReleaseId = request['releaseId']?.toString().trim() ?? '';
    final requestStatus = request['status']?.toString().trim() ?? '';

    return requestReleaseId == releaseId &&
        (requestStatus == 'requested' || requestStatus == 'queued');
  }

  Future<void> _showNotice({
    required BuildContext context,
    required String homeId,
    required String ownerUid,
    required String homeName,
    required String releaseId,
    required bool critical,
    required HubUpdateHomeSelector selectHome,
  }) async {
    if (_disposed || !context.mounted || _noticeShowing) {
      return;
    }

    _noticeShowing = true;
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.hide);

    void openHubInfo() {
      if (_disposed || !context.mounted) {
        return;
      }

      messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
      selectHome(homeId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed || !context.mounted) {
          return;
        }

        showHubInfoSheet(
          context: context,
          ownerUid: ownerUid,
          homeId: homeId,
          homeName: homeName,
        );
      });
    }

    final color = critical ? MaiYenColors.warning : MaiYenColors.primary;
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    final bottomBarBottomInset = bottomSafeInset > 10.0
        ? bottomSafeInset
        : 10.0;
    final noticeBottomMargin = bottomBarBottomInset + 68.0 + 12.0;

    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(14, 12, 14, noticeBottomMargin),
        padding: EdgeInsets.zero,
        elevation: 10,
        backgroundColor: MaiYenColors.surface,
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.30)),
        ),
        content: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openHubInfo,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      critical
                          ? Icons.warning_amber_rounded
                          : Icons.system_update_alt_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.hubUpdateAvailableText(releaseId),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MaiYenColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          homeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MaiYenColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: color, size: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await controller.closed;
    _noticeShowing = false;
  }

  void dispose() {
    _disposed = true;
  }
}
