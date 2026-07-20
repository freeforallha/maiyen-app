import 'dart:io';

import 'package:safehome_app/localization/languages/ay_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/ay_strings.dart';
import 'package:safehome_app/localization/languages/az_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/en_strings.dart';
import 'package:safehome_app/localization/languages/es_strings.dart';
import 'package:safehome_app/localization/languages/gn_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/gn_strings.dart';
import 'package:safehome_app/localization/languages/ht_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/ht_strings.dart';
import 'package:safehome_app/localization/languages/qu_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/qu_strings.dart';
import 'package:safehome_app/localization/languages/vi_strings.dart';

void main(List<String> args) {
  final code = args.length == 1 ? args.single : null;
  final spec = _specs[code];

  if (spec == null) {
    stderr.writeln('Usage: dart tool/validate_latam_locale.dart gn|qu|ay|ht');
    exitCode = 64;
    return;
  }

  final errors = <String>[];
  final warnings = <String>[];
  final baseMap = _baseMap(spec.code);
  final dynamicMap = _dynamicMap(spec.code);

  _validateMapShape(
    label: '${spec.code} base',
    expectedKeys: viStrings.keys.toSet(),
    values: baseMap,
    errors: errors,
  );
  _validateMapShape(
    label: '${spec.code} dynamic',
    expectedKeys: azDynamicStrings.keys.toSet(),
    values: dynamicMap,
    errors: errors,
  );

  _validatePlaceholders(
    code: spec.code,
    values: baseMap,
    expectedValues: viStrings,
    alternateExpectedValues: enStrings,
    errors: errors,
  );
  _validatePlaceholders(
    code: '${spec.code} dynamic',
    values: dynamicMap,
    expectedValues: azDynamicStrings,
    errors: errors,
  );

  _validateNoGeneratedToken(
    label: '${spec.code} base',
    values: baseMap,
    errors: errors,
  );
  _validateNoGeneratedToken(
    label: '${spec.code} dynamic',
    values: dynamicMap,
    errors: errors,
  );
  _validateNoExactFallback(
    spec: spec,
    values: baseMap,
    errors: errors,
    warnings: warnings,
  );
  _validateRegistration(spec: spec, errors: errors);

  if (errors.isNotEmpty) {
    stderr.writeln('LATAM locale validation failed for ${spec.code}:');
    for (final error in errors.take(160)) {
      stderr.writeln('- $error');
    }
    if (errors.length > 160) {
      stderr.writeln('- ... ${errors.length - 160} more error(s)');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'LATAM locale ${spec.code} OK: '
    '${baseMap.length} base keys, ${dynamicMap.length} dynamic keys, '
    'label "${spec.label}", flag ${spec.flag}.',
  );

  for (final warning in warnings.take(8)) {
    stdout.writeln('warning: $warning');
  }
}

void _validateMapShape({
  required String label,
  required Set<String> expectedKeys,
  required Map<String, String> values,
  required List<String> errors,
}) {
  final actualKeys = values.keys.toSet();
  final missing = expectedKeys.difference(actualKeys);
  final extra = actualKeys.difference(expectedKeys);

  if (missing.isNotEmpty || extra.isNotEmpty) {
    errors.add(
      '$label key mismatch. Missing: ${missing.take(8).join(' | ')}. '
      'Extra: ${extra.take(8).join(' | ')}.',
    );
  }

  for (final entry in values.entries) {
    if (entry.value.trim().isEmpty) {
      errors.add('$label has empty value for "${entry.key}".');
    }
  }
}

void _validatePlaceholders({
  required String code,
  required Map<String, String> values,
  required Map<String, String> expectedValues,
  Map<String, String>? alternateExpectedValues,
  required List<String> errors,
}) {
  for (final entry in values.entries) {
    final expected = <String>{
      ..._placeholders(entry.key),
      ..._placeholders(expectedValues[entry.key] ?? ''),
      ..._placeholders(alternateExpectedValues?[entry.key] ?? ''),
    }.toList()..sort();
    final actual = _placeholders(entry.value);

    if (!_sameList(expected, actual)) {
      errors.add(
        '$code placeholder mismatch for "${entry.key}": '
        '${expected.join(',')} != ${actual.join(',')}',
      );
    }
  }
}

void _validateNoGeneratedToken({
  required String label,
  required Map<String, String> values,
  required List<String> errors,
}) {
  for (final entry in values.entries) {
    if (entry.value.contains('SAFEHOME_PROTECTED') ||
        entry.value.contains('__SAFEHOME') ||
        entry.value.contains('§')) {
      errors.add('$label leaked generator token for "${entry.key}".');
    }
  }
}

void _validateNoExactFallback({
  required LatamLocaleSpec spec,
  required Map<String, String> values,
  required List<String> errors,
  required List<String> warnings,
}) {
  for (final entry in values.entries) {
    final value = entry.value.trim();
    if (_isAllowedExactValue(value)) {
      continue;
    }

    final viValue = viStrings[entry.key]?.trim();
    final enValue = enStrings[entry.key]?.trim();
    final esValue = esStrings[entry.key]?.trim();

    if (value == viValue || value == enValue || value == esValue) {
      errors.add('${spec.code} exact fallback for "${entry.key}" -> "$value".');
    }
  }

  if (spec.needsNativeReview) {
    warnings.add(
      '${spec.label} was generated from a curated glossary and still needs '
      'native-speaker review before treating copy quality as final.',
    );
  }
}

void _validateRegistration({
  required LatamLocaleSpec spec,
  required List<String> errors,
}) {
  final controllerSource = File(
    'lib/localization/app_language_controller.dart',
  ).readAsStringSync();
  final appStringsSource = File(
    'lib/localization/app_strings.dart',
  ).readAsStringSync();
  final loginSource = File('lib/pages/login_page.dart').readAsStringSync();
  final settingsSource = File(
    'lib/sheets/settings_sheet.dart',
  ).readAsStringSync();
  final androidBackgroundSource = File(
    'lib/services/platform/android/android_background_notification_service.dart',
  ).readAsStringSync();

  final requiredSnippets = <String, String>{
    'controller code': '"${spec.code}"',
    'controller locale': 'Locale("${spec.code}", "${spec.region}")',
    'controller flag': '"${spec.code}": "${spec.flag}"',
    'controller label': '"${spec.code}": "${spec.label}"',
    'controller bool': 'is${spec.boolName}',
    'AppStrings bool': 'is${spec.boolName}',
    'AppStrings import base': "languages/${spec.code}_strings.dart",
    'AppStrings import dynamic': "languages/${spec.code}_dynamic_strings.dart",
    'AppStrings map': spec.mapName,
    'login subtitle': spec.subtitle,
    'settings subtitle': spec.subtitle,
    'login alias': spec.aliasNeedle,
    'settings alias': spec.aliasNeedle,
    'android code': "'${spec.code}'",
    'android locale': "Locale('${spec.code}', '${spec.region}')",
  };

  void expectContains(String label, String source, String needle) {
    if (!source.contains(needle)) {
      errors.add('$label missing "$needle".');
    }
  }

  expectContains(
    'controller code',
    controllerSource,
    requiredSnippets['controller code']!,
  );
  expectContains(
    'controller locale',
    controllerSource,
    requiredSnippets['controller locale']!,
  );
  expectContains(
    'controller flag',
    controllerSource,
    requiredSnippets['controller flag']!,
  );
  expectContains(
    'controller label',
    controllerSource,
    requiredSnippets['controller label']!,
  );
  expectContains(
    'controller bool',
    controllerSource,
    requiredSnippets['controller bool']!,
  );
  expectContains(
    'AppStrings bool',
    appStringsSource,
    requiredSnippets['AppStrings bool']!,
  );
  expectContains(
    'AppStrings import base',
    appStringsSource,
    requiredSnippets['AppStrings import base']!,
  );
  expectContains(
    'AppStrings import dynamic',
    appStringsSource,
    requiredSnippets['AppStrings import dynamic']!,
  );
  expectContains(
    'AppStrings map',
    appStringsSource,
    requiredSnippets['AppStrings map']!,
  );
  expectContains(
    'login subtitle',
    loginSource,
    requiredSnippets['login subtitle']!,
  );
  expectContains(
    'settings subtitle',
    settingsSource,
    requiredSnippets['settings subtitle']!,
  );
  expectContains('login alias', loginSource, requiredSnippets['login alias']!);
  expectContains(
    'settings alias',
    settingsSource,
    requiredSnippets['settings alias']!,
  );
  expectContains(
    'android code',
    androidBackgroundSource,
    requiredSnippets['android code']!,
  );
  expectContains(
    'android locale',
    androidBackgroundSource,
    requiredSnippets['android locale']!,
  );
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

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }

  return true;
}

bool _isAllowedExactValue(String value) {
  if (value.length <= 3) return true;

  const exactAllowed = {
    'SafeHome',
    'HomeChat',
    'SOS',
    'CO',
    'CO2',
    'CO₂',
    'PM2.5',
    'Wi-Fi',
    'Zigbee',
    'MQTT',
    'GPS',
    'Android',
    'iOS',
    'Face ID',
    'Touch ID',
    'Firebase',
    'FCM',
    'QR',
    'UID',
    'UPS',
    'AI',
    'OK',
    'Camera',
    'Hub',
    'Email',
  };

  if (exactAllowed.contains(value)) return true;

  return RegExp(r'^[0-9\s.,:;!?%/+_()\-°₂]+$').hasMatch(value);
}

class LatamLocaleSpec {
  const LatamLocaleSpec({
    required this.code,
    required this.region,
    required this.flag,
    required this.label,
    required this.boolName,
    required this.mapName,
    required this.subtitle,
    required this.aliasNeedle,
    this.needsNativeReview = true,
  });

  final String code;
  final String region;
  final String flag;
  final String label;
  final String boolName;
  final String mapName;
  final String subtitle;
  final String aliasNeedle;
  final bool needsNativeReview;
}

const _specs = <String, LatamLocaleSpec>{
  'gn': LatamLocaleSpec(
    code: 'gn',
    region: 'PY',
    flag: '🇵🇾',
    label: 'Guaraní',
    boolName: 'Guarani',
    mapName: '_guarani',
    subtitle: 'Guaraní • Paraguay',
    aliasNeedle: 'ava ñe',
  ),
  'qu': LatamLocaleSpec(
    code: 'qu',
    region: 'PE',
    flag: '🇵🇪',
    label: 'Quechua',
    boolName: 'Quechua',
    mapName: '_quechua',
    subtitle: 'Quechua • Peru',
    aliasNeedle: 'runasimi',
  ),
  'ay': LatamLocaleSpec(
    code: 'ay',
    region: 'BO',
    flag: '🇧🇴',
    label: 'Aymara',
    boolName: 'Aymara',
    mapName: '_aymara',
    subtitle: 'Aymara • Bolivia',
    aliasNeedle: 'aymara bolivia',
  ),
  'ht': LatamLocaleSpec(
    code: 'ht',
    region: 'HT',
    flag: '🇭🇹',
    label: 'Kreyòl ayisyen',
    boolName: 'HaitianCreole',
    mapName: '_haitianCreole',
    subtitle: 'Haitian Creole • Haiti',
    aliasNeedle: 'haitian creole',
  ),
};
