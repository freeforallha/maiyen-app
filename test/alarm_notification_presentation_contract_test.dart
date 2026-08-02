import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/localization/app_strings.dart';
import 'package:maiyen_app/services/notification/notification_alarm_presentation.dart';

Map<String, dynamic> securityData({
  String stage = 'initial',
  int repeatMinutes = 0,
  int repeatCount = 0,
}) {
  return {
    'type': 'alarm',
    'alarmFlowType': 'security',
    'alarmNotificationStage': stage,
    'alarmFamily': 'security',
    'repeatMinutes': '$repeatMinutes',
    'repeatCount': '$repeatCount',
    'alarmItems': jsonEncode([
      {
        'homeId': 'home-1',
        'homeName': 'Nhà Thị Kem',
        'deviceId': 'door-1',
        'deviceName': 'Cửa chính',
        'type': 'door',
        'reason': 'Đang mở bất thường',
      },
    ]),
  };
}

void main() {
  group('Alarm notification presentation', () {
    test('Vietnamese repeat title explicitly says Nhắc nhở lại', () {
      final strings = AppStrings.fromLocale(const Locale('vi'));
      final presentation = buildAlarmNotificationPresentation(
        securityData(stage: 'repeat', repeatMinutes: 30, repeatCount: 2),
        strings,
      );

      expect(
        presentation.title,
        '🔁 Nhắc nhở lại “Cửa chính: Đang mở bất thường”',
      );
      expect(presentation.body, contains('Nhà Thị Kem: Cửa chính:'));
      expect(presentation.body, contains('Lặp sau 30 phút'));
      expect(presentation.body, contains('#2'));
      expect(presentation.isRepeat, isTrue);
    });

    test('English repeat uses localized alarm reminder wording', () {
      final strings = AppStrings.fromLocale(const Locale('en'));
      final presentation = buildAlarmNotificationPresentation(
        securityData(stage: 'repeat', repeatMinutes: 15, repeatCount: 1),
        strings,
      );

      expect(presentation.title, startsWith('🔁 '));
      expect(presentation.title, isNot(contains('Nhắc nhở lại')));
      expect(presentation.body, isNot(contains('Lặp sau 15 phút')));
    });

    test('security stages have distinct titles', () {
      final strings = AppStrings.fromLocale(const Locale('vi'));
      final titles = {
        for (final stage in [
          'initial',
          'repeat',
          'detected',
          'fullscreen',
          'resolved',
        ])
          buildAlarmNotificationPresentation(
            securityData(
              stage: stage,
              repeatMinutes: stage == 'repeat' ? 30 : 0,
            ),
            strings,
          ).title,
      };

      expect(titles, hasLength(5));
      expect(titles.any((title) => title.startsWith('🚨 BÁO ĐỘNG')), isTrue);
      expect(
        titles.any((title) => title.startsWith('🔁 Nhắc nhở lại')),
        isTrue,
      );
      expect(titles.any((title) => title.startsWith('👁️ Cần chú ý')), isTrue);
      expect(
        titles.any((title) => title.startsWith('📢 Còi báo động')),
        isTrue,
      );
      expect(titles.any((title) => title.startsWith('✅ ')), isTrue);
    });

    test('emergency families have unique labels and symbols', () {
      final strings = AppStrings.fromLocale(const Locale('vi'));
      final cases = {
        'sos': '🆘 KHẨN CẤP · Nút SOS',
        'smoke': '🔥 KHẨN CẤP · Báo khói',
        'heat': '🌡️ KHẨN CẤP · Báo nhiệt',
        'carbon_monoxide': '☠️ KHẨN CẤP · Khí CO',
        'gas': '⚠️ KHẨN CẤP · Báo gas',
        'water': '🌊 KHẨN CẤP · Báo ngập/rò nước',
      };

      for (final entry in cases.entries) {
        final presentation = buildAlarmNotificationPresentation({
          'alarmFlowType': 'emergency',
          'alarmNotificationStage': 'initial',
          'alarmFamily': entry.key,
          'alarmItems': jsonEncode([
            {
              'homeName': 'Nhà Thị Kem',
              'deviceName': 'Thiết bị',
              'type': entry.key,
              'reason': 'Đang cảnh báo',
            },
          ]),
        }, strings);

        expect(presentation.title, entry.value);
      }
    });
  });
}
