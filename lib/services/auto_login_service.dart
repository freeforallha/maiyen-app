import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/maiyen_identifiers.dart';

class AutoLoginService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _emailKey = MaiYenIdentifiers.loginEmailStorageKey;

  static Future<void> saveLogin({required String email}) async {
    await _storage.write(key: _emailKey, value: email.trim().toLowerCase());
  }

  static Future<void> clearLogin() async {
    await _storage.delete(key: _emailKey);
  }

  static Future<Map<String, String?>> loadSavedLogin() async {
    return {'email': await _storage.read(key: _emailKey)};
  }
}
