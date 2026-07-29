import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readProjectFile(String relativePath) {
  return File(relativePath).readAsStringSync();
}

void main() {
  test('Fullscreen Alarm dùng notification channel mới', () {
    final source = readProjectFile('lib/config/maiyen_identifiers.dart');

    expect(source, contains("'maiyen_alarm_fullscreen_v2'"));
    expect(source, isNot(contains("'maiyen_alarm_fullscreen_v1'")));
  });

  test('Fullscreen Alarm dùng còi raw và audio stream Alarm', () {
    final source = readProjectFile(
      'lib/services/platform/android/android_notification_config.dart',
    );

    expect(
      source,
      contains("RawResourceAndroidNotificationSound('alarm_siren')"),
    );
    expect(source, contains('audioAttributesUsage: AudioAttributesUsage.alarm'));
    expect(source, contains('fullScreenIntent: true'));
  });

  test('Notification native lặp còi cho tới khi được hủy', () {
    final source = readProjectFile(
      'lib/services/platform/android/android_notification_config.dart',
    );

    expect(source, contains('_notificationFlagInsistent = 0x00000004'));
    expect(source, contains('additionalFlags: Int32List.fromList'));
  });

  test('Trang Alarm phát âm thanh trước khi hủy notification native', () {
    final source = readProjectFile('lib/pages/fullscreen_alarm_page.dart');
    const functionStart = 'Future<void> _startAlarmMode() async {';
    final startIndex = source.indexOf(functionStart);
    final endIndex = source.indexOf('\n  }', startIndex);

    expect(startIndex, greaterThanOrEqualTo(0));
    expect(endIndex, greaterThan(startIndex));

    final functionBody = source.substring(startIndex, endIndex);
    final startSoundIndex = functionBody.indexOf('await startAlarmSound();');
    final cancelIndex = functionBody.indexOf(
      'await NotificationService.stopAllAlarmNotifications();',
    );

    expect(startSoundIndex, greaterThanOrEqualTo(0));
    expect(cancelIndex, greaterThan(startSoundIndex));
  });
}
