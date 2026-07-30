import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/pages/all_home_page.dart';

void main() {
  test('AllHome facade keeps the public widget contract', () {
    expect(AllHome, isA<Type>());
  });

  test('AllHome implementation is split into bounded responsibility parts', () {
    const partLimits = <String, int>{
      'all_home_lifecycle_part.dart': 260,
      'all_home_summary_realtime_part.dart': 500,
      'all_home_grouping_part.dart': 180,
      'all_home_cards_part.dart': 420,
      'all_home_alarm_time_part.dart': 220,
      'all_home_alarm_config_part.dart': 650,
      'all_home_bulk_alarm_part.dart': 360,
      'all_home_sharing_part.dart': 560,
      'all_home_delete_part.dart': 380,
      'all_home_layout_part.dart': 420,
    };

    final facade = File('lib/pages/all_home_page.dart');
    final facadeSource = facade.readAsStringSync();

    expect(facade.readAsLinesSync().length, lessThan(150));
    expect(
      facadeSource,
      contains(
        'Widget build(BuildContext context) => _buildAllHomePage(context);',
      ),
    );
    expect(facadeSource, isNot(contains('all_home_management_part.dart')));

    for (final entry in partLimits.entries) {
      expect(
        facadeSource,
        contains("part 'all_home/${entry.key}';"),
        reason: entry.key,
      );

      final file = File('lib/pages/all_home/${entry.key}');
      expect(file.existsSync(), isTrue, reason: entry.key);
      expect(
        file.readAsLinesSync().length,
        lessThan(entry.value),
        reason: entry.key,
      );
      expect(
        file.readAsStringSync(),
        startsWith("part of '../all_home_page.dart';"),
        reason: entry.key,
      );
    }
  });

  test('bulk actions remain delegated from the AllHome layout', () {
    final layout = File(
      'lib/pages/all_home/all_home_layout_part.dart',
    ).readAsStringSync();
    final sharing = File(
      'lib/pages/all_home/all_home_sharing_part.dart',
    ).readAsStringSync();
    final alarm = File(
      'lib/pages/all_home/all_home_bulk_alarm_part.dart',
    ).readAsStringSync();

    expect(layout, contains('onTap: setSelectedHomesAlarm'));
    expect(layout, contains('onTap: _shareSelectedHomes'));
    expect(layout, contains('onTap: _manageSelectedHomeShares'));
    expect(layout, contains('onTap: confirmDeleteSelected'));
    expect(sharing, contains('MaiYenIdentifiers.buildJoinMultipleHomesQr'));
    expect(alarm, contains('_inputSelectedHomesAlarmConfig'));
  });
}
