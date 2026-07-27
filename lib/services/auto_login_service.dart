import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/legacy_identifiers.dart';

class AutoLoginService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _emailKey =
      MaiYenLegacyIdentifiers.loginEmailStorageKey;

  // Chỉ dùng để xoá mật khẩu do các bản app cũ từng lưu.
  static const String _legacyPasswordKey =
      MaiYenLegacyIdentifiers.legacyPasswordStorageKey;

  static Future<void> saveLogin({required String email}) async {
    await _storage.write(key: _emailKey, value: email.trim().toLowerCase());

    await removeLegacyPassword();
  }

  static Future<void> clearLogin() async {
    await _storage.delete(key: _emailKey);
    await removeLegacyPassword();
  }

  static Future<Map<String, String?>> loadSavedLogin() async {
    await removeLegacyPassword();

    return {"email": await _storage.read(key: _emailKey)};
  }

  static Future<void> removeLegacyPassword() async {
    await _storage.delete(key: _legacyPasswordKey);
  }
}
