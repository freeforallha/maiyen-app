import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/sheets/device_alarm_policy_sheet.dart';

void main() {
  group('personal alarm safety contract', () {
    test('leaving the home schedule clones all common schedules', () {
      final common = <String, Map<String, dynamic>>{
        'night': <String, dynamic>{
          'enabled': true,
          'start': '23:00',
          'end': '06:00',
          'repeatMinutes': 30,
          'days': <int>[1, 2, 3, 4, 5, 6, 7],
        },
      };

      final personal = buildSafePersonalSchedulesWhenLeavingHomeSchedule(
        common,
      );

      expect(personal.keys, contains('night'));
      expect(personal['night'], isNot(same(common['night'])));
      expect(personal['night']?['enabled'], isTrue);
    });

    test('leaving an empty home schedule creates one enabled schedule', () {
      final personal = buildSafePersonalSchedulesWhenLeavingHomeSchedule(
        const <String, Map<String, dynamic>>{},
      );

      expect(personal, hasLength(1));
      expect(personal.values.single['enabled'], isTrue);
      expect(personal.values.single['start'], '23:00');
      expect(personal.values.single['end'], '06:00');
    });
  });

  test('foreground FCM keeps the daily unprotected warning visible', () {
    final source = File('lib/services/fcm_service.dart').readAsStringSync();

    expect(source, contains("type == 'home_unprotected_daily_warning'"));
    expect(
      source,
      contains(
        'NotificationService.showSensorNotification(data: message.data)',
      ),
    );
  });
}
