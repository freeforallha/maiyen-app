import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  static const String _storageKey = "safehome_language_code";
  static const Set<String> supportedCodes = {"vi", "en"};

  Locale _locale = const Locale("vi");
  bool _loaded = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isEnglish => languageCode == "en";

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    _loaded = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      final savedCode = preferences.getString(_storageKey);

      if (savedCode != null &&
          supportedCodes.contains(savedCode) &&
          savedCode != languageCode) {
        _locale = Locale(savedCode);
        notifyListeners();
      }
    } catch (_) {
      // Giữ tiếng Việt nếu không đọc được cài đặt trên máy.
    }
  }

  Future<void> setLanguageCode(String code) async {
    if (!supportedCodes.contains(code) || code == languageCode) {
      return;
    }

    _locale = Locale(code);
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, code);
    } catch (_) {
      // Ngôn ngữ vẫn đổi trong phiên hiện tại.
    }
  }
}

final AppLanguageController appLanguageController =
    AppLanguageController();
