import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../firebase_options.dart';
import '../../../config/brand_config.dart';
import '../../../localization/app_strings.dart';
import '../../notification_service.dart';
import 'android_notification_config.dart';
import '../../../config/maiyen_identifiers.dart';

const String _languageStorageKey =
    MaiYenIdentifiers.languageStorageKey;
const Set<String> _supportedLanguageCodes = {
  'vi',
  'en',
  'zh',
  'ko',
  'ja',
  'de',
  'ru',
  'fr',
  'es',
  'id',
  'th',
  'ms',
  'fil',
  'km',
  'my',
  'lo',
  'ta',
  'pt',
  'tet',
  'it',
  'pl',
  'nl',
  'cs',
  'sk',
  'uk',
  'ro',
  'hu',
  'bg',
  'hr',
  'sr',
  'bs',
  'sl',
  'mk',
  'sq',
  'el',
  'tr',
  'sv',
  'da',
  'nb',
  'fi',
  'is',
  'et',
  'lv',
  'lt',
  'ga',
  'mt',
  'be',
  'lb',
  'ca',
  'cnr',
  'hy',
  'ka',
  'az',
};

String? _supportedLanguageCode(String? code) {
  final cleanCode = code?.trim().toLowerCase() ?? '';
  final normalizedCode = cleanCode == 'my_mm' || cleanCode == 'my-mm'
      ? 'my'
      : cleanCode;

  if (_supportedLanguageCodes.contains(normalizedCode)) {
    return normalizedCode;
  }

  return null;
}

Locale _localeForLanguageCode(String code) {
  switch (code) {
    case 'zh':
      return const Locale('zh', 'CN');
    case 'ko':
      return const Locale('ko', 'KR');
    case 'ja':
      return const Locale('ja', 'JP');
    case 'de':
      return const Locale('de', 'DE');
    case 'ru':
      return const Locale('ru', 'RU');
    case 'fr':
      return const Locale('fr', 'FR');
    case 'es':
      return const Locale('es', 'ES');
    case 'id':
      return const Locale('id', 'ID');
    case 'th':
      return const Locale('th', 'TH');
    case 'ms':
      return const Locale('ms', 'MY');
    case 'fil':
      return const Locale('fil', 'PH');
    case 'km':
      return const Locale('km', 'KH');
    case 'my':
      return const Locale('my', 'MM');
    case 'lo':
      return const Locale('lo');
    case 'ta':
      return const Locale('ta', 'SG');
    case 'pt':
      return const Locale('pt', 'TL');
    case 'tet':
      return const Locale('tet', 'TL');
    case 'it':
      return const Locale('it', 'IT');
    case 'pl':
      return const Locale('pl', 'PL');
    case 'nl':
      return const Locale('nl', 'NL');
    case 'cs':
      return const Locale('cs', 'CZ');
    case 'sk':
      return const Locale('sk', 'SK');
    case 'uk':
      return const Locale('uk', 'UA');
    case 'ro':
      return const Locale('ro', 'RO');
    case 'hu':
      return const Locale('hu', 'HU');
    case 'bg':
      return const Locale('bg', 'BG');
    case 'hr':
      return const Locale('hr', 'HR');
    case 'sr':
      return const Locale('sr', 'RS');
    case 'bs':
      return const Locale('bs', 'BA');
    case 'sl':
      return const Locale('sl', 'SI');
    case 'mk':
      return const Locale('mk', 'MK');
    case 'sq':
      return const Locale('sq', 'AL');
    case 'el':
      return const Locale('el', 'GR');
    case 'tr':
      return const Locale('tr', 'TR');
    case 'sv':
      return const Locale('sv', 'SE');
    case 'da':
      return const Locale('da', 'DK');
    case 'nb':
      return const Locale('nb', 'NO');
    case 'fi':
      return const Locale('fi', 'FI');
    case 'is':
      return const Locale('is', 'IS');
    case 'et':
      return const Locale('et', 'EE');
    case 'lv':
      return const Locale('lv', 'LV');
    case 'lt':
      return const Locale('lt', 'LT');
    case 'ga':
      return const Locale('ga', 'IE');
    case 'mt':
      return const Locale('mt', 'MT');
    case 'be':
      return const Locale('be', 'BY');
    case 'lb':
      return const Locale('lb', 'LU');
    case 'ca':
      return const Locale('ca', 'AD');
    case 'cnr':
      return const Locale('cnr', 'ME');
    case 'hy':
      return const Locale('hy', 'AM');
    case 'ka':
      return const Locale('ka', 'GE');
    case 'az':
      return const Locale('az', 'AZ');
    case 'en':
      return const Locale('en');
    case 'vi':
    default:
      return const Locale('vi');
  }
}

Future<AppStrings> _backgroundStrings() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = _supportedLanguageCode(
      preferences.getString(_languageStorageKey),
    );
    final systemCode = _supportedLanguageCode(
      PlatformDispatcher.instance.locale.languageCode,
    );
    final code = savedCode ?? systemCode ?? 'vi';

    return AppStrings.fromLocale(_localeForLanguageCode(code));
  } catch (_) {
    final systemCode =
        _supportedLanguageCode(
          PlatformDispatcher.instance.locale.languageCode,
        ) ??
        'vi';

    return AppStrings.fromLocale(_localeForLanguageCode(systemCode));
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await localNotif.initialize(
    const InitializationSettings(
      android: AndroidNotificationConfig.initializationSettings,
    ),
  );

  final strings = await _backgroundStrings();

  await AndroidNotificationConfig.createBackgroundChannels(
    localNotif,
    strings: strings,
  );

  final type = message.data['type']?.toString() ?? '';

  if (type == 'chat') {
    await _showBackgroundChatNotification(message.data);
    return;
  }

  if (type == 'alarm_resolved') {
    final hasRemainingActiveIncidents =
        message.data['hasRemainingActiveIncidents']?.toString() == 'true';

    if (!hasRemainingActiveIncidents) {
      await Future.wait([
        localNotif.cancel(NotificationService.emergencyNotificationId),
        localNotif.cancel(NotificationService.alarmNotificationId),
      ]);
    }

    return;
  }

  if (type == 'schedule_notification') {
    await _showBackgroundScheduleNotification(message.data);
    return;
  }

  if (type == 'emergency_notification' ||
      type == 'alarm_detected' ||
      type == 'alarm') {
    final validatedData =
        await NotificationService.validateIncomingAlarmData(
          message.data,
          updateLocalState: false,
        );

    if (validatedData == null) {
      // Bỏ qua payload cũ. Không hủy notification khác vì tài khoản có thể
      // vẫn còn một incident mới đang hoạt động với cùng notification ID.
      return;
    }

    await _showBackgroundPriorityAlarm(validatedData);
    return;
  }

  if (type == 'alarm_siren') {
    final alarmData = Map<String, dynamic>.from(message.data);

    if (!_shouldPresentFullscreenAlarmImmediately(alarmData)) {
      return;
    }

    // Fullscreen Alarm là đường khẩn cấp: không chờ một lượt đọc Firebase
    // trong background isolate. Việc chờ network tại đây có thể khiến Android
    // kết thúc handler trước khi local notification có fullScreenIntent được tạo.
    // Khi Activity mở, NotificationService vẫn xác minh incident với Firebase.
    await _showBackgroundFullscreenAlarm(
      alarmData,
      message.notification,
    );
  }
}

bool _shouldPresentFullscreenAlarmImmediately(
  Map<String, dynamic> data,
) {
  final status = data['incidentStatus']?.toString().trim().toLowerCase() ?? '';

  if (status.isNotEmpty && status != 'active') {
    return false;
  }

  final sentAt = int.tryParse(data['sentAt']?.toString() ?? '') ?? 0;

  if (sentAt > 0 &&
      DateTime.now().millisecondsSinceEpoch - sentAt >
          const Duration(minutes: 2).inMilliseconds) {
    return false;
  }

  return true;
}

Future<void> _showBackgroundPriorityAlarm(Map<String, dynamic> data) async {
  final strings = await _backgroundStrings();
  final title = NotificationService.localizedNotificationTitle(
    data['title']?.toString() ?? '',
    strings,
    strings.priorityAlarmNotificationTitle(),
  );

  final body = NotificationService.localizedAlarmBodyForData(data, strings);

  final payload = 'priority_alarm::${jsonEncode(data)}';

  await localNotif.cancel(NotificationService.emergencyNotificationId);

  await localNotif.show(
    NotificationService.emergencyNotificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.priorityAlarmDetails(
        title: title,
        body: body,
        strings: strings,
      ),
    ),
    payload: payload,
  );
}

Future<void> _showBackgroundFullscreenAlarm(
  Map<String, dynamic> data,
  RemoteNotification? notification,
) async {
  final strings = await _backgroundStrings();
  final title = NotificationService.localizedNotificationTitle(
    data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString()
        : notification?.title?.toString() ?? '',
    strings,
    strings.priorityAlarmNotificationTitle(),
  );
  final bodyData = Map<String, dynamic>.from(data);

  if (bodyData['body']?.toString().trim().isNotEmpty != true &&
      notification?.body?.toString().trim().isNotEmpty == true) {
    bodyData['body'] = notification!.body!.trim();
  }

  final body = NotificationService.localizedAlarmBodyForData(bodyData, strings);

  final payload = 'alarm_siren::${jsonEncode(data)}';

  await localNotif.cancel(NotificationService.emergencyNotificationId);
  await localNotif.cancel(NotificationService.alarmNotificationId);

  await localNotif.show(
    NotificationService.alarmNotificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.fullscreenAlarmDetails(
        title: title,
        body: body,
        strings: strings,
      ),
    ),
    payload: payload,
  );
}

Future<void> _showBackgroundScheduleNotification(
  Map<String, dynamic> data,
) async {
  final strings = await _backgroundStrings();
  final body = _buildScheduleBody(data, strings);

  final rawHomeTitle = data['title']?.toString().trim() ?? '';
  final homeTitle = rawHomeTitle == 'Nhà'
      ? strings.defaultHomeName()
      : rawHomeTitle.isNotEmpty
      ? rawHomeTitle
      : BrandConfig.appName;

  final isSafe =
      data['isSafe']?.toString() == 'true' ||
      data['isSafe']?.toString() == '1' ||
      data['isSafe']?.toString() == 'yes';

  final notificationTitle = strings.safetyReminderNotificationTitle(
    homeTitle: homeTitle,
    isSafe: isSafe,
  );

  await localNotif.cancel(999998);

  await localNotif.show(
    999998,
    notificationTitle,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.reminderDetails(
        title: notificationTitle,
        body: body,
        bigText: body,
        strings: strings,
      ),
    ),
    payload: 'open_home',
  );
}

Future<void> _showBackgroundChatNotification(Map<String, dynamic> data) async {
  final strings = await _backgroundStrings();
  final homeId = data['homeId']?.toString().trim() ?? '';

  if (homeId.isEmpty) {
    return;
  }

  final homeName = data['homeName']?.toString().trim() ?? '';

  final senderName = data['senderName']?.toString().trim() ?? '';

  final unreadCount = int.tryParse(data['unreadCount']?.toString() ?? '1') ?? 1;

  final rawTitle = data['title']?.toString().trim() ?? '';

  final rawBody = data['body']?.toString().trim() ?? '';

  final title = rawTitle.isNotEmpty
      ? NotificationService.localizedExactTextOrRaw(rawTitle, strings)
      : unreadCount > 1
      ? '${homeName.isNotEmpty ? homeName : "HomeChat"} · '
            '${strings.homeChatNewMessages(unreadCount)}'
      : homeName.isNotEmpty
      ? homeName
      : strings.homeChatTitle();

  final body = rawBody.isNotEmpty
      ? NotificationService.localizedExactTextOrRaw(rawBody, strings)
      : senderName.isNotEmpty
      ? strings.homeChatSenderMessage(senderName)
      : strings.homeChatNewMessage();

  final payload = NotificationService.homeChatPayload(
    homeId: homeId,
    homeName: homeName,
    ownerUid: data['ownerUid']?.toString() ?? '',
    messageId: data['messageId']?.toString() ?? '',
  );

  final notificationId = NotificationService.homeChatNotificationId(homeId);

  await localNotif.cancel(notificationId);

  await localNotif.show(
    notificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationConfig.chatDetails(
        title: title,
        body: body,
        strings: strings,
        tag: 'home_chat_$homeId',
      ),
    ),
    payload: payload,
  );
}

String _buildScheduleBody(Map<String, dynamic> data, AppStrings strings) {
  final isSafeText = data['isSafe']?.toString() ?? 'true';

  final isSafe =
      isSafeText == 'true' || isSafeText == '1' || isSafeText == 'yes';

  final reason = data['reason']?.toString().trim() ?? '';

  NotificationService.lastScheduleBody = strings.safetyReminderBody(
    isSafe: isSafe,
    reason: reason,
  );

  return NotificationService.lastScheduleBody;
}
