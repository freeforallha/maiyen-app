import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/widgets/status_panel.dart';

void main() {
  test('StatusPanel facade keeps the public widget contract', () {
    expect(StatusPanel, isA<Type>());
  });

  test('StatusPanel implementation is split into bounded domain parts', () {
    const partFiles = <String>[
      'status_panel_status_part.dart',
      'status_panel_security_part.dart',
      'status_panel_summary_part.dart',
      'status_panel_siren_part.dart',
      'status_panel_layout_part.dart',
    ];

    final facade = File('lib/widgets/status_panel.dart');
    final facadeSource = facade.readAsStringSync();

    expect(facade.readAsLinesSync().length, lessThan(220));
    expect(
      facadeSource,
      contains(
        'Widget build(BuildContext context) => _buildStatusPanel(context);',
      ),
    );

    for (final partFile in partFiles) {
      expect(
        facadeSource,
        contains("part 'status_panel/$partFile';"),
        reason: partFile,
      );

      final file = File('lib/widgets/status_panel/$partFile');
      expect(file.existsSync(), isTrue, reason: partFile);
      expect(
        file.readAsLinesSync().length,
        lessThan(500),
        reason: partFile,
      );
      expect(
        file.readAsStringSync(),
        startsWith("part of '../status_panel.dart';"),
        reason: partFile,
      );
    }
  });
}
