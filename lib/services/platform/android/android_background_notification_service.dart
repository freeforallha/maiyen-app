import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../firebase_options.dart';
import '../../../localization/app_strings.dart';
import '../../notification_service.dart';
import 'android_notification_config.dart';

const String _languageStorageKey = 'safehome_language_code';
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
};

String? _supportedLanguageCode(String? code) {
  final cleanCode = code?.trim().toLowerCase() ?? '';

  if (_supportedLanguageCodes.contains(cleanCode)) {
    return cleanCode;
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
    await Future.wait([
      localNotif.cancel(NotificationService.emergencyNotificationId),
      localNotif.cancel(NotificationService.alarmNotificationId),
    ]);
    return;
  }

  if (type == 'schedule_notification') {
    await _showBackgroundScheduleNotification(message.data);
    return;
  }

  if (type == 'emergency_notification' ||
      type == 'alarm_detected' ||
      type == 'alarm') {
    await _showBackgroundPriorityAlarm(message.data);
    return;
  }

  if (type == 'alarm_siren') {
    await _showBackgroundFullscreenAlarm(message.data, message.notification);
  }
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
      : 'SafeHome';

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

  final payload =
      'home_chat::${jsonEncode({'homeId': homeId, 'homeName': homeName, 'ownerUid': data['ownerUid']?.toString() ?? '', 'messageId': data['messageId']?.toString() ?? ''})}';

  final notificationId = _chatNotificationId(homeId);

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

int _chatNotificationId(String homeId) {
  var hash = 0;

  for (final codeUnit in homeId.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }

  return 200000 + (hash % 700000);
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
