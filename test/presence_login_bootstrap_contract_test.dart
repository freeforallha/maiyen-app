import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('presence login bootstrap contract', () {
    final appSource = File('lib/app/maiyen_app.dart').readAsStringSync();
    final coordinatorSource = File(
      'lib/services/home_auto_away_coordinator.dart',
    ).readAsStringSync();
    final androidTaskSource = File(
      'lib/services/platform/android/'
      'android_auto_away_foreground_task_service.dart',
    ).readAsStringSync();

    test('signed-in auth state schedules immediate and delayed recovery', () {
      for (final contract in <String>[
        '_scheduleSignedInPresenceRecovery(user.uid)',
        "event: 'auth_state_signed_in_recovery'",
        "event: 'auth_state_signed_in_recovery_30s'",
        "event: 'auth_state_signed_in_recovery_2m'",
        'AutoAwayService.activateForSignedInUser(cleanUid)',
        'PlatformAutoAwayTaskService.recoverNow(event: event)',
      ]) {
        expect(appSource, contains(contract), reason: contract);
      }
    });

    test('logout and dispose cancel pending recovery retries', () {
      expect(
        appSource,
        matches(
          RegExp(r'user == null[\s\S]*?_stopSignedInPresenceRecovery\(\)'),
        ),
      );
      expect(
        appSource,
        matches(
          RegExp(r'void dispose\(\)[\s\S]*?_stopSignedInPresenceRecovery\(\)'),
        ),
      );
    });

    test('failed foreground confirmation does not consume retry window', () {
      final awaitIndex = coordinatorSource.indexOf(
        'await AutoAwayService.refreshPresenceForHomes(',
      );
      final markIndex = coordinatorSource.indexOf(
        '_lastAndroidForegroundConfirmAt = DateTime.now();',
      );

      expect(awaitIndex, greaterThanOrEqualTo(0));
      expect(markIndex, greaterThan(awaitIndex));
    });

    test('running foreground service is always asked to refresh now', () {
      expect(androidTaskSource, contains("'action': 'refresh_now'"));
      expect(
        androidTaskSource,
        isNot(
          contains(
            'if (configChanged) {\n'
            '        FlutterForegroundTask.sendDataToTask',
          ),
        ),
      );
    });
  });
}
