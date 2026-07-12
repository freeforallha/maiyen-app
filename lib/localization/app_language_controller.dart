import 'dart:ui' as ui;

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
    "id",
    "th",
    "ms",
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
    Locale("id", "ID"),
    Locale("th", "TH"),
    Locale("ms", "MY"),
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
    "id": "Bahasa Indonesia",
    "th": "ภาษาไทย",
    "ms": "Bahasa Melayu",
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
  bool get isIndonesian => languageCode == "id";
  bool get isThai => languageCode == "th";
  bool get isMalay => languageCode == "ms";

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

    if (code == "id") {
      return const Locale("id", "ID");
    }

    if (code == "th") {
      return const Locale("th", "TH");
    }

    if (code == "ms") {
      return const Locale("ms", "MY");
    }

    return Locale(code);
  }

  String _systemSupportedLanguageCode() {
    final systemCode = ui.PlatformDispatcher.instance.locale.languageCode
        .trim()
        .toLowerCase();

    if (supportedCodes.contains(systemCode)) {
      return systemCode;
    }

    return "vi";
  }

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    _loaded = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      final savedCode = preferences
          .getString(_storageKey)
          ?.trim()
          .toLowerCase();
      final code = savedCode != null && supportedCodes.contains(savedCode)
          ? savedCode
          : _systemSupportedLanguageCode();

      if (code != languageCode) {
        _locale = _localeForCode(code);
        notifyListeners();
      }
    } catch (_) {
      final code = _systemSupportedLanguageCode();

      if (code != languageCode) {
        _locale = _localeForCode(code);
        notifyListeners();
      }
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
