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
            text: strings.choose(
              vi: 'Hệ thống: Đang kiểm tra...',
              en: 'System: Checking...',
              zh: '系统：正在检查...',
              ko: '시스템: 확인 중...',
              ja: 'システム: 確認中...',
            ),
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
                          strings.choose(
                            vi: 'Hệ thống SafeHome',
                            en: 'SafeHome System',
                            zh: 'SafeHome 系统',
                            ko: 'SafeHome 시스템',
                            ja: 'SafeHome システム',
                          ),
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
                      strings.choose(
                        vi: 'Kiểm tra điện thoại và cách bạn đang dùng app.',
                        en: 'Checks your phone and how you use the app.',
                        zh: '检查你的手机以及你使用应用的方式。',
                        ko: '휴대폰과 앱 사용 상태를 확인합니다.',
                        ja: 'スマートフォンとアプリの使い方を確認します。',
                      ),
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
                            title: strings.choose(
                              vi: 'Thiết bị của bạn',
                              en: 'Your device',
                              zh: '你的设备',
                              ko: '내 기기',
                              ja: 'あなたのデバイス',
                            ),
                            icon: Icons.phone_android_rounded,
                            items: data.deviceItems,
                          ),
                          const SizedBox(height: 12),
                          _SystemHealthSection(
                            title: strings.choose(
                              vi: 'Cách bạn đang dùng app',
                              en: 'How you use the app',
                              zh: '你使用应用的方式',
                              ko: '앱 사용 방식',
                              ja: 'アプリの使い方',
                            ),
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
        summaryText: strings.choose(
          vi: 'Hệ thống: Có thể bỏ lỡ cảnh báo',
          en: 'System: Alerts may be missed',
          zh: '系统：可能会错过警报',
          ko: '시스템: 알림을 놓칠 수 있음',
          ja: 'システム: 警報を見逃す可能性',
        ),
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
      summaryText: strings.choose(
        vi: 'Hệ thống: Sẵn sàng',
        en: 'System: Ready',
        zh: '系统：已就绪',
        ko: '시스템: 준비됨',
        ja: 'システム: 準備完了',
      ),
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
            ? strings.choose(
          vi: 'Đã bật thông báo',
          en: 'Notifications are enabled',
          zh: '已开启通知',
          ko: '알림이 켜져 있음',
          ja: '通知が有効です',
        )
            : strings.choose(
          vi: 'Chưa bật thông báo',
          en: 'Notifications are not enabled',
          zh: '尚未开启通知',
          ko: '알림이 꺼져 있음',
          ja: '通知が有効ではありません',
        ),
        message: notificationOk
            ? strings.choose(
          vi: 'Điện thoại có thể nhận thông báo SafeHome.',
          en: 'This phone can receive SafeHome notifications.',
          zh: '此手机可以接收 SafeHome 通知。',
          ko: '이 휴대폰은 SafeHome 알림을 받을 수 있습니다.',
          ja: 'この端末は SafeHome の通知を受け取れます。',
        )
            : strings.choose(
          vi: 'Cảnh báo có thể không hiển thị nếu thông báo bị tắt.',
          en: 'Alerts may not appear if notifications are disabled.',
          zh: '如果通知被关闭，警报可能不会显示。',
          ko: '알림이 꺼져 있으면 경고가 표시되지 않을 수 있습니다.',
          ja: '通知が無効だと警報が表示されない可能性があります。',
        ),
      ),
      _SystemHealthItem(
        level: isAndroid && notificationOk
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.info,
        icon: Icons.open_in_full_rounded,
        title: isAndroid
            ? strings.choose(
          vi: 'Cảnh báo toàn màn hình',
          en: 'Full-screen alerts',
          zh: '全屏警报',
          ko: '전체 화면 경고',
          ja: '全画面アラート',
        )
            : strings.choose(
          vi: 'Cảnh báo trên iOS',
          en: 'Alerts on iOS',
          zh: 'iOS 上的警报',
          ko: 'iOS 알림',
          ja: 'iOS の警報',
        ),
        message: isAndroid
            ? strings.choose(
          vi: 'Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.',
          en: 'Android uses full-screen alerts; allow it in settings if the phone blocks it.',
          zh: 'Android 使用全屏警报；如果手机阻止，请在设置中允许。',
          ko: 'Android는 전체 화면 경고를 사용합니다. 휴대폰이 차단하면 설정에서 허용하세요.',
          ja: 'Android は全画面警報を使います。端末がブロックする場合は設定で許可してください。',
        )
            : strings.choose(
          vi: 'iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.',
          en: 'iOS does not open full-screen like Android; the app uses system notifications and sound.',
          zh: 'iOS 不像 Android 那样全屏打开；应用使用系统通知和声音。',
          ko: 'iOS는 Android처럼 전체 화면으로 열리지 않으며 시스템 알림과 소리를 사용합니다.',
          ja: 'iOS は Android のように全画面表示せず、システム通知と音を使います。',
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
            ? strings.choose(
          vi: 'Đã cấp vị trí luôn luôn',
          en: 'Always location is allowed',
          zh: '已允许始终定位',
          ko: '항상 위치 권한 허용됨',
          ja: '常に位置情報が許可されています',
        )
            : strings.choose(
          vi: 'Chưa cấp vị trí luôn luôn',
          en: 'Always location is not allowed',
          zh: '尚未允许始终定位',
          ko: '항상 위치 권한이 허용되지 않음',
          ja: '常に位置情報が許可されていません',
        ),
        message: !autoAwayEnabled
            ? strings.choose(
          vi: 'Chỉ cần quyền này khi dùng Auto rời khỏi nhà.',
          en: 'This is only required when using Auto Away.',
          zh: '只有使用自动离家时才需要此权限。',
          ko: '자동 외출 기능을 사용할 때만 필요합니다.',
          ja: '自動外出を使う場合のみ必要です。',
        )
            : !locationServiceEnabled
            ? strings.choose(
          vi: 'Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.',
          en: 'Location service is off, so Auto Away may not work reliably.',
          zh: '定位服务已关闭，因此自动离家可能不稳定。',
          ko: '위치 서비스가 꺼져 있어 자동 외출이 안정적으로 작동하지 않을 수 있습니다.',
          ja: '位置情報サービスがオフのため、自動外出が安定しない可能性があります。',
        )
            : locationDenied
            ? strings.choose(
          vi: 'Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.',
          en: 'Location permission is required for Auto Away.',
          zh: '自动离家需要定位权限。',
          ko: '자동 외출에는 위치 권한이 필요합니다.',
          ja: '自動外出には位置情報の許可が必要です。',
        )
            : strings.choose(
          vi: 'Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.',
          en: 'Auto Away needs Always location to work reliably.',
          zh: '自动离家需要始终定位才能稳定运行。',
          ko: '자동 외출이 안정적으로 작동하려면 항상 위치 권한이 필요합니다.',
          ja: '自動外出を安定して動かすには常に位置情報が必要です。',
        ),
      ),
      if (isAndroid)
        _SystemHealthItem(
          level: batteryUnrestricted
              ? _SystemHealthLevel.ok
              : _SystemHealthLevel.warning,
          icon: Icons.battery_saver_rounded,
          title: batteryUnrestricted
              ? strings.choose(
            vi: 'Tối ưu pin không chặn app',
            en: 'Battery optimization is not blocking the app',
            zh: '电池优化未阻止应用',
            ko: '배터리 최적화가 앱을 차단하지 않음',
            ja: 'バッテリー最適化はアプリを妨げていません',
          )
              : strings.choose(
            vi: 'Chưa tắt tối ưu pin',
            en: 'Battery optimization is still enabled',
            zh: '尚未关闭电池优化',
            ko: '배터리 최적화가 아직 켜져 있음',
            ja: 'バッテリー最適化がまだ有効です',
          ),
          message: batteryUnrestricted
              ? strings.choose(
            vi: 'Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.',
            en: 'The phone is less likely to delay SafeHome alerts.',
            zh: '手机较少可能延迟 SafeHome 警报。',
            ko: '휴대폰이 SafeHome 경고를 지연할 가능성이 낮습니다.',
            ja: '端末が SafeHome の警報を遅らせる可能性は低いです。',
          )
              : strings.choose(
            vi: 'Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.',
            en: 'Some Android phones may delay alerts while battery optimization is on.',
            zh: '某些 Android 手机在开启电池优化时可能延迟警报。',
            ko: '일부 Android 휴대폰은 배터리 최적화가 켜져 있으면 경고가 지연될 수 있습니다.',
            ja: '一部の Android 端末では、バッテリー最適化が有効だと警報が遅れる場合があります。',
          ),
        ),
      if (isAndroid)
        _SystemHealthItem(
          level: !backgroundRestricted && autoStartConfirmed
              ? _SystemHealthLevel.ok
              : _SystemHealthLevel.warning,
          icon: Icons.run_circle_rounded,
          title: !backgroundRestricted && autoStartConfirmed
              ? strings.choose(
            vi: 'Chạy nền ổn định',
            en: 'Background use looks stable',
            zh: '后台运行看起来稳定',
            ko: '백그라운드 실행이 안정적입니다',
            ja: 'バックグラウンド動作は安定しています',
          )
              : strings.choose(
            vi: 'Cần kiểm tra chạy nền / tự khởi động',
            en: 'Check background use / auto-start',
            zh: '请检查后台运行 / 自启动',
            ko: '백그라운드 실행 / 자동 시작 확인 필요',
            ja: 'バックグラウンド動作 / 自動起動を確認してください',
          ),
          message: !backgroundRestricted && autoStartConfirmed
              ? strings.choose(
            vi: 'Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.',
            en: 'The device has confirmed the important background conditions.',
            zh: '设备已确认重要的后台条件。',
            ko: '기기가 중요한 백그라운드 조건을 확인했습니다.',
            ja: 'デバイスは重要なバックグラウンド条件を確認済みです。',
          )
              : strings.choose(
            vi: 'Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.',
            en: 'Check background permission and auto-start so alerts are not delayed.',
            zh: '请检查后台权限和自启动，避免警报延迟。',
            ko: '경고가 지연되지 않도록 백그라운드 권한과 자동 시작을 확인하세요.',
            ja: '警報が遅れないようにバックグラウンド権限と自動起動を確認してください。',
          ),
        ),
      if (isIos)
        _SystemHealthItem(
          level: _SystemHealthLevel.info,
          icon: Icons.phone_iphone_rounded,
          title: strings.choose(
            vi: 'Cơ chế iOS',
            en: 'iOS behavior',
            zh: 'iOS 机制',
            ko: 'iOS 동작 방식',
            ja: 'iOS の仕組み',
          ),
          message: strings.choose(
            vi: 'iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.',
            en: 'iOS controls background use more strictly than Android; keep notifications and Always location on if using Auto Away.',
            zh: 'iOS 对后台运行的管理比 Android 更严格；使用自动离家时请保持通知和始终定位开启。',
            ko: 'iOS는 Android보다 백그라운드를 더 엄격하게 관리합니다. 자동 외출을 사용하면 알림과 항상 위치 권한을 켜 두세요.',
            ja: 'iOS は Android よりバックグラウンド動作を厳しく管理します。自動外出を使う場合は通知と常に位置情報をオンにしてください。',
          ),
        ),
      _SystemHealthItem(
        level: fcmToken.isNotEmpty && notificationOk
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.cloud_done_rounded,
        title: fcmToken.isNotEmpty
            ? strings.choose(
          vi: 'Thiết bị nhận cảnh báo bình thường',
          en: 'This device can receive alerts',
          zh: '此设备可以接收警报',
          ko: '이 기기는 경고를 받을 수 있습니다',
          ja: 'このデバイスは警報を受信できます',
        )
            : strings.choose(
          vi: 'Thiết bị chưa đăng ký nhận cảnh báo',
          en: 'This device is not registered for alerts',
          zh: '此设备尚未注册接收警报',
          ko: '이 기기는 경고 수신 등록이 되어 있지 않습니다',
          ja: 'このデバイスは警報受信に登録されていません',
        ),
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
            : strings.choose(
          vi: 'Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.',
          en: 'Reopen the app or sign in again if this device does not receive alerts.',
          zh: '如果此设备收不到警报，请重新打开应用或重新登录。',
          ko: '이 기기가 경고를 받지 못하면 앱을 다시 열거나 다시 로그인하세요.',
          ja: 'このデバイスが警報を受信しない場合は、アプリを開き直すか再ログインしてください。',
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
            ? strings.choose(
          vi: 'Đã setup Reminder',
          en: 'Reminder is set up',
          zh: '已设置 Reminder',
          ko: 'Reminder 설정됨',
          ja: 'Reminder 設定済み',
        )
            : strings.choose(
          vi: 'Chưa setup Reminder',
          en: 'Reminder is not set up',
          zh: '尚未设置 Reminder',
          ko: 'Reminder가 설정되지 않음',
          ja: 'Reminder が未設定です',
        ),
        message: reminderEnabled
            ? strings.choose(
          vi: 'App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.',
          en: 'The app will remind you to check your home on schedule.',
          zh: '应用会按计划提醒你检查家庭。',
          ko: '앱이 설정된 일정에 따라 집 확인을 알려줍니다.',
          ja: 'アプリが設定したスケジュールで家の確認を促します。',
        )
            : strings.choose(
          vi: 'Nên có ít nhất một Reminder để không quên kiểm tra nhà.',
          en: 'Set at least one Reminder so you do not forget to check your home.',
          zh: '建议至少设置一个 Reminder，避免忘记检查家庭。',
          ko: '집 확인을 잊지 않도록 최소 하나의 Reminder를 설정하세요.',
          ja: '家の確認を忘れないように少なくとも 1 つ Reminder を設定してください。',
        ),
      ),
      _SystemHealthItem(
        level: alarmScheduleEnabled
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.warning,
        icon: Icons.crisis_alert_rounded,
        title: alarmScheduleEnabled
            ? strings.choose(
          vi: 'Đã set lịch Alarm',
          en: 'Alarm schedule is set',
          zh: '已设置 Alarm 时间表',
          ko: 'Alarm 일정 설정됨',
          ja: 'Alarm スケジュール設定済み',
        )
            : strings.choose(
          vi: 'Chưa set lịch Alarm',
          en: 'Alarm schedule is not set',
          zh: '尚未设置 Alarm 时间表',
          ko: 'Alarm 일정이 설정되지 않음',
          ja: 'Alarm スケジュールが未設定です',
        ),
        message: alarmScheduleEnabled
            ? strings.choose(
          vi: 'Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.',
          en: 'This home has an Alarm schedule or device-level alert schedule.',
          zh: '此家庭已有 Alarm 时间表或设备级警报时间表。',
          ko: '이 집에는 Alarm 일정 또는 기기별 경고 일정이 있습니다.',
          ja: 'この家には Alarm スケジュールまたはデバイス別警報スケジュールがあります。',
        )
            : strings.choose(
          vi: 'Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.',
          en: 'Set an Alarm schedule for sleeping time or when you are away.',
          zh: '建议为睡眠时间或外出时设置 Alarm 时间表。',
          ko: '수면 시간이나 외출 시간에 Alarm 일정을 설정하세요.',
          ja: '就寝中や外出時のために Alarm スケジュールを設定してください。',
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
            ? strings.choose(
          vi: 'Đã có thiết bị khẩn cấp',
          en: 'Emergency devices are added',
          zh: '已添加紧急设备',
          ko: '긴급 기기가 추가됨',
          ja: '緊急デバイスが追加されています',
        )
            : strings.choose(
          vi: 'Chưa có thiết bị khẩn cấp',
          en: 'No emergency device yet',
          zh: '尚无紧急设备',
          ko: '긴급 기기 없음',
          ja: '緊急デバイスがありません',
        ),
        message: emergencyTotal > 0
            ? strings.choose(
          vi: 'Hiện có $emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.',
          en: '$emergencyTotal emergency devices found. Recommended minimum: smoke sensor and SOS.',
          zh: '已有 $emergencyTotal 个紧急设备。建议至少配置：烟雾传感器和 SOS。',
          ko: '긴급 기기 $emergencyTotal개가 있습니다. 권장 최소 구성: 연기 감지기와 SOS.',
          ja: '$emergencyTotal 個の緊急デバイスがあります。推奨最小構成: 煙センサーと SOS。',
        )
            : strings.choose(
          vi: 'Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.',
          en: 'Add a smoke sensor, SOS, or emergency device suitable for your home.',
          zh: '建议添加烟雾传感器、SOS 或适合家庭的紧急设备。',
          ko: '집에 맞는 연기 감지기, SOS 또는 긴급 기기를 추가하세요.',
          ja: '煙センサー、SOS、または家に合った緊急デバイスを追加してください。',
        ),
      ),
      _SystemHealthItem(
        level: !autoAwayEnabled
            ? _SystemHealthLevel.info
            : monitoringEligible && locationPermission == LocationPermission.always
            ? _SystemHealthLevel.ok
            : _SystemHealthLevel.danger,
        icon: Icons.directions_walk_rounded,
        title: !autoAwayEnabled
            ? strings.choose(
          vi: 'Auto rời khỏi nhà chưa bật',
          en: 'Auto Away is not enabled',
          zh: '自动离家未开启',
          ko: '자동 외출이 꺼져 있음',
          ja: '自動外出は有効ではありません',
        )
            : monitoringEligible
            ? strings.choose(
          vi: 'Auto rời khỏi nhà đã sẵn sàng',
          en: 'Auto Away is ready',
          zh: '自动离家已就绪',
          ko: '자동 외출 준비됨',
          ja: '自動外出は準備完了です',
        )
            : strings.choose(
          vi: 'Auto rời khỏi nhà chưa ổn',
          en: 'Auto Away is not ready',
          zh: '自动离家尚未就绪',
          ko: '자동 외출이 준비되지 않음',
          ja: '自動外出は準備できていません',
        ),
        message: !autoAwayEnabled
            ? strings.choose(
          vi: 'Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.',
          en: 'Enable it if you want Guard mode to turn on automatically when you leave.',
          zh: '如果希望离家时自动开启布防，可以启用此功能。',
          ko: '외출 시 보호 모드를 자동으로 켜려면 활성화하세요.',
          ja: '外出時に自動で警戒モードにしたい場合は有効にしてください。',
        )
            : monitoringEligible
            ? strings.choose(
          vi: 'Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.',
          en: 'This device meets the requirements for Auto Away.',
          zh: '此设备满足自动离家的运行条件。',
          ko: '이 기기는 자동 외출에 필요한 조건을 충족합니다.',
          ja: 'このデバイスは自動外出の条件を満たしています。',
        )
            : strings.choose(
          vi: 'Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.',
          en: 'Check Always location permission and background conditions.',
          zh: '请检查始终定位权限和后台条件。',
          ko: '항상 위치 권한과 백그라운드 조건을 확인하세요.',
          ja: '常に位置情報の許可とバックグラウンド条件を確認してください。',
        ),
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
            ? strings.choose(
          vi: 'Đang ghi nhận tần suất vào app',
          en: 'App check frequency is being recorded',
          zh: '正在记录应用检查频率',
          ko: '앱 확인 빈도를 기록 중',
          ja: 'アプリ確認頻度を記録中',
        )
            : daysSincePreviousOpen >= 3
            ? strings.choose(
          vi: 'Đã lâu chưa vào app kiểm tra',
          en: 'It has been a while since the last app check',
          zh: '距离上次打开应用检查已有一段时间',
          ko: '앱을 확인한 지 오래되었습니다',
          ja: 'アプリ確認から時間が経っています',
        )
            : strings.choose(
          vi: 'Tần suất vào app ổn',
          en: 'App check frequency looks good',
          zh: '应用检查频率良好',
          ko: '앱 확인 빈도가 양호합니다',
          ja: 'アプリ確認頻度は良好です',
        ),
        message: previousOpenAt <= 0
            ? strings.choose(
          vi: 'Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.',
          en: 'After a few sessions, SafeHome can evaluate your app-check habit better.',
          zh: '使用几次后，SafeHome 可以更好地评估你的应用检查习惯。',
          ko: '몇 번 사용한 후 SafeHome이 앱 확인 습관을 더 잘 평가할 수 있습니다.',
          ja: '数回使用すると、SafeHome がアプリ確認習慣をより正確に評価できます。',
        )
            : daysSincePreviousOpen >= 3
            ? strings.choose(
          vi: 'Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.',
          en: 'Open the app regularly to review permissions, schedules, and unread alerts.',
          zh: '建议定期打开应用检查权限、时间表和未读警报。',
          ko: '권한, 일정, 읽지 않은 경고를 확인하기 위해 앱을 정기적으로 여세요.',
          ja: '権限、スケジュール、未読警報を確認するため定期的にアプリを開いてください。',
        )
            : strings.choose(
          vi: 'Bạn đã mở app gần đây để kiểm tra trạng thái.',
          en: 'You have opened the app recently to check status.',
          zh: '你最近已打开应用检查状态。',
          ko: '최근 앱을 열어 상태를 확인했습니다.',
          ja: '最近アプリを開いて状態を確認しています。',
        ),
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
      return strings.choose(
        vi: 'Bảo vệ đang tắt',
        en: 'Guard mode is off',
        zh: '布防已关闭',
        ko: '보호 모드 꺼짐',
        ja: '警戒モードはオフです',
      );
    }

    if (securityModeSource == 'auto_away') {
      return strings.choose(
        vi: 'Bảo vệ tự động đang bật',
        en: 'Auto Guard is on',
        zh: '自动布防已开启',
        ko: '자동 보호가 켜져 있음',
        ja: '自動警戒がオンです',
      );
    }

    return strings.choose(
      vi: 'Bảo vệ thủ công đang bật',
      en: 'Manual Guard is on',
      zh: '手动布防已开启',
      ko: '수동 보호가 켜져 있음',
      ja: '手動警戒がオンです',
    );
  }

  static String _securityModeMessage({
    required AppStrings strings,
    required String securityMode,
    required String securityModeSource,
  }) {
    if (securityMode != 'armed') {
      return strings.choose(
        vi: 'Nhà đang ở chế độ dùng bình thường.',
        en: 'This home is currently in normal use.',
        zh: '此家庭当前处于普通使用模式。',
        ko: '이 집은 현재 일반 사용 모드입니다.',
        ja: 'この家は現在通常モードです。',
      );
    }

    if (securityModeSource == 'auto_away') {
      return strings.choose(
        vi: 'SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.',
        en: 'SafeHome turned on Guard automatically because you left home.',
        zh: '由于你已离家，SafeHome 已自动开启布防。',
        ko: '집을 떠났기 때문에 SafeHome이 자동으로 보호를 켰습니다.',
        ja: '外出したため SafeHome が自動で警戒をオンにしました。',
      );
    }

    return strings.choose(
      vi: 'Bạn hoặc thành viên đã chủ động bật Bảo vệ.',
      en: 'You or a member manually turned on Guard.',
      zh: '你或成员已手动开启布防。',
      ko: '사용자 또는 구성원이 수동으로 보호를 켰습니다.',
      ja: 'あなたまたはメンバーが手動で警戒をオンにしました。',
    );
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
