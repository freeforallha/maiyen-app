import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InstallationIdService {
  const InstallationIdService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Giữ nguyên key cũ để FCM token và session cùng nhận diện
  // đúng một bản cài đặt ứng dụng trên thiết bị.
  static const String _installationIdKey =
      'safehome_fcm_installation_id';

  static String _cachedInstallationId = '';
  static Future<String>? _pendingInstallationId;

  static Future<String> getOrCreate() {
    final cached = _cachedInstallationId.trim();

    if (cached.isNotEmpty) {
      return Future<String>.value(cached);
    }

    final pending = _pendingInstallationId;

    if (pending != null) {
      return pending;
    }

    final future = _loadOrCreate();
    _pendingInstallationId = future;

    return future.whenComplete(() {
      _pendingInstallationId = null;
    });
  }

  static Future<String> _loadOrCreate() async {
    final saved = await _storage.read(
      key: _installationIdKey,
    );

    final cleanSaved = saved?.trim() ?? '';

    if (cleanSaved.isNotEmpty) {
      _cachedInstallationId = cleanSaved;
      return cleanSaved;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    final installationId = bytes
        .map(
          (value) => value.toRadixString(16).padLeft(2, '0'),
    )
        .join();

    await _storage.write(
      key: _installationIdKey,
      value: installationId,
    );

    _cachedInstallationId = installationId;
    return installationId;
  }
}
