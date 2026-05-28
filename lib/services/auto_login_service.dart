import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AutoLoginService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _emailKey = "safehome_email";
  static const String _passKey = "safehome_password";

  static Future<void> saveLogin({
    required String email,
    required String password,
  }) async {
    await _storage.write(
      key: _emailKey,
      value: email.trim().toLowerCase(),
    );

    await _storage.write(
      key: _passKey,
      value: password,
    );
  }

  static Future<void> clearLogin() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passKey);
  }

  static Future<User?> tryAutoLogin() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passKey);

    if (email == null || email.isEmpty) return null;
    if (password == null || password.isEmpty) return null;

    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return cred.user;
  }
}