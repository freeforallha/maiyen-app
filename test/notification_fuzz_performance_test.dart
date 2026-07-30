import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/localization/app_strings.dart';
import 'package:maiyen_app/services/notification_service.dart';

void main() {
  final strings = AppStrings.fromLocale(const Locale('en'));

  setUp(() {
    NotificationService.markAlarmPageClosed();
    NotificationService.clearActiveAlarms();
  });

  tearDown(() {
    NotificationService.markAlarmPageClosed();
    NotificationService.clearActiveAlarms();
  });

  group('payload fuzzing', () {
    test('alarm body parser does not crash on malformed payload shapes', () {
      final fuzzValues = <Object?>[
        null,
        '',
        'not-json',
        '{broken',
        42,
        true,
        {'deviceName': 'Map device', 'reason': 'Door opened'},
        [
          {'deviceName': 'List device', 'reason': 'Motion detected'},
          'bad item',
          null,
        ],
        jsonEncode({'deviceName': 'Encoded map', 'reason': 'Smoke detected'}),
        jsonEncode([
          {'deviceName': 'Encoded list', 'reason': 'Gas leak detected'},
        ]),
      ];

      for (final value in fuzzValues) {
        final body = NotificationService.localizedAlarmBodyForData({
          'alarmItems': value,
          'alarmItemsJson': value,
          'homeName': null,
          'deviceName': '',
          'body': 'Fallback body',
          'timestamp': 999999999999999999,
          'incidentId': r'id-with-/\:"*?<>|',
        }, strings);

        expect(body, isNotEmpty);
      }
    });

    test('long unicode names and many incidents keep non-empty identities', () {
      final items = [
        for (var index = 0; index < 120; index++)
          {
            'incidentId': 'incident-$index-安全-vi-th',
            'homeId': 'home-${index % 25}',
            'homeName': 'Nhà rất dài ${'x' * 120} $index',
            'deviceId': 'device-${index % 80}',
            'deviceName': 'Cảm biến cửa $index ${'y' * 80}',
            'reason': index.isEven ? 'Door opened' : 'Smoke detected',
          },
      ];

      final body = NotificationService.localizedAlarmBodyForData({
        'alarmItems': items,
      }, strings);

      expect(body, contains('Cảm biến cửa 0'));
      expect(body.split('\n'), hasLength(120));
    });
  });

  group('lightweight performance regression', () {
    test('parses and merges hundreds of alarm items in bounded time', () {
      NotificationService.markAlarmPageOpened();
      final stopwatch = Stopwatch()..start();

      for (var batch = 0; batch < 5; batch++) {
        NotificationService.openAlarmPage(
          title: 'SafeHome',
          body: 'Alarm body',
          alarmItemsJson: jsonEncode([
            for (var index = 0; index < 100; index++)
              {
                'incidentId': 'incident-$batch-$index',
                'homeId': 'home-${index % 50}',
                'homeName': 'Home ${index % 50}',
                'deviceId': 'device-$index',
                'deviceName': 'Device $index',
                'reason': index.isEven ? 'Door opened' : 'Motion detected',
              },
          ]),
        );
      }

      stopwatch.stop();

      expect(NotificationService.activeAlarmItems, hasLength(500));
      expect(NotificationService.lastAlarmItemsJson, isNotEmpty);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('notification id generation is stable under sample load', () {
      final ids = <int>{};
      final stopwatch = Stopwatch()..start();

      for (var index = 0; index < 500; index++) {
        final first = NotificationService.homeChatNotificationId('home-$index');
        final second = NotificationService.homeChatNotificationId(
          'home-$index',
        );

        expect(first, second);
        expect(first, inInclusiveRange(200000, 899999));
        ids.add(first);
      }

      stopwatch.stop();

      expect(ids.length, greaterThan(490));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('localization lookup remains stable for alarm hot path labels', () {
      final labels = [
        'Door opened',
        'Smoke detected',
        'Carbon monoxide detected',
        'Gas leak detected',
        'Water leak detected',
        'Motion detected',
        'Vibration detected',
        'Glass break detected',
      ];
      final stopwatch = Stopwatch()..start();
      final results = <String>[];

      for (var index = 0; index < 500; index++) {
        results.add(strings.statusText(labels[index % labels.length]));
      }

      stopwatch.stop();

      expect(results, hasLength(500));
      expect(results.toSet(), containsAll(labels.map(strings.statusText)));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });
  });
}
