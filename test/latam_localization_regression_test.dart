import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safehome_app/localization/app_language_controller.dart';

const _removedCodes = {'gn', 'qu', 'ay', 'ht'};
const _removedLanguageNames = {
  'Guaraní',
  'Quechua',
  'Aymara',
  'Kreyòl ayisyen',
  'Haitian Creole',
};
const _requiredKeys = {
  'Báo động',
  'Thông báo',
  'Cài đặt',
  'Báo động toàn màn hình',
  'Thông báo báo động',
  'Nhắc nhở',
  'Không có kết quả',
  'Đăng nhập',
  'Đăng xuất',
};

final _placeholderPattern = RegExp(
  r'\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\}|%[sdif]',
);

void main() {
  group('stable frontend localization regression', () {
    test('frontend registers exactly 53 aligned unique locales', () {
      final codes = AppLanguageController.supportedCodes;
      final locales = AppLanguageController.supportedLocales;
      final localeCodes = locales
          .map((locale) => locale.languageCode)
          .toList(growable: false);
      final controllerSource = File(
        'lib/localization/app_language_controller.dart',
      ).readAsStringSync();
      final declaredCodes = _extractDeclaredCodes(controllerSource);

      expect(codes, hasLength(53));
      expect(locales, hasLength(53));
      expect(declaredCodes, hasLength(53));
      expect(declaredCodes.toSet(), hasLength(declaredCodes.length));
      expect(localeCodes.toSet(), hasLength(localeCodes.length));
      expect(localeCodes, unorderedEquals(codes));
      expect(AppLanguageController.languageFlags.keys, unorderedEquals(codes));
      expect(AppLanguageController.languageLabels.keys, unorderedEquals(codes));
      expect(
        AppLanguageController.languageFlags.values,
        everyElement(isNot(isEmpty)),
      );
      expect(
        AppLanguageController.languageLabels.values,
        everyElement(isNot(isEmpty)),
      );
      expect(codes.intersection(_removedCodes), isEmpty);
    });

    test('removed locale files and registrations stay absent', () {
      for (final code in _removedCodes) {
        expect(
          File('lib/localization/languages/${code}_strings.dart').existsSync(),
          isFalse,
        );
        expect(
          File(
            'lib/localization/languages/${code}_dynamic_strings.dart',
          ).existsSync(),
          isFalse,
        );
      }

      final surfaceSource = [
        'lib/localization/app_language_controller.dart',
        'lib/localization/app_strings.dart',
        'lib/pages/login_page.dart',
        'lib/sheets/settings_sheet.dart',
        'lib/services/platform/android/android_background_notification_service.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');

      for (final code in _removedCodes) {
        expect(surfaceSource, isNot(contains('"$code"')));
        expect(surfaceSource, isNot(contains("'$code'")));
        expect(surfaceSource, isNot(contains('/${code}_strings.dart')));
        expect(surfaceSource, isNot(contains('/${code}_dynamic_strings.dart')));
      }
      for (final name in _removedLanguageNames) {
        expect(surfaceSource, isNot(contains(name)));
      }
    });

    test('all 53 base maps retain keys, placeholders, and required values', () {
      final files = _translationFiles(dynamic: false);
      final codes = files.map(_localeCodeForFile).toList(growable: false);
      final reference = _parseMapFile(
        File('lib/localization/languages/vi_strings.dart'),
      );

      expect(files, hasLength(53));
      expect(codes, unorderedEquals(AppLanguageController.supportedCodes));
      expect(reference.duplicates, isEmpty);

      for (final file in files) {
        final code = _localeCodeForFile(file);
        final parsed = _parseMapFile(file);

        expect(
          parsed.duplicates,
          isEmpty,
          reason: '${file.path} contains duplicate keys',
        );
        expect(
          parsed.values.keys,
          unorderedEquals(reference.values.keys),
          reason: '$code base key set differs from Vietnamese',
        );

        for (final key in reference.values.keys) {
          expect(
            _placeholders(parsed.values[key] ?? ''),
            _placeholders(reference.values[key] ?? ''),
            reason: '$code placeholder mismatch for "$key"',
          );
        }
        for (final key in _requiredKeys) {
          expect(
            parsed.values[key]?.trim(),
            isNot(isEmpty),
            reason: '$code has an empty required value for "$key"',
          );
        }
      }
    });

    test('stable dynamic maps retain keys and placeholders', () {
      final files = _translationFiles(dynamic: true);
      final reference = _parseMapFile(
        File('lib/localization/languages/az_dynamic_strings.dart'),
      );

      expect(reference.duplicates, isEmpty);
      for (final file in files) {
        final code = _localeCodeForFile(file);
        final parsed = _parseMapFile(file);

        expect(
          AppLanguageController.supportedCodes,
          contains(code),
          reason: '${file.path} has no supported locale',
        );
        expect(
          parsed.duplicates,
          isEmpty,
          reason: '${file.path} contains duplicate keys',
        );
        expect(
          parsed.values.keys,
          everyElement(isIn(reference.values.keys)),
          reason: '$code dynamic map contains an unknown key',
        );
        expect(
          parsed.values.values.map((value) => value.trim()),
          everyElement(isNot(isEmpty)),
          reason: '$code dynamic map contains an empty value',
        );

        for (final key in parsed.values.keys) {
          expect(
            _placeholders(parsed.values[key] ?? ''),
            _placeholders(reference.values[key] ?? ''),
            reason: '$code dynamic placeholder mismatch for "$key"',
          );
        }
      }
    });
  });
}

List<String> _extractDeclaredCodes(String source) {
  final block = RegExp(
    r'supportedCodes\s*=\s*\{([\s\S]*?)\};',
  ).firstMatch(source)?.group(1);
  if (block == null) return const [];

  return RegExp(
    r'"([^"]+)"',
  ).allMatches(block).map((match) => match.group(1)!).toList();
}

List<File> _translationFiles({required bool dynamic}) {
  final suffix = dynamic ? '_dynamic_strings.dart' : '_strings.dart';
  final files = Directory('lib/localization/languages')
      .listSync()
      .whereType<File>()
      .where((file) {
        final name = _baseName(file.path);
        return name.endsWith(suffix) &&
            (dynamic || !name.endsWith('_dynamic_strings.dart'));
      })
      .toList(growable: false);
  files.sort((left, right) => left.path.compareTo(right.path));
  return files;
}

String _localeCodeForFile(File file) {
  return _baseName(
    file.path,
  ).replaceFirst('_dynamic_strings.dart', '').replaceFirst('_strings.dart', '');
}

String _baseName(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}

_ParsedMap _parseMapFile(File file) {
  final source = file.readAsStringSync();
  final values = <String, String>{};
  final duplicates = <String>[];
  var index = 0;

  while (index < source.length) {
    final key = _readStringAt(source, index);
    if (key == null) {
      index++;
      continue;
    }

    var cursor = _skipWhitespace(source, key.end);
    if (cursor >= source.length || source[cursor] != ':') {
      index = key.end;
      continue;
    }

    cursor = _skipWhitespace(source, cursor + 1);
    final value = _readConcatenatedString(source, cursor);
    if (value == null) {
      index = cursor;
      continue;
    }

    if (values.containsKey(key.value)) {
      duplicates.add(key.value);
    }
    values[key.value] = value.value;
    index = value.end;
  }

  return _ParsedMap(values, duplicates);
}

_ReadString? _readConcatenatedString(String source, int start) {
  var cursor = start;
  final buffer = StringBuffer();
  var readAny = false;

  while (cursor < source.length) {
    cursor = _skipWhitespace(source, cursor);
    final value = _readStringAt(source, cursor);
    if (value == null) break;

    buffer.write(value.value);
    cursor = value.end;
    readAny = true;
  }

  return readAny ? _ReadString(buffer.toString(), cursor) : null;
}

_ReadString? _readStringAt(String source, int start) {
  if (start >= source.length) return null;

  final quote = source[start];
  if (quote != '"' && quote != "'") return null;

  final triple =
      start + 2 < source.length &&
      source[start + 1] == quote &&
      source[start + 2] == quote;
  final contentStart = triple ? start + 3 : start + 1;
  final buffer = StringBuffer();
  var escaped = false;

  for (var index = contentStart; index < source.length; index++) {
    final char = source[index];

    if (escaped) {
      buffer.write(switch (char) {
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        _ => char,
      });
      escaped = false;
      continue;
    }

    if (char == '\\') {
      escaped = true;
      continue;
    }

    if (triple) {
      if (index + 2 < source.length &&
          char == quote &&
          source[index + 1] == quote &&
          source[index + 2] == quote) {
        return _ReadString(buffer.toString(), index + 3);
      }
    } else if (char == quote) {
      return _ReadString(buffer.toString(), index + 1);
    }

    buffer.write(char);
  }

  return null;
}

int _skipWhitespace(String source, int start) {
  var cursor = start;
  while (cursor < source.length) {
    final codeUnit = source.codeUnitAt(cursor);
    if (codeUnit != 0x20 &&
        codeUnit != 0x09 &&
        codeUnit != 0x0A &&
        codeUnit != 0x0D) {
      break;
    }
    cursor++;
  }
  return cursor;
}

List<String> _placeholders(String value) {
  final placeholders = _placeholderPattern
      .allMatches(value)
      .map((match) => match.group(0)!)
      .toList();
  placeholders.sort();
  return placeholders;
}

class _ParsedMap {
  const _ParsedMap(this.values, this.duplicates);

  final Map<String, String> values;
  final List<String> duplicates;
}

class _ReadString {
  const _ReadString(this.value, this.end);

  final String value;
  final int end;
}
