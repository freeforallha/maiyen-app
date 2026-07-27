import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import '../maiyen_theme.dart';
import '../sheets/device_alarm_policy_sheet.dart';
import '../services/system_usage_service.dart';
import '../navigation/maiyen_navigation.dart';

class SystemHealthStatusLine extends StatelessWidget {
  const SystemHealthStatusLine({
    super.key,
    required this.ownerUid,
    required this.homeId,
    required this.securityMode,
    required this.securityModeSource,
  });

  final String ownerUid;
  final String homeId;
  final String securityMode;
  final String securityModeSource;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return FutureBuilder<_SystemHealthSnapshot>(
      future: _SystemHealthSnapshot.load(
        context: context,
        ownerUid: ownerUid,
        homeId: homeId,
        securityMode: securityMode,
        securityModeSource: securityModeSource,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (data == null) {
          return _SystemHealthLineShell(
            icon: Icons.health_and_safety_rounded,
            color: MaiYenColors.textSecondary,
            text: strings.t("Hệ thống: Đang kiểm tra..."),
            onTap: null,
          );
        }

        return _SystemHealthLineShell(
          icon: data.summaryIcon,
          color: data.summaryColor,
          text: data.summaryText,
          onTap: () => showSystemHealthSheet(
            context: context,
            ownerUid: ownerUid,
            homeId: homeId,
            securityMode: securityMode,
            securityModeSource: securityModeSource,
          ),
        );
      },
    );
  }
}

class _SystemHealthLineShell extends StatelessWidget {
  const _SystemHealthLineShell({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showSystemHealthSheet({
  required BuildContext context,
  required String ownerUid,
  required String homeId,
  required String securityMode,
  required String securityModeSource,
}) async {
  final strings = AppStrings.of(context);

  await MaiYenNavigation.showModalSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          decoration: const BoxDecoration(
            color: MaiYenColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: FutureBuilder<_SystemHealthSnapshot>(
            future: _SystemHealthSnapshot.load(
              context: sheetContext,
              ownerUid: ownerUid,
              homeId: homeId,
              securityMode: securityMode,
              securityModeSource: securityModeSource,
            ),
            builder: (context, snapshot) {
              final data = snapshot.data;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MaiYenColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.t("Hệ thống MaiYen"),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: MaiYenColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        data?.summaryIcon ?? Icons.health_and_safety_rounded,
                        color: data?.summaryColor ?? MaiYenColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.t(
                        "Kiểm tra điện thoại và cách bạn đang dùng ứng dụng.",
                      ),
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: MaiYenColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 34),
                      child: CircularProgressIndicator(),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _SystemHealthSection(
                            title: strings.t("Thiết bị của bạn"),
                            icon: Icons.phone_android_rounded,
                            items: data.deviceItems,
                          ),
                          const SizedBox(height: 12),
                          _SystemHealthSection(
                            title: strings.t("Cách bạn đang dùng ứng dụng"),
                            icon: Icons.fact_check_rounded,
                            items: data.usageItems,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

enum _SystemHealthLevel { ok, info, warning, danger }

class _SystemHealthItem {
  const _SystemHealthItem({
    required this.level,
    required this.icon,
    required this.title,
    required this.message,
  });

  final _SystemHealthLevel level;
  final IconData icon;
  final String title;
  final String message;

  Color get color {
    switch (level) {
      case _SystemHealthLevel.ok:
        return MaiYenColors.safe;
      case _SystemHealthLevel.info:
        return MaiYenColors.info;
      case _SystemHealthLevel.warning:
        return MaiYenColors.warning;
      case _SystemHealthLevel.danger:
        return MaiYenColors.danger;
    }
  }

  IconData get statusIcon {
    switch (level) {
      case _SystemHealthLevel.ok:
        return Icons.check_circle_rounded;
      case _SystemHealthLevel.info:
        return Icons.info_rounded;
      case _SystemHealthLevel.warning:
        return Icons.error_rounded;
      case _SystemHealthLevel.danger:
        return Icons.warning_rounded;
    }
  }
}

class _SystemHealthSnapshot {
  const _SystemHealthSnapshot({
    required this.summaryText,
    required this.summaryColor,
    required this.summaryIcon,
    required this.deviceItems,
    required this.usageItems,
  });

  final String summaryText;
  final Color summaryColor;
  final IconData summaryIcon;
  final List<_SystemHealthItem> deviceItems;
  final List<_SystemHealthItem> usageItems;

  static Future<_SystemHealthSnapshot> load({
    required BuildContext context,
    required String ownerUid,
    required String homeId,
    required String securityMode,
    required String securityModeSource,
  }) async {
    final strings = AppStrings.of(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final cleanOwnerUid = ownerUid.trim();
    final cleanHomeId = homeId.trim();

    final results = await Future.wait<Object?>([
      FirebaseMessaging.instance.getNotificationSettings(),
      FirebaseMessaging.instance.getToken(),
      Geolocator.isLocationServiceEnabled(),
      Geolocator.checkPermission(),
      if (cleanOwnerUid.isNotEmpty && cleanHomeId.isNotEmpty)
        FirebaseDatabase.instance
            .ref('accounts/$cleanOwnerUid/homes/$cleanHomeId')
            .get()
      else
        Future<DataSnapshot?>.value(null),
      if (currentUid.isNotEmpty && cleanHomeId.isNotEmpty)
        FirebaseDatabase.instance
            .ref('accounts/$currentUid/homePresence/$cleanHomeId')
            .get()
      else
        Future<DataSnapshot?>.value(null),
      if (currentUid.isNotEmpty && cleanHomeId.isNotEmpty)
        FirebaseDatabase.instance
            .ref('accounts/$currentUid/customRules/$cleanHomeId')
            .get()
      else
        Future<DataSnapshot?>.value(null),
      SystemUsageService.previousOpenAt(),
    ]);

    final notificationSettings = results[0] as NotificationSettings;
    final fcmToken = results[1]?.toString().trim() ?? '';
    final locationServiceEnabled = results[2] == true;
    final locationPermission = results[3] as LocationPermission;
    final homeSnapshot = results[4] as DataSnapshot?;
    final presenceSnapshot = results[5] as DataSnapshot?;
    final customRulesSnapshot = results[6] as DataSnapshot?;
    final previousOpenAt = results[7] as int? ?? 0;

    final home = safeMap(homeSnapshot?.value);
    final presence = safeMap(presenceSnapshot?.value);
    final customRules = safeMap(customRulesSnapshot?.value);

    final deviceItems = _buildDeviceItems(
      strings: strings,
      notificationSettings: notificationSettings,
      fcmToken: fcmToken,
      locationServiceEnabled: locationServiceEnabled,
      locationPermission: locationPermission,
      presence: presence,
      home: home,
    );

    final usageItems = _buildUsageItems(
      strings: strings,
      home: home,
      customRules: customRules,
      securityMode: securityMode,
      securityModeSource: securityModeSource,
      locationPermission: locationPermission,
      presence: presence,
      previousOpenAt: previousOpenAt,
    );

    final allItems = [...deviceItems, ...usageItems];
    final dangerCount = allItems
        .where((item) => item.level == _SystemHealthLevel.danger)
        .length;
    final warningCount = allItems
        .where((item) => item.level == _SystemHealthLevel.warning)
        .length;
    final issueCount = dangerCount + warningCount;

    if (dangerCount > 0) {
      return _SystemHealthSnapshot(
        summaryText: strings.t("Hệ thống: Có thể bỏ lỡ cảnh báo"),
        summaryColor: MaiYenColors.danger,
        summaryIcon: Icons.warning_rounded,
        deviceItems: deviceItems,
        usageItems: usageItems,
      );
    }

    if (warningCount > 0) {
      return _SystemHealthSnapshot(
        summaryText: strings.systemNeedCheckText(issueCount),
        summaryColor: MaiYenColors.warning,
        summaryIcon: Icons.error_rounded,
        deviceItems: deviceItems,
        usageItems: usageItems,
      );
    }

    return _SystemHealthSnapshot(
      summaryText: strings.t("Hệ thống: Sẵn sàng"),
      summaryColor: MaiYenColors.safe,
      summaryIcon: Icons.health_and_safety_rounded,
      deviceItems: deviceItems,
      usageItems: usageItems,
    );
  }

  static List<_SystemHealthItem> _buildDeviceItems({
    required AppStrings strings,
    required NotificationSettings notificationSettings,
    required String fcmToken,
    required bool locationServiceEnabled,
    required LocationPermission locationPermission,
    required Map<String, dynamic> presence,
    required Map<String, dynamic> home,
  }) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final autoAwayEnabled = safeMap(home['autoAway'])['enabled'] == true;
    final notificationOk =
        notificationSettings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        notificationSettings.authorizationStatus ==
            AuthorizationStatus.provisional;
    final iosSoundEnabled =
        !isIos ||
        notificationSettings.sound == AppleNotificationSetting.enabled;
    final iosTimeSensitiveEnabled =
        !isIos ||
        notificationSettings.timeSensitive ==
            AppleNotificationSetting.enabled ||
        notificationSettings.timeSensitive ==
            AppleNotificationSetting.notSupported;
    final locationAlways = locationPermission == LocationPermission.always;
    final locationDenied =
        locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever;
    final batteryUnrestricted = presence['batteryUnrestricted'] != false;
    final backgroundRestricted = presence['backgroundRestricted'] == true;
    final autoStartConfirmed = presence['autoStartConfirmed'] != false;
    final monitoringEligible = presence['monitoringEligible'] == true;

    return [
      _SystemHealthItem(
        level: notificationOk
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.notifications_active_rounded,
        title: notificationOk
            ? strings.t("Đã bật thông báo")
            : strings.t("Chưa bật thông báo"),
        message: notificationOk
            ? strings.t("Điện thoại có thể nhận thông báo MaiYen.")
            : strings.t("Cảnh báo có thể không hiển thị nếu thông báo bị tắt."),
      ),
      _SystemHealthItem(
        level: isAndroid && notificationOk
            ? _SystemHealthLevel.ok
            : isIos &&
                  (!notificationOk ||
                      !iosSoundEnabled ||
                      !iosTimeSensitiveEnabled)
            ? _SystemHealthLevel.warning
            : _SystemHealthLevel.info,
        icon: Icons.open_in_full_rounded,
        title: isAndroid
            ? strings.t("Cảnh báo toàn màn hình")
            : strings.t("Cảnh báo trên iOS"),
        message: isAndroid
            ? strings.t(
                "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.",
              )
            : strings.t(
                "iOS không mở toàn màn hình như Android; ứng dụng dùng thông báo và âm thanh hệ thống.",
              ),
      ),
      _SystemHealthItem(
        level: !autoAwayEnabled
            ? _SystemHealthLevel.info
            : locationServiceEnabled && locationAlways
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.location_on_rounded,
        title: locationAlways
            ? strings.t("Đã cấp vị trí luôn luôn")
            : strings.t("Chưa cấp vị trí luôn luôn"),
        message: !autoAwayEnabled
            ? strings.t("Chỉ cần quyền này khi dùng Auto rời khỏi nhà.")
            : !locationServiceEnabled
            ? strings.t(
                "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.",
              )
            : locationDenied
            ? strings.t("Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.")
            : strings.t(
                "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.",
              ),
      ),
      if (isAndroid)
        _SystemHealthItem(
          level: batteryUnrestricted
              ? _SystemHealthLevel.ok
              : _SystemHealthLevel.warning,
          icon: Icons.battery_saver_rounded,
          title: batteryUnrestricted
              ? strings.t("Tối ưu pin không chặn ứng dụng")
              : strings.t("Chưa tắt tối ưu pin"),
          message: batteryUnrestricted
              ? strings.t(
                  "Điện thoại ít có khả năng trì hoãn cảnh báo MaiYen.",
                )
              : strings.t(
                  "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.",
                ),
        ),
      if (isAndroid)
        _SystemHealthItem(
          level: !backgroundRestricted && autoStartConfirmed
              ? _SystemHealthLevel.ok
              : _SystemHealthLevel.warning,
          icon: Icons.run_circle_rounded,
          title: !backgroundRestricted && autoStartConfirmed
              ? strings.t("Chạy nền ổn định")
              : strings.t("Cần kiểm tra chạy nền / tự khởi động"),
          message: !backgroundRestricted && autoStartConfirmed
              ? strings.t(
                  "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.",
                )
              : strings.t(
                  "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.",
                ),
        ),
      if (isIos)
        _SystemHealthItem(
          level: _SystemHealthLevel.info,
          icon: Icons.phone_iphone_rounded,
          title: strings.t("Cơ chế iOS"),
          message: strings.t(
            "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.",
          ),
        ),
      _SystemHealthItem(
        level: fcmToken.isNotEmpty && notificationOk
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.cloud_done_rounded,
        title: fcmToken.isNotEmpty
            ? strings.t("Thiết bị nhận cảnh báo bình thường")
            : strings.t("Thiết bị chưa đăng ký nhận cảnh báo"),
        message: fcmToken.isNotEmpty
            ? strings.fcmTokenReadyText(
                monitoringEligible: monitoringEligible,
                autoAwayEnabled: autoAwayEnabled,
              )
            : strings.t(
                "Hãy mở lại ứng dụng hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.",
              ),
      ),
    ];
  }

  static List<_SystemHealthItem> _buildUsageItems({
    required AppStrings strings,
    required Map<String, dynamic> home,
    required Map<String, dynamic> customRules,
    required String securityMode,
    required String securityModeSource,
    required LocationPermission locationPermission,
    required Map<String, dynamic> presence,
    required int previousOpenAt,
  }) {
    final schedules = safeMap(home['schedules']);
    final devices = safeMap(home['devices']);
    final legacyMode = customRules['mode']?.toString();
    final alarmLegacyMode =
        (customRules['alarmMode'] ?? customRules['mode'] ?? 'home').toString();
    final reminderMode = customRules['reminderMode']?.toString() ?? legacyMode;
    final reminderCustomMode = reminderMode == 'custom';
    final customNotifications = safeMap(customRules['notifications']);
    final customDevices = safeMap(customRules['devices']);
    final autoAway = safeMap(home['autoAway']);
    final autoAwayEnabled = autoAway['enabled'] == true;
    final monitoringEligible = presence['monitoringEligible'] == true;

    final reminderEnabled = reminderCustomMode
        ? _hasEnabledSchedule(customNotifications['items'])
        : _hasEnabledSchedule(schedules['notifications']);
    final homeAlarmScheduleEnabled =
        _hasEnabledSchedule(schedules['alarms']) ||
        _hasEnabledDeviceAlarm(devices);
    final customAlarmScheduleEnabled = _hasEnabledCustomDeviceAlarm(
      customDevices,
      legacyAlarmMode: alarmLegacyMode,
    );
    final alarmScheduleEnabled =
        homeAlarmScheduleEnabled || customAlarmScheduleEnabled;
    final emergencyCounts = _emergencyDeviceCounts(devices);
    final hasSmoke = (emergencyCounts['smoke'] ?? 0) > 0;
    final hasSos = (emergencyCounts['sos'] ?? 0) > 0;
    final emergencyTotal = emergencyCounts.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSincePreviousOpen = previousOpenAt > 0
        ? ((now - previousOpenAt) / (24 * 60 * 60 * 1000)).floor()
        : -1;

    return [
      _SystemHealthItem(
        level: reminderEnabled
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.warning,
        icon: Icons.notifications_active_rounded,
        title: reminderEnabled
            ? strings.t("Đã cài đặt nhắc nhở")
            : strings.t("Chưa cài đặt nhắc nhở"),
        message: reminderEnabled
            ? strings.t("Ứng dụng sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.")
            : strings.t(
                "Nên có ít nhất một nhắc nhở để không quên kiểm tra nhà.",
              ),
      ),
      _SystemHealthItem(
        level: alarmScheduleEnabled
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.warning,
        icon: Icons.crisis_alert_rounded,
        title: alarmScheduleEnabled
            ? strings.t("Đã cài lịch báo động")
            : strings.t("Chưa cài lịch báo động"),
        message: alarmScheduleEnabled
            ? strings.t(
                "Nhà đã có lịch báo động hoặc lịch cảnh báo theo thiết bị.",
              )
            : strings.t(
                "Nên đặt lịch báo động cho thời gian ngủ hoặc vắng nhà.",
              ),
      ),
      _SystemHealthItem(
        level: emergencyTotal > 0
            ? hasSmoke && hasSos
                  ? _SystemHealthLevel.ok
                  : _SystemHealthLevel.info
            : _SystemHealthLevel.warning,
        icon: Icons.emergency_rounded,
        title: emergencyTotal > 0
            ? strings.t("Đã có thiết bị khẩn cấp")
            : strings.t("Chưa có thiết bị khẩn cấp"),
        message: emergencyTotal > 0
            ? strings.emergencyDeviceRecommendationText(emergencyTotal)
            : strings.t(
                "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.",
              ),
      ),
      _SystemHealthItem(
        level: !autoAwayEnabled
            ? _SystemHealthLevel.info
            : monitoringEligible &&
                  locationPermission == LocationPermission.always
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.directions_walk_rounded,
        title: !autoAwayEnabled
            ? strings.t("Auto rời khỏi nhà chưa bật")
            : monitoringEligible
            ? strings.t("Auto rời khỏi nhà đã sẵn sàng")
            : strings.t("Auto rời khỏi nhà chưa ổn"),
        message: !autoAwayEnabled
            ? strings.t(
                "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.",
              )
            : monitoringEligible
            ? strings.t("Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.")
            : strings.t(
                "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.",
              ),
      ),
      _SystemHealthItem(
        level: securityMode == 'armed'
            ? _SystemHealthLevel.ok
            : securityMode == 'unprotected'
            ? _SystemHealthLevel.warning
            : _SystemHealthLevel.info,
        icon: securityMode == 'unprotected'
            ? Icons.shield_outlined
            : Icons.shield_rounded,
        title: _securityModeTitle(
          strings: strings,
          securityMode: securityMode,
          securityModeSource: securityModeSource,
        ),
        message: _securityModeMessage(
          strings: strings,
          securityMode: securityMode,
          securityModeSource: securityModeSource,
        ),
      ),
      _SystemHealthItem(
        level: previousOpenAt <= 0
            ? _SystemHealthLevel.info
            : daysSincePreviousOpen >= 3
            ? _SystemHealthLevel.warning
            : _SystemHealthLevel.ok,
        icon: Icons.event_available_rounded,
        title: previousOpenAt <= 0
            ? strings.t("Đang ghi nhận tần suất vào ứng dụng")
            : daysSincePreviousOpen >= 3
            ? strings.t("Đã lâu chưa vào ứng dụng kiểm tra")
            : strings.t("Tần suất vào ứng dụng ổn"),
        message: previousOpenAt <= 0
            ? strings.t(
                "Sau vài lần sử dụng, MaiYen sẽ đánh giá thói quen kiểm tra ứng dụng tốt hơn.",
              )
            : daysSincePreviousOpen >= 3
            ? strings.t(
                "Bạn nên mở ứng dụng định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.",
              )
            : strings.t("Bạn đã mở ứng dụng gần đây để kiểm tra trạng thái."),
      ),
    ];
  }

  static bool _hasEnabledSchedule(dynamic raw) {
    if (raw is List) {
      return raw.any((item) => safeMap(item)['enabled'] == true);
    }

    if (raw is Map) {
      return raw.values.any((item) => safeMap(item)['enabled'] == true);
    }

    return false;
  }

  static bool _hasEnabledDeviceAlarm(Map<String, dynamic> devices) {
    for (final rawDevice in devices.values) {
      final device = safeMap(rawDevice);
      if (_hasEnabledSchedule(device['alarmSchedules']) ||
          safeMap(device['alarm'])['enabled'] == true) {
        return true;
      }
    }

    return false;
  }

  static bool _hasEnabledCustomDeviceAlarm(
    Map<String, dynamic> customDevices, {
    required String legacyAlarmMode,
  }) {
    for (final rawDevice in customDevices.values) {
      final customDevice = safeMap(rawDevice);
      final preferences = DevicePersonalAlarmPreferences.fromCustomDevice(
        customDevice: customDevice,
        legacyFullscreenEnabled: true,
      );

      // Khi theo lịch chung, lịch đã được tính ở homeAlarmScheduleEnabled.
      // Không đọc lịch cá nhân cũ để tránh báo trùng hoặc sai trạng thái.
      if (preferences.followHomeSchedule) {
        continue;
      }

      final alarms = normalizeEffectivePersonalAlarmSchedules(
        customDevice: customDevice,
        legacyAlarmMode: legacyAlarmMode,
      );

      if (hasEnabledDeviceAlarmSchedules(alarms)) {
        return true;
      }
    }

    return false;
  }

  static Map<String, int> _emergencyDeviceCounts(Map<String, dynamic> devices) {
    final result = <String, int>{};
    const emergencyTypes = {
      'smoke',
      'sos',
      'heat',
      'carbon_monoxide',
      'gas',
      'water_leak',
      'flood',
    };

    for (final rawDevice in devices.values) {
      final device = safeMap(rawDevice);
      final type = device['type']?.toString().trim().toLowerCase() ?? '';

      if (!emergencyTypes.contains(type)) {
        continue;
      }

      result[type] = (result[type] ?? 0) + 1;
    }

    return result;
  }

  static String _securityModeTitle({
    required AppStrings strings,
    required String securityMode,
    required String securityModeSource,
  }) {
    if (securityMode == 'unprotected') {
      return strings.t("Không bảo vệ đang bật");
    }

    if (securityMode != 'armed') {
      return strings.t("Bảo vệ đang tắt");
    }

    if (securityModeSource == 'auto_away') {
      return strings.t("Bảo vệ tự động đang bật");
    }

    return strings.t("Bảo vệ thủ công đang bật");
  }

  static String _securityModeMessage({
    required AppStrings strings,
    required String securityMode,
    required String securityModeSource,
  }) {
    if (securityMode == 'unprotected') {
      return strings.t(
        "Toàn bộ báo động của nhà đang tắt; hệ thống chỉ gửi thông báo.",
      );
    }

    if (securityMode != 'armed') {
      return strings.t("Nhà đang ở chế độ dùng bình thường.");
    }

    if (securityModeSource == 'auto_away') {
      return strings.t("MaiYen tự bật Bảo vệ vì bạn đã rời khỏi nhà.");
    }

    return strings.t("Bạn hoặc thành viên đã chủ động bật Bảo vệ.");
  }
}

class _SystemHealthSection extends StatelessWidget {
  const _SystemHealthSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_SystemHealthItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: MaiYenColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MaiYenColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: MaiYenColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _SystemHealthTile(item: item)),
        ],
      ),
    );
  }
}

class _SystemHealthTile extends StatelessWidget {
  const _SystemHealthTile({required this.item});

  final _SystemHealthItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.statusIcon, size: 18, color: item.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 14, color: item.color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.2,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: MaiYenColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
                    color: MaiYenColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
