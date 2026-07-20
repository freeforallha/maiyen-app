import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safehome_app/localization/app_strings.dart';
import 'package:safehome_app/services/notification_service.dart';

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

  group('alarm regression helpers', () {
    test('classifies supported alarm metadata without payload rewrites', () {
      expect(
        NotificationService.normalizedIncidentEventCategory({
          'eventCategory': 'security',
        }),
        'security',
      );
      expect(
        NotificationService.normalizedIncidentAlarmLevel({
          'eventCategory': 'security',
        }),
        'alarm',
      );
      expect(
        NotificationService.normalizedIncidentEventCategory({
          'eventCategory': 'emergency',
        }),
        'emergency',
      );
      expect(
        NotificationService.normalizedIncidentAlarmLevel({
          'eventCategory': 'emergency',
        }),
        'emergency',
      );
      expect(
        NotificationService.normalizedIncidentAlarmLevel({
          'eventCategory': 'system_warning',
        }),
        'warning',
      );
      expect(
        NotificationService.normalizedIncidentAlarmLevel({
          'severity': 'critical',
        }),
        'emergency',
      );
      expect(
        NotificationService.normalizedIncidentStatus({
          'incidentStatus': ' RESOLVED ',
        }),
        'resolved',
      );
    });

    test(
      'keeps two incidents from one device and dedupes the same incident',
      () {
        NotificationService.markAlarmPageOpened();

        NotificationService.openAlarmPage(
          title: 'SafeHome',
          body: 'Alarm body',
          alarmItemsJson: jsonEncode([
            _alarmItem(
              incidentId: 'incident-a',
              homeId: 'home-1',
              homeName: 'Main home',
              deviceId: 'door-1',
              deviceName: 'Front door',
              reason: 'Door opened',
            ),
          ]),
        );

        NotificationService.openAlarmPage(
          title: 'SafeHome',
          body: 'Alarm body',
          alarmItemsJson: jsonEncode([
            _alarmItem(
              incidentId: 'incident-a',
              homeId: 'home-1',
              homeName: 'Main home',
              deviceId: 'door-1',
              deviceName: 'Front door',
              reason: 'Door opened again',
            ),
            _alarmItem(
              incidentId: 'incident-b',
              homeId: 'home-1',
              homeName: 'Main home',
              deviceId: 'door-1',
              deviceName: 'Front door',
              reason: 'Door opened',
            ),
          ]),
        );

        expect(NotificationService.activeAlarmItems, hasLength(2));
        expect(
          NotificationService.activeAlarmItems.map(
            (item) => item['incidentId'],
          ),
          ['incident-a', 'incident-b'],
        );
        expect(
          NotificationService.activeAlarmItems.map((item) => item['homeName']),
          everyElement('Main home'),
        );
        expect(
          NotificationService.activeAlarmItems.first['reason'],
          'Door opened again',
        );
      },
    );

    test('preserves stable display order across multiple homes', () {
      NotificationService.markAlarmPageOpened();

      NotificationService.openAlarmPage(
        title: 'SafeHome',
        body: 'Alarm body',
        alarmItemsJson: jsonEncode([
          _alarmItem(
            incidentId: 'incident-1',
            homeId: 'home-a',
            homeName: 'Alpha',
            deviceId: 'smoke-1',
            deviceName: 'Kitchen smoke',
            reason: 'Smoke detected',
          ),
          _alarmItem(
            incidentId: 'incident-2',
            homeId: 'home-b',
            homeName: 'Beta',
            deviceId: 'gas-1',
            deviceName: 'Gas sensor',
            reason: 'Gas leak detected',
          ),
        ]),
      );

      NotificationService.openAlarmPage(
        title: 'SafeHome',
        body: 'Alarm body',
        alarmItemsJson: jsonEncode([
          _alarmItem(
            incidentId: 'incident-3',
            homeId: 'home-a',
            homeName: 'Alpha',
            deviceId: 'lock-1',
            deviceName: 'Front lock',
            reason: 'Unlocked',
          ),
        ]),
      );

      expect(
        NotificationService.activeAlarmItems.map((item) => item['incidentId']),
        ['incident-1', 'incident-2', 'incident-3'],
      );
      expect(
        NotificationService.activeAlarmItems.map((item) => item['homeName']),
        ['Alpha', 'Beta', 'Alpha'],
      );
    });

    test(
      'updates revision when an already open alarm page receives new data',
      () {
        NotificationService.markAlarmPageOpened();
        final before = NotificationService.alarmRevision.value;

        NotificationService.openAlarmPage(
          title: 'SafeHome',
          body: 'Alarm body',
          alarmItemsJson: jsonEncode([
            _alarmItem(
              incidentId: 'revision-incident',
              homeId: 'home-r',
              homeName: 'Revision home',
              deviceId: 'motion-1',
              deviceName: 'Motion sensor',
              reason: 'Motion detected',
            ),
          ]),
        );

        expect(NotificationService.alarmRevision.value, before + 1);
        expect(NotificationService.lastAlarmItemsJson, isNotEmpty);
      },
    );

    test(
      'uses safe fallback text for missing names and malformed item fields',
      () {
        final body = NotificationService.localizedAlarmBodyForData({
          'alarmItems': jsonEncode([
            {'homeName': 'Fallback home', 'reason': 'Smoke detected'},
            {'deviceName': 'Gate', 'reason': ''},
            {'alarmItems': 'nested-noise'},
          ]),
        }, strings);

        expect(body.split('\n'), contains('Smoke detected'));
        expect(body.split('\n'), contains('Gate'));
      },
    );

    test('covers common security and emergency device reason labels', () {
      final reasons = <String>[
        'SOS activated',
        'Smoke detected',
        'Carbon monoxide detected',
        'Gas leak detected',
        'Water leak detected',
        'Door opened',
        'Unlocked',
        'Motion detected',
        'Vibration detected',
        'Glass break detected',
      ];

      final body = NotificationService.localizedAlarmBodyForData({
        'alarmItems': [
          for (final reason in reasons)
            {
              'deviceName': 'Device ${reasons.indexOf(reason)}',
              'reason': reason,
            },
        ],
      }, strings);

      for (final reason in reasons) {
        expect(body, contains(strings.statusText(reason)));
      }
    });
  });
}

Map<String, String> _alarmItem({
  required String incidentId,
  required String homeId,
  required String homeName,
  required String deviceId,
  required String deviceName,
  required String reason,
}) {
  return {
    'incidentId': incidentId,
    'homeId': homeId,
    'homeName': homeName,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'reason': reason,
  };
}
