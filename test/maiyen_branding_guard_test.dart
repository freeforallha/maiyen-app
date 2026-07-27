import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user-facing Dart source does not reintroduce SafeHome branding', () {
    final roots = <Directory>[
      Directory('lib/app'),
      Directory('lib/dialogs'),
      Directory('lib/localization'),
      Directory('lib/navigation'),
      Directory('lib/pages'),
      Directory('lib/sheets'),
      Directory('lib/widgets'),
    ];

    final violations = <String>[];

    for (final root in roots) {
      if (!root.existsSync()) {
        continue;
      }

      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }

        final content = entity.readAsStringSync();

        if (RegExp(r'safehome', caseSensitive: false).hasMatch(content)) {
          violations.add(entity.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Tên SafeHome chỉ được tồn tại trong định danh/callback legacy, '
          'không được xuất hiện lại trong mã nguồn giao diện.',
    );
  });

  test('retired SafeHome Dart files stay removed', () {
    const retiredPaths = <String>[
      'lib/app/safe_home_app.dart',
      'lib/navigation/safehome_navigation.dart',
      'lib/safehome_theme.dart',
    ];

    final existing = retiredPaths.where((path) => File(path).existsSync());

    expect(existing, isEmpty);
  });
}
