import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final eventSheet = File('lib/sheets/home_event_sheet.dart').readAsStringSync();
  final requestSheet = File(
    'lib/sheets/share_request_sheet.dart',
  ).readAsStringSync();
  final memberSheet = File('lib/sheets/share_list_sheet.dart').readAsStringSync();
  final strings = File('lib/localization/app_strings.dart').readAsStringSync();
  final service = File(
    'lib/services/home_notification_service.dart',
  ).readAsStringSync();

  const expandedTypes = <String>[
    'share_request_accepted',
    'share_request_denied',
    'join_request_accepted',
    'join_request_denied',
    'transfer_owner_accepted',
    'transfer_owner_failed',
    'member_removed',
    'alarm_pause_cancelled',
  ];

  test('Home Notification UI nhận diện đủ loại bổ sung', () {
    for (final type in expandedTypes) {
      expect(eventSheet, contains('case "$type"'));
      expect(strings, contains('type == "$type"'));
    }
  });

  test('tiêu đề Thông báo được căn trái', () {
    expect(eventSheet, contains('alignment: Alignment.centerLeft'));
    expect(eventSheet, contains('strings.notifications'));
    expect(
      eventSheet,
      isNot(contains('const Spacer(),\n                    Text(')),
    );
  });

  test('chấp nhận và từ chối lời mời tạo notification nhắm đúng người', () {
    for (final type in const <String>[
      'share_request_accepted',
      'share_request_denied',
      'join_request_accepted',
      'join_request_denied',
      'transfer_owner_failed',
    ]) {
      expect(requestSheet, contains('type: "$type"'));
    }
    expect(requestSheet, contains('writeHomeTimeline: false'));
    expect(requestSheet, contains('waitForBackendResult: true'));
    expect(service, contains('homeNotificationRequestResults'));
    expect(service, contains('Duration(seconds: 8)'));
  });

  test('xoá thành viên thông báo cho chính thành viên bị xoá', () {
    expect(memberSheet, contains('recipientUid: targetUid'));
    expect(memberSheet, contains('type: "member_removed"'));
    expect(memberSheet, contains('writeHomeTimeline: false'));
  });
}
