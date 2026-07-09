import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  static const String _storageKey = "safehome_language_code";
  static const Set<String> supportedCodes = {
    "vi",
    "en",
    "zh",
    "ko",
    "ja",
    "de",
    "ru",
    "fr",
    "es",
  };
  static const List<Locale> supportedLocales = [
    Locale("vi"),
    Locale("en"),
    Locale("zh", "CN"),
    Locale("ko", "KR"),
    Locale("ja", "JP"),
    Locale("de", "DE"),
    Locale("ru", "RU"),
    Locale("fr", "FR"),
    Locale("es", "ES"),
  ];
  static const Map<String, String> languageLabels = {
    "vi": "Tiếng Việt",
    "en": "English",
    "zh": "中文",
    "ko": "한국어",
    "ja": "日本語",
    "de": "Deutsch",
    "ru": "Русский",
    "fr": "Français",
    "es": "Español",
  };

  Locale _locale = const Locale("vi");
  bool _loaded = false;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isEnglish => languageCode == "en";
  bool get isChinese => languageCode == "zh";
  bool get isKorean => languageCode == "ko";
  bool get isJapanese => languageCode == "ja";
  bool get isGerman => languageCode == "de";
  bool get isRussian => languageCode == "ru";
  bool get isFrench => languageCode == "fr";
  bool get isSpanish => languageCode == "es";

  Locale _localeForCode(String code) {
    if (code == "zh") {
      return const Locale("zh", "CN");
    }

    if (code == "ko") {
      return const Locale("ko", "KR");
    }

    if (code == "ja") {
      return const Locale("ja", "JP");
    }

    if (code == "de") {
      return const Locale("de", "DE");
    }

    if (code == "ru") {
      return const Locale("ru", "RU");
    }

    if (code == "fr") {
      return const Locale("fr", "FR");
    }

    if (code == "es") {
      return const Locale("es", "ES");
    }

    return Locale(code);
  }

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
        _locale = _localeForCode(savedCode);
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

    _locale = _localeForCode(code);
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, code);
    } catch (_) {
      // Ngôn ngữ vẫn đổi trong phiên hiện tại.
    }
  }
}

final AppLanguageController appLanguageController = AppLanguageController();
