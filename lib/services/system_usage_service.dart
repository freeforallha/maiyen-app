import 'package:shared_preferences/shared_preferences.dart';
import '../config/maiyen_identifiers.dart';

class SystemUsageService {
  const SystemUsageService._();

  static const String _lastOpenAtKey = MaiYenIdentifiers.lastOpenAtStorageKey;
  static const String _previousOpenAtKey =
      MaiYenIdentifiers.previousOpenAtStorageKey;
  static const int _newSessionGapMs = 30 * 60 * 1000;

  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastOpenAt = prefs.getInt(_lastOpenAtKey) ?? 0;

    if (lastOpenAt <= 0 || now - lastOpenAt > _newSessionGapMs) {
      if (lastOpenAt > 0) {
        await prefs.setInt(_previousOpenAtKey, lastOpenAt);
      }
    }

    await prefs.setInt(_lastOpenAtKey, now);
  }

  static Future<int> previousOpenAt() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_previousOpenAtKey) ?? 0;
  }
}
