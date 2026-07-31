import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readSource(String path) {
  return File(path).readAsStringSync().replaceAll('\r\n', '\n');
}

void main() {
  final coordinator = _readSource(
    'lib/services/hub_update_notice_coordinator.dart',
  );
  final settings = _readSource('lib/sheets/settings_sheet.dart');

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
    expect(settings, contains('hubStatus/updateAvailable'));
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
