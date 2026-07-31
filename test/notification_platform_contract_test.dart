import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/localization/app_strings.dart';
import 'package:maiyen_app/services/notification_service.dart';
import 'package:maiyen_app/services/platform/android/android_notification_config.dart';
import 'package:maiyen_app/services/platform/ios/ios_notification_config.dart';

void main() {
  final strings = AppStrings.fromLocale(const Locale('en'));

  group('notification id contract', () {
    test('fixed alarm and reminder ids remain in their reserved namespace', () {
      expect(NotificationService.emergencyNotificationId, 999997);
      expect(NotificationService.alarmNotificationId, 999999);

      final chatIds = {
        for (final homeId in [
          'home-a',
          'home-b',
          'home-with-unicode-vi',
          'home with spaces',
          'home/special?chars',
        ])
          NotificationService.homeChatNotificationId(homeId),
      };

      expect(chatIds, hasLength(5));
      expect(chatIds, everyElement(inInclusiveRange(200000, 899999)));
      expect(
        chatIds,
        isNot(contains(NotificationService.emergencyNotificationId)),
      );
      expect(chatIds, isNot(contains(NotificationService.alarmNotificationId)));
      expect(chatIds, isNot(contains(999998)));
    });
  });

  group('Android notification details contract', () {
    test('fullscreen alarm stays ongoing, audible, and fullscreen', () {
      final details = AndroidNotificationConfig.fullscreenAlarmDetails(
        title: 'SafeHome',
        body: 'Alarm',
        strings: strings,
      );

      expect(
        details.channelId,
        AndroidNotificationConfig.alarmFullscreenChannelId,
      );
      expect(details.fullScreenIntent, isTrue);
      expect(details.ongoing, isTrue);
      expect(details.autoCancel, isFalse);
      expect(details.playSound, isTrue);
      expect(details.category, AndroidNotificationCategory.alarm);
    });

    test('priority alarm is ongoing but does not request fullscreen', () {
      final details = AndroidNotificationConfig.priorityAlarmDetails(
        title: 'SafeHome',
        body: 'Alarm',
        strings: strings,
      );

      expect(
        details.channelId,
        AndroidNotificationConfig.emergencyPriorityChannelId,
      );
      expect(details.fullScreenIntent, isFalse);
      expect(details.ongoing, isTrue);
      expect(details.autoCancel, isFalse);
      expect(details.playSound, isTrue);
      expect(details.category, AndroidNotificationCategory.alarm);
    });

    test('reminder, chat, and sensor channels remain separated', () {
      final reminder = AndroidNotificationConfig.reminderDetails(
        title: 'SafeHome',
        body: 'Reminder',
        bigText: 'Reminder',
        strings: strings,
      );
      final chat = AndroidNotificationConfig.chatDetails(
        title: 'Chat',
        body: 'Message',
        strings: strings,
      );
      final sensor = AndroidNotificationConfig.sensorNotificationDetails(
        title: 'Sensor',
        body: 'Event',
        strings: strings,
      );

      expect(
        reminder.channelId,
        AndroidNotificationConfig.reminderPriorityChannelId,
      );
      expect(chat.channelId, AndroidNotificationConfig.chatChannelId);
      expect(
        sensor.channelId,
        AndroidNotificationConfig.sensorNotificationChannelId,
      );
      expect({
        reminder.channelId,
        chat.channelId,
        sensor.channelId,
      }, hasLength(3));
      expect(reminder.ongoing, isTrue);
      expect(sensor.autoCancel, isTrue);
    });
  });

  group('iOS notification details contract', () {
    test('critical alerts stay disabled by default without entitlement', () {
      expect(IosNotificationConfig.criticalAlertsEntitlementEnabled, isFalse);
      expect(
        IosNotificationConfig.initializationSettings.requestCriticalPermission,
        isFalse,
      );
    });

    test(
      'emergency alarm uses emergency category and time-sensitive level',
      () {
        final details = IosNotificationConfig.alarmDetails(
          data: {
            'eventCategory': 'emergency',
            'homeId': 'home/needs sanitizing',
          },
          playSound: true,
        );

        expect(
          details.categoryIdentifier,
          IosNotificationConfig.emergencyAlarmCategoryId,
        );
        expect(details.threadIdentifier, 'maiyen_alarm_home_needs_sanitizing');
        expect(details.presentSound, isTrue);
        expect(details.interruptionLevel, InterruptionLevel.timeSensitive);
      },
    );

    test(
      'security alarm, sensor, chat, and reminder categories stay distinct',
      () {
        final alarm = IosNotificationConfig.alarmDetails(
          data: {'eventCategory': 'security', 'homeId': 'home-a'},
          playSound: false,
        );
        final sensor = IosNotificationConfig.sensorDetails(
          data: {'homeId': 'home-a'},
        );
        final chat = IosNotificationConfig.chatDetails(homeId: 'home-a');

        expect(
          alarm.categoryIdentifier,
          IosNotificationConfig.securityAlarmCategoryId,
        );
        expect(alarm.presentSound, isFalse);
        expect(
          sensor.categoryIdentifier,
          IosNotificationConfig.sensorCategoryId,
        );
        expect(chat.categoryIdentifier, IosNotificationConfig.chatCategoryId);
        expect(
          IosNotificationConfig.reminderDetails.categoryIdentifier,
          IosNotificationConfig.reminderCategoryId,
        );
        expect({
          alarm.categoryIdentifier,
          sensor.categoryIdentifier,
          chat.categoryIdentifier,
          IosNotificationConfig.reminderDetails.categoryIdentifier,
        }, hasLength(4));
      },
    );
  });
}
