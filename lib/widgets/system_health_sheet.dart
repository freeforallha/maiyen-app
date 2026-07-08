import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/home_helper.dart';
import '../localization/app_strings.dart';
import '../safehome_theme.dart';
import '../services/system_usage_service.dart';

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
            color: SafeHomeColors.textSecondary,
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
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: color,
              ),
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

  await showModalBottomSheet<void>(
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
            color: SafeHomeColors.background,
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
                      color: SafeHomeColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.t("Hệ thống SafeHome"),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: SafeHomeColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        data?.summaryIcon ?? Icons.health_and_safety_rounded,
                        color: data?.summaryColor ?? SafeHomeColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.t("Kiểm tra điện thoại và cách bạn đang dùng app."),
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: SafeHomeColors.textSecondary,
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
                            title: strings.t("Cách bạn đang dùng app"),
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
        return SafeHomeColors.safe;
      case _SystemHealthLevel.info:
        return SafeHomeColors.info;
      case _SystemHealthLevel.warning:
        return SafeHomeColors.warning;
      case _SystemHealthLevel.danger:
        return SafeHomeColors.danger;
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
        summaryColor: SafeHomeColors.danger,
        summaryIcon: Icons.warning_rounded,
        deviceItems: deviceItems,
        usageItems: usageItems,
      );
    }

    if (warningCount > 0) {
      return _SystemHealthSnapshot(
        summaryText: strings.choose(
          vi: 'Hệ thống: Cần kiểm tra $issueCount mục',
          en: 'System: $issueCount items need checking',
          zh: '系统：需要检查 $issueCount 项',
          ko: '시스템: $issueCount개 항목 확인 필요',
          ja: 'システム: $issueCount 項目の確認が必要',
        ),
        summaryColor: SafeHomeColors.warning,
        summaryIcon: Icons.error_rounded,
        deviceItems: deviceItems,
        usageItems: usageItems,
      );
    }

    return _SystemHealthSnapshot(
      summaryText: strings.t("Hệ thống: Sẵn sàng"),
      summaryColor: SafeHomeColors.safe,
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
        notificationSettings.authorizationStatus == AuthorizationStatus.authorized ||
            notificationSettings.authorizationStatus ==
                AuthorizationStatus.provisional;
    final locationAlways = locationPermission == LocationPermission.always;
    final locationDenied = locationPermission == LocationPermission.denied ||
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
            ? strings.t("Điện thoại có thể nhận thông báo SafeHome.")
            : strings.t("Cảnh báo có thể không hiển thị nếu thông báo bị tắt."),
      ),
      _SystemHealthItem(
        level: isAndroid && notificationOk
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.info,
        icon: Icons.open_in_full_rounded,
        title: isAndroid
            ? strings.t("Cảnh báo toàn màn hình")
            : strings.t("Cảnh báo trên iOS"),
        message: isAndroid
            ? strings.t("Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.")
            : strings.t("iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống."),
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
            ? strings.t("Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.")
            : locationDenied
            ? strings.t("Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.")
            : strings.t("Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định."),
      ),
      if (isAndroid)
        _SystemHealthItem(
          level: batteryUnrestricted
              ? _SystemHealthLevel.ok
              : _SystemHealthLevel.warning,
          icon: Icons.battery_saver_rounded,
          title: batteryUnrestricted
              ? strings.t("Tối ưu pin không chặn app")
              : strings.t("Chưa tắt tối ưu pin"),
          message: batteryUnrestricted
              ? strings.t("Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.")
              : strings.t("Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật."),
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
              ? strings.t("Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.")
              : strings.t("Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ."),
        ),
      if (isIos)
        _SystemHealthItem(
          level: _SystemHealthLevel.info,
          icon: Icons.phone_iphone_rounded,
          title: strings.t("Cơ chế iOS"),
          message: strings.t("iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà."),
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
            ? strings.choose(
          vi: monitoringEligible || !autoAwayEnabled
              ? 'FCM token đã sẵn sàng trên điện thoại này.'
              : 'FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.',
          en: monitoringEligible || !autoAwayEnabled
              ? 'The FCM token is ready on this phone.'
              : 'The FCM token is ready, but Auto Away is missing a requirement.',
          zh: monitoringEligible || !autoAwayEnabled
              ? '此手机上的 FCM token 已准备好。'
              : 'FCM token 已准备好，但自动离家仍缺少条件。',
          ko: monitoringEligible || !autoAwayEnabled
              ? '이 휴대폰의 FCM 토큰이 준비되었습니다.'
              : 'FCM 토큰은 준비되었지만 자동 외출에 필요한 조건이 부족합니다.',
          ja: monitoringEligible || !autoAwayEnabled
              ? 'この端末の FCM トークンは準備済みです。'
              : 'FCM トークンは準備済みですが、自動外出に必要な条件が不足しています。',
        )
            : strings.t("Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo."),
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
    final customMode = customRules['mode']?.toString() == 'custom';
    final customNotifications = safeMap(customRules['notifications']);
    final customDevices = safeMap(customRules['devices']);
    final autoAway = safeMap(home['autoAway']);
    final autoAwayEnabled = autoAway['enabled'] == true;
    final monitoringEligible = presence['monitoringEligible'] == true;

    final reminderEnabled = customMode
        ? _hasEnabledSchedule(customNotifications['items'])
        : _hasEnabledSchedule(schedules['notifications']);
    final alarmScheduleEnabled =
        _hasEnabledSchedule(schedules['alarms']) || _hasEnabledDeviceAlarm(devices) || _hasEnabledCustomDeviceAlarm(customDevices);
    final emergencyCounts = _emergencyDeviceCounts(devices);
    final hasSmoke = (emergencyCounts['smoke'] ?? 0) > 0;
    final hasSos = (emergencyCounts['sos'] ?? 0) > 0;
    final emergencyTotal = emergencyCounts.values.fold<int>(0, (sum, value) => sum + value);
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
            ? strings.t("Đã setup Reminder")
            : strings.t("Chưa setup Reminder"),
        message: reminderEnabled
            ? strings.t("App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.")
            : strings.t("Nên có ít nhất một Reminder để không quên kiểm tra nhà."),
      ),
      _SystemHealthItem(
        level: alarmScheduleEnabled
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.warning,
        icon: Icons.crisis_alert_rounded,
        title: alarmScheduleEnabled
            ? strings.t("Đã set lịch Alarm")
            : strings.t("Chưa set lịch Alarm"),
        message: alarmScheduleEnabled
            ? strings.t("Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.")
            : strings.t("Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà."),
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
            ? strings.choose(
          vi: 'Hiện có $emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.',
          en: '$emergencyTotal emergency devices found. Recommended minimum: smoke sensor and SOS.',
          zh: '已有 $emergencyTotal 个紧急设备。建议至少配置：烟雾传感器和 SOS。',
          ko: '긴급 기기 $emergencyTotal개가 있습니다. 권장 최소 구성: 연기 감지기와 SOS.',
          ja: '$emergencyTotal 個の緊急デバイスがあります。推奨最小構成: 煙センサーと SOS。',
        )
            : strings.t("Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà."),
      ),
      _SystemHealthItem(
        level: !autoAwayEnabled
            ? _SystemHealthLevel.info
            : monitoringEligible && locationPermission == LocationPermission.always
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.directions_walk_rounded,
        title: !autoAwayEnabled
            ? strings.t("Auto rời khỏi nhà chưa bật")
            : monitoringEligible
            ? strings.t("Auto rời khỏi nhà đã sẵn sàng")
            : strings.t("Auto rời khỏi nhà chưa ổn"),
        message: !autoAwayEnabled
            ? strings.t("Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.")
            : monitoringEligible
            ? strings.t("Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.")
            : strings.t("Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền."),
      ),
      _SystemHealthItem(
        level: securityMode == 'armed'
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.info,
        icon: Icons.shield_rounded,
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
            ? strings.t("Đang ghi nhận tần suất vào app")
            : daysSincePreviousOpen >= 3
            ? strings.t("Đã lâu chưa vào app kiểm tra")
            : strings.t("Tần suất vào app ổn"),
        message: previousOpenAt <= 0
            ? strings.t("Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.")
            : daysSincePreviousOpen >= 3
            ? strings.t("Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.")
            : strings.t("Bạn đã mở app gần đây để kiểm tra trạng thái."),
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
      final alarm = safeMap(safeMap(rawDevice)['alarm']);

      if (alarm['enabled'] == true) {
        return true;
      }
    }

    return false;
  }

  static bool _hasEnabledCustomDeviceAlarm(Map<String, dynamic> customDevices) {
    for (final rawDevice in customDevices.values) {
      final alarm = safeMap(safeMap(rawDevice)['alarm']);

      if (alarm['enabled'] == true) {
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
    if (securityMode != 'armed') {
      return strings.t("Nhà đang ở chế độ dùng bình thường.");
    }

    if (securityModeSource == 'auto_away') {
      return strings.t("SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.");
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
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SafeHomeColors.border),
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
                  color: SafeHomeColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SafeHomeColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: SafeHomeColors.textPrimary,
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
                          color: SafeHomeColors.textPrimary,
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
                    color: SafeHomeColors.textSecondary,
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
