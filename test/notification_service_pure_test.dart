import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/localization/app_strings.dart';
import 'package:maiyen_app/services/notification_service.dart';

void main() {
  group('NotificationService pure helpers', () {
    test('home chat payload keeps the public prefix and data fields', () {
      final payload = NotificationService.homeChatPayload(
        homeId: 'home_a',
        homeName: 'Main home',
        ownerUid: 'owner_1',
        messageId: 'msg_9',
      );

      expect(payload, startsWith('home_chat::'));

      final decoded = jsonDecode(payload.replaceFirst('home_chat::', ''));

      expect(decoded, {
        'homeId': 'home_a',
        'homeName': 'Main home',
        'ownerUid': 'owner_1',
        'messageId': 'msg_9',
      });
    });

    test('home chat notification id is stable and namespaced', () {
      final first = NotificationService.homeChatNotificationId('home_a');
      final second = NotificationService.homeChatNotificationId('home_a');
      final other = NotificationService.homeChatNotificationId('home_b');

      expect(first, second);
      expect(first, isNot(other));
      expect(first, inInclusiveRange(200000, 899999));
      expect(other, inInclusiveRange(200000, 899999));
    });

    test('normalizes incident metadata without changing payload keys', () {
      expect(
        NotificationService.normalizedIncidentEventCategory({
          'alarmFlowType': 'emergency',
        }),
        'emergency',
      );
      expect(
        NotificationService.normalizedIncidentEventCategory({
          'eventCategory': 'system_warning',
        }),
        'system_warning',
      );
      expect(
        NotificationService.normalizedIncidentAlarmLevel({
          'severity': 'critical',
        }),
        'emergency',
      );
      expect(
        NotificationService.normalizedIncidentAlarmLevel({
          'alarmLevel': 'warning',
        }),
        'warning',
      );
      expect(NotificationService.normalizedIncidentStatus({}), 'active');
      expect(
        NotificationService.normalizedIncidentStatus({'status': 'resolved'}),
        'resolved',
      );
    });

    test('localized alarm body deduplicates repeated item lines', () {
      final strings = AppStrings.fromLocale(const Locale('en'));
      final body = NotificationService.localizedAlarmBodyForData({
        'alarmItems': jsonEncode([
          {
            'homeId': 'home_a',
            'deviceId': 'door_1',
            'deviceName': 'Front door',
            'reason': 'TEST_REASON_ALPHA',
          },
          {
            'homeId': 'home_a',
            'deviceId': 'door_1',
            'deviceName': 'Front door',
            'reason': 'TEST_REASON_ALPHA',
          },
          {
            'homeId': 'home_b',
            'deviceId': 'smoke_1',
            'deviceName': 'Kitchen smoke',
            'reason': 'TEST_REASON_BETA',
          },
        ]),
      }, strings);

      final lines = body.split('\n');

      expect(lines, contains('Front door: TEST_REASON_ALPHA'));
      expect(lines, contains('Kitchen smoke: TEST_REASON_BETA'));
      expect(
        lines.where((line) => line == 'Front door: TEST_REASON_ALPHA'),
        hasLength(1),
      );
    });

    test('localized alarm body falls back from flat payload fields', () {
      final strings = AppStrings.fromLocale(const Locale('en'));
      final body = NotificationService.localizedAlarmBodyForData({
        'homeId': 'home_a',
        'deviceId': 'gas_1',
        'deviceName': 'Gas sensor',
        'body': 'TEST_GAS_ALERT',
      }, strings);

      expect(body, 'Gas sensor: TEST_GAS_ALERT');
    });
  });
}
