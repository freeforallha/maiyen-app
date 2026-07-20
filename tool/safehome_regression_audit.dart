import 'dart:io';

final _placeholderPattern = RegExp(
  r'\$\{[^}]+\}|\$[A-Za-z_][A-Za-z0-9_]*|\{[A-Za-z_][A-Za-z0-9_]*\}|%[sdif]',
);

Future<void> main() async {
  final errors = <String>[];
  final warnings = <String>[];

  _auditLocalization(errors, warnings);
  _auditAssets(errors, warnings);
  _auditNotificationAndNativeContracts(errors, warnings);
  _auditLifecycleHeuristics(warnings);
  _auditHardcodedUserText(warnings);

  for (final warning in warnings.take(80)) {
    stderr.writeln('WARNING: $warning');
  }
  if (warnings.length > 80) {
    stderr.writeln('WARNING: ${warnings.length - 80} more warnings omitted.');
  }

  for (final error in errors) {
    stderr.writeln('ERROR: $error');
  }

  if (errors.isNotEmpty) {
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'SafeHome regression audit passed with ${warnings.length} warning(s).',
  );
}

void _auditLocalization(List<String> errors, List<String> warnings) {
  final controllerSource = File(
    'lib/localization/app_language_controller.dart',
  ).readAsStringSync();
  final supportedCodes = _extractSupportedCodes(controllerSource);
  final localeCodes = _extractSupportedLocaleCodes(controllerSource);
  final languageDirectory = Directory('lib/localization/languages');
  final baseFiles = <String, File>{};
  final dynamicFiles = <String, File>{};

  for (final file in languageDirectory.listSync().whereType<File>()) {
    final name = _baseName(file.path);

    if (name.endsWith('_dynamic_strings.dart')) {
      dynamicFiles[name.replaceFirst('_dynamic_strings.dart', '')] = file;
      continue;
    }

    if (name.endsWith('_strings.dart')) {
      baseFiles[name.replaceFirst('_strings.dart', '')] = file;
    }
  }

  _expectSetEquals(
    label: 'supported locale codes and supportedCodes',
    left: localeCodes,
    right: supportedCodes,
    errors: errors,
  );
  _expectSetEquals(
    label: 'supported locale codes and base translation files',
    left: supportedCodes,
    right: baseFiles.keys.toSet(),
    errors: errors,
  );

  if (supportedCodes.length != 57) {
    errors.add(
      'Expected 57 supported locale codes, found ${supportedCodes.length}.',
    );
  }

  final requiredKeys = <String>[
    'Báo động',
    'Thông báo',
    'Cài đặt',
    'Báo động toàn màn hình',
    'Thông báo báo động',
    'Cài đặt thông báo',
    'Cảnh báo trên iOS',
    'iOS không mở toàn màn hình như Android; ứng dụng dùng thông báo và âm thanh hệ thống.',
    'Nhắc nhở',
    'Nhắc nhở theo lịch',
  ];
  final parsedBaseMaps = <String, Map<String, String>>{};

  for (final entry in baseFiles.entries) {
    final duplicates = <String>[];
    final values = _parseDartStringMap(
      entry.value.readAsStringSync(),
      duplicates,
    );
    parsedBaseMaps[entry.key] = values;

    if (duplicates.isNotEmpty) {
      errors.add(
        '${entry.value.path} has duplicate keys: ${duplicates.take(8).join(' | ')}',
      );
    }

    for (final requiredKey in requiredKeys) {
      final value = values[requiredKey];

      if (value == null) {
        errors.add('${entry.key} missing required key "$requiredKey".');
      } else if (value.trim().isEmpty) {
        errors.add('${entry.key} has empty value for "$requiredKey".');
      }
    }
  }

  final viMap = parsedBaseMaps['vi'] ?? const <String, String>{};
  for (final entry in parsedBaseMaps.entries) {
    if (entry.key == 'vi') continue;

    for (final key in requiredKeys) {
      final expected = _placeholders(viMap[key] ?? key);
      final actual = _placeholders(entry.value[key] ?? '');

      if (!_sameList(expected, actual)) {
        errors.add(
          '${entry.key} placeholder mismatch for required key "$key": '
          '${expected.join(',')} != ${actual.join(',')}',
        );
      }
    }
  }

  for (final entry in dynamicFiles.entries) {
    final duplicates = <String>[];
    _parseDartStringMap(entry.value.readAsStringSync(), duplicates);

    if (duplicates.isNotEmpty) {
      errors.add(
        '${entry.value.path} has duplicate keys: ${duplicates.take(8).join(' | ')}',
      );
    }

    if (!supportedCodes.contains(entry.key)) {
      errors.add('${entry.value.path} has no supported locale code.');
    }
  }

  final appStringsSource = File(
    'lib/localization/app_strings.dart',
  ).readAsStringSync();
  for (final code in supportedCodes) {
    if (!appStringsSource.contains("is${_localeFlagName(code)}") &&
        !_knownAppStringsNameExceptions.contains(code)) {
      warnings.add(
        'Could not statically match AppStrings bool flag for $code.',
      );
    }
  }
}

void _auditAssets(List<String> errors, List<String> warnings) {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final declaredAssets = RegExp(
    r'^\s+-\s+(assets/[^\r\n]+)\s*$',
    multiLine: true,
  ).allMatches(pubspec).map((match) => match.group(1)!.trim()).toSet();

  for (final asset in declaredAssets) {
    if (!File(asset).existsSync()) {
      errors.add('Declared asset is missing: $asset');
    }
  }

  final dartAssetPattern = RegExp(
    r'''(?:Image\.asset|AssetSource)\(\s*["']([^"']+)["']''',
  );
  for (final file in _dartFiles(Directory('lib'))) {
    final source = file.readAsStringSync();

    for (final match in dartAssetPattern.allMatches(source)) {
      final raw = match.group(1)!;
      final asset = raw.startsWith('assets/') ? raw : 'assets/$raw';

      if (!File(asset).existsSync()) {
        errors.add('Dart asset reference is missing: ${file.path} -> $raw');
      }
    }
  }

  if (!File('android/app/src/main/res/raw/alarm_siren.mp3').existsSync()) {
    errors.add('Android raw alarm sound is missing.');
  }
  if (!File(
    'android/app/src/main/res/drawable/ic_stat_safehome.xml',
  ).existsSync()) {
    errors.add('Android notification icon is missing.');
  }

  final iosConfig = File(
    'lib/services/platform/ios/ios_notification_config.dart',
  ).readAsStringSync();
  if (iosConfig.contains("sound: 'default'")) {
    warnings.add(
      'iOS notification config uses system default sound, no custom iOS sound file to validate.',
    );
  }
}

void _auditNotificationAndNativeContracts(
  List<String> errors,
  List<String> warnings,
) {
  final platformBootstrap = File(
    'lib/services/platform/platform_bootstrap_service.dart',
  ).readAsStringSync();
  final fcmSource = File('lib/services/fcm_service.dart').readAsStringSync();
  final notificationSource = File(
    'lib/services/notification_service.dart',
  ).readAsStringSync();
  final androidConfig = File(
    'lib/services/platform/android/android_notification_config.dart',
  ).readAsStringSync();
  final androidBackground = File(
    'lib/services/platform/android/android_background_notification_service.dart',
  ).readAsStringSync();
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final mainActivity = File(
    'android/app/src/main/kotlin/com/myfamily/safehome/MainActivity.kt',
  ).readAsStringSync();
  final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final entitlements = File(
    'ios/Runner/Runner.entitlements',
  ).readAsStringSync();

  for (final token in [
    'FirebaseMessaging.onBackgroundMessage',
    'FirebaseMessaging.onMessage.listen',
    'FirebaseMessaging.onMessageOpenedApp.listen',
    'getInitialMessage()',
    'onDidReceiveNotificationResponse',
    'getNotificationAppLaunchDetails',
    '@pragma(\'vm:entry-point\')',
    'safehome/native_alarm_permission',
    'fullscreen_alarm',
  ]) {
    final combined =
        '$platformBootstrap\n$fcmSource\n$notificationSource\n$androidBackground\n$mainActivity';
    if (!combined.contains(token)) {
      errors.add('Notification/native contract token missing: $token');
    }
  }

  for (final type in [
    'alarm_siren',
    'priority_alarm',
    'alarm_summary',
    'schedule_notification',
    'reminder',
    'chat',
    'sensor_notification',
    'alarm_resolved',
  ]) {
    final combined = '$fcmSource\n$notificationSource\n$androidBackground';
    if (!combined.contains(type)) {
      errors.add('Payload type/prefix missing from frontend contract: $type');
    }
  }

  final activeUidGuards = RegExp(
    r'if \(_activeUid != cleanUid\)',
  ).allMatches(fcmSource).length;
  if (activeUidGuards < 5) {
    errors.add(
      'Expected at least 5 _activeUid async guards, found $activeUidGuards.',
    );
  }

  final channelIds = RegExp(
    r"static const [A-Za-z0-9_]+ChannelId = '([^']+)'",
  ).allMatches(androidConfig).map((match) => match.group(1)!).toSet();
  final defaultChannel = RegExp(
    r'com\.google\.firebase\.messaging\.default_notification_channel_id"[\s\S]*?android:value="([^"]+)"',
  ).firstMatch(manifest)?.group(1);

  if (defaultChannel == null || defaultChannel.isEmpty) {
    errors.add('Android default FCM channel is missing.');
  } else if (!channelIds.contains(defaultChannel)) {
    warnings.add(
      'AndroidManifest default FCM channel "$defaultChannel" is not declared in AndroidNotificationConfig; kept as report-only.',
    );
  }

  final nativeChannel = RegExp(
    r'private val channelName = "([^"]+)"',
  ).firstMatch(mainActivity)?.group(1);
  final dartChannels = RegExp(r"MethodChannel\(\s*'([^']+)'")
      .allMatches(
        File(
              'lib/services/platform/android/android_alarm_permission_service.dart',
            ).readAsStringSync() +
            File(
              'lib/services/platform/android/android_auto_away_system_service.dart',
            ).readAsStringSync(),
      )
      .map((match) => match.group(1))
      .toSet();

  if (nativeChannel == null || !dartChannels.contains(nativeChannel)) {
    errors.add(
      'Dart/native MethodChannel mismatch for Android alarm permission.',
    );
  }

  if (entitlements.contains(
    'com.apple.developer.usernotifications.critical-alerts',
  )) {
    errors.add(
      'Critical Alerts entitlement is present, but this audit expects it to remain absent.',
    );
  }
  if (!infoPlist.contains('<string>remote-notification</string>')) {
    errors.add(
      'iOS Info.plist remote-notification background mode is missing.',
    );
  }
  if (!appDelegate.contains(
    'UNUserNotificationCenter.current().delegate = self',
  )) {
    errors.add('iOS AppDelegate notification delegate hookup is missing.');
  }

  _warnDuplicateXmlKeys(
    'AndroidManifest',
    manifest,
    r'android:name="([^"]+)"',
    warnings,
  );
  _warnDuplicateXmlKeys(
    'Info.plist',
    infoPlist,
    r'<key>([^<]+)</key>',
    warnings,
  );
}

void _auditLifecycleHeuristics(List<String> warnings) {
  for (final file in _dartFiles(Directory('lib'))) {
    final source = file.readAsStringSync();
    final path = file.path;

    if (source.contains('TextEditingController') &&
        !source.contains('.dispose()')) {
      warnings.add(
        'Lifecycle check: TextEditingController without obvious dispose in $path',
      );
    }
    if (source.contains('AnimationController') &&
        !source.contains('.dispose()') &&
        !source.contains('controller.dispose')) {
      warnings.add(
        'Lifecycle check: AnimationController without obvious dispose in $path',
      );
    }
    if ((source.contains('Timer(') || source.contains('Timer.periodic')) &&
        !source.contains('.cancel()')) {
      warnings.add('Lifecycle check: Timer without obvious cancel in $path');
    }
    if (source.contains('addObserver(this)') &&
        !source.contains('removeObserver(this)')) {
      warnings.add(
        'Lifecycle check: observer without obvious removeObserver in $path',
      );
    }
    if (source.contains('StreamSubscription') &&
        !source.contains('.cancel()')) {
      warnings.add(
        'Lifecycle check: StreamSubscription without obvious cancel in $path',
      );
    }
  }
}

void _auditHardcodedUserText(List<String> warnings) {
  final textPattern = RegExp(r'''["']([^"'\n]*[À-ỹ][^"'\n]*)["']''');
  final allowPattern = RegExp(
    r"strings\.t\(|choose\(|safeDebugPrint|Exception\(|Firebase|ref\(|payload|type|status|reason|event|debug|ERROR|WARNING",
  );
  var reported = 0;

  for (final file in _dartFiles(Directory('lib'))) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    if (normalizedPath.contains('/localization/') ||
        normalizedPath.endsWith('/helpers/home_helper.dart')) {
      continue;
    }

    final source = file.readAsStringSync();
    final lines = source.split('\n');

    for (var index = 0; index < lines.length; index++) {
      if (reported >= 30) return;

      final line = lines[index];
      final contextWindow = [
        for (var previous = index - 30; previous < index; previous++)
          if (previous >= 0) lines[previous],
        line,
        if (index + 1 < lines.length) lines[index + 1],
      ].join(' ');

      if (allowPattern.hasMatch(contextWindow)) continue;

      final match = textPattern.firstMatch(line);
      if (match != null) {
        warnings.add(
          'Possible hardcoded user-facing text: ${file.path}:${index + 1}: ${match.group(1)}',
        );
        reported++;
      }
    }
  }
}

Set<String> _extractSupportedCodes(String source) {
  final block = RegExp(
    r'supportedCodes\s*=\s*\{([\s\S]*?)\};',
  ).firstMatch(source)?.group(1);

  if (block == null) return const {};

  return RegExp(
    r'"([^"]+)"',
  ).allMatches(block).map((match) => match.group(1)!).toSet();
}

Set<String> _extractSupportedLocaleCodes(String source) {
  final block = RegExp(
    r'supportedLocales\s*=\s*\[([\s\S]*?)\];',
  ).firstMatch(source)?.group(1);

  if (block == null) return const {};

  return RegExp(
    r'Locale\("([^"]+)"',
  ).allMatches(block).map((match) => match.group(1)!).toSet();
}

Map<String, String> _parseDartStringMap(
  String source,
  List<String> duplicates,
) {
  final values = <String, String>{};
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

  return values;
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

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }

  return true;
}

void _expectSetEquals({
  required String label,
  required Set<String> left,
  required Set<String> right,
  required List<String> errors,
}) {
  final missing = left.difference(right);
  final extra = right.difference(left);

  if (missing.isNotEmpty || extra.isNotEmpty) {
    errors.add(
      '$label mismatch. Missing: ${missing.join(', ')}. Extra: ${extra.join(', ')}.',
    );
  }
}

void _warnDuplicateXmlKeys(
  String label,
  String source,
  String pattern,
  List<String> warnings,
) {
  final seen = <String>{};
  final duplicates = <String>{};

  for (final match in RegExp(pattern).allMatches(source)) {
    final key = match.group(1)!;
    if (!seen.add(key)) {
      duplicates.add(key);
    }
  }

  if (duplicates.isNotEmpty) {
    warnings.add('$label has duplicate declarations: ${duplicates.join(', ')}');
  }
}

Iterable<File> _dartFiles(Directory directory) {
  if (!directory.existsSync()) return const Iterable<File>.empty();

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

String _baseName(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}

String _localeFlagName(String code) {
  return switch (code) {
    'en' => 'English',
    'zh' => 'Chinese',
    'ko' => 'Korean',
    'ja' => 'Japanese',
    'de' => 'German',
    'ru' => 'Russian',
    'fr' => 'French',
    'es' => 'Spanish',
    'id' => 'Indonesian',
    'th' => 'Thai',
    'ms' => 'Malay',
    'fil' => 'Filipino',
    'km' => 'Khmer',
    'my' => 'Burmese',
    'lo' => 'Lao',
    'ta' => 'Tamil',
    'pt' => 'Portuguese',
    'tet' => 'Tetum',
    'it' => 'Italian',
    'pl' => 'Polish',
    'nl' => 'Dutch',
    'cs' => 'Czech',
    'sk' => 'Slovak',
    'uk' => 'Ukrainian',
    'ro' => 'Romanian',
    'hu' => 'Hungarian',
    'bg' => 'Bulgarian',
    'hr' => 'Croatian',
    'sr' => 'Serbian',
    'bs' => 'Bosnian',
    'sl' => 'Slovenian',
    'mk' => 'Macedonian',
    'sq' => 'Albanian',
    'el' => 'Greek',
    'tr' => 'Turkish',
    'sv' => 'Swedish',
    'da' => 'Danish',
    'nb' => 'NorwegianBokmal',
    'fi' => 'Finnish',
    'is' => 'Icelandic',
    'et' => 'Estonian',
    'lv' => 'Latvian',
    'lt' => 'Lithuanian',
    'ga' => 'Irish',
    'mt' => 'Maltese',
    'be' => 'Belarusian',
    'lb' => 'Luxembourgish',
    'ca' => 'Catalan',
    'cnr' => 'Montenegrin',
    'hy' => 'Armenian',
    'ka' => 'Georgian',
    'az' => 'Azerbaijani',
    'gn' => 'Guarani',
    'qu' => 'Quechua',
    'ay' => 'Aymara',
    'ht' => 'HaitianCreole',
    _ => '',
  };
}

const _knownAppStringsNameExceptions = {'vi'};

class _ReadString {
  const _ReadString(this.value, this.end);

  final String value;
  final int end;
}
