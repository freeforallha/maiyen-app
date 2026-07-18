import 'dart:io';

import 'package:safehome_app/localization/languages/de_strings.dart';
import 'package:safehome_app/localization/languages/en_strings.dart';
import 'package:safehome_app/localization/languages/es_strings.dart';
import 'package:safehome_app/localization/languages/fil_strings.dart';
import 'package:safehome_app/localization/languages/fr_strings.dart';
import 'package:safehome_app/localization/languages/id_strings.dart';
import 'package:safehome_app/localization/languages/ja_strings.dart';
import 'package:safehome_app/localization/languages/km_strings.dart';
import 'package:safehome_app/localization/languages/ko_strings.dart';
import 'package:safehome_app/localization/languages/lo_strings.dart';
import 'package:safehome_app/localization/languages/ms_strings.dart';
import 'package:safehome_app/localization/languages/my_strings.dart';
import 'package:safehome_app/localization/languages/pt_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/pt_strings.dart';
import 'package:safehome_app/localization/languages/ru_strings.dart';
import 'package:safehome_app/localization/languages/ta_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/ta_strings.dart';
import 'package:safehome_app/localization/languages/tet_dynamic_strings.dart';
import 'package:safehome_app/localization/languages/tet_strings.dart';
import 'package:safehome_app/localization/languages/th_strings.dart';
import 'package:safehome_app/localization/languages/vi_strings.dart';
import 'package:safehome_app/localization/languages/zh_strings.dart';

const _maps = <String, Map<String, String>>{
  'vi': viStrings,
  'en': enStrings,
  'zh': zhStrings,
  'ko': koStrings,
  'ja': jaStrings,
  'de': deStrings,
  'ru': ruStrings,
  'fr': frStrings,
  'es': esStrings,
  'id': idStrings,
  'th': thStrings,
  'ms': msStrings,
  'fil': filStrings,
  'km': kmStrings,
  'my': myStrings,
  'lo': loStrings,
  'ta': taStrings,
  'pt': ptStrings,
  'tet': tetStrings,
};

const _dynamicMaps = <String, Map<String, String>>{
  'ta': taDynamicStrings,
  'pt': ptDynamicStrings,
  'tet': tetDynamicStrings,
};

final _placeholderPattern = RegExp(
  r'\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\}|%[sdif]',
);
final _obviousVietnamesePattern = RegExp(
  r'(^|\s)(không|đang|được|thiết bị|nhà|báo động|cảnh báo|chưa|tài khoản|người dùng|vị trí|mật khẩu|chủ nhà|nhắc nhở)(\s|$)',
  caseSensitive: false,
);

Future<void> main() async {
  final errors = <String>[];
  final warnings = <String>[];
  final referenceKeys = viStrings.keys.toSet();
  final languageDirectory = Directory('lib/localization/languages');
  final files = languageDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('_strings.dart'))
      .where((file) => !file.path.endsWith('_dynamic_strings.dart'))
      .toList(growable: false);
  final fileCodes = files
      .map(
        (file) => file.uri.pathSegments.last.replaceFirst('_strings.dart', ''),
      )
      .toSet();
  final registeredCodes = _maps.keys.toSet();

  for (final code in registeredCodes.difference(fileCodes)) {
    errors.add('$code is registered but has no translation file');
  }
  for (final code in fileCodes.difference(registeredCodes)) {
    errors.add('$code has a translation file but is not registered in audit');
  }

  for (final entry in _maps.entries) {
    final code = entry.key;
    final translations = entry.value;
    final keys = translations.keys.toSet();
    final missing = referenceKeys.difference(keys);
    final extra = keys.difference(referenceKeys);

    if (missing.isNotEmpty) {
      errors.add(
        '$code is missing ${missing.length} keys: ${missing.take(8).join(' | ')}',
      );
    }
    if (extra.isNotEmpty) {
      errors.add(
        '$code has ${extra.length} extra keys: ${extra.take(8).join(' | ')}',
      );
    }

    for (final key in referenceKeys.intersection(keys)) {
      final expected = _placeholders(viStrings[key]!);
      final actual = _placeholders(translations[key]!);
      if (!_sameList(expected, actual)) {
        errors.add(
          '$code placeholder mismatch for "$key": '
          '${expected.join(',')} != ${actual.join(',')}',
        );
      }
    }

    if (code != 'vi') {
      final suspicious = translations.entries
          .where((item) {
            return _obviousVietnamesePattern.hasMatch(item.value) &&
                !item.value.contains('SafeHome');
          })
          .toList(growable: false);
      if (suspicious.isNotEmpty) {
        warnings.add(
          '$code has ${suspicious.length} values with Vietnamese characters: '
          '${suspicious.take(5).map((item) => item.key).join(' | ')}',
        );
      }

      final untranslatedVietnamese = translations.entries
          .where((item) {
            return item.value == viStrings[item.key] &&
                _obviousVietnamesePattern.hasMatch(item.value);
          })
          .toList(growable: false);
      if (untranslatedVietnamese.isNotEmpty) {
        warnings.add(
          '$code has ${untranslatedVietnamese.length} values identical to Vietnamese: '
          '${untranslatedVietnamese.take(5).map((item) => item.key).join(' | ')}',
        );
      }

      if (const {'de', 'ru', 'fr', 'es'}.contains(code)) {
        final untranslatedEnglish = translations.entries
            .where((item) {
              final english = enStrings[item.key];
              return item.value == english &&
                  english != null &&
                  !_isTechnicalOnly(english) &&
                  !_isCommonCrossLanguageTerm(english);
            })
            .toList(growable: false);
        if (untranslatedEnglish.isNotEmpty) {
          warnings.add(
            '$code has ${untranslatedEnglish.length} values identical to English: '
            '${untranslatedEnglish.take(5).map((item) => item.key).join(' | ')}',
          );
        }
      }
    }

    stdout.writeln('$code: ${translations.length} keys');
  }

  final dynamicReference = await _dynamicReferenceStrings();
  final dynamicKeys = dynamicReference.keys.toSet();
  for (final entry in _dynamicMaps.entries) {
    final code = entry.key;
    final translations = entry.value;
    final keys = translations.keys.toSet();
    final missing = dynamicKeys.difference(keys);
    final extra = keys.difference(dynamicKeys);

    if (missing.isNotEmpty) {
      errors.add(
        '$code dynamic strings are missing ${missing.length} keys: '
        '${missing.take(8).join(' | ')}',
      );
    }
    if (extra.isNotEmpty) {
      errors.add(
        '$code dynamic strings have ${extra.length} extra keys: '
        '${extra.take(8).join(' | ')}',
      );
    }

    for (final key in dynamicKeys.intersection(keys)) {
      final expected = _placeholders(dynamicReference[key]!);
      final actual = _placeholders(translations[key]!);
      if (!_sameList(expected, actual)) {
        errors.add(
          '$code dynamic placeholder mismatch for "$key": '
          '${expected.join(',')} != ${actual.join(',')}',
        );
      }
    }

    stdout.writeln('$code dynamic: ${translations.length} keys');
  }

  for (final file in files) {
    final source = await file.readAsString();
    final keyPattern = RegExp(r'^\s*"((?:\\.|[^"\\])*)"\s*:', multiLine: true);
    final seen = <String>{};
    final duplicates = <String>[];
    for (final match in keyPattern.allMatches(source)) {
      final rawKey = match.group(1)!;
      if (!seen.add(rawKey)) {
        duplicates.add(rawKey);
      }
    }
    if (duplicates.isNotEmpty) {
      errors.add(
        '${file.path} has duplicate keys: ${duplicates.take(8).join(' | ')}',
      );
    }
  }

  for (final warning in warnings) {
    stderr.writeln('WARNING: $warning');
  }
  for (final error in errors) {
    stderr.writeln('ERROR: $error');
  }

  if (errors.isNotEmpty) {
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Localization audit passed for ${_maps.length} locales and '
    '${viStrings.length} reference keys, plus '
    '${dynamicReference.length} dynamic templates.',
  );
}

Future<Map<String, String>> _dynamicReferenceStrings() async {
  final source = await File('lib/localization/app_strings.dart').readAsString();
  final values = <String, String>{};
  final marker = RegExp(r'\bvi\s*:');

  for (final match in marker.allMatches(source)) {
    var cursor = match.end;
    while (cursor < source.length && _isWhitespace(source.codeUnitAt(cursor))) {
      cursor++;
    }
    final value = _readDartString(source, cursor);
    if (value != null &&
        value.trim().isNotEmpty &&
        !viStrings.containsKey(value)) {
      values[value] = value;
    }
  }
  return values;
}

String? _readDartString(String source, int start) {
  if (start >= source.length ||
      (source[start] != '"' && source[start] != "'")) {
    return null;
  }

  final quote = source[start];
  final buffer = StringBuffer();
  var escaped = false;
  for (var index = start + 1; index < source.length; index++) {
    final char = source[index];
    if (escaped) {
      buffer.write(switch (char) {
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        _ => char,
      });
      escaped = false;
    } else if (char == '\\') {
      escaped = true;
    } else if (char == quote) {
      return buffer.toString();
    } else {
      buffer.write(char);
    }
  }
  return null;
}

bool _isWhitespace(int codeUnit) {
  return codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D;
}

List<String> _placeholders(String value) {
  final placeholders = _placeholderPattern
      .allMatches(value)
      .map((match) => match.group(0)!)
      .toList();
  placeholders.sort();
  return placeholders;
}

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _isTechnicalOnly(String value) {
  final stripped = value
      .replaceAll(
        RegExp(
          r'SafeHome|Firebase|Zigbee|Wi-Fi|MQTT|FCM|PM2\.5|CO₂|CO|UPS|SOS|QR|UID|Camera|Admin',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'[^A-Za-z]'), '');
  return stripped.isEmpty;
}

bool _isCommonCrossLanguageTerm(String value) {
  return const {
    'OK',
    'Email',
    'Alarm',
    'Notifications',
    'Notification',
    'Liste de notifications',
    'No',
    'Personal',
  }.contains(value);
}
