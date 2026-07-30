import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final coordinator = File(
    'lib/services/hub_update_notice_coordinator.dart',
  ).readAsStringSync();
  final settings = File('lib/sheets/settings_sheet.dart').readAsStringSync();

  test('thông báo Hub update nằm phía trên HomeBottomBar', () {
    expect(coordinator, contains('final noticeBottomMargin ='));
    expect(coordinator, contains('bottomBarBottomInset + 68.0 + 12.0'));
    expect(
      coordinator,
      contains('EdgeInsets.fromLTRB(14, 12, 14, noticeBottomMargin)'),
    );
    expect(
      coordinator,
      isNot(contains('margin: const EdgeInsets.fromLTRB(14, 12, 14, 14)')),
    );
  });

  test('badge Hub update chỉ nghe đúng field updateAvailable', () {
    expect(
      settings,
      contains('hubStatus/updateAvailable'),
    );
    expect(settings, contains('class _HubUpdateAttentionTrailing'));
    expect(settings, contains("child: const Text(\n                  '!',"));
  });

  test('Quản lý nhà và Hub trung tâm cùng có dấu cảnh báo', () {
    final badgeUsage = RegExp(
      r'trailing: _HubUpdateAttentionTrailing\(',
    ).allMatches(settings).length;

    expect(badgeUsage, 2);
    expect(settings, contains('strings.t("Quản lý nhà")'));
    expect(settings, contains("strings.t('Hub trung tâm')"));
  });
}
