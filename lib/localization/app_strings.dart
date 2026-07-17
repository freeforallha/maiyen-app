import 'package:flutter/material.dart';

import 'languages/vi_strings.dart';
import 'languages/en_strings.dart';
import 'languages/zh_strings.dart';
import 'languages/ko_strings.dart';
import 'languages/ja_strings.dart';
import 'languages/de_strings.dart';
import 'languages/ru_strings.dart';
import 'languages/fr_strings.dart';
import 'languages/es_strings.dart';
import 'languages/id_strings.dart';
import 'languages/th_strings.dart';
import 'languages/ms_strings.dart';
import 'languages/fil_strings.dart';
import 'languages/km_strings.dart';
import 'languages/my_strings.dart';
import 'languages/lo_strings.dart';

class AppStrings {
  final bool isEnglish;
  final bool isChinese;
  final bool isKorean;
  final bool isJapanese;
  final bool isGerman;
  final bool isRussian;
  final bool isFrench;
  final bool isSpanish;
  final bool isIndonesian;
  final bool isThai;
  final bool isMalay;
  final bool isFilipino;
  final bool isKhmer;
  final bool isBurmese;
  final bool isLao;

  const AppStrings._({
    required this.isEnglish,
    required this.isChinese,
    required this.isKorean,
    required this.isJapanese,
    required this.isGerman,
    required this.isRussian,
    required this.isFrench,
    required this.isSpanish,
    required this.isIndonesian,
    required this.isThai,
    required this.isMalay,
    required this.isFilipino,
    required this.isKhmer,
    required this.isBurmese,
    required this.isLao,
  });

  factory AppStrings.fromLocale(Locale locale) {
    return AppStrings._(
      isEnglish: locale.languageCode == "en",
      isChinese: locale.languageCode == "zh",
      isKorean: locale.languageCode == "ko",
      isJapanese: locale.languageCode == "ja",
      isGerman: locale.languageCode == "de",
      isRussian: locale.languageCode == "ru",
      isFrench: locale.languageCode == "fr",
      isSpanish: locale.languageCode == "es",
      isIndonesian: locale.languageCode == "id",
      isThai: locale.languageCode == "th",
      isMalay: locale.languageCode == "ms",
      isFilipino: locale.languageCode == "fil",
      isKhmer: locale.languageCode == "km",
      isBurmese: locale.languageCode == "my",
      isLao: locale.languageCode == "lo",
    );
  }

  static AppStrings of(BuildContext context) {
    return AppStrings.fromLocale(Localizations.localeOf(context));
  }

  String choose({
    required String vi,
    required String en,
    String? zh,
    String? ko,
    String? ja,
    String? de,
    String? ru,
    String? fr,
    String? es,
    String? id,
    String? th,
    String? ms,
    String? fil,
    String? km,
    String? my,
    String? lo,
  }) {
    final key = _translationAliases[vi] ?? vi;

    if (isThai) {
      return _translationFromMap(_thai, key) ?? th ?? en;
    }

    if (isMalay) {
      return _translationFromMap(_malay, key) ?? ms ?? en;
    }

    if (isFilipino) {
      return _translationFromMap(_filipino, key) ?? fil ?? en;
    }

    if (isKhmer) {
      return _translationFromMap(_khmer, key) ?? km ?? en;
    }

    if (isBurmese) {
      return _translationFromMap(_burmese, key) ?? my ?? en;
    }

    if (isLao) {
      return _translationFromMap(_lao, key) ?? lo ?? en;
    }

    if (isIndonesian) {
      return _translationFromMap(_indonesian, key) ?? id ?? en;
    }

    if (isSpanish) {
      return _translationFromMap(_spanish, key) ?? es ?? en;
    }

    if (isFrench) {
      return _translationFromMap(_french, key) ?? fr ?? en;
    }

    if (isRussian) {
      return _translationFromMap(_russian, key) ?? ru ?? en;
    }

    if (isGerman) {
      return _translationFromMap(_german, key) ?? de ?? en;
    }

    if (isJapanese) {
      return _translationFromMap(_japanese, key) ?? ja ?? en;
    }

    if (isKorean) {
      return _translationFromMap(_korean, key) ?? ko ?? en;
    }

    if (isChinese) {
      return _translationFromMap(_chinese, key) ?? zh ?? en;
    }

    if (isEnglish) {
      return _translationFromMap(_english, key) ?? en;
    }

    return _translationFromMap(_vietnameseDisplayOverrides, key) ?? vi;
  }

  String? _translationFromMap(Map<String, String> translations, String text) {
    final exact = translations[text];

    if (exact != null) {
      return exact;
    }

    final placeholderPattern = RegExp(r'\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?');

    for (final entry in translations.entries) {
      final template = entry.key;
      final placeholders = placeholderPattern.allMatches(template).toList();

      if (placeholders.isEmpty) {
        continue;
      }

      final pattern = StringBuffer('^');
      var cursor = 0;

      for (final placeholder in placeholders) {
        pattern.write(
          RegExp.escape(template.substring(cursor, placeholder.start)),
        );
        pattern.write('(.+?)');
        cursor = placeholder.end;
      }

      pattern.write(RegExp.escape(template.substring(cursor)));
      pattern.write(r'$');
      final match = RegExp(pattern.toString()).firstMatch(text);

      if (match == null) {
        continue;
      }

      var translated = entry.value;

      for (var index = 0; index < placeholders.length; index++) {
        final name = placeholders[index].group(1)!;
        final value = match.group(index + 1) ?? '';
        translated = translated.replaceAll(RegExp('\\\$\\{?$name\\}?'), value);
      }

      return translated;
    }

    return null;
  }

  String _fr({required String vi, required String en}) {
    final exact = _french[vi];

    if (exact != null) {
      return exact;
    }

    return _frenchDynamic(vi, en) ?? en;
  }

  String? _frenchDynamic(String vi, String en) {
    String? quotedAt(int index) {
      final matches = RegExp(r'"([^"]+)"').allMatches(en).toList();
      return index < matches.length ? matches[index].group(1) : null;
    }

    final firstQuote = quotedAt(0);
    final secondQuote = quotedAt(1);
    final thirdQuote = quotedAt(2);

    if (en.contains("The alarm repeats after ")) {
      final minutes = RegExp(r"after (.+) minutes").firstMatch(en)?.group(1);
      return minutes == null
          ? null
          : "L’alarme se répète après $minutes minutes si le problème persiste.";
    }

    if (en.contains("turned on Manual Guard mode for") && firstQuote != null) {
      final actorName = en.split(" turned on ").first;
      return "$actorName a activé le mode protection manuel pour « $firstQuote ». Ce mode ne se désactive que lorsqu'un membre autorisé revient au mode normal.";
    }

    if (en.startsWith("You enabled Alarm for") && firstQuote != null) {
      return "Vous avez activé l’alarme pour « $firstQuote ».";
    }

    if (en.startsWith("You disabled every Alarm for") && firstQuote != null) {
      return "Toutes les alarmes de la maison « $firstQuote » ont été désactivées.";
    }

    if (en.contains(" joined ") && firstQuote != null) {
      final memberName = en.split(" joined ").first;
      return "$memberName a rejoint « $firstQuote ».";
    }

    if (en.contains(" left ") && firstQuote != null) {
      final memberName = en.split(" left ").first;
      return "$memberName a quitté « $firstQuote ».";
    }

    if (en.contains("'s role from ") && firstQuote != null) {
      final actorName = en.split(" changed ").first;
      final roleMatch = RegExp(
        r"changed (.+)'s role from (.+) to (.+) in ",
      ).firstMatch(en);
      if (roleMatch != null) {
        return "$actorName a changé le rôle de ${roleMatch.group(1)} de ${roleMatch.group(2)} à ${roleMatch.group(3)} dans « $firstQuote ».";
      }
    }

    if (en.endsWith(" unread messages")) {
      return "${en.split(" ").first} messages non lus";
    }

    if (en.endsWith(" new messages")) {
      return "${en.split(" ").first} nouveaux messages";
    }

    if (en.contains(" sent a message")) {
      return "${en.split(" sent a message").first} a envoyé un message";
    }

    if (en.contains("Guard mode will repeat the alert after ")) {
      final minutes = RegExp(r"after (.+) minutes").firstMatch(en)?.group(1);
      return minutes == null
          ? null
          : "Le mode protection répétera l'alerte après $minutes minutes";
    }

    if (en.startsWith("Join requests sent for ")) {
      final count = en.split(" ")[4];
      return "Demandes d'adhésion envoyées pour $count maisons";
    }

    if (en.contains(" requested to join ") && firstQuote != null) {
      final requesterName = en.split(" requested to join ").first;
      return "$requesterName demande à rejoindre « $firstQuote ».";
    }

    if (en.startsWith("You deleted ") && firstQuote != null) {
      return "Vous avez supprimé « $firstQuote ».";
    }

    if (en.contains("ownership transfer request") && firstQuote != null) {
      final email = en.split(" to ").last.replaceAll(".", "");
      return "Vous avez envoyé une demande de transfert de propriété pour « $firstQuote » à $email.";
    }

    if (en.contains("wants to transfer ownership") && firstQuote != null) {
      final actorName = en.split(" wants to ").first;
      return "$actorName souhaite vous transférer la propriété de « $firstQuote ».";
    }

    if (en.contains(" invited you to join ") && firstQuote != null) {
      final actorName = en.split(" invited you to join ").first;
      return "$actorName vous a invité à rejoindre « $firstQuote ».";
    }

    if (en.startsWith("SafeHome is removing") &&
        firstQuote != null &&
        secondQuote != null) {
      return "SafeHome supprime l'appareil « $firstQuote » de « $secondQuote ».";
    }

    if (en.startsWith("Device ") &&
        en.contains(" was added to ") &&
        firstQuote != null &&
        secondQuote != null) {
      return "L'appareil « $firstQuote » a été ajouté à « $secondQuote ».";
    }

    if (en.startsWith("You created the home ") && firstQuote != null) {
      return "Vous avez créé « $firstQuote ».";
    }

    if (en.contains("updated the home name to") && firstQuote != null) {
      final actorName = en.split(" updated ").first;
      return "$actorName a renommé la maison en « $firstQuote » et a modifié son adresse.";
    }

    if (en.contains("renamed the home to") && firstQuote != null) {
      final actorName = en.split(" renamed ").first;
      return "$actorName a renommé la maison en « $firstQuote ».";
    }

    if (en.contains("updated the address of") && firstQuote != null) {
      final actorName = en.split(" updated ").first;
      return "$actorName a mis à jour l'adresse de « $firstQuote ».";
    }

    if (en.contains("renamed device") &&
        firstQuote != null &&
        secondQuote != null &&
        thirdQuote != null) {
      final actorName = en.split(" renamed ").first;
      return "$actorName a renommé l'appareil « $firstQuote » en « $secondQuote » dans « $thirdQuote ».";
    }

    if (en.startsWith("Pairing: ")) {
      return en.replaceFirst("Pairing:", "Appairage :");
    }

    if (en.contains("Device pairing was enabled") && firstQuote != null) {
      final seconds = RegExp(r"for (.+) seconds").firstMatch(en)?.group(1);
      return seconds == null
          ? null
          : "L'appairage des appareils a été activé dans « $firstQuote » pendant $seconds secondes.";
    }

    if (en.contains("pause period must be within")) {
      return en.replaceFirst(
        "The pause period must be within the Alarm schedule",
        "La période de pause doit être dans le planning d’alarme",
      );
    }

    final testsMatch = RegExp(r"^(.+)/(.+) tests passed").firstMatch(en);
    if (testsMatch != null) {
      return "${testsMatch.group(1)}/${testsMatch.group(2)} tests réussis\n\n";
    }

    if (en.contains("has not added a phone number")) {
      return "${en.split(" has not ").first} n'a pas ajouté de numéro de téléphone à son profil.";
    }

    if (en.startsWith("New message in ")) {
      return "Nouveau message dans ${en.replaceFirst("New message in ", "")}";
    }

    if (en.endsWith(" results")) {
      return en.replaceAll("results", "résultats");
    }

    if (en.startsWith("Replying to ")) {
      return "Réponse à ${en.replaceFirst("Replying to ", "")}";
    }

    if (en.contains("detected smoke") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » a détecté de la fumée dans « $secondQuote ».";
    }

    if (en.contains("has returned to normal") && firstQuote != null) {
      return "« $firstQuote » est revenu à l'état normal.";
    }

    if (en.contains("triggered SOS") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » a déclenché SOS dans « $secondQuote ».";
    }

    if (en.contains("is no longer in SOS state") && firstQuote != null) {
      return "« $firstQuote » n'est plus en état SOS.";
    }

    if (en.contains("reported tampering") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » a signalé une tentative d'arrachement dans « $secondQuote ».";
    }

    if (en.contains("tamper alert has cleared") && firstQuote != null) {
      return "L'alerte d'arrachement de « $firstQuote » est terminée.";
    }

    if (en.contains(" closed in ") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » est fermé dans « $secondQuote ».";
    }

    if (en.contains(" is open in ") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » est ouvert dans « $secondQuote ».";
    }

    if (en.contains("has a low battery") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » dans « $secondQuote » a une batterie faible.";
    }

    if (en.contains("went offline") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » dans « $secondQuote » est hors ligne.";
    }

    if (en.contains("is back online") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » dans « $secondQuote » est de nouveau en ligne.";
    }

    if (en.contains("recorded a high temperature") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » a relevé une température élevée dans « $secondQuote ».";
    }

    if (en.contains("recorded high humidity") &&
        firstQuote != null &&
        secondQuote != null) {
      return "« $firstQuote » a relevé une humidité élevée dans « $secondQuote ».";
    }

    if (en.startsWith("Alerts again at ")) {
      return en
          .replaceFirst("Alerts again at", "Nouvelle alerte à")
          .replaceFirst(
            "if the issue has not been handled.",
            "si le problème n'a pas été traité.",
          );
    }

    final selectedHomes = RegExp(r"^(.+) homes selected$").firstMatch(en);
    if (selectedHomes != null) {
      return "${selectedHomes.group(1)} maisons sélectionnées";
    }

    if (en.contains("unsafe homes")) {
      return en.replaceAll("unsafe homes", "maisons non sécurisées");
    }

    if (en.contains("homes need attention")) {
      return en.replaceAll(
        "homes need attention",
        "maisons nécessitent une attention",
      );
    }

    if (en.contains("safe homes")) {
      return en.replaceAll("safe homes", "maisons sécurisées");
    }

    if (en.endsWith(" homes monitored")) {
      return en.replaceAll("homes monitored", "maisons surveillées");
    }

    if (en.endsWith(" minutes")) {
      return en.replaceAll("minutes", "minutes");
    }

    if (en.startsWith("Alarm applied to ")) {
      return en
          .replaceFirst("Alarm applied to", "Alarme appliquée à")
          .replaceAll("security devices", "appareils de sécurité");
    }

    if (en.startsWith("Apply the same schedule to ")) {
      return en
          .replaceFirst(
            "Apply the same schedule to",
            "Appliquer le même planning à",
          )
          .replaceAll("security devices", "appareils de sécurité");
    }

    if (en.endsWith(" minutes ago")) {
      return "il y a ${en.split(" ").first} minutes";
    }

    if (en.endsWith(" hours ago")) {
      return "il y a ${en.split(" ").first} heures";
    }

    if (en.endsWith(" days ago")) {
      return "il y a ${en.split(" ").first} jours";
    }

    if (en.endsWith(" months ago")) {
      return "il y a ${en.split(" ").first} mois";
    }

    if (en.contains("Are you sure you want to remove ")) {
      final name = en
          .replaceFirst("Are you sure you want to remove ", "")
          .replaceFirst(" from this home?", "");
      return "Voulez-vous vraiment supprimer $name de cette maison ?";
    }

    if (en.contains("Requests to join") && firstQuote != null) {
      final prefix = en.split("\n").first;
      return en.contains("\n")
          ? "$prefix\nDemande à rejoindre « $firstQuote »"
          : "Demande à rejoindre « $firstQuote »";
    }

    if (en.contains("Invites you to join") && firstQuote != null) {
      final prefix = en.split("\n").first;
      return en.contains("\n")
          ? "$prefix\nVous invite à rejoindre « $firstQuote »"
          : "Vous invite à rejoindre « $firstQuote »";
    }

    if (en.contains("receive ownership") && firstQuote != null) {
      return "Vous avez été invité à recevoir la propriété de « $firstQuote »";
    }

    if (en.startsWith("Needs attention: ")) {
      return "Attention requise : ${en.replaceFirst("Needs attention: ", "")}";
    }

    if (en.startsWith("Updated ")) {
      return "Mis à jour ${en.replaceFirst("Updated ", "")}";
    }

    if (en.startsWith("Repeat after ")) {
      return en.replaceFirst("Repeat after", "Répéter après");
    }

    if (en.startsWith("Active • ")) {
      return en.replaceFirst("Active", "Actif");
    }

    if (en.startsWith("Security monitoring • ")) {
      return en.replaceFirst("Security monitoring", "Surveillance de sécurité");
    }

    if (en.startsWith("Home mode: ")) {
      return en.replaceFirst("Home mode:", "Mode maison :");
    }

    if (en.contains("issues need attention")) {
      final count = en.split(" ").first;
      return "$count problèmes nécessitent une attention";
    }

    if (en.contains("Doors were used") && en.contains("times today")) {
      final count = RegExp(r"used (.+) times").firstMatch(en)?.group(1);
      return count == null
          ? null
          : "Les portes ont été utilisées $count fois aujourd'hui";
    }

    if (en.contains("recent activities recorded")) {
      final count = en.split(" ").first;
      return "$count activités récentes enregistrées";
    }

    if (en.startsWith("System: ") && en.contains("items need checking")) {
      final count = RegExp(r"System: (.+) items").firstMatch(en)?.group(1);
      return count == null ? null : "Système : $count éléments à vérifier";
    }

    if (en.contains("emergency devices found")) {
      final count = en.split(" ").first;
      return "$count appareils d'urgence détectés. Minimum recommandé : détecteur de fumée et SOS.";
    }

    if (en.startsWith("Transfer home ownership to:")) {
      return en.replaceFirst(
        "Transfer home ownership to:",
        "Transférer la propriété de la maison à :",
      );
    }

    if (en.contains("doors safely closed")) {
      final count = en.split(" ").first;
      return "$count portes fermées en sécurité";
    }

    if (en.contains("doors and locks secured")) {
      final count = en.split(" ").first;
      return "$count portes et serrures sécurisées";
    }

    if (en.contains("devices monitored")) {
      final count = en.split(" ").first;
      return "$count appareils surveillés";
    }

    if (en.startsWith("Latest data updated ")) {
      return en
          .replaceFirst(
            "Latest data updated",
            "Dernières données mises à jour il y a",
          )
          .replaceAll(" minutes ago", " minutes")
          .replaceAll(" hours ago", " heures");
    }

    if (en.startsWith("Members at home: ")) {
      return "Membres à la maison : ${en.replaceFirst("Members at home: ", "")}";
    }

    if (en.startsWith("Members away: ")) {
      return "Membres absents : ${en.replaceFirst("Members away: ", "")}";
    }

    if (en.startsWith("Location unknown: ")) {
      return "Position inconnue : ${en.replaceFirst("Location unknown: ", "")}";
    }

    if (en.startsWith("Current environment: ")) {
      return "Environnement actuel : ${en.replaceFirst("Current environment: ", "")}";
    }

    if (en.contains(": Open while Home is in Guard mode")) {
      return en.replaceFirst(
        ": Open while Home is in Guard mode",
        " : ouvert pendant que la maison est en mode protection",
      );
    }

    if (en.startsWith("Auto-closes in ")) {
      return "Fermeture automatique dans ${en.replaceFirst("Auto-closes in ", "")}";
    }

    return null;
  }

  String get permissionDeniedMessage => choose(
    vi: "Bạn không có quyền thực hiện thao tác này.",
    en: "You don't have permission to perform this action.",
    zh: "你没有权限执行此操作。",
    ko: "이 작업을 수행할 권한이 없습니다.",
    ja: "この操作を実行する権限がありません。",
    de: 'Du hast keine Berechtigung, diese Aktion auszuführen.',
    ru: 'У вас нет разрешения выполнить это действие.',

    es: "No tienes permiso para realizar esta acción.",
    fr: _fr(
      vi: "Bạn không có quyền thực hiện thao tác này.",
      en: "You don't have permission to perform this action.",
    ),
  );

  String get genericOperationError => choose(
    vi: "Không thể hoàn tất thao tác. Vui lòng thử lại.",
    en: "Couldn't complete the action. Please try again.",
    zh: "无法完成此操作。请重试。",
    ko: "작업을 완료할 수 없습니다. 다시 시도해 주세요.",
    ja: "操作を完了できませんでした。もう一度お試しください。",
    de: 'Die Aktion konnte nicht abgeschlossen werden. Bitte versuche es erneut.',
    ru: 'Не удалось завершить действие. Повторите попытку.',

    es: "No se pudo completar la acción. Inténtalo de nuevo.",
    fr: _fr(
      vi: "Không thể hoàn tất thao tác. Vui lòng thử lại.",
      en: "Couldn't complete the action. Please try again.",
    ),
  );

  bool isPermissionDeniedError(Object? error) {
    final text = error?.toString().toLowerCase() ?? "";

    return text.contains("permission-denied") ||
        text.contains("permission_denied") ||
        text.contains("permission denied") ||
        text.contains("doesn't have permission");
  }

  String sanitizeUserMessage(String message, {String? fallback}) {
    final cleanMessage = message.trim();

    if (isPermissionDeniedError(cleanMessage)) {
      return permissionDeniedMessage;
    }

    final lower = cleanMessage.toLowerCase();
    final looksLikeRawFirebaseError =
        lower.contains("firebase") ||
        lower.contains("databaseerror") ||
        lower.contains("firebaseexception") ||
        lower.contains("desired data") ||
        lower.contains(" at path ") ||
        lower.contains("accounts/") ||
        lower.contains("sharedbyhome/") ||
        lower.contains("homechats/") ||
        lower.contains("device_delete_requests/");

    if (looksLikeRawFirebaseError) {
      return fallback ?? genericOperationError;
    }

    return cleanMessage.isEmpty
        ? fallback ?? genericOperationError
        : cleanMessage;
  }

  String systemNotificationText(String text, {String type = ""}) {
    final cleanType = type.trim().toLowerCase();
    final cleanText = text.trim();

    String typeFallback() {
      switch (cleanType) {
        case "device_sos":
        case "sos":
          return t("SOS được kích hoạt");
        case "device_sos_clear":
        case "sos_clear":
          return t("SOS đã kết thúc");
        case "device_tamper":
        case "tamper":
          return t("Phát hiện bất thường");
        case "device_tamper_clear":
        case "tamper_clear":
          return t("Tamper bình thường");
        default:
          return "";
      }
    }

    var result = cleanText.isEmpty ? typeFallback() : cleanText;

    if (result.isEmpty) {
      return result;
    }

    final replacements = <String, String>{
      "SOS KHẨN CẤP": t("SOS được kích hoạt"),
      "SOS activated": t("SOS được kích hoạt"),
      "SOS được kích hoạt": t("SOS được kích hoạt"),
      "SOS cleared": t("SOS đã kết thúc"),
      "SOS ended": t("SOS đã kết thúc"),
      "SOS đã kết thúc": t("SOS đã kết thúc"),
      "Door closed": t("Cửa đã đóng"),
      "Door opened": t("Cửa đang mở"),
      "Cửa đóng": t("Cửa đã đóng"),
      "Cửa mở": t("Cửa đang mở"),
      "Tamper condition cleared": t("Tamper bình thường"),
      "Tamper cleared": t("Tamper bình thường"),
      "Tamper normal": t("Tamper bình thường"),
      "Tamper detected": t("Phát hiện bất thường"),
      "Phát hiện cạy phá": t("Phát hiện bất thường"),
      "Motion detected": t("Phát hiện chuyển động"),
      "Battery low": t("Pin yếu"),
      "Device offline": t("Thiết bị offline"),
      "Device online": t("Thiết bị online"),
      "Alarm triggered": t("Báo động kích hoạt"),
      "Alarm cleared": t("Báo động đã tắt"),
      "Vai trò thành viên đã thay đổi": t("Vai trò thành viên đã thay đổi"),
    };

    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }

  String roleName(String role) {
    switch (role.trim().toLowerCase()) {
      case "owner":
        return choose(
          vi: "Chủ nhà",
          en: "Owner",
          zh: "房主",
          ko: "집 소유자",
          ja: "所有者",
          de: 'Besitzer',
          ru: 'Владелец',

          es: "Propietario",
          fr: _fr(vi: "Chủ nhà", en: "Owner"),
        );
      case "admin":
        return choose(
          vi: "Quản trị viên",
          en: "Admin",
          zh: "管理员",
          ko: "관리자",
          ja: "管理者",
          de: 'Administrator',
          ru: 'Администратор',

          es: "Administrador",
          fr: _fr(vi: "Quản trị viên", en: "Admin"),
        );
      case "member":
        return choose(
          vi: "Thành viên",
          en: "Member",
          zh: "成员",
          ko: "구성원",
          ja: "メンバー",
          de: 'Mitglied',
          ru: 'Участник',

          es: "Miembro",
          fr: _fr(vi: "Thành viên", en: "Member"),
        );
    }

    return role;
  }

  String armedSecurityModeSourceLabel(String source) {
    final normalizedSource = source.trim().toLowerCase();
    final automatic =
        normalizedSource == "auto_away" || normalizedSource == "schedule";

    if (automatic) {
      return choose(
        vi: "Bảo vệ - Tự động",
        en: "Guard - Auto",
        zh: "布防 - 自动",
        ko: "보호 - 자동",
        ja: "警戒 - 自動",
        de: "Schutzmodus - Automatisch",
        ru: "Режим охраны - Автоматически",
        fr: "Protection - Automatique",
        es: "Protección - Automática",
        id: "Perlindungan - Otomatis",
        th: "ป้องกัน - อัตโนมัติ",
        ms: "Perlindungan - Automatik",
        fil: "Proteksyon - Awtomatiko",
        km: "ការពារ - ស្វ័យប្រវត្តិ",
        my: "ကာကွယ်မှု - အလိုအလျောက်",
        lo: "ປ້ອງກັນ - ອັດຕະໂນມັດ",
      );
    }

    return choose(
      vi: "Bảo vệ - Thủ công",
      en: "Guard - Manual",
      zh: "布防 - 手动",
      ko: "보호 - 수동",
      ja: "警戒 - 手動",
      de: "Schutzmodus - Manuell",
      ru: "Режим охраны - Вручную",
      fr: "Protection - Par l’utilisateur",
      es: "Protección - Por el usuario",
      id: "Perlindungan - Oleh pengguna",
      th: "ป้องกัน - ด้วยตนเอง",
      ms: "Perlindungan - Oleh pengguna",
      fil: "Proteksyon - Manu-mano",
      km: "ការពារ - ដោយដៃ",
      my: "ကာကွယ်မှု - ကိုယ်တိုင်",
      lo: "ປ້ອງກັນ - ດ້ວຍຕົນເອງ",
    );
  }

  String armedSecurityModeSourceDetailLabel(String source) {
    final normalizedSource = source.trim().toLowerCase();
    final automatic =
        normalizedSource == "auto_away" || normalizedSource == "schedule";

    if (automatic) {
      return choose(
        vi: "Tự động",
        en: "Auto",
        zh: "自动",
        ko: "자동",
        ja: "自動",
        de: "Automatisch",
        ru: "Автоматически",
        fr: "Automatique",
        es: "Automático",
        id: "Otomatis",
        th: "อัตโนมัติ",
        ms: "Automatik",
        fil: "Awtomatiko",
        km: "ស្វ័យប្រវត្តិ",
        my: "အလိုအလျောက်",
        lo: "ອັດຕະໂນມັດ",
      );
    }

    return choose(
      vi: "Thủ công",
      en: "Manual",
      zh: "手动",
      ko: "수동",
      ja: "手動",
      de: "Manuell",
      ru: "Вручную",
      fr: "Par l’utilisateur",
      es: "Por el usuario",
      id: "Oleh pengguna",
      th: "ด้วยตนเอง",
      ms: "Oleh pengguna",
      fil: "Manu-mano",
      km: "ដោយដៃ",
      my: "ကိုယ်တိုင်",
      lo: "ດ້ວຍຕົນເອງ",
    );
  }

  String manualSecurityModeEnabledTitle() => choose(
    vi: "Chế độ Bảo vệ thủ công đã bật",
    en: "Manual Guard mode enabled",
    zh: "手动布防模式已开启",
    ko: "수동 보호 모드가 켜졌습니다",
    ja: "手動Guardモードがオンになりました",
    de: 'Manueller Schutzmodus aktiviert',
    ru: 'Ручной режим охраны включен',

    es: "Modo protección manual activado",
    fr: _fr(
      vi: "Chế độ Bảo vệ thủ công đã bật",
      en: "Manual Guard mode enabled",
    ),
  );

  String manualSecurityModeEnabledMessage({
    required String actorName,
    required String homeName,
    required int securityModeRepeatMinutes,
  }) {
    final repeatMessage = securityModeRepeatMinutes == 0
        ? choose(
            vi: "Báo động không lặp lại.",
            en: "The alarm will not repeat.",
            zh: "警报不会重复。",
            ko: "경보은 반복되지 않습니다.",
            ja: "警報 は繰り返されません。",
            de: 'Der Alarm wird nicht wiederholt.',
            ru: 'Тревога не будет повторяться.',

            es: "La alarma no se repetirá.",
            fr: _fr(
              vi: "Báo động không lặp lại.",
              en: "The alarm will not repeat.",
            ),
          )
        : choose(
            vi: "Báo động lặp sau $securityModeRepeatMinutes phút nếu sự cố vẫn còn.",
            fil:
                "Uulit ang alarma pagkalipas ng $securityModeRepeatMinutes minuto kung magpapatuloy ang problema.",
            km: "សំឡេងរោទិ៍ នឹងកើតឡើងវិញបន្ទាប់ពី $securityModeRepeatMinutes នាទី ប្រសិនបើបញ្ហានៅតែមាន។",
            en: "The alarm repeats after $securityModeRepeatMinutes minutes if the issue remains.",
            zh: "如果问题仍然存在，警报将在 $securityModeRepeatMinutes 分钟后重复。",
            ko: "문제가 계속되면 $securityModeRepeatMinutes분 후 경보이 반복됩니다.",
            ja: "問題が残っている場合、$securityModeRepeatMinutes 分後に 警報 が繰り返されます。",
            de: 'Der Alarm wird nach $securityModeRepeatMinutes Minuten wiederholt, wenn das Problem weiter besteht.',
            ru: 'Тревога повторится через $securityModeRepeatMinutes минут, если проблема останется.',

            es: "La alarma se repetirá después de $securityModeRepeatMinutes minutos si el problema continúa.",
            fr: _fr(
              vi: "Báo động lặp sau $securityModeRepeatMinutes phút nếu sự cố vẫn còn.",
              en: "The alarm repeats after $securityModeRepeatMinutes minutes if the issue remains.",
            ),
            id: "Alarm berulang setelah $securityModeRepeatMinutes menit jika masalah masih ada.",
            th: "สัญญาณเตือน จะทำซ้ำหลัง $securityModeRepeatMinutes นาที หากยังมีปัญหาอยู่",
            ms: "Penggera akan berulang selepas $securityModeRepeatMinutes minit jika masalah berterusan.",
            my: "ပြဿနာရှိနေသေးပါက $securityModeRepeatMinutes မိနစ်အကြာတွင် အရေးပေါ်အချက်ပေးသံ ထပ်မံသတိပေးပါမည်။",
            lo: "ສັນຍານເຕືອນໄພຈະເຮັດຊ້ຳຫຼັງ $securityModeRepeatMinutes ນາທີ ຖ້າບັນຫາຍັງຄົງຢູ່",
          );

    return choose(
      vi: "$actorName đã bật Chế độ Bảo vệ thủ công cho \"$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. $repeatMessage",
      fil:
          "Manu-manong in-on ni $actorName ang Mode ng Proteksyon para sa \"$homeName\". Mananatiling naka-on ang mode na ito hanggang ibalik ito sa Normal ng miyembrong may pahintulot. $repeatMessage",
      km: "$actorName បានបើកមុខងារការពារដោយដៃសម្រាប់ \"$homeName\"។ មុខងារនេះបិទបានតែនៅពេលសមាជិកដែលមានសិទ្ធិប្ដូរត្រឡប់ទៅធម្មតា។ $repeatMessage",
      en: "$actorName turned on Manual Guard mode for \"$homeName\". This mode only turns off when a permitted member switches back to Normal. $repeatMessage",
      zh: "$actorName 已为“$homeName”开启手动布防模式。只有具备权限的成员主动切换回普通模式时，此模式才会关闭。$repeatMessage",
      ko: "$actorName님이 \"$homeName\"에 수동 보호 모드를 켰습니다. 권한이 있는 구성원이 Normal로 직접 전환해야 이 모드가 꺼집니다. $repeatMessage",
      ja: "$actorName が「$homeName」で手動Guardモードをオンにしました。このモードは、権限のあるメンバーがNormalに戻した場合にのみオフになります。$repeatMessage",
      de: '$actorName hat den manuellen Schutzmodus für "$homeName" aktiviert. Dieser Modus wird nur deaktiviert, wenn ein berechtigtes Mitglied zurück in den Normalmodus wechselt. $repeatMessage',
      ru: '$actorName включил ручной режим охраны для "$homeName". Этот режим отключается только когда участник с правами переключит обратно в обычный режим. $repeatMessage',

      es: "$actorName activó manualmente el modo protección para «$homeName». Este modo solo se desactiva cuando un miembro con permiso cambia al modo normal. $repeatMessage",
      fr: _fr(
        vi: "$actorName đã bật Chế độ Bảo vệ thủ công cho \"$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. $repeatMessage",
        en: "$actorName turned on Manual Guard mode for \"$homeName\". This mode only turns off when a permitted member switches back to Normal. $repeatMessage",
      ),
      id: "$actorName menyalakan mode Perlindungan manual untuk \"$homeName\". Mode ini hanya mati ketika anggota yang berwenang kembali ke Normal. $repeatMessage",
      th: "$actorName เปิดโหมดป้องกันด้วยตนเองสำหรับ \"$homeName\" โหมดนี้จะปิดเมื่อสมาชิกที่ได้รับอนุญาตเปลี่ยนกลับเป็นโหมดปกติเท่านั้น $repeatMessage",
      ms: "$actorName telah menghidupkan Mod Perlindungan manual untuk \"$homeName\". Mod ini hanya dimatikan apabila ahli yang dibenarkan menukarnya kepada Mod Normal. $repeatMessage",
      my: "$actorName က \"$homeName\" အတွက် ကိုယ်တိုင် ကာကွယ်ရေးမုဒ်ကို ဖွင့်ထားသည်။ ခွင့်ပြုထားသောအဖွဲ့ဝင်တစ်ဦးက ပုံမှန်မုဒ်သို့ ပြန်ပြောင်းမှသာ ဤမုဒ် ပိတ်မည်။ $repeatMessage",
      lo: "$actorName ເປີດໂໝດປ້ອງກັນດ້ວຍຕົນເອງສຳລັບ \"$homeName\". ໂໝດນີ້ຈະປິດເມື່ອສະມາຊິກທີ່ມີສິດປ່ຽນກັບເປັນປົກກະຕິ. $repeatMessage",
    );
  }

  String alarmSettingChangedTitle(bool enabled) {
    return enabled ? t("Đã bật báo động") : t("Đã tắt báo động");
  }

  String alarmSettingChangedMessage({
    required bool enabled,
    required String homeName,
  }) {
    return enabled
        ? choose(
            vi: "Bạn đã bật báo động cho nhà \"$homeName\".",
            fil: "In-enable mo ang alarma para sa bahay na \"$homeName\".",
            km: "អ្នកបានបើក សំឡេងរោទិ៍ សម្រាប់ \"$homeName\"។",
            en: "You enabled Alarm for \"$homeName\".",
            zh: "你已为“$homeName”开启 警报。",
            ko: "\"$homeName\"의 경보을 켰습니다.",
            ja: "「$homeName」の 警報 をオンにしました。",
            de: 'Du hast Alarm für das Zuhause "$homeName" aktiviert.',
            ru: 'Вы включили тревога для дома "$homeName".',

            es: "Activaste alarma para \"$homeName\".",
            fr: _fr(
              vi: "Bạn đã bật báo động cho nhà \"$homeName\".",
              en: "You enabled Alarm for \"$homeName\".",
            ),
            id: "Anda mengaktifkan alarm untuk rumah \"$homeName\".",
            th: "คุณเปิด สัญญาณเตือน สำหรับบ้าน \"$homeName\" แล้ว",
            ms: "Anda telah mendayakan penggera untuk rumah \"$homeName\".",
            my: "\"$homeName\" အတွက် အရေးပေါ်အချက်ပေးသံ ကို သင်ဖွင့်ထားသည်။",
            lo: "ທ່ານເປີດສັນຍານເຕືອນໄພສຳລັບ \"$homeName\" ແລ້ວ",
          )
        : choose(
            vi: "Bạn đã tắt toàn bộ báo động của nhà \"$homeName\".",
            fil: "In-off mo ang lahat ng alarma ng bahay na \"$homeName\".",
            km: "អ្នកបានបិទ សំឡេងរោទិ៍ ទាំងអស់សម្រាប់ \"$homeName\"។",
            en: "You disabled every Alarm for \"$homeName\".",
            zh: "你已关闭“$homeName”的所有 警报。",
            ko: "\"$homeName\"의 모든 경보을 껐습니다.",
            ja: "「$homeName」のすべての 警報 をオフにしました。",
            de: 'Du hast alle Alarm-Einstellungen für das Zuhause "$homeName" deaktiviert.',
            ru: 'Вы отключили все тревога для дома "$homeName".',

            es: "Desactivaste todos los alarma de \"$homeName\".",
            fr: _fr(
              vi: "Bạn đã tắt toàn bộ báo động của nhà \"$homeName\".",
              en: "You disabled every Alarm for \"$homeName\".",
            ),
            id: "Semua alarm di rumah \"$homeName\" telah dinonaktifkan.",
            th: "คุณได้ปิด สัญญาณเตือน ทั้งหมดของบ้าน \"$homeName\" แล้ว",
            ms: "Anda telah melumpuhkan semua penggera rumah \"$homeName\".",
            my: "\"$homeName\" ၏ အရေးပေါ်အချက်ပေးသံ အားလုံးကို သင်ပိတ်ထားသည်။",
            lo: "ທ່ານປິດສັນຍານເຕືອນໄພທັງໝົດຂອງ \"$homeName\" ແລ້ວ",
          );
  }

  String memberJoinedHomeTitle() => choose(
    vi: "Thành viên mới",
    en: "New member",
    zh: "新成员",
    ko: "새 구성원",
    ja: "新しいメンバー",
    de: 'Neues Mitglied',
    ru: 'Новый участник',

    es: "Nuevo miembro",
    fr: _fr(vi: "Thành viên mới", en: "New member"),
  );

  String memberJoinedHomeMessage({
    required String memberName,
    required String homeName,
  }) {
    final displayMemberName = memberName.trim().isNotEmpty
        ? memberName.trim()
        : t("Một thành viên");

    return choose(
      vi: '$displayMemberName đã gia nhập nhà "$homeName".',
      my: '$displayMemberName သည် "$homeName" သို့ ဝင်ရောက်ခဲ့သည်။',
      fil: "Sumali si $displayMemberName sa bahay na \"$homeName\".",
      km: "$displayMemberName បានចូលរួមផ្ទះ \"$homeName\"។",
      en: '$displayMemberName joined "$homeName".',
      zh: '$displayMemberName 已加入“$homeName”。',
      ko: '$displayMemberName님이 "$homeName"에 참여했습니다.',
      ja: '$displayMemberName が「$homeName」に参加しました。',
      de: '$displayMemberName ist "$homeName" beigetreten.',
      ru: '$displayMemberName присоединился к дому "$homeName".',

      es: "$displayMemberName se unió a «$homeName».",
      fr: _fr(
        vi: '$displayMemberName đã gia nhập nhà "$homeName".',
        en: '$displayMemberName joined "$homeName".',
      ),
      id: "$displayMemberName bergabung dengan \"$homeName\".",
      th: "$displayMemberName เข้าร่วมบ้าน \"$homeName\" แล้ว",
      ms: "$displayMemberName telah menyertai rumah \"$homeName\".",
      lo: "$displayMemberName ເຂົ້າຮ່ວມເຮືອນ \"$homeName\" ແລ້ວ.",
    );
  }

  String memberLeftHomeTitle() => choose(
    vi: "Thành viên rời nhà",
    en: "Member left home",
    zh: "成员已离开家庭",
    ko: "구성원이 집에서 나갔습니다",
    ja: "メンバーが家から退出しました",
    de: 'Mitglied hat Zuhause verlassen',
    ru: 'Участник покинул дом',

    es: "Un miembro salió de la casa",
    fr: _fr(vi: "Thành viên rời nhà", en: "Member left home"),
  );

  String memberLeftHomeMessage({
    required String memberName,
    required String homeName,
  }) {
    final displayMemberName = memberName.trim().isNotEmpty
        ? memberName.trim()
        : choose(
            vi: "Một thành viên",
            en: "A member",
            zh: "一位成员",
            ko: "구성원 한 명",
            ja: "メンバー",
            de: 'Ein Mitglied',
            ru: 'Участник',

            es: "Un miembro",
            fr: _fr(vi: "Một thành viên", en: "A member"),
          );

    return choose(
      vi: "$displayMemberName đã rời khỏi nhà \"$homeName\".",
      fil: "Umalis si $displayMemberName sa bahay na \"$homeName\".",
      km: "$displayMemberName បានចាកចេញពី \"$homeName\"។",
      en: "$displayMemberName left \"$homeName\".",
      zh: "$displayMemberName 已离开“$homeName”。",
      ko: "$displayMemberName님이 \"$homeName\"에서 나갔습니다.",
      ja: "$displayMemberName が「$homeName」から退出しました。",
      de: '$displayMemberName hat "$homeName" verlassen.',
      ru: '$displayMemberName покинул дом "$homeName".',

      es: "$displayMemberName salió de «$homeName».",
      fr: _fr(
        vi: "$displayMemberName đã rời khỏi nhà \"$homeName\".",
        en: "$displayMemberName left \"$homeName\".",
      ),
      id: "$displayMemberName keluar dari \"$homeName\".",
      th: "$displayMemberName ออกจากบ้าน \"$homeName\" แล้ว",
      ms: "$displayMemberName meninggalkan rumah \"$homeName\".",
      my: "$displayMemberName သည် \"$homeName\" မှ ထွက်သွားသည်။",
      lo: "$displayMemberName ອອກຈາກ \"$homeName\" ແລ້ວ",
    );
  }

  String memberRoleChangedTitle() => choose(
    vi: "Vai trò thành viên đã thay đổi",
    en: "Member role changed",
    zh: "成员角色已更改",
    ko: "구성원 역할이 변경되었습니다",
    ja: "メンバーの役割が変更されました",
    de: 'Mitgliedsrolle geändert',
    ru: 'Роль участника изменена',

    es: "El rol del miembro cambió",
    fr: _fr(vi: "Vai trò thành viên đã thay đổi", en: "Member role changed"),
  );

  String memberRoleChangedMessage({
    required String actorName,
    required String memberName,
    required String oldRole,
    required String newRole,
    required String homeName,
  }) {
    final oldRoleName = roleName(oldRole);
    final newRoleName = roleName(newRole);

    return choose(
      vi: "$actorName đã đổi vai trò của $memberName từ $oldRoleName thành $newRoleName trong nhà \"$homeName\".",
      fil:
          "Pinalitan ni $actorName ang tungkulin ni $memberName mula $oldRoleName patungong $newRoleName sa bahay na \"$homeName\".",
      km: "$actorName បានផ្លាស់ប្ដូរតួនាទីរបស់ $memberName ពី $oldRoleName ទៅ $newRoleName ក្នុង \"$homeName\"។",
      en: "$actorName changed $memberName's role from $oldRoleName to $newRoleName in \"$homeName\".",
      zh: "$actorName 已将 $memberName 在“$homeName”中的角色从 $oldRoleName 更改为 $newRoleName。",
      ko: "$actorName님이 \"$homeName\"에서 $memberName님의 역할을 변경했습니다. 이전 역할: $oldRoleName, 새 역할: $newRoleName.",
      ja: "$actorName が「$homeName」で $memberName の役割を $oldRoleName から $newRoleName に変更しました。",
      de: '$actorName hat die Rolle von $memberName in "$homeName" von $oldRoleName zu $newRoleName geändert.',
      ru: '$actorName изменил роль $memberName с $oldRoleName на $newRoleName в доме "$homeName".',

      es: "$actorName cambió el rol de $memberName de $oldRoleName a $newRoleName en «$homeName».",
      fr: _fr(
        vi: "$actorName đã đổi vai trò của $memberName từ $oldRoleName thành $newRoleName trong nhà \"$homeName\".",
        en: "$actorName changed $memberName's role from $oldRoleName to $newRoleName in \"$homeName\".",
      ),
      id: "$actorName mengubah peran $memberName dari $oldRoleName menjadi $newRoleName di \"$homeName\".",
      th: "$actorName เปลี่ยนบทบาทของ $memberName จาก $oldRoleName เป็น $newRoleName ในบ้าน \"$homeName\" แล้ว",
      ms: "$actorName menukar peranan $memberName daripada $oldRoleName kepada $newRoleName dalam rumah \"$homeName\".",
      my: "$actorName က \"$homeName\" တွင် $memberName ၏အခန်းကဏ္ဍကို $oldRoleName မှ $newRoleName သို့ ပြောင်းလဲခဲ့သည်။",
      lo: "$actorName ປ່ຽນບົດບາດຂອງ $memberName ຈາກ $oldRoleName ເປັນ $newRoleName ໃນ \"$homeName\"",
    );
  }

  String unreadChatNotice(int count) => choose(
    vi: "Còn $count tin nhắn chưa đọc",
    fil: "May $count hindi pa nababasang mensahe",
    km: "សារមិនទាន់អាន $count",
    en: "$count unread messages",
    zh: "还有 $count 条未读消息",
    ko: "읽지 않은 메시지 $count개",
    ja: "未読メッセージが $count 件あります",
    de: '$count ungelesene Nachrichten',
    ru: '$count непрочитанных сообщений',

    es: "$count mensajes sin leer",
    fr: _fr(vi: "Còn $count tin nhắn chưa đọc", en: "$count unread messages"),
    id: "$count pesan belum dibaca",
    th: "มีข้อความที่ยังไม่ได้อ่าน $count ข้อความ",
    ms: "Masih ada $count mesej belum dibaca",
    my: "မဖတ်ရသေးသောစာတို $count စောင်ရှိသည်",
    lo: "ມີ $count ຂໍ້ຄວາມທີ່ຍັງບໍ່ອ່ານ",
  );

  String safeStatusTitle() => choose(
    vi: "ĐÃ AN TOÀN",
    en: "SAFE",
    zh: "安全",
    ko: "안전",
    ja: "安全",
    de: 'SICHER',
    ru: 'БЕЗОПАСНО',

    es: "SEGURO",
    fr: _fr(vi: "ĐÃ AN TOÀN", en: "SAFE"),
  );

  String emergencyStatusTitle() => choose(
    vi: "NGUY HIỂM",
    fil: "MAPANGANIB",
    km: "គ្រោះថ្នាក់",
    en: "DANGER",
    zh: "危险",
    ko: "위험",
    ja: "危険",
    de: "GEFAHR",
    ru: "ОПАСНО",
    fr: "DANGER",
    es: "PELIGRO",
    id: "BAHAYA",
    th: "อันตราย",
    ms: "BAHAYA",
    my: "အန္တရာယ်",
    lo: "ອັນຕະລາຍ",
  );

  String emergencySectionTitle() => choose(
    vi: "Nguy hiểm & Khẩn cấp",
    fil: "Panganib at Emergency",
    km: "គ្រោះថ្នាក់ និងបន្ទាន់",
    en: "Danger & Emergency",
    zh: "危险与紧急情况",
    ko: "위험 및 긴급 상황",
    ja: "危険・緊急",
    de: "Gefahr & Notfall",
    ru: "Опасность и экстренная ситуация",
    fr: "Danger et urgence",
    es: "Peligro y emergencia",
    id: "Bahaya & Darurat",
    th: "อันตรายและฉุกเฉิน",
    ms: "Bahaya & Kecemasan",
    my: "အန္တရာယ်နှင့် အရေးပေါ်",
    lo: "ອັນຕະລາຍ ແລະ ສຸກເສີນ",
  );

  String unsafeStatusTitle() => choose(
    vi: "CHƯA AN TOÀN",
    en: "UNSAFE",
    zh: "不安全",
    ko: "안전하지 않음",
    ja: "安全ではありません",
    de: 'NICHT SICHER',
    ru: 'НЕБЕЗОПАСНО',

    es: "NO SEGURO",
    fr: _fr(vi: "CHƯA AN TOÀN", en: "UNSAFE"),
  );

  String safeReminderBody() => choose(
    vi: "Hãy an tâm nghỉ ngơi.",
    en: "You can rest assured.",
    zh: "你可以放心休息。",
    ko: "안심하고 쉬셔도 됩니다.",
    ja: "安心してお休みください。",
    de: 'Du kannst beruhigt sein.',
    ru: 'Можете быть спокойны.',

    es: "Puedes descansar con tranquilidad.",
    fr: _fr(vi: "Hãy an tâm nghỉ ngơi.", en: "You can rest assured."),
  );

  String unsafeReminderBody(String reason) {
    final cleanReason = reason.trim();

    if (cleanReason.isNotEmpty) {
      return statusText(cleanReason);
    }

    return choose(
      vi: "Có thiết bị chưa an toàn.",
      en: "Some devices are not safe.",
      zh: "有设备处于不安全状态。",
      ko: "일부 기기가 안전하지 않습니다.",
      ja: "一部のデバイスが安全ではありません。",
      de: 'Einige Geräte sind nicht sicher.',
      ru: 'Некоторые устройства небезопасны.',

      es: "Algunos dispositivos no son seguros.",
      fr: _fr(
        vi: "Có thiết bị chưa an toàn.",
        en: "Some devices are not safe.",
      ),
    );
  }

  String safetyReminderBody({required bool isSafe, String reason = ""}) {
    return isSafe
        ? "✅ ${safeStatusTitle()}\n${safeReminderBody()}"
        : "⚠️ ${unsafeStatusTitle()}\n${unsafeReminderBody(reason)}";
  }

  String safetyReminderNotificationTitle({
    required String homeTitle,
    required bool isSafe,
  }) {
    final cleanHomeTitle = homeTitle.trim().isNotEmpty
        ? homeTitle.trim()
        : "SafeHome";

    return "$cleanHomeTitle · ${isSafe ? safeStatusTitle() : unsafeStatusTitle()}";
  }

  String updatingLocationNotificationTitle() => choose(
    vi: "SafeHome đang cập nhật vị trí",
    en: "SafeHome is updating location",
    zh: "SafeHome 正在更新位置",
    ko: "SafeHome이 위치를 업데이트하는 중입니다",
    ja: "SafeHome が位置情報を更新中です",
    de: 'SafeHome aktualisiert den Standort',
    ru: 'SafeHome обновляет местоположение',

    es: "SafeHome está actualizando la ubicación",
    fr: _fr(
      vi: "SafeHome đang cập nhật vị trí",
      en: "SafeHome is updating location",
    ),
  );

  String updatingLocationNotificationBody() => choose(
    vi: "Đang theo dõi để tự động bật Chế độ Bảo vệ.",
    en: "Monitoring to turn on Guard mode automatically.",
    zh: "正在监测以自动开启布防模式。",
    ko: "보호 모드를 자동으로 켜기 위해 모니터링 중입니다.",
    ja: "Guardモードを自動でオンにするため監視しています。",
    de: 'Überwachung aktiv, um den Schutzmodus automatisch zu aktivieren.',
    ru: 'Мониторинг для автоматического включения режима охраны.',

    es: "Supervisando para activar automáticamente el modo protección.",
    fr: _fr(
      vi: "Đang theo dõi để tự động bật Chế độ Bảo vệ.",
      en: "Monitoring to turn on Guard mode automatically.",
    ),
  );

  String updatingLocationChannelDescription() => choose(
    vi: "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.",
    en: "Uses location to turn on Guard mode automatically when everyone leaves home.",
    zh: "使用位置在所有人离家时自动开启布防模式。",
    ko: "모두가 집을 떠나면 위치를 사용해 보호 모드를 자동으로 켭니다.",
    ja: "全員が外出したときに位置情報を使ってGuardモードを自動でオンにします。",
    de: 'Nutzt den Standort, um den Schutzmodus automatisch zu aktivieren, wenn alle das Zuhause verlassen.',
    ru: 'Использует местоположение, чтобы автоматически включать режим охраны, когда все покидают дом.',

    es: "Usa la ubicación para activar automáticamente el modo protección cuando todos salen de casa.",
    fr: _fr(
      vi: "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.",
      en: "Uses location to turn on Guard mode automatically when everyone leaves home.",
    ),
  );

  String alarmCategoryTitle(String category) {
    switch (category.trim().toLowerCase()) {
      case "sos":
        return choose(
          vi: "CẢNH BÁO SOS",
          en: "SOS ALERT",
          zh: "SOS 警报",
          ko: "SOS 경보",
          ja: "SOS アラート",
          de: 'SOS-Alarm',
          ru: 'SOS-ТРЕВОГА',

          es: "ALERTA SOS",
          fr: _fr(vi: "CẢNH BÁO SOS", en: "SOS ALERT"),
        );
      case "smoke":
      case "fire":
        return choose(
          vi: "CẢNH BÁO KHÓI / CHÁY",
          en: "SMOKE / FIRE ALERT",
          zh: "烟雾 / 火灾警报",
          ko: "연기 / 화재 경보",
          ja: "煙 / 火災アラート",
          de: 'RAUCH-/FEUERALARM',
          ru: 'ТРЕВОГА ДЫМ / ПОЖАР',

          es: "ALERTA DE HUMO / INCENDIO",
          fr: _fr(vi: "CẢNH BÁO KHÓI / CHÁY", en: "SMOKE / FIRE ALERT"),
        );
      case "flood":
      case "water":
        return choose(
          vi: "CẢNH BÁO NGẬP NƯỚC",
          en: "FLOOD ALERT",
          zh: "漏水警报",
          ko: "침수 경보",
          ja: "浸水アラート",
          de: 'ÜBERSCHWEMMUNGSALARM',
          ru: 'ТРЕВОГА ЗАТОПЛЕНИЯ',

          es: "ALERTA DE INUNDACIÓN",
          fr: _fr(vi: "CẢNH BÁO NGẬP NƯỚC", en: "FLOOD ALERT"),
        );
      case "gas":
        return choose(
          vi: "CẢNH BÁO RÒ KHÍ",
          en: "GAS LEAK ALERT",
          zh: "燃气泄漏警报",
          ko: "가스 누출 경보",
          ja: "ガス漏れアラート",
          de: 'GASLECK-Alarm',
          ru: 'ТРЕВОГА УТЕЧКИ ГАЗА',

          es: "ALERTA DE FUGA DE GAS",
          fr: _fr(vi: "CẢNH BÁO RÒ KHÍ", en: "GAS LEAK ALERT"),
        );
      case "door":
      case "window":
      case "gate":
      case "lock":
        return choose(
          vi: "CẢNH BÁO CỬA",
          en: "DOOR ALERT",
          zh: "门警报",
          ko: "문 경보",
          ja: "ドアアラート",
          de: 'TÜR-Alarm',
          ru: 'ТРЕВОГА ДВЕРИ',

          es: "ALERTA DE PUERTA",
          fr: _fr(vi: "CẢNH BÁO CỬA", en: "DOOR ALERT"),
        );
      default:
        return choose(
          vi: "CẢNH BÁO AN NINH",
          en: "SECURITY ALERT",
          zh: "安全警报",
          ko: "보안 경보",
          ja: "セキュリティアラート",
          de: 'SICHERHEITSALARM',
          ru: 'ТРЕВОГА БЕЗОПАСНОСТИ',

          es: "ALERTA DE SEGURIDAD",
          fr: _fr(vi: "CẢNH BÁO AN NINH", en: "SECURITY ALERT"),
        );
    }
  }

  String stopAlarmLabel() => choose(
    vi: "TẮT CẢNH BÁO",
    en: "STOP ALERT",
    zh: "停止警报",
    ko: "경보 중지",
    ja: "アラートを停止",
    de: 'Alarm STOPPEN',
    ru: 'ОСТАНОВИТЬ ТРЕВОГУ',

    es: "DETENER ALERTA",
    fr: _fr(vi: "TẮT CẢNH BÁO", en: "STOP ALERT"),
  );

  String stopSirenLabel() => choose(
    vi: "TẮT CÒI",
    my: "ဥဩပိတ်ရန်",
    en: "STOP SIREN",
    zh: "关闭警笛",
    ko: "사이렌 끄기",
    ja: "サイレン停止",
    de: "SIRENE STOPPEN",
    ru: "ВЫКЛЮЧИТЬ СИРЕНУ",
    es: "DETENER SIRENA",
    fr: "ARRÊTER LA SIRÈNE",
    id: "MATIKAN SIRENE",
    th: "ปิดไซเรน",
    ms: "HENTIKAN SIREN",
    fil: "PATAYIN ANG SIRENA",
    km: "បិទស៊ីរ៉ែន",
    lo: "ຢຸດສຽງໄຊເຣນ",
  );

  String confirmStopSirenTitle() => choose(
    vi: "Tắt còi báo động?",
    my: "သတိပေးဥဩကို ပိတ်မလား?",
    en: "Stop the alarm siren?",
    zh: "关闭警笛？",
    ko: "경보 사이렌을 끌까요?",
    ja: "警報サイレンを停止しますか？",
    de: "Alarmsirene stoppen?",
    ru: "Выключить тревожную сирену?",
    es: "¿Detener la sirena de alarma?",
    fr: "Arrêter la sirène d’alarme ?",
    id: "Matikan sirene alarm?",
    th: "ปิดไซเรนเตือนภัยหรือไม่",
    ms: "Hentikan siren penggera?",
    fil: "Patayin ang alarma siren?",
    km: "បិទស៊ីរ៉ែនប្រកាសអាសន្ន?",
    lo: "ຢຸດສຽງໄຊເຣນສັນຍານເຕືອນໄພບໍ?",
  );

  String confirmStopSirenBody() => choose(
    vi: "Còi vật lý sẽ dừng, nhưng cảnh báo vẫn tiếp tục cho đến khi sự cố được xử lý.\n\nBạn chắc chắn muốn tắt còi?",
    my: "ဥဩသံရပ်သွားမည်ဖြစ်သော်လည်း ဖြစ်စဉ်ကို ဖြေရှင်းပြီးသည်အထိ သတိပေးချက် ဆက်လက်အသက်ဝင်နေမည်။\n\nဥဩကို ပိတ်လိုသည်မှာ သေချာပါသလား?",
    en: "The physical siren will stop, but the alert will remain active until the incident is handled.\n\nAre you sure you want to stop the siren?",
    zh: "实体警笛将停止，但警报会保持有效，直到事件得到处理。\n\n确定要关闭警笛吗？",
    ko: "실물 사이렌은 멈추지만 문제가 처리될 때까지 경보는 계속 유지됩니다.\n\n사이렌을 끄시겠습니까?",
    ja: "物理サイレンは停止しますが、問題が解決されるまで警報は継続します。\n\nサイレンを停止しますか？",
    de: "Die physische Sirene wird gestoppt, der Alarm bleibt jedoch aktiv, bis der Vorfall bearbeitet wurde.\n\nMöchtest du die Sirene wirklich stoppen?",
    ru: "Физическая сирена остановится, но тревога останется активной до устранения происшествия.\n\nВы действительно хотите выключить сирену?",
    es: "La sirena física se detendrá, pero la alerta seguirá activa hasta que se gestione el incidente.\n\n¿Seguro que quieres detener la sirena?",
    fr: "La sirène physique s’arrêtera, mais l’alerte restera active jusqu’au traitement de l’incident.\n\nVoulez-vous vraiment arrêter la sirène ?",
    id: "Sirene fisik akan berhenti, tetapi peringatan tetap aktif sampai insiden ditangani.\n\nYakin ingin mematikan sirene?",
    th: "ไซเรนจริงจะหยุด แต่การแจ้งเตือนจะยังคงทำงานจนกว่าจะจัดการเหตุการณ์เรียบร้อย\n\nยืนยันที่จะปิดไซเรนหรือไม่",
    ms: "Siren fizikal akan berhenti, tetapi amaran kekal aktif sehingga insiden ditangani.\n\nPasti mahu menghentikan siren?",
    fil:
        "Hihinto ang pisikal na sirena, ngunit mananatiling aktibo ang alerto hanggang maresolba ang insidente.\n\nSigurado ka bang papatayin ang sirena?",
    km: "ស៊ីរ៉ែនផ្ទាល់នឹងឈប់ ប៉ុន្តែការជូនដំណឹងនៅតែសកម្មរហូតដល់ហេតុការណ៍ត្រូវបានដោះស្រាយ។\n\nតើអ្នកប្រាកដថាចង់បិទស៊ីរ៉ែនឬ?",
    lo: "ສຽງໄຊເຣນຈະຢຸດ ແຕ່ການເຕືອນຈະຍັງດຳເນີນຕໍ່ຈົນກວ່າເຫດການຈະຖືກແກ້ໄຂ.\n\nທ່ານແນ່ໃຈບໍວ່າຈະຢຸດສຽງໄຊເຣນ?",
  );

  String sirenStoppedMessage() => choose(
    vi: "Đã gửi lệnh tắt còi. Cảnh báo vẫn đang được theo dõi.",
    my: "ဥဩပိတ်ရန် အမိန့်ပို့ပြီးပါပြီ။ သတိပေးချက်ကို ဆက်လက်စောင့်ကြည့်နေသည်။",
    en: "The siren stop command was sent. The alert is still being monitored.",
    zh: "已发送关闭警笛命令。警报仍在监控中。",
    ko: "사이렌 중지 명령을 보냈습니다. 경보는 계속 모니터링됩니다.",
    ja: "サイレン停止命令を送信しました。警報の監視は継続します。",
    de: "Der Befehl zum Stoppen der Sirene wurde gesendet. Der Alarm wird weiter überwacht.",
    ru: "Команда выключения сирены отправлена. Тревога продолжает отслеживаться.",
    es: "Se envió la orden para detener la sirena. La alerta sigue supervisada.",
    fr: "La commande d’arrêt de la sirène a été envoyée. L’alerte reste surveillée.",
    id: "Perintah mematikan sirene telah dikirim. Peringatan tetap dipantau.",
    th: "ส่งคำสั่งปิดไซเรนแล้ว ระบบยังคงติดตามการแจ้งเตือน",
    ms: "Arahan menghentikan siren telah dihantar. Amaran masih dipantau.",
    fil:
        "Naipadala ang utos na patayin ang sirena. Patuloy pa ring binabantayan ang alerto.",
    km: "បានផ្ញើពាក្យបញ្ជាបិទស៊ីរ៉ែន។ ការជូនដំណឹងនៅតែត្រូវបានតាមដាន។",
    lo: "ສົ່ງຄຳສັ່ງຢຸດສຽງໄຊເຣນແລ້ວ. ການເຕືອນຍັງຖືກຕິດຕາມຢູ່.",
  );

  String sirenStopUnavailableMessage() => choose(
    vi: "Không tìm thấy cảnh báo đang hoạt động hoặc chưa thể gửi lệnh tắt còi.",
    my: "အသက်ဝင်နေသောသတိပေးချက် မတွေ့ပါ သို့မဟုတ် ဥဩပိတ်ရန် အမိန့်ပို့၍မရပါ။",
    en: "No active alert was found, or the siren stop command could not be sent.",
    zh: "未找到有效警报，或无法发送关闭警笛命令。",
    ko: "활성 경보를 찾지 못했거나 사이렌 중지 명령을 보낼 수 없습니다.",
    ja: "有効な警報が見つからないか、サイレン停止命令を送信できませんでした。",
    de: "Kein aktiver Alarm gefunden oder der Befehl zum Stoppen der Sirene konnte nicht gesendet werden.",
    ru: "Активная тревога не найдена или не удалось отправить команду выключения сирены.",
    es: "No se encontró una alerta activa o no se pudo enviar la orden para detener la sirena.",
    fr: "Aucune alerte active n’a été trouvée ou la commande d’arrêt de la sirène n’a pas pu être envoyée.",
    id: "Tidak ada peringatan aktif atau perintah mematikan sirene tidak dapat dikirim.",
    th: "ไม่พบการแจ้งเตือนที่ทำงานอยู่ หรือไม่สามารถส่งคำสั่งปิดไซเรนได้",
    ms: "Tiada amaran aktif ditemui atau arahan menghentikan siren tidak dapat dihantar.",
    fil:
        "Walang nakitang aktibong alerto o hindi maipadala ang utos na patayin ang sirena.",
    km: "រកមិនឃើញការជូនដំណឹងសកម្ម ឬមិនអាចផ្ញើពាក្យបញ្ជាបិទស៊ីរ៉ែនបាន។",
    lo: "ບໍ່ພົບການເຕືອນທີ່ກຳລັງເຮັດວຽກ ຫຼື ຍັງສົ່ງຄຳສັ່ງຢຸດສຽງໄຊເຣນບໍ່ໄດ້.",
  );

  // Giữ tương thích với FullscreenAlarmPage từ commit local 7a47dac.
  // Hai API này chỉ tắt còi vật lý; incident/cảnh báo vẫn tiếp tục hoạt động.
  String muteHomeSirenLabel() => choose(
    vi: "TẮT CÒI TRONG NHÀ",
    my: "အိမ်ရှိ ဥဩကို ပိတ်ရန်",
    en: "SILENCE HOME SIREN",
    zh: "关闭家中警报器",
    ko: "집 사이렌 끄기",
    ja: "家のサイレンを停止",
    de: "HAUSSIRENE STUMMSCHALTEN",
    ru: "ВЫКЛЮЧИТЬ СИРЕНУ ДОМА",
    fr: "COUPER LA SIRÈNE DU DOMICILE",
    es: "SILENCIAR SIRENA DE CASA",
    id: "MATIKAN SIRENE RUMAH",
    th: "ปิดเสียงไซเรนในบ้าน",
    ms: "SENYAPKAN SIREN RUMAH",
    fil: "PATAYIN ANG SIRENA SA BAHAY",
    km: "បិទសំឡេងស៊ីរ៉ែនក្នុងផ្ទះ",
    lo: "ຢຸດສຽງໄຊເຣນໃນເຮືອນ",
  );

  String homeSirenMutedMessage() => choose(
    vi: "Đã tắt còi trong nhà. Cảnh báo vẫn tiếp tục cho đến khi được xử lý.",
    my: "အိမ်ရှိ ဥဩကို ပိတ်ပြီးပါပြီ။ သတိပေးချက်ကို ကိုင်တွယ်ဖြေရှင်းပြီးသည်အထိ ဆက်လက်အသက်ဝင်နေမည်။",
    en: "The home siren is silenced. The alert remains active until it is handled.",
    zh: "家中警报器已关闭。警报会保持有效，直到问题得到处理。",
    ko: "집 사이렌을 껐습니다. 문제가 처리될 때까지 경보는 계속 유지됩니다.",
    ja: "家のサイレンを停止しました。対応が完了するまでアラートは継続します。",
    de: "Die Haussirene wurde stummgeschaltet. Der Alarm bleibt aktiv, bis er bearbeitet wurde.",
    ru: "Сирена дома выключена. Тревога останется активной до устранения причины.",
    fr: "La sirène du domicile est coupée. L’alerte reste active jusqu’à sa prise en charge.",
    es: "La sirena de casa está silenciada. La alerta seguirá activa hasta que se resuelva.",
    id: "Sirene rumah telah dimatikan. Peringatan tetap aktif sampai ditangani.",
    th: "ปิดเสียงไซเรนในบ้านแล้ว การแจ้งเตือนจะยังทำงานจนกว่าจะได้รับการจัดการ",
    ms: "Siren rumah telah disenyapkan. Amaran kekal aktif sehingga ditangani.",
    fil:
        "Napatay na ang sirena sa bahay. Mananatiling aktibo ang alerto hanggang maresolba.",
    km: "បានបិទសំឡេងស៊ីរ៉ែនក្នុងផ្ទះ។ ការជូនដំណឹងនៅតែសកម្មរហូតដល់បានដោះស្រាយ។",
    lo: "ປິດສຽງໄຊເຣນໃນເຮືອນແລ້ວ. ການເຕືອນຍັງດຳເນີນຕໍ່ຈົນກວ່າຈະຖືກແກ້ໄຂ.",
  );

  String defaultHomeName() => choose(
    vi: "Nhà",
    en: "Home",
    zh: "家庭",
    ko: "집",
    ja: "家",
    de: 'Zuhause',
    ru: 'Дом',

    es: "Casa",
    fr: _fr(vi: "Nhà", en: "Home"),
  );

  String defaultUnsafeReminderReason() => unsafeReminderBody("");

  String alarmActionErrorMessage() => choose(
    vi: "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.",
    en: "Could not confirm with SafeHome. Check your connection and try again.",
    zh: "无法与 SafeHome 确认。请检查连接后重试。",
    ko: "SafeHome에 확인할 수 없습니다. 연결을 확인한 뒤 다시 시도해 주세요.",
    ja: "SafeHome に確認できませんでした。接続を確認してもう一度お試しください。",
    de: 'Bestätigung mit SafeHome fehlgeschlagen. Prüfe die Verbindung und versuche es erneut.',
    ru: 'Не удалось подтвердить через SafeHome. Проверьте подключение и повторите попытку.',

    es: "No se pudo confirmar con SafeHome. Revisa la conexión e inténtalo de nuevo.",
    fr: _fr(
      vi: "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.",
      en: "Could not confirm with SafeHome. Check your connection and try again.",
    ),
  );

  String confirmStopAlarmBody() => choose(
    vi: "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?",
    en: "Only stop the alert after checking the home's condition.\n\nAre you sure you want to stop the alert?",
    zh: "请仅在检查家庭状态后停止警报。\n\n确定要停止警报吗？",
    ko: "집 상태를 확인한 뒤에만 경보를 중지하세요.\n\n경보를 중지하시겠습니까?",
    ja: "家の状態を確認してからアラートを停止してください。\n\nアラートを停止しますか？",
    de: 'Stoppe den Alarm erst, nachdem du den Zustand des Zuhauses geprüft hast.\n\nMöchtest du den Alarm wirklich stoppen?',
    ru: 'Останавливайте тревогу только после проверки состояния дома.\n\nВы действительно хотите остановить тревогу?',

    es: "Detén la alerta solo después de revisar el estado de la casa.\n\n¿Seguro que quieres detener la alerta?",
    fr: _fr(
      vi: "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?",
      en: "Only stop the alert after checking the home's condition.\n\nAre you sure you want to stop the alert?",
    ),
    my: "အိမ်အခြေအနေကို စစ်ဆေးပြီးမှသာ သတိပေးချက်ကို ပိတ်ပါ။\n\nသတိပေးချက်ကို ပိတ်လိုသည်မှာ သေချာပါသလား?",
    lo: "ປິດການເຕືອນຫຼັງຈາກກວດສະພາບໃນເຮືອນແລ້ວເທົ່ານັ້ນ.\n\nທ່ານແນ່ໃຈບໍວ່າຈະປິດການເຕືອນ?",
  );

  String priorityAlarmNotificationTitle() => choose(
    vi: "🚨 SafeHome phát hiện cảnh báo",
    en: "🚨 SafeHome detected an alert",
    zh: "🚨 SafeHome 检测到警报",
    ko: "🚨 SafeHome이 경보를 감지했습니다",
    ja: "🚨 SafeHome がアラートを検知しました",
    de: '🚨 SafeHome hat einen Alarm erkannt',
    ru: '🚨 SafeHome обнаружил тревогу',

    es: "🚨 SafeHome detectó una alerta",
    fr: _fr(
      vi: "🚨 SafeHome phát hiện cảnh báo",
      en: "🚨 SafeHome detected an alert",
    ),
  );

  String openSafeHomeToCheckBody() => choose(
    vi: "Mở SafeHome để kiểm tra ngay.",
    en: "Open SafeHome to check now.",
    zh: "打开 SafeHome 立即检查。",
    ko: "SafeHome을 열어 지금 확인하세요.",
    ja: "SafeHome を開いて今すぐ確認してください。",
    de: 'Öffne SafeHome, um sofort zu prüfen.',
    ru: 'Откройте SafeHome, чтобы проверить сейчас.',

    es: "Abre SafeHome para revisar ahora.",
    fr: _fr(
      vi: "Mở SafeHome để kiểm tra ngay.",
      en: "Open SafeHome to check now.",
    ),
  );

  String homeChatNewMessages(int count) => choose(
    vi: "$count tin nhắn mới",
    fil: "$count bagong mensahe",
    km: "សារថ្មី $count",
    en: "$count new messages",
    zh: "$count 条新消息",
    ko: "새 메시지 $count개",
    ja: "新着メッセージが $count 件あります",
    de: '$count neue Nachrichten',
    ru: '$count новых сообщений',

    es: "$count mensajes nuevos",
    fr: _fr(vi: "$count tin nhắn mới", en: "$count new messages"),
    id: "$count pesan baru",
    th: "$count ข้อความใหม่",
    ms: "$count mesej baharu",
    my: "စာတိုအသစ် $count စောင်",
    lo: "$count ຂໍ້ຄວາມໃໝ່",
  );

  String homeChatTitle() => choose(
    vi: "Tin nhắn HomeChat",
    en: "HomeChat message",
    zh: "HomeChat 消息",
    ko: "HomeChat 메시지",
    ja: "HomeChat メッセージ",
    de: 'HomeChat-Nachricht',
    ru: 'Сообщение HomeChat',

    es: "Mensaje de HomeChat",
    fr: _fr(vi: "Tin nhắn HomeChat", en: "HomeChat message"),
  );

  String newMessageInHome(String homeName) => choose(
    vi: "Tin nhắn mới trong $homeName",
    fil: "Bagong mensahe sa $homeName",
    km: "សារថ្មីនៅក្នុង $homeName",
    en: "New message in $homeName",
    zh: "$homeName 有新消息",
    ko: "$homeName의 새 메시지",
    ja: "$homeName に新着メッセージ",
    de: 'Neue Nachricht in $homeName',
    ru: 'Новое сообщение в $homeName',
    fr: "Nouveau message dans $homeName",
    es: "Mensaje nuevo en $homeName",
    id: "Pesan baru di $homeName",
    th: "ข้อความใหม่ใน $homeName",
    ms: "Mesej baharu dalam $homeName",
    my: "$homeName တွင် စာတိုအသစ်ရှိသည်",
    lo: "ຂໍ້ຄວາມໃໝ່ໃນ $homeName",
  );

  String homeChatSenderMessage(String senderName) => choose(
    vi: "$senderName đã gửi một tin nhắn",
    fil: "Nagpadala ng mensahe si $senderName",
    km: "$senderName បានផ្ញើសារ",
    en: "$senderName sent a message",
    zh: "$senderName 发送了一条消息",
    ko: "$senderName님이 메시지를 보냈습니다",
    ja: "$senderName がメッセージを送信しました",
    de: '$senderName hat eine Nachricht gesendet',
    ru: '$senderName отправил сообщение',

    es: "$senderName envió un mensaje",
    fr: _fr(
      vi: "$senderName đã gửi một tin nhắn",
      en: "$senderName sent a message",
    ),
    id: "$senderName mengirim pesan",
    th: "$senderName ส่งข้อความ",
    ms: "$senderName menghantar mesej",
    my: "$senderName က စာတိုတစ်စောင် ပို့ခဲ့သည်",
    lo: "$senderName ສົ່ງຂໍ້ຄວາມ",
  );

  String homeChatNewMessage() => choose(
    vi: "Bạn có tin nhắn mới",
    en: "You have a new message",
    zh: "你有一条新消息",
    ko: "새 메시지가 있습니다",
    ja: "新着メッセージがあります",
    de: 'Du hast eine neue Nachricht',
    ru: 'У вас новое сообщение',

    es: "Tienes un mensaje nuevo",
    fr: _fr(vi: "Bạn có tin nhắn mới", en: "You have a new message"),
  );

  String chatTypingOne(String name) => choose(
    vi: "$name đang chuẩn bị gửi tin...",
    my: "$name စာရိုက်နေသည်...",
    fil: "Nagta-type si $name...",
    km: "$name កំពុងវាយសារ...",
    en: "$name is typing...",
    zh: "$name 正在输入...",
    ko: "$name님이 입력 중...",
    ja: "$name が入力中...",
    de: '$name schreibt...',
    ru: '$name печатает...',
    fr: "$name est en train d'écrire...",
    es: "$name está escribiendo...",
    id: "$name sedang mengetik...",
    th: "$name กำลังพิมพ์...",
    ms: "$name sedang menaip...",
    lo: "$name ກຳລັງພິມ...",
  );

  String chatTypingTwo(String name1, String name2) => choose(
    vi: "$name1 và $name2 đang chuẩn bị gửi tin...",
    my: "$name1 နှင့် $name2 စာရိုက်နေသည်...",
    fil: "Nagta-type sina $name1 at $name2...",
    km: "$name1 និង $name2 កំពុងវាយសារ...",
    en: "$name1 and $name2 are typing...",
    zh: "$name1 和 $name2 正在输入...",
    ko: "$name1님과 $name2님이 입력 중...",
    ja: "$name1 と $name2 が入力中...",
    de: '$name1 und $name2 schreiben...',
    ru: '$name1 и $name2 печатают...',
    fr: "$name1 et $name2 sont en train d'écrire...",
    es: "$name1 y $name2 están escribiendo...",
    id: "$name1 dan $name2 sedang mengetik...",
    th: "$name1 และ $name2 กำลังพิมพ์...",
    ms: "$name1 dan $name2 sedang menaip...",
    lo: "$name1 ແລະ $name2 ກຳລັງພິມ...",
  );

  String chatTypingMany(String name, int otherCount) => choose(
    vi: "$name và $otherCount người khác đang chuẩn bị gửi tin...",
    my: "$name နှင့် အခြား $otherCount ဦး စာရိုက်နေသည်...",
    fil: "Nagta-type si $name at $otherCount pang iba...",
    km: "$name និងមនុស្ស $otherCount នាក់ទៀតកំពុងវាយសារ...",
    en: "$name and $otherCount others are typing...",
    zh: "$name 和另外 $otherCount 人正在输入...",
    ko: "$name님 외 $otherCount명이 입력 중...",
    ja: "$name と他 $otherCount 人が入力中...",
    de: '$name und $otherCount weitere schreiben...',
    ru: '$name и еще $otherCount печатают...',
    fr: "$name et $otherCount autres sont en train d'écrire...",
    es: "$name y $otherCount más están escribiendo...",
    id: "$name dan $otherCount lainnya sedang mengetik...",
    th: "$name และคนอื่นอีก $otherCount คนกำลังพิมพ์...",
    ms: "$name dan $otherCount yang lain sedang menaip...",
    lo: "$name ແລະອີກ $otherCount ຄົນກຳລັງພິມ...",
  );

  String androidLegacyAlarmChannelDescription() => choose(
    vi: "Kênh báo động cũ để giữ tương thích",
    my: "ကိုက်ညီမှုရှိစေရန် ထားရှိသော အရေးပေါ်အချက်ပေးသံ ချန်နယ်အဟောင်း",
    fil: "Lumang alarma channel para mapanatili ang compatibility",
    km: "ឆានែល សំឡេងរោទិ៍ ចាស់សម្រាប់រក្សាភាពត្រូវគ្នា",
    en: "Legacy Alarm channel kept for compatibility",
    zh: "为保持兼容而保留的旧 警报 通道",
    ko: "호환성을 위해 유지되는 기존 경보 채널",
    ja: "互換性のために保持される旧 警報 チャンネル",
    de: 'Alter Alarm-Kanal zur Kompatibilität',
    ru: 'Устаревший канал тревога для совместимости',
    es: "Canal de alarma antiguo conservado por compatibilidad",
    fr: _fr(
      vi: "Kênh báo động cũ để giữ tương thích",
      en: "Legacy Alarm channel kept for compatibility",
    ),
    th: "ช่อง สัญญาณเตือน เดิมเพื่อรองรับความเข้ากันได้",
    ms: "Saluran penggera lama dikekalkan untuk keserasian",
    lo: "ຊ່ອງສັນຍານເຕືອນໄພເກົ່າເພື່ອຮັກສາຄວາມເຂົ້າກັນໄດ້",
  );

  String androidAlarmFullscreenChannelName() => choose(
    vi: "SafeHome báo động toàn màn hình",
    my: "SafeHome မျက်နှာပြင်အပြည့် အရေးပေါ်အချက်ပေးသံ",
    fil: "Full-screen na alarma ng SafeHome",
    km: "SafeHome សំឡេងរោទិ៍ ពេញអេក្រង់",
    en: "SafeHome Alarm Fullscreen",
    zh: "SafeHome 警报 全屏",
    ko: "SafeHome 경보 전체 화면",
    ja: "SafeHome 警報 フルスクリーン",
    de: 'SafeHome Alarm Vollbild',
    ru: 'SafeHome тревога на весь экран',
    es: "SafeHome alarma pantalla completa",
    fr: _fr(
      vi: "SafeHome báo động toàn màn hình",
      en: "SafeHome Alarm Fullscreen",
    ),
    th: "สัญญาณเตือน ของ SafeHome แบบเต็มหน้าจอ",
    ms: "Penggera skrin penuh SafeHome",
    lo: "ສັນຍານເຕືອນໄພ SafeHome ເຕັມຈໍ",
  );

  String androidAlarmFullscreenChannelDescription() => choose(
    vi: "Mở cảnh báo toàn màn hình; âm còi phát từ trang báo động",
    my: "မျက်နှာပြင်အပြည့် သတိပေးချက်ဖွင့်ပြီး အရေးပေါ်အချက်ပေးသံ စာမျက်နှာမှ ဥဩသံ ဖွင့်သည်",
    fil:
        "Buksan ang full-screen alert; tutunog ang sirena mula sa pahina ng alarma",
    km: "បើកការជូនដំណឹងពេញអេក្រង់; ស៊ីរ៉ែនបន្លឺពីទំព័រ សំឡេងរោទិ៍",
    en: "Opens fullscreen alarms; siren sound plays from the Alarm page",
    zh: "打开全屏警报；警笛声由 警报 页面播放",
    ko: "전체 화면 경보을 엽니다. 사이렌 소리는 경보 페이지에서 재생됩니다",
    ja: "全画面アラームを開き、サイレン音は 警報 ページから再生されます",
    de: 'Öffnet Vollbild-Alarme; der Sirenenton wird auf der Alarm-Seite abgespielt',
    ru: 'Открывает тревоги на весь экран; сирена воспроизводится со страницы тревога',
    es: "Abre alarmas a pantalla completa; la sirena se reproduce desde la página alarma",
    fr: _fr(
      vi: "Mở cảnh báo toàn màn hình; âm còi phát từ trang báo động",
      en: "Opens fullscreen alarms; siren sound plays from the Alarm page",
    ),
    th: "เปิดการแจ้งเตือนแบบเต็มหน้าจอ เสียงไซเรนจะดังจากหน้า สัญญาณเตือน",
    ms: "Membuka amaran skrin penuh; bunyi siren dimainkan dari halaman penggera",
    lo: "ເປີດການເຕືອນເຕັມຈໍ; ສຽງໄຊເຣນຈະຫຼິ້ນຈາກໜ້າສັນຍານເຕືອນໄພ",
  );

  String androidEmergencyPriorityChannelName() => choose(
    vi: "SafeHome cảnh báo khẩn cấp",
    my: "SafeHome အရေးပေါ်ဦးစားပေးသတိပေးချက်",
    fil: "Mga alertong pang-emergency ng SafeHome",
    km: "ការជូនដំណឹងបន្ទាន់របស់ SafeHome",
    en: "SafeHome Emergency Priority",
    zh: "SafeHome 紧急优先警报",
    ko: "SafeHome 긴급 우선 알림",
    ja: "SafeHome 緊急優先アラート",
    de: 'SafeHome Notfall-Priorität',
    ru: 'SafeHome экстренный приоритет',
    es: "SafeHome prioridad de emergencia",
    fr: _fr(
      vi: "SafeHome cảnh báo khẩn cấp",
      en: "SafeHome Emergency Priority",
    ),
    th: "การแจ้งเตือนฉุกเฉินของ SafeHome",
    ms: "Amaran kecemasan SafeHome",
    lo: "ການເຕືອນສຸກເສີນ SafeHome",
  );

  String androidEmergencyPriorityChannelDescription() => choose(
    vi: "Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình",
    my: "မျက်နှာပြင်အပြည့် မဖွင့်မီ ဦးစားပေးအရေးပေါ်သတိပေးချက်",
    fil:
        "Mataas na priyoridad na alertong pang-emergency bago buksan ang full-screen",
    km: "ការជូនដំណឹងបន្ទាន់អាទិភាពខ្ពស់ មុនពេលបើកពេញអេក្រង់",
    en: "High-priority emergency alert before fullscreen opens",
    zh: "全屏打开前的高优先级紧急警报",
    ko: "전체 화면이 열리기 전의 높은 우선순위 긴급 알림",
    ja: "全画面表示の前に出す高優先度の緊急アラート",
    de: 'Notfallalarm mit hoher Priorität, bevor Vollbild geöffnet wird',
    ru: 'Экстренная тревога высокого приоритета перед открытием на весь экран',
    es: "Alerta de emergencia de alta prioridad antes de abrir pantalla completa",
    fr: _fr(
      vi: "Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình",
      en: "High-priority emergency alert before fullscreen opens",
    ),
    th: "การแจ้งเตือนฉุกเฉินที่มีลำดับความสำคัญสูงก่อนเปิดแบบเต็มหน้าจอ",
    ms: "Amaran kecemasan keutamaan tinggi sebelum skrin penuh dibuka",
    lo: "ການເຕືອນສຸກເສີນຄວາມສຳຄັນສູງກ່ອນເປີດເຕັມຈໍ",
  );

  String androidScheduleFullscreenChannelName() => choose(
    vi: "SafeHome nhắc nhở toàn màn hình",
    my: "SafeHome မျက်နှာပြင်အပြည့် သတိပေးချက်",
    fil: "Full-screen na paalala ng SafeHome",
    km: "SafeHome ការរំលឹក ពេញអេក្រង់",
    en: "SafeHome Schedule Fullscreen",
    zh: "SafeHome 提醒 全屏",
    ko: "SafeHome 리마인더 전체 화면",
    ja: "SafeHome リマインダー フルスクリーン",
    de: 'SafeHome Erinnerung Vollbild',
    ru: 'SafeHome напоминание на весь экран',
    es: "SafeHome recordatorio pantalla completa",
    fr: _fr(
      vi: "SafeHome nhắc nhở toàn màn hình",
      en: "SafeHome Schedule Fullscreen",
    ),
    th: "การเตือนความจำ ของ SafeHome แบบเต็มหน้าจอ",
    ms: "Peringatan skrin penuh SafeHome",
    lo: "ການເຕືອນຄວາມຈຳ SafeHome ເຕັມຈໍ",
  );

  String androidScheduleFullscreenChannelDescription() => choose(
    vi: "Nhắc nhở SafeHome toàn màn hình không âm thanh",
    my: "အသံမပါသော SafeHome မျက်နှာပြင်အပြည့် သတိပေးချက်",
    fil: "Full-screen na paalala ng SafeHome na walang tunog",
    km: "ការរំលឹក ពេញអេក្រង់របស់ SafeHome ដោយគ្មានសំឡេង",
    en: "Silent fullscreen SafeHome Reminder",
    zh: "无声音全屏 SafeHome 提醒",
    ko: "무음 전체 화면 SafeHome 리마인더",
    ja: "音なしの全画面 SafeHome リマインダー",
    de: 'Stummer SafeHome Erinnerung im Vollbild',
    ru: 'Беззвучный SafeHome напоминание на весь экран',
    es: "Recordatorio de SafeHome a pantalla completa sin sonido",
    fr: _fr(
      vi: "Nhắc nhở SafeHome toàn màn hình không âm thanh",
      en: "Silent fullscreen SafeHome Reminder",
    ),
    th: "การเตือนความจำ ของ SafeHome แบบเต็มหน้าจอโดยไม่มีเสียง",
    ms: "Peringatan SafeHome skrin penuh tanpa bunyi",
    lo: "ການເຕືອນຄວາມຈຳ SafeHome ເຕັມຈໍແບບບໍ່ມີສຽງ",
  );

  String androidReminderPriorityChannelName() => choose(
    vi: "SafeHome nhắc nhở ưu tiên cao",
    my: "SafeHome ဦးစားပေး သတိပေးချက်",
    fil: "Mataas na priyoridad na paalala ng SafeHome",
    km: "SafeHome ការរំលឹក អាទិភាពខ្ពស់",
    en: "SafeHome Reminder Priority",
    zh: "SafeHome 提醒 优先",
    ko: "SafeHome 리마인더 우선 알림",
    ja: "SafeHome リマインダー 優先通知",
    de: 'SafeHome Erinnerung Priorität',
    ru: 'SafeHome напоминание с приоритетом',
    es: "SafeHome recordatorio prioritario",
    fr: _fr(
      vi: "SafeHome nhắc nhở ưu tiên cao",
      en: "SafeHome Reminder Priority",
    ),
    th: "การเตือนความจำ ของ SafeHome ลำดับความสำคัญสูง",
    ms: "Peringatan SafeHome keutamaan tinggi",
    lo: "ການເຕືອນຄວາມຈຳ SafeHome ຄວາມສຳຄັນສູງ",
  );

  String androidReminderPriorityChannelDescription() => choose(
    vi: "Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình",
    my: "မျက်နှာပြင်အပြည့် မဖွင့်သော SafeHome ဦးစားပေး သတိပေးချက်",
    fil:
        "Mataas na priyoridad na paalala ng SafeHome na hindi nagbubukas ng full-screen",
    km: "ការរំលឹក អាទិភាពខ្ពស់របស់ SafeHome ដែលមិនបើកពេញអេក្រង់",
    en: "High-priority SafeHome Reminder without fullscreen",
    zh: "高优先级 SafeHome 提醒，不打开全屏",
    ko: "전체 화면 없이 높은 우선순위 SafeHome 리마인더",
    ja: "全画面を開かない高優先度の SafeHome リマインダー",
    de: 'SafeHome Erinnerung mit hoher Priorität ohne Vollbild',
    ru: 'SafeHome напоминание высокого приоритета без полноэкранного режима',
    es: "Recordatorio de SafeHome de alta prioridad sin pantalla completa",
    fr: _fr(
      vi: "Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình",
      en: "High-priority SafeHome Reminder without fullscreen",
    ),
    th: "การเตือนความจำ ของ SafeHome ลำดับความสำคัญสูงโดยไม่เปิดเต็มหน้าจอ",
    ms: "Peringatan SafeHome keutamaan tinggi tanpa skrin penuh",
    lo: "ການເຕືອນຄວາມຈຳ SafeHome ຄວາມສຳຄັນສູງ ໂດຍບໍ່ເປີດເຕັມຈໍ",
  );

  String androidHomeChatChannelDescription() => choose(
    vi: "Tin nhắn mới trong các nhà SafeHome",
    my: "SafeHome အိမ်များရှိ စာတိုအသစ်များ",
    fil: "Mga bagong mensahe sa mga bahay ng SafeHome",
    km: "សារថ្មីនៅក្នុងផ្ទះ SafeHome",
    en: "New messages in SafeHome homes",
    zh: "SafeHome 家庭中的新消息",
    ko: "SafeHome 집의 새 메시지",
    ja: "SafeHome の家の新着メッセージ",
    de: 'Neue Nachrichten in SafeHome-Zuhause',
    ru: 'Новые сообщения в домах SafeHome',
    es: "Mensajes nuevos en las casas SafeHome",
    fr: _fr(
      vi: "Tin nhắn mới trong các nhà SafeHome",
      en: "New messages in SafeHome homes",
    ),
    th: "ข้อความใหม่ในบ้าน SafeHome",
    ms: "Mesej baharu dalam rumah SafeHome",
    lo: "ຂໍ້ຄວາມໃໝ່ໃນເຮືອນ SafeHome",
  );

  String homeSecurityRepeatToast(int minutes) {
    return minutes == 0
        ? choose(
            vi: "Chế độ Bảo vệ sẽ chỉ báo động một lần",
            en: "Guard mode will alert only once",
            zh: "布防模式只会警报一次",
            ko: "보호 모드는 한 번만 경보를 보냅니다",
            ja: "Guardモードは一度だけアラートします",
            de: 'Der Schutzmodus alarmiert nur einmal',
            ru: 'Режим охраны подаст тревогу только один раз',

            es: "El modo protección alertará solo una vez",
            fr: _fr(
              vi: "Chế độ Bảo vệ sẽ chỉ báo động một lần",
              en: "Guard mode will alert only once",
            ),
          )
        : choose(
            vi: "Chế độ Bảo vệ sẽ lặp báo động sau $minutes phút",
            fil:
                "Uulit ang alerto ng Mode ng Proteksyon pagkalipas ng $minutes minuto",
            km: "មុខងារការពារនឹងជូនដំណឹងម្ដងទៀតបន្ទាប់ពី $minutes នាទី",
            en: "Guard mode will repeat the alert after $minutes minutes",
            zh: "布防模式将在 $minutes 分钟后重复警报",
            ko: "보호 모드는 $minutes분 후 경보를 반복합니다",
            ja: "Guardモードは $minutes 分後にアラートを繰り返します",
            de: 'Der Schutzmodus wiederholt den Alarm nach $minutes Minuten',
            ru: 'Режим охраны повторит тревогу через $minutes минут',

            es: "El modo protección repetirá la alerta después de $minutes minutos",
            fr: _fr(
              vi: "Chế độ Bảo vệ sẽ lặp báo động sau $minutes phút",
              en: "Guard mode will repeat the alert after $minutes minutes",
            ),
            id: "Mode Perlindungan akan mengulang peringatan setelah $minutes menit",
            th: "โหมดป้องกันจะแจ้งเตือนซ้ำหลัง $minutes นาที",
            ms: "Mod Perlindungan akan mengulangi penggera selepas $minutes minit",
            my: "ကာကွယ်ရေးမုဒ်က $minutes မိနစ်အကြာတွင် ထပ်မံသတိပေးမည်",
            lo: "ໂໝດປ້ອງກັນຈະເຮັດຊ້ຳການເຕືອນຫຼັງ $minutes ນາທີ",
          );
  }

  String joinRequestsSentMessage(int count) => choose(
    vi: "Đã gửi yêu cầu gia nhập $count nhà",
    fil: "Naipadala ang mga kahilingang sumali sa $count bahay",
    km: "បានផ្ញើសំណើចូលរួមផ្ទះចំនួន $count",
    en: "Join requests sent for $count homes",
    zh: "已发送 $count 个家庭的加入请求",
    ko: "$count개 집에 가입 요청을 보냈습니다",
    ja: "$count 件の家への参加リクエストを送信しました",
    de: 'Beitrittsanfragen für $count Zuhause gesendet',
    ru: 'Запросы на присоединение отправлены для $count домов',

    es: "Solicitudes de acceso enviadas a $count casas",
    fr: _fr(
      vi: "Đã gửi yêu cầu gia nhập $count nhà",
      en: "Join requests sent for $count homes",
    ),
    id: "Permintaan bergabung untuk $count rumah telah dikirim",
    th: "ส่งคำขอเข้าร่วมบ้าน $count หลังแล้ว",
    ms: "Permintaan untuk menyertai $count rumah telah dihantar",
    my: "အိမ် $count လုံးအတွက် ဝင်ခွင့်တောင်းဆိုမှု ပို့ပြီးပါပြီ",
    lo: "ສົ່ງຄຳຂໍເຂົ້າຮ່ວມ $count ເຮືອນແລ້ວ",
  );

  String joinRequestMessage({
    required String requesterName,
    required String homeName,
  }) => choose(
    vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
    fil: "Humiling si $requesterName na sumali sa bahay na \"$homeName\".",
    km: "$requesterName បានស្នើសុំចូលរួម \"$homeName\"។",
    en: "$requesterName requested to join \"$homeName\".",
    zh: "$requesterName 请求加入“$homeName”。",
    ko: "$requesterName님이 \"$homeName\" 가입을 요청했습니다.",
    ja: "$requesterName が「$homeName」への参加をリクエストしています。",
    de: '$requesterName möchte "$homeName" beitreten.',
    ru: '$requesterName запрашивает доступ к дому "$homeName".',

    es: "$requesterName solicitó acceso a «$homeName».",
    fr: _fr(
      vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
      en: "$requesterName requested to join \"$homeName\".",
    ),
    id: "$requesterName meminta bergabung ke \"$homeName\".",
    th: "$requesterName กำลังขอเข้าร่วมบ้าน \"$homeName\"",
    ms: "$requesterName memohon untuk menyertai rumah \"$homeName\".",
    my: "$requesterName က \"$homeName\" သို့ ဝင်ခွင့်တောင်းထားသည်။",
    lo: "$requesterName ກຳລັງຂໍເຂົ້າຮ່ວມ \"$homeName\"",
  );

  String homeDeletedMessage(String homeName) => choose(
    vi: "Bạn đã xoá nhà \"$homeName\".",
    fil: "Tinanggal mo ang bahay na \"$homeName\".",
    km: "អ្នកបានលុប \"$homeName\"។",
    en: "You deleted \"$homeName\".",
    zh: "你已删除“$homeName”。",
    ko: "\"$homeName\"을 삭제했습니다.",
    ja: "「$homeName」を削除しました。",
    de: 'Du hast "$homeName" gelöscht.',
    ru: 'Вы удалили дом "$homeName".',

    es: "Eliminaste \"$homeName\".",
    fr: _fr(
      vi: "Bạn đã xoá nhà \"$homeName\".",
      en: "You deleted \"$homeName\".",
    ),
    id: "Anda menghapus \"$homeName\".",
    th: "คุณได้ลบบ้าน \"$homeName\" แล้ว",
    ms: "Anda telah memadamkan rumah \"$homeName\".",
    my: "\"$homeName\" ကို သင်ဖျက်ပြီးပါပြီ။",
    lo: "ທ່ານລຶບເຮືອນ \"$homeName\" ແລ້ວ",
  );

  String ownershipTransferRequestSentMessage({
    required String homeName,
    required String email,
  }) => choose(
    vi: "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"$homeName\" cho $email.",
    fil:
        "Nagpadala ka kay $email ng kahilingan na ilipat ang pagmamay-ari ng bahay na \"$homeName\".",
    km: "អ្នកបានផ្ញើសំណើផ្ទេរសិទ្ធិម្ចាស់ផ្ទះរបស់ \"$homeName\" ទៅ $email។",
    en: "You sent an ownership transfer request for \"$homeName\" to $email.",
    zh: "你已将“$homeName”的所有权转移请求发送给 $email。",
    ko: "\"$homeName\"의 소유권 이전 요청을 $email에게 보냈습니다.",
    ja: "「$homeName」の所有権譲渡リクエストを $email に送信しました。",
    de: 'Du hast eine Anfrage zur Übertragung des Besitzes von "$homeName" an $email gesendet.',
    ru: 'Вы отправили запрос на передачу прав владельца дома "$homeName" на $email.',

    es: "Enviaste una solicitud de transferencia de propiedad de «$homeName» a $email.",
    fr: _fr(
      vi: "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"$homeName\" cho $email.",
      en: "You sent an ownership transfer request for \"$homeName\" to $email.",
    ),
    id: "Anda mengirim permintaan pengalihan kepemilikan \"$homeName\" ke $email.",
    th: "คุณได้ส่งคำขอโอนสิทธิ์เจ้าของบ้านของ \"$homeName\" ให้ $email แล้ว",
    ms: "Anda telah menghantar permintaan pemindahan hak pemilik rumah \"$homeName\" kepada $email.",
    my: "\"$homeName\" ၏ပိုင်ဆိုင်မှုကို $email ထံ လွှဲပြောင်းရန် တောင်းဆိုမှု ပို့ပြီးပါပြီ။",
    lo: "ທ່ານສົ່ງຄຳຂໍໂອນຄວາມເປັນເຈົ້າຂອງ \"$homeName\" ໃຫ້ $email ແລ້ວ",
  );

  String ownershipTransferRequestMessage({
    required String actorName,
    required String homeName,
  }) => choose(
    vi: "$actorName muốn chuyển quyền chủ nhà \"$homeName\" cho bạn.",
    fil:
        "Gustong ilipat ni $actorName sa iyo ang pagmamay-ari ng bahay na \"$homeName\".",
    km: "$actorName ចង់ផ្ទេរសិទ្ធិម្ចាស់ផ្ទះរបស់ \"$homeName\" មកឱ្យអ្នក។",
    en: "$actorName wants to transfer ownership of \"$homeName\" to you.",
    zh: "$actorName 想将“$homeName”的所有权转移给你。",
    ko: "$actorName님이 \"$homeName\"의 소유권을 당신에게 이전하려고 합니다.",
    ja: "$actorName が「$homeName」の所有権をあなたに譲渡したいと考えています。",
    de: '$actorName möchte den Besitz von "$homeName" an dich übertragen.',
    ru: '$actorName хочет передать вам права владельца дома "$homeName".',

    es: "$actorName quiere transferirte la propiedad de «$homeName».",
    fr: _fr(
      vi: "$actorName muốn chuyển quyền chủ nhà \"$homeName\" cho bạn.",
      en: "$actorName wants to transfer ownership of \"$homeName\" to you.",
    ),
    id: "$actorName ingin mengalihkan kepemilikan \"$homeName\" kepada Anda.",
    th: "$actorName ต้องการโอนสิทธิ์เจ้าของบ้านของ \"$homeName\" ให้คุณ",
    ms: "$actorName mahu memindahkan hak pemilik rumah \"$homeName\" kepada anda.",
    my: "$actorName က \"$homeName\" ၏ပိုင်ဆိုင်မှုကို သင့်ထံ လွှဲပြောင်းလိုသည်။",
    lo: "$actorName ຕ້ອງການໂອນຄວາມເປັນເຈົ້າຂອງ \"$homeName\" ໃຫ້ທ່ານ",
  );

  String shareInvitationMessage({
    required String actorName,
    required String homeName,
  }) => choose(
    vi: "$actorName đã mời bạn tham gia nhà \"$homeName\".",
    fil: "Inimbitahan ka ni $actorName na sumali sa bahay na \"$homeName\".",
    km: "$actorName បានអញ្ជើញអ្នកឱ្យចូលរួម \"$homeName\"។",
    en: "$actorName invited you to join \"$homeName\".",
    zh: "$actorName 邀请你加入“$homeName”。",
    ko: "$actorName님이 \"$homeName\"에 초대했습니다.",
    ja: "$actorName が「$homeName」への参加に招待しました。",
    de: '$actorName hat dich eingeladen, "$homeName" beizutreten.',
    ru: '$actorName пригласил вас присоединиться к дому "$homeName".',

    es: "$actorName te invitó a unirte a «$homeName».",
    fr: _fr(
      vi: "$actorName đã mời bạn tham gia nhà \"$homeName\".",
      en: "$actorName invited you to join \"$homeName\".",
    ),
    id: "$actorName mengundang Anda bergabung ke \"$homeName\".",
    th: "$actorName ขอเชิญคุณเข้าร่วมบ้าน \"$homeName\"",
    ms: "$actorName telah menjemput anda untuk menyertai rumah \"$homeName\".",
    my: "$actorName က \"$homeName\" သို့ ဝင်ရန် သင့်ကို ဖိတ်ထားသည်။",
    lo: "$actorName ເຊີນທ່ານເຂົ້າຮ່ວມ \"$homeName\"",
  );

  String deviceDeleteInProgressMessage({
    required String deviceName,
    required String homeName,
  }) => choose(
    vi: "SafeHome đang xoá thiết bị \"$deviceName\" khỏi nhà \"$homeName\".",
    fil:
        "Tinatanggal ng SafeHome ang \"$deviceName\" mula sa bahay na \"$homeName\".",
    km: "SafeHome កំពុងដក \"$deviceName\" ចេញពី \"$homeName\"។",
    en: "SafeHome is removing \"$deviceName\" from \"$homeName\".",
    zh: "SafeHome 正在从“$homeName”中移除“$deviceName”。",
    ko: "SafeHome이 \"$homeName\"에서 \"$deviceName\"을(를) 삭제하는 중입니다.",
    ja: "SafeHome は「$homeName」から「$deviceName」を削除しています。",
    de: 'SafeHome entfernt "$deviceName" aus "$homeName".',
    ru: 'SafeHome удаляет "$deviceName" из дома "$homeName".',

    es: "SafeHome está eliminando el dispositivo «$deviceName» de «$homeName».",
    fr: _fr(
      vi: "SafeHome đang xoá thiết bị \"$deviceName\" khỏi nhà \"$homeName\".",
      en: "SafeHome is removing \"$deviceName\" from \"$homeName\".",
    ),
    id: "SafeHome sedang menghapus \"$deviceName\" dari \"$homeName\".",
    th: "SafeHome กำลังลบอุปกรณ์ \"$deviceName\" ออกจากบ้าน \"$homeName\"",
    ms: "SafeHome sedang memadam peranti \"$deviceName\" daripada rumah \"$homeName\".",
    my: "SafeHome က \"$homeName\" မှ \"$deviceName\" စက်ပစ္စည်းကို ဖယ်ရှားနေသည်။",
    lo: "SafeHome ກຳລັງລຶບອຸປະກອນ \"$deviceName\" ອອກຈາກ \"$homeName\"",
  );

  String deviceAddedMessage({
    required String deviceName,
    required String homeName,
  }) => choose(
    vi: "Thiết bị \"$deviceName\" đã xuất hiện trong \"$homeName\".",
    fil: "Naidagdag ang aparatong \"$deviceName\" sa bahay na \"$homeName\".",
    km: "បានបន្ថែមឧបករណ៍ \"$deviceName\" ទៅ \"$homeName\"។",
    en: "Device \"$deviceName\" was added to \"$homeName\".",
    zh: "设备“$deviceName”已添加到“$homeName”。",
    ko: "\"$homeName\"에 기기 \"$deviceName\"이 추가되었습니다.",
    ja: "デバイス「$deviceName」が「$homeName」に追加されました。",
    de: 'Gerät "$deviceName" wurde zu "$homeName" hinzugefügt.',
    ru: 'Устройство "$deviceName" появилось в доме "$homeName".',

    es: "El dispositivo «$deviceName» se añadió a «$homeName».",
    fr: _fr(
      vi: "Thiết bị \"$deviceName\" đã xuất hiện trong \"$homeName\".",
      en: "Device \"$deviceName\" was added to \"$homeName\".",
    ),
    id: "Perangkat \"$deviceName\" ditambahkan ke \"$homeName\".",
    th: "เพิ่มอุปกรณ์ \"$deviceName\" ในบ้าน \"$homeName\" แล้ว",
    ms: "Peranti \"$deviceName\" telah ditambahkan pada \"$homeName\".",
    my: "\"$deviceName\" စက်ပစ္စည်းကို \"$homeName\" သို့ ထည့်ပြီးပါပြီ။",
    lo: "ເພີ່ມອຸປະກອນ \"$deviceName\" ເຂົ້າໃນ \"$homeName\" ແລ້ວ",
  );

  String homeCreatedMessage(String name) => choose(
    vi: "Bạn đã tạo nhà \"$name\".",
    fil: "Nagawa mo na ang bahay na \"$name\".",
    km: "អ្នកបានបង្កើតផ្ទះ \"$name\"។",
    en: "You created the home \"$name\".",
    zh: "你已创建家庭“$name”。",
    ko: "\"$name\" 집을 만들었습니다.",
    ja: "家「$name」を作成しました。",
    de: 'Du hast das Zuhause "$name" erstellt.',
    ru: 'Вы создали дом "$name".',

    es: "Creaste la casa \"$name\".",
    fr: _fr(
      vi: "Bạn đã tạo nhà \"$name\".",
      en: "You created the home \"$name\".",
    ),
    id: "Anda membuat rumah \"$name\".",
    th: "คุณสร้างบ้าน \"$name\" แล้ว",
    ms: "Anda telah mencipta rumah \"$name\".",
    my: "\"$name\" အိမ်ကို သင်ဖန်တီးပြီးပါပြီ။",
    lo: "ທ່ານສ້າງເຮືອນ \"$name\" ແລ້ວ",
  );

  String homeInfoUpdatedMessage({
    required String actorName,
    required String newName,
    required bool nameChanged,
    required bool addressChanged,
  }) {
    if (nameChanged && addressChanged) {
      return choose(
        vi: "$actorName đã cập nhật tên nhà thành \"$newName\" và thay đổi địa chỉ.",
        fil:
            "Pinalitan ni $actorName ng \"$newName\" ang pangalan ng bahay at binago rin ang address nito.",
        km: "$actorName បានធ្វើបច្ចុប្បន្នភាពឈ្មោះផ្ទះទៅជា \"$newName\" និងផ្លាស់ប្ដូរអាសយដ្ឋាន។",
        en: "$actorName updated the home name to \"$newName\" and changed its address.",
        zh: "$actorName 已将家庭名称更新为“$newName”并更改了地址。",
        ko: "$actorName님이 집 이름을 \"$newName\"로 업데이트하고 주소를 변경했습니다.",
        ja: "$actorName が家の名前を「$newName」に更新し、住所を変更しました。",
        de: '$actorName hat den Namen des Zuhauses zu "$newName" aktualisiert und die Adresse geändert.',
        ru: '$actorName обновил имя дома на "$newName" и изменил адрес.',

        es: "$actorName actualizó la información de «$newName».",
        fr: _fr(
          vi: "$actorName đã cập nhật tên nhà thành \"$newName\" và thay đổi địa chỉ.",
          en: "$actorName updated the home name to \"$newName\" and changed its address.",
        ),
        id: "$actorName memperbarui nama rumah menjadi \"$newName\" dan mengubah alamatnya.",
        th: "$actorName อัปเดตชื่อบ้านเป็น \"$newName\" และเปลี่ยนที่อยู่แล้ว",
        ms: "$actorName mengemas kini nama rumah kepada \"$newName\" dan menukar alamat.",
        my: "$actorName က အိမ်အမည်ကို \"$newName\" ဟု မွမ်းမံပြီး လိပ်စာကို ပြောင်းလဲခဲ့သည်။",
        lo: "$actorName ອັບເດດຊື່ເຮືອນເປັນ \"$newName\" ແລະ ປ່ຽນທີ່ຢູ່",
      );
    }

    if (nameChanged) {
      return choose(
        vi: "$actorName đã đổi tên nhà thành \"$newName\".",
        fil: "Pinalitan ni $actorName ng \"$newName\" ang pangalan ng bahay.",
        km: "$actorName បានប្ដូរឈ្មោះផ្ទះទៅជា \"$newName\"។",
        en: "$actorName renamed the home to \"$newName\".",
        zh: "$actorName 已将家庭名称改为“$newName”。",
        ko: "$actorName님이 집 이름을 변경했습니다. 새 이름은 \"$newName\"입니다.",
        ja: "$actorName が家の名前を「$newName」に変更しました。",
        de: '$actorName hat das Zuhause in "$newName" umbenannt.',
        ru: '$actorName переименовал дом в "$newName".',

        es: "$actorName cambió el nombre de la casa a «$newName».",
        fr: _fr(
          vi: "$actorName đã đổi tên nhà thành \"$newName\".",
          en: "$actorName renamed the home to \"$newName\".",
        ),
        id: "$actorName mengganti nama rumah menjadi \"$newName\".",
        th: "$actorName เปลี่ยนชื่อบ้านเป็น \"$newName\" แล้ว",
        ms: "$actorName telah menukar nama rumah kepada \"$newName\".",
        my: "$actorName က အိမ်အမည်ကို \"$newName\" ဟု ပြောင်းလဲခဲ့သည်။",
        lo: "$actorName ປ່ຽນຊື່ເຮືອນເປັນ \"$newName\"",
      );
    }

    return choose(
      vi: "$actorName đã cập nhật địa chỉ của nhà \"$newName\".",
      fil: "In-update ni $actorName ang address ng bahay na \"$newName\".",
      km: "$actorName បានធ្វើបច្ចុប្បន្នភាពអាសយដ្ឋានរបស់ \"$newName\"។",
      en: "$actorName updated the address of \"$newName\".",
      zh: "$actorName 已更新“$newName”的地址。",
      ko: "$actorName님이 \"$newName\"의 주소를 업데이트했습니다.",
      ja: "$actorName が「$newName」の住所を更新しました。",
      de: '$actorName hat die Adresse von "$newName" aktualisiert.',
      ru: '$actorName обновил адрес дома "$newName".',

      es: "$actorName actualizó la dirección de «$newName».",
      fr: _fr(
        vi: "$actorName đã cập nhật địa chỉ của nhà \"$newName\".",
        en: "$actorName updated the address of \"$newName\".",
      ),
      id: "$actorName memperbarui alamat \"$newName\".",
      th: "$actorName อัปเดตที่อยู่ของบ้าน \"$newName\" แล้ว",
      ms: "$actorName mengemas kini alamat rumah \"$newName\".",
      my: "$actorName က \"$newName\" ၏လိပ်စာကို မွမ်းမံခဲ့သည်။",
      lo: "$actorName ອັບເດດທີ່ຢູ່ຂອງ \"$newName\"",
    );
  }

  String deviceRenamedMessage({
    required String actorName,
    required String oldDeviceName,
    required String newName,
    required String homeName,
  }) => choose(
    vi: "$actorName đã đổi tên thiết bị \"$oldDeviceName\" thành \"$newName\" trong nhà \"$homeName\".",
    fil:
        "Pinalitan ni $actorName ng \"$newName\" ang pangalan ng aparatong \"$oldDeviceName\" sa bahay na \"$homeName\".",
    km: "$actorName បានប្ដូរឈ្មោះឧបករណ៍ \"$oldDeviceName\" ទៅជា \"$newName\" ក្នុង \"$homeName\"។",
    en: "$actorName renamed device \"$oldDeviceName\" to \"$newName\" in \"$homeName\".",
    zh: "$actorName 已在“$homeName”中将设备“$oldDeviceName”重命名为“$newName”。",
    ko: "$actorName님이 \"$homeName\"에서 기기 \"$oldDeviceName\"의 이름을 변경했습니다. 새 이름은 \"$newName\"입니다.",
    ja: "$actorName が「$homeName」でデバイス「$oldDeviceName」の名前を「$newName」に変更しました。",
    de: '$actorName hat Gerät "$oldDeviceName" in "$homeName" in "$newName" umbenannt.',
    ru: '$actorName переименовал устройство "$oldDeviceName" в "$newName" в доме "$homeName".',

    es: "$actorName cambió el nombre del dispositivo «$oldDeviceName» a «$newName» en «$homeName».",
    fr: _fr(
      vi: "$actorName đã đổi tên thiết bị \"$oldDeviceName\" thành \"$newName\" trong nhà \"$homeName\".",
      en: "$actorName renamed device \"$oldDeviceName\" to \"$newName\" in \"$homeName\".",
    ),
    id: "$actorName mengganti nama perangkat \"$oldDeviceName\" menjadi \"$newName\" di \"$homeName\".",
    th: "$actorName เปลี่ยนชื่ออุปกรณ์ \"$oldDeviceName\" เป็น \"$newName\" ในบ้าน \"$homeName\" แล้ว",
    ms: "$actorName menamakan semula peranti \"$oldDeviceName\" kepada \"$newName\" dalam rumah \"$homeName\".",
    my: "$actorName က \"$homeName\" တွင် \"$oldDeviceName\" စက်ပစ္စည်းကို \"$newName\" ဟု အမည်ပြောင်းခဲ့သည်။",
    lo: "$actorName ປ່ຽນຊື່ອຸປະກອນ \"$oldDeviceName\" ເປັນ \"$newName\" ໃນ \"$homeName\"",
  );

  String pairingCountdownText(int seconds) => choose(
    vi: "Đang ghép nối: $seconds giây",
    fil: "Ipinapares: $seconds segundo",
    km: "កំពុងផ្គូផ្គង៖ $seconds វិនាទី",
    en: "Pairing: $seconds s",
    zh: "正在配对: $seconds 秒",
    ko: "페어링 중: $seconds초",
    ja: "ペアリング中: $seconds 秒",
    de: 'Kopplung: $seconds s',
    ru: 'Сопряжение: $seconds с',

    es: "Emparejando: $seconds s",
    fr: _fr(vi: "Đang ghép nối: $seconds giây", en: "Pairing: $seconds s"),
    id: "Pemasangan: $seconds dtk",
    th: "กำลังจับคู่: $seconds วินาที",
    ms: "Sedang berpasangan: $seconds saat",
    my: "ချိတ်ဆက်နေသည် - $seconds စက္ကန့်",
    lo: "ກຳລັງຈັບຄູ່: $seconds ວິນາທີ",
  );

  String pairingEnabledMessage({
    required String homeName,
    required int seconds,
  }) => choose(
    vi: "Chế độ thêm thiết bị đã được mở trong nhà \"$homeName\" trong $seconds giây.",
    fil:
        "Naka-enable ang pagpapares ng aparato sa bahay na \"$homeName\" sa loob ng $seconds segundo.",
    km: "បានបើកការផ្គូផ្គងឧបករណ៍ក្នុង \"$homeName\" រយៈពេល $seconds វិនាទី។",
    en: "Device pairing was enabled in \"$homeName\" for $seconds seconds.",
    zh: "“$homeName”的设备配对模式已开启 $seconds 秒。",
    ko: "\"$homeName\"에서 기기 추가 모드가 $seconds초 동안 활성화되었습니다.",
    ja: "「$homeName」でデバイス追加モードが $seconds 秒間有効になりました。",
    de: 'Die Gerätekopplung wurde in "$homeName" für $seconds Sekunden aktiviert.',
    ru: 'Режим добавления устройства открыт в доме "$homeName" на $seconds секунд.',

    es: "El modo de emparejamiento de dispositivos se activó en \"$homeName\" durante $seconds segundos.",
    fr: _fr(
      vi: "Chế độ thêm thiết bị đã được mở trong nhà \"$homeName\" trong $seconds giây.",
      en: "Device pairing was enabled in \"$homeName\" for $seconds seconds.",
    ),
    id: "Mode pemasangan perangkat diaktifkan di \"$homeName\" selama $seconds detik.",
    th: "เปิดโหมดเพิ่มอุปกรณ์ในบ้าน \"$homeName\" เป็นเวลา $seconds วินาที",
    ms: "Mod tambah peranti telah dibuka di rumah \"$homeName\" selama $seconds saat.",
    my: "\"$homeName\" တွင် စက်ပစ္စည်းချိတ်ဆက်မုဒ်ကို $seconds စက္ကန့်ကြာ ဖွင့်ထားသည်။",
    lo: "ເປີດການຈັບຄູ່ອຸປະກອນໃນ \"$homeName\" ເປັນເວລາ $seconds ວິນາທີ",
  );

  String alarmPauseWithinScheduleMessage({
    required String start,
    required String end,
  }) => choose(
    vi: "Khoảng thời gian phải nằm trong khung báo động ($start → $end)",
    fil:
        "Dapat nasa loob ng iskedyul ng alarma ang panahon ng pag-pause ($start → $end)",
    km: "រយៈពេលផ្អាកត្រូវស្ថិតក្នុងកាលវិភាគ សំឡេងរោទិ៍ ($start → $end)",
    en: "The pause period must be within the Alarm schedule ($start → $end)",
    zh: "暂停时间必须在 警报 计划内 ($start → $end)",
    ko: "일시 중지 시간은 경보 일정($start → $end) 안에 있어야 합니다",
    ja: "一時停止期間は 警報 スケジュール（$start → $end）内である必要があります",
    de: 'Der Pausenzeitraum muss innerhalb des Alarm-Zeitplans liegen ($start → $end)',
    ru: 'Период паузы должен быть в рамках расписания тревога ($start → $end)',

    es: "El período de pausa debe estar dentro del horario de alarma ($start → $end)",
    fr: _fr(
      vi: "Khoảng thời gian phải nằm trong khung báo động ($start → $end)",
      en: "The pause period must be within the Alarm schedule ($start → $end)",
    ),
    id: "Periode jeda harus berada dalam jadwal alarm ($start → $end)",
    th: "ช่วงเวลาหยุดชั่วคราวต้องอยู่ภายในกำหนดเวลา สัญญาณเตือน ($start → $end)",
    ms: "Tempoh Jeda penggera mesti berada dalam Jadual penggera ($start → $end)",
    my: "ခေတ္တရပ်မည့်ကာလသည် အရေးပေါ်အချက်ပေးသံ အချိန်ဇယားအတွင်း ဖြစ်ရမည် ($start → $end)",
    lo: "ຊ່ວງເວລາຢຸດຕ້ອງຢູ່ໃນຕາຕະລາງສັນຍານເຕືອນໄພ ($start → $end)",
  );

  String alarmPauseReminderText() => choose(
    vi:
        'Hành động này sẽ thay đổi thời gian báo động của một số thiết bị hôm nay.\n\n'
        'Báo động của các thiết bị thuộc trường "Nguy hiểm khẩn cấp" và báo động ở chế độ "Bảo vệ" sẽ không bị ảnh hưởng bởi chức năng này.',
    my:
        "ဤလုပ်ဆောင်ချက်က ယနေ့ စက်ပစ္စည်းအချို့၏ အရေးပေါ်အချက်ပေးသံ အချိန်ကို ပြောင်းလဲပါမည်။\n\n"
        "\"အရေးပေါ်အန္တရာယ်များ\" အမျိုးအစားရှိ စက်ပစ္စည်း အရေးပေါ်အချက်ပေးသံ များနှင့် \"ကာကွယ်ရေး\" မုဒ်ရှိ အရေးပေါ်အချက်ပေးသံ များကို ဤလုပ်ဆောင်ချက်က မသက်ရောက်ပါ။",
    fil:
        "Babaguhin ng aksyong ito ang oras ng alarma para sa ilang aparato ngayong araw.\n\nHindi maaapektuhan ng feature na ito ang mga alarma ng mga aparatong nasa kategoryang \"Mga agarang panganib\" at ang mga alarma sa Mode ng Proteksyon.",
    km: "សកម្មភាពនេះនឹងផ្លាស់ប្ដូរពេលវេលា សំឡេងរោទិ៍ របស់ឧបករណ៍មួយចំនួននៅថ្ងៃនេះ។\n\nAlarm របស់ឧបករណ៍ក្នុងក្រុម \"គ្រោះថ្នាក់បន្ទាន់\" និង សំឡេងរោទិ៍ ក្នុងមុខងារ \"ការពារ\" នឹងមិនទទួលរងឥទ្ធិពលពីមុខងារនេះទេ។",
    en:
        'This action will change today\'s Alarm time for some devices.\n\n'
        'Alarms from devices in the "Emergency danger" category and alarms in "Guard" mode will not be affected by this feature.',
    zh:
        '此操作将更改部分设备今天的 警报 时间。\n\n'
        '“紧急危险”类别中的设备警报，以及“警戒”模式下的警报，不受此功能影响。',
    ko:
        '이 작업은 일부 기기의 오늘 경보 시간을 변경합니다.\n\n'
        '"긴급 위험" 항목에 속한 기기의 경보와 "보호" 모드의 경보는 이 기능의 영향을 받지 않습니다.',
    ja:
        'この操作により、一部のデバイスの本日の 警報 時間が変更されます。\n\n'
        '「緊急の危険」カテゴリに属するデバイスの警報と「警戒」モードの警報は、この機能の影響を受けません。',
    de:
        'Diese Aktion ändert die heutige Alarm-Zeit für einige Geräte.\n\n'
        'Alarme von Geräten in der Kategorie „Akute Gefahr“ sowie Alarme im Modus „Schutz“ werden von dieser Funktion nicht beeinflusst.',
    ru:
        'Это действие изменит время тревога сегодня для некоторых устройств.\n\n'
        'Сигналы устройств из категории «Экстренная опасность» и сигналы в режиме «Охрана» не будут затронуты этой функцией.',
    fr:
        'Cette action modifiera aujourd\'hui l\'heure de l\'alarme pour certains appareils.\n\n'
        'Les alarmes des appareils de la catégorie « Danger urgent » et les alarmes en mode « Protection » ne seront pas affectées par cette fonction.',
    es:
        'Esta acción cambiará hoy la hora de alarma de algunos dispositivos.\n\n'
        'Las alarmas de los dispositivos de la categoría «Peligro de emergencia» y las alarmas en modo «Protección» no se verán afectadas por esta función.',
    th: "การดำเนินการนี้จะเปลี่ยนเวลา สัญญาณเตือน ของอุปกรณ์บางเครื่องในวันนี้\n\nAlarm ของอุปกรณ์ในหมวด \"อันตรายฉุกเฉิน\" และ สัญญาณเตือน ที่ใช้ \"โหมดป้องกัน\" จะไม่ได้รับผลกระทบจากฟังก์ชันนี้",
    ms: "Tindakan ini akan mengubah masa penggera bagi sesetengah peranti pada hari ini.\n\nAlarm untuk peranti dalam kategori \"Bahaya kecemasan\" dan penggera dalam mod \"Perlindungan\" tidak akan terjejas oleh fungsi ini.",
    lo: "ການດຳເນີນການນີ້ຈະປ່ຽນເວລາສັນຍານເຕືອນໄພຂອງອຸປະກອນບາງອັນໃນມື້ນີ້.\n\n",
  );

  String firebaseRulesPassedSummary({
    required int passCount,
    required int total,
  }) => choose(
    vi: "$passCount/$total bài test đạt\n\n",
    fil: "$passCount/$total pagsusuri ang pumasa\n\n",
    km: "ការសាកល្បងបានជោគជ័យ $passCount/$total\n\n",
    en: "$passCount/$total tests passed\n\n",
    zh: "$passCount/$total 项测试通过\n\n",
    ko: "$passCount/$total개 테스트 통과\n\n",
    ja: "$passCount/$total 件のテストに合格\n\n",
    de: '$passCount/$total Tests bestanden\n\n',
    ru: '$passCount/$total тестов пройдено\n\n',

    es: "$passCount/$total pruebas superadas\n\n",
    fr: _fr(
      vi: "$passCount/$total bài test đạt\n\n",
      en: "$passCount/$total tests passed\n\n",
    ),
    id: "$passCount/$total tes lulus\\n\\n",
    th: "ผ่านการทดสอบ $passCount/$total รายการ\n\n",
    ms: "$passCount/$total ujian lulus\n\n",
    my: "စမ်းသပ်မှု $passCount/$total ခု အောင်မြင်သည်\n\n",
    lo: "ຜ່ານ $passCount/$total ການທົດສອບ\n\n",
  );

  String memberPhoneMissingProfileMessage(String name) => choose(
    vi: "$name chưa cập nhật số điện thoại trong hồ sơ.",
    fil: "Hindi pa nagdagdag si $name ng numero ng telepono sa profile.",
    km: "$name មិនទាន់បានបន្ថែមលេខទូរសព្ទទៅក្នុងប្រវត្តិរូបទេ។",
    en: "$name has not added a phone number to their profile.",
    zh: "$name 尚未在个人资料中添加电话号码。",
    ko: "$name님이 프로필에 전화번호를 추가하지 않았습니다.",
    ja: "$name はプロフィールに電話番号を追加していません。",
    de: '$name hat im Profil noch keine Telefonnummer hinzugefügt.',
    ru: '$name еще не добавил номер телефона в профиль.',

    es: "$name aún no ha añadido un número de teléfono a su perfil.",
    fr: _fr(
      vi: "$name chưa cập nhật số điện thoại trong hồ sơ.",
      en: "$name has not added a phone number to their profile.",
    ),
    id: "$name belum menambahkan nomor telepon ke profilnya.",
    th: "$name ยังไม่ได้อัปเดตหมายเลขโทรศัพท์ในโปรไฟล์",
    ms: "$name belum mengemas kini nombor telefon dalam profilnya.",
    my: "$name သည် ကိုယ်ရေးအချက်အလက်တွင် ဖုန်းနံပါတ် မထည့်ရသေးပါ။",
    lo: "$name ຍັງບໍ່ໄດ້ເພີ່ມເບີໂທລະສັບໃນໂປຣໄຟລ໌",
  );

  String newChatInHomeTitle(String homeName) => choose(
    vi: "Tin nhắn mới trong $homeName",
    fil: "Bagong mensahe sa $homeName",
    km: "សារថ្មីនៅក្នុង $homeName",
    en: "New message in $homeName",
    zh: "$homeName 有新消息",
    ko: "$homeName 새 메시지",
    ja: "$homeName に新しいメッセージがあります",
    de: 'Neue Nachricht in $homeName',
    ru: 'Новое сообщение в $homeName',

    es: "Mensaje nuevo en $homeName",
    fr: _fr(vi: "Tin nhắn mới trong $homeName", en: "New message in $homeName"),
    id: "Pesan baru di $homeName",
    th: "ข้อความใหม่ใน $homeName",
    ms: "Mesej baharu dalam $homeName",
    my: "$homeName တွင် စာတိုအသစ်ရှိသည်",
    lo: "ຂໍ້ຄວາມໃໝ່ໃນ $homeName",
  );

  String searchResultCountText({required int current, required int total}) =>
      choose(
        vi: "$current/$total kết quả",
        fil: "Resulta $current/$total",
        km: "លទ្ធផល $current/$total",
        en: "$current/$total results",
        zh: "$current/$total 个结果",
        ko: "$current/$total개 결과",
        ja: "$current/$total 件の結果",
        de: '$current/$total Ergebnisse',
        ru: '$current/$total результатов',

        es: "$current/$total resultados",
        fr: _fr(vi: "$current/$total kết quả", en: "$current/$total results"),
        id: "$current/$total hasil",
        th: "$current/$total ผลลัพธ์",
        ms: "$current/$total hasil",
        my: "ရလဒ် $current/$total",
        lo: "$current/$total ຜົນລັບ",
      );

  String replyingToText(String name) => choose(
    vi: "Đang trả lời $name",
    fil: "Tumutugon kay $name",
    km: "កំពុងឆ្លើយតបទៅ $name",
    en: "Replying to $name",
    zh: "正在回复 $name",
    ko: "$name님에게 답장 중",
    ja: "$name に返信中",
    de: 'Antwort an $name',
    ru: 'Ответ $name',

    es: "Respondiendo a $name",
    fr: _fr(vi: "Đang trả lời $name", en: "Replying to $name"),
    id: "Membalas $name",
    th: "กำลังตอบกลับ $name",
    ms: "Membalas $name",
    my: "$name ထံ ပြန်စာရေးနေသည်",
    lo: "ກຳລັງຕອບ $name",
  );

  String deviceSmokeDetectedMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" phát hiện khói trong \"$homeName\".",
    fil: "Natukoy ng \"$name\" ang usok sa bahay na \"$homeName\".",
    km: "\"$name\" បានរកឃើញផ្សែងនៅក្នុង \"$homeName\"។",
    en: "\"$name\" detected smoke in \"$homeName\".",
    zh: "“$name”在“$homeName”中检测到烟雾。",
    ko: "\"$homeName\"의 \"$name\"에서 연기가 감지되었습니다.",
    ja: "「$name」が「$homeName」で煙を検知しました。",
    de: '"$name" hat Rauch in "$homeName" erkannt.',
    ru: '"$name" обнаружил дым в "$homeName".',

    es: "«$name» detectó humo en «$homeName».",
    fr: _fr(
      vi: "\"$name\" phát hiện khói trong \"$homeName\".",
      en: "\"$name\" detected smoke in \"$homeName\".",
    ),
    id: "\"$name\" mendeteksi asap di \"$homeName\".",
    th: "\"$name\" ตรวจพบควันใน \"$homeName\"",
    ms: "\"$name\" mengesan asap di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" က မီးခိုးတွေ့ရှိသည်။",
    lo: "\"$name\" ກວດພົບຄວັນໃນ \"$homeName\"",
  );

  String deviceReturnedNormalMessage(String name) => choose(
    vi: "\"$name\" đã trở lại trạng thái bình thường.",
    fil: "Bumalik na sa normal ang \"$name\".",
    km: "\"$name\" បានត្រឡប់ទៅស្ថានភាពធម្មតា។",
    en: "\"$name\" has returned to normal.",
    zh: "“$name”已恢复正常状态。",
    ko: "\"$name\"이 정상 상태로 돌아왔습니다.",
    ja: "「$name」は通常状態に戻りました。",
    de: '"$name" ist zum Normalzustand zurückgekehrt.',
    ru: '"$name" вернулся в обычное состояние.',

    es: "«$name» volvió al estado normal.",
    fr: _fr(
      vi: "\"$name\" đã trở lại trạng thái bình thường.",
      en: "\"$name\" has returned to normal.",
    ),
    id: "\"$name\" kembali normal.",
    th: "\"$name\" กลับสู่สถานะปกติแล้ว",
    ms: "\"$name\" telah kembali ke status normal.",
    my: "\"$name\" သည် ပုံမှန်အခြေအနေသို့ ပြန်ရောက်ပြီ။",
    lo: "\"$name\" ກັບຄືນເປັນປົກກະຕິແລ້ວ",
  );

  String deviceSosTriggeredMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" vừa kích hoạt SOS trong \"$homeName\".",
    fil: "Na-trigger ng \"$name\" ang SOS sa bahay na \"$homeName\".",
    km: "\"$name\" បានដំណើរការ SOS នៅក្នុង \"$homeName\"។",
    en: "\"$name\" triggered SOS in \"$homeName\".",
    zh: "“$name”在“$homeName”中触发了 SOS。",
    ko: "\"$homeName\"의 \"$name\"에서 SOS가 작동했습니다.",
    ja: "「$name」が「$homeName」で SOS を起動しました。",
    de: '"$name" hat SOS in "$homeName" ausgelöst.',
    ru: '"$name" активировал SOS в "$homeName".',

    es: "«$name» activó SOS en «$homeName».",
    fr: _fr(
      vi: "\"$name\" vừa kích hoạt SOS trong \"$homeName\".",
      en: "\"$name\" triggered SOS in \"$homeName\".",
    ),
    id: "\"$name\" memicu SOS di \"$homeName\".",
    th: "\"$name\" เปิดใช้งาน SOS ใน \"$homeName\"",
    ms: "\"$name\" baru sahaja mengaktifkan SOS di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" က SOS ဖွင့်ခဲ့သည်။",
    lo: "\"$name\" ກະຕຸ້ນ SOS ໃນ \"$homeName\"",
  );

  String deviceSosClearedMessage(String name) => choose(
    vi: "\"$name\" đã hết trạng thái SOS.",
    fil: "Wala na sa SOS status ang \"$name\".",
    km: "\"$name\" លែងស្ថិតក្នុងស្ថានភាព SOS ទៀតហើយ។",
    en: "\"$name\" is no longer in SOS state.",
    zh: "“$name”的 SOS 状态已解除。",
    ko: "\"$name\"의 SOS 상태가 해제되었습니다.",
    ja: "「$name」の SOS 状態は解除されました。",
    de: '"$name" ist nicht mehr im SOS-Zustand.',
    ru: '"$name" больше не в состоянии SOS.',

    es: "«$name» ya no está en estado SOS.",
    fr: _fr(
      vi: "\"$name\" đã hết trạng thái SOS.",
      en: "\"$name\" is no longer in SOS state.",
    ),
    id: "Status SOS \"$name\" telah berakhir.",
    th: "\"$name\" สิ้นสุดสถานะ SOS แล้ว",
    ms: "Status SOS untuk \"$name\" telah tamat.",
    my: "\"$name\" ၏ SOS အခြေအနေ ပြီးဆုံးပြီ။",
    lo: "\"$name\" ສິ້ນສຸດສະຖານະ SOS ແລ້ວ",
  );

  String deviceTamperDetectedMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" báo bị tháo/cạy trong \"$homeName\".",
    fil: "Natukoy ng \"$name\" ang pakikialam sa bahay na \"$homeName\".",
    km: "ឧបករណ៍ \"$name\" ត្រូវបានដោះ ឬលូកលាន់នៅក្នុង \"$homeName\"។",
    en: "\"$name\" reported tampering in \"$homeName\".",
    zh: "“$name”在“$homeName”中报告被拆卸/撬动。",
    ko: "\"$homeName\"의 \"$name\"에서 분리/강제 개방이 감지되었습니다.",
    ja: "「$name」が「$homeName」で取り外し/こじ開けを検知しました。",
    de: '"$name" meldet Manipulation in "$homeName".',
    ru: '"$name" сообщил о вскрытии/снятии в "$homeName".',

    es: "«$name» informó manipulación en «$homeName».",
    fr: _fr(
      vi: "\"$name\" báo bị tháo/cạy trong \"$homeName\".",
      en: "\"$name\" reported tampering in \"$homeName\".",
    ),
    id: "\"$name\" melaporkan perangkat dilepas/dicungkil di \"$homeName\".",
    th: "\"$name\" ถูกงัดแงะใน \"$homeName\"",
    ms: "\"$name\" mengesan gangguan di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" က ဖြုတ်/ဖောက်ဝင်မှု တွေ့ရှိသည်။",
    lo: "\"$name\" ລາຍງານການຖອດງັດໃນ \"$homeName\"",
  );

  String deviceTamperClearedMessage(String name) => choose(
    vi: "\"$name\" đã hết cảnh báo tháo/cạy.",
    fil: "Natapos na ang alerto sa pakikialam para sa \"$name\".",
    km: "ការជូនដំណឹងអំពីការដោះ ឬលូកលាន់ឧបករណ៍ \"$name\" បានបញ្ចប់។",
    en: "\"$name\" tamper alert has cleared.",
    zh: "“$name”的拆卸/撬动警报已解除。",
    ko: "\"$name\"의 분리 경고가 해제되었습니다.",
    ja: "「$name」の取り外し警告は解除されました。",
    de: 'Manipulationsalarm von "$name" wurde aufgehoben.',
    ru: 'Тревога вскрытия/снятия у "$name" снята.',

    es: "La alerta de manipulación de «$name» ha finalizado.",
    fr: _fr(
      vi: "\"$name\" đã hết cảnh báo tháo/cạy.",
      en: "\"$name\" tamper alert has cleared.",
    ),
    id: "Peringatan lepas/cungkil pada \"$name\" sudah selesai.",
    th: "การแจ้งเตือนการงัดแงะของ \"$name\" สิ้นสุดแล้ว",
    ms: "Amaran gangguan untuk \"$name\" telah tamat.",
    my: "\"$name\" ၏ ဖြုတ်/ဖောက်ဝင်မှု သတိပေးချက် ပြီးဆုံးပြီ။",
    lo: "ການເຕືອນຖອດງັດຂອງ \"$name\" ສິ້ນສຸດແລ້ວ",
  );

  String deviceDoorClosedMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" đã đóng trong \"$homeName\".",
    fil: "Nagsara ang \"$name\" sa bahay na \"$homeName\".",
    km: "\"$name\" បានបិទនៅក្នុង \"$homeName\"។",
    en: "\"$name\" closed in \"$homeName\".",
    zh: "“$name”已在“$homeName”中关闭。",
    ko: "\"$homeName\"의 \"$name\"이 닫혔습니다.",
    ja: "「$name」は「$homeName」で閉じました。",
    de: '"$name" wurde in "$homeName" geschlossen.',
    ru: '"$name" закрыт в "$homeName".',

    es: "«$name» está cerrado en «$homeName».",
    fr: _fr(
      vi: "\"$name\" đã đóng trong \"$homeName\".",
      en: "\"$name\" closed in \"$homeName\".",
    ),
    id: "\"$name\" tertutup di \"$homeName\".",
    th: "\"$name\" ปิดแล้วใน \"$homeName\"",
    ms: "\"$name\" telah ditutup di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" ပိတ်သွားသည်။",
    lo: "\"$name\" ປິດແລ້ວໃນ \"$homeName\"",
  );

  String deviceDoorOpenMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" đang mở trong \"$homeName\".",
    fil: "Bukas ang \"$name\" sa bahay na \"$homeName\".",
    km: "\"$name\" បើកនៅក្នុង \"$homeName\"។",
    en: "\"$name\" is open in \"$homeName\".",
    zh: "“$name”在“$homeName”中处于打开状态。",
    ko: "\"$homeName\"의 \"$name\"이 열려 있습니다.",
    ja: "「$name」は「$homeName」で開いています。",
    de: '"$name" ist in "$homeName" geöffnet.',
    ru: '"$name" открыт в "$homeName".',

    es: "«$name» está abierto en «$homeName».",
    fr: _fr(
      vi: "\"$name\" đang mở trong \"$homeName\".",
      en: "\"$name\" is open in \"$homeName\".",
    ),
    id: "\"$name\" terbuka di \"$homeName\".",
    th: "\"$name\" เปิดอยู่ใน \"$homeName\"",
    ms: "\"$name\" sedang terbuka di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" ဖွင့်ထားသည်။",
    lo: "\"$name\" ເປີດຢູ່ໃນ \"$homeName\"",
  );

  String deviceLowBatteryMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" trong \"$homeName\" đang yếu pin.",
    fil: "Mahina ang baterya ng \"$name\" sa bahay na \"$homeName\".",
    km: "ថ្មរបស់ \"$name\" នៅក្នុង \"$homeName\" ខ្សោយ។",
    en: "\"$name\" in \"$homeName\" has a low battery.",
    zh: "“$homeName”中的“$name”电量低。",
    ko: "\"$homeName\"의 \"$name\" 배터리가 부족합니다.",
    ja: "「$homeName」の「$name」はバッテリー残量が低下しています。",
    de: '"$name" in "$homeName" hat einen niedrigen Batteriestand.',
    ru: 'У "$name" в "$homeName" низкий заряд батареи.',

    es: "La batería de «$name» en «$homeName» está baja.",
    fr: _fr(
      vi: "\"$name\" trong \"$homeName\" đang yếu pin.",
      en: "\"$name\" in \"$homeName\" has a low battery.",
    ),
    id: "Baterai \"$name\" di \"$homeName\" lemah.",
    th: "\"$name\" ใน \"$homeName\" มีแบตเตอรี่ใกล้หมด",
    ms: "Bateri \"$name\" di \"$homeName\" lemah.",
    my: "\"$homeName\" ရှိ \"$name\" ၏ဘက်ထရီအားနည်းနေသည်။",
    lo: "\"$name\" ໃນ \"$homeName\" ມີແບັດເຕີຣີຕ່ຳ",
  );

  String deviceOfflineMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" trong \"$homeName\" đã mất kết nối.",
    fil: "Nag-offline ang \"$name\" sa bahay na \"$homeName\".",
    km: "\"$name\" នៅក្នុង \"$homeName\" បានអហ្វឡាញ។",
    en: "\"$name\" in \"$homeName\" went offline.",
    zh: "“$homeName”中的“$name”已断开连接。",
    ko: "\"$homeName\"의 \"$name\" 연결이 끊어졌습니다.",
    ja: "「$homeName」の「$name」はオフラインになりました。",
    de: '"$name" in "$homeName" ist offline.',
    ru: '"$name" в "$homeName" потерял соединение.',

    es: "«$name» en «$homeName» perdió la conexión.",
    fr: _fr(
      vi: "\"$name\" trong \"$homeName\" đã mất kết nối.",
      en: "\"$name\" in \"$homeName\" went offline.",
    ),
    id: "\"$name\" di \"$homeName\" kehilangan koneksi.",
    th: "\"$name\" ใน \"$homeName\" ออฟไลน์แล้ว",
    ms: "\"$name\" di \"$homeName\" telah terputus sambungan.",
    my: "\"$homeName\" ရှိ \"$name\" ချိတ်ဆက်မှု ပြတ်တောက်သွားသည်။",
    lo: "\"$name\" ໃນ \"$homeName\" ອອບລາຍ",
  );

  String deviceOnlineMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" trong \"$homeName\" đã kết nối trở lại.",
    fil: "Online na muli ang \"$name\" sa bahay na \"$homeName\".",
    km: "\"$name\" នៅក្នុង \"$homeName\" បានត្រឡប់អនឡាញវិញ។",
    en: "\"$name\" in \"$homeName\" is back online.",
    zh: "“$homeName”中的“$name”已重新连接。",
    ko: "\"$homeName\"의 \"$name\" 연결이 복구되었습니다.",
    ja: "「$homeName」の「$name」はオンラインに戻りました。",
    de: '"$name" in "$homeName" ist wieder online.',
    ru: '"$name" в "$homeName" снова подключен.',

    es: "«$name» en «$homeName» volvió a conectarse.",
    fr: _fr(
      vi: "\"$name\" trong \"$homeName\" đã kết nối trở lại.",
      en: "\"$name\" in \"$homeName\" is back online.",
    ),
    id: "\"$name\" di \"$homeName\" kembali online.",
    th: "\"$name\" ใน \"$homeName\" กลับมาออนไลน์แล้ว",
    ms: "\"$name\" di \"$homeName\" telah disambungkan semula.",
    my: "\"$homeName\" ရှိ \"$name\" ပြန်လည်ချိတ်ဆက်ပြီ။",
    lo: "\"$name\" ໃນ \"$homeName\" ກັບມາອອນລາຍແລ້ວ",
  );

  String deviceHighTemperatureMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
    fil:
        "Nagtala ang \"$name\" ng mataas na temperatura sa bahay na \"$homeName\".",
    km: "\"$name\" បានកត់ត្រាសីតុណ្ហភាពខ្ពស់នៅក្នុង \"$homeName\"។",
    en: "\"$name\" recorded a high temperature in \"$homeName\".",
    zh: "“$name”在“$homeName”中记录到高温。",
    ko: "\"$homeName\"의 \"$name\"에서 높은 온도가 기록되었습니다.",
    ja: "「$name」が「$homeName」で高温を記録しました。",
    de: '"$name" hat eine hohe Temperatur in "$homeName" gemessen.',
    ru: '"$name" зафиксировал высокую температуру в "$homeName".',

    es: "\"$name\" registró una temperatura alta en \"$homeName\".",
    fr: _fr(
      vi: "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
      en: "\"$name\" recorded a high temperature in \"$homeName\".",
    ),
    id: "\"$name\" mencatat suhu tinggi di \"$homeName\".",
    th: "\"$name\" ตรวจพบอุณหภูมิสูงใน \"$homeName\"",
    ms: "\"$name\" mengesan suhu tinggi di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" က အပူချိန်မြင့်မားမှု မှတ်တမ်းတင်ခဲ့သည်။",
    lo: "\"$name\" ບັນທຶກອຸນຫະພູມສູງໃນ \"$homeName\"",
  );

  String deviceHighHumidityMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" ghi nhận độ ẩm cao trong \"$homeName\".",
    fil:
        "Nagtala ang \"$name\" ng mataas na halumigmig sa bahay na \"$homeName\".",
    km: "\"$name\" បានកត់ត្រាសំណើមខ្ពស់នៅក្នុង \"$homeName\"។",
    en: "\"$name\" recorded high humidity in \"$homeName\".",
    zh: "“$name”在“$homeName”中记录到高湿度。",
    ko: "\"$homeName\"의 \"$name\"에서 높은 습도가 기록되었습니다.",
    ja: "「$name」が「$homeName」で高い湿度を記録しました。",
    de: '"$name" hat hohe Luftfeuchtigkeit in "$homeName" gemessen.',
    ru: '"$name" зафиксировал высокую влажность в "$homeName".',

    es: "\"$name\" recorded high humedad in \"$homeName\".",
    fr: _fr(
      vi: "\"$name\" ghi nhận độ ẩm cao trong \"$homeName\".",
      en: "\"$name\" recorded high humidity in \"$homeName\".",
    ),
    id: "\"$name\" mencatat kelembapan tinggi di \"$homeName\".",
    th: "\"$name\" ตรวจพบความชื้นสูงใน \"$homeName\"",
    ms: "\"$name\" mengesan kelembapan tinggi di \"$homeName\".",
    my: "\"$homeName\" တွင် \"$name\" က စိုထိုင်းဆမြင့်မားမှု မှတ်တမ်းတင်ခဲ့သည်။",
    lo: "\"$name\" ບັນທຶກຄວາມຊຸ່ມສູງໃນ \"$homeName\"",
  );

  String alarmFallbackReason(String category) {
    switch (category.trim().toLowerCase()) {
      case "sos":
        return choose(
          vi: "Có nút SOS vừa được kích hoạt",
          en: "An SOS button was triggered",
          zh: "SOS 按钮刚刚被触发",
          ko: "SOS 버튼이 작동했습니다",
          ja: "SOS ボタンが作動しました",
          de: 'Ein SOS-Button wurde ausgelöst',
          ru: 'Активирована кнопка SOS',

          es: "Se ha activado un botón SOS",
          fr: _fr(
            vi: "Có nút SOS vừa được kích hoạt",
            en: "An SOS button was triggered",
          ),
        );
      case "smoke":
      case "fire":
        return choose(
          vi: "Có dấu hiệu khói hoặc cháy",
          en: "Smoke or fire was detected",
          zh: "检测到烟雾或火灾迹象",
          ko: "연기 또는 화재 징후가 있습니다",
          ja: "煙または火災の兆候があります",
          de: 'Rauch oder Feuer wurde erkannt',
          ru: 'Обнаружен дым или пожар',

          es: "Se detectó humo o fuego",
          fr: _fr(
            vi: "Có dấu hiệu khói hoặc cháy",
            en: "Smoke or fire was detected",
          ),
        );
      case "flood":
      case "water":
        return choose(
          vi: "Có dấu hiệu ngập nước",
          en: "Water flooding was detected",
          zh: "检测到漏水迹象",
          ko: "침수 징후가 있습니다",
          ja: "浸水の兆候があります",
          de: 'Überschwemmung wurde erkannt',
          ru: 'Обнаружено затопление',

          es: "Se detectó inundación",
          fr: _fr(
            vi: "Có dấu hiệu ngập nước",
            en: "Water flooding was detected",
          ),
        );
      case "gas":
        return choose(
          vi: "Có dấu hiệu rò khí",
          en: "A gas leak was detected",
          zh: "检测到燃气泄漏迹象",
          ko: "가스 누출 징후가 있습니다",
          ja: "ガス漏れの兆候があります",
          de: 'Ein Gasleck wurde erkannt',
          ru: 'Обнаружена утечка газа',

          es: "Se detectó una fuga de gas",
          fr: _fr(vi: "Có dấu hiệu rò khí", en: "A gas leak was detected"),
        );
      case "door":
      case "window":
      case "gate":
      case "lock":
        return choose(
          vi: "Có cửa đang mở hoặc thiết bị bị tháo",
          en: "A door is open or a device was tampered with",
          zh: "有门打开或设备被拆卸",
          ko: "문이 열려 있거나 기기가 분리되었습니다",
          ja: "ドアが開いているか、デバイスが取り外されています",
          de: 'Eine Tür ist geöffnet oder ein Gerät wurde manipuliert',
          ru: 'Дверь открыта или устройство было снято',

          es: "Hay una puerta abierta o un dispositivo manipulado",
          fr: _fr(
            vi: "Có cửa đang mở hoặc thiết bị bị tháo",
            en: "A door is open or a device was tampered with",
          ),
        );
      default:
        return choose(
          vi: "Có thiết bị đang cảnh báo",
          en: "A device is alerting",
          zh: "有设备正在报警",
          ko: "경보 중인 기기가 있습니다",
          ja: "アラート中のデバイスがあります",
          de: 'Ein Gerät meldet Alarm',
          ru: 'Устройство сообщает тревогу',

          es: "Hay un dispositivo en alerta",
          fr: _fr(vi: "Có thiết bị đang cảnh báo", en: "A device is alerting"),
        );
    }
  }

  String alarmEmergencyEscalationText() => choose(
    vi: "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.",
    en: "If no one confirms, SafeHome will initiate an emergency call.",
    zh: "如果没有人确认，SafeHome 将转为紧急呼叫。",
    ko: "아무도 확인하지 않으면 SafeHome이 긴급 전화로 전환합니다.",
    ja: "誰も確認しない場合、SafeHome は緊急通話に切り替えます。",
    de: 'Wenn niemand bestätigt, wechselt SafeHome zu einem Notruf.',
    ru: 'Если никто не подтвердит, SafeHome перейдет к экстренному звонку.',

    es: "Si nadie confirma, SafeHome pasará a una llamada de emergencia.",
    fr: _fr(
      vi: "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.",
      en: "If no one confirms, SafeHome will initiate an emergency call.",
    ),
  );

  String alarmRepeatAtText(String time) => choose(
    vi: "Báo lại lúc $time nếu vấn đề chưa được xử lý.",
    fil: "Mag-aalerto muli sa $time kung hindi pa nalulutas ang problema.",
    km: "នឹងជូនដំណឹងម្ដងទៀតនៅម៉ោង $time ប្រសិនបើបញ្ហាមិនទាន់បានដោះស្រាយ។",
    en: "Alerts again at $time if the issue has not been handled.",
    zh: "如果问题尚未处理，将在 $time 再次提醒。",
    ko: "문제가 처리되지 않으면 $time에 다시 알립니다.",
    ja: "問題が解決されていない場合、$time に再度通知します。",
    de: 'Alarmiert erneut um $time, wenn das Problem nicht behoben wurde.',
    ru: 'Повторит тревогу в $time, если проблема не решена.',

    es: "Volverá a avisar a las $time si el problema no se ha resuelto.",
    fr: _fr(
      vi: "Báo lại lúc $time nếu vấn đề chưa được xử lý.",
      en: "Alerts again at $time if the issue has not been handled.",
    ),
    id: "Akan memperingatkan lagi pada $time jika masalah belum ditangani.",
    th: "จะแจ้งเตือนอีกครั้งเวลา $time หากยังไม่ได้แก้ไขปัญหา",
    ms: "Amaran akan diulang pada $time jika masalah belum diselesaikan.",
    my: "ပြဿနာ မဖြေရှင်းရသေးပါက $time တွင် ထပ်မံသတိပေးမည်။",
    lo: "ຈະເຕືອນອີກຄັ້ງເວລາ $time ຖ້າບັນຫາຍັງບໍ່ໄດ້ແກ້ໄຂ",
  );

  String alarmRepeatByScheduleText() => choose(
    vi: "Sẽ báo lại theo lịch báo động đã cài nếu vấn đề chưa được xử lý.",
    en: "Alerts again according to the Alarm schedule if the issue has not been handled.",
    zh: "如果问题尚未处理，将按已设置的 警报 计划再次提醒。",
    ko: "문제가 처리되지 않으면 설정된 경보 일정에 따라 다시 알립니다.",
    ja: "問題が解決されていない場合、設定済みの 警報 スケジュールに従って再度通知します。",
    de: 'Alarmiert erneut gemäß dem eingestellten Alarm-Zeitplan, wenn das Problem nicht behoben wurde.',
    ru: 'Повторит тревогу по расписанию тревога, если проблема не решена.',

    es: "Volverá a avisar según la programación de alarma si el problema no se ha resuelto.",
    fr: _fr(
      vi: "Sẽ báo lại theo lịch báo động đã cài nếu vấn đề chưa được xử lý.",
      en: "Alerts again according to the Alarm schedule if the issue has not been handled.",
    ),
  );

  String stripSafetyStatusText(String text) {
    var result = text.replaceAll("⚠️", "").replaceAll("✅", "");

    for (final value in const [
      "CHƯA AN TOÀN",
      "ĐÃ AN TOÀN",
      "UNSAFE",
      "SAFE",
      "不安全",
      "안전하지 않음",
      "安全ではありません",
      "安全",
      "안전",
      "SICHER",
      "NICHT SICHER",
      "БЕЗОПАСНО",
      "НЕБЕЗОПАСНО",
      "SÉCURISÉ",
      "NON SÉCURISÉ",
      "SEGURO",
      "NO SEGURO",
    ]) {
      result = result.replaceAll(value, "");
    }

    return result.trim();
  }

  String notificationTitle(Map<String, dynamic> item, {String homeName = ""}) {
    final type = _notificationString(item, "type").toLowerCase();
    final rawTitle = _notificationString(item, "title");

    final lifecycleTitle = _homeLifecycleNotificationTitle(type);
    if (lifecycleTitle != null) {
      return lifecycleTitle;
    }

    if (_isManualSecurityModeNotification(type)) {
      return manualSecurityModeEnabledTitle();
    }

    if (_isMemberLeftHomeNotification(type)) {
      return memberLeftHomeTitle();
    }

    if (_isMemberJoinedHomeNotification(type)) {
      return memberJoinedHomeTitle();
    }

    if (_isAlarmSettingChangedNotification(type)) {
      final enabled = _notificationBool(
        _firstNotificationValue(item, const ["alarmEnabled", "enabled"]),
      );

      if (enabled != null) {
        return alarmSettingChangedTitle(enabled);
      }
    }

    if (_isMemberRoleNotification(type)) {
      return memberRoleChangedTitle();
    }

    if (_isDeviceRenamedNotification(type)) {
      return t("Đã đổi tên thiết bị");
    }

    if (_isHomeUpdatedNotification(type)) {
      return t("Đã cập nhật thông tin nhà");
    }

    if (_isDeviceDeleteNotification(type)) {
      return t("Đang xoá thiết bị");
    }

    if (_isHomeCreatedNotification(type)) {
      return t("Đã tạo nhà");
    }

    if (_isHomeDeletedNotification(type)) {
      return t("Đã xoá nhà");
    }

    final deviceEventTitle = _deviceEventNotificationTitle(item);
    if (deviceEventTitle != null) {
      return deviceEventTitle;
    }

    if (_isAbnormalNotification(type, rawTitle)) {
      return choose(
        vi: "Phát hiện bất thường",
        en: "Abnormal activity detected",
        zh: "检测到异常",
        ko: "이상 감지",
        ja: "異常を検知",
        de: 'Auffälligkeit erkannt',
        ru: 'Обнаружена аномалия',

        es: "Anomalía detectada",
        fr: _fr(vi: "Phát hiện bất thường", en: "Abnormal activity detected"),
      );
    }

    final doorClosed = _notificationDoorClosed(item);
    if (doorClosed != null &&
        (rawTitle.isEmpty ||
            _isDoorNotificationType(type) ||
            _doorClosedFromText(rawTitle) != null)) {
      return choose(
        vi: "Phát hiện bất thường",
        en: "Abnormal activity detected",
        zh: "检测到异常",
        ko: "이상 감지",
        ja: "異常を検知",
        de: 'Auffälligkeit erkannt',
        ru: 'Обнаружена аномалия',

        es: "Anomalía detectada",
        fr: _fr(vi: "Phát hiện bất thường", en: "Abnormal activity detected"),
      );
    }

    final title = systemNotificationText(rawTitle, type: type);

    return title.isNotEmpty ? title : notification;
  }

  String notificationMessage(
    Map<String, dynamic> item, {
    String homeName = "",
  }) {
    final type = _notificationString(item, "type").toLowerCase();
    final resolvedHomeName = homeName.trim().isNotEmpty
        ? homeName.trim()
        : _firstNotificationString(item, const ["homeName"]);

    final lifecycleMessage = _homeLifecycleNotificationMessage(
      item,
      type,
      resolvedHomeName,
    );
    if (lifecycleMessage != null) {
      return lifecycleMessage;
    }

    if (_isManualSecurityModeNotification(type)) {
      final actorName = _firstNotificationString(item, const ["actorName"]);
      final repeatMinutesValue = _firstNotificationValue(item, const [
        "securityModeRepeatMinutes",
      ]);
      final repeatMinutes = repeatMinutesValue is num
          ? repeatMinutesValue.toInt()
          : int.tryParse(repeatMinutesValue?.toString() ?? "") ?? 0;

      if (actorName.isNotEmpty && resolvedHomeName.isNotEmpty) {
        return manualSecurityModeEnabledMessage(
          actorName: actorName,
          homeName: resolvedHomeName,
          securityModeRepeatMinutes: repeatMinutes,
        );
      }
    }

    if (_isMemberLeftHomeNotification(type)) {
      final memberName = _firstNotificationString(item, const ["memberName"]);

      if (resolvedHomeName.isNotEmpty) {
        return memberLeftHomeMessage(
          memberName: memberName,
          homeName: resolvedHomeName,
        );
      }
    }

    if (_isMemberJoinedHomeNotification(type)) {
      final memberName = _firstNotificationString(item, const [
        "memberName",
        "targetName",
        "actorName",
      ]);

      if (resolvedHomeName.isNotEmpty) {
        return memberJoinedHomeMessage(
          memberName: memberName,
          homeName: resolvedHomeName,
        );
      }
    }

    if (_isAlarmSettingChangedNotification(type)) {
      final enabled = _notificationBool(
        _firstNotificationValue(item, const ["alarmEnabled", "enabled"]),
      );

      if (enabled != null && resolvedHomeName.isNotEmpty) {
        return alarmSettingChangedMessage(
          enabled: enabled,
          homeName: resolvedHomeName,
        );
      }
    }

    if (_isMemberRoleNotification(type)) {
      final actorName = _firstNotificationString(item, const ["actorName"]);
      final memberName = _firstNotificationString(item, const [
        "targetName",
        "memberName",
      ]);
      final oldRole = _firstNotificationString(item, const ["oldRole"]);
      final newRole = _firstNotificationString(item, const ["newRole"]);

      if (actorName.isNotEmpty &&
          memberName.isNotEmpty &&
          oldRole.isNotEmpty &&
          newRole.isNotEmpty &&
          resolvedHomeName.isNotEmpty) {
        return memberRoleChangedMessage(
          actorName: actorName,
          memberName: memberName,
          oldRole: oldRole,
          newRole: newRole,
          homeName: resolvedHomeName,
        );
      }
    }

    if (_isDeviceRenamedNotification(type)) {
      final actorName = _firstNotificationString(item, const ["actorName"]);
      final oldDeviceName = _firstNotificationString(item, const [
        "oldDeviceName",
        "oldName",
      ]);
      final newDeviceName = _firstNotificationString(item, const [
        "newDeviceName",
        "newName",
        "deviceName",
      ]);

      if (actorName.isNotEmpty &&
          oldDeviceName.isNotEmpty &&
          newDeviceName.isNotEmpty &&
          resolvedHomeName.isNotEmpty) {
        return deviceRenamedMessage(
          actorName: actorName,
          oldDeviceName: oldDeviceName,
          newName: newDeviceName,
          homeName: resolvedHomeName,
        );
      }
    }

    if (_isHomeUpdatedNotification(type)) {
      final actorName = _firstNotificationString(item, const ["actorName"]);
      final oldName = _firstNotificationString(item, const ["oldName"]);
      final newName = _firstNotificationString(item, const [
        "newName",
        "homeName",
      ]);
      final oldAddress = _firstNotificationString(item, const ["oldAddress"]);
      final newAddress = _firstNotificationString(item, const ["newAddress"]);
      final displayHomeName = newName.isNotEmpty ? newName : resolvedHomeName;

      if (displayHomeName.isNotEmpty) {
        final displayActor = actorName.isNotEmpty
            ? actorName
            : t("Một thành viên");
        return homeInfoUpdatedMessage(
          actorName: displayActor,
          newName: displayHomeName,
          nameChanged: oldName.isNotEmpty && oldName != displayHomeName,
          addressChanged: oldAddress.isNotEmpty && oldAddress != newAddress,
        );
      }
    }

    if (_isDeviceDeleteNotification(type)) {
      final deviceName = _notificationDeviceName(item);

      if (deviceName.isNotEmpty && resolvedHomeName.isNotEmpty) {
        return deviceDeleteInProgressMessage(
          deviceName: deviceName,
          homeName: resolvedHomeName,
        );
      }
    }

    if (_isHomeCreatedNotification(type) && resolvedHomeName.isNotEmpty) {
      return homeCreatedMessage(resolvedHomeName);
    }

    if (_isHomeDeletedNotification(type) && resolvedHomeName.isNotEmpty) {
      return homeDeletedMessage(resolvedHomeName);
    }

    final deviceEventMessage = _deviceEventNotificationMessage(
      item,
      resolvedHomeName,
    );
    if (deviceEventMessage != null) {
      return deviceEventMessage;
    }

    final doorClosed = _notificationDoorClosed(item);
    if (doorClosed != null) {
      final deviceName = _notificationDeviceName(item);

      if (deviceName.isNotEmpty && resolvedHomeName.isNotEmpty) {
        return doorClosed
            ? choose(
                vi: "\"$deviceName\" đã đóng trong \"$resolvedHomeName\".",
                fil:
                    "Nagsara ang \"$deviceName\" sa bahay na \"$resolvedHomeName\".",
                km: "\"$deviceName\" បានបិទនៅក្នុង \"$resolvedHomeName\"។",
                en: "\"$deviceName\" closed in \"$resolvedHomeName\".",
                zh: "“$deviceName”已在“$resolvedHomeName”中关闭。",
                ko: "\"$resolvedHomeName\"의 \"$deviceName\"이 닫혔습니다.",
                ja: "「$resolvedHomeName」の「$deviceName」が閉じました。",
                de: '"$deviceName" wurde in "$resolvedHomeName" geschlossen.',
                ru: '"$deviceName" закрыт в "$resolvedHomeName".',

                es: "«$deviceName» está cerrado en «$resolvedHomeName».",
                fr: _fr(
                  vi: "\"$deviceName\" đã đóng trong \"$resolvedHomeName\".",
                  en: "\"$deviceName\" closed in \"$resolvedHomeName\".",
                ),
                id: "\"$deviceName\" tertutup di \"$resolvedHomeName\".",
                th: "\"$deviceName\" ปิดแล้วใน \"$resolvedHomeName\"",
                ms: "\"$deviceName\" telah ditutup di \"$resolvedHomeName\".",
                my: "\"$resolvedHomeName\" တွင် \"$deviceName\" ပိတ်သွားသည်။",
                lo: "\"$deviceName\" ປິດແລ້ວໃນ \"$resolvedHomeName\"",
              )
            : choose(
                vi: "\"$deviceName\" đang mở trong \"$resolvedHomeName\".",
                fil:
                    "Bukas ang \"$deviceName\" sa bahay na \"$resolvedHomeName\".",
                km: "\"$deviceName\" បើកនៅក្នុង \"$resolvedHomeName\"។",
                en: "\"$deviceName\" is open in \"$resolvedHomeName\".",
                zh: "“$deviceName”在“$resolvedHomeName”中处于打开状态。",
                ko: "\"$resolvedHomeName\"의 \"$deviceName\"이 열려 있습니다.",
                ja: "「$resolvedHomeName」の「$deviceName」が開いています。",
                de: '"$deviceName" ist in "$resolvedHomeName" geöffnet.',
                ru: '"$deviceName" открыт в "$resolvedHomeName".',

                es: "«$deviceName» está abierto en «$resolvedHomeName».",
                fr: _fr(
                  vi: "\"$deviceName\" đang mở trong \"$resolvedHomeName\".",
                  en: "\"$deviceName\" is open in \"$resolvedHomeName\".",
                ),
                id: "\"$deviceName\" terbuka di \"$resolvedHomeName\".",
                th: "\"$deviceName\" เปิดอยู่ใน \"$resolvedHomeName\"",
                ms: "\"$deviceName\" sedang terbuka di \"$resolvedHomeName\".",
                my: "\"$resolvedHomeName\" တွင် \"$deviceName\" ဖွင့်ထားသည်။",
                lo: "\"$deviceName\" ເປີດຢູ່ໃນ \"$resolvedHomeName\"",
              );
      }

      if (deviceName.isNotEmpty) {
        return "$deviceName: ${_doorStatusTitle(doorClosed)}";
      }
    }

    final rawMessage = _firstNotificationString(item, const [
      "message",
      "body",
      "text",
    ]);
    final message = systemNotificationText(rawMessage, type: type);

    return statusText(message);
  }

  String? _homeLifecycleNotificationTitle(String type) {
    return switch (type) {
      "alarm_resolved" => t("Cảnh báo an ninh đã kết thúc"),
      "emergency_resolved" => t("Sự cố nguy hiểm đã kết thúc"),
      "alarm_pause_ended" => t("Báo động đã hoạt động trở lại"),
      "system_hub_offline" => t("Hub mất kết nối"),
      "system_hub_online" => t("Hub đã kết nối trở lại"),
      "system_mqtt_offline" => t("MQTT mất kết nối"),
      "system_mqtt_online" => t("MQTT đã kết nối trở lại"),
      "system_device_offline" => t("Thiết bị offline"),
      "system_device_online" => t("Thiết bị online"),
      "system_device_low_battery" => t("Pin yếu"),
      "system_device_battery_ok" => t("Pin thiết bị đã ổn định"),
      "physical_siren_muted" => t("Còi báo động đã được tắt"),
      "security_mode_normal" => t("Đã chuyển nhà về Bình thường"),
      "auto_away_armed" => t("Bảo vệ tự động đã bật"),
      "auto_away_normal" => t("Bảo vệ tự động đã tắt"),
      "device_added" => t("Thiết bị mới"),
      "device_delete_succeeded" => t("Thiết bị đã được xoá"),
      "device_delete_failed" => t("Không thể xoá thiết bị"),
      _ => null,
    };
  }

  String? _homeLifecycleNotificationMessage(
    Map<String, dynamic> item,
    String type,
    String homeName,
  ) {
    final deviceName = _notificationDeviceName(item);
    final actorName = _firstNotificationString(item, const ["actorName"]);

    switch (type) {
      case "alarm_resolved":
      case "emergency_resolved":
        final hasRemaining = _notificationBool(
              _firstNotificationValue(
                item,
                const ["hasRemainingActiveIncidents"],
              ),
            ) ==
            true;
        return hasRemaining
            ? t("Vẫn còn cảnh báo khác đang hoạt động.")
            : t("Cảnh báo đã được kết thúc.");
      case "alarm_pause_ended":
        return t("Thời gian tạm dừng báo động đã kết thúc.");
      case "system_hub_offline":
        return t("Hub mất kết nối");
      case "system_hub_online":
        return t("Hub đã kết nối trở lại");
      case "system_mqtt_offline":
        return t("MQTT mất kết nối");
      case "system_mqtt_online":
        return t("MQTT đã kết nối trở lại");
      case "system_device_offline":
        return deviceName.isNotEmpty && homeName.isNotEmpty
            ? deviceOfflineMessage(name: deviceName, homeName: homeName)
            : null;
      case "system_device_online":
        return deviceName.isNotEmpty && homeName.isNotEmpty
            ? deviceOnlineMessage(name: deviceName, homeName: homeName)
            : null;
      case "system_device_low_battery":
        return deviceName.isNotEmpty && homeName.isNotEmpty
            ? deviceLowBatteryMessage(name: deviceName, homeName: homeName)
            : null;
      case "system_device_battery_ok":
        return deviceName.isNotEmpty
            ? deviceReturnedNormalMessage(deviceName)
            : t("Pin thiết bị đã ổn định");
      case "physical_siren_muted":
        final actor = actorName.isNotEmpty ? actorName : t("Một thành viên");
        return "$actor: ${t("Còi báo động đã được tắt")}. "
            "${t("Sự cố vẫn đang được theo dõi.")}";
      case "security_mode_normal":
        final actor = actorName.isNotEmpty ? actorName : t("Một thành viên");
        return "$actor: ${t("Chế độ Bảo vệ đã được tắt.")} "
            "${t("Nhà đang ở chế độ Bình thường.")}";
      case "auto_away_armed":
        return t("Toàn bộ thành viên đã rời khỏi nhà.");
      case "auto_away_normal":
        final reason = _firstNotificationString(item, const ["reason"]);
        return reason == "member_returned"
            ? t("Có thành viên đã trở về nhà.")
            : t("Nhà đang ở chế độ Bình thường.");
      case "device_added":
        return deviceName.isNotEmpty && homeName.isNotEmpty
            ? deviceAddedMessage(deviceName: deviceName, homeName: homeName)
            : null;
      case "device_delete_succeeded":
        return deviceName.isNotEmpty
            ? "$deviceName: ${t("Thiết bị đã được xoá")}"
            : t("Thiết bị đã được xoá");
      case "device_delete_failed":
        return deviceName.isNotEmpty
            ? "$deviceName: ${t("Hãy thử lại thao tác xoá thiết bị.")}"
            : t("Hãy thử lại thao tác xoá thiết bị.");
    }

    return null;
  }

  String _doorStatusTitle(bool closed) {
    return closed
        ? choose(
            vi: "Cửa đã đóng",
            en: "Door closed",
            zh: "门已关闭",
            ko: "문이 닫힘",
            ja: "ドアが閉じました",
            de: 'Tür geschlossen',
            ru: 'Дверь закрыта',

            es: "La puerta está cerrada",
            fr: _fr(vi: "Cửa đã đóng", en: "Door closed"),
          )
        : choose(
            vi: "Cửa đang mở",
            en: "Door is open",
            zh: "门已打开",
            ko: "문이 열려 있음",
            ja: "ドアが開いています",
            de: 'Tür geöffnet',
            ru: 'Дверь открыта',

            es: "La puerta está abierta",
            fr: _fr(vi: "Cửa đang mở", en: "Door is open"),
          );
  }

  String? _deviceEventNotificationTitle(Map<String, dynamic> item) {
    final type = _notificationString(item, "type").toLowerCase();
    final event = _notificationString(item, "event").toLowerCase();
    final availability = _notificationString(
      item,
      "availability",
    ).toLowerCase();
    final condition = _notificationString(item, "condition").toLowerCase();

    if (type == "device_smoke" || event == "smoke_detected") {
      return t("Cảnh báo khói");
    }

    if (type == "device_smoke_clear" || event == "smoke_cleared") {
      return t("Khói đã an toàn");
    }

    if (type == "device_sos" || event == "sos_triggered") {
      return t("SOS được kích hoạt");
    }

    if (type == "device_sos_clear" || event == "sos_cleared") {
      return t("SOS đã kết thúc");
    }

    if (type == "device_tamper" || event == "tamper_detected") {
      return t("Thiết bị bị tháo");
    }

    if (type == "device_tamper_clear" || event == "tamper_cleared") {
      return t("Tamper bình thường");
    }

    if (type == "device_battery_low" || event == "battery_low") {
      return t("Pin yếu");
    }

    if ((type == "device_connection" && availability == "offline") ||
        event == "device_offline") {
      return t("Thiết bị offline");
    }

    if ((type == "device_connection" && availability == "online") ||
        event == "device_online") {
      return t("Thiết bị online");
    }

    if ((type == "device_environment" && condition == "temperature_high") ||
        event == "high_temperature") {
      return t("Nhiệt độ cao");
    }

    if ((type == "device_environment" && condition == "humidity_high") ||
        event == "high_humidity") {
      return t("Độ ẩm cao");
    }

    return null;
  }

  String? _deviceEventNotificationMessage(
    Map<String, dynamic> item,
    String resolvedHomeName,
  ) {
    final type = _notificationString(item, "type").toLowerCase();
    final event = _notificationString(item, "event").toLowerCase();
    final availability = _notificationString(
      item,
      "availability",
    ).toLowerCase();
    final condition = _notificationString(item, "condition").toLowerCase();
    final deviceName = _notificationDeviceName(item);

    if (deviceName.isEmpty) {
      return null;
    }

    if (type == "device_smoke" || event == "smoke_detected") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceSmokeDetectedMessage(
              name: deviceName,
              homeName: resolvedHomeName,
            );
    }

    if (type == "device_smoke_clear" || event == "smoke_cleared") {
      return deviceReturnedNormalMessage(deviceName);
    }

    if (type == "device_sos" || event == "sos_triggered") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceSosTriggeredMessage(
              name: deviceName,
              homeName: resolvedHomeName,
            );
    }

    if (type == "device_sos_clear" || event == "sos_cleared") {
      return deviceSosClearedMessage(deviceName);
    }

    if (type == "device_tamper" || event == "tamper_detected") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceTamperDetectedMessage(
              name: deviceName,
              homeName: resolvedHomeName,
            );
    }

    if (type == "device_tamper_clear" || event == "tamper_cleared") {
      return deviceTamperClearedMessage(deviceName);
    }

    if (type == "device_battery_low" || event == "battery_low") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceLowBatteryMessage(
              name: deviceName,
              homeName: resolvedHomeName,
            );
    }

    if ((type == "device_connection" && availability == "offline") ||
        event == "device_offline") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceOfflineMessage(name: deviceName, homeName: resolvedHomeName);
    }

    if ((type == "device_connection" && availability == "online") ||
        event == "device_online") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceOnlineMessage(name: deviceName, homeName: resolvedHomeName);
    }

    if ((type == "device_environment" && condition == "temperature_high") ||
        event == "high_temperature") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceHighTemperatureMessage(
              name: deviceName,
              homeName: resolvedHomeName,
            );
    }

    if ((type == "device_environment" && condition == "humidity_high") ||
        event == "high_humidity") {
      return resolvedHomeName.isEmpty
          ? null
          : deviceHighHumidityMessage(
              name: deviceName,
              homeName: resolvedHomeName,
            );
    }

    return null;
  }

  Map<String, dynamic> _notificationData(Map<String, dynamic> item) {
    final data = item["data"];

    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  dynamic _firstNotificationValue(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    final data = _notificationData(item);

    for (final key in keys) {
      final value = item[key] ?? data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String _notificationString(Map<String, dynamic> item, String key) {
    return _firstNotificationString(item, [key]);
  }

  String _firstNotificationString(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    final value = _firstNotificationValue(item, keys);

    return value?.toString().trim() ?? "";
  }

  bool _isMemberRoleNotification(String type) {
    return type == "member_role_changed" || type == "role_changed";
  }

  bool _isManualSecurityModeNotification(String type) {
    return type == "manual_security_mode_enabled" ||
        type == "manual_security_enabled" ||
        type == "manual_guard_enabled";
  }

  bool _isMemberLeftHomeNotification(String type) {
    return type == "member_leave" ||
        type == "member_left" ||
        type == "member_left_home";
  }

  bool _isMemberJoinedHomeNotification(String type) {
    return type == "member_join" || type == "member_joined_home";
  }

  bool _isAlarmSettingChangedNotification(String type) {
    return type == "alarm_setting_changed";
  }

  bool _isDeviceRenamedNotification(String type) {
    return type == "device_renamed" || type == "device_rename";
  }

  bool _isHomeUpdatedNotification(String type) {
    return type == "home_renamed" ||
        type == "home_info_updated" ||
        type == "home_updated";
  }

  bool _isDeviceDeleteNotification(String type) {
    return type == "device_delete_requested" ||
        type == "device_delete_in_progress";
  }

  bool _isHomeCreatedNotification(String type) {
    return type == "home_created";
  }

  bool _isHomeDeletedNotification(String type) {
    return type == "home_deleted";
  }

  bool _isAbnormalNotification(String type, String title) {
    final normalizedTitle = _normalizeNotificationText(title);

    return type == "device_tamper" ||
        type == "tamper" ||
        type == "device_tamper_detected" ||
        normalizedTitle == _normalizeNotificationText("Phát hiện bất thường") ||
        normalizedTitle == "abnormal activity detected";
  }

  bool _isDoorNotificationType(String type) {
    return const {
      "device_contact",
      "door",
      "door_open",
      "door_closed",
      "device_door_open",
      "device_door_closed",
      "device_door",
      "status",
    }.contains(type);
  }

  bool _isDoorDevice(Map<String, dynamic> item) {
    final deviceType = _firstNotificationString(item, const [
      "deviceType",
      "entityType",
    ]).toLowerCase();

    return const {
      "door",
      "window",
      "gate",
      "lock",
      "door_lock",
      "contact",
    }.contains(deviceType);
  }

  bool? _notificationBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final text = value?.toString().trim().toLowerCase() ?? "";

    if (text == "true" || text == "1" || text == "closed") {
      return true;
    }

    if (text == "false" || text == "0" || text == "open") {
      return false;
    }

    return null;
  }

  bool? _notificationDoorClosed(Map<String, dynamic> item) {
    final type = _notificationString(item, "type").toLowerCase();
    final isDoorEvent = _isDoorNotificationType(type) || _isDoorDevice(item);

    if (type == "door_open" || type == "device_door_open") {
      return false;
    }

    if (type == "door_closed" || type == "device_door_closed") {
      return true;
    }

    final contactValue = _firstNotificationValue(item, const [
      "contact",
      "isClosed",
      "closed",
    ]);
    final contactClosed = _notificationBool(contactValue);
    if (contactClosed != null && isDoorEvent) {
      return contactClosed;
    }

    final openValue = _firstNotificationValue(item, const ["isOpen", "open"]);
    final isOpen = _notificationBool(openValue);
    if (isOpen != null && isDoorEvent) {
      return !isOpen;
    }

    for (final key in const [
      "status",
      "event",
      "action",
      "state",
      "message",
      "text",
      "title",
    ]) {
      final statusText = _notificationString(item, key);
      final textClosed = _doorClosedFromText(statusText);
      if (textClosed != null &&
          (isDoorEvent || _looksLikeDoorStatusText(statusText))) {
        return textClosed;
      }
    }

    final severity = _notificationString(item, "severity").toLowerCase();
    if (isDoorEvent) {
      if (severity == "success" || severity == "cleared") {
        return true;
      }

      if (severity == "warning" || severity == "critical") {
        return false;
      }
    }

    return null;
  }

  bool? _doorClosedFromText(String text) {
    final normalized = _normalizeNotificationText(text);

    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.contains("cửa đã đóng") ||
        normalized.contains("cửa đóng") ||
        normalized.contains("door closed")) {
      return true;
    }

    if (normalized.contains("cửa đang mở") ||
        normalized.contains("cửa mở") ||
        normalized.contains("door is open") ||
        normalized.contains("door opened")) {
      return false;
    }

    if (normalized == "closed") {
      return true;
    }

    if (normalized == "open") {
      return false;
    }

    return null;
  }

  bool _looksLikeDoorStatusText(String text) {
    final normalized = _normalizeNotificationText(text);

    return normalized.contains("cửa") || normalized.contains("door");
  }

  String _notificationDeviceName(Map<String, dynamic> item) {
    final direct = _firstNotificationString(item, const [
      "deviceName",
      "device_name",
    ]);

    if (direct.isNotEmpty) {
      return direct;
    }

    final rawLine = _firstNotificationString(item, const [
      "message",
      "body",
      "text",
      "title",
    ]);
    final separator = rawLine.indexOf(":");

    if (separator <= 0) {
      return "";
    }

    final details = rawLine.substring(separator + 1);

    return _doorClosedFromText(details) == null
        ? ""
        : rawLine.substring(0, separator).trim();
  }

  String _normalizeNotificationText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r"\s+"), " ");
  }

  static const Map<String, String> _translationAliases = {
    "pin yếu": "Pin yếu",
    "sóng yếu": "Sóng yếu",
    "CẦN CHÚ Ý": "Cần chú ý",
    "Cần kiểm tra": "CẦN KIỂM TRA",
    "Hủy": "HỦY",
    "Xác nhận": "XÁC NHẬN",
  };

  static const Map<String, String> _vietnameseDisplayOverrides = viStrings;

  static const Map<String, String> _english = enStrings;

  static const Map<String, String> _chinese = zhStrings;

  static const Map<String, String> _korean = koStrings;

  static const Map<String, String> _japanese = jaStrings;

  static const Map<String, String> _german = deStrings;

  static const Map<String, String> _russian = ruStrings;

  static const Map<String, String> _french = frStrings;

  static const Map<String, String> _spanish = esStrings;

  static const Map<String, String> _indonesian = idStrings;

  static const Map<String, String> _thai = thStrings;

  static const Map<String, String> _malay = msStrings;

  static const Map<String, String> _filipino = filStrings;

  static const Map<String, String> _khmer = kmStrings;

  static const Map<String, String> _burmese = myStrings;

  static const Map<String, String> _lao = loStrings;

  String t(String vi) {
    final key = _translationAliases[vi] ?? vi;

    if (isThai) {
      return _translationFromMap(_thai, key) ?? vi;
    }

    if (isMalay) {
      return _translationFromMap(_malay, key) ?? vi;
    }

    if (isFilipino) {
      return _translationFromMap(_filipino, key) ?? vi;
    }

    if (isKhmer) {
      return _translationFromMap(_khmer, key) ?? vi;
    }

    if (isBurmese) {
      return _translationFromMap(_burmese, key) ?? vi;
    }

    if (isLao) {
      return _translationFromMap(_lao, key) ?? vi;
    }

    if (isIndonesian) {
      return _translationFromMap(_indonesian, key) ?? vi;
    }

    if (isSpanish) {
      return _spanish[key] ?? vi;
    }

    if (isFrench) {
      return _french[key] ?? vi;
    }

    if (isRussian) {
      return _russian[key] ?? vi;
    }

    if (isGerman) {
      return _german[key] ?? vi;
    }

    if (isJapanese) {
      return _japanese[key] ?? vi;
    }

    if (isKorean) {
      return _korean[key] ?? vi;
    }

    if (isChinese) {
      return _chinese[key] ?? vi;
    }

    if (!isEnglish) {
      return _vietnameseDisplayOverrides[vi] ?? vi;
    }

    return _english[key] ?? vi;
  }

  String get alarm => t("Báo động");
  String get alarmSettings => t("Cài đặt báo động");
  String get alarmNotification => t("Thông báo báo động");
  String get stopAlarm => t("Tắt báo động");
  String get reminder => t("Nhắc nhở");
  String get reminderSettings => t("Cài đặt nhắc nhở");
  String get scheduledReminder => t("Nhắc nhở theo lịch");
  String get notification => t("Thông báo");
  String get notifications => t("Danh sách thông báo");
  String get notificationSettings => t("Cài đặt thông báo");

  String selectedHomesCountText(int count) => choose(
    vi: "$count nhà đã chọn",
    fil: "$count bahay ang napili",
    km: "បានជ្រើសរើសផ្ទះចំនួន $count",
    en: "$count homes selected",
    zh: "已选择 $count 个家庭",
    ko: "선택한 집 $count개",
    ja: "$count 件の家を選択済み",
    de: '$count Zuhause ausgewählt',
    ru: '$count домов выбрано',

    es: "$count casas seleccionadas",
    fr: _fr(vi: "$count nhà đã chọn", en: "$count homes selected"),
    id: "$count rumah dipilih",
    th: "เลือกบ้าน $count หลัง",
    ms: "$count rumah terpilih",
    my: "အိမ် $count လုံး ရွေးထားသည်",
    lo: "ເລືອກ $count ເຮືອນ",
  );

  String allHomeEmergencyCountText(int count, {String reason = ""}) {
    final suffix = reason.trim().isNotEmpty ? " • ${reason.trim()}" : "";
    return choose(
      vi: "🆘 $count nhà nguy hiểm$suffix",
      fil: "🆘 $count bahay ang nasa panganib$suffix",
      km: "🆘 ផ្ទះគ្រោះថ្នាក់ចំនួន $count$suffix",
      en: "🆘 $count homes in danger$suffix",
      zh: "🆘 $count 个家庭处于危险中$suffix",
      ko: "🆘 위험 상태인 집 $count개$suffix",
      ja: "🆘 危険状態の家 $count 件$suffix",
      de: "🆘 $count Zuhause in Gefahr$suffix",
      ru: "🆘 $count домов в опасности$suffix",
      fr: "🆘 $count maisons en danger$suffix",
      es: "🆘 $count casas en peligro$suffix",
      id: "🆘 $count rumah dalam bahaya$suffix",
      th: "🆘 บ้านที่อยู่ในอันตราย $count หลัง$suffix",
      ms: "🆘 $count rumah dalam bahaya$suffix",
      my: "🆘 အန္တရာယ်ရှိသောအိမ် $count လုံး$suffix",
      lo: "🆘 $count ເຮືອນຢູ່ໃນອັນຕະລາຍ$suffix",
    );
  }

  String allHomeDangerCountText(int count, {String reason = ""}) {
    final suffix = reason.trim().isNotEmpty ? " • ${reason.trim()}" : "";
    return choose(
      vi: "🚨 $count nhà không an toàn$suffix",
      fil: "🚨 $count bahay ang hindi ligtas$suffix",
      km: "🚨 ផ្ទះមិនមានសុវត្ថិភាពចំនួន $count$suffix",
      en: "🚨 $count unsafe homes$suffix",
      zh: "🚨 $count 个家庭不安全$suffix",
      ko: "🚨 안전하지 않은 집 $count개$suffix",
      ja: "🚨 安全ではない家 $count 件$suffix",
      de: '🚨 $count Zuhause nicht sicher$suffix',
      ru: '🚨 $count домов небезопасны$suffix',

      es: "🚨 $count casas no seguras$suffix",
      fr: _fr(
        vi: "🚨 $count nhà không an toàn$suffix",
        en: "🚨 $count unsafe homes$suffix",
      ),
      id: "🚨 $count rumah tidak aman$suffix",
      th: "🚨 บ้านที่ไม่ปลอดภัย $count หลัง$suffix",
      ms: "🚨 $count rumah tidak selamat$suffix",
      my: "🚨 မလုံခြုံသောအိမ် $count လုံး$suffix",
      lo: "🚨 $count ເຮືອນບໍ່ປອດໄພ$suffix",
    );
  }

  String allHomeWarningCountText(int count, {String reason = ""}) {
    final suffix = reason.trim().isNotEmpty ? " • ${reason.trim()}" : "";
    return choose(
      vi: "⚠️ $count nhà cần chú ý$suffix",
      fil: "⚠️ $count bahay ang kailangang bigyang-pansin$suffix",
      km: "⚠️ ផ្ទះត្រូវការការយកចិត្តទុកដាក់ចំនួន $count$suffix",
      en: "⚠️ $count homes need attention$suffix",
      zh: "⚠️ $count 个家庭需要注意$suffix",
      ko: "⚠️ 주의가 필요한 집 $count개$suffix",
      ja: "⚠️ 確認が必要な家 $count 件$suffix",
      de: '⚠️ $count Zuhause erfordern Aufmerksamkeit$suffix',
      ru: '⚠️ $count домов требуют внимания$suffix',

      es: "⚠️ $count casas requieren atención$suffix",
      fr: _fr(
        vi: "⚠️ $count nhà cần chú ý$suffix",
        en: "⚠️ $count homes need attention$suffix",
      ),
      id: "⚠️ $count rumah perlu perhatian$suffix",
      th: "⚠️ บ้านที่ต้องตรวจสอบ $count หลัง$suffix",
      ms: "⚠️ $count rumah memerlukan perhatian$suffix",
      my: "⚠️ စစ်ဆေးရန်လိုသောအိမ် $count လုံး$suffix",
      lo: "⚠️ $count ເຮືອນຕ້ອງໃສ່ໃຈ$suffix",
    );
  }

  String allHomeSafeCountText(int count) => choose(
    vi: "✅ $count nhà an toàn",
    fil: "✅ $count ligtas na bahay",
    km: "✅ ផ្ទះមានសុវត្ថិភាពចំនួន $count",
    en: "✅ $count safe homes",
    zh: "✅ $count 个家庭安全",
    ko: "✅ 안전한 집 $count개",
    ja: "✅ 安全な家 $count 件",
    de: '✅ $count Zuhause sicher',
    ru: '✅ $count домов безопасны',

    es: "✅ $count casas seguras",
    fr: _fr(vi: "✅ $count nhà an toàn", en: "✅ $count safe homes"),
    id: "✅ $count rumah aman",
    th: "✅ บ้านที่ปลอดภัย $count หลัง",
    ms: "✅ $count rumah selamat",
    my: "✅ လုံခြုံသောအိမ် $count လုံး",
    lo: "✅ $count ເຮືອນປອດໄພ",
  );

  String monitoredHomesCountText(int count) => choose(
    vi: "$count nhà đang được theo dõi",
    fil: "$count bahay ang sinusubaybayan",
    km: "កំពុងតាមដានផ្ទះចំនួន $count",
    en: "$count homes monitored",
    zh: "正在监测 $count 个家庭",
    ko: "집 $count개를 모니터링 중입니다",
    ja: "$count 件の家を監視中",
    de: '$count Zuhause werden überwacht',
    ru: '$count домов под наблюдением',

    es: "$count casas supervisadas",
    fr: _fr(vi: "$count nhà đang được theo dõi", en: "$count homes monitored"),
    id: "$count rumah dipantau",
    th: "กำลังตรวจสอบบ้าน $count หลัง",
    ms: "$count rumah sedang dipantau",
    my: "အိမ် $count လုံးကို စောင့်ကြည့်နေသည်",
    lo: "ກຳລັງຕິດຕາມ $count ເຮືອນ",
  );

  String minuteText(int minutes) => choose(
    vi: "$minutes phút",
    fil: "$minutes minuto",
    km: "$minutes នាទី",
    en: "$minutes minutes",
    zh: "$minutes 分钟",
    ko: "$minutes분",
    ja: "$minutes 分",
    de: '$minutes Minuten',
    ru: '$minutes минут',

    es: "$minutes minutos",
    fr: _fr(vi: "$minutes phút", en: "$minutes minutes"),
    id: "$minutes menit",
    th: "$minutes นาที",
    ms: "$minutes minit",
    my: "$minutes မိနစ်",
    lo: "$minutes ນາທີ",
  );

  String allHomeReminderAppliedText(
    int updatedHomes,
    int skippedHomes,
  ) => choose(
    vi:
        "Đã cài nhắc nhở cho $updatedHomes nhà."
        "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}",
    fil:
        "Naitakda ang paalala para sa $updatedHomes bahay."
        "${skippedHomes > 0 ? "\n\nNilaktawan ang $skippedHomes bahay dahil wala kang pahintulot." : ""}",
    km:
        "បានកំណត់ ការរំលឹក សម្រាប់ផ្ទះចំនួន $updatedHomes។"
        "${skippedHomes > 0 ? "\n\nផ្ទះចំនួន $skippedHomes ត្រូវបានរំលង ព្រោះអ្នកមិនមានសិទ្ធិ។" : ""}",
    en:
        "Reminder was set for $updatedHomes homes."
        "${skippedHomes > 0 ? "\n\n$skippedHomes homes were skipped because you do not have permission." : ""}",
    zh:
        "已为 $updatedHomes 个家庭设置 提醒。"
        "${skippedHomes > 0 ? "\n\n$skippedHomes 个家庭因没有权限而被跳过。" : ""}",
    ko:
        "$updatedHomes개 집에 리마인더를 설정했습니다."
        "${skippedHomes > 0 ? "\n\n권한이 없어 $skippedHomes개 집을 건너뛰었습니다." : ""}",
    ja:
        "$updatedHomes 件の家に リマインダー を設定しました。"
        "${skippedHomes > 0 ? "\n\n権限がないため $skippedHomes 件の家をスキップしました。" : ""}",
    de:
        'Erinnerung wurde für $updatedHomes Zuhause eingerichtet.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes Zuhause wurden übersprungen, weil du keine Berechtigung hast." : ""}',
    ru:
        'Напоминание установлен для $updatedHomes домов.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes домов пропущено, потому что у вас нет разрешения." : ""}',

    es:
        "Recordatorio configurado para $updatedHomes casas."
        "${skippedHomes > 0 ? "\n\nSe omitieron $skippedHomes casas porque no tienes permiso." : ""}",
    fr:
        "Rappel configuré pour $updatedHomes maisons."
        "${skippedHomes > 0 ? "\n\n$skippedHomes maisons ont été ignorées car vous n'avez pas l'autorisation." : ""}",
    id:
        "Pengingat telah diatur untuk $updatedHomes rumah."
        "${skippedHomes > 0 ? "\n\n$skippedHomes rumah dilewati karena Anda tidak memiliki izin." : ""}",
    th:
        "ตั้งค่า การเตือนความจำ ให้บ้าน $updatedHomes หลังแล้ว"
        "${skippedHomes > 0 ? "\n\nข้ามบ้าน $skippedHomes หลังเนื่องจากคุณไม่มีสิทธิ์" : ""}",
    ms:
        "Peringatan telah ditetapkan untuk $updatedHomes rumah."
        "${skippedHomes > 0 ? "\n\n$skippedHomes rumah dilangkau kerana anda tiada kebenaran." : ""}",
    my:
        "$updatedHomes အိမ်အတွက် သတိပေးချက် သတ်မှတ်ပြီးပါပြီ။"
        "${skippedHomes > 0 ? "\n\nခွင့်ပြုချက်မရှိသောကြောင့် အိမ် $skippedHomes လုံးကို ကျော်ခဲ့သည်။" : ""}",
    lo:
        "ຕັ້ງການເຕືອນຄວາມຈຳໃຫ້ $updatedHomes ເຮືອນແລ້ວ."
        "${skippedHomes > 0 ? "\n\nຂ້າມ $skippedHomes ເຮືອນເພາະທ່ານບໍ່ມີສິດ." : ""}",
  );

  String allHomeAlarmAppliedText({
    required int updatedDevices,
    required int updatedHomes,
    required String repeatLabel,
    required int skippedHomes,
  }) => choose(
    vi:
        "Đã cài báo động cho $updatedDevices thiết bị trong $updatedHomes nhà.\n"
        "Thời gian lặp lại: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}",
    fil:
        "Naitakda ang alarma para sa $updatedDevices aparato sa $updatedHomes bahay.\n"
        "Oras ng pag-uulit: $repeatLabel."
        "${skippedHomes > 0 ? "\n\nNilaktawan ang $skippedHomes bahay dahil wala kang pahintulot." : ""}",
    km:
        "បានកំណត់ សំឡេងរោទិ៍ សម្រាប់ឧបករណ៍ $updatedDevices នៅក្នុងផ្ទះចំនួន $updatedHomes។\n"
        "ចន្លោះពេលកើតឡើងវិញ៖ $repeatLabel។"
        "${skippedHomes > 0 ? "\n\nផ្ទះចំនួន $skippedHomes ត្រូវបានរំលង ព្រោះអ្នកមិនមានសិទ្ធិ។" : ""}",
    en:
        "Alarm was set for $updatedDevices devices across $updatedHomes homes.\n"
        "Repeat time: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes homes were skipped because you do not have permission." : ""}",
    zh:
        "已为 $updatedHomes 个家庭中的 $updatedDevices 台设备设置 警报。\n"
        "重复时间：$repeatLabel。"
        "${skippedHomes > 0 ? "\n\n$skippedHomes 个家庭因没有权限而被跳过。" : ""}",
    ko:
        "$updatedHomes개 집의 기기 $updatedDevices대에 경보을 설정했습니다.\n"
        "반복 시간: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n권한이 없어 $skippedHomes개 집을 건너뛰었습니다." : ""}",
    ja:
        "$updatedHomes 件の家にある $updatedDevices 台のデバイスに 警報 を設定しました。\n"
        "繰り返し時間: $repeatLabel。"
        "${skippedHomes > 0 ? "\n\n権限がないため $skippedHomes 件の家をスキップしました。" : ""}",
    de:
        'Alarm wurde für $updatedDevices Geräte in $updatedHomes Zuhause eingerichtet.\n'
        'Wiederholungszeit: $repeatLabel.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes Zuhause wurden übersprungen, weil du keine Berechtigung hast." : ""}',
    ru:
        'Тревога установлен для $updatedDevices устройств в $updatedHomes домах.\n'
        'Время повтора: $repeatLabel.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes домов пропущено, потому что у вас нет разрешения." : ""}',

    es:
        "Alarma configurado para $updatedDevices dispositivos en $updatedHomes casas.\n"
        "Tiempo de repetición: $repeatLabel."
        "${skippedHomes > 0 ? "\n\nSe omitieron $skippedHomes casas porque no tienes permiso." : ""}",
    fr:
        "Alarme configuré pour $updatedDevices appareils dans $updatedHomes maisons.\n"
        "Délai de répétition : $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes maisons ont été ignorées car vous n'avez pas l'autorisation." : ""}",
    id:
        "Alarm telah diatur untuk $updatedDevices perangkat di $updatedHomes rumah.\n"
        "Waktu ulang: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes rumah dilewati karena Anda tidak memiliki izin." : ""}",
    th:
        "ตั้งค่า สัญญาณเตือน ให้กับอุปกรณ์ $updatedDevices เครื่องในบ้าน $updatedHomes หลังแล้ว\n"
        "เวลาทำซ้ำ: $repeatLabel"
        "${skippedHomes > 0 ? "\n\nข้ามบ้าน $skippedHomes หลังเนื่องจากคุณไม่มีสิทธิ์" : ""}",
    ms:
        "Penggera telah ditetapkan untuk $updatedDevices peranti di $updatedHomes rumah.\n"
        "Masa ulangan: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes rumah dilangkau kerana anda tiada kebenaran." : ""}",
    my:
        "$updatedHomes အိမ်ရှိ စက်ပစ္စည်း $updatedDevices ခုအတွက် အရေးပေါ်အချက်ပေး သတ်မှတ်ပြီးပါပြီ။\n"
        "ထပ်မံသတိပေးချိန်: $repeatLabel။"
        "${skippedHomes > 0 ? "\n\nခွင့်ပြုချက်မရှိသောကြောင့် အိမ် $skippedHomes လုံးကို ကျော်ခဲ့သည်။" : ""}",
    lo:
        "ຕັ້ງສັນຍານເຕືອນໄພໃຫ້ $updatedDevices ອຸປະກອນໃນ $updatedHomes ເຮືອນແລ້ວ.\n"
        "ເວລາເຮັດຊ້ຳ: $repeatLabel."
        "${skippedHomes > 0 ? "\n\nຂ້າມ $skippedHomes ເຮືອນເພາະທ່ານບໍ່ມີສິດ." : ""}",
  );

  String allHomeShareResultText(int skipped) {
    if (skipped <= 0) {
      return t("Đã chia sẻ nhà thành công.");
    }

    return choose(
      vi: "Đã chia sẻ các nhà bạn có quyền.\n\n$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.",
      fil:
          "Naibahagi ang mga bahay na pinamamahalaan mo.\n\nNilaktawan ang $skipped bahay dahil wala kang pahintulot na ibahagi ang mga ito.",
      km: "បានចែករំលែកផ្ទះដែលអ្នកគ្រប់គ្រង។\n\nផ្ទះចំនួន $skipped ត្រូវបានរំលង ព្រោះអ្នកមិនមានសិទ្ធិចែករំលែក។",
      en: "Homes you manage were shared.\n\n$skipped homes were skipped because you do not have sharing permission.",
      zh: "已共享你有权限管理的家庭。\n\n$skipped 个家庭因没有共享权限而被跳过。",
      ko: "관리 권한이 있는 집을 공유했습니다.\n\n공유 권한이 없어 $skipped개의 집은 건너뛰었습니다.",
      ja: "管理権限のある家を共有しました。\n\n共有権限がないため $skipped 件の家をスキップしました。",
      de: 'Die von dir verwalteten Zuhause wurden geteilt.\n\n$skipped Zuhause wurden übersprungen, weil du keine Freigabeberechtigung hast.',
      ru: 'Дома, которыми вы управляете, были предоставлены.\n\n$skipped домов пропущено, потому что у вас нет разрешения на общий доступ.',

      es: "Se compartieron las casas que administras.\n\nSe omitieron $skipped casas porque no tienes permiso para compartirlas.",
      fr: "Les maisons que vous gérez ont été partagées.\n\n$skipped maisons ont été ignorées car vous n'avez pas l'autorisation de les partager.",
      id: "Rumah yang dapat Anda kelola telah dibagikan.\\n\\n$skipped rumah dilewati karena Anda tidak memiliki izin berbagi.",
      th: "แชร์บ้านที่คุณมีสิทธิ์แล้ว\n\nข้ามบ้าน $skipped หลังเนื่องจากคุณไม่มีสิทธิ์แชร์",
      ms: "Rumah yang anda urus telah dikongsi.\n\n$skipped rumah dilangkau kerana anda tiada kebenaran untuk berkongsi.",
      my: "သင်စီမံခန့်ခွဲသောအိမ်များကို မျှဝေပြီးပါပြီ။\n\nမျှဝေခွင့်မရှိသောကြောင့် အိမ် $skipped လုံးကို ကျော်ခဲ့သည်။",
      lo: "ແບ່ງປັນເຮືອນທີ່ທ່ານຈັດການແລ້ວ.\n\nຂ້າມ $skipped ເຮືອນເພາະທ່ານບໍ່ມີສິດແບ່ງປັນ",
    );
  }

  String alarmAppliedToSecurityDevicesText(int count) => choose(
    vi: "Đã áp dụng báo động cho $count thiết bị an ninh",
    fil: "Inilapat ang alarma sa $count aparatong panseguridad",
    km: "បានអនុវត្ត សំឡេងរោទិ៍ លើឧបករណ៍សន្តិសុខចំនួន $count",
    en: "Alarm applied to $count security devices",
    zh: "警报 已应用到 $count 个安全设备",
    ko: "보안 기기 $count대에 경보을 적용했습니다",
    ja: "$count 台のセキュリティデバイスに 警報 を適用しました",
    de: 'Alarm auf $count Sicherheitsgeräte angewendet',
    ru: 'Тревога применен к $count устройствам безопасности',

    es: "Alarma aplicado a $count dispositivos de seguridad",
    fr: _fr(
      vi: "Đã áp dụng báo động cho $count thiết bị an ninh",
      en: "Alarm applied to $count security devices",
    ),
    id: "Alarm diterapkan ke $count perangkat keamanan",
    th: "ใช้ สัญญาณเตือน กับอุปกรณ์รักษาความปลอดภัย $count เครื่องแล้ว",
    ms: "Penggera telah digunakan pada $count peranti keselamatan",
    my: "လုံခြုံရေးစက်ပစ္စည်း $count ခုအတွက် အရေးပေါ်အချက်ပေးသံ အသုံးပြုပြီးပါပြီ",
    lo: "ນຳໃຊ້ສັນຍານເຕືອນໄພກັບ $count ອຸປະກອນຄວາມປອດໄພແລ້ວ",
  );

  String applySameAlarmScheduleToSecurityDevicesText(int count) => choose(
    vi: "Áp dụng cùng một lịch cho $count thiết bị an ninh",
    fil: "Ilapat ang parehong iskedyul sa $count aparatong panseguridad",
    km: "អនុវត្តកាលវិភាគដូចគ្នាលើឧបករណ៍សន្តិសុខចំនួន $count",
    en: "Apply the same schedule to $count security devices",
    zh: "将同一日程应用到 $count 个安全设备",
    ko: "보안 기기 $count대에 동일한 일정을 적용합니다",
    ja: "$count 台のセキュリティデバイスに同じスケジュールを適用します",
    de: 'Denselben Zeitplan auf $count Sicherheitsgeräte anwenden',
    ru: 'Применить одно расписание к $count устройствам безопасности',

    es: "Aplicar la misma programación a $count dispositivos de seguridad",
    fr: _fr(
      vi: "Áp dụng cùng một lịch cho $count thiết bị an ninh",
      en: "Apply the same schedule to $count security devices",
    ),
    id: "Terapkan jadwal yang sama ke $count perangkat keamanan",
    th: "ใช้กำหนดเวลาเดียวกันกับอุปกรณ์รักษาความปลอดภัย $count เครื่อง",
    ms: "Gunakan jadual yang sama pada $count peranti keselamatan",
    my: "လုံခြုံရေးစက်ပစ္စည်း $count ခုအတွက် တူညီသောအချိန်ဇယား အသုံးပြုရန်",
    lo: "ນຳໃຊ້ຕາຕະລາງດຽວກັນກັບ $count ອຸປະກອນຄວາມປອດໄພ",
  );

  String minutesAgo(int count) => choose(
    vi: "$count phút trước",
    fil: "$count minuto ang nakalipas",
    km: "$count នាទីមុន",
    en: "$count minutes ago",
    zh: "$count 分钟前",
    ko: "$count분 전",
    ja: "$count 分前",
    de: 'vor $count Minuten',
    ru: '$count минут назад',

    es: "hace $count minutos",
    fr: _fr(vi: "$count phút trước", en: "$count minutes ago"),
    id: "$count menit lalu",
    th: "$count นาทีที่แล้ว",
    ms: "$count minit yang lalu",
    my: "$count မိနစ်အကြာက",
    lo: "$count ນາທີກ່ອນ",
  );

  String hoursAgo(int count) => choose(
    vi: "$count giờ trước",
    fil: "$count oras ang nakalipas",
    km: "$count ម៉ោងមុន",
    en: "$count hours ago",
    zh: "$count 小时前",
    ko: "$count시간 전",
    ja: "$count 時間前",
    de: 'vor $count Stunden',
    ru: '$count часов назад',

    es: "hace $count horas",
    fr: _fr(vi: "$count giờ trước", en: "$count hours ago"),
    id: "$count jam lalu",
    th: "$count ชั่วโมงที่แล้ว",
    ms: "$count jam yang lalu",
    my: "$count နာရီအကြာက",
    lo: "$count ຊົ່ວໂມງກ່ອນ",
  );

  String hoursAgoShort(int count) => choose(
    vi: "${count}h trước",
    fil: "${count} oras ang nakalipas",
    km: "${count} ម៉ោងមុន",
    en: "${count}h ago",
    zh: "$count 小时前",
    ko: "$count시간 전",
    ja: "$count 時間前",
    de: 'vor ${count}h',
    ru: '$countч назад',

    es: "hace ${count}h",
    fr: _fr(vi: "${count}h trước", en: "${count}h ago"),
    id: "${count}j lalu",
    th: "${count} ชั่วโมงที่แล้ว",
    ms: "${count} jam lalu",
    my: "${count} နာရီအကြာက",
    lo: "${count} ຊົ່ວໂມງກ່ອນ",
  );

  String hoursMinutesAgoShort(int hours, int minutes) => choose(
    vi: "${hours}h$minutes' trước",
    fil: "${hours} oras at ${minutes} minuto ang nakalipas",
    km: "${hours} ម៉ោង ${minutes} នាទីមុន",
    en: "${hours}h ${minutes}m ago",
    zh: "$hours 小时 $minutes 分钟前",
    ko: "$hours시간 $minutes분 전",
    ja: "$hours 時間 $minutes 分前",
    de: 'vor ${hours}h ${minutes}m',
    ru: '$hoursч $minutesм назад',

    es: "hace ${hours}h ${minutes}m",
    fr: _fr(vi: "${hours}h$minutes' trước", en: "${hours}h ${minutes}m ago"),
    id: "${hours}j ${minutes}m lalu",
    th: "${hours} ชม. $minutes นาทีที่แล้ว",
    ms: "${hours} jam $minutes minit lalu",
    my: "${hours} နာရီ ${minutes} မိနစ်အကြာက",
    lo: "${hours} ຊົ່ວໂມງ $minutes ນາທີກ່ອນ",
  );

  String daysAgo(int count) => choose(
    vi: "$count ngày trước",
    fil: "$count araw ang nakalipas",
    km: "$count ថ្ងៃមុន",
    en: "$count days ago",
    zh: "$count 天前",
    ko: "$count일 전",
    ja: "$count 日前",
    de: 'vor $count Tagen',
    ru: '$count дней назад',

    es: "hace $count días",
    fr: _fr(vi: "$count ngày trước", en: "$count days ago"),
    id: "$count hari lalu",
    th: "$count วันที่แล้ว",
    ms: "$count hari yang lalu",
    my: "$count ရက်အကြာက",
    lo: "$count ມື້ກ່ອນ",
  );

  String monthsAgo(int count) => choose(
    vi: "$count tháng trước",
    fil: "$count buwan ang nakalipas",
    km: "$count ខែមុន",
    en: "$count months ago",
    zh: "$count 个月前",
    ko: "$count개월 전",
    ja: "$count か月前",
    de: 'vor $count Monaten',
    ru: '$count месяцев назад',

    es: "hace $count meses",
    fr: _fr(vi: "$count tháng trước", en: "$count months ago"),
    id: "$count bulan lalu",
    th: "$count เดือนที่แล้ว",
    ms: "$count bulan lalu",
    my: "$count လအကြာက",
    lo: "$count ເດືອນກ່ອນ",
  );

  String confirmRemoveMemberFromHomeText(String name) => choose(
    vi: "Bạn chắc chắn muốn xoá $name khỏi nhà này?",
    fil: "Sigurado ka bang gusto mong alisin si $name sa bahay na ito?",
    km: "តើអ្នកប្រាកដថាចង់ដក $name ចេញពីផ្ទះនេះមែនទេ?",
    en: "Are you sure you want to remove $name from this home?",
    zh: "确定要将 $name 从此家庭中移除吗？",
    ko: "정말 이 집에서 $name 님을 삭제하시겠습니까?",
    ja: "$name をこの家から削除してもよろしいですか？",
    de: 'Möchtest du $name wirklich aus diesem Zuhause entfernen?',
    ru: 'Вы действительно хотите удалить $name из этого дома?',

    es: "¿Seguro que quieres eliminar a $name de esta casa?",
    fr: _fr(
      vi: "Bạn chắc chắn muốn xoá $name khỏi nhà này?",
      en: "Are you sure you want to remove $name from this home?",
    ),
    id: "Yakin ingin menghapus $name dari rumah ini?",
    th: "คุณแน่ใจหรือไม่ว่าต้องการลบ $name ออกจากบ้านหลังนี้",
    ms: "Adakah anda pasti mahu mengalih keluar $name daripada rumah ini?",
    my: "$name ကို ဤအိမ်မှ ဖယ်ရှားလိုသည်မှာ သေချာပါသလား?",
    lo: "ທ່ານແນ່ໃຈບໍວ່າຈະລຶບ $name ອອກຈາກເຮືອນນີ້?",
  );

  String joinHomeRequestTitle(String targetEmail, String homeName) => choose(
    vi: "$targetEmail\nXin gia nhập \"$homeName\"",
    fil: "$targetEmail\nHumihiling na sumali sa \"$homeName\"",
    km: "$targetEmail\nបានស្នើសុំចូលរួម \"$homeName\"",
    en: "$targetEmail\nRequests to join \"$homeName\"",
    zh: "$targetEmail\n申请加入“$homeName”",
    ko: "$targetEmail\n\"$homeName\" 가입 요청",
    ja: "$targetEmail\n「$homeName」への参加をリクエストしています",
    de: '$targetEmail\nMöchte "$homeName" beitreten',
    ru: '$targetEmail\nЗапрашивает доступ к "$homeName"',

    es: "$targetEmail\nSolicita acceso a «$homeName»",
    fr: _fr(
      vi: "$targetEmail\nXin gia nhập \"$homeName\"",
      en: "$targetEmail\nRequests to join \"$homeName\"",
    ),
    id: "$targetEmail\\nMeminta bergabung ke \"$homeName\"",
    th: "$targetEmail\nขอเข้าร่วม \"$homeName\"",
    ms: "$targetEmail\nMemohon untuk menyertai \"$homeName\"",
    my: "$targetEmail\n\"$homeName\" သို့ ဝင်ခွင့်တောင်းထားသည်",
    lo: "$targetEmail\nຂໍເຂົ້າຮ່ວມ \"$homeName\"",
  );

  String joinHomeRequestSubtitle(String homeName) => choose(
    vi: "Xin gia nhập \"$homeName\"",
    fil: "Humihiling na sumali sa \"$homeName\"",
    km: "បានស្នើសុំចូលរួម \"$homeName\"",
    en: "Requests to join \"$homeName\"",
    zh: "申请加入“$homeName”",
    ko: "\"$homeName\" 가입 요청",
    ja: "「$homeName」への参加をリクエストしています",
    de: 'Möchte "$homeName" beitreten',
    ru: 'Запрашивает доступ к "$homeName"',

    es: "Solicita acceso a «$homeName»",
    fr: _fr(
      vi: "Xin gia nhập \"$homeName\"",
      en: "Requests to join \"$homeName\"",
    ),
    id: "Meminta bergabung ke \"$homeName\"",
    th: "ขอเข้าร่วม \"$homeName\"",
    ms: "Memohon untuk menyertai \"$homeName\"",
    my: "\"$homeName\" သို့ ဝင်ခွင့်တောင်းထားသည်",
    lo: "ຂໍເຂົ້າຮ່ວມ \"$homeName\"",
  );

  String ownershipInviteTitle(String homeName) => choose(
    vi: "Bạn được mời nhận quyền nhà \"$homeName\"",
    fil:
        "Inimbitahan kang tanggapin ang pagmamay-ari ng bahay na \"$homeName\"",
    km: "អ្នកត្រូវបានអញ្ជើញឱ្យទទួលសិទ្ធិម្ចាស់ផ្ទះរបស់ \"$homeName\"",
    en: "You were invited to receive ownership of \"$homeName\"",
    zh: "你被邀请接收“$homeName”的屋主权限",
    ko: "\"$homeName\"의 소유권을 받도록 초대되었습니다",
    ja: "「$homeName」の所有権を受け取るよう招待されています",
    de: 'Du wurdest eingeladen, den Besitz von "$homeName" zu übernehmen',
    ru: 'Вас пригласили принять права на дом "$homeName"',

    es: "Te invitaron a recibir la propiedad de «$homeName»",
    fr: _fr(
      vi: "Bạn được mời nhận quyền nhà \"$homeName\"",
      en: "You were invited to receive ownership of \"$homeName\"",
    ),
    id: "Anda diundang untuk menerima kepemilikan \"$homeName\"",
    th: "คุณได้รับเชิญให้รับสิทธิ์เจ้าของบ้านของ \"$homeName\"",
    ms: "Anda dijemput untuk menerima hak pemilik rumah bagi \"$homeName\"",
    my: "\"$homeName\" ၏ပိုင်ဆိုင်မှုကို လက်ခံရန် သင့်ကို ဖိတ်ထားသည်",
    lo: "ທ່ານຖືກເຊີນໃຫ້ຮັບຄວາມເປັນເຈົ້າຂອງ \"$homeName\"",
  );

  String homeInviteTitle(String ownerEmail, String homeName) => choose(
    vi: "$ownerEmail\nMời bạn gia nhập \"$homeName\"",
    fil: "$ownerEmail\nIniimbitahan kang sumali sa \"$homeName\"",
    km: "$ownerEmail\nបានអញ្ជើញអ្នកឱ្យចូលរួម \"$homeName\"",
    en: "$ownerEmail\nInvites you to join \"$homeName\"",
    zh: "$ownerEmail\n邀请你加入“$homeName”",
    ko: "$ownerEmail\n\"$homeName\"에 초대했습니다",
    ja: "$ownerEmail\n「$homeName」への参加に招待しています",
    de: '$ownerEmail\nLädt dich ein, "$homeName" beizutreten',
    ru: '$ownerEmail\nПриглашает вас присоединиться к "$homeName"',

    es: "$ownerEmail\nTe invita a unirte a «$homeName»",
    fr: _fr(
      vi: "$ownerEmail\nMời bạn gia nhập \"$homeName\"",
      en: "$ownerEmail\nInvites you to join \"$homeName\"",
    ),
    id: "$ownerEmail\\nMengundang Anda bergabung ke \"$homeName\"",
    th: "$ownerEmail\nคุณได้รับเชิญให้เข้าร่วม \"$homeName\"",
    ms: "$ownerEmail\nMenjemput anda untuk menyertai \"$homeName\"",
    my: "$ownerEmail\n\"$homeName\" သို့ ဝင်ရန် သင့်ကို ဖိတ်ထားသည်",
    lo: "$ownerEmail\nເຊີນທ່ານເຂົ້າຮ່ວມ \"$homeName\"",
  );

  String homeInviteSubtitle(String homeName) => choose(
    vi: "Mời bạn gia nhập \"$homeName\"",
    fil: "Iniimbitahan kang sumali sa \"$homeName\"",
    km: "បានអញ្ជើញអ្នកឱ្យចូលរួម \"$homeName\"",
    en: "Invites you to join \"$homeName\"",
    zh: "邀请你加入“$homeName”",
    ko: "\"$homeName\"에 초대했습니다",
    ja: "「$homeName」への参加に招待しています",
    de: 'Lädt dich ein, "$homeName" beizutreten',
    ru: 'Приглашает вас присоединиться к "$homeName"',

    es: "Te invita a unirte a «$homeName»",
    fr: _fr(
      vi: "Mời bạn gia nhập \"$homeName\"",
      en: "Invites you to join \"$homeName\"",
    ),
    id: "Mengundang Anda bergabung ke \"$homeName\"",
    th: "คุณได้รับเชิญให้เข้าร่วม \"$homeName\"",
    ms: "Anda dijemput untuk menyertai \"$homeName\"",
    my: "\"$homeName\" သို့ ဝင်ရန် သင့်ကို ဖိတ်ထားသည်",
    lo: "ເຊີນທ່ານເຂົ້າຮ່ວມ \"$homeName\"",
  );

  String deviceWarningsText(List<String> warnings) {
    final joined = warnings.join(", ");
    return choose(
      vi: "Cần kiểm tra: $joined",
      fil: "Kailangang bigyang-pansin: $joined",
      km: "ត្រូវការការយកចិត្តទុកដាក់៖ $joined",
      en: "Needs attention: $joined",
      zh: "需要检查: $joined",
      ko: "확인 필요: $joined",
      ja: "確認が必要: $joined",
      de: 'Aufmerksamkeit erforderlich: $joined',
      ru: 'Требует внимания: $joined',

      es: "Requiere revisión: $joined",
      fr: _fr(vi: "Cần kiểm tra: $joined", en: "Needs attention: $joined"),
      id: "Perlu diperiksa: $joined",
      th: "ต้องตรวจสอบ: $joined",
      ms: "Perlu diperiksa: $joined",
      my: "စစ်ဆေးရန်လိုသည် - $joined",
      lo: "ຕ້ອງກວດ: $joined",
    );
  }

  String updatedAgoText(String value) => choose(
    vi: "Cập nhật $value",
    fil: "In-update ang $value",
    km: "បានធ្វើបច្ចុប្បន្នភាព $value",
    en: "Updated $value",
    zh: "$value更新",
    ko: "$value에 업데이트됨",
    ja: "$valueに更新",
    de: 'Aktualisiert $value',
    ru: 'Обновлено $value',

    es: "Actualizado $value",
    fr: _fr(vi: "Cập nhật $value", en: "Updated $value"),
    id: "Diperbarui $value",
    th: "อัปเดต $value",
    ms: "Dikemas kini $value",
    my: "$value တွင် မွမ်းမံထားသည်",
    lo: "ອັບເດດ $value",
  );

  String statusAddFirstDeviceSuggestion() => choose(
    vi: "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.",
    en: "Add your first SafeHome device to start monitoring this home.",
    zh: "请先添加第一个 SafeHome 设备以开始监控家庭。",
    ko: "집 상태를 확인하려면 먼저 SafeHome 기기를 추가하세요.",
    ja: "家の見守りを始めるには、まず SafeHome デバイスを追加してください。",
    de: 'Füge dein erstes SafeHome-Gerät hinzu, um dieses Zuhause zu überwachen.',
    ru: 'Добавьте первое устройство SafeHome, чтобы начать наблюдение за этим домом.',

    es: "Añade tu primer dispositivo SafeHome para empezar a supervisar esta casa.",
    fr: _fr(
      vi: "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.",
      en: "Add your first SafeHome device to start monitoring this home.",
    ),
  );

  String statusEmergencyActionSuggestion() => choose(
    vi: "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.",
    en: "Check emergency alerts first, then contact household members if needed.",
    zh: "请先检查紧急警报，必要时联系家中成员。",
    ko: "긴급 경보를 먼저 확인하고, 필요하면 가족 구성원에게 연락하세요.",
    ja: "まず緊急アラートを確認し、必要なら家のメンバーに連絡してください。",
    de: 'Prüfe zuerst Notfallwarnungen und kontaktiere bei Bedarf die Mitglieder im Zuhause.',
    ru: 'Сначала проверьте экстренные тревоги, затем при необходимости свяжитесь с участниками дома.',

    es: "Revisa primero las alertas de emergencia y luego contacta con los miembros de la casa si es necesario.",
    fr: _fr(
      vi: "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.",
      en: "Check emergency alerts first, then contact household members if needed.",
    ),
  );

  String statusOpenHomeEmptySuggestion() => choose(
    vi: "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.",
    en: "No household member is home but a door or lock is open. Check it now.",
    zh: "家中没有成员，但门或锁处于打开状态，请立即检查。",
    ko: "집에 사람이 없는데 문이나 잠금장치가 열려 있습니다. 바로 확인하세요.",
    ja: "家に誰もいないのにドアまたは鍵が開いています。すぐ確認してください。",
    de: 'Kein Mitglied ist zuhause, aber eine Tür oder ein Schloss ist offen. Bitte sofort prüfen.',
    ru: 'Никого нет дома, но дверь или замок открыты. Проверьте немедленно.',

    es: "No hay ningún miembro en casa, pero una puerta o cerradura está abierta. Revísalo ahora.",
    fr: _fr(
      vi: "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.",
      en: "No household member is home but a door or lock is open. Check it now.",
    ),
  );

  String statusArmedOpenSuggestion() => choose(
    vi: "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.",
    en: "Check the open door or lock before keeping this home in Guard mode.",
    zh: "在保持防护模式前，请先检查打开的门或锁。",
    ko: "보호 모드를 유지하기 전에 열린 문이나 잠금장치를 먼저 확인하세요.",
    ja: "保護モードを維持する前に、開いているドアや鍵を確認してください。",
    de: 'Prüfe die offene Tür oder das offene Schloss, bevor du dieses Zuhause im Schutzmodus lässt.',
    ru: 'Проверьте открытую дверь или замок перед тем, как оставить дом в режиме охраны.',

    es: "Revisa la puerta o cerradura abierta antes de mantener esta casa en modo protección.",
    fr: _fr(
      vi: "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.",
      en: "Check the open door or lock before keeping this home in Guard mode.",
    ),
  );

  String statusMemberInsideWhileArmedSuggestion() => choose(
    vi: "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.",
    en: "Someone may still be home. If so, switch back to Normal mode.",
    zh: "可能仍有人在家；如果属实，建议切回普通模式。",
    ko: "아직 집에 사람이 있을 수 있습니다. 그렇다면 일반 모드로 전환하세요.",
    ja: "まだ家に人がいる可能性があります。その場合は通常モードに戻してください。",
    de: 'Es könnte noch jemand zuhause sein. Falls ja, wechsle zurück in den Normalmodus.',
    ru: 'Возможно, кто-то все еще дома; если это так, переключите в обычный режим.',

    es: "Puede que aún haya alguien en casa; si es así, conviene cambiar al modo normal.",
    fr: _fr(
      vi: "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.",
      en: "Someone may still be home. If so, switch back to Normal mode.",
    ),
  );

  String statusUnknownLocationSuggestion() => choose(
    vi: "Có thành viên chưa xác định vị trí, hãy nhắc họ mở ứng dụng hoặc kiểm tra quyền vị trí.",
    en: "Some members have unknown location. Ask them to open the app or check location permission.",
    zh: "有成员位置未知，请提醒他们打开应用或检查定位权限。",
    ko: "위치를 알 수 없는 구성원이 있습니다. 앱을 열거나 위치 권한을 확인하도록 알려주세요.",
    ja: "位置が不明なメンバーがいます。アプリを開くか位置情報権限を確認してもらってください。",
    de: 'Bei einigen Mitgliedern ist der Standort unbekannt. Bitte erinnere sie, die App zu öffnen oder die Standortberechtigung zu prüfen.',
    ru: 'У некоторых участников местоположение неизвестно. Попросите их открыть приложение или проверить разрешение геолокации.',

    es: "Hay miembros con ubicación desconocida; pídeles que abran la app o revisen el permiso de ubicación.",
    fr: _fr(
      vi: "Có thành viên chưa xác định vị trí, hãy nhắc họ mở ứng dụng hoặc kiểm tra quyền vị trí.",
      en: "Some members have unknown location. Ask them to open the app or check location permission.",
    ),
  );

  String statusDisconnectedDeviceSuggestion() => choose(
    vi: "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.",
    en: "A device is disconnected. Check its battery, power, or placement.",
    zh: "有设备已断开连接，请检查电池、电源或摆放位置。",
    ko: "연결이 끊긴 기기가 있습니다. 배터리, 전원 또는 설치 위치를 확인하세요.",
    ja: "接続が切れているデバイスがあります。電池・電源・設置場所を確認してください。",
    de: 'Ein Gerät ist getrennt. Prüfe Batterie, Stromversorgung oder Platzierung.',
    ru: 'Устройство отключено. Проверьте батарею, питание или место установки.',

    es: "Un dispositivo perdió la conexión. Revisa la batería, la alimentación o su ubicación.",
    fr: _fr(
      vi: "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.",
      en: "A device is disconnected. Check its battery, power, or placement.",
    ),
  );

  String statusLowBatterySuggestion() => choose(
    vi: "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.",
    en: "A device has low battery. Replace it soon to avoid missed alerts.",
    zh: "有设备电量低，建议尽快更换电池以避免漏报。",
    ko: "배터리가 부족한 기기가 있습니다. 경보 누락을 막기 위해 빨리 교체하세요.",
    ja: "電池残量が少ないデバイスがあります。アラートを逃さないよう早めに交換してください。",
    de: 'Ein Gerät hat einen niedrigen Batteriestand. Tausche die Batterie bald aus, um verpasste Alarme zu vermeiden.',
    ru: 'У устройства низкий заряд батареи. Замените батарею заранее, чтобы не пропустить тревоги.',

    es: "Hay un dispositivo con batería baja. Cámbiala pronto para evitar perder alertas.",
    fr: _fr(
      vi: "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.",
      en: "A device has low battery. Replace it soon to avoid missed alerts.",
    ),
  );

  String statusReminderMissingSuggestion() => choose(
    vi: "Bạn chưa đặt nhắc nhở, nên tạo lịch nhắc kiểm tra nhà định kỳ.",
    en: "Reminder is not set. Create a schedule to check your home regularly.",
    zh: "尚未设置提醒，建议创建定期检查家庭的提醒。",
    ko: "리마인더가 설정되어 있지 않습니다. 집을 정기적으로 확인할 일정을 만들어 보세요.",
    ja: "リマインダーが未設定です。定期的に家を確認する予定を作成してください。",
    de: 'Erinnerung ist nicht eingerichtet. Erstelle einen Zeitplan, um dein Zuhause regelmäßig zu prüfen.',
    ru: 'Напоминание не настроен. Создайте расписание для регулярной проверки дома.',

    es: "Aún no has configurado recordatorio. Crea una programación para revisar la casa periódicamente.",
    fr: _fr(
      vi: "Bạn chưa đặt nhắc nhở, nên tạo lịch nhắc kiểm tra nhà định kỳ.",
      en: "Reminder is not set. Create a schedule to check your home regularly.",
    ),
  );

  String statusAlarmMissingSuggestion() => choose(
    vi: "Bạn chưa đặt lịch báo động, nên bật bảo vệ theo khung giờ thường vắng nhà.",
    en: "Alarm schedule is not set. Enable protection for times you are usually away.",
    zh: "尚未设置警报时间，建议在经常不在家的时段启用防护。",
    ko: "알람 일정이 설정되어 있지 않습니다. 자주 집을 비우는 시간대에 보호를 켜세요.",
    ja: "アラーム予定が未設定です。普段不在の時間帯に保護を有効にしてください。",
    de: 'Der Alarm-Zeitplan ist nicht eingerichtet. Aktiviere Schutz für Zeiten, in denen normalerweise niemand zuhause ist.',
    ru: 'Расписание тревога не настроено. Включите защиту на время, когда дома обычно никого нет.',

    es: "No has configurado una programación de alarma; conviene activar la protección en los horarios en los que normalmente no hay nadie en casa.",
    fr: _fr(
      vi: "Bạn chưa đặt lịch báo động, nên bật bảo vệ theo khung giờ thường vắng nhà.",
      en: "Alarm schedule is not set. Enable protection for times you are usually away.",
    ),
  );

  String statusNoImmediateActionSuggestion() => choose(
    vi: "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.",
    en: "No immediate action is needed. Keep monitoring this home.",
    zh: "目前没有需要立即处理的事项，请继续关注家庭状态。",
    ko: "즉시 처리할 일은 없습니다. 집 상태를 계속 확인하세요.",
    ja: "すぐ対応が必要な項目はありません。家の状態を引き続き確認してください。",
    de: 'Es ist nichts sofort zu erledigen. Überwache den Zustand des Zuhauses weiter.',
    ru: 'Срочных действий не требуется. Продолжайте наблюдать за состоянием дома.',

    es: "No se necesita ninguna acción inmediata. Sigue supervisando esta casa.",
    fr: _fr(
      vi: "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.",
      en: "No immediate action is needed. Keep monitoring this home.",
    ),
  );

  String alarmRepeatAfterText(int minutes) {
    if (minutes <= 0) {
      return t("Không lặp lại");
    }

    return choose(
      vi: "Lặp sau $minutes phút",
      fil: "Ulitin pagkalipas ng $minutes minuto",
      km: "កើតឡើងវិញបន្ទាប់ពី $minutes នាទី",
      en: "Repeat after $minutes minutes",
      zh: "$minutes 分钟后重复",
      ko: "$minutes분 후 반복",
      ja: "$minutes 分後に繰り返し",
      de: 'Wiederholung nach $minutes Minuten',
      ru: 'Повтор через $minutes минут',

      es: "Repetir después de $minutes minutos",
      fr: _fr(vi: "Lặp sau $minutes phút", en: "Repeat after $minutes minutes"),
      id: "Ulangi setelah $minutes menit",
      th: "แจ้งเตือนซ้ำหลัง $minutes นาที",
      ms: "Ulang selepas $minutes minit",
      my: "$minutes မိနစ်အကြာတွင် ထပ်မံသတိပေးရန်",
      lo: "ເຮັດຊ້ຳຫຼັງ $minutes ນາທີ",
    );
  }

  String securityModeActiveText(String repeatText) => choose(
    vi: "Đang dùng • $repeatText",
    fil: "Aktibo • $repeatText",
    km: "កំពុងដំណើរការ • $repeatText",
    en: "Active • $repeatText",
    zh: "使用中 • $repeatText",
    ko: "사용 중 • $repeatText",
    ja: "有効 • $repeatText",
    de: 'Aktiv • $repeatText',
    ru: 'Активно • $repeatText',

    es: "Activo • $repeatText",
    fr: _fr(vi: "Đang dùng • $repeatText", en: "Active • $repeatText"),
    id: "Aktif • $repeatText",
    th: "ใช้งานอยู่ • $repeatText",
    ms: "Sedang menggunakan • $repeatText",
    my: "အသုံးပြုနေသည် • $repeatText",
    lo: "ກຳລັງໃຊ້ • $repeatText",
  );

  String securityModeMonitoringText(String repeatText) => choose(
    vi: "Giám sát an ninh • $repeatText",
    fil: "Pagsubaybay sa seguridad • $repeatText",
    km: "ការតាមដានសន្តិសុខ • $repeatText",
    en: "Security monitoring • $repeatText",
    zh: "安全监测 • $repeatText",
    ko: "보안 모니터링 • $repeatText",
    ja: "セキュリティ監視 • $repeatText",
    de: 'Sicherheitsüberwachung • $repeatText',
    ru: 'Мониторинг безопасности • $repeatText',

    es: "Supervisión de seguridad • $repeatText",
    fr: _fr(
      vi: "Giám sát an ninh • $repeatText",
      en: "Security monitoring • $repeatText",
    ),
    id: "Pemantauan keamanan • $repeatText",
    th: "การตรวจสอบความปลอดภัย • $repeatText",
    ms: "Pemantauan keselamatan • $repeatText",
    my: "လုံခြုံရေးစောင့်ကြည့်မှု • $repeatText",
    lo: "ຕິດຕາມຄວາມປອດໄພ • $repeatText",
  );

  String familyModeText(String mode) => choose(
    vi: "Gia đình: $mode",
    fil: "Mode ng bahay: $mode",
    km: "មុខងារផ្ទះ៖ $mode",
    en: "Home mode: $mode",
    zh: "家庭模式：$mode",
    ko: "집 모드: $mode",
    ja: "家のモード: $mode",
    de: 'Zuhause-Modus: $mode',
    ru: 'Режим дома: $mode',

    es: "Modo de casa: $mode",
    fr: "Mode maison : $mode",
    id: "Mode rumah: $mode",
    th: "โหมดบ้าน: $mode",
    ms: "Mod rumah: $mode",
    my: "အိမ်မုဒ် - $mode",
    lo: "ໂໝດເຮືອນ: $mode",
  );

  String actionSuggestionTitle() => choose(
    vi: "Gợi ý xử lý",
    en: "Suggested actions",
    zh: "处理建议",
    ko: "처리 제안",
    ja: "対応の提案",
    de: 'Vorgeschlagene Aktionen',
    ru: 'Рекомендуемые действия',

    es: "Acciones sugeridas",
    fr: _fr(vi: "Gợi ý xử lý", en: "Suggested actions"),
  );

  String detectedIssuesCountText(int count) => choose(
    vi: "Phát hiện $count vấn đề cần xử lý",
    fil: "May natukoy na $count problemang kailangang aksyunan",
    km: "មានបញ្ហា $count ដែលត្រូវការការយកចិត្តទុកដាក់",
    en: "$count issues need attention",
    zh: "发现 $count 个问题需要处理",
    ko: "$count개 문제를 처리해야 합니다",
    ja: "$count 件の問題に対応が必要です",
    de: '$count Probleme erfordern Aufmerksamkeit',
    ru: 'Обнаружено $count проблем, требующих внимания',

    es: "$count problemas requieren atención",
    fr: _fr(
      vi: "Phát hiện $count vấn đề cần xử lý",
      en: "$count issues need attention",
    ),
    id: "$count masalah perlu ditangani",
    th: "พบปัญหาที่ต้องแก้ไข $count รายการ",
    ms: "Dikesan $count masalah yang perlu ditangani",
    my: "ဖြေရှင်းရန်လိုသောပြဿနာ $count ခု တွေ့ရှိသည်",
    lo: "ພົບ $count ບັນຫາທີ່ຕ້ອງຈັດການ",
  );

  String doorsUsedTodayText(int count) => choose(
    vi: "Hôm nay các cửa đã được sử dụng $count lần",
    fil: "Ginamit ang mga pinto nang $count beses ngayong araw",
    km: "ទ្វារត្រូវបានប្រើ $count ដងនៅថ្ងៃនេះ",
    en: "Doors were used $count times today",
    zh: "今天门被使用了 $count 次",
    ko: "오늘 문이 $count번 사용되었습니다",
    ja: "今日はドアが $count 回使用されました",
    de: 'Türen wurden heute $count Mal genutzt',
    ru: 'Сегодня двери использовались $count раз',

    es: "Las puertas se usaron $count veces hoy",
    fr: _fr(
      vi: "Hôm nay các cửa đã được sử dụng $count lần",
      en: "Doors were used $count times today",
    ),
    id: "Pintu digunakan $count kali hari ini",
    th: "วันนี้มีการใช้งานประตู $count ครั้ง",
    ms: "Hari ini pintu telah digunakan $count kali",
    my: "ယနေ့ တံခါးများကို $count ကြိမ် အသုံးပြုခဲ့သည်",
    lo: "ມື້ນີ້ປະຕູຖືກໃຊ້ $count ຄັ້ງ",
  );

  String recentActivitiesCountText(int count) => choose(
    vi: "Đã ghi nhận $count hoạt động gần đây",
    fil: "Naitala ang $count kamakailang aktibidad",
    km: "បានកត់ត្រាសកម្មភាពថ្មីៗចំនួន $count",
    en: "$count recent activities recorded",
    zh: "已记录 $count 条近期活动",
    ko: "최근 활동 $count개가 기록되었습니다",
    ja: "最近のアクティビティが $count 件記録されました",
    de: '$count aktuelle Aktivitäten aufgezeichnet',
    ru: 'Записано $count недавних действий',

    es: "$count actividades recientes registradas",
    fr: _fr(
      vi: "Đã ghi nhận $count hoạt động gần đây",
      en: "$count recent activities recorded",
    ),
    id: "$count aktivitas terbaru tercatat",
    th: "บันทึกกิจกรรมล่าสุด $count รายการแล้ว",
    ms: "$count aktiviti terkini telah direkodkan",
    my: "လတ်တလောလှုပ်ရှားမှု $count ခု မှတ်တမ်းတင်ထားသည်",
    lo: "ບັນທຶກ $count ກິດຈະກຳຫຼ້າສຸດ",
  );

  String systemNeedCheckText(int issueCount) => choose(
    vi: "Hệ thống: Cần kiểm tra $issueCount mục",
    fil: "System: May $issueCount item na kailangang suriin",
    km: "ប្រព័ន្ធ៖ មាន $issueCount ចំណុចត្រូវពិនិត្យ",
    en: "System: $issueCount items need checking",
    zh: "系统：需要检查 $issueCount 项",
    ko: "시스템: $issueCount개 항목 확인 필요",
    ja: "システム: $issueCount 項目の確認が必要",
    de: 'System: $issueCount Punkte prüfen',
    ru: 'Система: нужно проверить $issueCount пунктов',

    es: "Sistema: $issueCount elementos requieren revisión",
    fr: _fr(
      vi: "Hệ thống: Cần kiểm tra $issueCount mục",
      en: "System: $issueCount items need checking",
    ),
    id: "Sistem: $issueCount item perlu diperiksa",
    th: "ระบบ: ต้องตรวจสอบ $issueCount รายการ",
    ms: "Sistem: $issueCount perkara perlu diperiksa",
    my: "စနစ် - အချက် $issueCount ခု စစ်ဆေးရန်လိုသည်",
    lo: "ລະບົບ: ຕ້ອງກວດ $issueCount ລາຍການ",
  );

  String fcmTokenReadyText({
    required bool monitoringEligible,
    required bool autoAwayEnabled,
  }) {
    final ready = monitoringEligible || !autoAwayEnabled;

    return ready
        ? choose(
            vi: "FCM token đã sẵn sàng trên điện thoại này.",
            en: "The FCM token is ready on this phone.",
            zh: "此手机上的 FCM token 已准备好。",
            ko: "이 휴대폰의 FCM 토큰이 준비되었습니다.",
            ja: "この端末の FCM トークンは準備済みです。",
            de: 'FCM-Token ist auf diesem Telefon bereit.',
            ru: 'FCM-токен готов на этом телефоне.',

            es: "El token FCM está listo en este teléfono.",
            fr: _fr(
              vi: "FCM token đã sẵn sàng trên điện thoại này.",
              en: "The FCM token is ready on this phone.",
            ),
          )
        : choose(
            vi: "FCM token đã sẵn sàng, nhưng tính năng tự động khi rời nhà còn thiếu điều kiện.",
            my: "FCM token အသင့်ဖြစ်သော်လည်း အိမ်မှထွက်ချိန် အလိုအလျောက်ကာကွယ်မှုအတွက် လိုအပ်ချက်တစ်ခု ကျန်နေသည်။",
            fil:
                "Handa na ang FCM token, ngunit may kulang pang kinakailangan para sa Awtomatikong Proteksyon kapag wala sa bahay.",
            km: "FCM token រួចរាល់ ប៉ុន្តែការការពារដោយស្វ័យប្រវត្តិនៅពេលចាកចេញនៅខ្វះលក្ខខណ្ឌមួយ។",
            en: "The FCM token is ready, but Auto Away is missing a requirement.",
            zh: "FCM token 已准备好，但自动离家仍缺少条件。",
            ko: "FCM 토큰은 준비되었지만 자동 외출에 필요한 조건이 부족합니다.",
            ja: "FCM トークンは準備済みですが、自動外出に必要な条件が不足しています。",
            de: 'FCM-Token ist bereit, aber für den automatischen Schutz beim Verlassen fehlt noch eine Voraussetzung.',
            ru: 'FCM-токен готов, но для автоматической охраны при уходе не хватает условия.',

            es: "El token FCM está listo, pero la protección automática al salir aún necesita cumplir alguna condición.",
            fr: _fr(
              vi: "FCM token đã sẵn sàng, nhưng tính năng tự động khi rời nhà còn thiếu điều kiện.",
              en: "The FCM token is ready, but Auto Away is missing a requirement.",
            ),
            lo: "FCM token ພ້ອມແລ້ວ ແຕ່ການປ້ອງກັນອັດຕະໂນມັດເມື່ອອອກຈາກເຮືອນຍັງຂາດເງື່ອນໄຂໜຶ່ງ.",
          );
  }

  String emergencyDeviceRecommendationText(int emergencyTotal) => choose(
    vi: "Hiện có $emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.",
    fil:
        "May $emergencyTotal aparatong pang-emergency. Inirerekomendang minimum: sensor ng usok at SOS.",
    km: "រកឃើញឧបករណ៍បន្ទាន់ចំនួន $emergencyTotal។ ចំនួនអប្បបរមាដែលបានណែនាំ៖ ឧបករណ៍ចាប់ផ្សែង និង SOS។",
    en: "$emergencyTotal emergency devices found. Recommended minimum: smoke sensor and SOS.",
    zh: "已有 $emergencyTotal 个紧急设备。建议至少配置：烟雾传感器和 SOS。",
    ko: "긴급 기기 $emergencyTotal개가 있습니다. 권장 최소 구성: 연기 감지기와 SOS.",
    ja: "$emergencyTotal 個の緊急デバイスがあります。推奨最小構成: 煙センサーと SOS。",
    de: '$emergencyTotal Notfallgeräte gefunden. Mindestempfehlung: Rauchmelder und SOS.',
    ru: 'Найдено экстренных устройств: $emergencyTotal. Рекомендуемый минимум: датчик дыма и SOS.',

    es: "Se encontraron $emergencyTotal dispositivos de emergencia. Mínimo recomendado: sensor de humo y SOS.",
    fr: _fr(
      vi: "Hiện có $emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.",
      en: "$emergencyTotal emergency devices found. Recommended minimum: smoke sensor and SOS.",
    ),
    id: "Ditemukan $emergencyTotal perangkat darurat. Rekomendasi minimum: sensor asap dan SOS.",
    th: "ขณะนี้มีอุปกรณ์ฉุกเฉิน $emergencyTotal เครื่อง คำแนะนำขั้นต่ำ: เครื่องตรวจจับควันและ SOS",
    ms: "$emergencyTotal peranti kecemasan tersedia. Cadangan minimum: pengesan asap dan SOS.",
    my: "အရေးပေါ်စက်ပစ္စည်း $emergencyTotal ခု ရှိသည်။ အနည်းဆုံး မီးခိုးအာရုံခံကိရိယာနှင့် SOS ထားရန် အကြံပြုသည်။",
    lo: "ພົບ $emergencyTotal ອຸປະກອນສຸກເສີນ. ແນະນຳຢ່າງນ້ອຍ: ເຊັນເຊີຄວັນ ແລະ SOS",
  );

  String confirmTransferOwnerText(String targetEmail) => choose(
    vi: "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n$targetEmail?",
    fil: "Ilipat ang pagmamay-ari ng bahay kay:\n$targetEmail?",
    km: "ផ្ទេរសិទ្ធិម្ចាស់ផ្ទះទៅ៖\n$targetEmail?",
    en: "Transfer home ownership to:\n$targetEmail?",
    zh: "确定要将家庭所有权转移给：\n$targetEmail？",
    ko: "집 소유권을 다음 사람에게 이전하시겠습니까?\n$targetEmail",
    ja: "家の所有権を次の相手に移転しますか？\n$targetEmail",
    de: 'Besitz des Zuhauses übertragen an:\n$targetEmail?',
    ru: 'Передать права владельца дома:\n$targetEmail?',

    es: "¿Seguro que quieres transferir la propiedad de la casa a:\n$targetEmail?",
    fr: _fr(
      vi: "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n$targetEmail?",
      en: "Transfer home ownership to:\n$targetEmail?",
    ),
    id: "Alihkan kepemilikan rumah ke:\\n$targetEmail?",
    th: "คุณแน่ใจหรือไม่ว่าต้องการโอนสิทธิ์เจ้าของบ้านให้บุคคลต่อไปนี้:\n$targetEmail?",
    ms: "Adakah anda pasti mahu memindahkan hak pemilik rumah kepada:\n$targetEmail?",
    my: "အိမ်ပိုင်ဆိုင်မှုကို အောက်ပါသူထံ လွှဲပြောင်းမလား?\n$targetEmail",
    lo: "ໂອນຄວາມເປັນເຈົ້າຂອງເຮືອນໃຫ້:\n$targetEmail ບໍ?",
  );

  Map<String, String>? get _activeTranslations => isMalay
      ? _malay
      : isFilipino
      ? _filipino
      : isKhmer
      ? _khmer
      : isBurmese
      ? _burmese
      : isLao
      ? _lao
      : isThai
      ? _thai
      : isIndonesian
      ? _indonesian
      : isSpanish
      ? _spanish
      : isFrench
      ? _french
      : isRussian
      ? _russian
      : isGerman
      ? _german
      : isKorean
      ? _korean
      : isJapanese
      ? _japanese
      : isChinese
      ? _chinese
      : isEnglish
      ? _english
      : null;

  String statusText(String text) {
    if (text.trim().isEmpty) {
      return text;
    }

    final translations = _activeTranslations;

    final exact = translations?[_translationAliases[text] ?? text];
    if (exact != null) {
      return exact;
    }

    final closedMatch = RegExp(
      r"^(\d+)/(\d+) cửa đã đóng an toàn$",
    ).firstMatch(text);
    if (closedMatch != null) {
      final count = "${closedMatch.group(1)}/${closedMatch.group(2)}";
      return choose(
        vi: "$count cửa đã đóng an toàn",
        fil: "$count pintong ligtas na nakasara",
        km: "ទ្វារចំនួន $count បានបិទដោយសុវត្ថិភាព",
        en: "$count doors safely closed",
        zh: "$count 扇门已安全关闭",
        ko: "$count개의 문이 안전하게 닫힘",
        ja: "$count 個のドアが安全に閉じています",
        de: '$count Türen sicher geschlossen',
        ru: '$count дверей надежно закрыто',

        es: "$count puertas cerradas de forma segura",
        fr: _fr(
          vi: "$count cửa đã đóng an toàn",
          en: "$count doors safely closed",
        ),
        id: "$count pintu tertutup aman",
        th: "ประตู $count บานปิดอย่างปลอดภัยแล้ว",
        ms: "$count pintu telah ditutup dengan selamat",
        my: "တံခါး $count ချပ် လုံခြုံစွာပိတ်ထားသည်",
        lo: "$count ປະຕູປິດຢ່າງປອດໄພ",
      );
    }

    final securedAccessMatch = RegExp(
      r"^(\d+)/(\d+) cửa và khóa đã an toàn$",
    ).firstMatch(text);
    if (securedAccessMatch != null) {
      final count =
          "${securedAccessMatch.group(1)}/${securedAccessMatch.group(2)}";
      return choose(
        vi: "$count cửa và khóa đã an toàn",
        fil: "Ligtas na ang $count pinto at lock",
        km: "ទ្វារ និងសោចំនួន $count មានសុវត្ថិភាព",
        en: "$count doors and locks secured",
        zh: "$count 扇门和门锁已安全",
        ko: "$count개의 문과 잠금장치가 안전함",
        ja: "$count 個のドアとロックが安全です",
        de: '$count Türen und Schlösser gesichert',
        ru: '$count дверей и замков защищены',

        es: "$count puertas y cerraduras seguras",
        fr: _fr(
          vi: "$count cửa và khóa đã an toàn",
          en: "$count doors and locks secured",
        ),
        id: "$count pintu dan kunci aman",
        th: "ประตูและล็อก $count รายการปลอดภัยแล้ว",
        ms: "$count pintu dan kunci selamat",
        my: "တံခါးနှင့်သော့ $count ခု လုံခြုံသည်",
        lo: "$count ປະຕູ ແລະ ກະແຈປອດໄພ",
      );
    }

    final deviceMatch = RegExp(
      r"^(\d+) thiết bị đang được theo dõi$",
    ).firstMatch(text);
    if (deviceMatch != null) {
      final count = deviceMatch.group(1)!;
      return choose(
        vi: "$count thiết bị đang được theo dõi",
        fil: "$count aparato ang sinusubaybayan",
        km: "កំពុងតាមដានឧបករណ៍ចំនួន $count",
        en: "$count devices monitored",
        zh: "正在监测 $count 台设备",
        ko: "기기 $count대 모니터링 중",
        ja: "$count 台のデバイスを監視中",
        de: '$count Geräte werden überwacht',
        ru: '$count устройств под наблюдением',

        es: "$count dispositivos supervisados",
        fr: _fr(
          vi: "$count thiết bị đang được theo dõi",
          en: "$count devices monitored",
        ),
        id: "$count perangkat dipantau",
        th: "กำลังตรวจสอบอุปกรณ์ $count เครื่อง",
        ms: "$count peranti sedang dipantau",
        my: "စက်ပစ္စည်း $count ခုကို စောင့်ကြည့်နေသည်",
        lo: "ກຳລັງຕິດຕາມ $count ອຸປະກອນ",
      );
    }

    final doorsUsedTodayMatch = RegExp(
      r"^Hôm nay các cửa đã được sử dụng (\d+) lần$",
    ).firstMatch(text);
    if (doorsUsedTodayMatch != null) {
      final count = doorsUsedTodayMatch.group(1)!;
      return choose(
        vi: "Hôm nay các cửa đã được sử dụng $count lần",
        fil: "Ginamit ang mga pinto nang $count beses ngayong araw",
        km: "ទ្វារត្រូវបានប្រើ $count ដងនៅថ្ងៃនេះ",
        en: "Doors were used $count times today",
        zh: "今天门被使用了 $count 次",
        ko: "오늘 문이 $count번 사용되었습니다",
        ja: "今日はドアが $count 回使用されました",
        de: 'Türen wurden heute $count Mal genutzt',
        ru: 'Сегодня двери использовались $count раз',

        es: "Las puertas se usaron $count veces hoy",
        fr: _fr(
          vi: "Hôm nay các cửa đã được sử dụng $count lần",
          en: "Doors were used $count times today",
        ),
        id: "Pintu digunakan $count kali hari ini",
        th: "วันนี้มีการใช้งานประตู $count ครั้ง",
        ms: "Hari ini pintu telah digunakan $count kali",
        my: "ယနေ့ တံခါးများကို $count ကြိမ် အသုံးပြုခဲ့သည်",
        lo: "ມື້ນີ້ປະຕູຖືກໃຊ້ $count ຄັ້ງ",
      );
    }

    final updatedMatch = RegExp(r"^Cập nhật (.+)$").firstMatch(text);
    if (updatedMatch != null) {
      final timeText = _translateAgoFragment(updatedMatch.group(1)!);
      return choose(
        vi: "Cập nhật $timeText",
        fil: "Na-update $timeText",
        km: "បានធ្វើបច្ចុប្បន្នភាព $timeText",
        en: "Updated $timeText",
        zh: "$timeText更新",
        ko: "$timeText에 업데이트됨",
        ja: "$timeTextに更新",
        de: 'Aktualisiert $timeText',
        ru: 'Обновлено $timeText',

        es: "Actualizado $timeText",
        fr: _fr(vi: "Cập nhật $timeText", en: "Updated $timeText"),
        id: "Diperbarui $timeText",
        th: "อัปเดต $timeText",
        ms: "Dikemas kini $timeText",
        my: "$timeText တွင် မွမ်းမံထားသည်",
        lo: "ອັບເດດ $timeText",
      );
    }

    final minuteMatch = RegExp(
      r"^Dữ liệu gần nhất cập nhật (\d+) phút trước$",
    ).firstMatch(text);
    if (minuteMatch != null) {
      final count = minuteMatch.group(1)!;
      return choose(
        vi: "Dữ liệu gần nhất cập nhật $count phút trước",
        fil: "Huling na-update ang datos $count minuto ang nakalipas",
        km: "ទិន្នន័យចុងក្រោយបានធ្វើបច្ចុប្បន្នភាព $count នាទីមុន",
        en: "Latest data updated $count minutes ago",
        zh: "最近数据更新于 $count 分钟前",
        ko: "최신 데이터가 $count분 전에 업데이트됨",
        ja: "最新データは $count 分前に更新されました",
        de: 'Neueste Daten vor $count Minuten aktualisiert',
        ru: 'Последние данные обновлены $count минут назад',

        es: "Los datos más recientes se actualizaron hace $count minutos",
        fr: _fr(
          vi: "Dữ liệu gần nhất cập nhật $count phút trước",
          en: "Latest data updated $count minutes ago",
        ),
        id: "Data terbaru diperbarui $count menit lalu",
        th: "อัปเดตข้อมูลล่าสุดเมื่อ $count นาทีที่แล้ว",
        ms: "Data terkini dikemas kini $count minit lalu",
        my: "နောက်ဆုံးအချက်အလက်ကို $count မိနစ်အကြာက မွမ်းမံထားသည်",
        lo: "ຂໍ້ມູນຫຼ້າສຸດອັບເດດ $count ນາທີກ່ອນ",
      );
    }

    final hourMatch = RegExp(
      r"^Dữ liệu gần nhất cập nhật (\d+) giờ trước$",
    ).firstMatch(text);
    if (hourMatch != null) {
      final count = hourMatch.group(1)!;
      return choose(
        vi: "Dữ liệu gần nhất cập nhật $count giờ trước",
        fil: "Huling na-update ang datos $count oras ang nakalipas",
        km: "ទិន្នន័យចុងក្រោយបានធ្វើបច្ចុប្បន្នភាព $count ម៉ោងមុន",
        en: "Latest data updated $count hours ago",
        zh: "最近数据更新于 $count 小时前",
        ko: "최신 데이터가 $count시간 전에 업데이트됨",
        ja: "最新データは $count 時間前に更新されました",
        de: 'Neueste Daten vor $count Stunden aktualisiert',
        ru: 'Последние данные обновлены $count часов назад',

        es: "Los datos más recientes se actualizaron hace $count horas",
        fr: _fr(
          vi: "Dữ liệu gần nhất cập nhật $count giờ trước",
          en: "Latest data updated $count hours ago",
        ),
        id: "Data terbaru diperbarui $count jam lalu",
        th: "อัปเดตข้อมูลล่าสุดเมื่อ $count ชั่วโมงที่แล้ว",
        ms: "Data terkini dikemas kini $count jam lalu",
        my: "နောက်ဆုံးအချက်အလက်ကို $count နာရီအကြာက မွမ်းမံထားသည်",
        lo: "ຂໍ້ມູນຫຼ້າສຸດອັບເດດ $count ຊົ່ວໂມງກ່ອນ",
      );
    }

    final membersAtHomeMatch = RegExp(
      r"^(?:Thành viên đang ở trong nhà|Thành viên trong nhà): (\d+)/(\d+)$",
    ).firstMatch(text);

    if (membersAtHomeMatch != null) {
      final count =
          "${membersAtHomeMatch.group(1)}/${membersAtHomeMatch.group(2)}";

      return '${t("Thành viên đang ở trong nhà")}: $count';
    }

    final membersAwayMatch = RegExp(
      r"^(?:Thành viên đang ở ngoài|Thành viên bên ngoài): (\d+)/(\d+)$",
    ).firstMatch(text);

    if (membersAwayMatch != null) {
      final count = "${membersAwayMatch.group(1)}/${membersAwayMatch.group(2)}";

      return '${t("Thành viên đang ở ngoài")}: $count';
    }

    final unknownLocationMatch = RegExp(
      r"^(?:Thành viên chưa xác định vị trí|Chưa xác định vị trí): (\d+)/(\d+)$",
    ).firstMatch(text);

    if (unknownLocationMatch != null) {
      final count =
          "${unknownLocationMatch.group(1)}/${unknownLocationMatch.group(2)}";

      return '${t("Thành viên chưa xác định vị trí")}: $count';
    }

    if (text.startsWith("Môi trường hiện tại: ")) {
      final environment = text
          .replaceFirst("Môi trường hiện tại: ", "")
          .split(RegExp(r"\s*/\s*"))
          .map(_translateStatusFragment)
          .join(" / ");
      return choose(
        vi: "Môi trường hiện tại: $environment",
        fil: "Kasalukuyang kapaligiran: $environment",
        km: "បរិស្ថានបច្ចុប្បន្ន៖ $environment",
        en: "Current environment: $environment",
        zh: "当前环境：$environment",
        ko: "현재 환경: $environment",
        ja: "現在の環境: $environment",
        de: 'Aktuelle Umgebung: $environment',
        ru: 'Текущая среда: $environment',

        es: "Entorno actual: $environment",
        fr: _fr(
          vi: "Môi trường hiện tại: $environment",
          en: "Current environment: $environment",
        ),
        id: "Lingkungan saat ini: $environment",
        th: "สภาพแวดล้อมปัจจุบัน: $environment",
        ms: "Persekitaran semasa: $environment",
        my: "လက်ရှိပတ်ဝန်းကျင် - $environment",
        lo: "ສິ່ງແວດລ້ອມປັດຈຸບັນ: $environment",
      );
    }

    if (!isMalay &&
        !isFilipino &&
        !isKhmer &&
        !isBurmese &&
        !isLao &&
        !isThai &&
        !isIndonesian &&
        !isSpanish &&
        !isFrench &&
        !isEnglish &&
        !isChinese &&
        !isKorean &&
        !isJapanese &&
        !isGerman &&
        !isRussian) {
      return text;
    }

    final issueSeparator = text.indexOf(":");
    if (issueSeparator > 0) {
      final name = text.substring(0, issueSeparator).trim();
      final details = text.substring(issueSeparator + 1).trim();
      const openWhileGuardDetails = {
        "Đang mở khi nhà ở chế độ Bảo vệ",
        "Open while Home is in Guard mode",
        "家庭处于布防模式时仍打开",
        "집이 보호 모드일 때 열려 있음",
        "家が警戒モードのときに開いています",
      };

      if (openWhileGuardDetails.contains(details)) {
        return choose(
          vi: "$name: Đang mở khi nhà ở chế độ Bảo vệ",
          fil: "$name: Bukas habang nasa Mode ng Proteksyon ang bahay",
          km: "$name៖ បើកខណៈពេលផ្ទះស្ថិតក្នុងមុខងារការពារ",
          en: "$name: Open while Home is in Guard mode",
          zh: "$name：家庭处于布防模式时仍打开",
          ko: "$name: 집이 보호 모드일 때 열려 있음",
          ja: "$name: 家が警戒モードのときに開いています",
          de: '$name: Offen, während Zuhause im Schutzmodus ist',
          ru: '$name: открыт, когда дом в режиме охраны',

          es: "$name: abierto mientras la casa está en modo protección",
          fr: _fr(
            vi: "$name: Đang mở khi nhà ở chế độ Bảo vệ",
            en: "$name: Open while Home is in Guard mode",
          ),
          id: "$name: Terbuka saat rumah dalam mode Perlindungan",
          th: "$name: เปิดอยู่เมื่อบ้านอยู่ในโหมดป้องกัน",
          ms: "$name: Terbuka ketika rumah dalam Mod Perlindungan",
          my: "$name - အိမ်က ကာကွယ်ရေးမုဒ်တွင်ရှိချိန် ဖွင့်ထားသည်",
          lo: "$name: ເປີດຢູ່ຂະນະທີ່ເຮືອນຢູ່ໃນໂໝດປ້ອງກັນ",
        );
      }

      final translatedDetails = details
          .splitMapJoin(
            RegExp(r"\s*(,|&|/)\s*"),
            onMatch: (match) {
              final separator = match.group(1)!;
              return separator == "," ? ", " : " $separator ";
            },
            onNonMatch: (fragment) => _translateStatusFragment(fragment),
          )
          .trim();
      return "$name: $translatedDetails";
    }

    return _translateStatusFragment(text);
  }

  String _translateAgoFragment(String text) {
    final clean = text.trim();

    if (clean == "Vừa xong") {
      return t("Vừa xong");
    }

    final minuteMatch = RegExp(r"^(\d+) phút trước$").firstMatch(clean);
    if (minuteMatch != null) {
      final count = minuteMatch.group(1)!;
      return choose(
        vi: "$count phút trước",
        fil: "$count minuto ang nakalipas",
        km: "$count នាទីមុន",
        en: "$count minutes ago",
        zh: "$count 分钟前",
        ko: "$count분 전",
        ja: "$count 分前",
        de: 'vor $count Minuten',
        ru: '$count минут назад',

        es: "hace $count minutos",
        fr: _fr(vi: "$count phút trước", en: "$count minutes ago"),
        id: "$count menit lalu",
        th: "$count นาทีที่แล้ว",
        ms: "$count minit yang lalu",
        my: "$count မိနစ်အကြာက",
        lo: "$count ນາທີກ່ອນ",
      );
    }

    final hourMinuteMatch = RegExp(r"^(\d+)h(\d+)' trước$").firstMatch(clean);
    if (hourMinuteMatch != null) {
      final hours = hourMinuteMatch.group(1)!;
      final minutes = hourMinuteMatch.group(2)!;
      return choose(
        vi: "${hours}h$minutes' trước",
        fil: "${hours} oras at ${minutes} minuto ang nakalipas",
        km: "${hours} ម៉ោង ${minutes} នាទីមុន",
        en: "${hours}h ${minutes}m ago",
        zh: "$hours 小时 $minutes 分钟前",
        ko: "$hours시간 $minutes분 전",
        ja: "$hours 時間 $minutes 分前",
        de: 'vor ${hours}h ${minutes}m',
        ru: '$hoursч $minutesм назад',

        es: "hace ${hours}h ${minutes}m",
        fr: _fr(
          vi: "${hours}h$minutes' trước",
          en: "${hours}h ${minutes}m ago",
        ),
        id: "${hours}j ${minutes}m lalu",
        th: "${hours} ชม. $minutes นาทีที่แล้ว",
        ms: "${hours} jam $minutes minit lalu",
        my: "${hours} နာရီ ${minutes} မိနစ်အကြာက",
        lo: "${hours} ຊົ່ວໂມງ $minutes ນາທີກ່ອນ",
      );
    }

    final hourMatch = RegExp(r"^(\d+)h trước$").firstMatch(clean);
    if (hourMatch != null) {
      final count = hourMatch.group(1)!;
      return choose(
        vi: "${count}h trước",
        fil: "${count} oras ang nakalipas",
        km: "${count} ម៉ោងមុន",
        en: "${count}h ago",
        zh: "$count 小时前",
        ko: "$count시간 전",
        ja: "$count 時間前",
        de: 'vor ${count}h',
        ru: '$countч назад',

        es: "hace ${count}h",
        fr: _fr(vi: "${count}h trước", en: "${count}h ago"),
        id: "${count}j lalu",
        th: "${count} ชั่วโมงที่แล้ว",
        ms: "${count} jam lalu",
        my: "${count} နာရီအကြာက",
        lo: "${count} ຊົ່ວໂມງກ່ອນ",
      );
    }

    final dayMatch = RegExp(r"^(\d+) ngày trước$").firstMatch(clean);
    if (dayMatch != null) {
      final count = dayMatch.group(1)!;
      return choose(
        vi: "$count ngày trước",
        fil: "$count araw ang nakalipas",
        km: "$count ថ្ងៃមុន",
        en: "$count days ago",
        zh: "$count 天前",
        ko: "$count일 전",
        ja: "$count 日前",
        de: 'vor $count Tagen',
        ru: '$count дней назад',

        es: "hace $count días",
        fr: _fr(vi: "$count ngày trước", en: "$count days ago"),
        id: "$count hari lalu",
        th: "$count วันที่แล้ว",
        ms: "$count hari yang lalu",
        my: "$count ရက်အကြာက",
        lo: "$count ມື້ກ່ອນ",
      );
    }

    final monthMatch = RegExp(r"^(\d+) tháng trước$").firstMatch(clean);
    if (monthMatch != null) {
      final count = monthMatch.group(1)!;
      return choose(
        vi: "$count tháng trước",
        fil: "$count buwan ang nakalipas",
        km: "$count ខែមុន",
        en: "$count months ago",
        zh: "$count 个月前",
        ko: "$count개월 전",
        ja: "$count か月前",
        de: 'vor $count Monaten',
        ru: '$count месяцев назад',

        es: "hace $count meses",
        fr: _fr(vi: "$count tháng trước", en: "$count months ago"),
        id: "$count bulan lalu",
        th: "$count เดือนที่แล้ว",
        ms: "$count bulan lalu",
        my: "$count လအကြာက",
        lo: "$count ເດືອນກ່ອນ",
      );
    }

    return _translateStatusFragment(clean);
  }

  String _capitalizeStatusFragment(String text) {
    if (text.isEmpty) {
      return text;
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  String? _translateLowercaseStatusFragment(String lowerText) {
    switch (lowerText) {
      case "đang mở":
        return choose(
          vi: "Đang mở",
          en: "Open",
          zh: "已打开",
          ko: "열림",
          ja: "開いています",
          de: "Offen",
          ru: "Открыто",
          es: "Abierto",
          fr: _fr(vi: "Đang mở", en: "Open"),
        );
      case "đang đóng":
        return choose(
          vi: "Đang đóng",
          en: "Closed",
          zh: "已关闭",
          ko: "닫힘",
          ja: "閉じています",
          de: "Geschlossen",
          ru: "Закрыто",
          es: "Cerrado",
          fr: _fr(vi: "Đang đóng", en: "Closed"),
        );
      case "pin yếu":
        return choose(
          vi: "Pin yếu",
          en: "Low battery",
          zh: "电量低",
          ko: "배터리 부족",
          ja: "バッテリー低下",
          de: "Niedriger Batteriestand",
          ru: "Низкий заряд батареи",
          es: "batería baja",
          fr: _fr(vi: "Pin yếu", en: "Low battery"),
        );
      case "mất kết nối":
        return choose(
          vi: "Mất kết nối",
          en: "Disconnected",
          zh: "连接中断",
          ko: "연결 끊김",
          ja: "接続が切断されました",
          de: "Getrennt",
          ru: "Отключено",
          es: "Desconectado",
          fr: _fr(vi: "Mất kết nối", en: "Disconnected"),
        );
      case "bị tháo":
        return choose(
          vi: "Bị tháo",
          en: "Tamper detected",
          zh: "检测到拆卸",
          ko: "분리 감지",
          ja: "取り外し検知",
          de: "Manipulation erkannt",
          ru: "Обнаружено снятие",
          es: "Manipulación detectada",
          fr: _fr(vi: "Bị tháo", en: "Tamper detected"),
        );
      case "phát hiện khói":
        return choose(
          vi: "Phát hiện khói",
          en: "Smoke detected",
          zh: "检测到烟雾",
          ko: "연기 감지",
          ja: "煙を検知",
          de: "Rauch erkannt",
          ru: "Обнаружен дым",
          es: "Humo detectado",
          fr: _fr(vi: "Phát hiện khói", en: "Smoke detected"),
        );
      case "đã kích hoạt sos":
        return choose(
          vi: "Đã kích hoạt SOS",
          my: "SOS ဖွင့်ထားသည်",
          fil: "Na-activate ang SOS",
          km: "បានដំណើរការ SOS",
          en: "SOS activated",
          zh: "SOS 已激活",
          ko: "SOS 활성화됨",
          ja: "SOS が作動しました",
          de: "SOS aktiviert",
          ru: "SOS активирован",
          es: "SOS activado",
          fr: _fr(vi: "Đã kích hoạt SOS", en: "SOS activated"),
          th: "เปิดใช้งาน SOS แล้ว",
          ms: "SOS telah diaktifkan",
          lo: "ເປີດໃຊ້ SOS ແລ້ວ",
        );
      case "rò rỉ gas":
        return choose(
          vi: "Rò rỉ gas",
          en: "Gas leak detected",
          zh: "检测到燃气泄漏",
          ko: "가스 누출 감지",
          ja: "ガス漏れを検知",
          de: "Gasleck erkannt",
          ru: "Обнаружена утечка газа",
          es: "Fuga de gas detectada",
          fr: _fr(vi: "Rò rỉ gas", en: "Gas leak detected"),
        );
      case "phát hiện ngập nước":
        return choose(
          vi: "Phát hiện ngập nước",
          en: "Water leak detected",
          zh: "检测到漏水",
          ko: "누수 감지",
          ja: "水漏れを検知",
          de: "Wasserleck erkannt",
          ru: "Обнаружена протечка воды",
          es: "Inundación detectada",
          fr: _fr(vi: "Phát hiện ngập nước", en: "Water leak detected"),
        );
      case "phát hiện chập điện":
        return choose(
          vi: "Phát hiện chập điện",
          fil: "Natukoy ang short circuit",
          km: "រកឃើញសៀគ្វីខ្លី",
          en: "Short circuit detected",
          zh: "检测到短路",
          ko: "단락 감지",
          ja: "短絡を検知",
          de: "Kurzschluss erkannt",
          ru: "Обнаружено короткое замыкание",
          fr: "Court-circuit détecté",
          es: "Cortocircuito detectado",
          id: "Korsleting terdeteksi",
          th: "ตรวจพบไฟฟ้าลัดวงจร",
          ms: "Litar pintas dikesan",
          my: "လျှပ်စစ်ရှော့ခ် တွေ့ရှိသည်",
          lo: "ກວດພົບໄຟຟ້າລັດວົງຈອນ",
        );
      case "phát hiện quá dòng":
        return choose(
          vi: "Phát hiện quá dòng",
          fil: "Natukoy ang sobrang kuryente",
          km: "រកឃើញចរន្តលើស",
          en: "Overcurrent detected",
          zh: "检测到过流",
          ko: "과전류 감지",
          ja: "過電流を検知",
          de: "Überstrom erkannt",
          ru: "Обнаружен сверхток",
          fr: "Surintensité détectée",
          es: "Sobrecorriente detectada",
          id: "Arus berlebih terdeteksi",
          th: "ตรวจพบกระแสไฟเกิน",
          ms: "Arus berlebihan dikesan",
          my: "လျှပ်စီးအားလွန်ကဲမှု တွေ့ရှိသည်",
          lo: "ກວດພົບກະແສໄຟເກີນ",
        );
      case "phát hiện quá áp":
        return choose(
          vi: "Phát hiện quá áp",
          fil: "Natukoy ang sobrang boltahe",
          km: "រកឃើញវ៉ុលលើស",
          en: "Overvoltage detected",
          zh: "检测到过压",
          ko: "과전압 감지",
          ja: "過電圧を検知",
          de: "Überspannung erkannt",
          ru: "Обнаружено перенапряжение",
          fr: "Surtension détectée",
          es: "Sobretensión detectada",
          id: "Tegangan berlebih terdeteksi",
          th: "ตรวจพบแรงดันไฟเกิน",
          ms: "Voltan berlebihan dikesan",
          my: "ဗို့အားလွန်ကဲမှု တွေ့ရှိသည်",
          lo: "ກວດພົບແຮງດັນໄຟເກີນ",
        );
      case "thiết bị điện quá nhiệt":
        return choose(
          vi: "Thiết bị điện quá nhiệt",
          fil: "Sobrang init ng de-kuryenteng aparato",
          km: "ឧបករណ៍អគ្គិសនីឡើងកម្ដៅខ្លាំង",
          en: "Electrical device overheating",
          zh: "电气设备过热",
          ko: "전기 장치 과열",
          ja: "電気機器の過熱",
          de: "Elektrisches Gerät überhitzt",
          ru: "Перегрев электрического устройства",
          fr: "Surchauffe d’un appareil électrique",
          es: "Sobrecalentamiento del dispositivo eléctrico",
          id: "Perangkat listrik terlalu panas",
          th: "อุปกรณ์ไฟฟ้าร้อนเกินไป",
          ms: "Peranti elektrik terlalu panas",
          my: "လျှပ်စစ်ကိရိယာ အပူလွန်ကဲနေသည်",
          lo: "ອຸປະກອນໄຟຟ້າຮ້ອນເກີນໄປ",
        );
      case "khóa đang mở":
        return choose(
          vi: "Khóa đang mở",
          en: "Unlocked",
          zh: "未上锁",
          ko: "잠금 해제됨",
          ja: "ロック解除中",
          de: "Entriegelt",
          ru: "Замок открыт",
          es: "Cerradura abierta",
          fr: _fr(vi: "Khóa đang mở", en: "Unlocked"),
        );
      case "sóng yếu":
        return choose(
          vi: "Sóng yếu",
          en: "Weak signal",
          zh: "信号弱",
          ko: "신호 약함",
          ja: "信号が弱い",
          de: "Schwaches Signal",
          ru: "Слабый сигнал",
          es: "Señal débil",
          fr: _fr(vi: "Sóng yếu", en: "Weak signal"),
        );
      case "nhiệt độ cao":
        return choose(
          vi: "Nhiệt độ cao",
          en: "High temperature",
          zh: "温度过高",
          ko: "온도 높음",
          ja: "高温",
          de: "Hohe Temperatur",
          ru: "Высокая температура",
          es: "Temperatura alta",
          fr: _fr(vi: "Nhiệt độ cao", en: "High temperature"),
        );
      case "độ ẩm cao":
        return choose(
          vi: "Độ ẩm cao",
          en: "High humidity",
          zh: "湿度过高",
          ko: "습도 높음",
          ja: "高湿度",
          de: "Hohe Luftfeuchtigkeit",
          ru: "Высокая влажность",
          es: "Humedad alta",
          fr: _fr(vi: "Độ ẩm cao", en: "High humidity"),
        );
    }

    return null;
  }

  String _translateStatusFragment(String text) {
    final clean = text.trim();

    if (clean.isEmpty) {
      return text;
    }

    final translations = _activeTranslations;
    final exact = translations?[_translationAliases[clean] ?? clean];

    if (exact != null) {
      return exact;
    }

    final capitalized = _capitalizeStatusFragment(clean);
    final capitalizedExact = translations?[capitalized];

    if (capitalizedExact != null) {
      return capitalizedExact;
    }

    final lowercaseTranslation = _translateLowercaseStatusFragment(
      clean.toLowerCase(),
    );

    if (lowercaseTranslation != null) {
      return lowercaseTranslation;
    }

    if (isThai) {
      final exact = _translationFromMap(
        _thai,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isMalay) {
      final exact = _translationFromMap(
        _malay,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isFilipino) {
      final exact = _translationFromMap(
        _filipino,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isKhmer) {
      final exact = _translationFromMap(
        _khmer,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isBurmese) {
      final exact = _translationFromMap(
        _burmese,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isLao) {
      final exact = _translationFromMap(
        _lao,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isIndonesian) {
      final exact = _translationFromMap(
        _indonesian,
        _translationAliases[text] ?? text,
      );

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isSpanish) {
      final exact = _spanish[text];

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isFrench) {
      final exact = _french[text];

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isRussian) {
      final exact = _russian[text];

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isGerman) {
      final exact = _german[text];

      if (exact != null) {
        return exact;
      }

      return text;
    }

    if (isJapanese) {
      final exact = _japanese[text];

      if (exact != null) {
        return exact;
      }

      const fragments = {
        "Nhiệt độ cao": "高温",
        "Độ ẩm cao": "高湿度",
        "Có khói": "煙を検知",
        "SOS": "SOS",
        "Đang mở khi nhà ở chế độ Bảo vệ": "家が警戒モードのときに開いています",
        "Đang mở trong giờ báo động": "警報時間中に開いています",
        "Đang mở": "開いています",
        "Phát hiện chuyển động": "動きを検知",
        "Phát hiện hiện diện": "在室を検知",
        "Phát hiện rung/chấn động": "振動/衝撃を検知",
        "Phát hiện kính vỡ": "ガラス破損を検知",
        "Nhiệt độ nguy hiểm": "危険な高温を検知",
        "Phát hiện khí CO": "一酸化炭素を検知",
        "Khóa đang mở khi nhà ở chế độ Bảo vệ": "警戒モード中にロックが解除されています",
        "Khóa đang mở trong giờ báo động": "警報時間中にロックが解除されています",
        "Khóa đang mở": "ロック解除中",
        "Mất điện lưới": "主電源が切断されました",
        "Rò rỉ gas": "ガス漏れを検知",
        "Phát hiện ngập nước": "水漏れを検知",
        "Bị tháo": "取り外し検知",
        "Pin yếu": "バッテリー低下",
        "Sóng yếu": "信号が弱い",
        "Mất kết nối": "接続が切断されました",
        "Hub chưa gửi trạng thái": "Hub の状態がありません",
        "Hub mất kết nối": "Hub が切断されました",
        "MQTT mất kết nối": "MQTT が切断されました",
        "Đang kiểm tra kết nối Hub": "Hub 接続を確認中",
        "Hub tín hiệu bình thường": "Hub 接続は正常です",
        "Chưa có dữ liệu thiết bị để đánh giá": "評価するためのデバイスデータがありません",
      };

      return fragments[text] ?? text;
    }

    if (isKorean) {
      final exact = _korean[text];

      if (exact != null) {
        return exact;
      }

      const fragments = {
        "Nhiệt độ cao": "온도 높음",
        "Độ ẩm cao": "습도 높음",
        "Có khói": "연기 감지",
        "SOS": "SOS",
        "Đang mở khi nhà ở chế độ Bảo vệ": "집이 보호 모드일 때 열려 있음",
        "Đang mở trong giờ báo động": "경보 시간 중 열림",
        "Đang mở": "열림",
        "Phát hiện chuyển động": "움직임 감지",
        "Phát hiện hiện diện": "재실 감지",
        "Phát hiện rung/chấn động": "진동/충격 감지",
        "Phát hiện kính vỡ": "유리 파손 감지",
        "Nhiệt độ nguy hiểm": "위험 온도 감지",
        "Phát hiện khí CO": "일산화탄소 감지",
        "Khóa đang mở khi nhà ở chế độ Bảo vệ": "보호 모드에서 잠금 해제됨",
        "Khóa đang mở trong giờ báo động": "경보 시간 중 잠금 해제됨",
        "Khóa đang mở": "잠금 해제됨",
        "Mất điện lưới": "전원 끊김",
        "Rò rỉ gas": "가스 누출 감지",
        "Phát hiện ngập nước": "누수 감지",
        "Bị tháo": "분리 감지",
        "Pin yếu": "배터리 부족",
        "Sóng yếu": "신호 약함",
        "Mất kết nối": "연결 끊김",
        "Hub chưa gửi trạng thái": "Hub 상태 없음",
        "Hub mất kết nối": "Hub 연결 끊김",
        "MQTT mất kết nối": "MQTT 연결 끊김",
        "Đang kiểm tra kết nối Hub": "Hub 연결 확인 중",
        "Hub tín hiệu bình thường": "Hub 연결 정상",
        "Chưa có dữ liệu thiết bị để đánh giá": "평가할 기기 데이터가 없습니다",
      };

      return fragments[text] ?? text;
    }

    if (isChinese) {
      final exact = _chinese[text];

      if (exact != null) {
        return exact;
      }

      const fragments = {
        "Nhiệt độ cao": "温度过高",
        "Độ ẩm cao": "湿度过高",
        "Có khói": "检测到烟雾",
        "SOS": "SOS",
        "Đang mở khi nhà ở chế độ Bảo vệ": "家庭处于布防模式时仍打开",
        "Đang mở trong giờ báo động": "警报时段内被打开",
        "Đang mở": "已打开",
        "Phát hiện chuyển động": "检测到移动",
        "Phát hiện hiện diện": "检测到有人",
        "Phát hiện rung/chấn động": "检测到震动",
        "Phát hiện kính vỡ": "检测到玻璃破碎",
        "Nhiệt độ nguy hiểm": "危险高温",
        "Phát hiện khí CO": "检测到一氧化碳",
        "Khóa đang mở khi nhà ở chế độ Bảo vệ": "家庭处于布防模式时门锁未锁",
        "Khóa đang mở trong giờ báo động": "警报时段内门锁未锁",
        "Khóa đang mở": "未上锁",
        "Mất điện lưới": "市电断开",
        "Rò rỉ gas": "检测到燃气泄漏",
        "Phát hiện ngập nước": "检测到漏水",
        "Bị tháo": "检测到拆卸",
        "Pin yếu": "电量低",
        "Sóng yếu": "信号弱",
        "Mất kết nối": "连接中断",
        "Hub chưa gửi trạng thái": "Hub 状态不可用",
        "Hub mất kết nối": "Hub 已断开",
        "MQTT mất kết nối": "MQTT 已断开",
        "Đang kiểm tra kết nối Hub": "正在检查 Hub 连接",
        "Hub tín hiệu bình thường": "Hub 连接正常",
        "Chưa có dữ liệu thiết bị để đánh giá": "暂无设备数据可评估",
      };

      return fragments[text] ?? text;
    }

    if (!isEnglish) {
      return text;
    }

    const fragments = {
      "Nhiệt độ cao": "High temperature",
      "Độ ẩm cao": "High humidity",
      "Có khói": "Smoke detected",
      "SOS": "SOS",
      "Đang mở khi nhà ở chế độ Bảo vệ": "Open while Home is in Guard mode",
      "Đang mở trong giờ báo động": "Open during Alarm hours",
      "Đang mở": "Open",
      "Phát hiện chuyển động": "Motion detected",
      "Phát hiện hiện diện": "Presence detected",
      "Phát hiện rung/chấn động": "Vibration detected",
      "Phát hiện kính vỡ": "Glass break detected",
      "Nhiệt độ nguy hiểm": "Dangerous heat detected",
      "Phát hiện khí CO": "Carbon monoxide detected",
      "Khóa đang mở khi nhà ở chế độ Bảo vệ":
          "Unlocked while Home is in Guard mode",
      "Khóa đang mở trong giờ báo động": "Unlocked during Alarm hours",
      "Khóa đang mở": "Unlocked",
      "Mất điện lưới": "Mains power lost",
      "Rò rỉ gas": "Gas leak detected",
      "Phát hiện ngập nước": "Water leak detected",
      "Bị tháo": "Tamper detected",
      "Pin yếu": "Low battery",
      "Sóng yếu": "Weak signal",
      "Mất kết nối": "Disconnected",
      "Hub chưa gửi trạng thái": "Hub status unavailable",
      "Hub mất kết nối": "Hub disconnected",
      "MQTT mất kết nối": "MQTT disconnected",
      "Đang kiểm tra kết nối Hub": "Checking Hub connection",
      "Hub tín hiệu bình thường": "Hub connected",
      "Chưa có dữ liệu thiết bị để đánh giá":
          "No device data available for assessment",
    };

    return fragments[text] ?? text;
  }

  String get splashTagline => choose(
    vi: "An tâm hơn trong từng ngôi nhà",
    en: "Peace of mind in every home",
    zh: "让每个家庭更安心",
    ko: "모든 집에 더 큰 안심을",
    ja: "すべての家に、もっと安心を",
    de: 'Mehr Ruhe in jedem Zuhause',
    ru: 'Спокойствие в каждом доме',

    es: "Más tranquilidad en cada casa",
    fr: _fr(
      vi: "An tâm hơn trong từng ngôi nhà",
      en: "Peace of mind in every home",
    ),
  );

  String get alarmTitle => choose(
    vi: "Báo động SafeHome",
    en: "SafeHome Alarm",
    zh: "SafeHome 警报",
    ko: "SafeHome 경보",
    ja: "SafeHome 警報",
    de: 'SafeHome Alarm',
    ru: 'SafeHome тревога',

    es: "Alarma SafeHome",
    fr: _fr(vi: "Báo động SafeHome", en: "SafeHome Alarm"),
  );

  String get alarmBody => choose(
    vi: "Có cảnh báo an ninh cần kiểm tra ngay.",
    en: "A security alert requires your attention.",
    zh: "有安全警报需要立即检查。",
    ko: "확인이 필요한 보안 경고가 있습니다.",
    ja: "確認が必要なセキュリティ警告があります。",
    de: 'Ein Sicherheitsalarm erfordert deine Aufmerksamkeit.',
    ru: 'Тревога безопасности требует вашего внимания.',

    es: "Una alerta de seguridad requiere revisión inmediata.",
    fr: _fr(
      vi: "Có cảnh báo an ninh cần kiểm tra ngay.",
      en: "A security alert requires your attention.",
    ),
  );

  String get alarmFallback => choose(
    vi: "Có cảnh báo cần kiểm tra",
    en: "An alert requires your attention",
    zh: "有警报需要检查",
    ko: "확인이 필요한 경고가 있습니다",
    ja: "確認が必要な警告があります",
    de: 'Ein Alarm erfordert deine Aufmerksamkeit',
    ru: 'Тревога требует вашего внимания',

    es: "Hay una alerta que revisar",
    fr: _fr(
      vi: "Có cảnh báo cần kiểm tra",
      en: "An alert requires your attention",
    ),
  );

  String autoCloseAfter(String time) => choose(
    vi: "Tự đóng sau $time",
    fil: "Awtomatikong magsasara sa loob ng $time",
    km: "បិទដោយស្វ័យប្រវត្តិក្នុងរយៈពេល $time",
    en: "Auto-closes in $time",
    zh: "$time 后自动关闭",
    ko: "$time 후 자동으로 닫힘",
    ja: "$time 後に自動で閉じます",
    de: 'Schließt automatisch in $time',
    ru: 'Автоматически закроется через $time',

    es: "Se cierra automáticamente en $time",
    fr: _fr(vi: "Tự đóng sau $time", en: "Auto-closes in $time"),
    id: "Tutup otomatis dalam $time",
    th: "ปิดอัตโนมัติหลัง $time",
    ms: "Ditutup secara automatik dalam $time",
    my: "$time အကြာတွင် အလိုအလျောက်ပိတ်မည်",
    lo: "ປິດເອງຫຼັງ $time",
  );

  String get owner => t("Chủ nhà");
  String get admin => choose(
    vi: "Quản trị viên",
    en: "Admin",
    zh: "管理员",
    ko: "관리자",
    ja: "管理者",
    de: 'Administrator',
    ru: 'Администратор',

    es: "Administrador",
    fr: _fr(vi: "Quản trị viên", en: "Admin"),
  );
  String get member => choose(
    vi: "Thành viên",
    en: "Member",
    zh: "成员",
    ko: "구성원",
    ja: "メンバー",
    de: 'Mitglied',
    ru: 'Участник',

    es: "Miembro",
    fr: _fr(vi: "Thành viên", en: "Member"),
  );
  String get notUpdated => t("Chưa cập nhật");
  String get unnamedHome => t("Nhà chưa đặt tên");
  String get role => choose(
    vi: "Vai trò",
    en: "Role",
    zh: "角色",
    ko: "역할",
    ja: "役割",
    de: 'Rolle',
    ru: 'Роль',

    es: "Rol",
    fr: _fr(vi: "Vai trò", en: "Role"),
  );
  String get address => t("Địa chỉ");
  String get members => choose(
    vi: "Thành viên",
    en: "Members",
    zh: "成员",
    ko: "구성원",
    ja: "メンバー",
    de: 'Mitglieder',
    ru: 'Участники',

    es: "Miembro",
    fr: _fr(vi: "Thành viên", en: "Members"),
  );
  String get loading => choose(
    vi: "Đang tải...",
    en: "Loading...",
    zh: "正在加载...",
    ko: "로딩 중...",
    ja: "読み込み中...",
    de: 'Wird geladen...',
    ru: 'Загрузка...',

    es: "Cargando...",
    fr: _fr(vi: "Đang tải...", en: "Loading..."),
  );
  String get manageHome => choose(
    vi: "Quản lý nhà",
    en: "Home management",
    zh: "家庭管理",
    ko: "집 관리",
    ja: "家の管理",
    de: 'Zuhause verwalten',
    ru: 'Управление домом',

    es: "Casa management",
    fr: _fr(vi: "Quản lý nhà", en: "Home management"),
  );
  String get shareHome => t("Chia sẻ nhà");
  String get shareHomeSubtitle => choose(
    vi: "Mời người khác tham gia nhà này",
    en: "Invite someone to join this home",
    zh: "邀请他人加入此家庭",
    ko: "다른 사람을 이 집에 초대합니다",
    ja: "他の人をこの家に招待します",
    de: 'Jemanden einladen, diesem Zuhause beizutreten',
    ru: 'Пригласить другого человека присоединиться к этому дому',

    es: "Invitar a otra persona a unirse a esta casa",
    fr: _fr(
      vi: "Mời người khác tham gia nhà này",
      en: "Invite someone to join this home",
    ),
  );
  String get homeMembers => choose(
    vi: "Thành viên trong nhà",
    en: "Home members",
    zh: "家庭成员",
    ko: "집 구성원",
    ja: "家のメンバー",
    de: 'Mitglieder im Zuhause',
    ru: 'Участники дома',

    es: "Miembros de la casa",
    fr: _fr(vi: "Thành viên trong nhà", en: "Home members"),
  );
  String get homeMembersSubtitle => choose(
    vi: "Xem và quản lý quyền thành viên",
    en: "View and manage member roles",
    zh: "查看和管理成员权限",
    ko: "구성원 권한을 보고 관리합니다",
    ja: "メンバーの権限を表示・管理します",
    de: 'Mitgliederrollen anzeigen und verwalten',
    ru: 'Просмотр и управление ролями участников',

    es: "Ver y gestionar los roles de los miembros",
    fr: _fr(
      vi: "Xem và quản lý quyền thành viên",
      en: "View and manage member roles",
    ),
  );
  String get manageRooms => choose(
    vi: "Quản lý phòng",
    en: "Manage rooms",
    zh: "管理房间",
    ko: "방 관리",
    ja: "部屋の管理",
    de: 'Räume verwalten',
    ru: 'Управление комнатами',

    es: "Gestionar habitaciones",
    fr: _fr(vi: "Quản lý phòng", en: "Manage rooms"),
  );
  String get manageRoomsSubtitle => choose(
    vi: "Thêm, đổi tên và sắp xếp phòng",
    en: "Add, rename and reorder rooms",
    zh: "添加、重命名和排序房间",
    ko: "방을 추가, 이름 변경 및 정렬합니다",
    ja: "部屋の追加、名前変更、並べ替えを行います",
    de: 'Räume hinzufügen, umbenennen und neu anordnen',
    ru: 'Добавление, переименование и сортировка комнат',

    es: "Añadir, renombrar y ordenar habitaciones",
    fr: _fr(
      vi: "Thêm, đổi tên và sắp xếp phòng",
      en: "Add, rename and reorder rooms",
    ),
  );
  String get allDevices => choose(
    vi: "Toàn bộ thiết bị",
    en: "All devices",
    zh: "全部设备",
    ko: "전체 기기",
    ja: "すべてのデバイス",
    de: 'Alle Geräte',
    ru: 'Все устройства',

    es: "Todos los dispositivos",
    fr: _fr(vi: "Toàn bộ thiết bị", en: "All devices"),
  );
  String get allDevicesSubtitle => choose(
    vi: "Kiểm tra thiết bị trong nhà này",
    en: "Review devices in this home",
    zh: "查看此家庭中的设备",
    ko: "이 집의 기기를 확인합니다",
    ja: "この家のデバイスを確認します",
    de: 'Geräte in diesem Zuhause prüfen',
    ru: 'Проверить устройства в этом доме',

    es: "Revisar dispositivos en esta casa",
    fr: _fr(
      vi: "Kiểm tra thiết bị trong nhà này",
      en: "Review devices in this home",
    ),
  );
  String get transferOwnership => t("Chuyển quyền chủ nhà");
  String get transferOwnershipSubtitle => choose(
    vi: "Chuyển quyền sở hữu cho thành viên khác",
    en: "Transfer ownership to another member",
    zh: "将所有权转移给其他成员",
    ko: "소유권을 다른 구성원에게 이전합니다",
    ja: "所有権を他のメンバーに移転します",
    de: 'Besitz an ein anderes Mitglied übertragen',
    ru: 'Передать права владельца другому участнику',

    es: "Transferir la propiedad a otro miembro",
    fr: _fr(
      vi: "Chuyển quyền sở hữu cho thành viên khác",
      en: "Transfer ownership to another member",
    ),
  );
  String get accountAndSystem => choose(
    vi: "Tài khoản & hệ thống",
    en: "Account & system",
    zh: "账户与系统",
    ko: "계정 및 시스템",
    ja: "アカウントとシステム",
    de: 'Konto & System',
    ru: 'Аккаунт и система',

    es: "Cuenta & system",
    fr: _fr(vi: "Tài khoản & hệ thống", en: "Account & system"),
  );
  String get personalAccount => choose(
    vi: "Tài khoản cá nhân",
    en: "Personal account",
    zh: "个人账户",
    ko: "개인 계정",
    ja: "個人アカウント",
    de: 'Persönliches Konto',
    ru: 'Личный аккаунт',

    es: "Personal cuenta",
    fr: _fr(vi: "Tài khoản cá nhân", en: "Personal account"),
  );
  String get personalAccountSubtitle => choose(
    vi: "Hồ sơ, yêu cầu và lời mời tham gia",
    en: "Profile, requests and invitations",
    zh: "个人资料、申请和邀请",
    ko: "프로필, 요청 및 초대",
    ja: "プロフィール、リクエスト、招待",
    de: 'Profil, Anfragen und Einladungen',
    ru: 'Профиль, запросы и приглашения',

    es: "Perfil, solicitudes e invitaciones",
    fr: _fr(
      vi: "Hồ sơ, yêu cầu và lời mời tham gia",
      en: "Profile, requests and invitations",
    ),
  );
  String get language => choose(
    vi: "Ngôn ngữ",
    en: "Language",
    zh: "语言",
    ko: "언어",
    ja: "言語",
    de: 'Sprache',
    ru: 'Язык',

    es: "Idioma",
    fr: _fr(vi: "Ngôn ngữ", en: "Language"),
  );
  String get languageSubtitle => choose(
    vi: "Thay đổi ngôn ngữ hiển thị",
    en: "Change the display language",
    zh: "更改显示语言",
    ko: "표시 언어 변경",
    ja: "表示言語を変更",
    de: 'Anzeigesprache ändern',
    ru: 'Изменить язык отображения',

    es: "Cambiar idioma de visualización",
    fr: _fr(
      vi: "Thay đổi ngôn ngữ hiển thị",
      en: "Change the display language",
    ),
  );
  String get chooseLanguage => choose(
    vi: "Chọn ngôn ngữ",
    en: "Choose language",
    zh: "选择语言",
    ko: "언어 선택",
    ja: "言語を選択",
    de: 'Sprache auswählen',
    ru: 'Выбрать язык',

    es: "Elegir idioma",
    fr: _fr(vi: "Chọn ngôn ngữ", en: "Choose language"),
  );
  String get accountInUseTitle => choose(
    vi: "Tài khoản đang được sử dụng",
    my: "အကောင့်ကို အသုံးပြုနေသည်",
    en: "Account in use",
    zh: "账户正在使用中",
    ko: "계정 사용 중",
    ja: "アカウントは使用中です",
    de: "Konto wird verwendet",
    ru: "Аккаунт используется",
    fr: "Compte en cours d’utilisation",
    es: "La cuenta está en uso",
    id: "Akun sedang digunakan",
    th: "บัญชีกำลังถูกใช้งาน",
    ms: "Akaun sedang digunakan",
    fil: "Ginagamit ang account",
    km: "គណនីកំពុងត្រូវបានប្រើ",
    lo: "ບັນຊີກຳລັງຖືກໃຊ້",
  );
  String get accountInUseMessage => choose(
    vi: "Hiện tại tài khoản này đang đăng nhập trên một thiết bị khác. Nếu tiếp tục, tài khoản trên thiết bị đó sẽ tự đăng xuất.",
    my: "ဤအကောင့်ကို အခြားစက်ပစ္စည်းတစ်ခုတွင် လက်ရှိဝင်ထားသည်။ ဆက်လုပ်ပါက ထိုစက်ပစ္စည်းရှိအကောင့်သည် အလိုအလျောက်ထွက်ပါမည်။",
    en: "This account is currently signed in on another device. If you continue, the account on that device will be signed out automatically.",
    zh: "此账户当前已在另一台设备上登录。如果继续，该设备上的账户将自动退出登录。",
    ko: "현재 이 계정은 다른 기기에 로그인되어 있습니다. 계속하면 해당 기기의 계정이 자동으로 로그아웃됩니다.",
    ja: "現在、このアカウントは別のデバイスでログインしています。続行すると、そのデバイスのアカウントは自動的にログアウトされます。",
    de: "Dieses Konto ist derzeit auf einem anderen Gerät angemeldet. Wenn Sie fortfahren, wird das Konto auf diesem Gerät automatisch abgemeldet.",
    ru: "Сейчас этот аккаунт используется для входа на другом устройстве. Если продолжить, на том устройстве будет автоматически выполнен выход.",
    fr: "Ce compte est actuellement connecté sur un autre appareil. Si vous continuez, il sera automatiquement déconnecté de cet appareil.",
    es: "Esta cuenta tiene una sesión activa en otro dispositivo. Si continúas, la sesión de ese dispositivo se cerrará automáticamente.",
    id: "Akun ini sedang masuk di perangkat lain. Jika Anda melanjutkan, akun di perangkat tersebut akan keluar secara otomatis.",
    th: "ขณะนี้บัญชีนี้ลงชื่อเข้าใช้อยู่บนอุปกรณ์อื่น หากดำเนินการต่อ บัญชีบนอุปกรณ์นั้นจะออกจากระบบโดยอัตโนมัติ",
    ms: "Akaun ini sedang dilog masuk pada peranti lain. Jika anda meneruskan, akaun pada peranti tersebut akan dilog keluar secara automatik.",
    fil:
        "Kasalukuyang naka-sign in ang account na ito sa ibang device. Kung magpapatuloy ka, awtomatikong masa-sign out ang account sa device na iyon.",
    km: "បច្ចុប្បន្ន គណនីនេះកំពុងចូលនៅលើឧបករណ៍ផ្សេង។ ប្រសិនបើអ្នកបន្ត គណនីនៅលើឧបករណ៍នោះនឹងត្រូវចាកចេញដោយស្វ័យប្រវត្តិ។",
    lo: "ບັນຊີນີ້ກຳລັງເຂົ້າລະບົບຢູ່ໃນອຸປະກອນອື່ນ. ຖ້າສືບຕໍ່ ບັນຊີໃນອຸປະກອນນັ້ນຈະຖືກອອກຈາກລະບົບ.",
  );
  String get continueSignInLabel => choose(
    vi: "Tiếp tục đăng nhập",
    my: "ဆက်လက်အကောင့်ဝင်ရန်",
    en: "Continue signing in",
    zh: "继续登录",
    ko: "계속 로그인",
    ja: "ログインを続ける",
    de: "Anmeldung fortsetzen",
    ru: "Продолжить вход",
    fr: "Continuer la connexion",
    es: "Continuar inicio de sesión",
    id: "Lanjutkan masuk",
    th: "ลงชื่อเข้าใช้ต่อ",
    ms: "Teruskan log masuk",
    fil: "Magpatuloy sa pag-sign in",
    km: "បន្តចូល",
    lo: "ສືບຕໍ່ເຂົ້າລະບົບ",
  );
  String get forcedRemoteSessionLogoutMessage => choose(
    vi: "Tài khoản đã được đăng nhập trên một thiết bị khác.",
    my: "ဤအကောင့်ကို အခြားစက်ပစ္စည်းတစ်ခုတွင် ဝင်ထားသည်။",
    en: "This account was signed in on another device.",
    zh: "此账户已在另一台设备上登录。",
    ko: "이 계정이 다른 기기에서 로그인되었습니다.",
    ja: "このアカウントは別のデバイスでログインされました。",
    de: "Dieses Konto wurde auf einem anderen Gerät angemeldet.",
    ru: "В этот аккаунт вошли на другом устройстве.",
    fr: "Ce compte a été connecté sur un autre appareil.",
    es: "Se ha iniciado sesión en esta cuenta desde otro dispositivo.",
    id: "Akun ini telah masuk di perangkat lain.",
    th: "บัญชีนี้ได้ลงชื่อเข้าใช้บนอุปกรณ์อื่นแล้ว",
    ms: "Akaun ini telah dilog masuk pada peranti lain.",
    fil: "Na-sign in ang account na ito sa ibang device.",
    km: "គណនីនេះបានចូលនៅលើឧបករណ៍ផ្សេង។",
    lo: "ບັນຊີນີ້ເຂົ້າລະບົບຢູ່ໃນອຸປະກອນອື່ນ.",
  );
  String get vietnamese => choose(
    vi: "Tiếng Việt",
    en: "Vietnamese",
    zh: "越南语",
    ko: "베트남어",
    ja: "ベトナム語",
    de: 'Vietnamesisch',
    ru: 'Вьетнамский',

    es: "Vietnamita",
    fr: _fr(vi: "Tiếng Việt", en: "Vietnamese"),
  );
  String get english => choose(
    vi: "Tiếng Anh",
    en: "English",
    zh: "英语",
    ko: "영어",
    ja: "英語",
    de: 'Englisch',
    ru: 'Английский',

    es: "Inglés",
    fr: _fr(vi: "Tiếng Anh", en: "English"),
  );
  String get chinese => choose(
    vi: "Tiếng Trung",
    en: "Chinese",
    zh: "中文",
    ko: "중국어",
    ja: "中国語",
    de: 'Chinesisch',
    ru: 'Китайский',

    es: "Chino",
    fr: _fr(vi: "Tiếng Trung", en: "Chinese"),
  );
  String get korean => choose(
    vi: "Tiếng Hàn",
    en: "Korean",
    zh: "韩语",
    ko: "한국어",
    ja: "韓国語",
    de: 'Koreanisch',
    ru: 'Корейский',

    es: "Coreano",
    fr: _fr(vi: "Tiếng Hàn", en: "Korean"),
  );
  String get japanese => choose(
    vi: "Tiếng Nhật",
    en: "Japanese",
    zh: "日语",
    ko: "일본어",
    ja: "日本語",
    de: 'Japanisch',
    ru: 'Японский',

    es: "Japonés",
    fr: _fr(vi: "Tiếng Nhật", en: "Japanese"),
  );
  String get currentLanguageName {
    if (isMalay) {
      return "Bahasa Melayu";
    }

    if (isFilipino) {
      return "Filipino";
    }

    if (isKhmer) {
      return "ភាសាខ្មែរ";
    }

    if (isBurmese) {
      return "မြန်မာဘာသာ";
    }

    if (isLao) {
      return "ລາວ";
    }

    if (isThai) {
      return "ภาษาไทย";
    }

    if (isIndonesian) {
      return "Bahasa Indonesia";
    }

    if (isSpanish) {
      return "Español";
    }
    if (isFrench) {
      return "Français";
    }
    if (isRussian) {
      return "Русский";
    }

    if (isGerman) {
      return "Deutsch";
    }

    if (isJapanese) {
      return "日本語";
    }

    if (isKorean) {
      return "한국어";
    }

    if (isChinese) {
      return "中文";
    }

    return isEnglish ? "English" : "Tiếng Việt";
  }

  String get dangerZone => choose(
    vi: "Khu vực nguy hiểm",
    en: "Danger zone",
    zh: "危险区域",
    ko: "위험 구역",
    ja: "危険ゾーン",
    de: 'Gefahrenbereich',
    ru: 'Опасная зона',

    es: "Zona de peligro",
    fr: _fr(vi: "Khu vực nguy hiểm", en: "Danger zone"),
  );

  String alarmIncidentLevelLabel(String level) {
    switch (level.trim().toLowerCase()) {
      case "emergency":
        return choose(
          vi: "KHẨN CẤP",
          en: "EMERGENCY",
          zh: "紧急",
          ko: "긴급",
          ja: "緊急",
          de: "NOTFALL",
          ru: "ЭКСТРЕННО",
          fr: "URGENCE",
          es: "EMERGENCIA",
          id: "DARURAT",
          th: "ฉุกเฉิน",
          ms: "KECEMASAN",
          fil: "EMERGENCY",
          km: "បន្ទាន់",
          my: "အရေးပေါ်",
          lo: "ສຸກເສີນ",
        );
      case "warning":
        return choose(
          vi: "CẦN CHÚ Ý",
          en: "WARNING",
          zh: "注意",
          ko: "주의",
          ja: "注意",
          de: "WARNUNG",
          ru: "ВНИМАНИЕ",
          fr: "ATTENTION",
          es: "ADVERTENCIA",
          id: "PERINGATAN",
          th: "คำเตือน",
          ms: "AMARAN",
          fil: "BABALA",
          km: "ការព្រមាន",
          my: "သတိပေးချက်",
          lo: "ຄຳເຕືອນ",
        );
      case "info":
        return choose(
          vi: "THÔNG TIN",
          en: "INFORMATION",
          zh: "信息",
          ko: "정보",
          ja: "情報",
          de: "INFORMATION",
          ru: "ИНФОРМАЦИЯ",
          fr: "INFORMATION",
          es: "INFORMACIÓN",
          id: "INFORMASI",
          th: "ข้อมูล",
          ms: "MAKLUMAT",
          fil: "IMPORMASYON",
          km: "ព័ត៌មាន",
          my: "အချက်အလက်",
          lo: "ຂໍ້ມູນ",
        );
      case "alarm":
      default:
        return choose(
          vi: "BÁO ĐỘNG",
          en: "ALARM",
          zh: "警报",
          ko: "경보",
          ja: "警報",
          de: "Alarm",
          ru: "ТРЕВОГА",
          fr: "ALARME",
          es: "ALARMA",
          id: "Alarm",
          th: "สัญญาณเตือน",
          ms: "PENGGERA",
          fil: "Alarma",
          km: "សំឡេងរោទិ៍",
          my: "အချက်ပေးသံ",
          lo: "ສັນຍານເຕືອນໄພ",
        );
    }
  }

  String alarmIncidentActiveLabel() => choose(
    vi: "Đang hoạt động",
    en: "Active",
    zh: "正在进行",
    ko: "활성",
    ja: "対応中",
    de: "Aktiv",
    ru: "Активно",
    fr: "Active",
    es: "Activa",
    id: "Aktif",
    th: "กำลังทำงาน",
    ms: "Aktif",
    fil: "Aktibo",
    km: "កំពុងដំណើរការ",
    my: "လုပ်ဆောင်နေသည်",
  );

  String alarmIncidentResolutionReason(String action) {
    final value = action.trim().toLowerCase();

    if (value.contains("device_state_resolved") ||
        value.contains("condition_cleared") ||
        value.contains("sensor_cleared")) {
      return choose(
        vi: "Cảm biến đã trở lại trạng thái an toàn.",
        en: "The sensor returned to a safe state.",
        zh: "传感器已恢复到安全状态。",
        ko: "센서가 안전 상태로 돌아왔습니다.",
        ja: "センサーが安全な状態に戻りました。",
        de: "Der Sensor ist wieder in einem sicheren Zustand.",
        ru: "Датчик вернулся в безопасное состояние.",
        fr: "Le capteur est revenu à un état sûr.",
        es: "El sensor volvió a un estado seguro.",
        id: "Sensor kembali ke kondisi aman.",
        th: "เซ็นเซอร์กลับสู่สถานะปลอดภัยแล้ว",
        ms: "Sensor telah kembali ke keadaan selamat.",
        fil: "Bumalik na sa ligtas na estado ang sensor.",
        km: "ឧបករណ៍ចាប់សញ្ញាបានត្រឡប់ទៅស្ថានភាពសុវត្ថិភាព។",
        my: "အာရုံခံကိရိယာသည် လုံခြုံသောအခြေအနေသို့ ပြန်ရောက်ပါပြီ။",
        lo: "ເຊັນເຊີກັບຄືນສູ່ສະຖານະປອດໄພແລ້ວ.",
      );
    }

    if (value == "stop" || value.contains("manual")) {
      return choose(
        vi: "Người dùng đã tắt cảnh báo.",
        en: "The alert was stopped by a user.",
        zh: "用户已停止警报。",
        ko: "사용자가 경보를 중지했습니다.",
        ja: "ユーザーが警報を停止しました。",
        de: "Der Alarm wurde von einem Benutzer beendet.",
        ru: "Пользователь остановил тревогу.",
        fr: "L’alerte a été arrêtée par un utilisateur.",
        es: "Un usuario detuvo la alerta.",
        id: "Peringatan dihentikan oleh pengguna.",
        th: "ผู้ใช้หยุดการแจ้งเตือนแล้ว",
        ms: "Amaran telah dihentikan oleh pengguna.",
        fil: "Itinigil ng user ang alerto.",
        km: "អ្នកប្រើបានបញ្ឈប់ការជូនដំណឹង។",
        my: "အသုံးပြုသူက သတိပေးချက်ကို ရပ်လိုက်ပါသည်။",
        lo: "ຜູ້ໃຊ້ຢຸດການເຕືອນແລ້ວ.",
      );
    }

    if (value.contains("schedule") || value.contains("outside_window")) {
      return choose(
        vi: "Khung giờ bảo vệ đã kết thúc.",
        en: "The protection schedule ended.",
        zh: "保护时段已结束。",
        ko: "보호 일정이 종료되었습니다.",
        ja: "保護スケジュールが終了しました。",
        de: "Der Schutzzeitplan ist beendet.",
        ru: "Расписание охраны завершилось.",
        fr: "La période de protection est terminée.",
        es: "El horario de protección terminó.",
        id: "Jadwal perlindungan telah berakhir.",
        th: "ช่วงเวลาการป้องกันสิ้นสุดแล้ว",
        ms: "Jadual perlindungan telah tamat.",
        fil: "Natapos na ang iskedyul ng proteksiyon.",
        km: "កាលវិភាគការពារបានបញ្ចប់។",
        my: "ကာကွယ်ရေးအချိန်ဇယား ပြီးဆုံးသွားပါပြီ။",
        lo: "ຊ່ວງເວລາປ້ອງກັນສິ້ນສຸດແລ້ວ.",
      );
    }

    if (value.contains("mode") || value.contains("disarmed")) {
      return choose(
        vi: "Chế độ Bảo vệ đã được tắt.",
        en: "Protection mode was turned off.",
        zh: "保护模式已关闭。",
        ko: "보호 모드가 꺼졌습니다.",
        ja: "保護モードが解除されました。",
        de: "Der Schutzmodus wurde ausgeschaltet.",
        ru: "Режим охраны выключен.",
        fr: "Le mode Protection a été désactivé.",
        es: "El modo Protección se desactivó.",
        id: "Mode Perlindungan dinonaktifkan.",
        th: "ปิดโหมดป้องกันแล้ว",
        ms: "Mod Perlindungan telah dimatikan.",
        fil: "In-off ang Protection mode.",
        km: "របៀបការពារត្រូវបានបិទ។",
        my: "ကာကွယ်မှုမုဒ်ကို ပိတ်လိုက်ပါပြီ။",
        lo: "ປິດໂໝດປ້ອງກັນແລ້ວ.",
      );
    }

    if (value.contains("expired")) {
      return choose(
        vi: "Cảnh báo tức thời đã tự kết thúc.",
        en: "The temporary alert ended automatically.",
        zh: "临时警报已自动结束。",
        ko: "일시 경보가 자동으로 종료되었습니다.",
        ja: "一時的な警報が自動的に終了しました。",
        de: "Der temporäre Alarm wurde automatisch beendet.",
        ru: "Временная тревога завершилась автоматически.",
        fr: "L’alerte temporaire s’est terminée automatiquement.",
        es: "La alerta temporal terminó automáticamente.",
        id: "Peringatan sementara berakhir otomatis.",
        th: "การแจ้งเตือนชั่วคราวสิ้นสุดโดยอัตโนมัติ",
        ms: "Amaran sementara tamat secara automatik.",
        fil: "Awtomatikong natapos ang pansamantalang alerto.",
        km: "ការជូនដំណឹងបណ្តោះអាសន្នបានបញ្ចប់ដោយស្វ័យប្រវត្តិ។",
        my: "ယာယီသတိပေးချက်သည် အလိုအလျောက် ပြီးဆုံးသွားပါပြီ။",
        lo: "ການເຕືອນທັນທີສິ້ນສຸດອັດຕະໂນມັດແລ້ວ.",
      );
    }

    return choose(
      vi: "Điều kiện cảnh báo không còn hoạt động.",
      en: "The alert condition is no longer active.",
      zh: "警报条件已不再存在。",
      ko: "경보 조건이 더 이상 활성 상태가 아닙니다.",
      ja: "警報条件はすでに解消されています。",
      de: "Die Alarmbedingung ist nicht mehr aktiv.",
      ru: "Условие тревоги больше не активно.",
      fr: "La condition d’alerte n’est plus active.",
      es: "La condición de alerta ya no está activa.",
      id: "Kondisi peringatan sudah tidak aktif.",
      th: "เงื่อนไขการแจ้งเตือนไม่ทำงานแล้ว",
      ms: "Keadaan amaran tidak lagi aktif.",
      fil: "Hindi na aktibo ang kondisyon ng alerto.",
      km: "លក្ខខណ្ឌការជូនដំណឹងលែងសកម្ម។",
      my: "သတိပေးချက်အခြေအနေသည် မလုပ်ဆောင်တော့ပါ။",
      lo: "ເງື່ອນໄຂການເຕືອນບໍ່ເຮັດວຽກແລ້ວ.",
    );
  }

  String alarmIncidentResolvedMessage(String action) {
    final reason = alarmIncidentResolutionReason(action);

    return choose(
      vi: "Cảnh báo đã kết thúc: $reason",
      en: "Alert ended: $reason",
      zh: "警报已结束：$reason",
      ko: "경보 종료: $reason",
      ja: "警報終了: $reason",
      de: "Alarm beendet: $reason",
      ru: "Тревога завершена: $reason",
      fr: "Alerte terminée : $reason",
      es: "Alerta finalizada: $reason",
      id: "Peringatan berakhir: $reason",
      th: "สิ้นสุดการแจ้งเตือน: $reason",
      ms: "Amaran tamat: $reason",
      fil: "Natapos ang alerto: $reason",
      km: "ការជូនដំណឹងបានបញ្ចប់៖ $reason",
      my: "သတိပေးချက်ပြီးဆုံးပါပြီ: $reason",
      lo: "ການເຕືອນສິ້ນສຸດແລ້ວ: $reason",
    );
  }

  String get deleteHome => t("Xoá nhà");
  String get deleteHomeSubtitle => choose(
    vi: "Xoá toàn bộ dữ liệu và thiết bị",
    en: "Delete all home data and devices",
    zh: "删除所有家庭数据和设备",
    ko: "모든 집 데이터와 기기를 삭제합니다",
    ja: "家のデータとデバイスをすべて削除します",
    de: 'Alle Zuhause-Daten und Geräte löschen',
    ru: 'Удалить все данные дома и устройства',

    es: "Eliminar todos los datos y dispositivos de la casa",
    fr: _fr(
      vi: "Xoá toàn bộ dữ liệu và thiết bị",
      en: "Delete all home data and devices",
    ),
  );
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
