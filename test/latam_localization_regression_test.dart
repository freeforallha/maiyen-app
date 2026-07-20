import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safehome_app/localization/languages/ay_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/ay_strings.dart';
import 'package:safehome_app/localization/languages/az_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/gn_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/gn_strings.dart';
import 'package:safehome_app/localization/languages/ht_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/ht_strings.dart';
import 'package:safehome_app/localization/languages/qu_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/qu_strings.dart';
import 'package:safehome_app/localization/languages/vi_strings.dart';

void main() {
  group('Latin America localization regression', () {
    for (final spec in _specs) {
      test('${spec.code} has complete base and dynamic translations', () {
        final base = _baseMap(spec.code);
        final dynamic = _dynamicMap(spec.code);

        expect(base.keys.toSet(), viStrings.keys.toSet());
        expect(dynamic.keys.toSet(), azDynamicStrings.keys.toSet());
        expect(base.values.every((value) => value.trim().isNotEmpty), isTrue);
        expect(
          dynamic.values.every((value) => value.trim().isNotEmpty),
          isTrue,
        );

        for (final entry in base.entries) {
          expect(
            _placeholders(entry.value),
            _placeholders(viStrings[entry.key] ?? entry.key),
            reason: '${spec.code}: ${entry.key}',
          );
          expect(entry.value, isNot(contains('SAFEHOME_PROTECTED')));
          expect(entry.value, isNot(contains('§')));
        }

        for (final entry in dynamic.entries) {
          expect(
            _placeholders(entry.value),
            _placeholders(entry.key),
            reason: '${spec.code} dynamic: ${entry.key}',
          );
          expect(entry.value, isNot(contains('SAFEHOME_PROTECTED')));
          expect(entry.value, isNot(contains('§')));
        }
      });

      test('${spec.code} is registered in language surfaces', () {
        final controllerSource = File(
          'lib/localization/app_language_controller.dart',
        ).readAsStringSync();
        final appStringsSource = File(
          'lib/localization/app_strings.dart',
        ).readAsStringSync();
        final loginSource = File(
          'lib/pages/login_page.dart',
        ).readAsStringSync();
        final settingsSource = File(
          'lib/sheets/settings_sheet.dart',
        ).readAsStringSync();
        final androidBackgroundSource = File(
          'lib/services/platform/android/android_background_notification_service.dart',
        ).readAsStringSync();

        expect(controllerSource, contains('"${spec.code}"'));
        expect(
          controllerSource,
          contains('Locale("${spec.code}", "${spec.region}")'),
        );
        expect(controllerSource, contains('"${spec.code}": "${spec.flag}"'));
        expect(controllerSource, contains('"${spec.code}": "${spec.label}"'));
        expect(controllerSource, contains('is${spec.boolName}'));
        expect(appStringsSource, contains('is${spec.boolName}'));
        expect(
          appStringsSource,
          contains("languages/${spec.code}_strings.dart"),
        );
        expect(
          appStringsSource,
          contains("languages/${spec.code}_dynamic_strings.dart"),
        );
        expect(appStringsSource, contains(spec.mapName));
        expect(loginSource, contains(spec.subtitle));
        expect(settingsSource, contains(spec.subtitle));
        expect(loginSource, contains(spec.aliasNeedle));
        expect(settingsSource, contains(spec.aliasNeedle));
        expect(androidBackgroundSource, contains("'${spec.code}'"));
        expect(
          androidBackgroundSource,
          contains("Locale('${spec.code}', '${spec.region}')"),
        );
      });
    }
  });
}

Map<String, String> _baseMap(String code) {
  return switch (code) {
    'gn' => gnStrings,
    'qu' => quStrings,
    'ay' => ayStrings,
    'ht' => htStrings,
    _ => throw ArgumentError.value(code, 'code'),
  };
}

Map<String, String> _dynamicMap(String code) {
  return switch (code) {
    'gn' => gnDynamicStrings,
    'qu' => quDynamicStrings,
    'ay' => ayDynamicStrings,
    'ht' => htDynamicStrings,
    _ => throw ArgumentError.value(code, 'code'),
  };
}

List<String> _placeholders(String value) {
  final placeholders = RegExp(
    r'\$\{?[A-Za-z_][A-Za-z0-9_]*\}?',
  ).allMatches(value).map((match) => match.group(0)!).toList();
  placeholders.sort();
  return placeholders;
}

class _LatamLocaleSpec {
  const _LatamLocaleSpec({
    required this.code,
    required this.region,
    required this.flag,
    required this.label,
    required this.boolName,
    required this.mapName,
    required this.subtitle,
    required this.aliasNeedle,
  });

  final String code;
  final String region;
  final String flag;
  final String label;
  final String boolName;
  final String mapName;
  final String subtitle;
  final String aliasNeedle;
}

const _specs = <_LatamLocaleSpec>[
  _LatamLocaleSpec(
    code: 'gn',
    region: 'PY',
    flag: '🇵🇾',
    label: 'Guaraní',
    boolName: 'Guarani',
    mapName: '_guarani',
    subtitle: 'Guaraní • Paraguay',
    aliasNeedle: 'ava ñe',
  ),
  _LatamLocaleSpec(
    code: 'qu',
    region: 'PE',
    flag: '🇵🇪',
    label: 'Quechua',
    boolName: 'Quechua',
    mapName: '_quechua',
    subtitle: 'Quechua • Peru',
    aliasNeedle: 'runasimi',
  ),
  _LatamLocaleSpec(
    code: 'ay',
    region: 'BO',
    flag: '🇧🇴',
    label: 'Aymara',
    boolName: 'Aymara',
    mapName: '_aymara',
    subtitle: 'Aymara • Bolivia',
    aliasNeedle: 'aymara bolivia',
  ),
  _LatamLocaleSpec(
    code: 'ht',
    region: 'HT',
    flag: '🇭🇹',
    label: 'Kreyòl ayisyen',
    boolName: 'HaitianCreole',
    mapName: '_haitianCreole',
    subtitle: 'Haitian Creole • Haiti',
    aliasNeedle: 'haitian creole',
  ),
];
