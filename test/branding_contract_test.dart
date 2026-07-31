import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maiyen_app/config/brand_config.dart';

void main() {
  test('MaiYen display branding contract stays compatible', () {
    expect(BrandConfig.appName, 'MaiYen');
    expect(BrandConfig.appNameUppercase, 'MAIYEN');
    expect(BrandConfig.sloganVi, 'Vẹn nguyên tổ ấm');
    expect(BrandConfig.defaultHubName, 'MaiYen Hub');
    expect(BrandConfig.mapUserAgent, 'MaiYen/1.1.0 (com.myfamily.maiyen)');

    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));

    final androidStrings = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    expect(androidStrings, contains('>MaiYen</string>'));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, contains('<string>MaiYen</string>'));

    final mapPage = File(
      'lib/pages/home/home_auto_away_map_page.dart',
    ).readAsStringSync();
    expect(mapPage, contains('BrandConfig.mapUserAgent'));
    expect(mapPage, isNot(contains("'SafeHome/1.0")));

    expect(
      File(
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).existsSync(),
      isTrue,
    );
  });
}
