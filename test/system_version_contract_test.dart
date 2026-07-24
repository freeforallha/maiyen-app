import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:safehome_app/config/system_version.dart';
import 'package:safehome_app/localization/app_strings.dart';
import 'package:safehome_app/localization/system_version_strings.dart';

void main() {
  test('pubspec and runtime app versions stay synchronized', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      pubspec,
      contains('version: ${SystemVersionConfig.appVersionDisplay}'),
    );
    expect(SystemVersionConfig.appVersionName, '1.1.0');
    expect(SystemVersionConfig.appBuildNumber, 2);
  });

  test('protocol compatibility is based on the protocol major version', () {
    expect(
      SystemVersionConfig.protocolCompatibility('1.0.0'),
      ProtocolCompatibility.compatible,
    );
    expect(
      SystemVersionConfig.protocolCompatibility('1.9.4'),
      ProtocolCompatibility.compatible,
    );
    expect(
      SystemVersionConfig.protocolCompatibility('2.0.0'),
      ProtocolCompatibility.incompatible,
    );
    expect(
      SystemVersionConfig.protocolCompatibility(''),
      ProtocolCompatibility.unknown,
    );
    expect(
      SystemVersionConfig.protocolCompatibility('invalid'),
      ProtocolCompatibility.unknown,
    );
  });

  test('Hub version payload is parsed safely', () {
    final info = HubSystemVersionInfo.fromHubStatus({
      'backendVersion': '1.1.0',
      'hubFirmwareVersion': '1.0.0',
      'protocolVersion': '1.0.0',
      'versionSchemaVersion': 1,
    });

    expect(info.backendVersion, '1.1.0');
    expect(info.hubFirmwareVersion, '1.0.0');
    expect(info.protocolVersion, '1.0.0');
    expect(info.versionSchemaVersion, 1);
    expect(info.compatibility, ProtocolCompatibility.compatible);
  });

  test('system version labels are available for all 53 locales', () {
    const languageCodes = <String>[
      'vi', 'en', 'zh', 'ko', 'ja', 'de', 'ru', 'fr', 'es', 'id',
      'th', 'ms', 'fil', 'km', 'my', 'lo', 'ta', 'pt', 'tet', 'it',
      'pl', 'nl', 'cs', 'sk', 'uk', 'ro', 'hu', 'bg', 'hr', 'sr',
      'bs', 'sl', 'mk', 'sq', 'el', 'tr', 'sv', 'da', 'nb', 'fi',
      'is', 'et', 'lv', 'lt', 'ga', 'mt', 'be', 'lb', 'ca', 'cnr',
      'hy', 'ka', 'az',
    ];

    for (final code in languageCodes) {
      final strings = AppStrings.fromLocale(Locale(code));
      final values = <String>[
        strings.systemVersionsTitle,
        strings.appVersionLabel,
        strings.backendVersionLabel,
        strings.hubFirmwareVersionLabel,
        strings.protocolVersionLabel,
        strings.protocolCompatibilityLabel,
        strings.protocolCompatibleText,
        strings.protocolIncompatibleText,
      ];

      expect(
        values.every((value) => value.trim().isNotEmpty),
        isTrue,
        reason: 'Missing version localization for $code',
      );
    }
  });
}
