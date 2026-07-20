import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification routing static contract', () {
    late final String fcmSource;
    late final String notificationSource;
    late final String backgroundSource;
    late final String mainActivitySource;
    late final String appDelegateSource;

    setUpAll(() {
      fcmSource = File('lib/services/fcm_service.dart').readAsStringSync();
      notificationSource = File(
        'lib/services/notification_service.dart',
      ).readAsStringSync();
      backgroundSource = File(
        'lib/services/platform/android/android_background_notification_service.dart',
      ).readAsStringSync();
      mainActivitySource = File(
        'android/app/src/main/kotlin/com/myfamily/safehome/MainActivity.kt',
      ).readAsStringSync();
      appDelegateSource = File(
        'ios/Runner/AppDelegate.swift',
      ).readAsStringSync();
    });

    test(
      'FCM foreground and opened handlers keep all public payload types',
      () {
        for (final type in [
          'chat',
          'sensor_notification',
          'alarm_resolved',
          'emergency_notification',
          'alarm_detected',
          'alarm',
          'alarm_siren',
          'schedule_notification',
        ]) {
          expect(fcmSource, contains("type == '$type'"));
        }

        expect(fcmSource, contains('FirebaseMessaging.onMessage.listen'));
        expect(
          fcmSource,
          contains('FirebaseMessaging.onMessageOpenedApp.listen'),
        );
        expect(fcmSource, contains('messaging.getInitialMessage()'));
        expect(fcmSource, contains('expectedUid: _activeUid'));
      },
    );

    test('active uid guards remain after async setup gaps', () {
      final guardCount = RegExp(
        r'if \(_activeUid != cleanUid\)',
      ).allMatches(fcmSource).length;

      expect(guardCount, greaterThanOrEqualTo(5));
      expect(
        fcmSource,
        contains('if (activeUid.isEmpty || _activeUid != activeUid)'),
      );
      expect(fcmSource, contains('await _tokenRefreshSubscription?.cancel()'));
    });

    test(
      'local notification tap and cold-start payload routes stay registered',
      () {
        for (final payload in [
          'home_chat::',
          'priority_alarm::',
          'alarm_siren',
          'alarm_summary|',
          'alarm',
          'open_home',
          'schedule_notification',
          'schedule_notification::',
          'schedule_notification|',
        ]) {
          expect(notificationSource, contains(payload));
        }

        expect(
          notificationSource,
          contains('onDidReceiveNotificationResponse'),
        );
        expect(notificationSource, contains('getNotificationAppLaunchDetails'));
        expect(
          notificationSource,
          contains("alarmRouteName = 'fullscreen_alarm'"),
        );
      },
    );

    test('background and native alarm entrypoints remain wired', () {
      expect(
        File(
          'lib/services/platform/firebase_background_message_service.dart',
        ).readAsStringSync(),
        contains('@pragma(\'vm:entry-point\')'),
      );
      expect(backgroundSource, contains('@pragma(\'vm:entry-point\')'));
      expect(backgroundSource, contains('firebaseMessagingBackgroundHandler'));
      expect(backgroundSource, contains('alarm_siren::'));
      expect(backgroundSource, contains('priority_alarm::'));

      for (final value in [
        'alarm_siren',
        'fullscreen_alarm',
        'priority_alarm::',
        'alarm_summary|',
      ]) {
        expect(mainActivitySource, contains(value));
      }

      for (final type in [
        'alarm_detected',
        'alarm',
        'alarm_siren',
        'emergency_notification',
      ]) {
        expect(appDelegateSource, contains(type));
      }
    });
  });

  group('localization and asset static contract', () {
    test('supported locales have one base language file each', () {
      final controllerSource = File(
        'lib/localization/app_language_controller.dart',
      ).readAsStringSync();
      final supportedCodes = _extractSupportedCodes(controllerSource);
      final languageFiles = Directory('lib/localization/languages')
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = _baseName(file.path);
            return name.endsWith('_strings.dart') &&
                !name.endsWith('_dynamic_strings.dart');
          })
          .map((file) => _baseName(file.path).replaceFirst('_strings.dart', ''))
          .toSet();

      expect(supportedCodes, hasLength(57));
      expect(supportedCodes, languageFiles);
    });

    test('pubspec assets and direct Dart asset references exist', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final declaredAssets = RegExp(
        r'^\s+-\s+(assets/[^\r\n]+)\s*$',
        multiLine: true,
      ).allMatches(pubspec).map((match) => match.group(1)!.trim()).toSet();

      expect(declaredAssets, isNotEmpty);
      for (final asset in declaredAssets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }

      final directAssetPattern = RegExp(
        r'''(?:Image\.asset|AssetSource)\(\s*["']([^"']+)["']''',
      );
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final match in directAssetPattern.allMatches(source)) {
          final raw = match.group(1)!;
          final asset = raw.startsWith('assets/') ? raw : 'assets/$raw';
          expect(
            File(asset).existsSync(),
            isTrue,
            reason: '${file.path}: $raw',
          );
        }
      }
    });

    test('native notification resources and method channel names match', () {
      expect(
        File('android/app/src/main/res/raw/alarm_siren.mp3').existsSync(),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/res/drawable/ic_stat_safehome.xml',
        ).existsSync(),
        isTrue,
      );

      final dartChannelFiles = [
        File(
          'lib/services/platform/android/android_alarm_permission_service.dart',
        ),
        File(
          'lib/services/platform/android/android_auto_away_system_service.dart',
        ),
      ];
      final nativeChannel = RegExp(r'private val channelName = "([^"]+)"')
          .firstMatch(
            File(
              'android/app/src/main/kotlin/com/myfamily/safehome/MainActivity.kt',
            ).readAsStringSync(),
          )!
          .group(1);

      for (final file in dartChannelFiles) {
        expect(file.readAsStringSync(), contains("'$nativeChannel'"));
      }

      final entitlements = File(
        'ios/Runner/Runner.entitlements',
      ).readAsStringSync();
      expect(
        entitlements,
        isNot(
          contains('com.apple.developer.usernotifications.critical-alerts'),
        ),
      );
    });
  });
}

Set<String> _extractSupportedCodes(String source) {
  final block = RegExp(
    r'supportedCodes\s*=\s*\{([\s\S]*?)\};',
  ).firstMatch(source)!.group(1)!;

  return RegExp(
    r'"([^"]+)"',
  ).allMatches(block).map((match) => match.group(1)!).toSet();
}

String _baseName(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}
