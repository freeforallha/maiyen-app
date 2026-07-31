import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readSource(String path) {
  return File(path).readAsStringSync().replaceAll('\r\n', '\n');
}

void main() {
  final homePage = _readSource('lib/pages/home_page.dart');
  final bottomBar = _readSource('lib/pages/home/home_bottom_bar.dart');
  final coordinator = _readSource(
    'lib/services/hub_update_notice_coordinator.dart',
  );
  final settings = _readSource('lib/sheets/settings_sheet.dart');

  test('banner Hub update nằm phía trên HomeBottomBar', () {
    expect(coordinator, contains('final noticeBottomMargin ='));
    expect(coordinator, contains('bottomBarBottomInset + 68.0 + 12.0'));
    expect(
      coordinator,
      contains('EdgeInsets.fromLTRB(14, 12, 14, noticeBottomMargin)'),
    );
  });

  test('banner có phiên bản Hub mới chỉ dành cho Owner', () {
    expect(coordinator, contains('ownerUid.isEmpty || ownerUid != uid.trim()'));
  });

  test('Settings ngoài HomePage có dấu chấm than khi Owner cần update Hub', () {
    expect(bottomBar, contains('final bool hubUpdateAttention;'));
    expect(bottomBar, contains('if (inviteCount > 0 || hubUpdateAttention)'));
    expect(bottomBar, contains('inviteCount > 0 ? "\$inviteCount" : "!"'));
    expect(homePage, contains('final hubUpdateAttention ='));
    expect(homePage, contains('isOwner() &&'));
    expect(homePage, contains('hubUpdateAttention: hubUpdateAttention'));
  });

  test('Member và Admin không nhận dấu cảnh báo Hub ở Settings ngoài', () {
    expect(
      homePage,
      contains(
        'isOwner() &&\n'
        '        parseDeviceBool(overviewHubStatus["updateAvailable"]) == true',
      ),
    );
  });

  test('Quản lý nhà và Hub trung tâm tiếp tục có dấu cảnh báo cho Owner', () {
    final badgeUsage = RegExp(
      r'trailing: _HubUpdateAttentionTrailing\(',
    ).allMatches(settings).length;

    expect(badgeUsage, 2);
    expect(settings, contains('if (role == "owner")'));
    expect(settings, contains('hubStatus/updateAvailable'));
    expect(settings, contains('strings.t("Quản lý nhà")'));
    expect(settings, contains("strings.t('Hub trung tâm')"));
  });
}
