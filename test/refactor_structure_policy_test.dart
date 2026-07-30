import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/pages/all_home_page.dart';
import 'package:maiyen_app/pages/home_page.dart';
import 'package:maiyen_app/services/notification/notification_incident_normalizer.dart';
import 'package:maiyen_app/services/notification/notification_payload_codec.dart';
import 'package:maiyen_app/widgets/device_list.dart';

void main() {
  test('large UI libraries compile through domain part files', () {
    expect(MaiYen, isA<Type>());
    expect(AllHome, isA<Type>());
    expect(DeviceList, isA<Type>());
  });

  test('notification payload codec keeps Hub and chat contracts', () {
    final hubPayload = NotificationPayloadCodec.hubUpdatePayload(
      homeId: 'homeA',
      homeName: 'Nhà A',
      ownerUid: 'ownerA',
      releaseId: 'v1.2.11',
    );
    final chatPayload = NotificationPayloadCodec.homeChatPayload(
      homeId: 'homeA',
      homeName: 'Nhà A',
      ownerUid: 'ownerA',
      messageId: 'messageA',
    );

    expect(NotificationPayloadCodec.decodeHubUpdatePayload(hubPayload), {
      'homeId': 'homeA',
      'homeName': 'Nhà A',
      'ownerUid': 'ownerA',
      'releaseId': 'v1.2.11',
    });
    expect(NotificationPayloadCodec.decodeHomeChatPayload(chatPayload), {
      'homeId': 'homeA',
      'homeName': 'Nhà A',
      'ownerUid': 'ownerA',
      'messageId': 'messageA',
    });
  });

  test('incident normalizer preserves Alarm defaults', () {
    expect(
      NotificationIncidentNormalizer.eventCategory({
        'flowType': 'emergency',
      }),
      'emergency',
    );
    expect(
      NotificationIncidentNormalizer.alarmLevel({
        'eventCategory': 'system_warning',
      }),
      'warning',
    );
    expect(NotificationIncidentNormalizer.status({}), 'active');
  });

  test('composition files stay below refactor guardrails', () {
    expect(File('lib/pages/home_page.dart').readAsLinesSync().length, lessThan(1000));
    expect(File('lib/widgets/device_list.dart').readAsLinesSync().length, lessThan(400));
    expect(File('lib/pages/all_home_page.dart').readAsLinesSync().length, lessThan(150));
    expect(File('lib/services/notification_service.dart').readAsLinesSync().length, lessThan(450));
  });
}
