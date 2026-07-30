import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/services/notification_service.dart';

void main() {
  test('NotificationService facade keeps the public contract', () {
    expect(NotificationService.emergencyNotificationId, 999997);
    expect(NotificationService.alarmNotificationId, 999999);
    expect(NotificationService.reminderRouteName, 'fullscreen_reminder');
    expect(NotificationService.alarmRouteName, 'fullscreen_alarm');

    expect(
      identical(
        NotificationService.chatOpenRequest,
        NotificationService.chatOpenRequest,
      ),
      isTrue,
    );
    expect(
      identical(
        NotificationService.alarmRevision,
        NotificationService.alarmRevision,
      ),
      isTrue,
    );

    final originalBody = NotificationService.lastAlarmBody;
    NotificationService.lastAlarmBody = 'phase2-contract-check';
    expect(NotificationService.lastAlarmBody, 'phase2-contract-check');
    NotificationService.lastAlarmBody = originalBody;
  });

  test('Hub update and chat payload delegates keep their contracts', () {
    final hubPayload = NotificationService.hubUpdatePayload(
      homeId: 'homeA',
      homeName: 'Nhà A',
      ownerUid: 'ownerA',
      releaseId: 'v1.2.12',
    );
    final chatPayload = NotificationService.homeChatPayload(
      homeId: 'homeA',
      homeName: 'Nhà A',
      ownerUid: 'ownerA',
      messageId: 'messageA',
    );

    expect(hubPayload, contains('hub_update::'));
    expect(chatPayload, contains('home_chat::'));
    expect(NotificationService.hubUpdateNotificationId('homeA'), isNot(0));
    expect(NotificationService.homeChatNotificationId('homeA'), isNot(0));
  });

  test('notification implementation is split into bounded domain parts', () {
    const partFiles = <String>[
      'notification_navigation_part.dart',
      'notification_alarm_validation_part.dart',
      'notification_alarm_actions_part.dart',
      'notification_alarm_delivery_part.dart',
      'notification_delivery_part.dart',
      'notification_reminder_part.dart',
      'notification_bootstrap_part.dart',
      'notification_alarm_session_part.dart',
    ];

    final facade = File('lib/services/notification_service.dart');
    final facadeSource = facade.readAsStringSync();

    expect(facade.readAsLinesSync().length, lessThan(450));

    for (final partFile in partFiles) {
      expect(
        facadeSource,
        contains("part 'notification/$partFile';"),
      );

      final file = File('lib/services/notification/$partFile');
      expect(file.existsSync(), isTrue, reason: partFile);
      expect(
        file.readAsLinesSync().length,
        lessThan(650),
        reason: partFile,
      );
      expect(
        file.readAsStringSync(),
        startsWith("part of '../notification_service.dart';"),
        reason: partFile,
      );
    }
  });
}
