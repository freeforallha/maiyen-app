import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
    "fil",
    "km",
    "my",
    "lo",
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
    Locale("fil", "PH"),
    Locale("km", "KH"),
    Locale("my", "MM"),
    Locale("lo"),
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
    "fil": "Filipino",
    "km": "ភាសាខ្មែរ",
    "my": "မြန်မာဘာသာ",
    "lo": "ລາວ",
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
  bool get isFilipino => languageCode == "fil";
  bool get isKhmer => languageCode == "km";
  bool get isBurmese => languageCode == "my";
  bool get isLao => languageCode == "lo";

  String _normalizeLanguageCode(String code) {
    final cleanCode = code.trim().toLowerCase();

    if (cleanCode == "my_mm" || cleanCode == "my-mm") {
      return "my";
    }

    return cleanCode;
  }

  Locale _localeForCode(String code) {
    final normalizedCode = _normalizeLanguageCode(code);

    if (normalizedCode == "my") {
      return const Locale("my", "MM");
    }

    if (normalizedCode == "lo") {
      return const Locale("lo");
    }

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

    if (code == "fil") {
      return const Locale("fil", "PH");
    }

    if (code == "km") {
      return const Locale("km", "KH");
    }

    return Locale(code);
  }

  Future<void> _syncLanguageToFirebase(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final normalizedCode = _normalizeLanguageCode(code);
      if (!supportedCodes.contains(normalizedCode)) return;

      await FirebaseDatabase.instance
          .ref("accounts/${user.uid}/languageCode")
          .set(normalizedCode);
    } catch (_) {
      // Không chặn đổi ngôn ngữ cục bộ khi Firebase tạm thời không khả dụng.
    }
  }

  String _systemSupportedLanguageCode() {
    final systemCode = _normalizeLanguageCode(
      ui.PlatformDispatcher.instance.locale.languageCode,
    );

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
      final savedValue = preferences.getString(_storageKey);
      final savedCode = savedValue == null
          ? null
          : _normalizeLanguageCode(savedValue);
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

    await _syncLanguageToFirebase(languageCode);
  }

  Future<void> setLanguageCode(String code) async {
    final normalizedCode = _normalizeLanguageCode(code);

    if (!supportedCodes.contains(normalizedCode) ||
        normalizedCode == languageCode) {
      return;
    }

    _locale = _localeForCode(normalizedCode);
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, normalizedCode);
    } catch (_) {
      // Ngôn ngữ vẫn đổi trong phiên hiện tại.
    }

    await _syncLanguageToFirebase(normalizedCode);
  }
}

final AppLanguageController appLanguageController = AppLanguageController();
