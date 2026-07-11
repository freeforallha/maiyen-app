import 'package:flutter/material.dart';

class AppStrings {
  final bool isEnglish;
  final bool isChinese;
  final bool isKorean;
  final bool isJapanese;
  final bool isGerman;
  final bool isRussian;
  final bool isFrench;
  final bool isSpanish;

  const AppStrings._({
    required this.isEnglish,
    required this.isChinese,
    required this.isKorean,
    required this.isJapanese,
    required this.isGerman,
    required this.isRussian,
    required this.isFrench,
    required this.isSpanish,
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
  }) {
    if (isSpanish) {
      return es ?? _spanish[vi] ?? vi;
    }

    if (isFrench) {
      return fr ?? _french[vi] ?? en;
    }

    if (isRussian) {
      return ru ?? _russian[vi] ?? en;
    }

    if (isGerman) {
      return de ?? _german[vi] ?? en;
    }

    if (isJapanese) {
      return ja ?? _japanese[vi] ?? vi;
    }

    if (isKorean) {
      return ko ?? _korean[vi] ?? vi;
    }

    if (isChinese) {
      return zh ?? _chinese[vi] ?? vi;
    }

    return isEnglish ? en : vi;
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
          : "L'Alarm se répète après $minutes minutes si le problème persiste.";
    }

    if (en.contains("turned on Manual Guard mode for") && firstQuote != null) {
      final actorName = en.split(" turned on ").first;
      return "$actorName a activé le mode protection manuel pour « $firstQuote ». Ce mode ne se désactive que lorsqu'un membre autorisé revient au mode normal.";
    }

    if (en.startsWith("You enabled Alarm for") && firstQuote != null) {
      return "Vous avez activé Alarm pour « $firstQuote ».";
    }

    if (en.startsWith("You disabled every Alarm for") && firstQuote != null) {
      return "Vous avez désactivé tous les Alarm de « $firstQuote ».";
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
        "La période de pause doit être dans le planning Alarm",
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
          .replaceFirst("Alarm applied to", "Alarm appliqué à")
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
          ko: "집 주인",
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

  String manualSecurityModeEnabledTitle() => choose(
    vi: "Mode Bảo vệ thủ công đã bật",
    en: "Manual Guard mode enabled",
    zh: "手动保护模式已开启",
    ko: "수동 보호 모드가 켜졌습니다",
    ja: "手動Guardモードがオンになりました",
    de: 'Manueller Schutzmodus aktiviert',
    ru: 'Ручной режим охраны включен',

    es: "Modo protección manual activado",
    fr: _fr(vi: "Mode Bảo vệ thủ công đã bật", en: "Manual Guard mode enabled"),
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
      ko: "Alarm은 반복되지 않습니다.",
      ja: "Alarm は繰り返されません。",
      de: 'Der Alarm wird nicht wiederholt.',
      ru: 'Alarm не будет повторяться.',

      es: "La alarma no se repetirá.",
      fr: _fr(
        vi: "Báo động không lặp lại.",
        en: "The alarm will not repeat.",
      ),
    )
        : choose(
      vi: "Báo động lặp sau $securityModeRepeatMinutes phút nếu sự cố vẫn còn.",
      en: "The alarm repeats after $securityModeRepeatMinutes minutes if the issue remains.",
      zh: "如果问题仍然存在，警报将在 $securityModeRepeatMinutes 分钟后重复。",
      ko: "문제가 계속되면 $securityModeRepeatMinutes분 후 Alarm이 반복됩니다.",
      ja: "問題が残っている場合、$securityModeRepeatMinutes 分後に Alarm が繰り返されます。",
      de: 'Der Alarm wird nach $securityModeRepeatMinutes Minuten wiederholt, wenn das Problem weiter besteht.',
      ru: 'Alarm повторится через $securityModeRepeatMinutes минут, если проблема останется.',

      es: "La alarma se repetirá después de $securityModeRepeatMinutes minutos si el problema continúa.",
      fr: _fr(
        vi: "Báo động lặp sau $securityModeRepeatMinutes phút nếu sự cố vẫn còn.",
        en: "The alarm repeats after $securityModeRepeatMinutes minutes if the issue remains.",
      ),
    );

    return choose(
      vi: "$actorName đã bật Mode Bảo vệ thủ công cho \"$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. $repeatMessage",
      en: "$actorName turned on Manual Guard mode for \"$homeName\". This mode only turns off when a permitted member switches back to Normal. $repeatMessage",
      zh: "$actorName 已为“$homeName”开启手动保护模式。只有具备权限的成员主动切换回普通模式时，此模式才会关闭。$repeatMessage",
      ko: "$actorName님이 \"$homeName\"에 수동 보호 모드를 켰습니다. 권한이 있는 구성원이 Normal로 직접 전환해야 이 모드가 꺼집니다. $repeatMessage",
      ja: "$actorName が「$homeName」で手動Guardモードをオンにしました。このモードは、権限のあるメンバーがNormalに戻した場合にのみオフになります。$repeatMessage",
      de: '$actorName hat den manuellen Schutzmodus für "$homeName" aktiviert. Dieser Modus wird nur deaktiviert, wenn ein berechtigtes Mitglied zurück in den Normalmodus wechselt. $repeatMessage',
      ru: '$actorName включил ручной режим охраны для "$homeName". Этот режим отключается только когда участник с правами переключит обратно в обычный режим. $repeatMessage',

      es: "$actorName activó manualmente el modo protección para «$homeName». Este modo solo se desactiva cuando un miembro con permiso cambia al modo normal. $repeatMessage",
      fr: _fr(
        vi: "$actorName đã bật Mode Bảo vệ thủ công cho \"$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. $repeatMessage",
        en: "$actorName turned on Manual Guard mode for \"$homeName\". This mode only turns off when a permitted member switches back to Normal. $repeatMessage",
      ),
    );
  }

  String alarmSettingChangedTitle(bool enabled) {
    return enabled ? t("Đã bật Alarm") : t("Đã tắt Alarm");
  }

  String alarmSettingChangedMessage({
    required bool enabled,
    required String homeName,
  }) {
    return enabled
        ? choose(
      vi: "Bạn đã bật Alarm cho nhà \"$homeName\".",
      en: "You enabled Alarm for \"$homeName\".",
      zh: "你已为“$homeName”开启 Alarm。",
      ko: "\"$homeName\"의 Alarm을 켰습니다.",
      ja: "「$homeName」の Alarm をオンにしました。",
      de: 'Du hast Alarm für das Zuhause "$homeName" aktiviert.',
      ru: 'Вы включили Alarm для дома "$homeName".',

      es: "Activaste Alarm para \"$homeName\".",
      fr: _fr(
        vi: "Bạn đã bật Alarm cho nhà \"$homeName\".",
        en: "You enabled Alarm for \"$homeName\".",
      ),
    )
        : choose(
      vi: "Bạn đã tắt toàn bộ Alarm của nhà \"$homeName\".",
      en: "You disabled every Alarm for \"$homeName\".",
      zh: "你已关闭“$homeName”的所有 Alarm。",
      ko: "\"$homeName\"의 모든 Alarm을 껐습니다.",
      ja: "「$homeName」のすべての Alarm をオフにしました。",
      de: 'Du hast alle Alarm-Einstellungen für das Zuhause "$homeName" deaktiviert.',
      ru: 'Вы отключили все Alarm для дома "$homeName".',

      es: "Desactivaste todos los Alarm de \"$homeName\".",
      fr: _fr(
        vi: "Bạn đã tắt toàn bộ Alarm của nhà \"$homeName\".",
        en: "You disabled every Alarm for \"$homeName\".",
      ),
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
      en: "$actorName changed $memberName's role from $oldRoleName to $newRoleName in \"$homeName\".",
      zh: "$actorName 已将 $memberName 在“$homeName”中的角色从 $oldRoleName 更改为 $newRoleName。",
      ko: "$actorName님이 \"$homeName\"에서 $memberName님의 역할을 $oldRoleName에서 $newRoleName로 변경했습니다.",
      ja: "$actorName が「$homeName」で $memberName の役割を $oldRoleName から $newRoleName に変更しました。",
      de: '$actorName hat die Rolle von $memberName in "$homeName" von $oldRoleName zu $newRoleName geändert.',
      ru: '$actorName изменил роль $memberName с $oldRoleName на $newRoleName в доме "$homeName".',

      es: "$actorName cambió el rol de $memberName de $oldRoleName a $newRoleName en «$homeName».",
      fr: _fr(
        vi: "$actorName đã đổi vai trò của $memberName từ $oldRoleName thành $newRoleName trong nhà \"$homeName\".",
        en: "$actorName changed $memberName's role from $oldRoleName to $newRoleName in \"$homeName\".",
      ),
    );
  }

  String unreadChatNotice(int count) => choose(
    vi: "Còn $count tin nhắn chưa đọc",
    en: "$count unread messages",
    zh: "还有 $count 条未读消息",
    ko: "읽지 않은 메시지 $count개",
    ja: "未読メッセージが $count 件あります",
    de: '$count ungelesene Nachrichten',
    ru: '$count непрочитанных сообщений',

    es: "$count mensajes sin leer",
    fr: _fr(vi: "Còn $count tin nhắn chưa đọc", en: "$count unread messages"),
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
    zh: "正在监测以自动开启保护模式。",
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
    zh: "使用位置在所有人离家时自动开启保护模式。",
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
          de: 'SOS-ALARM',
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
          de: 'GASLECK-ALARM',
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
          de: 'TÜR-ALARM',
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
    de: 'ALARM STOPPEN',
    ru: 'ОСТАНОВИТЬ ТРЕВОГУ',

    es: "DETENER ALERTA",
    fr: _fr(vi: "TẮT CẢNH BÁO", en: "STOP ALERT"),
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
    en: "$count new messages",
    zh: "$count 条新消息",
    ko: "새 메시지 $count개",
    ja: "新着メッセージが $count 件あります",
    de: '$count neue Nachrichten',
    ru: '$count новых сообщений',

    es: "$count mensajes nuevos",
    fr: _fr(vi: "$count tin nhắn mới", en: "$count new messages"),
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
    en: "New message in $homeName",
    zh: "$homeName 有新消息",
    ko: "$homeName의 새 메시지",
    ja: "$homeName に新着メッセージ",
    de: 'Neue Nachricht in $homeName',
    ru: 'Новое сообщение в $homeName',
    fr: "Nouveau message dans $homeName",
    es: "Mensaje nuevo en $homeName",
  );

  String homeChatSenderMessage(String senderName) => choose(
    vi: "$senderName đã gửi một tin nhắn",
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
    en: "$name is typing...",
    zh: "$name 正在输入...",
    ko: "$name님이 입력 중...",
    ja: "$name が入力中...",
    de: '$name schreibt...',
    ru: '$name печатает...',
    fr: "$name est en train d'écrire...",
    es: "$name está escribiendo...",
  );

  String chatTypingTwo(String name1, String name2) => choose(
    vi: "$name1 và $name2 đang chuẩn bị gửi tin...",
    en: "$name1 and $name2 are typing...",
    zh: "$name1 和 $name2 正在输入...",
    ko: "$name1님과 $name2님이 입력 중...",
    ja: "$name1 と $name2 が入力中...",
    de: '$name1 und $name2 schreiben...',
    ru: '$name1 и $name2 печатают...',
    fr: "$name1 et $name2 sont en train d'écrire...",
    es: "$name1 y $name2 están escribiendo...",
  );

  String chatTypingMany(String name, int otherCount) => choose(
    vi: "$name và $otherCount người khác đang chuẩn bị gửi tin...",
    en: "$name and $otherCount others are typing...",
    zh: "$name 和另外 $otherCount 人正在输入...",
    ko: "$name님 외 $otherCount명이 입력 중...",
    ja: "$name と他 $otherCount 人が入力中...",
    de: '$name und $otherCount weitere schreiben...',
    ru: '$name и еще $otherCount печатают...',
    fr: "$name et $otherCount autres sont en train d'écrire...",
    es: "$name y $otherCount más están escribiendo...",
  );

  String androidLegacyAlarmChannelDescription() => choose(
    vi: "Kênh Alarm cũ để giữ tương thích",
    en: "Legacy Alarm channel kept for compatibility",
    zh: "为保持兼容而保留的旧 Alarm 通道",
    ko: "호환성을 위해 유지되는 기존 Alarm 채널",
    ja: "互換性のために保持される旧 Alarm チャンネル",
    de: 'Alter Alarm-Kanal zur Kompatibilität',
    ru: 'Устаревший канал Alarm для совместимости',
    es: "Canal de Alarm antiguo conservado por compatibilidad",
    fr: _fr(
      vi: "Kênh Alarm cũ để giữ tương thích",
      en: "Legacy Alarm channel kept for compatibility",
    ),
  );

  String androidAlarmFullscreenChannelName() => choose(
    vi: "SafeHome Alarm toàn màn hình",
    en: "SafeHome Alarm Fullscreen",
    zh: "SafeHome Alarm 全屏",
    ko: "SafeHome Alarm 전체 화면",
    ja: "SafeHome Alarm フルスクリーン",
    de: 'SafeHome Alarm Vollbild',
    ru: 'SafeHome Alarm на весь экран',
    es: "SafeHome Alarm pantalla completa",
    fr: _fr(
      vi: "SafeHome Alarm toàn màn hình",
      en: "SafeHome Alarm Fullscreen",
    ),
  );

  String androidAlarmFullscreenChannelDescription() => choose(
    vi: "Mở cảnh báo toàn màn hình; âm còi phát từ trang Alarm",
    en: "Opens fullscreen alarms; siren sound plays from the Alarm page",
    zh: "打开全屏警报；警笛声由 Alarm 页面播放",
    ko: "전체 화면 Alarm을 엽니다. 사이렌 소리는 Alarm 페이지에서 재생됩니다",
    ja: "全画面アラームを開き、サイレン音は Alarm ページから再生されます",
    de: 'Öffnet Vollbild-Alarme; der Sirenenton wird auf der Alarm-Seite abgespielt',
    ru: 'Открывает тревоги на весь экран; сирена воспроизводится со страницы Alarm',
    es: "Abre alarmas a pantalla completa; la sirena se reproduce desde la página Alarm",
    fr: _fr(
      vi: "Mở cảnh báo toàn màn hình; âm còi phát từ trang Alarm",
      en: "Opens fullscreen alarms; siren sound plays from the Alarm page",
    ),
  );

  String androidEmergencyPriorityChannelName() => choose(
    vi: "SafeHome cảnh báo khẩn cấp",
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
  );

  String androidEmergencyPriorityChannelDescription() => choose(
    vi: "Cảnh báo khẩn cấp ưu tiên cao trước khi mở toàn màn hình",
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
  );

  String androidScheduleFullscreenChannelName() => choose(
    vi: "SafeHome Reminder toàn màn hình",
    en: "SafeHome Schedule Fullscreen",
    zh: "SafeHome Reminder 全屏",
    ko: "SafeHome Reminder 전체 화면",
    ja: "SafeHome Reminder フルスクリーン",
    de: 'SafeHome Reminder Vollbild',
    ru: 'SafeHome Reminder на весь экран',
    es: "SafeHome Reminder pantalla completa",
    fr: _fr(
      vi: "SafeHome Reminder toàn màn hình",
      en: "SafeHome Schedule Fullscreen",
    ),
  );

  String androidScheduleFullscreenChannelDescription() => choose(
    vi: "Nhắc nhở SafeHome toàn màn hình không âm thanh",
    en: "Silent fullscreen SafeHome Reminder",
    zh: "无声音全屏 SafeHome Reminder",
    ko: "무음 전체 화면 SafeHome Reminder",
    ja: "音なしの全画面 SafeHome Reminder",
    de: 'Stummer SafeHome Reminder im Vollbild',
    ru: 'Беззвучный SafeHome Reminder на весь экран',
    es: "Reminder de SafeHome a pantalla completa sin sonido",
    fr: _fr(
      vi: "Nhắc nhở SafeHome toàn màn hình không âm thanh",
      en: "Silent fullscreen SafeHome Reminder",
    ),
  );

  String androidReminderPriorityChannelName() => choose(
    vi: "SafeHome Reminder ưu tiên cao",
    en: "SafeHome Reminder Priority",
    zh: "SafeHome Reminder 优先",
    ko: "SafeHome Reminder 우선 알림",
    ja: "SafeHome Reminder 優先通知",
    de: 'SafeHome Reminder Priorität',
    ru: 'SafeHome Reminder с приоритетом',
    es: "SafeHome Reminder prioritario",
    fr: _fr(
      vi: "SafeHome Reminder ưu tiên cao",
      en: "SafeHome Reminder Priority",
    ),
  );

  String androidReminderPriorityChannelDescription() => choose(
    vi: "Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình",
    en: "High-priority SafeHome Reminder without fullscreen",
    zh: "高优先级 SafeHome Reminder，不打开全屏",
    ko: "전체 화면 없이 높은 우선순위 SafeHome Reminder",
    ja: "全画面を開かない高優先度の SafeHome Reminder",
    de: 'SafeHome Reminder mit hoher Priorität ohne Vollbild',
    ru: 'SafeHome Reminder высокого приоритета без полноэкранного режима',
    es: "Reminder de SafeHome de alta prioridad sin pantalla completa",
    fr: _fr(
      vi: "Nhắc nhở SafeHome ưu tiên cao, không mở toàn màn hình",
      en: "High-priority SafeHome Reminder without fullscreen",
    ),
  );

  String androidHomeChatChannelDescription() => choose(
    vi: "Tin nhắn mới trong các nhà SafeHome",
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
  );

  String homeSecurityRepeatToast(int minutes) {
    return minutes == 0
        ? choose(
      vi: "Mode Bảo vệ sẽ chỉ báo động một lần",
      en: "Guard mode will alert only once",
      zh: "保护模式只会警报一次",
      ko: "보호 모드는 한 번만 경보를 보냅니다",
      ja: "Guardモードは一度だけアラートします",
      de: 'Der Schutzmodus alarmiert nur einmal',
      ru: 'Режим охраны подаст тревогу только один раз',

      es: "El modo protección alertará solo una vez",
      fr: _fr(
        vi: "Mode Bảo vệ sẽ chỉ báo động một lần",
        en: "Guard mode will alert only once",
      ),
    )
        : choose(
      vi: "Mode Bảo vệ sẽ lặp báo động sau $minutes phút",
      en: "Guard mode will repeat the alert after $minutes minutes",
      zh: "保护模式将在 $minutes 分钟后重复警报",
      ko: "보호 모드는 $minutes분 후 경보를 반복합니다",
      ja: "Guardモードは $minutes 分後にアラートを繰り返します",
      de: 'Der Schutzmodus wiederholt den Alarm nach $minutes Minuten',
      ru: 'Режим охраны повторит тревогу через $minutes минут',

      es: "El modo protección repetirá la alerta después de $minutes minutos",
      fr: _fr(
        vi: "Mode Bảo vệ sẽ lặp báo động sau $minutes phút",
        en: "Guard mode will repeat the alert after $minutes minutes",
      ),
    );
  }

  String joinRequestsSentMessage(int count) => choose(
    vi: "Đã gửi yêu cầu gia nhập $count nhà",
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
  );

  String joinRequestMessage({
    required String requesterName,
    required String homeName,
  }) => choose(
    vi: "$requesterName đang xin gia nhập nhà \"$homeName\".",
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
  );

  String homeDeletedMessage(String homeName) => choose(
    vi: "Bạn đã xoá nhà \"$homeName\".",
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
  );

  String ownershipTransferRequestSentMessage({
    required String homeName,
    required String email,
  }) => choose(
    vi: "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"$homeName\" cho $email.",
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
  );

  String ownershipTransferRequestMessage({
    required String actorName,
    required String homeName,
  }) => choose(
    vi: "$actorName muốn chuyển quyền chủ nhà \"$homeName\" cho bạn.",
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
  );

  String shareInvitationMessage({
    required String actorName,
    required String homeName,
  }) => choose(
    vi: "$actorName đã mời bạn tham gia nhà \"$homeName\".",
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
  );

  String deviceDeleteInProgressMessage({
    required String deviceName,
    required String homeName,
  }) => choose(
    vi: "SafeHome đang xoá thiết bị \"$deviceName\" khỏi nhà \"$homeName\".",
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
  );

  String deviceAddedMessage({
    required String deviceName,
    required String homeName,
  }) => choose(
    vi: "Thiết bị \"$deviceName\" đã xuất hiện trong \"$homeName\".",
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
  );

  String homeCreatedMessage(String name) => choose(
    vi: "Bạn đã tạo nhà \"$name\".",
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
        en: "$actorName updated the home name to \"$newName\" and changed its address.",
        zh: "$actorName 已将家庭名称更新为“$newName”并更改了地址。",
        ko: "$actorName님이 집 이름을 \"$newName\"(으)로 업데이트하고 주소를 변경했습니다.",
        ja: "$actorName が家の名前を「$newName」に更新し、住所を変更しました。",
        de: '$actorName hat den Namen des Zuhauses zu "$newName" aktualisiert und die Adresse geändert.',
        ru: '$actorName обновил имя дома на "$newName" и изменил адрес.',

        es: "$actorName actualizó la información de «$newName».",
        fr: _fr(
          vi: "$actorName đã cập nhật tên nhà thành \"$newName\" và thay đổi địa chỉ.",
          en: "$actorName updated the home name to \"$newName\" and changed its address.",
        ),
      );
    }

    if (nameChanged) {
      return choose(
        vi: "$actorName đã đổi tên nhà thành \"$newName\".",
        en: "$actorName renamed the home to \"$newName\".",
        zh: "$actorName 已将家庭名称改为“$newName”。",
        ko: "$actorName님이 집 이름을 \"$newName\"(으)로 변경했습니다.",
        ja: "$actorName が家の名前を「$newName」に変更しました。",
        de: '$actorName hat das Zuhause in "$newName" umbenannt.',
        ru: '$actorName переименовал дом в "$newName".',

        es: "$actorName cambió el nombre de la casa a «$newName».",
        fr: _fr(
          vi: "$actorName đã đổi tên nhà thành \"$newName\".",
          en: "$actorName renamed the home to \"$newName\".",
        ),
      );
    }

    return choose(
      vi: "$actorName đã cập nhật địa chỉ của nhà \"$newName\".",
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
    );
  }

  String deviceRenamedMessage({
    required String actorName,
    required String oldDeviceName,
    required String newName,
    required String homeName,
  }) => choose(
    vi: "$actorName đã đổi tên thiết bị \"$oldDeviceName\" thành \"$newName\" trong nhà \"$homeName\".",
    en: "$actorName renamed device \"$oldDeviceName\" to \"$newName\" in \"$homeName\".",
    zh: "$actorName 已在“$homeName”中将设备“$oldDeviceName”重命名为“$newName”。",
    ko: "$actorName님이 \"$homeName\"에서 기기 \"$oldDeviceName\"의 이름을 \"$newName\"(으)로 변경했습니다.",
    ja: "$actorName が「$homeName」でデバイス「$oldDeviceName」の名前を「$newName」に変更しました。",
    de: '$actorName hat Gerät "$oldDeviceName" in "$homeName" in "$newName" umbenannt.',
    ru: '$actorName переименовал устройство "$oldDeviceName" в "$newName" в доме "$homeName".',

    es: "$actorName cambió el nombre del dispositivo «$oldDeviceName» a «$newName» en «$homeName».",
    fr: _fr(
      vi: "$actorName đã đổi tên thiết bị \"$oldDeviceName\" thành \"$newName\" trong nhà \"$homeName\".",
      en: "$actorName renamed device \"$oldDeviceName\" to \"$newName\" in \"$homeName\".",
    ),
  );

  String pairingCountdownText(int seconds) => choose(
    vi: "Đang ghép nối: $seconds giây",
    en: "Pairing: $seconds s",
    zh: "正在配对: $seconds 秒",
    ko: "페어링 중: $seconds초",
    ja: "ペアリング中: $seconds 秒",
    de: 'Kopplung: $seconds s',
    ru: 'Сопряжение: $seconds с',

    es: "Emparejando: $seconds s",
    fr: _fr(vi: "Đang ghép nối: $seconds giây", en: "Pairing: $seconds s"),
  );

  String pairingEnabledMessage({
    required String homeName,
    required int seconds,
  }) => choose(
    vi: "Chế độ thêm thiết bị đã được mở trong nhà \"$homeName\" trong $seconds giây.",
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
  );

  String alarmPauseWithinScheduleMessage({
    required String start,
    required String end,
  }) => choose(
    vi: "Khoảng thời gian phải nằm trong khung Alarm ($start → $end)",
    en: "The pause period must be within the Alarm schedule ($start → $end)",
    zh: "暂停时间必须在 Alarm 计划内 ($start → $end)",
    ko: "일시 중지 시간은 Alarm 일정($start → $end) 안에 있어야 합니다",
    ja: "一時停止期間は Alarm スケジュール（$start → $end）内である必要があります",
    de: 'Der Pausenzeitraum muss innerhalb des Alarm-Zeitplans liegen ($start → $end)',
    ru: 'Период паузы должен быть в рамках расписания Alarm ($start → $end)',

    es: "El período de pausa debe estar dentro del horario de Alarm ($start → $end)",
    fr: _fr(
      vi: "Khoảng thời gian phải nằm trong khung Alarm ($start → $end)",
      en: "The pause period must be within the Alarm schedule ($start → $end)",
    ),
  );

  String alarmPauseReminderText() => choose(
    vi:
    'Hành động này sẽ thay đổi thời gian báo động của một số thiết bị hôm nay.\n\n'
        'Báo động của các thiết bị thuộc trường "Nguy hiểm khẩn cấp" và báo động ở chế độ "Bảo vệ" sẽ không bị ảnh hưởng bởi chức năng này.',
    en:
    'This action will change today\'s Alarm time for some devices.\n\n'
        'Alarms from devices in the "Emergency danger" category and alarms in "Guard" mode will not be affected by this feature.',
    zh:
    '此操作将更改部分设备今天的 Alarm 时间。\n\n'
        '“紧急危险”类别中的设备警报，以及“警戒”模式下的警报，不受此功能影响。',
    ko:
    '이 작업은 일부 기기의 오늘 Alarm 시간을 변경합니다.\n\n'
        '"긴급 위험" 항목에 속한 기기의 경보와 "보호" 모드의 경보는 이 기능의 영향을 받지 않습니다.',
    ja:
    'この操作により、一部のデバイスの本日の Alarm 時間が変更されます。\n\n'
        '「緊急の危険」カテゴリに属するデバイスの警報と「警戒」モードの警報は、この機能の影響を受けません。',
    de:
    'Diese Aktion ändert die heutige Alarm-Zeit für einige Geräte.\n\n'
        'Alarme von Geräten in der Kategorie „Akute Gefahr“ sowie Alarme im Modus „Schutz“ werden von dieser Funktion nicht beeinflusst.',
    ru:
    'Это действие изменит время Alarm сегодня для некоторых устройств.\n\n'
        'Сигналы устройств из категории «Экстренная опасность» и сигналы в режиме «Охрана» не будут затронуты этой функцией.',
    fr:
    'Cette action modifiera aujourd\'hui l\'heure de l\'Alarm pour certains appareils.\n\n'
        'Les alarmes des appareils de la catégorie « Danger urgent » et les alarmes en mode « Protection » ne seront pas affectées par cette fonction.',
    es:
    'Esta acción cambiará hoy la hora de Alarm de algunos dispositivos.\n\n'
        'Las alarmas de los dispositivos de la categoría «Peligro de emergencia» y las alarmas en modo «Protección» no se verán afectadas por esta función.',
  );

  String firebaseRulesPassedSummary({
    required int passCount,
    required int total,
  }) => choose(
    vi: "$passCount/$total bài test đạt\n\n",
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
  );

  String memberPhoneMissingProfileMessage(String name) => choose(
    vi: "$name chưa cập nhật số điện thoại trong hồ sơ.",
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
  );

  String newChatInHomeTitle(String homeName) => choose(
    vi: "Tin nhắn mới trong $homeName",
    en: "New message in $homeName",
    zh: "$homeName 有新消息",
    ko: "$homeName 새 메시지",
    ja: "$homeName に新しいメッセージがあります",
    de: 'Neue Nachricht in $homeName',
    ru: 'Новое сообщение в $homeName',

    es: "Mensaje nuevo en $homeName",
    fr: _fr(vi: "Tin nhắn mới trong $homeName", en: "New message in $homeName"),
  );

  String searchResultCountText({required int current, required int total}) =>
      choose(
        vi: "$current/$total kết quả",
        en: "$current/$total results",
        zh: "$current/$total 个结果",
        ko: "$current/$total개 결과",
        ja: "$current/$total 件の結果",
        de: '$current/$total Ergebnisse',
        ru: '$current/$total результатов',

        es: "$current/$total resultados",
        fr: _fr(vi: "$current/$total kết quả", en: "$current/$total results"),
      );

  String replyingToText(String name) => choose(
    vi: "Đang trả lời $name",
    en: "Replying to $name",
    zh: "正在回复 $name",
    ko: "$name님에게 답장 중",
    ja: "$name に返信中",
    de: 'Antwort an $name',
    ru: 'Ответ $name',

    es: "Respondiendo a $name",
    fr: _fr(vi: "Đang trả lời $name", en: "Replying to $name"),
  );

  String deviceSmokeDetectedMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" phát hiện khói trong \"$homeName\".",
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
  );

  String deviceReturnedNormalMessage(String name) => choose(
    vi: "\"$name\" đã trở lại trạng thái bình thường.",
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
  );

  String deviceSosTriggeredMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" vừa kích hoạt SOS trong \"$homeName\".",
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
  );

  String deviceSosClearedMessage(String name) => choose(
    vi: "\"$name\" đã hết trạng thái SOS.",
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
  );

  String deviceTamperDetectedMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" báo bị tháo/cạy trong \"$homeName\".",
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
  );

  String deviceTamperClearedMessage(String name) => choose(
    vi: "\"$name\" đã hết cảnh báo tháo/cạy.",
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
  );

  String deviceDoorClosedMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" đã đóng trong \"$homeName\".",
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
  );

  String deviceDoorOpenMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" đang mở trong \"$homeName\".",
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
  );

  String deviceLowBatteryMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" trong \"$homeName\" đang yếu pin.",
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
  );

  String deviceOfflineMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" trong \"$homeName\" đã mất kết nối.",
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
  );

  String deviceOnlineMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" trong \"$homeName\" đã kết nối trở lại.",
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
  );

  String deviceHighTemperatureMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
    en: "\"$name\" recorded a high temperature in \"$homeName\".",
    zh: "“$name”在“$homeName”中记录到高温。",
    ko: "\"$homeName\"의 \"$name\"에서 높은 온도가 기록되었습니다.",
    ja: "「$name」が「$homeName」で高温を記録しました。",
    de: '"$name" hat eine hohe Temperatur in "$homeName" gemessen.',
    ru: '"$name" зафиксировал высокую температуру в "$homeName".',

    es: "\"$name\" recorded a high temperatura in \"$homeName\".",
    fr: _fr(
      vi: "\"$name\" ghi nhận nhiệt độ cao trong \"$homeName\".",
      en: "\"$name\" recorded a high temperature in \"$homeName\".",
    ),
  );

  String deviceHighHumidityMessage({
    required String name,
    required String homeName,
  }) => choose(
    vi: "\"$name\" ghi nhận độ ẩm cao trong \"$homeName\".",
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
    en: "If no one confirms, SafeHome will switch to an emergency call.",
    zh: "如果没有人确认，SafeHome 将转为紧急呼叫。",
    ko: "아무도 확인하지 않으면 SafeHome이 긴급 전화로 전환합니다.",
    ja: "誰も確認しない場合、SafeHome は緊急通話に切り替えます。",
    de: 'Wenn niemand bestätigt, wechselt SafeHome zu einem Notruf.',
    ru: 'Если никто не подтвердит, SafeHome перейдет к экстренному звонку.',

    es: "Si nadie confirma, SafeHome pasará a una llamada de emergencia.",
    fr: _fr(
      vi: "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.",
      en: "If no one confirms, SafeHome will switch to an emergency call.",
    ),
  );

  String alarmRepeatAtText(String time) => choose(
    vi: "Báo lại lúc $time nếu vấn đề chưa được xử lý.",
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
  );

  String alarmRepeatByScheduleText() => choose(
    vi: "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.",
    en: "Alerts again according to the Alarm schedule if the issue has not been handled.",
    zh: "如果问题尚未处理，将按已设置的 Alarm 计划再次提醒。",
    ko: "문제가 처리되지 않으면 설정된 Alarm 일정에 따라 다시 알립니다.",
    ja: "問題が解決されていない場合、設定済みの Alarm スケジュールに従って再度通知します。",
    de: 'Alarmiert erneut gemäß dem eingestellten Alarm-Zeitplan, wenn das Problem nicht behoben wurde.',
    ru: 'Повторит тревогу по расписанию Alarm, если проблема не решена.',

    es: "Volverá a avisar según la programación de Alarm si el problema no se ha resuelto.",
    fr: _fr(
      vi: "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.",
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

    return title.isNotEmpty ? title : t("Thông báo");
  }

  String notificationMessage(
      Map<String, dynamic> item, {
        String homeName = "",
      }) {
    final type = _notificationString(item, "type").toLowerCase();
    final resolvedHomeName = homeName.trim().isNotEmpty
        ? homeName.trim()
        : _firstNotificationString(item, const ["homeName"]);

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
        )
            : choose(
          vi: "\"$deviceName\" đang mở trong \"$resolvedHomeName\".",
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

  static const Map<String, String> _english = {
    "Không tìm thấy người dùng": "User not found",
    "Không đọc được số điện thoại": "Could not read phone number",
    "Tin nhắn quá dài": "Message is too long",
    "Không gửi được tin nhắn": "Could not send message",
    "Bạn không có quyền sửa lịch chung của nhà": "You do not have permission to edit the shared home schedule",
    "Nhà của bạn": "Your home",
    "Tải tin cũ hơn": "Load older messages",
    "Nhà chưa đặt tên": "Unnamed home",
    "Nhà": "Home",
    "Chưa có thông tin": "No information available",
    "Chưa cập nhật": "Not updated",
    "Chủ nhà": "Owner",
    "Nhà được chia sẻ": "Shared home",
    "Địa chỉ": "Address",
    "An ninh ra/vào": "Entry security",
    "Nguy hiểm khẩn cấp": "Emergency hazards",
    "Điều khiển & hạ tầng": "Control & infrastructure",
    "Môi trường": "Environment",
    "Toàn bộ thiết bị SafeHome": "All SafeHome devices",
    "Cửa ra/vào": "Entry door",
    "Cửa": "Door",
    "Cửa sổ": "Window",
    "Cổng": "Gate",
    "Khóa thông minh": "Smart lock",
    "Chuyển động": "Motion",
    "Hiện diện": "Presence",
    "Rung/chấn động": "Vibration",
    "Kính vỡ": "Glass break",
    "Báo khói": "Smoke alarm",
    "Báo nhiệt": "Heat alarm",
    "Khí CO": "Carbon monoxide",
    "Báo gas": "Gas alarm",
    "Báo ngập/rò nước": "Water leak alarm",
    "Nút SOS": "SOS button",
    "Nhiệt độ/Độ ẩm": "Temperature/Humidity",
    "Bụi mịn PM2.5": "PM2.5 fine dust",
    "CO₂": "CO₂",
    "Chất lượng không khí": "Air quality",
    "Ổ điện thông minh": "Smart plug",
    "Còi báo động": "Siren",
    "Van thông minh": "Smart valve",
    "Camera": "Camera",
    "Chuông cửa": "Doorbell",
    "Bàn phím an ninh": "Security keypad",
    "Bộ mở rộng sóng": "Repeater",
    "Hub trung tâm": "Central Hub",
    "Đo điện năng": "Power monitor",
    "Nguồn dự phòng UPS": "UPS backup power",
    "Thiết bị đang Offline": "Device is offline",
    "Thiết bị đang Online": "Device is online",
    "pin yếu": "low battery",
    "sóng yếu": "weak signal",
    "lâu không phản hồi": "not responding",
    "Kết nối cần kiểm tra": "Connection needs attention",
    "Vừa xong": "Just now",
    "Bị tháo": "Tamper detected",
    "Có khói": "Smoke detected",
    "Bình thường": "Normal",
    "Bảo vệ": "Guard",
    "Chế độ Bảo vệ": "Guard mode",
    "Tự động Bảo vệ khi rời nhà": "Auto Guard when away",
    "Đã kích hoạt": "Activated",
    "Sẵn sàng": "Ready",
    "Đang đóng": "Closed",
    "Đang mở": "Open",
    "Rò rỉ gas": "Gas leak detected",
    "Phát hiện ngập nước": "Water leak detected",
    "Phát hiện chuyển động": "Motion detected",
    "Không có chuyển động": "No motion detected",
    "Phát hiện hiện diện": "Presence detected",
    "Không phát hiện hiện diện": "No presence detected",
    "Phát hiện rung/chấn động": "Vibration detected",
    "Không có rung bất thường": "No unusual vibration",
    "Phát hiện kính vỡ": "Glass break detected",
    "Không có cảnh báo kính vỡ": "No glass-break alert",
    "Nhiệt độ nguy hiểm": "Dangerous heat detected",
    "Phát hiện khí CO": "Carbon monoxide detected",
    "Không phát hiện khí CO": "No carbon monoxide detected",
    "Khóa đang mở": "Unlocked",
    "Khóa đang đóng": "Locked",
    "Đang bật": "On",
    "Đang tắt": "Off",
    "Đang theo dõi điện năng": "Monitoring power",
    "Đang dùng nguồn dự phòng": "Running on backup power",
    "Nguồn điện bình thường": "Mains power normal",
    "Còi đang bật": "Siren active",
    "Còi sẵn sàng": "Siren ready",
    "Van đang mở": "Valve open",
    "Van đã đóng": "Valve closed",
    "Đang hoạt động": "Operating",
    "Đang theo dõi": "Monitoring",
    "Chưa nhận diện": "Unrecognized device",
    "Chưa có cập nhật": "No updates yet",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh": "No devices yet. Tap + to add one and start protecting your home.",
    "CHƯA AN TOÀN": "UNSAFE",
    "CẦN CHÚ Ý": "NEEDS ATTENTION",
    "ĐÃ AN TOÀN": "SAFE",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.": "Your home needs attention. Review the statuses below.",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "Your home is operating normally.",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "No unusual smoke or SOS activity detected.",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "There is not enough recent activity for a deeper analysis.",
    "Hub kết nối bình thường": "Hub connected",
    "Cài đặt cảnh báo cho nhà hiện tại": "Alert settings for this home",
    "Nhận cảnh báo Alarm": "Receive Alarm alerts",
    "Đang bật cho tài khoản này": "Enabled for this account",
    "Đang tắt cho tài khoản này": "Disabled for this account",
    "Hẹn giờ Reminder": "Reminder schedule",
    "Nhắc kiểm tra nhà theo thời gian": "Schedule home check reminders",
    "Hẹn giờ Alarm": "Schedule Alarm",
    "Chưa thiết lập": "Not set",
    "Chưa thiết lập thời gian": "No schedule configured",
    "Tổng hợp trạng thái nhà": "Home status summary",
    "Cần xử lý ngay": "Action required",
    "Cần kiểm tra": "Needs attention",
    "Đánh giá tự động": "Automated assessment",
    "Tự động đánh giá": "Automatic assessment",
    "Tổng quan hôm nay": "Today overview",
    "Chưa có dữ liệu tổng quan": "No overview data yet",
    "Chưa có dữ liệu trạng thái": "No status data yet",
    "Chưa đủ dữ liệu để đánh giá": "Not enough data to evaluate",
    "Chưa có dữ liệu để đánh giá": "Not enough data to evaluate",
    "Bấm vào để xem chi tiết": "Tap to view details",
    "Nhấn để xem chi tiết...": "Tap to view details...",
    "Tạm dừng": "Paused",
    "Tắt": "Off",
    "Chi tiết": "Details",
    "Tổng hợp trạng thái": "Status summary",
    "Không an toàn": "Unsafe",
    "Cần chú ý": "Needs attention",
    "An toàn": "Safe",
    "Không có": "None",
    "Đổi tên nhóm": "Rename group",
    "Huỷ": "Cancel",
    "Hủy": "Cancel",
    "Lưu": "Save",
    "Thêm": "Add",
    "Xoá": "Delete",
    "Đổi tên": "Rename",
    "Nhà của tôi": "My homes",
    "Bỏ chọn toàn bộ nhóm": "Deselect entire group",
    "Chọn toàn bộ nhóm": "Select entire group",
    "Bỏ chọn": "Deselect",
    "Quay lại": "Back",
    "Tìm kiếm": "Search",
    "Đóng tìm kiếm": "Close search",
    "Giờ": "Hour",
    "Phút": "Minute",
    "Đặt Home Reminder": "Set Home Reminder",
    "Đặt Home Alarm": "Set Home Alarm",
    "Xác nhận thay đổi": "Confirm changes",
    "Tiếp tục": "Continue",
    "Giờ Reminder": "Reminder time",
    "Giờ bắt đầu Alarm": "Alarm start time",
    "Giờ kết thúc Alarm": "Alarm end time",
    "Không có nhà nào đủ điều kiện để cài": "No eligible homes were found",
    "Cài đặt hoàn tất": "Setup complete",
    "Xác nhận rời nhà": "Confirm leaving home",
    "Xác nhận xoá nhà": "Confirm home deletion",
    "Nhập mật khẩu": "Enter password",
    "Mật khẩu tài khoản": "Account password",
    "Rời khỏi nhà": "Leave home",
    "Xoá nhà": "Delete home",
    "Sai mật khẩu": "Incorrect password",
    "Đã rời khỏi home": "Left home",
    "Đã cập nhật": "Updated",
    "Tìm home...": "Search homes...",
    "Đặt vị trí nhà và bật bảo vệ tự động": "Set home location and enable automatic protection",
    "Chuyển quyền chủ nhà hoặc xoá nhà": "Transfer home ownership or delete home",
    "Đặt Reminder / Alarm nhà đã chọn": "Set Reminder / Alarm for selected homes",
    "Chia sẻ nhà đã chọn": "Share selected homes",
    "Mở danh sách chia sẻ nhà": "Open home sharing list",
    "Xoá các nhà đã chọn?": "Delete selected homes?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "Selected homes will be permanently deleted.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn": "Or scan a QR code to request access to selected homes",
    "Email người nhận": "Recipient email",
    "Chia sẻ": "Share",
    "Email chưa đăng ký": "Email is not registered",
    "Chia sẻ hoàn tất": "Sharing complete",
    "Mở List chia sẻ nhà": "Open home sharing list",
    "Không có nhà nào bạn có quyền quản lý": "You do not manage any selected homes",
    "Chưa share cho ai": "Not shared with anyone yet",
    "Tìm nhà": "Search homes",
    "Xoá các nhà đã chọn ?": "Delete selected homes?",
    "Thông báo Home": "Home notifications",
    "Thông báo nhà": "Home notifications",
    "Vai trò thành viên đã thay đổi": "Member role changed",
    "Xoá tất cả thông báo?": "Delete all notifications?",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "All home notifications will be deleted.",
    "Chưa có thông báo nào": "No notifications yet",
    "Chưa có thông báo": "No notifications",
    "Vuốt lên để tải thêm": "Swipe up to load more",
    "Không có thiết bị": "No devices",
    "Chỉ chủ nhà mới được xoá nhà": "Only the owner can delete this home",
    "Chỉ chủ nhà mới được chuyển quyền": "Only the owner can transfer ownership",
    "Lưu ý khi bật Alarm": "Alarm notice",
    "Alarm đã được bật": "Alarm enabled",
    "Đã hiểu": "Got it",
    "Lưu ý tạm tắt Alarm": "Alarm pause note",
    "Đã bật Alarm": "Alarm enabled",
    "Đã tắt Alarm": "Alarm disabled",
    "Tắt Alarm": "Turn off Alarm",
    "Cả ngày": "All day",
    "Bạn không có quyền thực hiện thao tác này.": "You don't have permission to perform this action.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.": "Couldn't complete the action. Please try again.",
    "QR gia nhập nhiều nhà không hợp lệ": "Invalid multi-home join QR code",
    "Bạn đang là chủ các nhà này": "You own these homes",
    "Một người dùng": "A user",
    "Yêu cầu gia nhập nhà": "Home join request",
    "Đã gửi yêu cầu gia nhập nhà": "Join request sent",
    "QR gia nhập không hợp lệ": "Invalid join QR code",
    "Bạn đang là chủ nhà này": "You already own this home",
    "QR này không phải mã xin gia nhập nhà": "This QR code is not a home join code",
    "Bạn không có quyền thêm thiết bị": "You do not have permission to add devices",
    "Đã mở chế độ thêm thiết bị": "Device pairing enabled",
    "Rời khỏi Home này?": "Leave this home?",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.": "This home and all its devices will be permanently deleted.",
    "Đã xoá nhà": "Home deleted",
    "QR của nhà này": "Home QR code",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.": "Others can scan this code to request access to the home.",
    "Chia sẻ nhà": "Share home",
    "Quét QR để xin gia nhập nhà": "Scan QR to join a home",
    "Quét QR xin gia nhập nhà": "Scan QR to join home",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "Place the shared home QR code inside the frame",
    "Mã QR này do chủ nhà chia sẻ":
    "This QR code is shared by the home owner",
    "Nhập mã mời": "Enter invitation code",
    "Gửi yêu cầu gia nhập": "Send join request",
    "QR này không phải mã thiết bị": "This QR code is not a device code",
    "Xin gia nhập nhà": "Request to join home",
    "Quét mã QR chia sẻ nhà": "Scan a home sharing QR code",
    "Mời thành viên bằng mã QR": "Invite member with QR code",
    "Không thể share cho chính bạn": "You cannot share with yourself",
    "Lời mời chia sẻ nhà": "Home sharing invitation",
    "Đã share home": "Home shared",
    "Chuyển quyền chủ nhà": "Transfer ownership",
    "Không thể chuyển quyền cho chính bạn": "You cannot transfer ownership to yourself",
    "Không tìm thấy user": "User not found",
    "Không tìm thấy tài khoản": "Account not found",
    "Xác nhận chuyển quyền": "Confirm ownership transfer",
    "Chuyển": "Transfer",
    "Xác nhận mật khẩu": "Confirm password",
    "Xác nhận": "Confirm",
    "Yêu cầu chuyển quyền chủ nhà": "Ownership transfer request",
    "Đã gửi yêu cầu chuyển quyền": "Transfer request sent",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "Ownership transfer request sent",
    "Bạn không có quyền xoá thiết bị": "You do not have permission to delete devices",
    "Xóa Device?": "Delete this device?",
    "Đã gửi yêu cầu xoá thiết bị": "Device deletion request sent",
    "Đang xoá thiết bị": "Deleting device",
    "Đăng xuất?": "Log out?",
    "Thêm nhà": "Add home",
    "Thêm nhà mới": "Add new home",
    "Tạo nhà mới": "Create new home",
    "Tạo một ngôi nhà mới của bạn": "Create a new home",
    "Quét mã QR được chủ nhà chia sẻ": "Scan the QR code shared by the homeowner",
    "Tên nhà": "Home name",
    "Số điện thoại": "Phone number",
    "Nam": "Male",
    "Nữ": "Female",
    "Ngày": "Day",
    "Tháng": "Month",
    "Năm": "Year",
    "Thông tin cá nhân": "Personal information",
    "Thiết lập tài khoản": "Set up account",
    "Vui lòng nhập đủ thông tin": "Please enter all required information",
    "Không thể lưu thông tin": "Could not save information",
    "Đã lưu thông tin": "Information saved",
    "Lỗi lưu profile": "Could not save profile",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp": "Add a phone number for emergencies",
    "Hoàn tất": "Done",
    "Đã tạo nhà mới": "Home created",
    "Về muộn": "Back late",
    "Ra ngoài": "Going out",
    "Khác": "Other",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ Pause Alarm today",
    "Chọn giờ bắt đầu tạm tắt": "Choose pause start time",
    "Từ": "From",
    "Từ giờ": "From",
    "Chọn giờ kết thúc tạm tắt": "Choose pause end time",
    "Đến": "To",
    "Đến giờ": "Until",
    "Xoá lịch tạm tắt": "Delete pause schedule",
    "Xóa lịch tạm tắt": "Delete pause schedule",
    "Giới tính": "Gender",
    "SĐT": "Phone",
    "Ngày sinh": "Date of birth",
    "Yêu cầu & lời mời": "Requests & invitations",
    "Xem lời mời chia sẻ và xin gia nhập": "View sharing invitations and join requests",
    "Cài đặt bảo mật": "Security settings",
    "Quyền báo động toàn màn hình": "Full-screen alarm permission",
    "Báo động toàn màn hình": "Full-screen alarm",
    "Đã được cấp quyền": "Permission granted",
    "Chưa được cấp quyền": "Permission not granted",
    "Mở cài đặt hệ thống": "Open system settings",
    "Đăng xuất": "Log out",
    "Thoát tài khoản khỏi thiết bị này": "Sign out of this device",
    "Không có yêu cầu hoặc lời mời nào": "No requests or invitations",
    "Xoá tài khoản": "Delete account",
    "Hành động này sẽ xoá toàn bộ dữ liệu:": "This will delete all data:",
    "Nhà và thiết bị": "Homes and devices",
    "Chia sẻ và quyền truy cập": "Sharing and access",
    "Toàn bộ dữ liệu liên quan": "All related data",
    "Mật khẩu xác nhận": "Confirmation password",
    "Đã xoá tài khoản": "Account deleted",
    "Xoá thất bại": "Delete failed",
    "Lỗi xoá tài khoản": "Could not delete account",
    "Tình trạng": "Status",
    "Tháo/Lắp": "Tamper",
    "Pin": "Battery",
    "Tín hiệu": "Signal",
    "Chưa liên kết": "Not linked",
    "Liên lạc cuối": "Last contact",
    "Event cuối": "Last event",
    "Sự kiện cuối": "Last event",
    "Lần kích hoạt cuối": "Last triggered",
    "Thiết bị không còn tồn tại": "Device no longer exists",
    "Mất kết nối": "Disconnected",
    "Online": "Online",
    "Offline": "Offline",
    "Loại thiết bị": "Device type",
    "Nhiệt độ": "Temperature",
    "Độ ẩm": "Humidity",
    "Công suất": "Power",
    "Điện áp": "Voltage",
    "Dòng điện": "Current",
    "Điện năng": "Energy",
    "Cường độ rung": "Vibration strength",
    "Góc nghiêng": "Tilt angle",
    "Độ mở van": "Valve opening",
    "Nguồn dự phòng": "Backup power",
    "Ngập/rò nước": "Water leak",
    "Phát hiện khói": "Smoke detected",
    "Quản lý phòng": "Room management",
    "Bạn không có quyền quản lý phòng": "You don't have permission to manage rooms",
    "Đổi tên phòng": "Rename room",
    "Tên phòng": "Room name",
    "Xoá phòng": "Delete room",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.": "Devices in this room will be moved to Unassigned.",
    "Thêm phòng": "Add room",
    "Ví dụ: Phòng khách": "Example: Living room",
    "Phòng khách": "Living room",
    "Tên phòng đã tồn tại": "Room name already exists",
    "Chưa phân phòng": "Unassigned",
    "Phòng mặc định": "Default room",
    "Phát hiện bất thường": "Abnormal activity detected",
    "Phát hiện cạy phá": "Abnormal activity detected",
    "Tamper detected": "Tamper detected",
    "Tamper cleared": "Tamper normal",
    "Door opened": "Door is open",
    "Door closed": "Door closed",
    "Motion detected": "Motion detected",
    "Battery low": "Low battery",
    "Device offline": "Device offline",
    "Device online": "Device online",
    "Alarm triggered": "Alarm triggered",
    "Alarm cleared": "Alarm cleared",
    "Cửa mở": "Door is open",
    "Cửa đóng": "Door closed",
    "Chưa đặt vị trí nhà": "Home location not set",
    "Đặt vị trí nhà tại đây": "Set home location here",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ": "Set the home location before turning on Auto Guard",
    "Bán kính bảo vệ mặc định: 150 m": "Default protection radius: 150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.": "Each member needs to allow Always location permission so away/home status can work in the background.",
    "Lưu cài đặt": "Save settings",
    "Đã đặt vị trí nhà": "Home location set",
    "Đang lấy vị trí...": "Getting location...",
    "Đang lưu...": "Saving...",
    "Đổi tên hiển thị": "Change display name",
    "Cập nhật thông tin nhà": "Update home information",
    "Nhập địa chỉ của nhà": "Enter the home address",
    "Lưu thay đổi": "Save changes",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.": "This name is only shown on your account.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.": "The name and address will be updated for all home members.",
    "Một thành viên": "A member",
    "Đã cập nhật thông tin nhà": "Home information updated",
    "Thay tên": "Rename",
    "Đã đổi tên thiết bị": "Device renamed",
    "Chưa chọn nhà để kiểm tra": "Select a home to test",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner": "Run this test using the owner account",
    "Không đọc được dữ liệu nhà": "Unable to read home data",
    "Nhà cần có ít nhất một thiết bị để test": "The home needs at least one device for testing",
    "Đóng": "Close",
    "Đã thiết lập": "Set",
    "Quét QR": "Scan QR",
    "Quét QR để thêm thiết bị": "Scan QR to add a device",
    "Nhập HUB ID thủ công": "Enter HUB ID manually",
    "Bạn không có quyền sắp xếp phòng": "You do not have permission to reorder rooms",
    "Cảnh báo khói": "Smoke alert",
    "Cập nhật thiết bị": "Device update",
    "Cửa đang mở": "Door is open",
    "Cửa đã đóng": "Door closed",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: ISSUES FOUND",
    "Firebase Rules: ĐẠT": "Firebase Rules: PASSED",
    "Giờ không hợp lệ": "Invalid time",
    "Khôi phục mật khẩu": "Reset password",
    "Nhập email của bạn": "Enter your email",
    "Gửi": "Send",
    "Đã gửi email khôi phục": "Password reset email sent",
    "Không gửi được email": "Could not send email",
    "Vui lòng nhập email và mật khẩu": "Enter your email and password",
    "Mật khẩu xác nhận không khớp": "Passwords do not match",
    "Không thể tạo tài khoản": "Could not create account",
    "Sai tài khoản": "Incorrect account",
    "Email đã tồn tại": "Email already exists",
    "Mật khẩu quá yếu": "Password is too weak",
    "Sai email hoặc mật khẩu": "Incorrect email or password",
    "Lỗi đăng nhập": "Sign-in error",
    "Email": "Email",
    "Mật khẩu": "Password",
    "Ghi nhớ tài khoản": "Remember account",
    "Đăng nhập": "Log in",
    "Đăng ký mới": "Create account",
    "Quên mật khẩu?": "Forgot password?",
    "Chưa có tài khoản? Đăng ký": "Don't have an account? Sign up",
    "Đã có tài khoản? Đăng nhập": "Already have an account? Log in",
    "Tính năng đang được phát triển": "This feature is under development",
    "Thông báo": "Notifications",
    "Chat trong nhà": "Home chat",
    "Tìm kiếm tin nhắn": "Search messages",
    "Xem thành viên": "View members",
    "Tìm nội dung hoặc tên người gửi": "Search content or sender name",
    "Xoá từ khoá": "Clear keyword",
    "Không có kết quả": "No results",
    "Tìm ngôn ngữ": "Search language",
    "Kết quả trước": "Previous result",
    "Kết quả tiếp theo": "Next result",
    "Chưa có tin nhắn": "No messages yet",
    "Không tìm thấy thành viên phù hợp": "No matching members found",
    "Nhắc đến trong tin nhắn": "Mention in message",
    "Huỷ trả lời": "Cancel reply",
    "Nhắn gì đó...": "Type a message...",
    "Gọi điện": "Call",
    "Alarm thiết bị": "Device Alarm",
    "Chế độ áp dụng": "Apply mode",
    "Theo nhà": "Home schedule",
    "Riêng tôi": "Personal",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập": "Use the shared schedule set by the owner or admin",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn": "Use a personal schedule that only applies to your account",
    "Thiết lập nhanh Alarm": "Quick Alarm setup",
    "Thiết lập nhanh toàn bộ thiết bị": "Quick set all devices",
    "Áp dụng cho toàn bộ thiết bị": "Apply to all devices",
    "Bắt đầu": "Start",
    "Kết thúc": "End",
    "Thời gian lặp lại": "Repeat interval",
    "Không lặp lại": "No repeat",
    "Quét QR HUB": "Scan HUB QR",
    "Đưa mã QR vào giữa khung": "Place the QR code inside the frame",
    "Đang áp dụng...": "Applying...",
    "Hôm nay đã ghi nhận cảnh báo SOS": "An SOS alert was recorded today",
    "Hôm nay đã ghi nhận cảnh báo khói": "A smoke alert was recorded today",
    "Khói đã an toàn": "Smoke condition cleared",
    "Không tìm thấy nhà của thông báo này": "The home for this notification was not found",
    "Không tìm thấy thiết bị trong nhà này": "The device was not found in this home",
    "Một chủ nhà": "A homeowner",
    "Ngôi nhà đang hoạt động ổn định": "The home is operating normally",
    "Nhiệt độ cao": "High temperature",
    "OK": "OK",
    "Pin yếu": "Low battery",
    "SOS đã kết thúc": "SOS cleared",
    "SOS được kích hoạt": "SOS activated",
    "Tamper bình thường": "Tamper normal",
    "Thiết bị bị tháo": "Tamper detected",
    "Thiết bị mới": "New device",
    "Thiết bị offline": "Device offline",
    "Thiết bị online": "Device online",
    "Báo động kích hoạt": "Alarm triggered",
    "Báo động đã tắt": "Alarm cleared",
    "Tạm tắt Alarm hôm nay": "Pause Alarm today",
    "Độ ẩm cao": "High humidity",
    "Thử lại": "Try again",
    "Không thể tải dữ liệu tài khoản": "Could not load account data",
    "Không": "No",
    "Đã chia sẻ nhà thành công.": "Homes shared successfully.",
    "Tìm nhà...": "Search homes...",
    "Đã rời khỏi nhà": "Left home",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.": "You will leave the shared homes.",
    "Các nhà của bạn sẽ bị xoá.\n": "Your homes will be deleted.\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n": "This will change Home Alarm schedules for all security devices in the selected homes.\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n": "This will add a Home Reminder to the selected homes.\n\n",
    "Xác nhận thay đổi Alarm": "Confirm Alarm changes",
    "Xác nhận thay đổi Reminder": "Confirm Reminder changes",
    "Lặp lại khi sự cố vẫn còn": "Repeat while the issue remains",
    "Thời gian lặp lại Alarm": "Alarm repeat time",
    "VD: Mr Chung": "E.g. Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 No homes yet",
    "Vẫn chuyển về Bình thường": "Still switch to Normal",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.": "Auto Guard when away is still enabled. If all members are still away, the system may turn Guard mode back on after a few minutes.",
    "Chuyển về Bình thường?": "Switch to Normal?",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n": "Security devices will be monitored immediately.\n\n",
    "Bật Bảo vệ thủ công?": "Turn on manual Guard mode?",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ": "This action will change the alarm timing for some devices today...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ": "This action will disable every Alarm for this ",
    "Tắt toàn bộ Alarm?": "Turn off all Alarm?",
    "Không xoá được lịch tạm tắt Alarm": "Unable to delete the Alarm pause schedule",
    "Không lưu được tạm tắt Alarm": "Unable to save the Alarm pause",
    "Không gửi được yêu cầu xoá": "Could not send deletion request",
    "Không lưu được cài đặt": "Could not save the setting",
    "Không lấy được vị trí hiện tại": "Could not get the current location",
    "Không thể xác nhận tài khoản hiện tại": "Could not verify the current account",
    "Mật khẩu không đúng": "Incorrect password",
    "Không thể xác nhận mật khẩu": "Could not verify the password",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động": "Only the Owner or an Admin can change the alarm repeat setting",
    "Không lưu được thời gian lặp báo động": "Could not save the alarm repeat time",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "Only the Owner or an Admin can change Guard mode",
    "Không thể thay đổi chế độ nhà": "Could not change the home mode",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "Guard mode is on, but the notification could not be sent",
    "Đã bật Mode Bảo vệ thủ công": "Manual Guard mode enabled",
    "Đã chuyển nhà về Bình thường": "Home switched back to Normal",
    "60 phút": "60 minutes",
    "30 phút": "30 minutes",
    "15 phút": "15 minutes",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.": "You are viewing the owner's schedule. Choose Only me to set your own Alarm schedule.",
    "Chọn giờ kết thúc Alarm": "Choose Alarm end time",
    "Chọn giờ bắt đầu Alarm": "Choose Alarm start time",
    "Bạn không có quyền sửa lịch Alarm của nhà": "You do not have permission to edit this home's Alarm schedule",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị": "Could not apply Alarm to all devices",
    "Nhà chưa có thiết bị an ninh để áp dụng": "This home has no security devices to apply",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.": "You do not have permission to edit Home settings. Choose Only me.",
    "Không thể lưu chế độ Alarm": "Could not save Alarm mode",
    "Thêm Reminder": "Add Reminder",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.": "Reminder will remind you to check your home's safety status at the selected time.",
    "Thêm khung giờ Alarm": "Add Alarm time window",
    "Đang sử dụng Reminder riêng của bạn": "Using your own Reminder settings",
    "Đang sử dụng Reminder của chủ nhà": "Using the owner's Reminder settings",
    "Sửa giờ Reminder": "Edit Reminder time",
    "Sửa giờ kết thúc Alarm": "Edit Alarm end time",
    "Sửa giờ bắt đầu Alarm": "Edit Alarm start time",
    "Xoá Reminder": "Delete Reminder",
    "Mỗi 1 giờ": "Every hour",
    "Mỗi 30 phút": "Every 30 minutes",
    "Mỗi 15 phút": "Every 15 minutes",
    "Không báo lại": "Do not repeat",
    "Báo lại khi vẫn chưa an toàn": "Repeat while still unsafe",
    "Báo lại mỗi 1 giờ": "Repeat every hour",
    "Báo lại mỗi 30 phút": "Repeat every 30 minutes",
    "Báo lại mỗi 15 phút": "Repeat every 15 minutes",
    "Quản lý nhà": "Home management",
    "Xoá thành viên": "Remove member",
    "Đã xoá thành viên": "Member removed",
    "Đồng ý": "OK",
    "Bạn chắc chắn muốn rời khỏi nhà này?": "Are you sure you want to leave this home?",
    "Xoá thành viên?": "Remove member?",
    "Rời khỏi nhà?": "Leave this home?",
    "Chỉ chủ nhà mới được thay đổi vai trò": "Only the owner can change roles",
    "Bạn không có quyền xoá thành viên này": "You do not have permission to remove this member",
    "Bạn": "You",
    "Không có email": "No email",
    "Chưa có số điện thoại": "No phone number",
    "Không mở được ứng dụng gọi điện": "Could not open the phone app",
    "Thành viên chưa cập nhật số điện thoại": "This member has not added a phone number",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "Manual Guard mode is on - switch to Normal to turn it off",
    "Thời gian lặp": "Repeat interval",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "Choose 0 to alert once. This setting applies to manual Guard mode and Auto Guard when away.",
    "Lặp báo động khi sự cố vẫn còn": "Repeat Alarm while the issue remains",
    "Đang được sử dụng": "Currently active",
    "Chuyển về sử dụng thông thường": "Switch back to normal use",
    "Chế độ nhà": "Home mode",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "The SOS device has not recorded an alert.",
    "Cảm biến khói chưa ghi nhận bất thường.": "The smoke sensor has not detected an issue.",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.": "You or a member manually turned on Guard.",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.": "SafeHome turned on Guard automatically because you left home.",
    "Nhà đang ở chế độ dùng bình thường.": "This home is currently in normal use.",
    "Bảo vệ thủ công đang bật": "Manual Guard is on",
    "Bảo vệ tự động đang bật": "Auto Guard is on",
    "Bảo vệ đang tắt": "Guard mode is off",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.": "You have opened the app recently to check status.",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.": "Open the app regularly to review permissions, schedules, and unread alerts.",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.": "After a few sessions, SafeHome can evaluate your app-check habit better.",
    "Tần suất vào app ổn": "App check frequency looks good",
    "Đã lâu chưa vào app kiểm tra": "It has been a while since the last app check",
    "Đang ghi nhận tần suất vào app": "App check frequency is being recorded",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.": "Check Always location permission and background conditions.",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.": "This device meets the requirements for Auto Away.",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.": "Enable it if you want Guard mode to turn on automatically when you leave.",
    "Auto rời khỏi nhà chưa ổn": "Auto Away is not ready",
    "Auto rời khỏi nhà đã sẵn sàng": "Auto Away is ready",
    "Auto rời khỏi nhà chưa bật": "Auto Away is not enabled",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.": "Add a smoke sensor, SOS, or emergency device suitable for your home.",
    "Chưa có thiết bị khẩn cấp": "No emergency device yet",
    "Đã có thiết bị khẩn cấp": "Emergency devices are added",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.": "Set an Alarm schedule for sleeping time or when you are away.",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.": "This home has an Alarm schedule or device-level alert schedule.",
    "Chưa set lịch Alarm": "Alarm schedule is not set",
    "Đã set lịch Alarm": "Alarm schedule is set",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.": "Set at least one Reminder so you do not forget to check your home.",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.": "The app will remind you to check your home on schedule.",
    "Chưa setup Reminder": "Reminder is not set up",
    "Đã setup Reminder": "Reminder is set up",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.": "Reopen the app or sign in again if this device does not receive alerts.",
    "Thiết bị chưa đăng ký nhận cảnh báo": "This device is not registered for alerts",
    "Thiết bị nhận cảnh báo bình thường": "This device can receive alerts",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.": "iOS controls background use more strictly than Android; keep notifications and Always location on if using Auto Away.",
    "Cơ chế iOS": "iOS behavior",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.": "Check background permission and auto-start so alerts are not delayed.",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.": "The device has confirmed the important background conditions.",
    "Cần kiểm tra chạy nền / tự khởi động": "Check background use / auto-start",
    "Chạy nền ổn định": "Background use looks stable",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "Some Android phones may delay alerts while battery optimization is on.",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.": "The phone is less likely to delay SafeHome alerts.",
    "Chưa tắt tối ưu pin": "Battery optimization is still enabled",
    "Tối ưu pin không chặn app": "Battery optimization is not blocking the app",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.": "Auto Away needs Always location to work reliably.",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.": "Location permission is required for Auto Away.",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.": "Location service is off, so Auto Away may not work reliably.",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.": "This is only required when using Auto Away.",
    "Chưa cấp vị trí luôn luôn": "Always location is not allowed",
    "Đã cấp vị trí luôn luôn": "Always location is allowed",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.": "iOS does not open full-screen like Android; the app uses system notifications and sound.",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.": "Android uses full-screen alerts; allow it in settings if the phone blocks it.",
    "Cảnh báo trên iOS": "Alerts on iOS",
    "Cảnh báo toàn màn hình": "Full-screen alerts",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "Alerts may not appear if notifications are disabled.",
    "Điện thoại có thể nhận thông báo SafeHome.": "This phone can receive SafeHome notifications.",
    "Chưa bật thông báo": "Notifications are not enabled",
    "Đã bật thông báo": "Notifications are enabled",
    "Hệ thống: Sẵn sàng": "System: Ready",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "System: Alerts may be missed",
    "Cách bạn đang dùng app": "How you use the app",
    "Thiết bị của bạn": "Your device",
    "Kiểm tra điện thoại và cách bạn đang dùng app.": "Checks your phone and how you use the app.",
    "Hệ thống SafeHome": "SafeHome System",
    "Hệ thống: Đang kiểm tra...": "System: Checking...",
    "Tên": "Name",
    "Bạn không có quyền thay đổi vị trí nhà": "You don't have permission to change the home location",
    "Hãy bật GPS để đặt vị trí nhà": "Turn on GPS to set the home location",
    "Bạn chưa cấp quyền vị trí": "Location permission has not been granted",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng": "Grant location permission in the app settings",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà": "Auto Guard when everyone leaves home is enabled",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà": "Auto Guard when everyone leaves home is disabled",
    "Không thể thay đổi trạng thái Alarm": "Could not change Alarm status",
    "Đã tắt toàn bộ Alarm của nhà": "All home Alarms have been turned off",
    "QR này không phải mã xin gia nhập Home": "This QR code is not a Home join code",
    "Thêm Home": "Add Home",
    "Mở cài đặt": "Open settings",
    "Để sau": "Later",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.": "SafeHome needs always-on location permission to detect when you leave or return home, including while the app is in the background.",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.": "SafeHome can currently access location only while the app is in use.\n\nOpen Location permission and select \"Allow all the time\" so automatic protection continues working in the background.",
    "Cho phép vị trí luôn luôn": "Always allow location",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.": "Your homes will be deleted.\nYou will leave the shared homes.",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "This will change Home Alarm schedules for all security devices in the selected homes.\n\nMembers using Home Alarm settings will be affected.\nPersonal Alarm settings will not be changed.",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "This will add a Home Reminder to the selected homes.\n\nMembers using Home Reminder settings will be affected.\nPersonal Reminder settings will not be changed.",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "Security devices will be monitored immediately.\n\nAuto Guard when away will pause. This mode does not turn off automatically when someone comes home and must be switched back to Normal by a permitted member.",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...": "This action will change the alarm timing for some devices today...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.": "This action will disable every Alarm for this home. You will no longer receive danger alerts on this phone.",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.": "Alarm is using Home settings.\n\nYou will receive alerts according to the shared schedules configured by the owner or an administrator.",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.": "Alarm is using My settings.\n\nYou will receive alerts according to the personal Alarm schedules for this account.",
    "Không thể đăng nhập bằng Google": "Could not sign in with Google",
    "Không đặt được mật khẩu": "Could not set password",
    "Chấp nhận": "Accept",
    "Cho phép": "Allow",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.": "Could not accept the invitation. Please try again.",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.": "Could not accept the join request. Please try again.",
    "Từ chối": "Decline",
    "Lời mời từ chủ nhà": "Invitation from the owner",
    "Nhận quyền chủ nhà": "Receive home ownership",
    "Một người dùng SafeHome": "A SafeHome user",
    "Lời mời gia nhập": "Join invitation",
    "Lời xin vào nhà": "Home join request",
    "Nhập HUB ID": "Enter HUB ID",
    "VD: HUB_001": "Example: HUB_001",
    "Pair": "Pair",
    "Mật khẩu tối thiểu 6 ký tự": "Password must be at least 6 characters",
    "Mật khẩu nhập lại không khớp": "Passwords do not match",
    "Tạo mật khẩu": "Create password",
    "Mật khẩu mới": "New password",
    "Nhập lại mật khẩu": "Re-enter password",
    "Xác nhận tắt cảnh báo": "Confirm alarm stop",
    "HỦY": "CANCEL",
    "XÁC NHẬN": "CONFIRM",
    "CẦN KIỂM TRA": "NEEDS CHECKING",
    "KIỂM TRA NHÀ": "CHECK HOME",
    "ĐÓNG NHẮC NHỞ": "CLOSE REMINDER",
    "SafeHome Security Alert": "SafeHome Security Alert",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "Choose Always Allow location permission in app settings",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.": "Your Google account needs an additional password to use security features.",
    "Alarm": "Alarm",
    "Bạn không có quyền thực hiện thao tác này。": "You do not have permission to perform this action.",
    "Cài đặt": "Settings",
    "Cập nhật": "Update",
    "Chọn ngôn ngữ": "Choose language",
    "Chưa có dữ liệu thiết bị để đánh giá": "No device data available for assessment",
    "Chuyển quyền sở hữu cho thành viên khác": "Transfer ownership to another member",
    "Có": "Yes",
    "Cửa đã đóng an toàn": "Door safely closed",
    "Đã xảy ra lỗi. Vui lòng thử lại.": "An error occurred. Please try again.",
    "Đang kiểm tra kết nối Hub": "Checking Hub connection",
    "Đang mở khi nhà ở chế độ Bảo vệ": "Open while Home is in Guard mode",
    "Đang mở trong giờ Alarm": "Open during Alarm hours",
    "Đang tải...": "Loading...",
    "Hồ sơ, yêu cầu và lời mời tham gia": "Profile, requests, and invitations",
    "Hub chưa gửi trạng thái": "Hub status unavailable",
    "Hub mất kết nối": "Hub disconnected",
    "Hub tín hiệu bình thường": "Hub connected",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ": "Unlocked while Home is in Guard mode",
    "Khóa đang mở trong giờ Alarm": "Unlocked during Alarm hours",
    "Không có thông báo": "No notifications",
    "Khu vực nguy hiểm": "Danger zone",
    "Kiểm tra thiết bị trong nhà này": "Review devices in this home",
    "Mất điện lưới": "Mains power lost",
    "Mời người khác tham gia nhà này": "Invite someone to join this home",
    "Môi trường hiện tại": "Current environment",
    "MQTT mất kết nối": "MQTT disconnected",
    "Ngôn ngữ": "Language",
    "Nhà đã chia sẻ": "Shared home",
    "Nhà đang hoạt động bình thường": "Home operating normally",
    "Nhập email": "Enter email",
    "Phòng": "Room",
    "Quản trị viên": "Administrator",
    "Reminder": "Reminder",
    "SafeHome": "SafeHome",
    "Sóng yếu": "Weak signal",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "Account & system",
    "Tài khoản cá nhân": "Personal account",
    "Tạo tài khoản": "Create account",
    "Thành viên": "Member",
    "Thành viên trong nhà": "Home members",
    "Thay đổi ngôn ngữ hiển thị": "Change the display language",
    "Thêm, đổi tên và sắp xếp phòng": "Add, rename and reorder rooms",
    "Thiết bị đang được giám sát": "Device is being monitored",
    "Tiếng Anh": "English",
    "Tiếng Hàn": "Korean",
    "Tiếng Nhật": "Japanese",
    "Tiếng Trung": "Chinese",
    "Tiếng Việt": "Vietnamese",
    "Toàn bộ thiết bị": "All devices",
    "Vai trò": "Role",
    "Về nhà": "At home",
    "Xem và quản lý quyền thành viên": "View and manage member roles",
    "Xóa": "Delete",
    "Xóa nhà": "Delete home",
    "Xoá toàn bộ dữ liệu và thiết bị": "Delete all data and devices",
    "TẮT CẢNH BÁO": "TURN OFF ALERT",
    "Đã tạo nhà": "Home created",

    "Mode Bảo vệ thủ công đã bật": "Manual Guard mode enabled",
    "Báo động không lặp lại.": "The alarm will not repeat.",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.": "The alarm repeats after \$securityModeRepeatMinutes minutes if the issue remains.",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage": "\$actorName turned on Manual Guard mode for \"\$homeName\". This mode only turns off when a permitted member switches back to Normal. \$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".": "You enabled Alarm for \"\$homeName\".",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".": "You disabled every Alarm for \"\$homeName\".",
    "Thành viên mới": "New member",
    "Thành viên rời nhà": "Member left home",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".": "\$displayMemberName left \"\$homeName\".",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".": "\$actorName changed \$memberName's role from \$oldRoleName to \$newRoleName in \"\$homeName\".",
    "Còn \$count tin nhắn chưa đọc": "\$count unread messages",
    "Hãy an tâm nghỉ ngơi.": "You can rest assured.",
    "Có thiết bị chưa an toàn.": "Some devices are not safe.",
    "SafeHome đang cập nhật vị trí": "SafeHome is updating location",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.": "Monitoring to turn on Guard mode automatically.",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.": "Uses location to turn on Guard mode automatically when everyone leaves home.",
    "CẢNH BÁO SOS": "SOS ALERT",
    "CẢNH BÁO KHÓI / CHÁY": "SMOKE / FIRE ALERT",
    "CẢNH BÁO NGẬP NƯỚC": "FLOOD ALERT",
    "CẢNH BÁO RÒ KHÍ": "GAS LEAK ALERT",
    "CẢNH BÁO CỬA": "DOOR ALERT",
    "CẢNH BÁO AN NINH": "SECURITY ALERT",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.": "Could not confirm with SafeHome. Check your connection and try again.",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?": "Only stop the alert after checking the home's condition.\n\nAre you sure you want to stop the alert?",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome detected an alert",
    "Mở SafeHome để kiểm tra ngay.": "Open SafeHome to check now.",
    "\$count tin nhắn mới": "\$count new messages",
    "Tin nhắn HomeChat": "HomeChat message",
    "\$senderName đã gửi một tin nhắn": "\$senderName sent a message",
    "Bạn có tin nhắn mới": "You have a new message",
    "Mode Bảo vệ sẽ chỉ báo động một lần": "Guard mode will alert only once",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút": "Guard mode will repeat the alert after \$minutes minutes",
    "Đã gửi yêu cầu gia nhập \$count nhà": "Join requests sent for \$count homes",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".": "\$requesterName requested to join \"\$homeName\".",
    "Bạn đã xoá nhà \"\$homeName\".": "You deleted \"\$homeName\".",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.": "You sent an ownership transfer request for \"\$homeName\" to \$email.",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.": "\$actorName wants to transfer ownership of \"\$homeName\" to you.",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".": "\$actorName invited you to join \"\$homeName\".",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".": "SafeHome is removing \"\$deviceName\" from \"\$homeName\".",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".": "Device \"\$deviceName\" was added to \"\$homeName\".",
    "Bạn đã tạo nhà \"\$name\".": "You created the home \"\$name\".",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.": "\$actorName updated the home name to \"\$newName\" and changed its address.",
    "\$actorName đã đổi tên nhà thành \"\$newName\".": "\$actorName renamed the home to \"\$newName\".",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".": "\$actorName updated the address of \"\$newName\".",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".": "\$actorName renamed device \"\$oldDeviceName\" to \"\$newName\" in \"\$homeName\".",
    "Đang ghép nối: \$seconds giây": "Pairing: \$seconds s",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.": "Device pairing was enabled in \"\$homeName\" for \$seconds seconds.",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)": "The pause period must be within the Alarm schedule (\$start → \$end)",
    "\$passCount/\$total bài test đạt\n\n": "\$passCount/\$total tests passed\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.": "\$name has not added a phone number to their profile.",
    "Tin nhắn mới trong \$homeName": "New message in \$homeName",
    "\$current/\$total kết quả": "\$current/\$total results",
    "Đang trả lời \$name": "Replying to \$name",
    "\"\$name\" phát hiện khói trong \"\$homeName\".": "\"\$name\" detected smoke in \"\$homeName\".",
    "\"\$name\" đã trở lại trạng thái bình thường.": "\"\$name\" has returned to normal.",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".": "\"\$name\" triggered SOS in \"\$homeName\".",
    "\"\$name\" đã hết trạng thái SOS.": "\"\$name\" is no longer in SOS state.",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".": "\"\$name\" reported tampering in \"\$homeName\".",
    "\"\$name\" đã hết cảnh báo tháo/cạy.": "\"\$name\" tamper alert has cleared.",
    "\"\$name\" đã đóng trong \"\$homeName\".": "\"\$name\" closed in \"\$homeName\".",
    "\"\$name\" đang mở trong \"\$homeName\".": "\"\$name\" is open in \"\$homeName\".",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.": "\"\$name\" in \"\$homeName\" has a low battery.",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.": "\"\$name\" in \"\$homeName\" went offline.",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.": "\"\$name\" in \"\$homeName\" is back online.",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".": "\"\$name\" recorded a high temperature in \"\$homeName\".",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".": "\"\$name\" recorded high humidity in \"\$homeName\".",
    "Có nút SOS vừa được kích hoạt": "An SOS button was triggered",
    "Có dấu hiệu khói hoặc cháy": "Smoke or fire was detected",
    "Có dấu hiệu ngập nước": "Water flooding was detected",
    "Có dấu hiệu rò khí": "A gas leak was detected",
    "Có cửa đang mở hoặc thiết bị bị tháo": "A door is open or a device was tampered with",
    "Có thiết bị đang cảnh báo": "A device is alerting",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.": "If no one confirms, SafeHome will switch to an emergency call.",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.": "Alerts again at \$time if the issue has not been handled.",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.": "Alerts again according to the Alarm schedule if the issue has not been handled.",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".": "\"\$deviceName\" closed in \"\$resolvedHomeName\".",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".": "\"\$deviceName\" is open in \"\$resolvedHomeName\".",
    "\$count nhà đã chọn": "\$count homes selected",
    "🚨 \$count nhà không an toàn\$suffix": "🚨 \$count unsafe homes\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix": "⚠️ \$count homes need attention\$suffix",
    "✅ \$count nhà an toàn": "✅ \$count safe homes",
    "\$count nhà đang được theo dõi": "\$count homes monitored",
    "\$minutes phút": "\$minutes minutes",
    "Đã cài Reminder cho \$updatedHomes nhà.": "Reminder was set for \$updatedHomes homes.",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n": "Alarm was set for \$updatedDevices devices across \$updatedHomes homes.\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.": "Homes you manage were shared.\n\n\$skipped homes were skipped because you do not have sharing permission.",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh": "Alarm applied to \$count security devices",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh": "Apply the same schedule to \$count security devices",
    "\$count phút trước": "\$count minutes ago",
    "\$count giờ trước": "\$count hours ago",
    "\${count}h trước": "\${count}h ago",
    "\${hours}h\$minutes' trước": "\${hours}h \${minutes}m ago",
    "\$count ngày trước": "\$count days ago",
    "\$count tháng trước": "\$count months ago",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?": "Are you sure you want to remove \$name from this home?",
    "\$targetEmail\nXin gia nhập \"\$homeName\"": "\$targetEmail\nRequests to join \"\$homeName\"",
    "Xin gia nhập \"\$homeName\"": "Requests to join \"\$homeName\"",
    "Bạn được mời nhận quyền nhà \"\$homeName\"": "You were invited to receive ownership of \"\$homeName\"",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"": "\$ownerEmail\nInvites you to join \"\$homeName\"",
    "Mời bạn gia nhập \"\$homeName\"": "Invites you to join \"\$homeName\"",
    "Cần kiểm tra: \$joined": "Needs attention: \$joined",
    "Cập nhật \$value": "Updated \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.": "Add your first SafeHome device to start monitoring this home.",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.": "Check emergency alerts first, then contact household members if needed.",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "No household member is home but a door or lock is open. Check it now.",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "Check the open door or lock before keeping this home in Guard mode.",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.": "Someone may still be home. If so, switch back to Normal mode.",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.": "Some members have unknown location. Ask them to open the app or check location permission.",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "A device is disconnected. Check its battery, power, or placement.",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.": "A device has low battery. Replace it soon to avoid missed alerts.",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.": "Reminder is not set. Create a schedule to check your home regularly.",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.": "Alarm schedule is not set. Enable protection for times you are usually away.",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.": "No immediate action is needed. Keep monitoring this home.",
    "Lặp sau \$minutes phút": "Repeat after \$minutes minutes",
    "Đang dùng • \$repeatText": "Active • \$repeatText",
    "Giám sát an ninh • \$repeatText": "Security monitoring • \$repeatText",
    "Gia đình: \$mode": "Home mode: \$mode",
    "Gợi ý xử lý": "Suggested actions",
    "Phát hiện \$count vấn đề cần xử lý": "\$count issues need attention",
    "Hôm nay các cửa đã được sử dụng \$count lần": "Doors were used \$count times today",
    "Đã ghi nhận \$count hoạt động gần đây": "\$count recent activities recorded",
    "Hệ thống: Cần kiểm tra \$issueCount mục": "System: \$issueCount items need checking",
    "FCM token đã sẵn sàng trên điện thoại này.": "The FCM token is ready on this phone.",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.": "The FCM token is ready, but Auto Away is missing a requirement.",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.": "\$emergencyTotal emergency devices found. Recommended minimum: smoke sensor and SOS.",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?": "Transfer home ownership to:\n\$targetEmail?",
    "\$count cửa đã đóng an toàn": "\$count doors safely closed",
    "\$count cửa và khóa đã an toàn": "\$count doors and locks secured",
    "\$count thiết bị đang được theo dõi": "\$count devices monitored",
    "Cập nhật \$timeText": "Updated \$timeText",
    "Dữ liệu gần nhất cập nhật \$count phút trước": "Latest data updated \$count minutes ago",
    "Dữ liệu gần nhất cập nhật \$count giờ trước": "Latest data updated \$count hours ago",
    "Thành viên trong nhà: \$count": "Members at home: \$count",
    "Thành viên bên ngoài: \$count": "Members away: \$count",
    "Chưa xác định vị trí: \$count": "Location unknown: \$count",
    "Môi trường hiện tại: \$environment": "Current environment: \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ": "\$name: Open while Home is in Guard mode",
    "An tâm hơn trong từng ngôi nhà": "Peace of mind in every home",
    "Báo động SafeHome": "SafeHome Alarm",
    "Có cảnh báo an ninh cần kiểm tra ngay.": "A security alert requires your attention.",
    "Có cảnh báo cần kiểm tra": "An alert requires your attention",
    "Tự đóng sau \$time": "Auto-closes in \$time",
  };

  static const Map<String, String> _chinese = {
    "Không tìm thấy người dùng": "未找到用户",
    "Không đọc được số điện thoại": "无法读取电话号码",
    "Tin nhắn quá dài": "消息太长",
    "Không gửi được tin nhắn": "无法发送消息",
    "Bạn không có quyền sửa lịch chung của nhà": "你没有权限编辑此家的共享日程",
    "Nhà của bạn": "你的家",
    "Tải tin cũ hơn": "加载更早的消息",
    "Nhà chưa đặt tên": "未命名家庭",
    "Nhà": "家庭",
    "Chưa có thông tin": "暂无信息",
    "Chưa cập nhật": "未更新",
    "Chủ nhà": "屋主",
    "Nhà được chia sẻ": "共享家庭",
    "Địa chỉ": "地址",
    "An ninh ra/vào": "出入安全",
    "Nguy hiểm khẩn cấp": "紧急危险",
    "Điều khiển & hạ tầng": "控制与基础设施",
    "Môi trường": "环境",
    "Toàn bộ thiết bị SafeHome": "所有 SafeHome 设备",
    "Cửa ra/vào": "出入门",
    "Cửa": "门",
    "Cửa sổ": "窗户",
    "Cổng": "大门",
    "Khóa thông minh": "智能门锁",
    "Chuyển động": "移动",
    "Hiện diện": "有人状态",
    "Rung/chấn động": "震动",
    "Kính vỡ": "玻璃破碎",
    "Báo khói": "烟雾报警器",
    "Báo nhiệt": "温度报警器",
    "Khí CO": "一氧化碳",
    "Báo gas": "燃气报警器",
    "Báo ngập/rò nước": "漏水报警器",
    "Nút SOS": "SOS 按钮",
    "Nhiệt độ/Độ ẩm": "温度/湿度",
    "Bụi mịn PM2.5": "PM2.5 细颗粒物",
    "CO₂": "CO₂",
    "Chất lượng không khí": "空气质量",
    "Ổ điện thông minh": "智能插座",
    "Còi báo động": "警笛",
    "Van thông minh": "智能阀门",
    "Camera": "摄像头",
    "Chuông cửa": "门铃",
    "Bàn phím an ninh": "安全键盘",
    "Bộ mở rộng sóng": "信号中继器",
    "Hub trung tâm": "中央 Hub",
    "Đo điện năng": "电量监测",
    "Nguồn dự phòng UPS": "UPS 备用电源",
    "Thiết bị đang Offline": "设备离线",
    "Thiết bị đang Online": "设备在线",
    "pin yếu": "电量低",
    "sóng yếu": "信号弱",
    "lâu không phản hồi": "长时间无响应",
    "Kết nối cần kiểm tra": "连接需要检查",
    "Vừa xong": "刚刚",
    "Bị tháo": "检测到拆卸",
    "Có khói": "检测到烟雾",
    "Bình thường": "普通模式",
    "Bảo vệ": "布防",
    "Chế độ Bảo vệ": "布防模式",
    "Tự động Bảo vệ khi rời nhà": "离家自动布防",
    "Đã kích hoạt": "已激活",
    "Sẵn sàng": "就绪",
    "Đang đóng": "已关闭",
    "Đang mở": "已打开",
    "Rò rỉ gas": "检测到燃气泄漏",
    "Phát hiện ngập nước": "检测到漏水",
    "Phát hiện chuyển động": "检测到移动",
    "Không có chuyển động": "未检测到移动",
    "Phát hiện hiện diện": "检测到有人",
    "Không phát hiện hiện diện": "未检测到有人",
    "Phát hiện rung/chấn động": "检测到震动",
    "Không có rung bất thường": "无异常震动",
    "Phát hiện kính vỡ": "检测到玻璃破碎",
    "Không có cảnh báo kính vỡ": "无玻璃破碎警报",
    "Nhiệt độ nguy hiểm": "危险高温",
    "Phát hiện khí CO": "检测到一氧化碳",
    "Không phát hiện khí CO": "未检测到一氧化碳",
    "Khóa đang mở": "未上锁",
    "Khóa đang đóng": "已上锁",
    "Đang bật": "开启",
    "Đang tắt": "关闭",
    "Đang theo dõi điện năng": "正在监测电力",
    "Đang dùng nguồn dự phòng": "正在使用备用电源",
    "Nguồn điện bình thường": "市电正常",
    "Còi đang bật": "警笛响起",
    "Còi sẵn sàng": "警笛就绪",
    "Van đang mở": "阀门打开",
    "Van đã đóng": "阀门关闭",
    "Đang hoạt động": "运行中",
    "Đang theo dõi": "正在监测",
    "Chưa nhận diện": "未识别设备",
    "Chưa có cập nhật": "暂无更新",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh": "暂无设备。点击 + 添加设备，开始保护你的家庭。",
    "CHƯA AN TOÀN": "不安全",
    "CẦN CHÚ Ý": "需要注意",
    "ĐÃ AN TOÀN": "安全",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.": "家中有需要检查的迹象，请查看下面的状态。",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "家中运行稳定，可以安心。",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "未发现异常烟雾或 SOS。",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "暂无足够的新活动用于深入分析。",
    "Hub kết nối bình thường": "Hub 连接正常",
    "Cài đặt cảnh báo cho nhà hiện tại": "当前家庭的提醒设置",
    "Nhận cảnh báo Alarm": "接收 Alarm 提醒",
    "Đang bật cho tài khoản này": "此账户已开启",
    "Đang tắt cho tài khoản này": "此账户已关闭",
    "Hẹn giờ Reminder": "Reminder 计划",
    "Nhắc kiểm tra nhà theo thời gian": "按时间提醒检查家庭",
    "Hẹn giờ Alarm": "设置 Alarm",
    "Chưa thiết lập": "未设置",
    "Chưa thiết lập thời gian": "未设置时间",
    "Tổng hợp trạng thái nhà": "家庭状态汇总",
    "Cần xử lý ngay": "需要立即处理",
    "Cần kiểm tra": "需要检查",
    "Đánh giá tự động": "自动评估",
    "Tự động đánh giá": "自动评估",
    "Tổng quan hôm nay": "今日概览",
    "Chưa có dữ liệu tổng quan": "暂无概览数据",
    "Chưa có dữ liệu trạng thái": "暂无状态数据",
    "Chưa đủ dữ liệu để đánh giá": "暂无足够数据可评估",
    "Chưa có dữ liệu để đánh giá": "暂无足够数据可评估",
    "Bấm vào để xem chi tiết": "点击查看详情",
    "Nhấn để xem chi tiết...": "点击查看详情...",
    "Tạm dừng": "暂停",
    "Tắt": "关闭",
    "Chi tiết": "详情",
    "Tổng hợp trạng thái": "状态汇总",
    "Không an toàn": "不安全",
    "Cần chú ý": "需要注意",
    "An toàn": "安全",
    "Không có": "无",
    "Huỷ": "取消",
    "Hủy": "取消",
    "Lưu": "保存",
    "Thêm": "添加",
    "Xoá": "删除",
    "Đổi tên": "重命名",
    "Nhà của tôi": "我的家庭",
    "Bỏ chọn toàn bộ nhóm": "取消选择整个分组",
    "Chọn toàn bộ nhóm": "选择整个分组",
    "Bỏ chọn": "取消选择",
    "Quay lại": "返回",
    "Tìm kiếm": "搜索",
    "Tìm nhà": "搜索家庭",
    "Đóng tìm kiếm": "关闭搜索",
    "Giờ": "小时",
    "Phút": "分钟",
    "Đặt Home Reminder": "设置家庭 Reminder",
    "Đặt Home Alarm": "设置家庭 Alarm",
    "Xác nhận thay đổi": "确认更改",
    "Tiếp tục": "继续",
    "Giờ Reminder": "Reminder 时间",
    "Giờ bắt đầu Alarm": "Alarm 开始时间",
    "Giờ kết thúc Alarm": "Alarm 结束时间",
    "Không có nhà nào đủ điều kiện để cài": "没有符合条件的家庭可设置",
    "Cài đặt hoàn tất": "设置完成",
    "Xác nhận rời nhà": "确认离开家庭",
    "Xác nhận xoá nhà": "确认删除家庭",
    "Nhập mật khẩu": "输入密码",
    "Mật khẩu tài khoản": "账户密码",
    "Rời khỏi nhà": "离开家庭",
    "Xoá nhà": "删除家庭",
    "Sai mật khẩu": "密码错误",
    "Đã rời khỏi home": "已离开家庭",
    "Đã cập nhật": "已更新",
    "Tìm home...": "搜索家庭...",
    "Đặt vị trí nhà và bật bảo vệ tự động": "设置家庭位置并开启自动保护",
    "Chuyển quyền chủ nhà hoặc xoá nhà": "转移家庭所有权或删除家庭",
    "Đặt Reminder / Alarm nhà đã chọn": "为所选家庭设置 Reminder / Alarm",
    "Chia sẻ nhà đã chọn": "共享所选家庭",
    "Chia sẻ": "共享",
    "Email người nhận": "收件人邮箱",
    "Email chưa đăng ký": "邮箱未注册",
    "Chia sẻ hoàn tất": "共享完成",
    "Mở danh sách chia sẻ nhà": "打开家庭共享列表",
    "Xoá các nhà đã chọn?": "删除所选家庭？",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "所选家庭将被永久删除。",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn": "或扫描二维码申请加入所选家庭",
    "Mở List chia sẻ nhà": "打开家庭共享列表",
    "Không có nhà nào bạn có quyền quản lý": "没有你有权管理的家庭",
    "Chưa share cho ai": "尚未共享给任何人",
    "Xoá các nhà đã chọn ?": "删除所选家庭？",
    "Thông báo Home": "家庭通知",
    "Thông báo nhà": "家庭通知",
    "Vai trò thành viên đã thay đổi": "成员角色已更改",
    "Xoá tất cả thông báo?": "删除所有通知？",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "所有家庭通知将被删除。",
    "Chưa có thông báo nào": "暂无通知",
    "Chưa có thông báo": "暂无通知",
    "Vuốt lên để tải thêm": "向上滑动加载更多",
    "Không có thiết bị": "没有设备",
    "Chỉ chủ nhà mới được xoá nhà": "只有屋主可以删除家庭",
    "Chỉ chủ nhà mới được chuyển quyền": "只有屋主可以转移所有权",
    "Lưu ý khi bật Alarm": "开启 Alarm 提示",
    "Alarm đã được bật": "Alarm 已开启",
    "Đã hiểu": "知道了",
    "Đã bật Alarm": "Alarm 已开启",
    "Đã tắt Alarm": "Alarm 已关闭",
    "Tắt Alarm": "关闭 Alarm",
    "Cả ngày": "全天",
    "Bạn không có quyền thực hiện thao tác này.": "你没有权限执行此操作。",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.": "无法完成此操作。请重试。",
    "Một người dùng": "一位用户",
    "Yêu cầu gia nhập nhà": "申请加入家庭",
    "Đã gửi yêu cầu gia nhập nhà": "已发送加入请求",
    "Bạn không có quyền thêm thiết bị": "你没有添加设备的权限",
    "Đã mở chế độ thêm thiết bị": "设备配对已开启",
    "QR của nhà này": "此家庭的二维码",
    "Chia sẻ nhà": "共享家庭",
    "Quét QR để xin gia nhập nhà": "扫描二维码加入家庭",
    "Quét QR xin gia nhập nhà": "扫描二维码加入家庭",
    "Đưa mã QR chia sẻ nhà vào khung hình": "将共享家庭二维码放入框内",
    "Mã QR này do chủ nhà chia sẻ": "此二维码由房主分享",
    "Nhập mã mời": "输入邀请码",
    "Gửi yêu cầu gia nhập": "发送加入请求",
    "QR này không phải mã thiết bị": "此二维码不是设备码",
    "Xin gia nhập nhà": "申请加入家庭",
    "Quét mã QR chia sẻ nhà": "扫描家庭共享二维码",
    "Mời thành viên bằng mã QR": "使用二维码邀请成员",
    "Không thể share cho chính bạn": "不能共享给自己",
    "Lời mời chia sẻ nhà": "家庭共享邀请",
    "Đã share home": "家庭已共享",
    "Chuyển quyền chủ nhà": "转移屋主权限",
    "Không thể chuyển quyền cho chính bạn": "不能转移给自己",
    "Không tìm thấy user": "未找到用户",
    "Không tìm thấy tài khoản": "未找到账户",
    "Xác nhận chuyển quyền": "确认转移所有权",
    "Chuyển": "转移",
    "Xác nhận mật khẩu": "确认密码",
    "Xác nhận": "确认",
    "Yêu cầu chuyển quyền chủ nhà": "屋主权限转移请求",
    "Đã gửi yêu cầu chuyển quyền": "已发送转移请求",
    "Bạn không có quyền xoá thiết bị": "你没有删除设备的权限",
    "Xóa Device?": "删除设备？",
    "Đang xoá thiết bị": "正在删除设备",
    "Đăng xuất?": "退出登录？",
    "Thêm nhà": "添加家庭",
    "Thêm nhà mới": "添加新家庭",
    "Tạo nhà mới": "创建新家庭",
    "Tạo một ngôi nhà mới của bạn": "创建一个新家庭",
    "Quét mã QR được chủ nhà chia sẻ": "扫描房主分享的二维码",
    "Tên nhà": "家庭名称",
    "Số điện thoại": "电话",
    "Nam": "男",
    "Nữ": "女",
    "Ngày": "日",
    "Tháng": "月",
    "Năm": "年",
    "Thông tin cá nhân": "个人信息",
    "Thiết lập tài khoản": "设置账户",
    "Vui lòng nhập đủ thông tin": "请填写完整信息",
    "Không thể lưu thông tin": "无法保存信息",
    "Đã lưu thông tin": "信息已保存",
    "Lỗi lưu profile": "无法保存资料",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp": "添加电话号码以便紧急情况使用",
    "Hoàn tất": "完成",
    "Đã tạo nhà mới": "家庭已创建",
    "Về muộn": "晚回家",
    "Ra ngoài": "外出",
    "Khác": "其他",
    "Lưu ý tạm tắt Alarm": "Alarm 暂停说明",
    "Tạm tắt Alarm hôm nay": "今天暂停 Alarm",
    "Chọn giờ bắt đầu tạm tắt": "选择暂停开始时间",
    "Từ": "从",
    "Từ giờ": "从",
    "Chọn giờ kết thúc tạm tắt": "选择暂停结束时间",
    "Đến": "到",
    "Đến giờ": "到",
    "Xoá lịch tạm tắt": "删除暂停计划",
    "Xóa lịch tạm tắt": "删除暂停计划",
    "Giới tính": "性别",
    "SĐT": "电话",
    "Ngày sinh": "出生日期",
    "Yêu cầu & lời mời": "请求与邀请",
    "Xem lời mời chia sẻ và xin gia nhập": "查看共享邀请和加入请求",
    "Cài đặt bảo mật": "安全设置",
    "Quyền báo động toàn màn hình": "全屏报警权限",
    "Báo động toàn màn hình": "全屏报警",
    "Đã được cấp quyền": "已授予权限",
    "Chưa được cấp quyền": "未授予权限",
    "Mở cài đặt hệ thống": "打开系统设置",
    "Đăng xuất": "退出登录",
    "Thoát tài khoản khỏi thiết bị này": "从此设备退出账号",
    "Không có yêu cầu hoặc lời mời nào": "暂无请求或邀请",
    "Xoá tài khoản": "删除账户",
    "Hành động này sẽ xoá toàn bộ dữ liệu:": "此操作将删除所有数据：",
    "Nhà và thiết bị": "家庭和设备",
    "Chia sẻ và quyền truy cập": "共享和访问权限",
    "Toàn bộ dữ liệu liên quan": "所有相关数据",
    "Mật khẩu xác nhận": "确认密码",
    "Đã xoá tài khoản": "账户已删除",
    "Xoá thất bại": "删除失败",
    "Lỗi xoá tài khoản": "无法删除账户",
    "Tình trạng": "状态",
    "Tháo/Lắp": "防拆",
    "Pin": "电量",
    "Tín hiệu": "信号",
    "Chưa liên kết": "未关联",
    "Liên lạc cuối": "最后联络",
    "Event cuối": "最后事件",
    "Sự kiện cuối": "最后事件",
    "Lần kích hoạt cuối": "最后触发",
    "Thiết bị không còn tồn tại": "设备不再存在",
    "Mất kết nối": "连接断开",
    "Online": "在线",
    "Offline": "离线",
    "Loại thiết bị": "设备类型",
    "Nhiệt độ": "温度",
    "Độ ẩm": "湿度",
    "Công suất": "功率",
    "Điện áp": "电压",
    "Dòng điện": "电流",
    "Điện năng": "电能",
    "Cường độ rung": "震动强度",
    "Góc nghiêng": "倾斜角度",
    "Độ mở van": "阀门开度",
    "Nguồn dự phòng": "备用电源",
    "Ngập/rò nước": "漏水",
    "Phát hiện khói": "检测到烟雾",
    "Quản lý phòng": "房间管理",
    "Bạn không có quyền quản lý phòng": "你没有管理房间的权限",
    "Đổi tên phòng": "重命名房间",
    "Tên phòng": "房间名称",
    "Xoá phòng": "删除房间",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.": "此房间中的设备将移动到未分配房间。",
    "Thêm phòng": "添加房间",
    "Ví dụ: Phòng khách": "例如：客厅",
    "Phòng khách": "客厅",
    "Tên phòng đã tồn tại": "房间名称已存在",
    "Chưa phân phòng": "未分配房间",
    "Phòng mặc định": "默认房间",
    "Phát hiện bất thường": "检测到异常",
    "Phát hiện cạy phá": "检测到异常",
    "Tamper detected": "检测到防拆异常",
    "Tamper cleared": "防拆正常",
    "Door opened": "门已打开",
    "Door closed": "门已关闭",
    "Motion detected": "检测到移动",
    "Battery low": "电量低",
    "Device offline": "设备离线",
    "Device online": "设备在线",
    "Alarm triggered": "警报已触发",
    "Alarm cleared": "警报已解除",
    "Cửa mở": "门已打开",
    "Cửa đóng": "门已关闭",
    "Chưa đặt vị trí nhà": "尚未设置家庭位置",
    "Đặt vị trí nhà tại đây": "将当前位置设为家庭位置",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ": "开启离家自动布防前，请先设置家庭位置",
    "Bán kính bảo vệ mặc định: 150 m": "默认保护半径：150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.": "每位成员都需要授予“始终允许”位置权限，离家/到家状态才能在后台工作。",
    "Lưu cài đặt": "保存设置",
    "Đã đặt vị trí nhà": "已设置家庭位置",
    "Đang lấy vị trí...": "正在获取位置...",
    "Đang lưu...": "正在保存...",
    "Đổi tên hiển thị": "更改显示名称",
    "Cập nhật thông tin nhà": "更新家庭信息",
    "Nhập địa chỉ của nhà": "输入家庭地址",
    "Lưu thay đổi": "保存更改",
    "Một thành viên": "一位成员",
    "Đã cập nhật thông tin nhà": "家庭信息已更新",
    "Thay tên": "重命名",
    "Đã đổi tên thiết bị": "设备已重命名",
    "Đóng": "关闭",
    "Đã thiết lập": "已设置",
    "Quét QR": "扫描二维码",
    "Quét QR để thêm thiết bị": "扫描二维码添加设备",
    "Nhập HUB ID thủ công": "手动输入 HUB ID",
    "Bạn không có quyền sắp xếp phòng": "你没有排序房间的权限",
    "Cảnh báo khói": "烟雾警报",
    "Cập nhật thiết bị": "设备更新",
    "Cửa đang mở": "门已打开",
    "Cửa đã đóng": "门已关闭",
    "Giờ không hợp lệ": "时间无效",
    "Khôi phục mật khẩu": "重置密码",
    "Nhập email của bạn": "输入你的邮箱",
    "Gửi": "发送",
    "Đã gửi email khôi phục": "已发送密码重置邮件",
    "Không gửi được email": "无法发送邮件",
    "Vui lòng nhập email và mật khẩu": "请输入邮箱和密码",
    "Mật khẩu xác nhận không khớp": "两次输入的密码不一致",
    "Không thể tạo tài khoản": "无法创建账户",
    "Sai tài khoản": "账户不正确",
    "Email đã tồn tại": "邮箱已存在",
    "Mật khẩu quá yếu": "密码太弱",
    "Sai email hoặc mật khẩu": "邮箱或密码不正确",
    "Lỗi đăng nhập": "登录错误",
    "Email": "邮箱",
    "Mật khẩu": "密码",
    "Ghi nhớ tài khoản": "记住账号",
    "Đăng nhập": "登录",
    "Đăng ký mới": "创建账号",
    "Quên mật khẩu?": "忘记密码？",
    "Chưa có tài khoản? Đăng ký": "没有账号？注册",
    "Đã có tài khoản? Đăng nhập": "已有账号？登录",
    "Tính năng đang được phát triển": "此功能正在开发中",
    "Thông báo": "通知",
    "Chat trong nhà": "家庭聊天",
    "Tìm kiếm tin nhắn": "搜索消息",
    "Xem thành viên": "查看成员",
    "Tìm nội dung hoặc tên người gửi": "搜索内容或发送者姓名",
    "Xoá từ khoá": "清除关键词",
    "Không có kết quả": "没有结果",
    "Tìm ngôn ngữ": "搜索语言",
    "Kết quả trước": "上一个结果",
    "Kết quả tiếp theo": "下一个结果",
    "Chưa có tin nhắn": "暂无消息",
    "Không tìm thấy thành viên phù hợp": "未找到匹配的成员",
    "Nhắc đến trong tin nhắn": "在消息中提及",
    "Huỷ trả lời": "取消回复",
    "Nhắn gì đó...": "输入消息...",
    "Gọi điện": "拨打电话",
    "Alarm thiết bị": "设备 Alarm",
    "Chế độ áp dụng": "应用模式",
    "Theo nhà": "按家庭",
    "Riêng tôi": "仅自己",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập": "使用房主或管理员设置的共享日程",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn": "使用仅适用于你账号的个人日程",
    "Thiết lập nhanh Alarm": "快速设置 Alarm",
    "Thiết lập nhanh toàn bộ thiết bị": "快速设置全部设备",
    "Áp dụng cho toàn bộ thiết bị": "应用到所有设备",
    "Bắt đầu": "开始",
    "Kết thúc": "结束",
    "Thời gian lặp lại": "重复间隔",
    "Không lặp lại": "不重复",
    "Quét QR HUB": "扫描 HUB 二维码",
    "Đưa mã QR vào giữa khung": "将二维码放到框内",
    "Đang áp dụng...": "正在应用...",
    "Ngôi nhà đang hoạt động ổn định": "家庭运行稳定",
    "Nhiệt độ cao": "温度过高",
    "OK": "OK",
    "Pin yếu": "电量低",
    "SOS đã kết thúc": "SOS 已结束",
    "SOS được kích hoạt": "SOS 已触发",
    "Tamper bình thường": "防拆状态正常",
    "Thiết bị bị tháo": "设备被拆卸",
    "Thiết bị mới": "新设备",
    "Thiết bị offline": "设备离线",
    "Thiết bị online": "设备在线",
    "Báo động kích hoạt": "警报已触发",
    "Báo động đã tắt": "警报已解除",
    "Độ ẩm cao": "湿度过高",
    "Thử lại": "重试",
    "Không thể tải dữ liệu tài khoản": "无法加载账户数据",
    "Không": "否",
    "Đã chia sẻ nhà thành công.": "家庭共享成功。",
    "Tìm nhà...": "搜索家庭...",
    "Đã rời khỏi nhà": "已离开家庭",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.": "你将离开共享家庭。",
    "Các nhà của bạn sẽ bị xoá.\n": "你的家庭将被删除。\n你将离开共享家庭。",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n": "此操作会更改所选家庭中所有安全设备的 Home Alarm 计划。\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n": "此操作会为所选家庭添加 Home Reminder。\n\n",
    "Xác nhận thay đổi Alarm": "确认更改 Alarm",
    "Xác nhận thay đổi Reminder": "确认更改 Reminder",
    "Lặp lại khi sự cố vẫn còn": "问题仍存在时重复",
    "Thời gian lặp lại Alarm": "Alarm 重复时间",
    "VD: Mr Chung": "例如：Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 暂无家庭",
    "Vẫn chuyển về Bình thường": "仍然切换到普通模式",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.": "离家自动布防仍处于开启状态。如果所有成员仍在外出，系统可能会在几分钟后重新开启布防。",
    "Chuyển về Bình thường?": "切换到普通模式？",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n": "开启后，安全设备会立即开始监测。\n\n",
    "Bật Bảo vệ thủ công?": "开启手动布防？",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ": "此操作将更改今天部分设备的报警时间……",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ": "此操作将关闭此家庭的所有 Alarm。你将不再在此手机上收到危险警报。",
    "Tắt toàn bộ Alarm?": "关闭全部 Alarm？",
    "Không xoá được lịch tạm tắt Alarm": "无法删除 Alarm 暂停计划",
    "Không lưu được tạm tắt Alarm": "无法保存 Alarm 暂停",
    "Không gửi được yêu cầu xoá": "无法发送删除请求",
    "Không lưu được cài đặt": "无法保存设置",
    "Không lấy được vị trí hiện tại": "无法获取当前位置",
    "Không thể xác nhận tài khoản hiện tại": "无法验证当前账户",
    "Mật khẩu không đúng": "密码不正确",
    "Không thể xác nhận mật khẩu": "无法验证密码",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động": "只有屋主或管理员可以更改警报重复设置",
    "Không lưu được thời gian lặp báo động": "无法保存警报重复时间",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "只有屋主或管理员可以更改保护模式",
    "Không thể thay đổi chế độ nhà": "无法更改家庭模式",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "保护模式已开启，但无法发送通知",
    "Đã bật Mode Bảo vệ thủ công": "手动保护模式已开启",
    "Đã chuyển nhà về Bình thường": "家庭已切换回普通模式",
    "60 phút": "60 分钟",
    "30 phút": "30 分钟",
    "15 phút": "15 分钟",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.": "你正在查看屋主的计划。选择仅自己即可设置个人 Alarm 计划。",
    "Chọn giờ kết thúc Alarm": "选择 Alarm 结束时间",
    "Chọn giờ bắt đầu Alarm": "选择 Alarm 开始时间",
    "Bạn không có quyền sửa lịch Alarm của nhà": "你没有权限编辑此家庭的 Alarm 计划",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị": "无法将 Alarm 应用到所有设备",
    "Nhà chưa có thiết bị an ninh để áp dụng": "此家庭暂无可应用的安全设备",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.": "你没有权限编辑按家庭设置。请选择仅自己。",
    "Không thể lưu chế độ Alarm": "无法保存 Alarm 模式",
    "Thêm Reminder": "添加 Reminder",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.": "Reminder 会在所选时间提醒你检查家庭安全状态。",
    "Thêm khung giờ Alarm": "添加 Alarm 时间段",
    "Đang sử dụng Reminder riêng của bạn": "正在使用你的个人 Reminder 设置",
    "Đang sử dụng Reminder của chủ nhà": "正在使用屋主的 Reminder 设置",
    "Sửa giờ Reminder": "编辑 Reminder 时间",
    "Sửa giờ kết thúc Alarm": "编辑 Alarm 结束时间",
    "Sửa giờ bắt đầu Alarm": "编辑 Alarm 开始时间",
    "Xoá Reminder": "删除 Reminder",
    "Mỗi 1 giờ": "每 1 小时",
    "Mỗi 30 phút": "每 30 分钟",
    "Mỗi 15 phút": "每 15 分钟",
    "Không báo lại": "不重复",
    "Báo lại khi vẫn chưa an toàn": "仍不安全时重复提醒",
    "Báo lại mỗi 1 giờ": "每 1 小时重复",
    "Báo lại mỗi 30 phút": "每 30 分钟重复",
    "Báo lại mỗi 15 phút": "每 15 分钟重复",
    "Quản lý nhà": "家庭管理",
    "Xoá thành viên": "移除成员",
    "Đã xoá thành viên": "成员已移除",
    "Đồng ý": "确定",
    "Bạn chắc chắn muốn rời khỏi nhà này?": "确定要离开此家庭吗？",
    "Xoá thành viên?": "移除成员？",
    "Rời khỏi nhà?": "离开此家庭？",
    "Chỉ chủ nhà mới được thay đổi vai trò": "只有屋主可以更改角色",
    "Bạn không có quyền xoá thành viên này": "你没有权限移除此成员",
    "Bạn": "你",
    "Không có email": "无邮箱",
    "Chưa có số điện thoại": "暂无电话号码",
    "Không mở được ứng dụng gọi điện": "无法打开拨号应用",
    "Thành viên chưa cập nhật số điện thoại": "该成员尚未添加电话号码",
    "Hôm nay đã ghi nhận cảnh báo SOS": "今天已记录 SOS 警报",
    "Hôm nay đã ghi nhận cảnh báo khói": "今天已记录烟雾警报",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "手动布防已开启 - 切换到普通模式后关闭",
    "Thời gian lặp": "重复间隔",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "选择 0 表示只提醒一次。此设置同时用于手动布防和离家自动布防。",
    "Lặp báo động khi sự cố vẫn còn": "问题仍存在时重复 Alarm",
    "Đang được sử dụng": "当前使用中",
    "Chuyển về sử dụng thông thường": "切换回普通模式",
    "Chế độ nhà": "家庭模式",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "SOS 设备未记录警报。",
    "Cảm biến khói chưa ghi nhận bất thường.": "烟雾传感器未记录异常。",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.": "你或成员已手动开启布防。",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.": "由于你已离家，SafeHome 已自动开启布防。",
    "Nhà đang ở chế độ dùng bình thường.": "此家庭当前处于普通使用模式。",
    "Bảo vệ thủ công đang bật": "手动布防已开启",
    "Bảo vệ tự động đang bật": "自动布防已开启",
    "Bảo vệ đang tắt": "布防已关闭",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.": "你最近已打开应用检查状态。",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.": "建议定期打开应用检查权限、时间表和未读警报。",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.": "使用几次后，SafeHome 可以更好地评估你的应用检查习惯。",
    "Tần suất vào app ổn": "应用检查频率良好",
    "Đã lâu chưa vào app kiểm tra": "距离上次打开应用检查已有一段时间",
    "Đang ghi nhận tần suất vào app": "正在记录应用检查频率",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.": "请检查始终定位权限和后台条件。",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.": "此设备满足自动离家的运行条件。",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.": "如果希望离家时自动开启布防，可以启用此功能。",
    "Auto rời khỏi nhà chưa ổn": "自动离家尚未就绪",
    "Auto rời khỏi nhà đã sẵn sàng": "自动离家已就绪",
    "Auto rời khỏi nhà chưa bật": "自动离家未开启",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.": "建议添加烟雾传感器、SOS 或适合家庭的紧急设备。",
    "Chưa có thiết bị khẩn cấp": "尚无紧急设备",
    "Đã có thiết bị khẩn cấp": "已添加紧急设备",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.": "建议为睡眠时间或外出时设置 Alarm 时间表。",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.": "此家庭已有 Alarm 时间表或设备级警报时间表。",
    "Chưa set lịch Alarm": "尚未设置 Alarm 时间表",
    "Đã set lịch Alarm": "已设置 Alarm 时间表",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.": "建议至少设置一个 Reminder，避免忘记检查家庭。",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.": "应用会按计划提醒你检查家庭。",
    "Chưa setup Reminder": "尚未设置 Reminder",
    "Đã setup Reminder": "已设置 Reminder",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.": "如果此设备收不到警报，请重新打开应用或重新登录。",
    "Thiết bị chưa đăng ký nhận cảnh báo": "此设备尚未注册接收警报",
    "Thiết bị nhận cảnh báo bình thường": "此设备可以接收警报",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.": "iOS 对后台运行的管理比 Android 更严格；使用自动离家时请保持通知和始终定位开启。",
    "Cơ chế iOS": "iOS 机制",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.": "请检查后台权限和自启动，避免警报延迟。",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.": "设备已确认重要的后台条件。",
    "Cần kiểm tra chạy nền / tự khởi động": "请检查后台运行 / 自启动",
    "Chạy nền ổn định": "后台运行看起来稳定",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "某些 Android 手机在开启电池优化时可能延迟警报。",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.": "手机较少可能延迟 SafeHome 警报。",
    "Chưa tắt tối ưu pin": "尚未关闭电池优化",
    "Tối ưu pin không chặn app": "电池优化未阻止应用",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.": "自动离家需要始终定位才能稳定运行。",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.": "自动离家需要定位权限。",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.": "定位服务已关闭，因此自动离家可能不稳定。",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.": "只有使用自动离家时才需要此权限。",
    "Chưa cấp vị trí luôn luôn": "尚未允许始终定位",
    "Đã cấp vị trí luôn luôn": "已允许始终定位",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.": "iOS 不像 Android 那样全屏打开；应用使用系统通知和声音。",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.": "Android 使用全屏警报；如果手机阻止，请在设置中允许。",
    "Cảnh báo trên iOS": "iOS 上的警报",
    "Cảnh báo toàn màn hình": "全屏警报",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "如果通知被关闭，警报可能不会显示。",
    "Điện thoại có thể nhận thông báo SafeHome.": "此手机可以接收 SafeHome 通知。",
    "Chưa bật thông báo": "尚未开启通知",
    "Đã bật thông báo": "已开启通知",
    "Hệ thống: Sẵn sàng": "系统：已就绪",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "系统：可能会错过警报",
    "Cách bạn đang dùng app": "你使用应用的方式",
    "Thiết bị của bạn": "你的设备",
    "Kiểm tra điện thoại và cách bạn đang dùng app.": "检查你的手机以及你使用应用的方式。",
    "Hệ thống SafeHome": "SafeHome 系统",
    "Hệ thống: Đang kiểm tra...": "系统：正在检查...",
    "Đổi tên nhóm": "重命名分组",
    "Tên": "名称",
    "Không tìm thấy thiết bị trong nhà này": "在此家庭中未找到设备",
    "Không tìm thấy nhà của thông báo này": "未找到此通知对应的家庭",
    "Bạn không có quyền thay đổi vị trí nhà": "你没有权限更改家庭位置",
    "Hãy bật GPS để đặt vị trí nhà": "请开启 GPS 以设置家庭位置",
    "Bạn chưa cấp quyền vị trí": "尚未授予位置权限",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng": "请在应用设置中授予位置权限",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà": "已开启所有人离家时自动布防",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà": "已关闭所有人离家时自动布防",
    "Không thể thay đổi trạng thái Alarm": "无法更改 Alarm 状态",
    "Đã tắt toàn bộ Alarm của nhà": "已关闭家庭的所有 Alarm",
    "QR gia nhập nhiều nhà không hợp lệ": "无效的多家庭加入二维码",
    "Bạn đang là chủ các nhà này": "你已经是这些家庭的屋主",
    "QR gia nhập không hợp lệ": "无效的加入二维码",
    "Bạn đang là chủ nhà này": "你已经是此家庭的屋主",
    "QR này không phải mã xin gia nhập nhà": "此二维码不是家庭加入码",
    "Rời khỏi Home này?": "离开此 Home？",
    "Đã xoá nhà": "家庭已删除",
    "Một chủ nhà": "一位屋主",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "已发送屋主权限转移请求",
    "Đã gửi yêu cầu xoá thiết bị": "已发送设备删除请求",
    "QR này không phải mã xin gia nhập Home": "此二维码不是 Home 加入码",
    "Chưa chọn nhà để kiểm tra": "尚未选择要检查的家庭",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner": "请使用 Owner 账户执行检查",
    "Không đọc được dữ liệu nhà": "无法读取家庭数据",
    "Nhà cần có ít nhất một thiết bị để test": "家庭至少需要一台设备才能测试",
    "Firebase Rules: ĐẠT": "Firebase Rules: 通过",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: 有问题",
    "Thêm Home": "添加 Home",
    "Khói đã an toàn": "烟雾状态已安全",
    "Mở cài đặt": "打开设置",
    "Để sau": "稍后",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.": "SafeHome 需要\"始终允许\"位置权限，才能在应用后台运行时识别你离家或回家。",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.": "SafeHome 目前只能在你使用应用时访问位置。\n\n请打开位置权限并选择\"始终允许\"，以便离家自动保护功能在后台也能继续工作。",
    "Cho phép vị trí luôn luôn": "始终允许位置",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.": "你的家庭将被删除。\n你将离开共享家庭。",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "此操作会更改所选家庭中所有安全设备的 Home Alarm 计划。\n\n正在使用按家庭 Alarm 设置的成员会受到影响。\n处于仅自己模式的个人 Alarm 不会改变。",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "此操作会为所选家庭添加 Home Reminder。\n\n正在使用按家庭 Reminder 设置的成员会受到影响。\n处于仅自己模式的个人 Reminder 不会改变。",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "开启后，安全设备会立即开始监测。\n\n离家自动布防将暂停。有人回家时此模式不会自动关闭，只能由有权限的成员手动切换回普通模式。",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...": "此操作将更改今天部分设备的报警时间……",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.": "此操作将关闭此家庭的所有 Alarm。你将不再在此手机上收到危险警报。",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.": "Alarm 正在使用家庭设置。\n\n你将根据屋主或管理员设置的共享 Alarm 日程接收警报。",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.": "Alarm 正在使用个人设置。\n\n你将根据此账户设置的个人 Alarm 日程接收警报。",
    "Không thể đăng nhập bằng Google": "无法使用 Google 登录",
    "Không đặt được mật khẩu": "无法设置密码",
    "Chấp nhận": "接受",
    "Cho phép": "允许",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.": "无法接受邀请。请重试。",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.": "无法接受加入请求。请重试。",
    "Từ chối": "拒绝",
    "Lời mời từ chủ nhà": "来自屋主的邀请",
    "Nhận quyền chủ nhà": "接收屋主权限",
    "Một người dùng SafeHome": "一位 SafeHome 用户",
    "Lời mời gia nhập": "加入邀请",
    "Lời xin vào nhà": "加入家庭请求",
    "Nhập HUB ID": "输入 HUB ID",
    "VD: HUB_001": "例如：HUB_001",
    "Pair": "配对",
    "Mật khẩu tối thiểu 6 ký tự": "密码至少需要 6 个字符",
    "Mật khẩu nhập lại không khớp": "两次输入的密码不一致",
    "Tạo mật khẩu": "创建密码",
    "Mật khẩu mới": "新密码",
    "Nhập lại mật khẩu": "再次输入密码",
    "Xác nhận tắt cảnh báo": "确认关闭警报",
    "HỦY": "取消",
    "XÁC NHẬN": "确认",
    "CẦN KIỂM TRA": "需要检查",
    "KIỂM TRA NHÀ": "检查家庭",
    "ĐÓNG NHẮC NHỞ": "关闭提醒",
    "SafeHome Security Alert": "SafeHome 安全警报",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "请在应用设置中将位置权限选择为始终允许",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.": "其他人扫描此二维码以发送加入家庭的请求。",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.": "此家庭及其中所有设备将被永久删除。",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.": "Google 账号需要创建额外密码才能使用安全功能。",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.": "此名称只会显示在你的账号中。",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.": "名称和地址将更新给家庭中的所有成员。",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ 今日暂停 Alarm",
    "Alarm": "Alarm",
    "Bạn không có quyền thực hiện thao tác này。": "你没有权限执行此操作。",
    "Cài đặt": "设置",
    "Cập nhật": "更新",
    "Chọn ngôn ngữ": "选择语言",
    "Chưa có dữ liệu thiết bị để đánh giá": "暂无设备数据可评估",
    "Chuyển quyền sở hữu cho thành viên khác": "将所有权转移给其他成员",
    "Có": "是",
    "Cửa đã đóng an toàn": "门已安全关闭",
    "Đã xảy ra lỗi. Vui lòng thử lại.": "发生错误。请重试。",
    "Đang kiểm tra kết nối Hub": "正在检查 Hub 连接",
    "Đang mở khi nhà ở chế độ Bảo vệ": "家庭处于布防模式时仍打开",
    "Đang mở trong giờ Alarm": "Alarm 时段内被打开",
    "Đang tải...": "正在加载...",
    "Hồ sơ, yêu cầu và lời mời tham gia": "个人资料、请求和邀请",
    "Hub chưa gửi trạng thái": "Hub 状态不可用",
    "Hub mất kết nối": "Hub 已断开",
    "Hub tín hiệu bình thường": "Hub 连接正常",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ": "家庭处于布防模式时门锁未锁",
    "Khóa đang mở trong giờ Alarm": "Alarm 时段内门锁未锁",
    "Không có thông báo": "没有通知",
    "Khu vực nguy hiểm": "危险区域",
    "Kiểm tra thiết bị trong nhà này": "查看此家庭中的设备",
    "Mất điện lưới": "市电断开",
    "Mời người khác tham gia nhà này": "邀请他人加入此家庭",
    "Môi trường hiện tại": "当前环境",
    "MQTT mất kết nối": "MQTT 已断开",
    "Ngôn ngữ": "语言",
    "Nhà đã chia sẻ": "共享家庭",
    "Nhà đang hoạt động bình thường": "家庭运行正常",
    "Nhập email": "输入邮箱",
    "Phòng": "房间",
    "Quản trị viên": "管理员",
    "Reminder": "提醒",
    "SafeHome": "SafeHome",
    "Sóng yếu": "信号弱",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "账号与系统",
    "Tài khoản cá nhân": "个人账号",
    "Tạo tài khoản": "创建账号",
    "Thành viên": "成员",
    "Thành viên trong nhà": "家庭成员",
    "Thay đổi ngôn ngữ hiển thị": "更改显示语言",
    "Thêm, đổi tên và sắp xếp phòng": "添加、重命名和排序房间",
    "Thiết bị đang được giám sát": "设备正在被监控",
    "Tiếng Anh": "英语",
    "Tiếng Hàn": "韩语",
    "Tiếng Nhật": "日语",
    "Tiếng Trung": "中文",
    "Tiếng Việt": "越南语",
    "Toàn bộ thiết bị": "全部设备",
    "Vai trò": "角色",
    "Về nhà": "在家",
    "Xem và quản lý quyền thành viên": "查看和管理成员权限",
    "Xóa": "删除",
    "Xóa nhà": "删除家庭",
    "Xoá toàn bộ dữ liệu và thiết bị": "删除所有数据和设备",
    "TẮT CẢNH BÁO": "关闭警报",
    "Đã tạo nhà": "家庭已创建",

    "Mode Bảo vệ thủ công đã bật": "手动保护模式已开启",
    "Báo động không lặp lại.": "警报不会重复。",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.": "如果问题仍然存在，警报将在 \$securityModeRepeatMinutes 分钟后重复。",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage": "\$actorName 已为 \"\$homeName\" 开启手动保护模式。只有有权限的成员切回普通模式时，此模式才会关闭。\$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".": "你已为 \"\$homeName\" 开启 Alarm。",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".": "你已关闭 \"\$homeName\" 的所有 Alarm。",
    "Thành viên mới": "新成员",
    "Thành viên rời nhà": "成员已离家",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".": "\$displayMemberName 已离开 \"\$homeName\"。",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".": "\$actorName 已将 \"\$homeName\" 中 \$memberName 的角色从 \$oldRoleName 改为 \$newRoleName。",
    "Còn \$count tin nhắn chưa đọc": "\$count 条未读消息",
    "Hãy an tâm nghỉ ngơi.": "你可以放心。",
    "Có thiết bị chưa an toàn.": "有些设备不安全。",
    "SafeHome đang cập nhật vị trí": "SafeHome 正在更新位置",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.": "正在监测以自动开启保护模式。",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.": "使用位置在所有人离家时自动开启保护模式。",
    "CẢNH BÁO SOS": "SOS 警报",
    "CẢNH BÁO KHÓI / CHÁY": "烟雾/火灾警报",
    "CẢNH BÁO NGẬP NƯỚC": "漏水警报",
    "CẢNH BÁO RÒ KHÍ": "燃气泄漏警报",
    "CẢNH BÁO CỬA": "门警报",
    "CẢNH BÁO AN NINH": "安全警报",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.": "无法通过 SafeHome 确认。请检查连接并重试。",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?": "请只在检查家中情况后停止警报。\n\n确定要停止警报吗？",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome 检测到警报",
    "Mở SafeHome để kiểm tra ngay.": "打开 SafeHome 立即检查。",
    "\$count tin nhắn mới": "\$count 条新消息",
    "Tin nhắn HomeChat": "HomeChat 消息",
    "\$senderName đã gửi một tin nhắn": "\$senderName 发送了一条消息",
    "Bạn có tin nhắn mới": "你有一条新消息",
    "Mode Bảo vệ sẽ chỉ báo động một lần": "保护模式只会报警一次",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút": "保护模式将在 \$minutes 分钟后重复报警",
    "Đã gửi yêu cầu gia nhập \$count nhà": "已向 \$count 个家庭发送加入请求",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".": "\$requesterName 请求加入 \"\$homeName\"。",
    "Bạn đã xoá nhà \"\$homeName\".": "你已删除 \"\$homeName\"。",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.": "你已向 \$email 发送 \"\$homeName\" 的所有权转让请求。",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.": "\$actorName 想将 \"\$homeName\" 的所有权转让给你。",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".": "\$actorName 邀请你加入 \"\$homeName\"。",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".": "SafeHome 正在从 \"\$homeName\" 移除 \"\$deviceName\"。",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".": "设备 \"\$deviceName\" 已添加到 \"\$homeName\"。",
    "Bạn đã tạo nhà \"\$name\".": "你已创建家庭 \"\$name\"。",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.": "\$actorName 已将家庭名称更新为 \"\$newName\" 并更改了地址。",
    "\$actorName đã đổi tên nhà thành \"\$newName\".": "\$actorName 已将家庭重命名为 \"\$newName\"。",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".": "\$actorName 已更新 \"\$newName\" 的地址。",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".": "\$actorName 已将 \"\$homeName\" 中的设备 \"\$oldDeviceName\" 重命名为 \"\$newName\"。",
    "Đang ghép nối: \$seconds giây": "正在配对：\$seconds 秒",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.": "\"\$homeName\" 已开启设备配对 \$seconds 秒。",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)": "暂停时间必须在 Alarm 日程范围内（\$start → \$end）",
    "\$passCount/\$total bài test đạt\n\n": "\$passCount/\$total 项测试通过\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.": "\$name 尚未在个人资料中添加电话号码。",
    "Tin nhắn mới trong \$homeName": "\$homeName 中有新消息",
    "\$current/\$total kết quả": "\$current/\$total 个结果",
    "Đang trả lời \$name": "正在回复 \$name",
    "\"\$name\" phát hiện khói trong \"\$homeName\".": "\"\$name\" 在 \"\$homeName\" 中检测到烟雾。",
    "\"\$name\" đã trở lại trạng thái bình thường.": "\"\$name\" 已恢复正常。",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".": "\"\$name\" 在 \"\$homeName\" 中触发了 SOS。",
    "\"\$name\" đã hết trạng thái SOS.": "\"\$name\" 已不再处于 SOS 状态。",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".": "\"\$name\" 报告 \"\$homeName\" 中有拆动/撬动。",
    "\"\$name\" đã hết cảnh báo tháo/cạy.": "\"\$name\" 的拆动/撬动警报已解除。",
    "\"\$name\" đã đóng trong \"\$homeName\".": "\"\$name\" 已在 \"\$homeName\" 中关闭。",
    "\"\$name\" đang mở trong \"\$homeName\".": "\"\$name\" 在 \"\$homeName\" 中处于打开状态。",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.": "\"\$homeName\" 中的 \"\$name\" 电量低。",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.": "\"\$homeName\" 中的 \"\$name\" 已离线。",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.": "\"\$homeName\" 中的 \"\$name\" 已重新上线。",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".": "\"\$name\" 在 \"\$homeName\" 中记录到高温。",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".": "\"\$name\" 在 \"\$homeName\" 中记录到高湿度。",
    "Có nút SOS vừa được kích hoạt": "有 SOS 按钮被触发",
    "Có dấu hiệu khói hoặc cháy": "检测到烟雾或火灾",
    "Có dấu hiệu ngập nước": "检测到漏水/积水",
    "Có dấu hiệu rò khí": "检测到燃气泄漏",
    "Có cửa đang mở hoặc thiết bị bị tháo": "有门打开或设备被拆动/撬动",
    "Có thiết bị đang cảnh báo": "有设备正在报警",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.": "如果无人确认，SafeHome 将转为紧急呼叫。",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.": "如果问题尚未处理，将在 \$time 再次提醒。",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.": "如果问题尚未处理，将按 Alarm 日程再次提醒。",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".": "\"\$deviceName\" 已在 \"\$resolvedHomeName\" 中关闭。",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".": "\"\$deviceName\" 在 \"\$resolvedHomeName\" 中处于打开状态。",
    "\$count nhà đã chọn": "已选择 \$count 个家庭",
    "🚨 \$count nhà không an toàn\$suffix": "🚨 \$count 个家庭不安全\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix": "⚠️ \$count 个家庭需要注意\$suffix",
    "✅ \$count nhà an toàn": "✅ \$count 个家庭安全",
    "\$count nhà đang được theo dõi": "正在监测 \$count 个家庭",
    "\$minutes phút": "\$minutes 分钟",
    "Đã cài Reminder cho \$updatedHomes nhà.": "已为 \$updatedHomes 个家庭设置 Reminder。",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n": "已为 \$updatedHomes 个家庭中的 \$updatedDevices 台设备设置 Alarm。\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.": "已分享你管理的家庭。\n\n由于你没有分享权限，已跳过 \$skipped 个家庭。",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh": "Alarm 已应用到 \$count 台安全设备",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh": "将相同日程应用到 \$count 台安全设备",
    "\$count phút trước": "\$count 分钟前",
    "\$count giờ trước": "\$count 小时前",
    "\${count}h trước": "\${count}小时前",
    "\${hours}h\$minutes' trước": "\${hours}小时\${minutes}分钟前",
    "\$count ngày trước": "\$count 天前",
    "\$count tháng trước": "\$count 个月前",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?": "确定要将 \$name 从这个家移除吗？",
    "\$targetEmail\nXin gia nhập \"\$homeName\"": "\$targetEmail\n请求加入 \"\$homeName\"",
    "Xin gia nhập \"\$homeName\"": "请求加入 \"\$homeName\"",
    "Bạn được mời nhận quyền nhà \"\$homeName\"": "你被邀请接收 \"\$homeName\" 的所有权",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"": "\$ownerEmail\n邀请你加入 \"\$homeName\"",
    "Mời bạn gia nhập \"\$homeName\"": "邀请你加入 \"\$homeName\"",
    "Cần kiểm tra: \$joined": "需要检查：\$joined",
    "Cập nhật \$value": "已更新：\$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.": "添加你的第一台 SafeHome 设备，开始监测这个家。",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.": "请先检查紧急警报，必要时联系家中成员。",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "没有家庭成员在家，但有门或锁打开。请立即检查。",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "在让这个家保持保护模式前，请先检查打开的门或锁。",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.": "可能仍有人在家；如果是这样，请切回普通模式。",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.": "有成员位置未知。请提醒他们打开 app 或检查位置权限。",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "有设备断开连接。请检查电池、电源或安装位置。",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.": "有设备电量低。请尽快更换电池，避免漏掉警报。",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.": "尚未设置 Reminder。请创建定期检查家庭的日程。",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.": "尚未设置 Alarm 日程。请在通常无人时段启用保护。",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.": "暂时无需立即处理。继续监测这个家即可。",
    "Lặp sau \$minutes phút": "\$minutes 分钟后重复",
    "Đang dùng • \$repeatText": "启用中 • \$repeatText",
    "Giám sát an ninh • \$repeatText": "安全监测 • \$repeatText",
    "Gia đình: \$mode": "家庭模式：\$mode",
    "Gợi ý xử lý": "处理建议",
    "Phát hiện \$count vấn đề cần xử lý": "\$count 个问题需要处理",
    "Hôm nay các cửa đã được sử dụng \$count lần": "今天门已使用 \$count 次",
    "Đã ghi nhận \$count hoạt động gần đây": "已记录 \$count 条最近活动",
    "Hệ thống: Cần kiểm tra \$issueCount mục": "系统：需要检查 \$issueCount 项",
    "FCM token đã sẵn sàng trên điện thoại này.": "此手机上的 FCM token 已准备好。",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.": "FCM token 已准备好，但 Auto Away 仍缺少条件。",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.": "发现 \$emergencyTotal 个紧急设备。建议至少包含烟雾传感器和 SOS。",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?": "将家庭所有权转让给：\n\$targetEmail？",
    "\$count cửa đã đóng an toàn": "\$count 扇门已安全关闭",
    "\$count cửa và khóa đã an toàn": "\$count 扇门和锁已安全",
    "\$count thiết bị đang được theo dõi": "正在监测 \$count 台设备",
    "Cập nhật \$timeText": "已更新 \$timeText",
    "Dữ liệu gần nhất cập nhật \$count phút trước": "最新数据更新于 \$count 分钟前",
    "Dữ liệu gần nhất cập nhật \$count giờ trước": "最新数据更新于 \$count 小时前",
    "Thành viên trong nhà: \$count": "在家成员：\$count",
    "Thành viên bên ngoài: \$count": "外出成员：\$count",
    "Chưa xác định vị trí: \$count": "位置未知：\$count",
    "Môi trường hiện tại: \$environment": "当前环境：\$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ": "\$name：家庭处于保护模式时打开",
    "An tâm hơn trong từng ngôi nhà": "让每个家庭更安心",
    "Báo động SafeHome": "SafeHome 警报",
    "Có cảnh báo an ninh cần kiểm tra ngay.": "有安全警报需要你立即处理。",
    "Có cảnh báo cần kiểm tra": "有警报需要你检查",
    "Tự đóng sau \$time": "\$time 后自动关闭",
  };

  static const Map<String, String> _korean = {
    "Không tìm thấy người dùng": "사용자를 찾을 수 없음",
    "Không đọc được số điện thoại": "전화번호를 읽을 수 없음",
    "Tin nhắn quá dài": "메시지가 너무 깁니다",
    "Không gửi được tin nhắn": "메시지를 보낼 수 없음",
    "Bạn không có quyền sửa lịch chung của nhà": "공유된 집 일정을 수정할 권한이 없습니다",
    "Nhà của bạn": "내 집",
    "Tải tin cũ hơn": "이전 메시지 불러오기",
    "SafeHome": "SafeHome",
    "Nhà chưa đặt tên": "이름 없는 집",
    "Nhà": "집",
    "Thêm nhà": "집 추가",
    "Tạo nhà mới": "새 집 만들기",
    "Thêm nhà mới": "새 집 추가",
    "Xin gia nhập nhà": "집 참여 요청",
    "Nhà đã chia sẻ": "공유된 집",
    "Nhà được chia sẻ": "공유된 집",
    "Thành viên trong nhà": "집 구성원",
    "Chưa có thông tin": "정보 없음",
    "Chưa cập nhật": "아직 업데이트 없음",
    "Chủ nhà": "집 주인",
    "Địa chỉ": "주소",
    "Tên nhà": "집 이름",
    "Vai trò": "역할",
    "Thành viên": "구성원",
    "Quản trị viên": "관리자",
    "Đang tải...": "로딩 중...",
    "Quản lý nhà": "집 관리",
    "Chia sẻ nhà": "집 공유",
    "Mời người khác tham gia nhà này": "다른 사람을 이 집에 초대",
    "Xem và quản lý quyền thành viên": "구성원 권한 보기 및 관리",
    "Quản lý phòng": "방 관리",
    "Thêm, đổi tên và sắp xếp phòng": "방 추가, 이름 변경 및 정렬",
    "Toàn bộ thiết bị": "전체 기기",
    "Kiểm tra thiết bị trong nhà này": "이 집의 기기 확인",
    "Chuyển quyền chủ nhà": "집 주인 권한 이전",
    "Chuyển quyền sở hữu cho thành viên khác": "소유권을 다른 구성원에게 이전",
    "Đặt vị trí nhà và bật bảo vệ tự động": "집 위치를 설정하고 자동 보호를 켭니다",
    "Chuyển quyền chủ nhà hoặc xoá nhà": "집 소유권 이전 또는 집 삭제",
    "Tài khoản & hệ thống": "계정 및 시스템",
    "Tài khoản cá nhân": "개인 계정",
    "Hồ sơ, yêu cầu và lời mời tham gia": "프로필, 요청 및 초대",
    "Ngôn ngữ": "언어",
    "Thay đổi ngôn ngữ hiển thị": "표시 언어 변경",
    "Chọn ngôn ngữ": "언어 선택",
    "Tiếng Việt": "베트남어",
    "Tiếng Anh": "영어",
    "Tiếng Trung": "중국어",
    "Tiếng Hàn": "한국어",
    "Khu vực nguy hiểm": "위험 구역",
    "Xoá nhà": "집 삭제",
    "Xóa nhà": "집 삭제",
    "Xoá toàn bộ dữ liệu và thiết bị": "모든 집 데이터와 기기 삭제",
    "Bạn không có quyền thực hiện thao tác này.": "이 작업을 수행할 권한이 없습니다.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.": "작업을 완료할 수 없습니다. 다시 시도해 주세요.",
    "An toàn": "안전",
    "Cần chú ý": "확인 필요",
    "Không an toàn": "안전하지 않음",
    "ĐÃ AN TOÀN": "안전",
    "CẦN CHÚ Ý": "확인 필요",
    "CHƯA AN TOÀN": "안전하지 않음",
    "Tổng hợp trạng thái nhà": "집 상태 요약",
    "Tự động đánh giá": "자동 평가",
    "Tổng quan hôm nay": "오늘 요약",
    "Chưa đủ dữ liệu để đánh giá": "평가할 데이터가 충분하지 않습니다",
    "Chưa có dữ liệu để đánh giá": "평가할 데이터가 부족합니다",
    "Nhấn để xem chi tiết...": "자세히 보려면 누르세요...",
    "Nhà đang hoạt động bình thường": "집이 정상적으로 작동 중입니다",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "집이 안정적으로 작동 중입니다.",
    "Ngôi nhà đang hoạt động ổn định": "집이 안정적으로 작동 중입니다",
    "Thiết bị đang được giám sát": "기기 모니터링 중",
    "Chưa có dữ liệu trạng thái": "상태 데이터가 없습니다",
    "Chưa có dữ liệu tổng quan": "요약 데이터가 없습니다",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "자세히 분석할 새 활동이 많지 않습니다.",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.": "집에 확인이 필요한 신호가 있습니다. 아래 상태를 확인해 주세요.",
    "Cần xử lý ngay": "즉시 처리 필요",
    "Cần kiểm tra": "확인 필요",
    "Chưa có dữ liệu thiết bị để đánh giá": "평가할 기기 데이터가 없습니다",
    "Đang kiểm tra kết nối Hub": "Hub 연결 확인 중",
    "Hub kết nối bình thường": "Hub 연결 정상",
    "Hub tín hiệu bình thường": "Hub 연결 정상",
    "Kết nối cần kiểm tra": "연결 확인 필요",
    "Thiết bị đang Offline": "기기 오프라인",
    "Thiết bị đang Online": "기기 온라인",
    "Mất kết nối": "연결 끊김",
    "Hub mất kết nối": "Hub 연결 끊김",
    "MQTT mất kết nối": "MQTT 연결 끊김",
    "Bảo vệ": "보호",
    "Chế độ Bảo vệ": "보호 모드",
    "Bình thường": "일반 모드",
    "Tắt": "꺼짐",
    "Tự động Bảo vệ khi rời nhà": "외출 시 자동 보호",
    "Chưa đặt vị trí nhà": "집 위치가 설정되지 않았습니다",
    "Đặt vị trí nhà tại đây": "현재 위치를 집 위치로 설정",
    "Bán kính bảo vệ mặc định: 150 m": "기본 보호 반경: 150 m",
    "Đã đặt vị trí nhà": "집 위치가 설정되었습니다",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.": "각 구성원은 앱이 백그라운드에서 실행될 때 외출/귀가 상태가 작동하도록 위치 권한을 항상 허용해야 합니다.",
    "Lưu cài đặt": "설정 저장",
    "An ninh ra/vào": "출입 보안",
    "Nguy hiểm khẩn cấp": "긴급 위험",
    "Môi trường": "환경",
    "Điều khiển & hạ tầng": "제어 및 인프라",
    "Toàn bộ thiết bị SafeHome": "전체 SafeHome 기기",
    "Cửa ra/vào": "출입문",
    "Cửa": "문",
    "Cửa sổ": "창문",
    "Cổng": "대문",
    "Khóa thông minh": "스마트 잠금장치",
    "Chuyển động": "움직임",
    "Hiện diện": "재실",
    "Rung/chấn động": "진동/충격",
    "Kính vỡ": "유리 파손",
    "Báo khói": "연기 경보기",
    "Báo nhiệt": "열 경보기",
    "Khí CO": "일산화탄소",
    "Báo gas": "가스 경보기",
    "Báo ngập/rò nước": "누수 경보기",
    "Nút SOS": "SOS 버튼",
    "Nhiệt độ/Độ ẩm": "온도/습도",
    "Bụi mịn PM2.5": "초미세먼지 PM2.5",
    "CO₂": "CO₂",
    "Chất lượng không khí": "공기질",
    "Ổ điện thông minh": "스마트 플러그",
    "Còi báo động": "사이렌",
    "Van thông minh": "스마트 밸브",
    "Camera": "카메라",
    "Chuông cửa": "초인종",
    "Bàn phím an ninh": "보안 키패드",
    "Bộ mở rộng sóng": "중계기",
    "Hub trung tâm": "중앙 Hub",
    "Đo điện năng": "전력 측정",
    "Nguồn dự phòng UPS": "UPS 예비 전원",
    "Tình trạng": "상태",
    "Đang mở": "열림",
    "Đang đóng": "닫힘",
    "Sẵn sàng": "준비됨",
    "Đang hoạt động": "작동 중",
    "Tháo/Lắp": "분리 감지",
    "Bị tháo": "분리 감지",
    "Pin": "배터리",
    "Pin yếu": "배터리 부족",
    "Tín hiệu": "신호",
    "Sóng yếu": "신호 약함",
    "Chưa liên kết": "연결되지 않음",
    "Liên lạc cuối": "마지막 연결",
    "Sự kiện cuối": "마지막 이벤트",
    "Cập nhật": "업데이트",
    "Vừa xong": "방금 전",
    "Chưa có cập nhật": "아직 업데이트 없음",
    "Alarm": "Alarm",
    "Reminder": "Reminder",
    "Hẹn giờ Reminder": "Reminder 예약",
    "Hẹn giờ Alarm": "Alarm 예약",
    "Alarm thiết bị": "기기 Alarm",
    "Alarm đã được bật": "Alarm이 켜졌습니다",
    "Tắt Alarm": "Alarm 끄기",
    "Tạm tắt Alarm hôm nay": "오늘 Alarm 일시 중지",
    "Lưu ý tạm tắt Alarm": "Alarm 일시 중지 안내",
    "Từ": "시작",
    "Đến": "종료",
    "Bắt đầu": "시작",
    "Kết thúc": "종료",
    "Về nhà": "귀가",
    "Về muộn": "늦게 귀가",
    "Ra ngoài": "외출",
    "Khác": "기타",
    "Lưu": "저장",
    "Xoá lịch tạm tắt": "일시 중지 일정 삭제",
    "Xóa lịch tạm tắt": "일시 중지 일정 삭제",
    "Cài đặt bảo mật": "보안 설정",
    "Báo động toàn màn hình": "전체 화면 알림",
    "Quyền báo động toàn màn hình": "전체 화면 알림 권한",
    "Đã được cấp quyền": "권한 허용됨",
    "Mở cài đặt hệ thống": "시스템 설정 열기",
    "Yêu cầu & lời mời": "요청 및 초대",
    "Giới tính": "성별",
    "SĐT": "전화번호",
    "Ngày sinh": "생년월일",
    "Xem lời mời chia sẻ và xin gia nhập": "공유 초대와 참여 요청 보기",
    "Không có yêu cầu hoặc lời mời nào": "요청 또는 초대가 없습니다",
    "Đăng xuất": "로그아웃",
    "Đăng xuất?": "로그아웃할까요?",
    "Thoát tài khoản khỏi thiết bị này": "이 기기에서 계정 로그아웃",
    "Không": "아니요",
    "OK": "확인",
    "Đã hiểu": "확인",
    "Huỷ": "취소",
    "Hủy": "취소",
    "Có": "예",
    "Thông báo nhà": "집 알림",
    "Vai trò thành viên đã thay đổi": "구성원 역할이 변경되었습니다",
    "Phát hiện bất thường": "이상 감지",
    "Cửa đang mở": "문이 열려 있음",
    "Cửa đã đóng": "문이 닫힘",
    "Tamper bình thường": "분리 감지 정상",
    "Thiết bị bị tháo": "기기 분리됨",
    "Không có thông báo": "알림 없음",
    "Chưa phân phòng": "방 미지정",
    "Phòng mặc định": "기본 방",
    "Phòng khách": "거실",
    "Thêm phòng": "방 추가",
    "Phòng": "방",
    "Đổi tên": "이름 변경",
    "Xoá": "삭제",
    "Xóa": "삭제",
    "Thêm": "추가",
    "Đóng": "닫기",
    "Xác nhận": "확인",
    "Email": "이메일",
    "Mật khẩu": "비밀번호",
    "Xác nhận mật khẩu": "비밀번호 확인",
    "Đăng nhập": "로그인",
    "Đăng ký mới": "새 계정 만들기",
    "Ghi nhớ tài khoản": "계정 기억하기",
    "Chưa có tài khoản? Đăng ký": "계정이 없나요? 가입하기",
    "Đã có tài khoản? Đăng nhập": "이미 계정이 있나요? 로그인",
    "Tạo tài khoản": "계정 만들기",
    "Quên mật khẩu?": "비밀번호를 잊으셨나요?",
    "Tính năng đang được phát triển": "이 기능은 개발 중입니다",
    "Nhập email": "Email 입력",
    "Nhập mật khẩu": "비밀번호 입력",
    "Tên": "이름",
    "Số điện thoại": "전화번호",
    "Nam": "남성",
    "Nữ": "여성",
    "Ngày": "일",
    "Tháng": "월",
    "Năm": "년",
    "Thông tin cá nhân": "개인 정보",
    "Thiết lập tài khoản": "계정 설정",
    "Vui lòng nhập đủ thông tin": "필수 정보를 모두 입력해 주세요",
    "Không thể lưu thông tin": "정보를 저장할 수 없습니다",
    "Đã lưu thông tin": "정보가 저장되었습니다",
    "Lỗi lưu profile": "프로필 저장 오류",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp": "긴급 상황에 사용할 전화번호를 추가하세요",
    "Lưu thay đổi": "변경 사항 저장",
    "Hoàn tất": "완료",
    "Cài đặt": "설정",
    "Thông báo": "알림",
    "Tìm kiếm": "검색",
    "Tìm nhà": "집 검색",
    "Không có kết quả": "결과 없음",
    "Tìm ngôn ngữ": "언어 검색",
    "Đặt Home Reminder": "Home Reminder 설정",
    "Đặt Home Alarm": "Home Alarm 설정",
    "Tiếp tục": "계속",
    "Xác nhận xoá nhà": "집 삭제 확인",
    "Chưa share cho ai": "아직 공유한 사람이 없습니다",
    "Đặt Reminder / Alarm nhà đã chọn": "선택한 집의 Reminder / Alarm 설정",
    "Chia sẻ nhà đã chọn": "선택한 집 공유",
    "Mở danh sách chia sẻ nhà": "집 공유 목록 열기",
    "Xoá các nhà đã chọn?": "선택한 집을 삭제할까요?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "선택한 집이 영구적으로 삭제됩니다.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn": "또는 QR 코드를 스캔하여 선택한 집 참여를 요청하세요",
    "Email người nhận": "받는 사람 이메일",
    "Mời thành viên bằng mã QR": "QR 코드로 구성원 초대",
    "Tạo một ngôi nhà mới của bạn": "새 집을 만듭니다",
    "Quét mã QR được chủ nhà chia sẻ": "집 주인이 공유한 QR 코드를 스캔합니다",
    "Nhắn gì đó...": "메시지를 입력하세요...",
    "Quét QR HUB": "HUB QR 스캔",
    "Đưa mã QR vào giữa khung": "QR 코드를 프레임 가운데에 맞추세요",
    "Chế độ áp dụng": "적용 모드",
    "Theo nhà": "집 기준",
    "Riêng tôi": "나만",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập": "집 주인 또는 관리자가 설정한 공용 일정을 사용합니다",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn": "내 계정에만 적용되는 개인 일정을 사용합니다",
    "Thiết lập nhanh Alarm": "Alarm 빠른 설정",
    "Thiết lập nhanh toàn bộ thiết bị": "모든 기기 빠른 설정",
    "Không lặp lại": "반복 없음",
    "Thời gian lặp lại": "반복 시간",
    "Chưa thiết lập": "설정되지 않음",
    "Đã thiết lập": "설정됨",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.": "Reminder는 선택한 시간에 집의 안전 상태를 확인하도록 알려줍니다.",
    "Thêm Reminder": "Reminder 추가",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...": "이 작업은 오늘 일부 기기의 Alarm 시간을 변경합니다...",
    "Cửa đã đóng an toàn": "문이 안전하게 닫힘",
    "Nhiệt độ cao": "온도 높음",
    "Độ ẩm cao": "습도 높음",
    "Có khói": "연기 감지",
    "SOS": "SOS",
    "SOS đã kết thúc": "SOS 종료됨",
    "SOS được kích hoạt": "SOS 활성화됨",
    "Rò rỉ gas": "가스 누출 감지",
    "Phát hiện ngập nước": "누수 감지",
    "Phát hiện chuyển động": "움직임 감지",
    "Không có chuyển động": "움직임 감지 안 됨",
    "Phát hiện hiện diện": "재실 감지",
    "Phát hiện rung/chấn động": "진동/충격 감지",
    "Phát hiện kính vỡ": "유리 파손 감지",
    "Nhiệt độ nguy hiểm": "위험 온도 감지",
    "Phát hiện khí CO": "일산화탄소 감지",
    "Đang mở khi nhà ở chế độ Bảo vệ": "집이 보호 모드일 때 열려 있음",
    "Đang mở trong giờ Alarm": "Alarm 시간 중 열림",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ": "보호 모드에서 잠금 해제됨",
    "Khóa đang mở trong giờ Alarm": "Alarm 시간 중 잠금 해제됨",
    "Khóa đang mở": "잠금 해제됨",
    "Mất điện lưới": "전원 끊김",
    "Hub chưa gửi trạng thái": "Hub 상태 없음",
    "Thiết bị mới": "새 기기",
    "Thiết bị offline": "기기 오프라인",
    "Thiết bị online": "기기 온라인",
    "Báo động kích hoạt": "알람 활성화됨",
    "Báo động đã tắt": "알람 꺼짐",
    "Thử lại": "다시 시도",
    "Không thể tải dữ liệu tài khoản": "계정 데이터를 불러올 수 없습니다",
    "Đã chia sẻ nhà thành công.": "집 공유가 완료되었습니다.",
    "Tìm nhà...": "집 검색...",
    "Đã rời khỏi nhà": "집에서 나갔습니다",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.": "공유된 집에서 나가게 됩니다.",
    "Các nhà của bạn sẽ bị xoá.\n": "내 집은 삭제됩니다.\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n": "선택한 집의 모든 보안 기기 Home Alarm 일정을 변경합니다.\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n": "선택한 집에 Home Reminder를 추가합니다.\n\n",
    "Xác nhận thay đổi Alarm": "Alarm 변경 확인",
    "Xác nhận thay đổi Reminder": "Reminder 변경 확인",
    "Lặp lại khi sự cố vẫn còn": "문제가 계속되면 반복",
    "Thời gian lặp lại Alarm": "Alarm 반복 시간",
    "VD: Mr Chung": "예: Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 아직 집이 없습니다",
    "Vẫn chuyển về Bình thường": "그래도 일반 모드로 전환",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.": "외출 시 자동 보호가 아직 켜져 있습니다. 모든 구성원이 아직 외출 중이면 몇 분 후 시스템이 보호 모드를 다시 켤 수 있습니다.",
    "Chuyển về Bình thường?": "일반 모드로 전환할까요?",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n": "켜면 보안 기기가 즉시 모니터링됩니다.\n\n",
    "Bật Bảo vệ thủ công?": "수동 보호 모드를 켜시겠습니까?",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ": "이 작업은 오늘 일부 기기의 Alarm 시간을 변경합니다...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ": "이 작업은 이 집의 모든 Alarm을 끕니다. ",
    "Tắt toàn bộ Alarm?": "모든 Alarm을 끄시겠습니까?",
    "Không xoá được lịch tạm tắt Alarm": "Alarm 임시 중지 일정을 삭제할 수 없습니다",
    "Không lưu được tạm tắt Alarm": "Alarm 임시 중지를 저장할 수 없습니다",
    "Không gửi được yêu cầu xoá": "삭제 요청을 보낼 수 없습니다",
    "Không lưu được cài đặt": "설정을 저장할 수 없습니다",
    "Không lấy được vị trí hiện tại": "현재 위치를 가져올 수 없습니다",
    "Không thể xác nhận tài khoản hiện tại": "현재 계정을 확인할 수 없습니다",
    "Mật khẩu không đúng": "비밀번호가 올바르지 않습니다",
    "Không thể xác nhận mật khẩu": "비밀번호를 확인할 수 없습니다",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động": "소유자 또는 관리자만 경보 반복 설정을 변경할 수 있습니다",
    "Không lưu được thời gian lặp báo động": "경보 반복 시간을 저장할 수 없습니다",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "소유자 또는 관리자만 보호 모드를 변경할 수 있습니다",
    "Không thể thay đổi chế độ nhà": "집 모드를 변경할 수 없습니다",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "보호 모드는 켜졌지만 알림을 보낼 수 없습니다",
    "Đã bật Mode Bảo vệ thủ công": "수동 보호 모드가 켜졌습니다",
    "Đã chuyển nhà về Bình thường": "집이 일반 모드로 전환되었습니다",
    "60 phút": "60분",
    "30 phút": "30분",
    "15 phút": "15분",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.": "집 주인의 일정을 보고 있습니다. 나만을 선택해 내 Alarm 일정을 설정하세요.",
    "Chọn giờ kết thúc Alarm": "Alarm 종료 시간 선택",
    "Chọn giờ bắt đầu Alarm": "Alarm 시작 시간 선택",
    "Bạn không có quyền sửa lịch Alarm của nhà": "이 집의 Alarm 일정을 수정할 권한이 없습니다",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị": "전체 기기에 Alarm을 적용할 수 없습니다",
    "Nhà chưa có thiết bị an ninh để áp dụng": "이 집에는 적용할 보안 기기가 없습니다.",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.": "집 기준 일정을 수정할 권한이 없습니다. 나만을 선택하세요.",
    "Không thể lưu chế độ Alarm": "Alarm 모드를 저장할 수 없습니다",
    "Thêm khung giờ Alarm": "Alarm 시간대 추가",
    "Đang sử dụng Reminder riêng của bạn": "내 Reminder 설정을 사용 중입니다",
    "Đang sử dụng Reminder của chủ nhà": "집 주인의 Reminder 설정을 사용 중입니다",
    "Sửa giờ Reminder": "Reminder 시간 수정",
    "Sửa giờ kết thúc Alarm": "Alarm 종료 시간 수정",
    "Sửa giờ bắt đầu Alarm": "Alarm 시작 시간 수정",
    "Xoá Reminder": "Reminder 삭제",
    "Mỗi 1 giờ": "1시간마다",
    "Mỗi 30 phút": "30분마다",
    "Mỗi 15 phút": "15분마다",
    "Không báo lại": "다시 알리지 않음",
    "Báo lại khi vẫn chưa an toàn": "아직 안전하지 않으면 반복 알림",
    "Báo lại mỗi 1 giờ": "1시간마다 다시 알림",
    "Báo lại mỗi 30 phút": "30분마다 다시 알림",
    "Báo lại mỗi 15 phút": "15분마다 다시 알림",
    "Xoá thành viên": "구성원 삭제",
    "Đã xoá thành viên": "구성원이 삭제되었습니다",
    "Đồng ý": "확인",
    "Bạn chắc chắn muốn rời khỏi nhà này?": "정말 이 집에서 나가시겠습니까?",
    "Xoá thành viên?": "구성원을 삭제하시겠습니까?",
    "Rời khỏi nhà?": "이 집에서 나가시겠습니까?",
    "Chỉ chủ nhà mới được thay đổi vai trò": "집 주인만 역할을 변경할 수 있습니다",
    "Bạn không có quyền xoá thành viên này": "이 구성원을 삭제할 권한이 없습니다",
    "Bạn": "나",
    "Không có email": "이메일 없음",
    "Chưa có số điện thoại": "전화번호 없음",
    "Gọi điện": "전화",
    "Không mở được ứng dụng gọi điện": "전화 앱을 열 수 없습니다",
    "Thành viên chưa cập nhật số điện thoại": "이 구성원이 전화번호를 추가하지 않았습니다",
    "Hôm nay đã ghi nhận cảnh báo SOS": "오늘 SOS 경보가 기록되었습니다",
    "Hôm nay đã ghi nhận cảnh báo khói": "오늘 연기 경보가 기록되었습니다",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "수동 보호 모드가 켜져 있습니다. 끄려면 일반 모드로 전환하세요.",
    "Thời gian lặp": "반복 시간",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "0을 선택하면 한 번만 알립니다. 이 설정은 수동 보호와 외출 시 자동 보호 모두에 적용됩니다.",
    "Lặp báo động khi sự cố vẫn còn": "문제가 계속되면 Alarm 반복",
    "Đang được sử dụng": "사용 중",
    "Chuyển về sử dụng thông thường": "일반 사용으로 전환",
    "Chế độ nhà": "집 모드",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "SOS 기기에 기록된 알림이 없습니다.",
    "Cảm biến khói chưa ghi nhận bất thường.": "연기 감지기가 이상을 감지하지 않았습니다.",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.": "사용자 또는 구성원이 수동으로 보호를 켰습니다.",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.": "집을 떠났기 때문에 SafeHome이 자동으로 보호를 켰습니다.",
    "Nhà đang ở chế độ dùng bình thường.": "이 집은 현재 일반 사용 모드입니다.",
    "Bảo vệ thủ công đang bật": "수동 보호가 켜져 있음",
    "Bảo vệ tự động đang bật": "자동 보호가 켜져 있음",
    "Bảo vệ đang tắt": "보호 모드 꺼짐",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.": "최근 앱을 열어 상태를 확인했습니다.",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.": "권한, 일정, 읽지 않은 경고를 확인하기 위해 앱을 정기적으로 여세요.",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.": "몇 번 사용한 후 SafeHome이 앱 확인 습관을 더 잘 평가할 수 있습니다.",
    "Tần suất vào app ổn": "앱 확인 빈도가 양호합니다",
    "Đã lâu chưa vào app kiểm tra": "앱을 확인한 지 오래되었습니다",
    "Đang ghi nhận tần suất vào app": "앱 확인 빈도를 기록 중",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.": "항상 위치 권한과 백그라운드 조건을 확인하세요.",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.": "이 기기는 자동 외출에 필요한 조건을 충족합니다.",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.": "외출 시 보호 모드를 자동으로 켜려면 활성화하세요.",
    "Auto rời khỏi nhà chưa ổn": "자동 외출이 준비되지 않음",
    "Auto rời khỏi nhà đã sẵn sàng": "자동 외출 준비됨",
    "Auto rời khỏi nhà chưa bật": "자동 외출이 꺼져 있음",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.": "집에 맞는 연기 감지기, SOS 또는 긴급 기기를 추가하세요.",
    "Chưa có thiết bị khẩn cấp": "긴급 기기 없음",
    "Đã có thiết bị khẩn cấp": "긴급 기기가 추가됨",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.": "수면 시간이나 외출 시간에 Alarm 일정을 설정하세요.",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.": "이 집에는 Alarm 일정 또는 기기별 경고 일정이 있습니다.",
    "Chưa set lịch Alarm": "Alarm 일정이 설정되지 않음",
    "Đã set lịch Alarm": "Alarm 일정 설정됨",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.": "집 확인을 잊지 않도록 최소 하나의 Reminder를 설정하세요.",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.": "앱이 설정된 일정에 따라 집 확인을 알려줍니다.",
    "Chưa setup Reminder": "Reminder가 설정되지 않음",
    "Đã setup Reminder": "Reminder 설정됨",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.": "이 기기가 경고를 받지 못하면 앱을 다시 열거나 다시 로그인하세요.",
    "Thiết bị chưa đăng ký nhận cảnh báo": "이 기기는 경고 수신 등록이 되어 있지 않습니다",
    "Thiết bị nhận cảnh báo bình thường": "이 기기는 경고를 받을 수 있습니다",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.": "iOS는 Android보다 백그라운드를 더 엄격하게 관리합니다. 자동 외출을 사용하면 알림과 항상 위치 권한을 켜 두세요.",
    "Cơ chế iOS": "iOS 동작 방식",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.": "경고가 지연되지 않도록 백그라운드 권한과 자동 시작을 확인하세요.",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.": "기기가 중요한 백그라운드 조건을 확인했습니다.",
    "Cần kiểm tra chạy nền / tự khởi động": "백그라운드 실행 / 자동 시작 확인 필요",
    "Chạy nền ổn định": "백그라운드 실행이 안정적입니다",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "일부 Android 휴대폰은 배터리 최적화가 켜져 있으면 경고가 지연될 수 있습니다.",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.": "휴대폰이 SafeHome 경고를 지연할 가능성이 낮습니다.",
    "Chưa tắt tối ưu pin": "배터리 최적화가 아직 켜져 있음",
    "Tối ưu pin không chặn app": "배터리 최적화가 앱을 차단하지 않음",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.": "자동 외출이 안정적으로 작동하려면 항상 위치 권한이 필요합니다.",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.": "자동 외출에는 위치 권한이 필요합니다.",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.": "위치 서비스가 꺼져 있어 자동 외출이 안정적으로 작동하지 않을 수 있습니다.",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.": "자동 외출 기능을 사용할 때만 필요합니다.",
    "Chưa cấp vị trí luôn luôn": "항상 위치 권한이 허용되지 않음",
    "Đã cấp vị trí luôn luôn": "항상 위치 권한 허용됨",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.": "iOS는 Android처럼 전체 화면으로 열리지 않으며 시스템 알림과 소리를 사용합니다.",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.": "Android는 전체 화면 경고를 사용합니다. 휴대폰이 차단하면 설정에서 허용하세요.",
    "Cảnh báo trên iOS": "iOS 알림",
    "Cảnh báo toàn màn hình": "전체 화면 경고",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "알림이 꺼져 있으면 경고가 표시되지 않을 수 있습니다.",
    "Điện thoại có thể nhận thông báo SafeHome.": "이 휴대폰은 SafeHome 알림을 받을 수 있습니다.",
    "Chưa bật thông báo": "알림이 꺼져 있음",
    "Đã bật thông báo": "알림이 켜져 있음",
    "Hệ thống: Sẵn sàng": "시스템: 준비됨",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "시스템: 알림을 놓칠 수 있음",
    "Cách bạn đang dùng app": "앱 사용 방식",
    "Thiết bị của bạn": "내 기기",
    "Kiểm tra điện thoại và cách bạn đang dùng app.": "휴대폰과 앱 사용 상태를 확인합니다.",
    "Hệ thống SafeHome": "SafeHome 시스템",
    "Hệ thống: Đang kiểm tra...": "시스템: 확인 중...",
    "Không có": "없음",
    "Tổng hợp trạng thái": "상태 요약",
    "Đổi tên nhóm": "그룹 이름 변경",
    "Nhà của tôi": "내 집",
    "Bỏ chọn toàn bộ nhóm": "그룹 전체 선택 해제",
    "Chọn toàn bộ nhóm": "그룹 전체 선택",
    "Giờ không hợp lệ": "유효하지 않은 시간",
    "Giờ": "시간",
    "Phút": "분",
    "Không có nhà nào đủ điều kiện để cài": "설정 가능한 집이 없습니다",
    "Cài đặt hoàn tất": "설정 완료",
    "Xác nhận rời nhà": "집 나가기 확인",
    "Không tìm thấy tài khoản": "계정을 찾을 수 없습니다",
    "Sai mật khẩu": "비밀번호가 올바르지 않습니다",
    "Mật khẩu tài khoản": "계정 비밀번호",
    "Rời khỏi nhà": "집에서 나가기",
    "Quay lại": "뒤로",
    "Đóng tìm kiếm": "검색 닫기",
    "Bỏ chọn": "선택 해제",
    "Chia sẻ": "공유",
    "Email chưa đăng ký": "등록되지 않은 이메일입니다",
    "Chia sẻ hoàn tất": "공유 완료",
    "Đang tắt": "꺼짐",
    "Chọn giờ bắt đầu tạm tắt": "일시 중지 시작 시간 선택",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ": "자동 보호를 켜기 전에 집 위치를 설정하세요",
    "Đang lấy vị trí...": "위치 가져오는 중...",
    "Đang lưu...": "저장 중...",
    "Đổi tên hiển thị": "표시 이름 변경",
    "Cập nhật thông tin nhà": "집 정보 업데이트",
    "Nhập địa chỉ của nhà": "집 주소 입력",
    "QR của nhà này": "이 집의 QR",
    "Quét QR": "QR 스캔",
    "Quét QR để thêm thiết bị": "QR을 스캔하여 기기 추가",
    "Nhập HUB ID thủ công": "HUB ID 직접 입력",
    "Xác nhận chuyển quyền": "소유권 이전 확인",
    "Chuyển": "이전",
    "Không tìm thấy thiết bị trong nhà này": "이 집에서 기기를 찾을 수 없습니다",
    "Không tìm thấy nhà của thông báo này": "이 알림의 집을 찾을 수 없습니다",
    "Bạn không có quyền thay đổi vị trí nhà": "집 위치를 변경할 권한이 없습니다",
    "Hãy bật GPS để đặt vị trí nhà": "집 위치를 설정하려면 GPS를 켜세요",
    "Bạn chưa cấp quyền vị trí": "위치 권한이 허용되지 않았습니다",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng": "앱 설정에서 위치 권한을 허용하세요",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà": "모두가 집을 떠날 때 자동 보호를 켰습니다",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà": "모두가 집을 떠날 때 자동 보호를 껐습니다",
    "Không thể thay đổi trạng thái Alarm": "Alarm 상태를 변경할 수 없습니다",
    "Đã tắt toàn bộ Alarm của nhà": "집의 모든 Alarm을 껐습니다",
    "Cập nhật thiết bị": "기기 업데이트",
    "QR gia nhập nhiều nhà không hợp lệ": "여러 집 참여 QR이 유효하지 않습니다",
    "Bạn đang là chủ các nhà này": "이 집들의 소유자입니다",
    "QR gia nhập không hợp lệ": "참여 QR이 유효하지 않습니다",
    "Bạn đang là chủ nhà này": "이 집의 소유자입니다",
    "Đã gửi yêu cầu gia nhập nhà": "집 참여 요청을 보냈습니다",
    "QR này không phải mã xin gia nhập nhà": "이 QR은 집 참여 코드가 아닙니다",
    "Bạn không có quyền thêm thiết bị": "기기를 추가할 권한이 없습니다",
    "Rời khỏi Home này?": "이 Home에서 나가시겠습니까?",
    "Đã xoá nhà": "집을 삭제했습니다",
    "Không thể share cho chính bạn": "자기 자신에게 공유할 수 없습니다",
    "Lời mời chia sẻ nhà": "집 공유 초대",
    "Một chủ nhà": "집 소유자",
    "Đã share home": "Home을 공유했습니다",
    "Không thể chuyển quyền cho chính bạn": "자기 자신에게 소유권을 이전할 수 없습니다",
    "Không tìm thấy user": "사용자를 찾을 수 없습니다",
    "Yêu cầu chuyển quyền chủ nhà": "소유권 이전 요청",
    "Đã gửi yêu cầu chuyển quyền": "이전 요청을 보냈습니다",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "소유권 이전 요청을 보냈습니다",
    "Bạn không có quyền xoá thiết bị": "기기를 삭제할 권한이 없습니다",
    "Xóa Device?": "기기를 삭제하시겠습니까?",
    "Đã gửi yêu cầu xoá thiết bị": "기기 삭제 요청을 보냈습니다",
    "Đang xoá thiết bị": "기기 삭제 중",
    "QR này không phải mã xin gia nhập Home": "이 QR은 Home 참여 코드가 아닙니다",
    "Đã tạo nhà mới": "새 집을 만들었습니다",
    "Một thành viên": "구성원 한 명",
    "Đã cập nhật thông tin nhà": "집 정보가 업데이트되었습니다",
    "Thay tên": "이름 변경",
    "Đã đổi tên thiết bị": "기기 이름이 변경되었습니다",
    "Chưa chọn nhà để kiểm tra": "확인할 집을 선택하지 않았습니다",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner": "Owner 계정으로 확인하세요",
    "Không đọc được dữ liệu nhà": "집 데이터를 읽을 수 없습니다",
    "Nhà cần có ít nhất một thiết bị để test": "테스트하려면 집에 기기가 하나 이상 필요합니다",
    "Firebase Rules: ĐẠT": "Firebase Rules: 통과",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: 오류 있음",
    "Không có thiết bị": "기기 없음",
    "Chỉ chủ nhà mới được xoá nhà": "소유자만 집을 삭제할 수 있습니다",
    "Chỉ chủ nhà mới được chuyển quyền": "소유자만 소유권을 이전할 수 있습니다",
    "Thông báo Home": "Home 알림",
    "Thêm Home": "Home 추가",
    "Chưa thiết lập thời gian": "시간이 설정되지 않았습니다",
    "Đã gửi email khôi phục": "복구 이메일을 보냈습니다",
    "Không gửi được email": "이메일을 보낼 수 없습니다",
    "Khôi phục mật khẩu": "비밀번호 복구",
    "Nhập email của bạn": "이메일을 입력하세요",
    "Gửi": "보내기",
    "Vui lòng nhập email và mật khẩu": "이메일과 비밀번호를 입력하세요",
    "Mật khẩu xác nhận không khớp": "확인 비밀번호가 일치하지 않습니다",
    "Không thể tạo tài khoản": "계정을 만들 수 없습니다",
    "Sai tài khoản": "계정이 올바르지 않습니다",
    "Email đã tồn tại": "이메일이 이미 존재합니다",
    "Mật khẩu quá yếu": "비밀번호가 너무 약합니다",
    "Sai email hoặc mật khẩu": "이메일 또는 비밀번호가 올바르지 않습니다",
    "Lỗi đăng nhập": "로그인 오류",
    "Cảnh báo khói": "연기 경보",
    "Khói đã an toàn": "연기 상태가 안전합니다",
    "Đã bật Alarm": "Alarm을 켰습니다",
    "Đã tắt Alarm": "Alarm을 껐습니다",
    "Một người dùng": "사용자 한 명",
    "Yêu cầu gia nhập nhà": "집 참여 요청",
    "Đã mở chế độ thêm thiết bị": "기기 추가 모드가 켜졌습니다",
    "Đã xoá tài khoản": "계정을 삭제했습니다",
    "Xoá thất bại": "삭제 실패",
    "Lỗi xoá tài khoản": "계정 삭제 오류",
    "Chưa được cấp quyền": "권한이 허용되지 않았습니다",
    "Xoá tài khoản": "계정 삭제",
    "Hành động này sẽ xoá toàn bộ dữ liệu:": "이 작업은 모든 데이터를 삭제합니다:",
    "Nhà và thiết bị": "집 및 기기",
    "Chia sẻ và quyền truy cập": "공유 및 접근 권한",
    "Toàn bộ dữ liệu liên quan": "모든 관련 데이터",
    "Mật khẩu xác nhận": "확인 비밀번호",
    "Đang áp dụng...": "적용 중...",
    "Áp dụng cho toàn bộ thiết bị": "모든 기기에 적용",
    "Thiết bị không còn tồn tại": "기기가 더 이상 존재하지 않습니다",
    "Lần kích hoạt cuối": "마지막 작동",
    "Chat trong nhà": "집 채팅",
    "Tìm kiếm tin nhắn": "메시지 검색",
    "Xem thành viên": "구성원 보기",
    "Xoá từ khoá": "키워드 지우기",
    "Kết quả trước": "이전 결과",
    "Kết quả tiếp theo": "다음 결과",
    "Chưa có tin nhắn": "아직 메시지가 없습니다",
    "Nhắc đến trong tin nhắn": "메시지 멘션",
    "Huỷ trả lời": "답장 취소",
    "Xoá tất cả thông báo?": "모든 알림을 삭제하시겠습니까?",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "모든 집 알림이 삭제됩니다.",
    "Chưa có thông báo nào": "아직 알림이 없습니다",
    "Chưa có thông báo": "알림 없음",
    "Vuốt lên để tải thêm": "위로 스와이프하여 더 불러오기",
    "Bạn không có quyền quản lý phòng": "방을 관리할 권한이 없습니다",
    "Đổi tên phòng": "방 이름 변경",
    "Tên phòng": "방 이름",
    "Xoá phòng": "방 삭제",
    "Ví dụ: Phòng khách": "예: 거실",
    "Tên phòng đã tồn tại": "방 이름이 이미 존재합니다",
    "Giờ bắt đầu Alarm": "Alarm 시작 시간",
    "Giờ kết thúc Alarm": "Alarm 종료 시간",
    "Giờ Reminder": "Reminder 시간",
    "pin yếu": "배터리 부족",
    "sóng yếu": "신호 약함",
    "lâu không phản hồi": "응답 없음",
    "Không phát hiện khí CO": "일산화탄소 감지 안 됨",
    "Đã kích hoạt": "활성화됨",
    "Không phát hiện hiện diện": "재실 감지 안 됨",
    "Không có rung bất thường": "비정상 진동 없음",
    "Không có cảnh báo kính vỡ": "유리 파손 경고 없음",
    "Khóa đang đóng": "잠김",
    "Đang bật": "켜짐",
    "Đang theo dõi điện năng": "전력 모니터링 중",
    "Đang dùng nguồn dự phòng": "예비 전원 사용 중",
    "Nguồn điện bình thường": "전원 정상",
    "Còi đang bật": "사이렌 작동 중",
    "Còi sẵn sàng": "사이렌 준비됨",
    "Van đang mở": "밸브 열림",
    "Van đã đóng": "밸브 닫힘",
    "Chưa nhận diện": "인식되지 않음",
    "Mở cài đặt": "설정 열기",
    "Để sau": "나중에",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.": "SafeHome은 앱이 백그라운드에서 실행 중일 때도 외출 또는 귀가를 감지하려면 \"항상 허용\" 위치 권한이 필요합니다.",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.": "SafeHome은 현재 앱을 사용하는 동안에만 위치에 접근할 수 있습니다.\n\n위치 권한을 열고 \"항상 허용\"을 선택하면 외출 시 자동 보호 기능이 백그라운드에서도 계속 작동합니다.",
    "Cho phép vị trí luôn luôn": "위치 항상 허용",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.": "내 집은 삭제됩니다.\n공유된 집에서는 나가게 됩니다.",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "선택한 집의 모든 보안 기기 Home Alarm 일정을 변경합니다.\n\nAlarm을 집 기준으로 사용하는 구성원이 영향을 받습니다.\n나만 모드의 개인 Alarm은 변경되지 않습니다.",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "선택한 집에 Home Reminder를 추가합니다.\n\nReminder를 집 기준으로 사용하는 구성원이 영향을 받습니다.\n나만 모드의 개인 Reminder는 변경되지 않습니다.",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "켜면 보안 기기가 즉시 모니터링됩니다.\n\n외출 시 자동 보호는 일시 중지됩니다. 이 모드는 누군가 집에 돌아와도 자동으로 꺼지지 않으며, 권한이 있는 구성원이 직접 일반 모드로 전환해야 합니다.",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.": "이 작업은 이 집의 모든 Alarm을 끕니다. 이 휴대전화에서 위험 알림을 더 이상 받지 않습니다.",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.": "Alarm이 집 기준 설정을 사용 중입니다.\n\n집 주인 또는 관리자가 설정한 공용 일정에 따라 알림을 받습니다.",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.": "Alarm이 나만 설정을 사용 중입니다.\n\n이 계정에 설정된 개인 Alarm 일정에 따라 알림을 받습니다.",
    "Không thể đăng nhập bằng Google": "Google로 로그인할 수 없습니다",
    "Không đặt được mật khẩu": "비밀번호를 설정할 수 없습니다",
    "Chấp nhận": "수락",
    "Cho phép": "허용",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.": "초대를 수락할 수 없습니다. 다시 시도해 주세요.",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.": "집 참여 요청을 수락할 수 없습니다. 다시 시도해 주세요.",
    "Từ chối": "거절",
    "Lời mời từ chủ nhà": "소유자의 초대",
    "Nhận quyền chủ nhà": "집 소유권 받기",
    "Một người dùng SafeHome": "SafeHome 사용자",
    "Lời mời gia nhập": "참여 초대",
    "Lời xin vào nhà": "집 참여 요청",
    "Đã cập nhật": "업데이트됨",
    "Nhập HUB ID": "HUB ID 입력",
    "VD: HUB_001": "예: HUB_001",
    "Pair": "페어링",
    "Mật khẩu tối thiểu 6 ký tự": "비밀번호는 최소 6자 이상이어야 합니다",
    "Mật khẩu nhập lại không khớp": "비밀번호가 일치하지 않습니다",
    "Tạo mật khẩu": "비밀번호 만들기",
    "Mật khẩu mới": "새 비밀번호",
    "Nhập lại mật khẩu": "비밀번호 다시 입력",
    "Xác nhận tắt cảnh báo": "경고 끄기 확인",
    "HỦY": "취소",
    "XÁC NHẬN": "확인",
    "CẦN KIỂM TRA": "확인 필요",
    "KIỂM TRA NHÀ": "집 확인",
    "ĐÓNG NHẮC NHỞ": "리마인더 닫기",
    "SafeHome Security Alert": "SafeHome 보안 경고",
    "Bạn không có quyền sắp xếp phòng": "방을 정렬할 권한이 없습니다",
    "Chọn giờ kết thúc tạm tắt": "일시 중지 종료 시간 선택",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh": "아직 기기가 없습니다. 보안을 유지하려면 + 버튼을 눌러 추가하세요",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "앱 설정에서 위치 권한을 항상 허용으로 선택하세요",
    "Không có nhà nào bạn có quyền quản lý": "관리 권한이 있는 집이 없습니다",
    "Không tìm thấy thành viên phù hợp": "일치하는 구성원을 찾을 수 없습니다",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.": "다른 사람이 이 코드를 스캔하여 집 가입 요청을 보낼 수 있습니다.",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.": "이 집과 안의 모든 기기가 영구적으로 삭제됩니다.",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.": "Google 계정은 보안 기능을 사용하려면 추가 비밀번호를 만들어야 합니다.",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.": "이 이름은 내 계정에만 표시됩니다.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.": "이름과 주소가 집의 모든 구성원에게 업데이트됩니다.",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.": "이 방의 기기는 미분류로 이동됩니다.",
    "Tìm nội dung hoặc tên người gửi": "내용 또는 보낸 사람 이름 검색",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ 오늘 Alarm 일시 중지",
    "Alarm cleared": "알람 해제됨",
    "Alarm triggered": "알람 발생",
    "Bấm vào để xem chi tiết": "탭하여 상세 보기",
    "Bạn không có quyền thực hiện thao tác này。": "이 작업을 수행할 권한이 없습니다.",
    "Battery low": "배터리 부족",
    "Cả ngày": "하루 종일",
    "Cài đặt cảnh báo cho nhà hiện tại": "현재 집 알림 설정",
    "Chi tiết": "상세",
    "Công suất": "전력",
    "Cửa đóng": "문 닫힘",
    "Cửa mở": "문 열림",
    "Cường độ rung": "진동 강도",
    "Đã rời khỏi home": "집에서 나갔습니다",
    "Đã xảy ra lỗi. Vui lòng thử lại.": "오류가 발생했습니다. 다시 시도해 주세요.",
    "Đang bật cho tài khoản này": "이 계정에서 켜짐",
    "Đang tắt cho tài khoản này": "이 계정에서 꺼짐",
    "Đang theo dõi": "모니터링 중",
    "Đánh giá tự động": "자동 평가",
    "Đến giờ": "종료 시간",
    "Device offline": "기기 오프라인",
    "Device online": "기기 온라인",
    "Điện áp": "전압",
    "Điện năng": "전력량",
    "Độ ẩm": "습도",
    "Độ mở van": "밸브 개도",
    "Dòng điện": "전류",
    "Door closed": "문 닫힘",
    "Door opened": "문 열림",
    "Event cuối": "마지막 이벤트",
    "Góc nghiêng": "기울기 각도",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "연기 또는 SOS 이상 징후가 없습니다.",
    "Loại thiết bị": "기기 유형",
    "Lưu ý khi bật Alarm": "Alarm 켤 때 유의사항",
    "Mở List chia sẻ nhà": "집 공유 목록 열기",
    "Môi trường hiện tại": "현재 환경",
    "Motion detected": "움직임 감지",
    "Ngập/rò nước": "침수/누수",
    "Nguồn dự phòng": "백업 전원",
    "Nhắc kiểm tra nhà theo thời gian": "지정 시간에 집 확인 알림",
    "Nhận cảnh báo Alarm": "Alarm 경고 받기",
    "Nhiệt độ": "온도",
    "Offline": "오프라인",
    "Online": "온라인",
    "Phát hiện cạy phá": "강제 개방 감지",
    "Phát hiện khói": "연기 감지",
    "Quét mã QR chia sẻ nhà": "집 공유 QR 코드 스캔",
    "Quét QR để xin gia nhập nhà": "QR을 스캔하여 집 참여 요청",
    "Quét QR xin gia nhập nhà": "집에 가입하려면 QR 스캔",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "공유된 집 QR 코드를 프레임 안에 맞춰주세요",
    "Mã QR này do chủ nhà chia sẻ":
    "이 QR 코드는 집 소유자가 공유한 것입니다",
    "Nhập mã mời": "초대 코드 입력",
    "Gửi yêu cầu gia nhập": "가입 요청 보내기",
    "QR này không phải mã thiết bị": "이 QR 코드는 기기 코드가 아닙니다",
    "Tạm dừng": "일시 중지",
    "Tamper cleared": "탈거 감지 해제",
    "Tamper detected": "탈거 감지",
    "Tiếng Nhật": "일본어",
    "Tìm home...": "집 검색...",
    "Từ giờ": "시작 시간",
    "Xác nhận thay đổi": "변경 확인",
    "Xoá các nhà đã chọn ?": "선택한 집을 삭제하시겠습니까?",
    "TẮT CẢNH BÁO": "경고 끄기",
    "Đã tạo nhà": "집을 만들었습니다",

    "Mode Bảo vệ thủ công đã bật": "수동 보호 모드가 켜졌습니다",
    "Báo động không lặp lại.": "알람은 반복되지 않습니다.",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.": "문제가 계속되면 \$securityModeRepeatMinutes분 후 알람이 반복됩니다.",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage": "\$actorName님이 \"\$homeName\"의 수동 보호 모드를 켰습니다. 이 모드는 권한이 있는 구성원이 일반 모드로 전환해야 꺼집니다. \$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".": "\"\$homeName\"의 Alarm을 켰습니다.",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".": "\"\$homeName\"의 모든 Alarm을 껐습니다.",
    "Thành viên mới": "새 구성원",
    "Thành viên rời nhà": "구성원이 집을 나갔습니다",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".": "\$displayMemberName님이 \"\$homeName\"에서 나갔습니다.",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".": "\$actorName님이 \"\$homeName\"에서 \$memberName님의 역할을 \$oldRoleName에서 \$newRoleName(으)로 변경했습니다.",
    "Còn \$count tin nhắn chưa đọc": "읽지 않은 메시지 \$count개",
    "Hãy an tâm nghỉ ngơi.": "안심하셔도 됩니다.",
    "Có thiết bị chưa an toàn.": "일부 기기가 안전하지 않습니다.",
    "SafeHome đang cập nhật vị trí": "SafeHome이 위치를 업데이트 중입니다",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.": "보호 모드를 자동으로 켜기 위해 모니터링 중입니다.",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.": "모두가 집을 떠나면 위치를 사용해 보호 모드를 자동으로 켭니다.",
    "CẢNH BÁO SOS": "SOS 경고",
    "CẢNH BÁO KHÓI / CHÁY": "연기/화재 경고",
    "CẢNH BÁO NGẬP NƯỚC": "침수 경고",
    "CẢNH BÁO RÒ KHÍ": "가스 누출 경고",
    "CẢNH BÁO CỬA": "문 경고",
    "CẢNH BÁO AN NINH": "보안 경고",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.": "SafeHome에서 확인할 수 없습니다. 연결을 확인하고 다시 시도하세요.",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?": "집 상태를 확인한 후에만 경고를 중지하세요.\n\n경고를 중지하시겠습니까?",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome이 경고를 감지했습니다",
    "Mở SafeHome để kiểm tra ngay.": "SafeHome을 열어 지금 확인하세요.",
    "\$count tin nhắn mới": "새 메시지 \$count개",
    "Tin nhắn HomeChat": "HomeChat 메시지",
    "\$senderName đã gửi một tin nhắn": "\$senderName님이 메시지를 보냈습니다",
    "Bạn có tin nhắn mới": "새 메시지가 있습니다",
    "Mode Bảo vệ sẽ chỉ báo động một lần": "보호 모드는 한 번만 경고합니다",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút": "보호 모드는 \$minutes분 후 경고를 반복합니다",
    "Đã gửi yêu cầu gia nhập \$count nhà": "\$count개 집에 참여 요청을 보냈습니다",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".": "\$requesterName님이 \"\$homeName\" 참여를 요청했습니다.",
    "Bạn đã xoá nhà \"\$homeName\".": "\"\$homeName\"을 삭제했습니다.",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.": "\$email님에게 \"\$homeName\" 소유권 이전 요청을 보냈습니다.",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.": "\$actorName님이 \"\$homeName\"의 소유권을 회원님에게 이전하려고 합니다.",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".": "\$actorName님이 \"\$homeName\"에 초대했습니다.",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".": "SafeHome이 \"\$homeName\"에서 \"\$deviceName\"을 제거하는 중입니다.",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".": "기기 \"\$deviceName\"이 \"\$homeName\"에 추가되었습니다.",
    "Bạn đã tạo nhà \"\$name\".": "\"\$name\" 집을 만들었습니다.",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.": "\$actorName님이 집 이름을 \"\$newName\"(으)로 업데이트하고 주소를 변경했습니다.",
    "\$actorName đã đổi tên nhà thành \"\$newName\".": "\$actorName님이 집 이름을 \"\$newName\"(으)로 변경했습니다.",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".": "\$actorName님이 \"\$newName\"의 주소를 업데이트했습니다.",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".": "\$actorName님이 \"\$homeName\"에서 기기 \"\$oldDeviceName\"의 이름을 \"\$newName\"(으)로 변경했습니다.",
    "Đang ghép nối: \$seconds giây": "페어링 중: \$seconds초",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.": "\"\$homeName\"에서 \$seconds초 동안 기기 추가 모드가 켜졌습니다.",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)": "일시 중지 시간은 Alarm 일정 범위(\$start → \$end) 안이어야 합니다",
    "\$passCount/\$total bài test đạt\n\n": "\$passCount/\$total개 테스트 통과\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.": "\$name님이 프로필에 전화번호를 추가하지 않았습니다.",
    "Tin nhắn mới trong \$homeName": "\$homeName의 새 메시지",
    "\$current/\$total kết quả": "\$current/\$total 결과",
    "Đang trả lời \$name": "\$name님에게 답장 중",
    "\"\$name\" phát hiện khói trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 연기를 감지했습니다.",
    "\"\$name\" đã trở lại trạng thái bình thường.": "\"\$name\"이 정상 상태로 돌아왔습니다.",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 SOS를 작동했습니다.",
    "\"\$name\" đã hết trạng thái SOS.": "\"\$name\"의 SOS 상태가 해제되었습니다.",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 분리/조작을 보고했습니다.",
    "\"\$name\" đã hết cảnh báo tháo/cạy.": "\"\$name\"의 분리/조작 경고가 해제되었습니다.",
    "\"\$name\" đã đóng trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 닫혔습니다.",
    "\"\$name\" đang mở trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 열려 있습니다.",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.": "\"\$homeName\"의 \"\$name\" 배터리가 부족합니다.",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.": "\"\$homeName\"의 \"\$name\"이 오프라인 상태가 되었습니다.",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.": "\"\$homeName\"의 \"\$name\"이 다시 온라인 상태입니다.",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 높은 온도를 기록했습니다.",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".": "\"\$name\"이 \"\$homeName\"에서 높은 습도를 기록했습니다.",
    "Có nút SOS vừa được kích hoạt": "SOS 버튼이 작동되었습니다",
    "Có dấu hiệu khói hoặc cháy": "연기 또는 화재가 감지되었습니다",
    "Có dấu hiệu ngập nước": "침수가 감지되었습니다",
    "Có dấu hiệu rò khí": "가스 누출이 감지되었습니다",
    "Có cửa đang mở hoặc thiết bị bị tháo": "문이 열려 있거나 기기가 분리/조작되었습니다",
    "Có thiết bị đang cảnh báo": "경고 중인 기기가 있습니다",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.": "아무도 확인하지 않으면 SafeHome이 긴급 전화로 전환합니다.",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.": "문제가 처리되지 않으면 \$time에 다시 알립니다.",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.": "문제가 처리되지 않으면 Alarm 일정에 따라 다시 알립니다.",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".": "\"\$deviceName\"이 \"\$resolvedHomeName\"에서 닫혔습니다.",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".": "\"\$deviceName\"이 \"\$resolvedHomeName\"에서 열려 있습니다.",
    "\$count nhà đã chọn": "\$count개 집 선택됨",
    "🚨 \$count nhà không an toàn\$suffix": "🚨 안전하지 않은 집 \$count개\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix": "⚠️ 주의가 필요한 집 \$count개\$suffix",
    "✅ \$count nhà an toàn": "✅ 안전한 집 \$count개",
    "\$count nhà đang được theo dõi": "\$count개 집을 모니터링 중",
    "\$minutes phút": "\$minutes분",
    "Đã cài Reminder cho \$updatedHomes nhà.": "\$updatedHomes개 집에 Reminder를 설정했습니다.",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n": "\$updatedHomes개 집의 \$updatedDevices개 기기에 Alarm을 설정했습니다.\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.": "관리 중인 집이 공유되었습니다.\n\n공유 권한이 없어 \$skipped개 집은 건너뛰었습니다.",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh": "\$count개 보안 기기에 Alarm이 적용되었습니다",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh": "\$count개 보안 기기에 같은 일정을 적용",
    "\$count phút trước": "\$count분 전",
    "\$count giờ trước": "\$count시간 전",
    "\${count}h trước": "\${count}시간 전",
    "\${hours}h\$minutes' trước": "\${hours}시간 \${minutes}분 전",
    "\$count ngày trước": "\$count일 전",
    "\$count tháng trước": "\$count개월 전",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?": "\$name님을 이 집에서 삭제하시겠습니까?",
    "\$targetEmail\nXin gia nhập \"\$homeName\"": "\$targetEmail\n\"\$homeName\" 참여 요청",
    "Xin gia nhập \"\$homeName\"": "\"\$homeName\" 참여 요청",
    "Bạn được mời nhận quyền nhà \"\$homeName\"": "\"\$homeName\"의 소유권을 받도록 초대되었습니다",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"": "\$ownerEmail\n\"\$homeName\"에 초대합니다",
    "Mời bạn gia nhập \"\$homeName\"": "\"\$homeName\"에 초대합니다",
    "Cần kiểm tra: \$joined": "확인 필요: \$joined",
    "Cập nhật \$value": "업데이트됨: \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.": "첫 SafeHome 기기를 추가해 이 집 모니터링을 시작하세요.",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.": "먼저 긴급 경고를 확인한 뒤 필요하면 집 구성원에게 연락하세요.",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "집에 구성원이 없지만 문이나 잠금장치가 열려 있습니다. 지금 확인하세요.",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "이 집을 보호 모드로 유지하기 전에 열린 문이나 잠금을 확인하세요.",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.": "아직 집에 사람이 있을 수 있습니다. 그렇다면 일반 모드로 전환하세요.",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.": "일부 구성원의 위치를 알 수 없습니다. 앱을 열거나 위치 권한을 확인하도록 안내하세요.",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "기기 연결이 끊겼습니다. 배터리, 전원 또는 설치 위치를 확인하세요.",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.": "배터리가 부족한 기기가 있습니다. 알림을 놓치지 않도록 곧 배터리를 교체하세요.",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.": "Reminder가 설정되지 않았습니다. 집을 정기적으로 확인할 일정을 만드세요.",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.": "Alarm 일정이 설정되지 않았습니다. 평소 집을 비우는 시간대에 보호를 켜세요.",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.": "즉시 조치할 필요는 없습니다. 이 집을 계속 모니터링하세요.",
    "Lặp sau \$minutes phút": "\$minutes분 후 반복",
    "Đang dùng • \$repeatText": "활성 • \$repeatText",
    "Giám sát an ninh • \$repeatText": "보안 모니터링 • \$repeatText",
    "Gia đình: \$mode": "집 모드: \$mode",
    "Gợi ý xử lý": "권장 조치",
    "Phát hiện \$count vấn đề cần xử lý": "\$count개 문제를 처리해야 합니다",
    "Hôm nay các cửa đã được sử dụng \$count lần": "오늘 문이 \$count번 사용되었습니다",
    "Đã ghi nhận \$count hoạt động gần đây": "최근 활동 \$count건이 기록되었습니다",
    "Hệ thống: Cần kiểm tra \$issueCount mục": "시스템: \$issueCount개 항목 확인 필요",
    "FCM token đã sẵn sàng trên điện thoại này.": "이 휴대폰의 FCM 토큰이 준비되었습니다.",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.": "FCM 토큰은 준비되었지만 Auto Away에 필요한 조건이 부족합니다.",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.": "긴급 기기 \$emergencyTotal개가 발견되었습니다. 권장 최소 구성: 연기 센서와 SOS.",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?": "집 소유권을 다음 계정으로 이전하시겠습니까:\n\$targetEmail?",
    "\$count cửa đã đóng an toàn": "문 \$count개가 안전하게 닫혔습니다",
    "\$count cửa và khóa đã an toàn": "문과 잠금장치 \$count개가 안전합니다",
    "\$count thiết bị đang được theo dõi": "\$count개 기기를 모니터링 중",
    "Cập nhật \$timeText": "\$timeText 업데이트됨",
    "Dữ liệu gần nhất cập nhật \$count phút trước": "최신 데이터가 \$count분 전에 업데이트되었습니다",
    "Dữ liệu gần nhất cập nhật \$count giờ trước": "최신 데이터가 \$count시간 전에 업데이트되었습니다",
    "Thành viên trong nhà: \$count": "집에 있는 구성원: \$count",
    "Thành viên bên ngoài: \$count": "외출 중인 구성원: \$count",
    "Chưa xác định vị trí: \$count": "위치 알 수 없음: \$count",
    "Môi trường hiện tại: \$environment": "현재 환경: \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ": "\$name: 집이 보호 모드일 때 열림",
    "An tâm hơn trong từng ngôi nhà": "모든 집에 더 큰 안심을",
    "Báo động SafeHome": "SafeHome 알람",
    "Có cảnh báo an ninh cần kiểm tra ngay.": "확인이 필요한 보안 경고가 있습니다.",
    "Có cảnh báo cần kiểm tra": "확인이 필요한 경고가 있습니다",
    "Tự đóng sau \$time": "\$time 후 자동으로 닫힘",
  };

  static const Map<String, String> _japanese = {
    "Không tìm thấy người dùng": "ユーザーが見つかりません",
    "Không đọc được số điện thoại": "電話番号を読み取れません",
    "Tin nhắn quá dài": "メッセージが長すぎます",
    "Không gửi được tin nhắn": "メッセージを送信できません",
    "Bạn không có quyền sửa lịch chung của nhà": "共有ホームのスケジュールを編集する権限がありません",
    "Nhà của bạn": "あなたの家",
    "Tải tin cũ hơn": "古いメッセージを読み込む",
    "Email": "メールアドレス",
    "Mật khẩu": "パスワード",
    "Xác nhận mật khẩu": "パスワード確認",
    "Đăng nhập": "ログイン",
    "Đăng ký mới": "新規登録",
    "Ghi nhớ tài khoản": "アカウントを記憶",
    "Quên mật khẩu?": "パスワードをお忘れですか？",
    "Chưa có tài khoản? Đăng ký": "アカウントをお持ちでないですか？登録",
    "Đã có tài khoản? Đăng nhập": "すでにアカウントをお持ちですか？ログイン",
    "Khôi phục mật khẩu": "パスワードをリセット",
    "Nhập email của bạn": "メールアドレスを入力",
    "Gửi": "送信",
    "Đã gửi email khôi phục": "パスワード再設定メールを送信しました",
    "Không gửi được email": "メールを送信できませんでした",
    "Vui lòng nhập email và mật khẩu": "メールアドレスとパスワードを入力してください",
    "Mật khẩu xác nhận không khớp": "パスワード確認が一致しません",
    "Không thể tạo tài khoản": "アカウントを作成できません",
    "Sai tài khoản": "アカウントが正しくありません",
    "Email đã tồn tại": "このメールアドレスはすでに存在します",
    "Mật khẩu quá yếu": "パスワードが弱すぎます",
    "Sai email hoặc mật khẩu": "メールアドレスまたはパスワードが正しくありません",
    "Lỗi đăng nhập": "ログインエラー",
    "Không thể đăng nhập bằng Google": "Google でログインできません",
    "Nhà": "家",
    "Nhà chưa đặt tên": "名前未設定の家",
    "Nhà được chia sẻ": "共有された家",
    "Địa chỉ": "住所",
    "An toàn": "安全",
    "Cần chú ý": "確認が必要",
    "Không an toàn": "安全ではありません",
    "Chưa đủ dữ liệu để đánh giá": "評価するためのデータが不足しています",
    "Chưa có dữ liệu để đánh giá": "評価するためのデータが不足しています",
    "Nhấn để xem chi tiết...": "詳細を見るにはタップ...",
    "Tổng hợp trạng thái nhà": "家の状態サマリー",
    "Tự động đánh giá": "自動評価",
    "Tổng quan hôm nay": "今日の概要",
    "Môi trường hiện tại": "現在の環境",
    "Hub kết nối bình thường": "Hub は正常に接続されています",
    "Bảo vệ": "警戒",
    "Chế độ Bảo vệ": "警戒モード",
    "Bình thường": "正常",
    "Tắt": "オフ",
    "Tự động Bảo vệ khi rời nhà": "外出時の自動警戒",
    "Chuyển về Bình thường?": "通常モードに切り替えますか？",
    "Vẫn chuyển về Bình thường": "それでも通常モードに切り替える",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.": "外出時の自動警戒がまだ有効です。全員が外出中の場合、数分後に警戒モードが自動で再び有効になることがあります。",
    "An ninh ra/vào": "出入り口セキュリティ",
    "Nguy hiểm khẩn cấp": "緊急リスク",
    "Môi trường": "環境",
    "Điều khiển & hạ tầng": "制御とインフラ",
    "Tình trạng": "状態",
    "Cửa": "ドア",
    "Cửa ra/vào": "出入口ドア",
    "Cửa sổ": "窓",
    "Cổng": "ゲート",
    "Đang mở": "開いています",
    "Đang đóng": "閉じています",
    "Sẵn sàng": "準備完了",
    "Đang hoạt động": "稼働中",
    "Tháo/Lắp": "取り外し検知",
    "Pin": "バッテリー",
    "Tín hiệu": "信号",
    "Camera": "カメラ",
    "Chưa liên kết": "未連携",
    "Liên lạc cuối": "最終通信",
    "Sự kiện cuối": "最終イベント",
    "Event cuối": "最終イベント",
    "Lần kích hoạt cuối": "最終作動",
    "Chưa cập nhật": "まだ更新がありません",
    "Tính năng đang được phát triển": "この機能は開発中です",
    "Alarm": "Alarm",
    "Reminder": "Reminder",
    "Hẹn giờ Alarm": "Alarm 予約",
    "Hẹn giờ Reminder": "Reminder 予約",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.": "Reminder は、選択した時刻に家の安全状態を確認するよう通知します。",
    "Thêm Reminder": "Reminder を追加",
    "Alarm thiết bị": "デバイス Alarm",
    "Chế độ áp dụng": "適用モード",
    "Theo nhà": "家の設定",
    "Riêng tôi": "自分のみ",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập": "家の所有者または管理者が設定した共通スケジュールを使用します",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn": "自分のアカウントにのみ適用される個人スケジュールを使用します",
    "Thiết lập nhanh toàn bộ thiết bị": "すべてのデバイスを一括設定",
    "Bắt đầu": "開始",
    "Kết thúc": "終了",
    "Thời gian lặp": "繰り返し間隔",
    "Thời gian lặp lại": "繰り返し間隔",
    "Không lặp lại": "繰り返しなし",
    "Chưa thiết lập": "未設定",
    "Đã thiết lập": "設定済み",
    "Tạm tắt Alarm hôm nay": "今日の Alarm を一時停止",
    "Lưu ý tạm tắt Alarm": "Alarm 一時停止の注意",
    "Từ": "開始",
    "Từ giờ": "開始",
    "Đến": "終了",
    "Đến giờ": "終了",
    "Về muộn": "帰宅が遅い",
    "Ra ngoài": "外出",
    "Khác": "その他",
    "Lưu": "保存",
    "Xoá lịch tạm tắt": "一時停止スケジュールを削除",
    "Xóa lịch tạm tắt": "一時停止スケジュールを削除",
    "Đã hiểu": "了解",
    "Cài đặt bảo mật": "セキュリティ設定",
    "Quyền báo động toàn màn hình": "全画面アラーム権限",
    "Báo động toàn màn hình": "全画面アラーム",
    "Đã được cấp quyền": "権限が許可されています",
    "Chưa được cấp quyền": "権限が許可されていません",
    "Mở cài đặt hệ thống": "システム設定を開く",
    "Yêu cầu & lời mời": "リクエストと招待",
    "Không có yêu cầu hoặc lời mời nào": "リクエストまたは招待はありません",
    "Đăng xuất": "ログアウト",
    "Đăng xuất?": "ログアウトしますか？",
    "Không": "いいえ",
    "Có": "はい",
    "OK": "OK",
    "Huỷ": "キャンセル",
    "Hủy": "キャンセル",
    "Tiếp tục": "続行",
    "Giới tính": "性別",
    "SĐT": "電話番号",
    "Số điện thoại": "電話番号",
    "Ngày sinh": "生年月日",
    "Thoát tài khoản khỏi thiết bị này": "このデバイスからログアウト",
    "Chia sẻ nhà": "家を共有",
    "Thành viên trong nhà": "家のメンバー",
    "Quản lý phòng": "部屋の管理",
    "Toàn bộ thiết bị": "すべてのデバイス",
    "Toàn bộ thiết bị SafeHome": "すべての SafeHome デバイス",
    "Quản lý nhà": "家の管理",
    "Chuyển quyền chủ nhà hoặc xoá nhà": "家の所有権を移転または家を削除",
    "Đặt vị trí nhà và bật bảo vệ tự động": "家の位置を設定し、自動警戒を有効にします",
    "Email người nhận": "受信者のメール",
    "Mời thành viên bằng mã QR": "QR コードでメンバーを招待",
    "Xin gia nhập nhà": "家への参加をリクエスト",
    "Quét QR HUB": "HUB の QR をスキャン",
    "Đưa mã QR vào giữa khung": "QR コードを枠の中央に合わせてください",
    "Quét mã QR được chủ nhà chia sẻ": "家の所有者が共有した QR コードをスキャン",
    "Chưa share cho ai": "まだ誰にも共有されていません",
    "Chưa phân phòng": "未割り当て",
    "Phòng mặc định": "デフォルトの部屋",
    "Phòng khách": "リビング",
    "Thêm phòng": "部屋を追加",
    "Phòng": "部屋",
    "Nhắn gì đó...": "メッセージを入力...",
    "Thông báo nhà": "家の通知",
    "Thông báo Home": "家の通知",
    "Phát hiện bất thường": "異常を検知",
    "Cửa đang mở": "ドアが開いています",
    "Cửa đã đóng": "ドアが閉じました",
    "SOS được kích hoạt": "SOS が作動しました",
    "SOS đã kết thúc": "SOS が終了しました",
    "Tamper bình thường": "取り外し検知は正常です",
    "Vai trò thành viên đã thay đổi": "メンバーの役割が変更されました",
    "Chủ nhà": "所有者",
    "Quản trị viên": "管理者",
    "Thành viên": "メンバー",
    "Vai trò": "役割",
    "Tìm nhà": "家を検索",
    "Tìm home...": "家を検索...",
    "Tìm nhà...": "家を検索...",
    "Đặt Reminder / Alarm nhà đã chọn": "選択した家の Reminder / Alarm を設定",
    "Chia sẻ nhà đã chọn": "選択した家を共有",
    "Mở danh sách chia sẻ nhà": "家の共有リストを開く",
    "Xoá các nhà đã chọn?": "選択した家を削除しますか？",
    "Xác nhận xoá nhà": "家の削除を確認",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "選択した家は完全に削除されます。",
    "Thêm nhà": "家を追加",
    "Thêm nhà mới": "新しい家を追加",
    "Tạo nhà mới": "新しい家を作成",
    "Tạo một ngôi nhà mới của bạn": "新しい家を作成します",
    "Tên nhà": "家の名前",
    "Chưa đặt vị trí nhà": "家の位置が未設定です",
    "Đã đặt vị trí nhà": "家の位置が設定されています",
    "Đặt vị trí nhà tại đây": "現在地を家の位置に設定",
    "Bán kính bảo vệ mặc định: 150 m": "デフォルトの保護半径: 150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.": "外出/帰宅状態をバックグラウンドで動作させるには、各メンバーが位置情報を「常に許可」にする必要があります。",
    "Lưu cài đặt": "設定を保存",
    "Bạn không có quyền thực hiện thao tác này。": "この操作を実行する権限がありません。",
    "Bạn không có quyền thực hiện thao tác này.": "この操作を実行する権限がありません。",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.": "エラーが発生しました。もう一度お試しください。",
    "Đã xảy ra lỗi. Vui lòng thử lại.": "エラーが発生しました。もう一度お試しください。",
    "Đang mở khi nhà ở chế độ Bảo vệ": "家が警戒モードのときに開いています",
    "Đang mở trong giờ Alarm": "Alarm 時間中に開いています",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ": "警戒モード中にロックが解除されています",
    "Khóa đang mở trong giờ Alarm": "Alarm 時間中にロックが解除されています",
    "Khóa đang mở": "ロック解除中",
    "Bị tháo": "取り外し検知",
    "Pin yếu": "バッテリー低下",
    "Sóng yếu": "信号が弱い",
    "Mất kết nối": "接続が切断されました",
    "Offline": "オフライン",
    "Online": "オンライン",
    "Thiết bị offline": "デバイスはオフラインです",
    "Thiết bị online": "デバイスはオンラインです",
    "Thiết bị mới": "新しいデバイス",
    "Đang tải...": "読み込み中...",
    "Ngôn ngữ": "言語",
    "Thay đổi ngôn ngữ hiển thị": "表示言語を変更",
    "Chọn ngôn ngữ": "言語を選択",
    "Tiếng Việt": "ベトナム語",
    "Tiếng Anh": "英語",
    "Tiếng Trung": "中国語",
    "Tiếng Hàn": "韓国語",
    "Tiếng Nhật": "日本語",
    "Cần kiểm tra": "確認が必要",
    "Không có": "なし",
    "Tổng hợp trạng thái": "状態サマリー",
    "Đổi tên nhóm": "グループ名を変更",
    "Nhà của tôi": "自分の家",
    "Bỏ chọn toàn bộ nhóm": "グループ全体の選択を解除",
    "Chọn toàn bộ nhóm": "グループ全体を選択",
    "Giờ không hợp lệ": "時刻が無効です",
    "Giờ": "時",
    "Phút": "分",
    "Xác nhận": "確認",
    "Đặt Home Reminder": "Home Reminder を設定",
    "Đặt Home Alarm": "Home Alarm を設定",
    "Giờ Reminder": "Reminder 時刻",
    "Giờ bắt đầu Alarm": "Alarm 開始時刻",
    "Giờ kết thúc Alarm": "Alarm 終了時刻",
    "Không có nhà nào đủ điều kiện để cài": "設定可能な家がありません",
    "Cài đặt hoàn tất": "設定が完了しました",
    "Xác nhận rời nhà": "家からの退出を確認",
    "Không tìm thấy tài khoản": "アカウントが見つかりません",
    "Sai mật khẩu": "パスワードが正しくありません",
    "Nhập mật khẩu": "パスワードを入力",
    "Mật khẩu tài khoản": "アカウントのパスワード",
    "Rời khỏi nhà": "家から退出",
    "Xoá nhà": "家を削除",
    "Đã cập nhật": "更新しました",
    "Quay lại": "戻る",
    "Đóng tìm kiếm": "検索を閉じる",
    "Bỏ chọn": "選択を解除",
    "Chia sẻ": "共有",
    "Email chưa đăng ký": "メールアドレスが登録されていません",
    "Chia sẻ hoàn tất": "共有が完了しました",
    "Đã lưu thông tin": "情報を保存しました",
    "Lỗi lưu profile": "プロフィールの保存に失敗しました",
    "Thông tin cá nhân": "個人情報",
    "Tên": "名前",
    "Nam": "男性",
    "Nữ": "女性",
    "Ngày": "日",
    "Tháng": "月",
    "Năm": "年",
    "Lưu thay đổi": "変更を保存",
    "Đang tắt": "オフ",
    "Chọn giờ bắt đầu tạm tắt": "一時停止の開始時刻を選択",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ": "自動警戒を有効にする前に家の位置を設定してください",
    "Đang lấy vị trí...": "位置情報を取得中...",
    "Đang lưu...": "保存中...",
    "Alarm đã được bật": "Alarm が有効になりました",
    "Tắt Alarm": "Alarm をオフにする",
    "Đổi tên hiển thị": "表示名を変更",
    "Cập nhật thông tin nhà": "家の情報を更新",
    "Nhập địa chỉ của nhà": "家の住所を入力",
    "QR của nhà này": "この家の QR",
    "Quét QR": "QR をスキャン",
    "Quét QR để thêm thiết bị": "QR をスキャンしてデバイスを追加",
    "Nhập HUB ID thủ công": "HUB ID を手動入力",
    "Chuyển quyền chủ nhà": "所有権を移転",
    "Xác nhận chuyển quyền": "所有権移転を確認",
    "Chuyển": "移転",
    "Không tìm thấy thiết bị trong nhà này": "この家にデバイスが見つかりません",
    "Không tìm thấy nhà của thông báo này": "この通知の家が見つかりません",
    "Bạn không có quyền thay đổi vị trí nhà": "家の位置を変更する権限がありません",
    "Hãy bật GPS để đặt vị trí nhà": "家の位置を設定するには GPS をオンにしてください",
    "Bạn chưa cấp quyền vị trí": "位置情報の権限が許可されていません",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng": "アプリ設定で位置情報の権限を許可してください",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà": "全員が外出したときの自動警戒を有効にしました",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà": "全員が外出したときの自動警戒を無効にしました",
    "Không thể thay đổi trạng thái Alarm": "Alarm の状態を変更できません",
    "Đã tắt toàn bộ Alarm của nhà": "家のすべての Alarm をオフにしました",
    "Cập nhật thiết bị": "デバイスを更新",
    "QR gia nhập nhiều nhà không hợp lệ": "複数の家への参加 QR が無効です",
    "Bạn đang là chủ các nhà này": "あなたはこれらの家の所有者です",
    "QR gia nhập không hợp lệ": "参加 QR が無効です",
    "Bạn đang là chủ nhà này": "あなたはこの家の所有者です",
    "Đã gửi yêu cầu gia nhập nhà": "家への参加リクエストを送信しました",
    "QR này không phải mã xin gia nhập nhà": "この QR は家への参加コードではありません",
    "Bạn không có quyền thêm thiết bị": "デバイスを追加する権限がありません",
    "Rời khỏi Home này?": "この Home から退出しますか？",
    "Đã xoá nhà": "家を削除しました",
    "Không thể share cho chính bạn": "自分自身には共有できません",
    "Lời mời chia sẻ nhà": "家の共有招待",
    "Một chủ nhà": "家の所有者",
    "Đã share home": "Home を共有しました",
    "Không thể chuyển quyền cho chính bạn": "自分自身に所有権を移転できません",
    "Không tìm thấy user": "ユーザーが見つかりません",
    "Yêu cầu chuyển quyền chủ nhà": "所有権移転リクエスト",
    "Đã gửi yêu cầu chuyển quyền": "移転リクエストを送信しました",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "所有権移転リクエストを送信しました",
    "Bạn không có quyền xoá thiết bị": "デバイスを削除する権限がありません",
    "Xóa Device?": "デバイスを削除しますか？",
    "Đã gửi yêu cầu xoá thiết bị": "デバイス削除リクエストを送信しました",
    "Đang xoá thiết bị": "デバイスを削除中",
    "QR này không phải mã xin gia nhập Home": "この QR は Home への参加コードではありません",
    "Đã tạo nhà mới": "新しい家を作成しました",
    "Một thành viên": "メンバー",
    "Đã cập nhật thông tin nhà": "家の情報を更新しました",
    "Thay tên": "名前を変更",
    "Đã đổi tên thiết bị": "デバイス名を変更しました",
    "Chưa chọn nhà để kiểm tra": "確認する家が選択されていません",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner": "Owner アカウントで確認してください",
    "Không đọc được dữ liệu nhà": "家のデータを読み取れません",
    "Nhà cần có ít nhất một thiết bị để test": "テストするには家に少なくとも 1 台のデバイスが必要です",
    "Firebase Rules: ĐẠT": "Firebase Rules: 合格",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: 問題あり",
    "Đóng": "閉じる",
    "Không có thiết bị": "デバイスがありません",
    "Chỉ chủ nhà mới được xoá nhà": "家を削除できるのは所有者だけです",
    "Chỉ chủ nhà mới được chuyển quyền": "所有権を移転できるのは所有者だけです",
    "Thêm Home": "Home を追加",
    "Chưa thiết lập thời gian": "時刻が未設定です",
    "Vui lòng nhập đủ thông tin": "必要な情報をすべて入力してください",
    "Không thể lưu thông tin": "情報を保存できません",
    "Thiết lập tài khoản": "アカウント設定",
    "Hoàn tất": "完了",
    "Cảnh báo khói": "煙警報",
    "Khói đã an toàn": "煙の状態は安全です",
    "Thiết bị bị tháo": "デバイスが取り外されました",
    "Nhiệt độ cao": "高温",
    "Độ ẩm cao": "高湿度",
    "Đã bật Alarm": "Alarm を有効にしました",
    "Đã tắt Alarm": "Alarm を無効にしました",
    "Một người dùng": "ユーザー",
    "Yêu cầu gia nhập nhà": "家への参加リクエスト",
    "Đã mở chế độ thêm thiết bị": "デバイス追加モードを有効にしました",
    "Đã xoá tài khoản": "アカウントを削除しました",
    "Xoá thất bại": "削除に失敗しました",
    "Lỗi xoá tài khoản": "アカウントを削除できません",
    "Xoá tài khoản": "アカウントを削除",
    "Hành động này sẽ xoá toàn bộ dữ liệu:": "この操作によりすべてのデータが削除されます:",
    "Nhà và thiết bị": "家とデバイス",
    "Chia sẻ và quyền truy cập": "共有とアクセス権",
    "Toàn bộ dữ liệu liên quan": "関連するすべてのデータ",
    "Mật khẩu xác nhận": "確認用パスワード",
    "Thiết lập nhanh Alarm": "Alarm クイック設定",
    "Đang áp dụng...": "適用中...",
    "Áp dụng cho toàn bộ thiết bị": "すべてのデバイスに適用",
    "Thiết bị không còn tồn tại": "デバイスは存在しません",
    "Gọi điện": "電話",
    "Chat trong nhà": "家のチャット",
    "Tìm kiếm tin nhắn": "メッセージを検索",
    "Xem thành viên": "メンバーを見る",
    "Xoá từ khoá": "キーワードをクリア",
    "Không có kết quả": "結果がありません",
    "Tìm ngôn ngữ": "言語を検索",
    "Kết quả trước": "前の結果",
    "Kết quả tiếp theo": "次の結果",
    "Chưa có tin nhắn": "まだメッセージはありません",
    "Nhắc đến trong tin nhắn": "メッセージでメンション",
    "Huỷ trả lời": "返信をキャンセル",
    "Vừa xong": "たった今",
    "Xoá tất cả thông báo?": "すべての通知を削除しますか？",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "家の通知はすべて削除されます。",
    "Chưa có thông báo nào": "まだ通知はありません",
    "Chưa có thông báo": "通知はありません",
    "Vuốt lên để tải thêm": "上にスワイプしてさらに読み込む",
    "Bạn không có quyền quản lý phòng": "部屋を管理する権限がありません",
    "Đổi tên phòng": "部屋名を変更",
    "Tên phòng": "部屋名",
    "Xoá phòng": "部屋を削除",
    "Xoá": "削除",
    "Ví dụ: Phòng khách": "例: リビング",
    "Thêm": "追加",
    "Tên phòng đã tồn tại": "部屋名はすでに存在します",
    "Đổi tên": "名前を変更",
    "Thiết bị đang Offline": "デバイスはオフラインです",
    "Thiết bị đang Online": "デバイスはオンラインです",
    "pin yếu": "バッテリー低下",
    "sóng yếu": "信号が弱い",
    "lâu không phản hồi": "応答がありません",
    "Kết nối cần kiểm tra": "接続の確認が必要です",
    "Có khói": "煙を検知",
    "Nhiệt độ nguy hiểm": "危険な高温",
    "Phát hiện khí CO": "一酸化炭素を検知",
    "Không phát hiện khí CO": "一酸化炭素は検知されていません",
    "Đã kích hoạt": "作動中",
    "Rò rỉ gas": "ガス漏れを検知",
    "Phát hiện ngập nước": "水漏れを検知",
    "Phát hiện chuyển động": "動きを検知",
    "Không có chuyển động": "動きは検知されていません",
    "Phát hiện hiện diện": "在室を検知",
    "Không phát hiện hiện diện": "在室は検知されていません",
    "Phát hiện rung/chấn động": "振動/衝撃を検知",
    "Không có rung bất thường": "異常な振動はありません",
    "Phát hiện kính vỡ": "ガラス破損を検知",
    "Không có cảnh báo kính vỡ": "ガラス破損警報はありません",
    "Khóa đang đóng": "ロック中",
    "Đang bật": "オン",
    "Đang theo dõi điện năng": "電力を監視中",
    "Đang dùng nguồn dự phòng": "バックアップ電源を使用中",
    "Nguồn điện bình thường": "主電源は正常です",
    "Còi đang bật": "サイレン作動中",
    "Còi sẵn sàng": "サイレン準備完了",
    "Van đang mở": "バルブが開いています",
    "Van đã đóng": "バルブが閉じました",
    "Chưa nhận diện": "未認識",
    "Chưa có cập nhật": "まだ更新はありません",
    "Chưa có thông tin": "情報がありません",
    "CHƯA AN TOÀN": "安全ではありません",
    "CẦN CHÚ Ý": "注意が必要",
    "ĐÃ AN TOÀN": "安全",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "家は安定して稼働しています。安心してご利用いただけます。",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "詳細に分析するための新しい活動がまだ十分にありません。",
    "Chưa có dữ liệu trạng thái": "状態データがありません",
    "Cần xử lý ngay": "すぐに対応が必要",
    "Chưa có dữ liệu tổng quan": "概要データがありません",
    "Ngôi nhà đang hoạt động ổn định": "家は安定して稼働しています",
    "Thử lại": "再試行",
    "Không thể tải dữ liệu tài khoản": "アカウントデータを読み込めません",
    "Đã chia sẻ nhà thành công.": "家の共有が完了しました。",
    "Đã rời khỏi nhà": "家から退出しました",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.": "共有された家から退出します。",
    "Các nhà của bạn sẽ bị xoá.\n": "自分の家は削除されます。\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n": "選択した家のすべてのセキュリティデバイスの Home Alarm スケジュールを変更します。\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n": "選択した家に Home Reminder を追加します。\n\n",
    "Xác nhận thay đổi Alarm": "Alarm の変更を確認",
    "Xác nhận thay đổi Reminder": "Reminder の変更を確認",
    "Lặp lại khi sự cố vẫn còn": "問題が続く間は繰り返す",
    "Thời gian lặp lại Alarm": "Alarm の繰り返し時間",
    "VD: Mr Chung": "例: Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 まだ家がありません",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n": "オンにすると、セキュリティデバイスはすぐに監視されます。\n\n",
    "Bật Bảo vệ thủ công?": "手動保護モードをオンにしますか？",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ": "この操作により、本日の一部デバイスの Alarm 時刻が変更されます...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ": "この操作により、この家のすべての Alarm がオフになります。",
    "Tắt toàn bộ Alarm?": "すべての Alarm をオフにしますか？",
    "Không xoá được lịch tạm tắt Alarm": "Alarm の一時停止スケジュールを削除できません",
    "Không lưu được tạm tắt Alarm": "Alarm の一時停止を保存できません",
    "Không gửi được yêu cầu xoá": "削除リクエストを送信できません",
    "Không lưu được cài đặt": "設定を保存できません",
    "Không lấy được vị trí hiện tại": "現在地を取得できません",
    "Không thể xác nhận tài khoản hiện tại": "現在のアカウントを確認できませんでした",
    "Mật khẩu không đúng": "パスワードが正しくありません",
    "Không thể xác nhận mật khẩu": "パスワードを確認できませんでした",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động": "所有者または管理者のみが警報の繰り返し設定を変更できます",
    "Không lưu được thời gian lặp báo động": "警報の繰り返し時間を保存できませんでした",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "所有者または管理者のみが保護モードを変更できます",
    "Không thể thay đổi chế độ nhà": "家のモードを変更できませんでした",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "保護モードはオンですが、通知を送信できませんでした",
    "Đã bật Mode Bảo vệ thủ công": "手動保護モードがオンになりました",
    "Đã chuyển nhà về Bình thường": "家を通常モードに戻しました",
    "60 phút": "60 分",
    "30 phút": "30 分",
    "15 phút": "15 分",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.": "所有者のスケジュールを表示しています。自分の Alarm スケジュールを設定するには「自分のみ」を選択してください。",
    "Chọn giờ kết thúc Alarm": "Alarm の終了時刻を選択",
    "Chọn giờ bắt đầu Alarm": "Alarm の開始時刻を選択",
    "Bạn không có quyền sửa lịch Alarm của nhà": "この家の Alarm スケジュールを編集する権限がありません",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị": "すべてのデバイスに Alarm を適用できません",
    "Nhà chưa có thiết bị an ninh để áp dụng": "この家には適用できるセキュリティデバイスがありません",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.": "家の設定を編集する権限がありません。「自分のみ」を選択してください。",
    "Không thể lưu chế độ Alarm": "Alarm モードを保存できません",
    "Thêm khung giờ Alarm": "Alarm 時間帯を追加",
    "Đang sử dụng Reminder riêng của bạn": "自分の Reminder 設定を使用中",
    "Đang sử dụng Reminder của chủ nhà": "所有者の Reminder 設定を使用中",
    "Sửa giờ Reminder": "Reminder 時刻を編集",
    "Sửa giờ kết thúc Alarm": "Alarm の終了時刻を編集",
    "Sửa giờ bắt đầu Alarm": "Alarm の開始時刻を編集",
    "Xoá Reminder": "Reminder を削除",
    "Mỗi 1 giờ": "1 時間ごと",
    "Mỗi 30 phút": "30 分ごと",
    "Mỗi 15 phút": "15 分ごと",
    "Không báo lại": "再通知しない",
    "Báo lại khi vẫn chưa an toàn": "まだ安全でない場合は再通知",
    "Báo lại mỗi 1 giờ": "1 時間ごとに再通知",
    "Báo lại mỗi 30 phút": "30 分ごとに再通知",
    "Báo lại mỗi 15 phút": "15 分ごとに再通知",
    "Xoá thành viên": "メンバーを削除",
    "Đã xoá thành viên": "メンバーを削除しました",
    "Đồng ý": "OK",
    "Bạn chắc chắn muốn rời khỏi nhà này?": "この家から退出してもよろしいですか？",
    "Xoá thành viên?": "メンバーを削除しますか？",
    "Rời khỏi nhà?": "この家から退出しますか？",
    "Chỉ chủ nhà mới được thay đổi vai trò": "役割を変更できるのは所有者のみです",
    "Bạn không có quyền xoá thành viên này": "このメンバーを削除する権限がありません",
    "Bạn": "あなた",
    "Không có email": "メールなし",
    "Chưa có số điện thoại": "電話番号がありません",
    "Không mở được ứng dụng gọi điện": "電話アプリを開けません",
    "Thành viên chưa cập nhật số điện thoại": "このメンバーは電話番号を追加していません",
    "Hôm nay đã ghi nhận cảnh báo SOS": "今日は SOS アラートが記録されました",
    "Hôm nay đã ghi nhận cảnh báo khói": "今日は煙アラートが記録されました",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "手動警戒モードがオンです - オフにするには通常モードに切り替えてください",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "0 を選ぶと 1 回だけ通知します。この設定は手動保護モードと外出時の自動保護の両方に適用されます。",
    "Lặp báo động khi sự cố vẫn còn": "問題が続く間 Alarm を繰り返す",
    "Đang được sử dụng": "現在有効です",
    "Chuyển về sử dụng thông thường": "通常の使用に戻す",
    "Chế độ nhà": "家のモード",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "SOS デバイスにアラートは記録されていません。",
    "Cảm biến khói chưa ghi nhận bất thường.": "煙センサーは異常を検知していません。",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.": "あなたまたはメンバーが手動で警戒をオンにしました。",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.": "外出したため SafeHome が自動で警戒をオンにしました。",
    "Nhà đang ở chế độ dùng bình thường.": "この家は現在通常モードです。",
    "Bảo vệ thủ công đang bật": "手動警戒がオンです",
    "Bảo vệ tự động đang bật": "自動警戒がオンです",
    "Bảo vệ đang tắt": "警戒モードはオフです",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.": "最近アプリを開いて状態を確認しています。",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.": "権限、スケジュール、未読警報を確認するため定期的にアプリを開いてください。",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.": "数回使用すると、SafeHome がアプリ確認習慣をより正確に評価できます。",
    "Tần suất vào app ổn": "アプリ確認頻度は良好です",
    "Đã lâu chưa vào app kiểm tra": "アプリ確認から時間が経っています",
    "Đang ghi nhận tần suất vào app": "アプリ確認頻度を記録中",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.": "常に位置情報の許可とバックグラウンド条件を確認してください。",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.": "このデバイスは自動外出の条件を満たしています。",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.": "外出時に自動で警戒モードにしたい場合は有効にしてください。",
    "Auto rời khỏi nhà chưa ổn": "自動外出は準備できていません",
    "Auto rời khỏi nhà đã sẵn sàng": "自動外出は準備完了です",
    "Auto rời khỏi nhà chưa bật": "自動外出は有効ではありません",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.": "煙センサー、SOS、または家に合った緊急デバイスを追加してください。",
    "Chưa có thiết bị khẩn cấp": "緊急デバイスがありません",
    "Đã có thiết bị khẩn cấp": "緊急デバイスが追加されています",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.": "就寝中や外出時のために Alarm スケジュールを設定してください。",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.": "この家には Alarm スケジュールまたはデバイス別警報スケジュールがあります。",
    "Chưa set lịch Alarm": "Alarm スケジュールが未設定です",
    "Đã set lịch Alarm": "Alarm スケジュール設定済み",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.": "家の確認を忘れないように少なくとも 1 つ Reminder を設定してください。",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.": "アプリが設定したスケジュールで家の確認を促します。",
    "Chưa setup Reminder": "Reminder が未設定です",
    "Đã setup Reminder": "Reminder 設定済み",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.": "このデバイスが警報を受信しない場合は、アプリを開き直すか再ログインしてください。",
    "Thiết bị chưa đăng ký nhận cảnh báo": "このデバイスは警報受信に登録されていません",
    "Thiết bị nhận cảnh báo bình thường": "このデバイスは警報を受信できます",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.": "iOS は Android よりバックグラウンド動作を厳しく管理します。自動外出を使う場合は通知と常に位置情報をオンにしてください。",
    "Cơ chế iOS": "iOS の仕組み",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.": "警報が遅れないようにバックグラウンド権限と自動起動を確認してください。",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.": "デバイスは重要なバックグラウンド条件を確認済みです。",
    "Cần kiểm tra chạy nền / tự khởi động": "バックグラウンド動作 / 自動起動を確認してください",
    "Chạy nền ổn định": "バックグラウンド動作は安定しています",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "一部の Android 端末では、バッテリー最適化が有効だと警報が遅れる場合があります。",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.": "端末が SafeHome の警報を遅らせる可能性は低いです。",
    "Chưa tắt tối ưu pin": "バッテリー最適化がまだ有効です",
    "Tối ưu pin không chặn app": "バッテリー最適化はアプリを妨げていません",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.": "自動外出を安定して動かすには常に位置情報が必要です。",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.": "自動外出には位置情報の許可が必要です。",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.": "位置情報サービスがオフのため、自動外出が安定しない可能性があります。",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.": "自動外出を使う場合のみ必要です。",
    "Chưa cấp vị trí luôn luôn": "常に位置情報が許可されていません",
    "Đã cấp vị trí luôn luôn": "常に位置情報が許可されています",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.": "iOS は Android のように全画面表示せず、システム通知と音を使います。",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.": "Android は全画面警報を使います。端末がブロックする場合は設定で許可してください。",
    "Cảnh báo trên iOS": "iOS の警報",
    "Cảnh báo toàn màn hình": "全画面アラート",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "通知が無効だと警報が表示されない可能性があります。",
    "Điện thoại có thể nhận thông báo SafeHome.": "この端末は SafeHome の通知を受け取れます。",
    "Chưa bật thông báo": "通知が有効ではありません",
    "Đã bật thông báo": "通知が有効です",
    "Hệ thống: Sẵn sàng": "システム: 準備完了",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "システム: 警報を見逃す可能性",
    "Cách bạn đang dùng app": "アプリの使い方",
    "Thiết bị của bạn": "あなたのデバイス",
    "Kiểm tra điện thoại và cách bạn đang dùng app.": "スマートフォンとアプリの使い方を確認します。",
    "Hệ thống SafeHome": "SafeHome システム",
    "Hệ thống: Đang kiểm tra...": "システム: 確認中...",
    "Mở cài đặt": "設定を開く",
    "Để sau": "後で",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.": "SafeHome には、外出または帰宅を検知するために \"常に許可\" の位置情報権限が必要です。アプリがバックグラウンドで動作している場合も含まれます。",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.": "SafeHome は現在、アプリの使用中のみ位置情報にアクセスできます。\n\n位置情報の権限を開き、\"常に許可\" を選択すると、外出時の自動保護がバックグラウンドでも動作し続けます。",
    "Cho phép vị trí luôn luôn": "位置情報を常に許可",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.": "自分の家は削除されます。\n共有された家からは退出します。",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "選択した家のすべてのセキュリティデバイスの Home Alarm スケジュールを変更します。\n\n家の Alarm 設定を使用しているメンバーに影響します。\n「自分のみ」モードの個人 Alarm は変更されません。",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "選択した家に Home Reminder を追加します。\n\n家の Reminder 設定を使用しているメンバーに影響します。\n「自分のみ」モードの個人 Reminder は変更されません。",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "オンにすると、セキュリティデバイスはすぐに監視されます。\n\n外出時の自動保護は一時停止します。このモードは誰かが帰宅しても自動ではオフにならず、権限のあるメンバーが手動で通常モードに戻す必要があります。",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...": "この操作により、本日の一部デバイスの Alarm 時刻が変更されます...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.": "この操作により、この家のすべての Alarm がオフになります。この端末で危険通知を受け取れなくなります。",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.": "Alarm は「家の設定」モードを使用しています。\n\n所有者または管理者が設定した共有スケジュールに従って通知を受け取ります。",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.": "Alarm は「自分のみ」モードを使用しています。\n\nこのアカウントに設定された個人用 Alarm スケジュールに従って通知を受け取ります。",
    "Không đặt được mật khẩu": "パスワードを設定できません",
    "Chấp nhận": "承認",
    "Cho phép": "許可",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.": "招待を承認できませんでした。もう一度お試しください。",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.": "参加リクエストを承認できませんでした。もう一度お試しください。",
    "Từ chối": "拒否",
    "Lời mời từ chủ nhà": "所有者からの招待",
    "Nhận quyền chủ nhà": "家の所有権を受け取る",
    "Một người dùng SafeHome": "SafeHome ユーザー",
    "Lời mời gia nhập": "参加招待",
    "Lời xin vào nhà": "家への参加リクエスト",
    "Nhập HUB ID": "HUB ID を入力",
    "VD: HUB_001": "例: HUB_001",
    "Pair": "ペアリング",
    "Mật khẩu tối thiểu 6 ký tự": "パスワードは6文字以上で入力してください",
    "Mật khẩu nhập lại không khớp": "再入力したパスワードが一致しません",
    "Tạo mật khẩu": "パスワードを作成",
    "Mật khẩu mới": "新しいパスワード",
    "Nhập lại mật khẩu": "パスワードを再入力",
    "Xác nhận tắt cảnh báo": "警報停止の確認",
    "HỦY": "キャンセル",
    "XÁC NHẬN": "確認",
    "CẦN KIỂM TRA": "確認が必要",
    "KIỂM TRA NHÀ": "家を確認",
    "ĐÓNG NHẮC NHỞ": "リマインダーを閉じる",
    "SafeHome Security Alert": "SafeHome セキュリティ警報",
    "Bạn không có quyền sắp xếp phòng": "部屋を並べ替える権限がありません",
    "Báo động đã tắt": "アラームはオフです",
    "Báo động kích hoạt": "アラームが作動しました",
    "Chọn giờ kết thúc tạm tắt": "一時停止の終了時刻を選択",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh": "まだデバイスがありません。+ ボタンを押して追加し、セキュリティを維持しましょう",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "アプリ設定で位置情報の権限を「常に許可」にしてください",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn": "または QR をスキャンして選択した家への参加を申請",
    "Không có nhà nào bạn có quyền quản lý": "管理権限のある家がありません",
    "Không tìm thấy thành viên phù hợp": "該当するメンバーが見つかりません",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.": "他の人がこのコードをスキャンして家への参加リクエストを送信できます。",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.": "この家と中のすべてのデバイスは完全に削除されます。",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.": "Google アカウントでセキュリティ機能を使うには、追加のパスワードを作成する必要があります。",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.": "この名前はあなたのアカウントにのみ表示されます。",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.": "名前と住所は家のすべてのメンバーに更新されます。",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp": "緊急時に使う電話番号を追加してください",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.": "この部屋のデバイスは「未分類」に移動されます。",
    "Thông báo": "通知",
    "Tìm nội dung hoặc tên người gửi": "内容または送信者名を検索",
    "Xem lời mời chia sẻ và xin gia nhập": "共有招待と参加リクエストを表示",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ 今日のAlarmを一時停止",
    "Alarm cleared": "アラーム解除",
    "Alarm triggered": "アラーム発生",
    "Bấm vào để xem chi tiết": "タップして詳細を表示",
    "Bàn phím an ninh": "セキュリティキーパッド",
    "Báo gas": "ガス警報",
    "Báo khói": "煙センサー",
    "Báo ngập/rò nước": "浸水・漏水センサー",
    "Báo nhiệt": "熱センサー",
    "Battery low": "バッテリー残量低下",
    "Bộ mở rộng sóng": "中継器",
    "Bụi mịn PM2.5": "PM2.5",
    "Cả ngày": "終日",
    "Cài đặt": "設定",
    "Cài đặt cảnh báo cho nhà hiện tại": "現在の家のアラーム設定",
    "Cập nhật": "更新",
    "Chất lượng không khí": "空気品質",
    "Chi tiết": "詳細",
    "Chưa có dữ liệu thiết bị để đánh giá": "評価するためのデバイスデータがありません",
    "Chuông cửa": "ドアベル",
    "Chuyển động": "モーション",
    "Chuyển quyền sở hữu cho thành viên khác": "所有権を別のメンバーに移転",
    "CO₂": "CO₂",
    "Còi báo động": "サイレン",
    "Công suất": "電力",
    "Cửa đã đóng an toàn": "ドアは安全に閉じています",
    "Cửa đóng": "ドアが閉じています",
    "Cửa mở": "ドアが開いています",
    "Cường độ rung": "振動強度",
    "Đã rời khỏi home": "家から退出しました",
    "Đang bật cho tài khoản này": "このアカウントで有効",
    "Đang kiểm tra kết nối Hub": "Hub 接続を確認中",
    "Đang tắt cho tài khoản này": "このアカウントで無効",
    "Đang theo dõi": "監視中",
    "Đánh giá tự động": "自動評価",
    "Device offline": "デバイスがオフライン",
    "Device online": "デバイスがオンライン",
    "Điện áp": "電圧",
    "Điện năng": "電力量",
    "Độ ẩm": "湿度",
    "Đo điện năng": "電力計測",
    "Độ mở van": "バルブ開度",
    "Dòng điện": "電流",
    "Door closed": "ドアが閉じました",
    "Door opened": "ドアが開きました",
    "Góc nghiêng": "傾斜角",
    "Hiện diện": "在室検知",
    "Hồ sơ, yêu cầu và lời mời tham gia": "プロフィール、リクエスト、招待",
    "Hub chưa gửi trạng thái": "Hub の状態がありません",
    "Hub mất kết nối": "Hub が切断されました",
    "Hub tín hiệu bình thường": "Hub 接続は正常です",
    "Hub trung tâm": "中央Hub",
    "Khí CO": "COセンサー",
    "Khóa thông minh": "スマートロック",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "煙またはSOSの異常はありません。",
    "Không có thông báo": "通知はありません",
    "Khu vực nguy hiểm": "危険ゾーン",
    "Kiểm tra thiết bị trong nhà này": "この家のデバイスを確認",
    "Kính vỡ": "ガラス破損",
    "Loại thiết bị": "デバイス種別",
    "Lưu ý khi bật Alarm": "Alarm有効時の注意",
    "Mất điện lưới": "主電源が切断されました",
    "Mở List chia sẻ nhà": "家の共有リストを開く",
    "Mời người khác tham gia nhà này": "他の人をこの家に招待",
    "Motion detected": "モーション検知",
    "MQTT mất kết nối": "MQTT が切断されました",
    "Ngập/rò nước": "浸水・漏水",
    "Nguồn dự phòng": "バックアップ電源",
    "Nguồn dự phòng UPS": "UPSバックアップ電源",
    "Nhà đã chia sẻ": "共有された家",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.": "家に確認が必要な兆候があります。下の状態を確認してください。",
    "Nhà đang hoạt động bình thường": "家は正常に動作しています",
    "Nhắc kiểm tra nhà theo thời gian": "指定時刻に家の確認を通知",
    "Nhận cảnh báo Alarm": "Alarmアラートを受信",
    "Nhập email": "メールアドレスを入力",
    "Nhiệt độ": "温度",
    "Nhiệt độ/Độ ẩm": "温度・湿度",
    "Nút SOS": "SOSボタン",
    "Ổ điện thông minh": "スマートプラグ",
    "Phát hiện cạy phá": "こじ開けを検知",
    "Phát hiện khói": "煙を検知",
    "Quét mã QR chia sẻ nhà": "共有QRコードをスキャン",
    "Quét QR để xin gia nhập nhà": "QRをスキャンして家への参加をリクエスト",
    "Quét QR xin gia nhập nhà": "家に参加するQRをスキャン",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "共有された家のQRコードを枠内に合わせてください",
    "Mã QR này do chủ nhà chia sẻ":
    "このQRコードは家の所有者が共有したものです",
    "Nhập mã mời": "招待コードを入力",
    "Gửi yêu cầu gia nhập": "参加リクエストを送信",
    "QR này không phải mã thiết bị": "このQRコードはデバイスコードではありません",
    "Rung/chấn động": "振動",
    "SafeHome": "SafeHome",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "アカウントとシステム",
    "Tài khoản cá nhân": "個人アカウント",
    "Tạm dừng": "一時停止",
    "Tamper cleared": "取り外し検知解除",
    "Tamper detected": "取り外し検知",
    "Tạo tài khoản": "アカウント作成",
    "Thêm, đổi tên và sắp xếp phòng": "部屋の追加、名前変更、並べ替え",
    "Thiết bị đang được giám sát": "デバイスを監視中",
    "Tìm kiếm": "検索",
    "Van thông minh": "スマートバルブ",
    "Về nhà": "帰宅",
    "Xác nhận thay đổi": "変更を確認",
    "Xem và quản lý quyền thành viên": "メンバー権限を表示・管理",
    "Xóa": "削除",
    "Xoá các nhà đã chọn ?": "選択した家を削除しますか？",
    "Xóa nhà": "家を削除",
    "Xoá toàn bộ dữ liệu và thiết bị": "すべてのデータとデバイスを削除",
    "TẮT CẢNH BÁO": "警報を停止",
    "Đã tạo nhà": "家を作成しました",

    "Mode Bảo vệ thủ công đã bật": "手動保護モードが有効です",
    "Báo động không lặp lại.": "アラームは繰り返されません。",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.": "問題が残っている場合、\$securityModeRepeatMinutes 分後にアラームが繰り返されます。",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage": "\$actorName が「\$homeName」の手動保護モードをオンにしました。このモードは、権限のあるメンバーが通常モードに戻したときだけオフになります。\$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".": "「\$homeName」のAlarmをオンにしました。",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".": "「\$homeName」のすべてのAlarmをオフにしました。",
    "Thành viên mới": "新しいメンバー",
    "Thành viên rời nhà": "メンバーが家を出ました",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".": "\$displayMemberName が「\$homeName」から退出しました。",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".": "\$actorName が「\$homeName」で \$memberName の役割を \$oldRoleName から \$newRoleName に変更しました。",
    "Còn \$count tin nhắn chưa đọc": "未読メッセージ \$count 件",
    "Hãy an tâm nghỉ ngơi.": "安心して大丈夫です。",
    "Có thiết bị chưa an toàn.": "一部のデバイスが安全ではありません。",
    "SafeHome đang cập nhật vị trí": "SafeHomeが位置情報を更新しています",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.": "保護モードを自動でオンにするため監視中です。",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.": "全員が外出したとき、位置情報を使って保護モードを自動でオンにします。",
    "CẢNH BÁO SOS": "SOSアラート",
    "CẢNH BÁO KHÓI / CHÁY": "煙/火災アラート",
    "CẢNH BÁO NGẬP NƯỚC": "浸水アラート",
    "CẢNH BÁO RÒ KHÍ": "ガス漏れアラート",
    "CẢNH BÁO CỬA": "ドアアラート",
    "CẢNH BÁO AN NINH": "セキュリティアラート",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.": "SafeHomeで確認できませんでした。接続を確認してもう一度お試しください。",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?": "家の状態を確認してからアラートを停止してください。\n\nアラートを停止してもよろしいですか？",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHomeがアラートを検知しました",
    "Mở SafeHome để kiểm tra ngay.": "SafeHomeを開いて今すぐ確認してください。",
    "\$count tin nhắn mới": "新着メッセージ \$count 件",
    "Tin nhắn HomeChat": "HomeChatメッセージ",
    "\$senderName đã gửi một tin nhắn": "\$senderName がメッセージを送信しました",
    "Bạn có tin nhắn mới": "新着メッセージがあります",
    "Mode Bảo vệ sẽ chỉ báo động một lần": "保護モードは一度だけアラートします",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút": "保護モードは \$minutes 分後にアラートを繰り返します",
    "Đã gửi yêu cầu gia nhập \$count nhà": "\$count 件の家に参加リクエストを送信しました",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".": "\$requesterName が「\$homeName」への参加をリクエストしました。",
    "Bạn đã xoá nhà \"\$homeName\".": "「\$homeName」を削除しました。",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.": "\$email に「\$homeName」の所有権譲渡リクエストを送信しました。",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.": "\$actorName が「\$homeName」の所有権をあなたに譲渡しようとしています。",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".": "\$actorName が「\$homeName」への参加に招待しました。",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".": "SafeHomeが「\$homeName」から「\$deviceName」を削除しています。",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".": "デバイス「\$deviceName」が「\$homeName」に追加されました。",
    "Bạn đã tạo nhà \"\$name\".": "家「\$name」を作成しました。",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.": "\$actorName が家の名前を「\$newName」に更新し、住所を変更しました。",
    "\$actorName đã đổi tên nhà thành \"\$newName\".": "\$actorName が家の名前を「\$newName」に変更しました。",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".": "\$actorName が「\$newName」の住所を更新しました。",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".": "\$actorName が「\$homeName」のデバイス「\$oldDeviceName」を「\$newName」に名前変更しました。",
    "Đang ghép nối: \$seconds giây": "ペアリング中: \$seconds 秒",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.": "「\$homeName」でデバイス追加モードが \$seconds 秒間有効になりました。",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)": "一時停止時間はAlarmスケジュール内（\$start → \$end）である必要があります",
    "\$passCount/\$total bài test đạt\n\n": "\$passCount/\$total 件のテストに合格\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.": "\$name はプロフィールに電話番号を追加していません。",
    "Tin nhắn mới trong \$homeName": "\$homeName に新着メッセージ",
    "\$current/\$total kết quả": "\$current/\$total 件の結果",
    "Đang trả lời \$name": "\$name に返信中",
    "\"\$name\" phát hiện khói trong \"\$homeName\".": "「\$homeName」の「\$name」が煙を検知しました。",
    "\"\$name\" đã trở lại trạng thái bình thường.": "「\$name」は通常状態に戻りました。",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".": "「\$homeName」の「\$name」がSOSを作動しました。",
    "\"\$name\" đã hết trạng thái SOS.": "「\$name」はSOS状態ではなくなりました。",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".": "「\$homeName」の「\$name」が改ざんを報告しました。",
    "\"\$name\" đã hết cảnh báo tháo/cạy.": "「\$name」の改ざんアラートは解除されました。",
    "\"\$name\" đã đóng trong \"\$homeName\".": "「\$homeName」の「\$name」が閉じました。",
    "\"\$name\" đang mở trong \"\$homeName\".": "「\$homeName」の「\$name」が開いています。",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.": "「\$homeName」の「\$name」はバッテリー残量が少なくなっています。",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.": "「\$homeName」の「\$name」がオフラインになりました。",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.": "「\$homeName」の「\$name」がオンラインに戻りました。",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".": "「\$homeName」の「\$name」が高温を記録しました。",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".": "「\$homeName」の「\$name」が高湿度を記録しました。",
    "Có nút SOS vừa được kích hoạt": "SOSボタンが作動しました",
    "Có dấu hiệu khói hoặc cháy": "煙または火災を検知しました",
    "Có dấu hiệu ngập nước": "浸水を検知しました",
    "Có dấu hiệu rò khí": "ガス漏れを検知しました",
    "Có cửa đang mở hoặc thiết bị bị tháo": "ドアが開いているか、デバイスが改ざんされました",
    "Có thiết bị đang cảnh báo": "アラート中のデバイスがあります",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.": "誰も確認しない場合、SafeHomeは緊急通話に切り替えます。",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.": "問題が未対応の場合、\$time に再通知します。",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.": "問題が未対応の場合、Alarmスケジュールに従って再通知します。",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".": "「\$resolvedHomeName」の「\$deviceName」が閉じました。",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".": "「\$resolvedHomeName」の「\$deviceName」が開いています。",
    "\$count nhà đã chọn": "\$count 件の家を選択済み",
    "🚨 \$count nhà không an toàn\$suffix": "🚨 安全ではない家 \$count 件\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix": "⚠️ \$count 件の家に注意が必要です\$suffix",
    "✅ \$count nhà an toàn": "✅ 安全な家 \$count 件",
    "\$count nhà đang được theo dõi": "\$count 件の家を監視中",
    "\$minutes phút": "\$minutes分",
    "Đã cài Reminder cho \$updatedHomes nhà.": "\$updatedHomes 件の家にReminderを設定しました。",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n": "\$updatedHomes 件の家にある \$updatedDevices 台のデバイスにAlarmを設定しました。\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.": "管理している家を共有しました。\n\n共有権限がないため、\$skipped 件の家をスキップしました。",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh": "\$count 台のセキュリティデバイスにAlarmを適用しました",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh": "\$count 台のセキュリティデバイスに同じスケジュールを適用",
    "\$count phút trước": "\$count分前",
    "\$count giờ trước": "\$count時間前",
    "\${count}h trước": "\${count}時間前",
    "\${hours}h\$minutes' trước": "\${hours}時間\${minutes}分前",
    "\$count ngày trước": "\$count日前",
    "\$count tháng trước": "\$countか月前",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?": "\$name をこの家から削除してもよろしいですか？",
    "\$targetEmail\nXin gia nhập \"\$homeName\"": "\$targetEmail\n「\$homeName」への参加をリクエスト",
    "Xin gia nhập \"\$homeName\"": "「\$homeName」への参加をリクエスト",
    "Bạn được mời nhận quyền nhà \"\$homeName\"": "「\$homeName」の所有権を受け取るよう招待されました",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"": "\$ownerEmail\n「\$homeName」への参加に招待しています",
    "Mời bạn gia nhập \"\$homeName\"": "「\$homeName」への参加に招待しています",
    "Cần kiểm tra: \$joined": "確認が必要: \$joined",
    "Cập nhật \$value": "更新: \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.": "最初のSafeHomeデバイスを追加して、この家の監視を始めましょう。",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.": "まず緊急アラートを確認し、必要に応じて家のメンバーに連絡してください。",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "家にメンバーがいませんが、ドアまたはロックが開いています。今すぐ確認してください。",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "この家を保護モードのままにする前に、開いているドアまたはロックを確認してください。",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.": "まだ家に人がいる可能性があります。その場合は通常モードに戻してください。",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.": "位置不明のメンバーがいます。アプリを開くか位置権限を確認するよう伝えてください。",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "デバイスが切断されています。バッテリー、電源、設置場所を確認してください。",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.": "バッテリー残量が少ないデバイスがあります。アラートを逃さないよう早めに交換してください。",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.": "Reminderが未設定です。家を定期的に確認するスケジュールを作成してください。",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.": "Alarmスケジュールが未設定です。普段不在にする時間帯に保護を有効にしてください。",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.": "今すぐ対応する必要はありません。この家の監視を続けてください。",
    "Lặp sau \$minutes phút": "\$minutes 分後に繰り返し",
    "Đang dùng • \$repeatText": "有効 • \$repeatText",
    "Giám sát an ninh • \$repeatText": "セキュリティ監視 • \$repeatText",
    "Gia đình: \$mode": "家のモード: \$mode",
    "Gợi ý xử lý": "推奨アクション",
    "Phát hiện \$count vấn đề cần xử lý": "\$count 件の問題に対応が必要です",
    "Hôm nay các cửa đã được sử dụng \$count lần": "今日はドアが \$count 回使用されました",
    "Đã ghi nhận \$count hoạt động gần đây": "最近のアクティビティ \$count 件を記録しました",
    "Hệ thống: Cần kiểm tra \$issueCount mục": "システム: \$issueCount 件の確認が必要です",
    "FCM token đã sẵn sàng trên điện thoại này.": "この端末のFCMトークンは準備済みです。",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.": "FCMトークンは準備済みですが、Auto Awayに必要な条件が不足しています。",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.": "緊急デバイスが \$emergencyTotal 台見つかりました。推奨最小構成: 煙センサーとSOS。",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?": "家の所有権を次に譲渡しますか:\n\$targetEmail?",
    "\$count cửa đã đóng an toàn": "\$count 個のドアが安全に閉じています",
    "\$count cửa và khóa đã an toàn": "\$count 個のドアとロックが安全です",
    "\$count thiết bị đang được theo dõi": "\$count 台のデバイスを監視中",
    "Cập nhật \$timeText": "\$timeText に更新",
    "Dữ liệu gần nhất cập nhật \$count phút trước": "最新データは \$count 分前に更新されました",
    "Dữ liệu gần nhất cập nhật \$count giờ trước": "最新データは \$count 時間前に更新されました",
    "Thành viên trong nhà: \$count": "在宅メンバー: \$count",
    "Thành viên bên ngoài: \$count": "外出中のメンバー: \$count",
    "Chưa xác định vị trí: \$count": "位置不明: \$count",
    "Môi trường hiện tại: \$environment": "現在の環境: \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ": "\$name: 家が保護モード中に開いています",
    "An tâm hơn trong từng ngôi nhà": "すべての家に、もっと安心を",
    "Báo động SafeHome": "SafeHomeアラーム",
    "Có cảnh báo an ninh cần kiểm tra ngay.": "確認が必要なセキュリティアラートがあります。",
    "Có cảnh báo cần kiểm tra": "確認が必要なアラートがあります",
    "Tự đóng sau \$time": "\$time 後に自動で閉じます",
  };

  static const Map<String, String> _german = {
    "Không tìm thấy người dùng": "Benutzer nicht gefunden",
    "Không đọc được số điện thoại": "Telefonnummer konnte nicht gelesen werden",
    "Tin nhắn quá dài": "Nachricht ist zu lang",
    "Không gửi được tin nhắn": "Nachricht konnte nicht gesendet werden",
    "Bạn không có quyền sửa lịch chung của nhà": "Du hast keine Berechtigung, den gemeinsamen Hauszeitplan zu bearbeiten",
    "Nhà của bạn": "Dein Zuhause",
    "Tải tin cũ hơn": "Ältere Nachrichten laden",
    "Nhà chưa đặt tên": "Unbenanntes Zuhause",
    "Nhà": "Zuhause",
    "Chưa có thông tin": "Keine Informationen verfügbar",
    "Chưa cập nhật": "Nicht aktualisiert",
    "Chủ nhà": "Besitzer",
    "Nhà được chia sẻ": "Geteiltes Zuhause",
    "Địa chỉ": "Adresse",
    "An ninh ra/vào": "Zugangssicherheit",
    "Nguy hiểm khẩn cấp": "Notfallrisiken",
    "Điều khiển & hạ tầng": "Steuerung & Infrastruktur",
    "Môi trường": "Umgebung",
    "Toàn bộ thiết bị SafeHome": "Alle SafeHome-Geräte",
    "Cửa ra/vào": "Eingangstür",
    "Cửa": "Tür",
    "Cửa sổ": "Fenster",
    "Cổng": "Tor",
    "Khóa thông minh": "Smartes Schloss",
    "Chuyển động": "Bewegung",
    "Hiện diện": "Anwesenheit",
    "Rung/chấn động": "Vibration/Erschütterung",
    "Kính vỡ": "Glasbruch",
    "Báo khói": "Rauchmelder",
    "Báo nhiệt": "Wärmesensor",
    "Khí CO": "CO-Sensor",
    "Báo gas": "Gasalarm",
    "Báo ngập/rò nước": "Überschwemmungs-/Leckagesensor",
    "Nút SOS": "SOS-Taste",
    "Nhiệt độ/Độ ẩm": "Temperatur/Luftfeuchtigkeit",
    "Bụi mịn PM2.5": "PM2.5",
    "CO₂": "CO₂-Sensor",
    "Chất lượng không khí": "Luftqualität",
    "Ổ điện thông minh": "Smarte Steckdose",
    "Còi báo động": "Sirene",
    "Van thông minh": "Smartes Ventil",
    "Camera": "Kamera",
    "Chuông cửa": "Türklingel",
    "Bàn phím an ninh": "Sicherheits-Tastenfeld",
    "Bộ mở rộng sóng": "Signalverstärker",
    "Hub trung tâm": "Zentraler Hub",
    "Đo điện năng": "Energiemessung",
    "Nguồn dự phòng UPS": "USV-Notstromversorgung",
    "Thiết bị đang Offline": "Gerät ist offline",
    "Thiết bị đang Online": "Gerät ist online",
    "pin yếu": "Niedriger Batteriestand",
    "sóng yếu": "Schwaches Signal",
    "lâu không phản hồi": "lange keine Antwort",
    "Kết nối cần kiểm tra": "Verbindung prüfen",
    "Vừa xong": "Gerade eben",
    "Bị tháo": "Manipulation erkannt",
    "Có khói": "Rauch erkannt",
    "Bình thường": "Normalmodus",
    "Bảo vệ": "Schutzmodus",
    "Chế độ Bảo vệ": "Schutzmodus",
    "Tự động Bảo vệ khi rời nhà": "Automatischer Schutz beim Verlassen",
    "Đã kích hoạt": "Aktiviert",
    "Sẵn sàng": "Bereit",
    "Đang đóng": "Geschlossen",
    "Đang mở": "Offen",
    "Rò rỉ gas": "Gasleck erkannt",
    "Phát hiện ngập nước": "Wasserleck erkannt",
    "Phát hiện chuyển động": "Bewegung erkannt",
    "Không có chuyển động": "Keine Bewegung erkannt",
    "Phát hiện hiện diện": "Anwesenheit erkannt",
    "Không phát hiện hiện diện": "Keine Anwesenheit erkannt",
    "Phát hiện rung/chấn động": "Vibration erkannt",
    "Không có rung bất thường": "Keine ungewöhnliche Vibration",
    "Phát hiện kính vỡ": "Glasbruch erkannt",
    "Không có cảnh báo kính vỡ": "Kein Glasbruchalarm",
    "Nhiệt độ nguy hiểm": "Gefährliche Hitze erkannt",
    "Phát hiện khí CO": "Kohlenmonoxid erkannt",
    "Không phát hiện khí CO": "Kein Kohlenmonoxid erkannt",
    "Khóa đang mở": "Entriegelt",
    "Khóa đang đóng": "Verriegelt",
    "Đang bật": "Ein",
    "Đang tắt": "Aus",
    "Đang theo dõi điện năng": "Stromüberwachung",
    "Đang dùng nguồn dự phòng": "Läuft mit Notstrom",
    "Nguồn điện bình thường": "Netzstrom normal",
    "Còi đang bật": "Sirene aktiv",
    "Còi sẵn sàng": "Sirene bereit",
    "Van đang mở": "Ventil offen",
    "Van đã đóng": "Ventil geschlossen",
    "Đang hoạt động": "In Betrieb",
    "Đang theo dõi": "Wird überwacht",
    "Chưa nhận diện": "Unbekanntes Gerät",
    "Chưa có cập nhật": "Keine Aktualisierung",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh": "Noch keine Geräte. Tippe auf +, um eines hinzuzufügen und dein Zuhause zu schützen.",
    "CHƯA AN TOÀN": "NICHT SICHER",
    "CẦN CHÚ Ý": "Aufmerksamkeit erforderlich",
    "ĐÃ AN TOÀN": "SICHER",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.": "Zuhause zeigt Anzeichen, die geprüft werden sollten. Prüfe die Status unten.",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "Dein Zuhause funktioniert normal.",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "Keine ungewöhnlichen Rauch- oder SOS-Anzeichen.",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "Es gibt noch nicht genug aktuelle Aktivität für eine genauere Analyse.",
    "Hub kết nối bình thường": "Hub verbunden",
    "Cài đặt cảnh báo cho nhà hiện tại": "Alarm-Einstellungen für das aktuelle Zuhause",
    "Nhận cảnh báo Alarm": "Alarm-Warnungen erhalten",
    "Đang bật cho tài khoản này": "Für dieses Konto aktiviert",
    "Đang tắt cho tài khoản này": "Für dieses Konto deaktiviert",
    "Hẹn giờ Reminder": "Reminder-Zeitplan",
    "Nhắc kiểm tra nhà theo thời gian": "Zu bestimmten Zeiten an die Zuhause-Prüfung erinnern",
    "Hẹn giờ Alarm": "Alarm planen",
    "Chưa thiết lập": "Nicht festgelegt",
    "Chưa thiết lập thời gian": "Kein Zeitplan eingerichtet",
    "Tổng hợp trạng thái nhà": "Statusübersicht des Zuhauses",
    "Cần xử lý ngay": "Sofortige Aktion erforderlich",
    "Cần kiểm tra": "Prüfung erforderlich",
    "Đánh giá tự động": "Automatische Bewertung",
    "Tự động đánh giá": "Automatische Bewertung",
    "Tổng quan hôm nay": "Heutige Übersicht",
    "Chưa có dữ liệu tổng quan": "Noch keine Übersichts-Daten",
    "Chưa có dữ liệu trạng thái": "Noch keine Statusdaten",
    "Chưa đủ dữ liệu để đánh giá": "Nicht genügend Daten zur Bewertung",
    "Chưa có dữ liệu để đánh giá": "Nicht genügend Daten zur Bewertung",
    "Bấm vào để xem chi tiết": "Tippen, um Details anzuzeigen",
    "Nhấn để xem chi tiết...": "Zum Anzeigen der Details tippen...",
    "Tạm dừng": "Pausieren",
    "Tắt": "Aus",
    "Chi tiết": "Einzelheiten",
    "Tổng hợp trạng thái": "Statusübersicht",
    "Không an toàn": "Nicht sicher",
    "Cần chú ý": "Aufmerksamkeit erforderlich",
    "An toàn": "Sicher",
    "Không có": "Keine",
    "Đổi tên nhóm": "Gruppe umbenennen",
    "Huỷ": "Abbrechen",
    "Hủy": "Abbrechen",
    "Lưu": "Speichern",
    "Thêm": "Hinzufügen",
    "Xoá": "Löschen",
    "Đổi tên": "Umbenennen",
    "Nhà của tôi": "Meine Zuhause",
    "Bỏ chọn toàn bộ nhóm": "Gesamte Gruppe abwählen",
    "Chọn toàn bộ nhóm": "Gesamte Gruppe auswählen",
    "Bỏ chọn": "Abwählen",
    "Quay lại": "Zurück",
    "Tìm kiếm": "Suche",
    "Đóng tìm kiếm": "Suche schließen",
    "Giờ": "Stunde",
    "Phút": "Minuten",
    "Đặt Home Reminder": "Zuhause-Reminder einrichten",
    "Đặt Home Alarm": "Zuhause-Alarm einrichten",
    "Xác nhận thay đổi": "Änderung bestätigen",
    "Tiếp tục": "Weiter",
    "Giờ Reminder": "Reminder-Zeit",
    "Giờ bắt đầu Alarm": "Alarm-Startzeit",
    "Giờ kết thúc Alarm": "Alarm-Endzeit",
    "Không có nhà nào đủ điều kiện để cài": "Keine geeigneten Zuhause gefunden",
    "Cài đặt hoàn tất": "Einstellung abgeschlossen",
    "Xác nhận rời nhà": "Verlassen des Zuhauses bestätigen",
    "Xác nhận xoá nhà": "Löschen des Zuhauses bestätigen",
    "Nhập mật khẩu": "Passwort eingeben",
    "Mật khẩu tài khoản": "Kontopasswort",
    "Rời khỏi nhà": "Zuhause verlassen",
    "Xoá nhà": "Zuhause löschen",
    "Sai mật khẩu": "Falsches Passwort",
    "Đã rời khỏi home": "Zuhause verlassen",
    "Đã cập nhật": "Aktualisiert",
    "Tìm home...": "Zuhause suchen...",
    "Đặt vị trí nhà và bật bảo vệ tự động": "Zuhause-Standort festlegen und automatischen Schutz aktivieren",
    "Chuyển quyền chủ nhà hoặc xoá nhà": "Besitz des Zuhauses übertragen oder Zuhause löschen",
    "Đặt Reminder / Alarm nhà đã chọn": "Reminder / Alarm für ausgewählte Zuhause festlegen",
    "Chia sẻ nhà đã chọn": "Ausgewählte Zuhause teilen",
    "Mở danh sách chia sẻ nhà": "Liste der Zuhause-Freigaben öffnen",
    "Xoá các nhà đã chọn?": "Ausgewählte Zuhause löschen?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "Ausgewählte Zuhause werden dauerhaft gelöscht.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn": "Oder QR scannen, um den Beitritt zu ausgewählten Zuhause anzufordern",
    "Email người nhận": "E-Mail des Empfängers",
    "Chia sẻ": "Teilen",
    "Email chưa đăng ký": "E-Mail ist nicht registriert",
    "Chia sẻ hoàn tất": "Teilen abgeschlossen",
    "Mở List chia sẻ nhà": "Zuhause-Freigabeliste öffnen",
    "Không có nhà nào bạn có quyền quản lý": "Du verwaltest keine ausgewählten Zuhause",
    "Chưa share cho ai": "Noch mit niemandem geteilt",
    "Tìm nhà": "Zuhause suchen",
    "Xoá các nhà đã chọn ?": "Ausgewählte Zuhause löschen?",
    "Thông báo Home": "Zuhause-Benachrichtigungen",
    "Thông báo nhà": "Zuhause-Benachrichtigungen",
    "Vai trò thành viên đã thay đổi": "Mitgliederrolle geändert",
    "Xoá tất cả thông báo?": "Alle Benachrichtigungen löschen?",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "Alle Zuhause-Benachrichtigungen werden gelöscht.",
    "Chưa có thông báo nào": "Noch keine Benachrichtigungen",
    "Chưa có thông báo": "Keine Benachrichtigungen",
    "Vuốt lên để tải thêm": "Nach oben wischen, um mehr zu laden",
    "Không có thiết bị": "Keine Geräte",
    "Chỉ chủ nhà mới được xoá nhà": "Nur der Besitzer kann dieses Zuhause löschen",
    "Chỉ chủ nhà mới được chuyển quyền": "Nur der Besitzer kann den Besitz übertragen",
    "Lưu ý khi bật Alarm": "Hinweis beim Aktivieren von Alarm",
    "Alarm đã được bật": "Alarm aktiviert",
    "Đã hiểu": "Verstanden",
    "Lưu ý tạm tắt Alarm": "Hinweis zur Alarm-Pause",
    "Đã bật Alarm": "Alarm aktiviert",
    "Đã tắt Alarm": "Alarm deaktiviert",
    "Tắt Alarm": "Alarm ausschalten",
    "Cả ngày": "Ganztägig",
    "Bạn không có quyền thực hiện thao tác này.": "Du hast keine Berechtigung, diese Aktion auszuführen.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.": "Die Aktion konnte nicht abgeschlossen werden. Bitte versuche es erneut.",
    "QR gia nhập nhiều nhà không hợp lệ": "Ungültiger QR-Code für den Beitritt zu mehreren Zuhause",
    "Bạn đang là chủ các nhà này": "Du bist Besitzer dieser Zuhause",
    "Một người dùng": "Ein Benutzer",
    "Yêu cầu gia nhập nhà": "Beitrittsanfrage für Zuhause",
    "Đã gửi yêu cầu gia nhập nhà": "Beitrittsanfrage gesendet",
    "QR gia nhập không hợp lệ": "Ungültiger QR-Code für den Beitritt",
    "Bạn đang là chủ nhà này": "Du bist bereits Besitzer dieses Zuhauses",
    "QR này không phải mã xin gia nhập nhà": "Dieser QR-Code ist kein Beitrittscode für ein Zuhause",
    "Bạn không có quyền thêm thiết bị": "Du hast keine Berechtigung, Geräte hinzuzufügen",
    "Đã mở chế độ thêm thiết bị": "Gerätekopplung aktiviert",
    "Rời khỏi Home này?": "Dieses Zuhause verlassen?",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.": "Dieses Zuhause und alle Geräte darin werden dauerhaft gelöscht.",
    "Đã xoá nhà": "Zuhause gelöscht",
    "QR của nhà này": "QR-Code dieses Zuhauses",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.": "Andere können diesen Code scannen, um Zugang zum Zuhause anzufordern.",
    "Chia sẻ nhà": "Zuhause teilen",
    "Quét QR để xin gia nhập nhà": "QR scannen, um den Beitritt zum Zuhause anzufordern",
    "Quét QR xin gia nhập nhà":
    "QR scannen, um dem Zuhause beizutreten",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "Platziere den geteilten Zuhause-QR-Code im Rahmen",
    "Mã QR này do chủ nhà chia sẻ":
    "Dieser QR-Code wurde vom Hauseigentümer geteilt",
    "Nhập mã mời": "Einladungscode eingeben",
    "Gửi yêu cầu gia nhập": "Beitrittsanfrage senden",
    "QR này không phải mã thiết bị": "Dieser QR-Code ist kein Gerätecode",
    "Xin gia nhập nhà": "Zugang zum Zuhause anfragen",
    "Quét mã QR chia sẻ nhà": "Freigabe-QR-Code scannen",
    "Mời thành viên bằng mã QR": "Mitglied per QR-Code einladen",
    "Không thể share cho chính bạn": "Du kannst nicht mit dir selbst teilen",
    "Lời mời chia sẻ nhà": "Einladung zur Zuhause-Freigabe",
    "Đã share home": "Zuhause geteilt",
    "Chuyển quyền chủ nhà": "Besitz übertragen",
    "Không thể chuyển quyền cho chính bạn": "Du kannst den Besitz nicht an dich selbst übertragen",
    "Không tìm thấy user": "Benutzer nicht gefunden",
    "Không tìm thấy tài khoản": "Konto nicht gefunden",
    "Xác nhận chuyển quyền": "Besitzübertragung bestätigen",
    "Chuyển": "Übertragen",
    "Xác nhận mật khẩu": "Passwort bestätigen",
    "Xác nhận": "Bestätigen",
    "Yêu cầu chuyển quyền chủ nhà": "Anfrage zur Besitzübertragung",
    "Đã gửi yêu cầu chuyển quyền": "Übertragungsanfrage gesendet",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "Anfrage zur Besitzübertragung gesendet",
    "Bạn không có quyền xoá thiết bị": "Du hast keine Berechtigung, Geräte zu löschen",
    "Xóa Device?": "Dieses Gerät löschen?",
    "Đã gửi yêu cầu xoá thiết bị": "Anfrage zum Löschen des Geräte gesendet",
    "Đang xoá thiết bị": "Gerät wird gelöscht",
    "Đăng xuất?": "Abmelden?",
    "Thêm nhà": "Zuhause hinzufügen",
    "Thêm nhà mới": "Neues Zuhause hinzufügen",
    "Tạo nhà mới": "Neues Zuhause erstellen",
    "Tạo một ngôi nhà mới của bạn": "Ein neues Zuhause erstellen",
    "Quét mã QR được chủ nhà chia sẻ": "Vom Besitzer geteilten QR-Code scannen",
    "Tên nhà": "Name des Zuhauses",
    "Số điện thoại": "Telefonnummer",
    "Nam": "Männlich",
    "Nữ": "Weiblich",
    "Ngày": "Tag",
    "Tháng": "Monat",
    "Năm": "Jahr",
    "Thông tin cá nhân": "Persönliche Informationen",
    "Thiết lập tài khoản": "Konto einrichten",
    "Vui lòng nhập đủ thông tin": "Bitte alle erforderlichen Informationen eingeben",
    "Không thể lưu thông tin": "Informationen konnten nicht gespeichert werden",
    "Đã lưu thông tin": "Informationen gespeichert",
    "Lỗi lưu profile": "Profil konnte nicht gespeichert werden",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp": "Telefonnummer für Notfälle hinzufügen",
    "Hoàn tất": "Fertig",
    "Đã tạo nhà mới": "Zuhause erstellt",
    "Về muộn": "Später zurück",
    "Ra ngoài": "Ausgehen",
    "Khác": "Andere",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ Alarm heute pausieren",
    "Chọn giờ bắt đầu tạm tắt": "Startzeit der Pause wählen",
    "Từ": "Von",
    "Từ giờ": "Von",
    "Chọn giờ kết thúc tạm tắt": "Endzeit der Pause wählen",
    "Đến": "Bis",
    "Đến giờ": "Bis",
    "Xoá lịch tạm tắt": "Pausenzeitplan löschen",
    "Xóa lịch tạm tắt": "Pausenzeitplan löschen",
    "Giới tính": "Geschlecht",
    "SĐT": "Telefon",
    "Ngày sinh": "Geburtsdatum",
    "Yêu cầu & lời mời": "Anfragen & Einladungen",
    "Xem lời mời chia sẻ và xin gia nhập": "Freigabe-Einladungen und Beitrittsanfragen anzeigen",
    "Cài đặt bảo mật": "Sicherheitseinstellungen",
    "Quyền báo động toàn màn hình": "Berechtigung für Vollbild-Alarm",
    "Báo động toàn màn hình": "Vollbild-Alarm",
    "Đã được cấp quyền": "Berechtigung erteilt",
    "Chưa được cấp quyền": "Berechtigung nicht erteilt",
    "Mở cài đặt hệ thống": "Systemeinstellungen öffnen",
    "Đăng xuất": "Abmelden",
    "Thoát tài khoản khỏi thiết bị này": "Von diesem Gerät abmelden",
    "Không có yêu cầu hoặc lời mời nào": "Keine Anfragen oder Einladungen",
    "Xoá tài khoản": "Konto löschen",
    "Hành động này sẽ xoá toàn bộ dữ liệu:": "Dadurch werden alle Daten gelöscht:",
    "Nhà và thiết bị": "Zuhause und Geräte",
    "Chia sẻ và quyền truy cập": "Freigabe und Zugriff",
    "Toàn bộ dữ liệu liên quan": "Alle zugehörigen Daten",
    "Mật khẩu xác nhận": "Bestätigungspasswort",
    "Đã xoá tài khoản": "Konto gelöscht",
    "Xoá thất bại": "Löschen fehlgeschlagen",
    "Lỗi xoá tài khoản": "Konto konnte nicht gelöscht werden",
    "Tình trạng": "Zustand",
    "Tháo/Lắp": "Manipulation",
    "Pin": "Batterie",
    "Tín hiệu": "Signalstärke",
    "Chưa liên kết": "Nicht verknüpft",
    "Liên lạc cuối": "Letzter Kontakt",
    "Event cuối": "Letztes Ereignis",
    "Sự kiện cuối": "Letztes Ereignis",
    "Lần kích hoạt cuối": "Zuletzt ausgelöst",
    "Thiết bị không còn tồn tại": "Gerät existiert nicht mehr",
    "Mất kết nối": "Getrennt",
    "Online": "Verbunden",
    "Offline": "Getrennt",
    "Loại thiết bị": "Gerätetyp",
    "Nhiệt độ": "Temperatur",
    "Độ ẩm": "Luftfeuchtigkeit",
    "Công suất": "Leistung",
    "Điện áp": "Spannung",
    "Dòng điện": "Stromstärke",
    "Điện năng": "Energie",
    "Cường độ rung": "Vibrationsstärke",
    "Góc nghiêng": "Neigungswinkel",
    "Độ mở van": "Ventilöffnung",
    "Nguồn dự phòng": "Notstromversorgung",
    "Ngập/rò nước": "Überschwemmung/Leckage",
    "Phát hiện khói": "Rauch erkannt",
    "Quản lý phòng": "Räume verwalten",
    "Bạn không có quyền quản lý phòng": "Du hast keine Berechtigung, Räume zu verwalten",
    "Đổi tên phòng": "Raum umbenennen",
    "Tên phòng": "Raumname",
    "Xoá phòng": "Löschen Raum",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.": "Geräte in diesem Raum werden nach \"Nicht zugeordnet\" verschoben.",
    "Thêm phòng": "Raum hinzufügen",
    "Ví dụ: Phòng khách": "Beispiel: Wohnzimmer",
    "Phòng khách": "Living Raum",
    "Tên phòng đã tồn tại": "Raumname existiert bereits",
    "Chưa phân phòng": "Nicht zugeordnet",
    "Phòng mặc định": "Standardraum",
    "Phát hiện bất thường": "Auffälligkeit erkannt",
    "Phát hiện cạy phá": "Aufbruch erkannt",
    "Tamper detected": "Manipulation erkannt",
    "Tamper cleared": "Manipulationsalarm aufgehoben",
    "Door opened": "Tür geöffnet",
    "Door closed": "Tür geschlossen",
    "Motion detected": "Bewegung erkannt",
    "Battery low": "Niedriger Batteriestand",
    "Device offline": "Gerät offline",
    "Device online": "Gerät online",
    "Alarm triggered": "Alarm ausgelöst",
    "Alarm cleared": "Alarm aufgehoben",
    "Cửa mở": "Tür offen",
    "Cửa đóng": "Tür geschlossen",
    "Chưa đặt vị trí nhà": "Standort des Zuhauses nicht festgelegt",
    "Đặt vị trí nhà tại đây": "Standort des Zuhauses hier festlegen",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ": "Lege den Standort des Zuhauses fest, bevor du den automatischen Schutz aktivierst",
    "Bán kính bảo vệ mặc định: 150 m": "Standard-Schutzradius: 150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.": "Jedes Mitglied muss die Standortberechtigung \"Immer erlauben\" erteilen, damit der Abwesend/Zuhause-Status im Hintergrund funktioniert.",
    "Lưu cài đặt": "Speichern Einstellungen",
    "Đã đặt vị trí nhà": "Standort des Zuhauses festgelegt",
    "Đang lấy vị trí...": "Getting Standort...",
    "Đang lưu...": "Wird gespeichert...",
    "Đổi tên hiển thị": "Anzeigenamen ändern",
    "Cập nhật thông tin nhà": "Informationen zum Zuhause aktualisieren",
    "Nhập địa chỉ của nhà": "Adresse des Zuhauses eingeben",
    "Lưu thay đổi": "Änderungen speichern",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.": "Dieser Name wird nur in deinem Konto angezeigt.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.": "Name und Adresse werden für alle Mitglieder des Zuhauses aktualisiert.",
    "Một thành viên": "Ein Mitglied",
    "Đã cập nhật thông tin nhà": "Informationen zum Zuhause aktualisiert",
    "Thay tên": "Umbenennen",
    "Đã đổi tên thiết bị": "Gerät umbenannt",
    "Chưa chọn nhà để kiểm tra": "Wähle ein Zuhause zum Testen aus",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner": "Führe diesen Test mit dem Besitzerkonto aus",
    "Không đọc được dữ liệu nhà": "Hausdaten konnten nicht gelesen werden",
    "Nhà cần có ít nhất một thiết bị để test": "Das Zuhause benötigt mindestens ein Gerät für den Test",
    "Đóng": "Schließen",
    "Đã thiết lập": "Eingerichtet",
    "Quét QR": "QR scannen",
    "Quét QR để thêm thiết bị": "QR scannen, um ein Gerät hinzuzufügen",
    "Nhập HUB ID thủ công": "HUB ID manuell eingeben",
    "Bạn không có quyền sắp xếp phòng": "Du hast keine Berechtigung, Räume neu zu sortieren",
    "Cảnh báo khói": "Rauchwarnung",
    "Cập nhật thiết bị": "Gerät aktualisieren",
    "Cửa đang mở": "Tür geöffnet",
    "Cửa đã đóng": "Tür geschlossen",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: Fehler gefunden",
    "Firebase Rules: ĐẠT": "Firebase Rules: Bestanden",
    "Giờ không hợp lệ": "Ungültige Zeit",
    "Khôi phục mật khẩu": "Reset Passwort",
    "Nhập email của bạn": "Gib deine E-Mail ein",
    "Gửi": "Senden",
    "Đã gửi email khôi phục": "E-Mail zum Zurücksetzen des Passworts gesendet",
    "Không gửi được email": "E-Mail konnte nicht gesendet werden",
    "Vui lòng nhập email và mật khẩu": "Bitte E-Mail und Passwort eingeben",
    "Mật khẩu xác nhận không khớp": "Passwörter stimmen nicht überein",
    "Không thể tạo tài khoản": "Konto konnte nicht erstellt werden",
    "Sai tài khoản": "Falsches Konto",
    "Email đã tồn tại": "E-Mail existiert bereits",
    "Mật khẩu quá yếu": "Passwort ist zu schwach",
    "Sai email hoặc mật khẩu": "E-Mail oder Passwort ist falsch",
    "Lỗi đăng nhập": "Anmeldefehler",
    "Email": "E-Mail",
    "Mật khẩu": "Passwort",
    "Ghi nhớ tài khoản": "ReMitglied Konto",
    "Đăng nhập": "Anmelden",
    "Đăng ký mới": "Neu registrieren",
    "Quên mật khẩu?": "Passwort vergessen?",
    "Chưa có tài khoản? Đăng ký": "Noch kein Konto? Registrieren",
    "Đã có tài khoản? Đăng nhập": "Schon ein Konto? Anmelden",
    "Tính năng đang được phát triển": "Diese Funktion wird noch entwickelt",
    "Thông báo": "Benachrichtigungen",
    "Chat trong nhà": "Zuhause-Chat",
    "Tìm kiếm tin nhắn": "Nachrichten suchen",
    "Xem thành viên": "View Mitglieder",
    "Tìm nội dung hoặc tên người gửi": "Nach Inhalt oder Absender suchen",
    "Xoá từ khoá": "Suchwort löschen",
    "Không có kết quả": "Keine Ergebnisse",
    "Tìm ngôn ngữ": "Sprache suchen",
    "Kết quả trước": "Vorheriges Ergebnis",
    "Kết quả tiếp theo": "Nächstes Ergebnis",
    "Chưa có tin nhắn": "Noch keine Nachrichten",
    "Không tìm thấy thành viên phù hợp": "Keine passenden Mitglieder gefunden",
    "Nhắc đến trong tin nhắn": "In Nachricht erwähnen",
    "Huỷ trả lời": "Antwort abbrechen",
    "Nhắn gì đó...": "Nachricht eingeben...",
    "Gọi điện": "Anrufen",
    "Alarm thiết bị": "Gerät Alarm",
    "Chế độ áp dụng": "Anwendungsmodus",
    "Theo nhà": "Zuhause Zeitplan",
    "Riêng tôi": "Nur ich",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập": "Gemeinsamen Zeitplan verwenden, der vom Besitzer oder Administrator festgelegt wurde",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn": "Persönlichen Zeitplan verwenden, der nur für dein Konto gilt",
    "Thiết lập nhanh Alarm": "Schnelle Alarm-Einrichtung",
    "Thiết lập nhanh toàn bộ thiết bị": "Alle Geräte schnell einrichten",
    "Áp dụng cho toàn bộ thiết bị": "Auf alle Geräte anwenden",
    "Bắt đầu": "Beginnen",
    "Kết thúc": "Ende",
    "Thời gian lặp lại": "Wiederholen interval",
    "Không lặp lại": "Nicht wiederholen",
    "Quét QR HUB": "HUB QR scannen",
    "Đưa mã QR vào giữa khung": "QR-Code in den Rahmen halten",
    "Đang áp dụng...": "Wird angewendet...",
    "Hôm nay đã ghi nhận cảnh báo SOS": "Heute wurde ein SOS-Alarm erfasst",
    "Hôm nay đã ghi nhận cảnh báo khói": "Heute wurde ein Rauchalarm erfasst",
    "Khói đã an toàn": "Rauch wieder sicher",
    "Không tìm thấy nhà của thông báo này": "Das Zuhause zu dieser Benachrichtigung wurde nicht gefunden",
    "Không tìm thấy thiết bị trong nhà này": "Das Gerät wurde in diesem Zuhause nicht gefunden",
    "Một chủ nhà": "Ein Hauseigentümer",
    "Ngôi nhà đang hoạt động ổn định": "Das Zuhause funktioniert normal",
    "Nhiệt độ cao": "Hohe Temperatur",
    "OK": "OK",
    "Pin yếu": "Niedriger Batteriestand",
    "SOS đã kết thúc": "SOS beendet",
    "SOS được kích hoạt": "SOS aktiviert",
    "Tamper bình thường": "Manipulation normal",
    "Thiết bị bị tháo": "Gerät wurde entfernt",
    "Thiết bị mới": "Neues Gerät",
    "Thiết bị offline": "Gerät offline",
    "Thiết bị online": "Gerät online",
    "Báo động kích hoạt": "Alarm ausgelöst",
    "Báo động đã tắt": "Alarm ausgeschaltet",
    "Tạm tắt Alarm hôm nay": "Alarm heute pausieren",
    "Độ ẩm cao": "Hohe Luftfeuchtigkeit",
    "Thử lại": "Erneut versuchen",
    "Không thể tải dữ liệu tài khoản": "Kontodaten konnten nicht geladen werden",
    "Không": "Nein",
    "Đã chia sẻ nhà thành công.": "Zuhause erfolgreich geteilt.",
    "Tìm nhà...": "Zuhause suchen...",
    "Đã rời khỏi nhà": "Zuhause verlassen",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.": "Du wirst die geteilten Zuhause verlassen.",
    "Các nhà của bạn sẽ bị xoá.\n": "Deine Zuhause werden gelöscht.\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n": "Dadurch werden die Zuhause-Alarm-Zeitpläne aller Sicherheitsgeräte in den ausgewählten Zuhause geändert.\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n": "Dadurch wird den ausgewählten Zuhause ein Zuhause-Reminder hinzugefügt.\n\n",
    "Xác nhận thay đổi Alarm": "Alarm-Änderungen bestätigen",
    "Xác nhận thay đổi Reminder": "Reminder-Änderungen bestätigen",
    "Lặp lại khi sự cố vẫn còn": "Wiederholen, solange das Problem besteht",
    "Thời gian lặp lại Alarm": "Alarm-Wiederholungszeit",
    "VD: Mr Chung": "z. B. Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 Keine Zuhauses yet",
    "Vẫn chuyển về Bình thường": "Trotzdem zum Normalmodus wechseln",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.": "Automatischer Schutz beim Verlassen ist weiterhin aktiviert. Wenn alle Mitglieder noch abwesend sind, kann das System den Schutzmodus nach einigen Minuten wieder aktivieren.",
    "Chuyển về Bình thường?": "Zum Normalmodus wechseln?",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n": "Sicherheitsgeräte werden sofort überwacht.\n\n",
    "Bật Bảo vệ thủ công?": "Manuellen Schutzmodus einschalten?",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ": "Diese Aktion ändert heute die Alarmzeiten einiger Geräte...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ": "Diese Aktion deaktiviert alle Alarme dieses Zuhauses ",
    "Tắt toàn bộ Alarm?": "Alle Alarm ausschalten?",
    "Không xoá được lịch tạm tắt Alarm": "Alarm-Pausenzeitplan konnte nicht gelöscht werden",
    "Không lưu được tạm tắt Alarm": "Alarm-Pause konnte nicht gespeichert werden",
    "Không gửi được yêu cầu xoá": "Löschanfrage konnte nicht gesendet werden",
    "Không lưu được cài đặt": "Einstellung konnte nicht gespeichert werden",
    "Không lấy được vị trí hiện tại": "Aktueller Standort konnte nicht abgerufen werden",
    "Không thể xác nhận tài khoản hiện tại": "Aktuelles Konto konnte nicht bestätigt werden",
    "Mật khẩu không đúng": "Falsches Passwort",
    "Không thể xác nhận mật khẩu": "Passwort konnte nicht bestätigt werden",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động": "Nur der Besitzer oder ein Administrator kann die Alarm-Wiederholung ändern",
    "Không lưu được thời gian lặp báo động": "Alarm-Wiederholungszeit konnte nicht gespeichert werden",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "Nur der Besitzer oder ein Administrator kann den Schutzmodus ändern",
    "Không thể thay đổi chế độ nhà": "Zuhause-Modus konnte nicht geändert werden",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "Schutzmodus ist aktiv, aber Benachrichtigung konnte nicht gesendet werden",
    "Đã bật Mode Bảo vệ thủ công": "Manueller Schutzmodus aktiviert",
    "Đã chuyển nhà về Bình thường": "Zuhause wieder im Normalmodus",
    "60 phút": "60 Minuten",
    "30 phút": "30 Minuten",
    "15 phút": "15 Minuten",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.": "Du siehst den Zeitplan des Besitzers. Wähle \"Nur ich\", um deinen eigenen Alarm-Zeitplan festzulegen.",
    "Chọn giờ kết thúc Alarm": "Alarm-Endzeit wählen",
    "Chọn giờ bắt đầu Alarm": "Alarm-Startzeit wählen",
    "Bạn không có quyền sửa lịch Alarm của nhà": "Du hast keine Berechtigung, den Alarm-Zeitplan dieses Zuhauses zu bearbeiten",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị": "Alarm konnte nicht auf alle Geräte angewendet werden",
    "Nhà chưa có thiết bị an ninh để áp dụng": "Dieses Zuhause hat keine Sicherheitsgeräte zum Anwenden",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.": "Du hast keine Berechtigung, die Zuhause-Einstellungen zu bearbeiten. Wähle \"Nur ich\".",
    "Không thể lưu chế độ Alarm": "Alarm-Modus konnte nicht gespeichert werden",
    "Thêm Reminder": "Reminder hinzufügen",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.": "Reminder erinnert dich zur gewählten Zeit daran, den Sicherheitsstatus deines Zuhauses zu prüfen.",
    "Thêm khung giờ Alarm": "Alarm-Zeitfenster hinzufügen",
    "Đang sử dụng Reminder riêng của bạn": "Deine eigenen Reminder-Einstellungen werden verwendet",
    "Đang sử dụng Reminder của chủ nhà": "Reminder-Einstellungen des Besitzers werden verwendet",
    "Sửa giờ Reminder": "Reminder-Zeit bearbeiten",
    "Sửa giờ kết thúc Alarm": "Alarm-Endzeit bearbeiten",
    "Sửa giờ bắt đầu Alarm": "Alarm-Startzeit bearbeiten",
    "Xoá Reminder": "Reminder löschen",
    "Mỗi 1 giờ": "Jede Stunde",
    "Mỗi 30 phút": "Alle 30 Minuten",
    "Mỗi 15 phút": "Alle 15 Minuten",
    "Không báo lại": "Nicht wiederholen",
    "Báo lại khi vẫn chưa an toàn": "Erneut erinnern, wenn es weiterhin unsicher ist",
    "Báo lại mỗi 1 giờ": "Stündlich wiederholen",
    "Báo lại mỗi 30 phút": "Alle 30 Minuten wiederholen",
    "Báo lại mỗi 15 phút": "Alle 15 Minuten wiederholen",
    "Quản lý nhà": "Zuhause verwalten",
    "Xoá thành viên": "Mitglied entfernen",
    "Đã xoá thành viên": "Mitglied removed",
    "Đồng ý": "OK",
    "Bạn chắc chắn muốn rời khỏi nhà này?": "Möchtest du dieses Zuhause wirklich verlassen?",
    "Xoá thành viên?": "Mitglied entfernen?",
    "Rời khỏi nhà?": "Dieses Zuhause verlassen?",
    "Chỉ chủ nhà mới được thay đổi vai trò": "Nur der Besitzer kann Rollen ändern",
    "Bạn không có quyền xoá thành viên này": "Du hast keine Berechtigung, dieses Mitglied zu entfernen",
    "Bạn": "Du",
    "Không có email": "Keine E-Mail",
    "Chưa có số điện thoại": "Keine Telefonnummer",
    "Không mở được ứng dụng gọi điện": "Telefon-App konnte nicht geöffnet werden",
    "Thành viên chưa cập nhật số điện thoại": "Dieses Mitglied hat keine Telefonnummer hinzugefügt",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "Manueller Schutzmodus ist aktiv - zum Ausschalten in den Normalmodus wechseln",
    "Thời gian lặp": "Wiederholen interval",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "Wähle 0, um nur einmal zu alarmieren. Diese Einstellung gilt für den manuellen Schutzmodus und den automatischen Schutz beim Verlassen.",
    "Lặp báo động khi sự cố vẫn còn": "Alarm wiederholen, solange das Problem besteht",
    "Đang được sử dụng": "Derzeit aktiv",
    "Chuyển về sử dụng thông thường": "Zur normalen Nutzung zurückkehren",
    "Chế độ nhà": "Zuhause-Modus",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "Das SOS-Gerät hat keinen Alarm erfasst.",
    "Cảm biến khói chưa ghi nhận bất thường.": "Der Rauchmelder hat keine Auffälligkeit erkannt.",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.": "Du oder ein Mitglied hat den Schutzmodus manuell aktiviert.",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.": "SafeHome hat den Schutzmodus automatisch aktiviert, weil du gegangen bist.",
    "Nhà đang ở chế độ dùng bình thường.": "Zuhause ist im Normalmodus.",
    "Bảo vệ thủ công đang bật": "Manueller Schutzmodus ist aktiv",
    "Bảo vệ tự động đang bật": "Automatischer Schutzmodus ist aktiv",
    "Bảo vệ đang tắt": "Schutzmodus ist aus",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.": "Du hast die App kürzlich geöffnet, um den Status zu prüfen.",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.": "Öffne die App regelmäßig, um Berechtigungen, Zeitpläne und ungelesene Warnungen zu prüfen.",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.": "Nach einigen Sitzungen kann SafeHome deine Gewohnheit zur App-Prüfung besser bewerten.",
    "Tần suất vào app ổn": "App-Prüfhäufigkeit sieht gut aus",
    "Đã lâu chưa vào app kiểm tra": "Letzte App-Prüfung ist lange her",
    "Đang ghi nhận tần suất vào app": "App-Prüfhäufigkeit wird erfasst",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.": "Prüfe die Standortberechtigung \"Immer erlauben\" und die Hintergrundbedingungen.",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.": "Dieses Gerät erfüllt die Voraussetzungen für die automatische Abwesenheit.",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.": "Aktiviere dies, wenn der Schutzmodus beim Verlassen automatisch starten soll.",
    "Auto rời khỏi nhà chưa ổn": "Automatischer Schutz beim Verlassen ist noch nicht stabil",
    "Auto rời khỏi nhà đã sẵn sàng": "Automatischer Schutz beim Verlassen ist bereit",
    "Auto rời khỏi nhà chưa bật": "Automatischer Schutz beim Verlassen ist aus",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.": "Füge einen Rauchmelder, SOS oder ein passendes Notfallgerät für dein Zuhause hinzu.",
    "Chưa có thiết bị khẩn cấp": "Kein Notfallgerät vorhanden",
    "Đã có thiết bị khẩn cấp": "Notfallgerät vorhanden",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.": "Lege Alarm für Schlafenszeiten oder Abwesenheit fest.",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.": "Dieses Zuhause hat einen Alarm-Zeitplan oder einen gerätespezifischen Warnzeitplan.",
    "Chưa set lịch Alarm": "Alarm-Zeitplan nicht eingerichtet",
    "Đã set lịch Alarm": "Alarm-Zeitplan eingerichtet",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.": "Lege mindestens einen Reminder fest, damit du die Prüfung deines Zuhauses nicht vergisst.",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.": "Die App erinnert dich nach dem festgelegten Zeitplan daran, dein Zuhause zu prüfen.",
    "Chưa setup Reminder": "Reminder nicht eingerichtet",
    "Đã setup Reminder": "Reminder eingerichtet",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.": "Öffne die App erneut oder melde dich erneut an, wenn dieses Gerät keine Warnungen empfängt.",
    "Thiết bị chưa đăng ký nhận cảnh báo": "Gerät ist nicht für Warnungen registriert",
    "Thiết bị nhận cảnh báo bình thường": "Gerät empfängt Warnungen normal",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.": "iOS verwaltet Hintergrundaktivitäten strenger als Android. Lasse Benachrichtigungen und \"Immer erlauben\" für den Standort aktiviert, wenn du automatische Abwesenheit nutzt.",
    "Cơ chế iOS": "iOS-Verhalten",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.": "Prüfe Hintergrundberechtigung und Autostart, damit Warnungen nicht verzögert werden.",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.": "Das Gerät hat die wichtigen Hintergrundbedingungen bestätigt.",
    "Cần kiểm tra chạy nền / tự khởi động": "Hintergrundbetrieb / Autostart prüfen",
    "Chạy nền ổn định": "Stabiler Hintergrundbetrieb",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "Einige Android-Telefone können Warnungen verzögern, wenn die Akkuoptimierung aktiviert ist.",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.": "Dieses Telefon wird SafeHome-Warnungen wahrscheinlich nicht verzögern.",
    "Chưa tắt tối ưu pin": "Akkuoptimierung ist noch aktiv",
    "Tối ưu pin không chặn app": "Akkuoptimierung blockiert die App nicht",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.": "Automatische Abwesenheit benötigt den Standort mit \"Immer erlauben\", um zuverlässig zu funktionieren.",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.": "Standortberechtigung ist erforderlich, damit Automatischer Schutz beim Verlassen funktioniert.",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.": "Der Standortdienst ist deaktiviert, daher funktioniert automatische Abwesenheit möglicherweise nicht zuverlässig.",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.": "Diese Berechtigung wird nur für Automatischer Schutz beim Verlassen benötigt.",
    "Chưa cấp vị trí luôn luôn": "Standort immer noch nicht erlaubt",
    "Đã cấp vị trí luôn luôn": "Standort immer erlaubt",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.": "iOS öffnet keine Vollbildwarnung wie Android. Die App verwendet Systembenachrichtigungen und Ton.",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.": "Android verwendet Vollbildwarnungen. Erlaube sie in den Einstellungen, falls das Telefon sie blockiert.",
    "Cảnh báo trên iOS": "iOS-Warnung",
    "Cảnh báo toàn màn hình": "Vollbildwarnung",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "Warnungen erscheinen möglicherweise nicht, wenn Benachrichtigungen deaktiviert sind.",
    "Điện thoại có thể nhận thông báo SafeHome.": "Das Telefon kann SafeHome-Benachrichtigungen empfangen.",
    "Chưa bật thông báo": "Benachrichtigungen nicht aktiviert",
    "Đã bật thông báo": "Benachrichtigungen aktiviert",
    "Hệ thống: Sẵn sàng": "System: Bereit",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "System: Warnungen könnten verpasst werden",
    "Cách bạn đang dùng app": "Deine App-Nutzung",
    "Thiết bị của bạn": "Dein Gerät",
    "Kiểm tra điện thoại và cách bạn đang dùng app.": "Prüfe dein Telefon und deine App-Nutzung.",
    "Hệ thống SafeHome": "SafeHome-System",
    "Hệ thống: Đang kiểm tra...": "System: Prüfung läuft...",
    "Tên": "Bezeichnung",
    "Bạn không có quyền thay đổi vị trí nhà": "Du hast keine Berechtigung, den Standort des Zuhauses zu ändern",
    "Hãy bật GPS để đặt vị trí nhà": "Aktiviere GPS, um den Standort des Zuhauses festzulegen",
    "Bạn chưa cấp quyền vị trí": "Standortberechtigung wurde nicht erteilt",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng": "Erteile die Standortberechtigung in den App-Einstellungen",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà": "Automatischer Schutz beim Verlassen wurde aktiviert",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà": "Automatischer Schutz beim Verlassen wurde deaktiviert",
    "Không thể thay đổi trạng thái Alarm": "Alarm-Status konnte nicht geändert werden",
    "Đã tắt toàn bộ Alarm của nhà": "Alle Alarme dieses Zuhauses wurden ausgeschaltet",
    "QR này không phải mã xin gia nhập Home": "Dieser QR-Code ist kein Beitrittscode für ein Zuhause",
    "Thêm Home": "Hinzufügen Zuhause",
    "Mở cài đặt": "Öffnen Einstellungen",
    "Để sau": "Später",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.": "SafeHome benötigt die Standortberechtigung \"Immer erlauben\", um zu erkennen, wenn du dein Zuhause verlässt oder zurückkehrst, auch wenn die App im Hintergrund läuft.",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.": "SafeHome kann derzeit nur auf den Standort zugreifen, während du die App verwendest.\n\nÖffne die Standortberechtigung und wähle \"Immer erlauben\", damit der automatische Schutz beim Verlassen im Hintergrund funktioniert.",
    "Cho phép vị trí luôn luôn": "Standort immer erlauben",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.": "Deine Zuhause werden gelöscht.\nDu wirst die geteilten Zuhause verlassen.",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "Dadurch werden die Zuhause-Alarm-Zeitpläne aller Sicherheitsgeräte in den ausgewählten Zuhause geändert.\n\nMitglieder, die Alarm-Einstellungen \"Nach Zuhause\" verwenden, sind betroffen.\nPersönliche Alarm-Einstellungen im Modus \"Nur ich\" werden nicht geändert.",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "Dadurch wird den ausgewählten Zuhause ein Zuhause-Reminder hinzugefügt.\n\nMitglieder, die Reminder-Einstellungen \"Nach Zuhause\" verwenden, sind betroffen.\nPersönliche Reminder-Einstellungen im Modus \"Nur ich\" werden nicht geändert.",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "Sicherheitsgeräte werden sofort überwacht.\n\nAutomatischer Schutz beim Verlassen wird pausiert. Dieser Modus schaltet sich nicht automatisch aus, wenn jemand nach Hause kommt, und kann nur von einem berechtigten Mitglied aktiv in den Normalmodus zurückgeschaltet werden.",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...": "Diese Aktion ändert heute die Alarmzeiten einiger Geräte...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.": "Diese Aktion deaktiviert alle Alarme für dieses Zuhause. Du erhältst bei Gefahr keine Warnungen mehr auf diesem Telefon.",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.": "Alarm verwendet die Zuhause-Einstellungen.\n\nDu erhältst Warnungen nach dem gemeinsamen Alarm-Zeitplan, der vom Besitzer oder Administrator festgelegt wurde.",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.": "Alarm verwendet die persönlichen Einstellungen.\n\nDu erhältst Warnungen nach dem persönlichen Alarm-Zeitplan für dieses Konto.",
    "Không thể đăng nhập bằng Google": "Anmeldung mit Google nicht möglich",
    "Không đặt được mật khẩu": "Passwort konnte nicht festgelegt werden",
    "Chấp nhận": "Annehmen",
    "Cho phép": "Erlauben",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.": "Einladung konnte nicht angenommen werden. Bitte versuche es erneut.",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.": "Beitrittsanfrage konnte nicht angenommen werden. Bitte versuche es erneut.",
    "Từ chối": "Ablehnen",
    "Lời mời từ chủ nhà": "Einladung vom Besitzer",
    "Nhận quyền chủ nhà": "Hauseigentümerschaft übernehmen",
    "Một người dùng SafeHome": "SafeHome-Nutzer",
    "Lời mời gia nhập": "Beitrittseinladung",
    "Lời xin vào nhà": "Beitrittsanfrage für Zuhause",
    "Nhập HUB ID": "HUB ID eingeben",
    "VD: HUB_001": "Beispiel: HUB_001",
    "Pair": "Koppeln",
    "Mật khẩu tối thiểu 6 ký tự": "Passwort muss mindestens 6 Zeichen lang sein",
    "Mật khẩu nhập lại không khớp": "Passwörter stimmen nicht überein",
    "Tạo mật khẩu": "Passwort erstellen",
    "Mật khẩu mới": "Neues Passwort",
    "Nhập lại mật khẩu": "Passwort erneut eingeben",
    "Xác nhận tắt cảnh báo": "Ausschalten der Warnung bestätigen",
    "HỦY": "Abbrechen",
    "XÁC NHẬN": "Bestätigen",
    "CẦN KIỂM TRA": "Prüfung erforderlich",
    "KIỂM TRA NHÀ": "ZUHAUSE PRÜFEN",
    "ĐÓNG NHẮC NHỞ": "REMINDER SCHLIESSEN",
    "SafeHome Security Alert": "SafeHome-Sicherheitswarnung",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "Wähle in den App-Einstellungen die Standortberechtigung \"Immer erlauben\"",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.": "Für ein Google-Konto muss ein zusätzliches Passwort erstellt werden, um Sicherheitsfunktionen zu nutzen.",
    "Alarm": "Alarm",
    "Bạn không có quyền thực hiện thao tác này。": "Du hast keine Berechtigung für diese Aktion.",
    "Cài đặt": "Einstellungen",
    "Cập nhật": "Aktualisieren",
    "Chọn ngôn ngữ": "Sprache auswählen",
    "Chưa có dữ liệu thiết bị để đánh giá": "Keine Gerätedaten zur Bewertung vorhanden",
    "Chuyển quyền sở hữu cho thành viên khác": "Besitz an ein anderes Mitglied übertragen",
    "Có": "Ja",
    "Cửa đã đóng an toàn": "Tür sicher geschlossen",
    "Đã xảy ra lỗi. Vui lòng thử lại.": "Ein Fehler ist aufgetreten. Bitte versuche es erneut.",
    "Đang kiểm tra kết nối Hub": "Hub-Verbindung wird geprüft",
    "Đang mở khi nhà ở chế độ Bảo vệ": "Offen, während Zuhause im Schutzmodus ist",
    "Đang mở trong giờ Alarm": "Offen während der Alarm-Zeit",
    "Đang tải...": "Wird geladen...",
    "Hồ sơ, yêu cầu và lời mời tham gia": "Profil, Anfragen und Einladungen",
    "Hub chưa gửi trạng thái": "Hub-Status nicht verfügbar",
    "Hub mất kết nối": "Hub getrennt",
    "Hub tín hiệu bình thường": "Hub verbunden",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ": "Entriegelt, während Zuhause im Schutzmodus ist",
    "Khóa đang mở trong giờ Alarm": "Entriegelt während der Alarm-Zeit",
    "Không có thông báo": "Keine Benachrichtigungen",
    "Khu vực nguy hiểm": "Gefahrenbereich",
    "Kiểm tra thiết bị trong nhà này": "Geräte in diesem Zuhause prüfen",
    "Mất điện lưới": "Netzstrom ausgefallen",
    "Mời người khác tham gia nhà này": "Jemanden einladen, diesem Zuhause beizutreten",
    "Môi trường hiện tại": "Aktuelle Umgebung",
    "MQTT mất kết nối": "MQTT getrennt",
    "Ngôn ngữ": "Sprache",
    "Nhà đã chia sẻ": "Geteiltes Zuhause",
    "Nhà đang hoạt động bình thường": "Zuhause funktioniert normal",
    "Nhập email": "E-Mail eingeben",
    "Phòng": "Raum",
    "Quản trị viên": "Verwalter",
    "Reminder": "Reminder",
    "SafeHome": "SafeHome",
    "Sóng yếu": "Schwaches Signal",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "Konto & System",
    "Tài khoản cá nhân": "Persönliches Konto",
    "Tạo tài khoản": "Konto erstellen",
    "Thành viên": "Mitglieder",
    "Thành viên trong nhà": "Mitglieder im Zuhause",
    "Thay đổi ngôn ngữ hiển thị": "Anzeigesprache ändern",
    "Thêm, đổi tên và sắp xếp phòng": "Räume hinzufügen, umbenennen und neu anordnen",
    "Thiết bị đang được giám sát": "Gerät wird überwacht",
    "Tiếng Anh": "Englisch",
    "Tiếng Hàn": "Koreanisch",
    "Tiếng Nhật": "Japanisch",
    "Tiếng Trung": "Chinesisch",
    "Tiếng Việt": "Vietnamesisch",
    "Toàn bộ thiết bị": "Alle Geräte",
    "Vai trò": "Rolle",
    "Về nhà": "Nach Hause",
    "Xem và quản lý quyền thành viên": "Mitgliederrollen anzeigen und verwalten",
    "Xóa": "Löschen",
    "Xóa nhà": "Zuhause löschen",
    "Xoá toàn bộ dữ liệu và thiết bị": "Alle Zuhause-Daten und Geräte löschen",
    "TẮT CẢNH BÁO": "ALARM STOPPEN",
    "Đã tạo nhà": "Zuhause erstellt",

    "Mode Bảo vệ thủ công đã bật": "Manueller Schutzmodus aktiviert",
    "Báo động không lặp lại.": "Der Alarm wird nicht wiederholt.",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.": "Der Alarm wiederholt sich nach \$securityModeRepeatMinutes Minuten, wenn das Problem weiter besteht.",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage": "\$actorName hat den manuellen Schutzmodus für \"\$homeName\" aktiviert. Dieser Modus wird nur deaktiviert, wenn ein berechtigtes Mitglied zurück auf Normal wechselt. \$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".": "Du hast Alarm für \"\$homeName\" aktiviert.",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".": "Du hast alle Alarme für \"\$homeName\" deaktiviert.",
    "Thành viên mới": "Neues Mitglied",
    "Thành viên rời nhà": "Mitglied hat das Zuhause verlassen",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".": "\$displayMemberName hat \"\$homeName\" verlassen.",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".": "\$actorName hat die Rolle von \$memberName in \"\$homeName\" von \$oldRoleName zu \$newRoleName geändert.",
    "Còn \$count tin nhắn chưa đọc": "\$count ungelesene Nachrichten",
    "Hãy an tâm nghỉ ngơi.": "Du kannst beruhigt sein.",
    "Có thiết bị chưa an toàn.": "Einige Geräte sind nicht sicher.",
    "SafeHome đang cập nhật vị trí": "SafeHome aktualisiert den Standort",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.": "Überwachung läuft, um den Schutzmodus automatisch zu aktivieren.",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.": "Nutzt den Standort, um den Schutzmodus automatisch zu aktivieren, wenn alle das Haus verlassen.",
    "CẢNH BÁO SOS": "SOS-ALARM",
    "CẢNH BÁO KHÓI / CHÁY": "RAUCH-/FEUERALARM",
    "CẢNH BÁO NGẬP NƯỚC": "ÜBERSCHWEMMUNGSALARM",
    "CẢNH BÁO RÒ KHÍ": "GASLECK-ALARM",
    "CẢNH BÁO CỬA": "TÜR-ALARM",
    "CẢNH BÁO AN NINH": "SICHERHEITSALARM",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.": "Bestätigung bei SafeHome nicht möglich. Prüfe deine Verbindung und versuche es erneut.",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?": "Stoppe den Alarm erst, nachdem du den Zustand im Zuhause geprüft hast.\n\nMöchtest du den Alarm wirklich stoppen?",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome hat einen Alarm erkannt",
    "Mở SafeHome để kiểm tra ngay.": "Öffne SafeHome, um sofort zu prüfen.",
    "\$count tin nhắn mới": "\$count neue Nachrichten",
    "Tin nhắn HomeChat": "HomeChat-Nachricht",
    "\$senderName đã gửi một tin nhắn": "\$senderName hat eine Nachricht gesendet",
    "Bạn có tin nhắn mới": "Du hast eine neue Nachricht",
    "Mode Bảo vệ sẽ chỉ báo động một lần": "Der Schutzmodus alarmiert nur einmal",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút": "Der Schutzmodus wiederholt den Alarm nach \$minutes Minuten",
    "Đã gửi yêu cầu gia nhập \$count nhà": "Beitrittsanfragen für \$count Zuhause gesendet",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".": "\$requesterName möchte \"\$homeName\" beitreten.",
    "Bạn đã xoá nhà \"\$homeName\".": "Du hast \"\$homeName\" gelöscht.",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.": "Du hast eine Anfrage zur Eigentumsübertragung für \"\$homeName\" an \$email gesendet.",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.": "\$actorName möchte dir das Eigentum an \"\$homeName\" übertragen.",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".": "\$actorName hat dich eingeladen, \"\$homeName\" beizutreten.",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".": "SafeHome entfernt \"\$deviceName\" aus \"\$homeName\".",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".": "Gerät \"\$deviceName\" wurde zu \"\$homeName\" hinzugefügt.",
    "Bạn đã tạo nhà \"\$name\".": "Du hast das Zuhause \"\$name\" erstellt.",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.": "\$actorName hat den Namen des Zuhauses zu \"\$newName\" geändert und die Adresse aktualisiert.",
    "\$actorName đã đổi tên nhà thành \"\$newName\".": "\$actorName hat das Zuhause in \"\$newName\" umbenannt.",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".": "\$actorName hat die Adresse von \"\$newName\" aktualisiert.",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".": "\$actorName hat Gerät \"\$oldDeviceName\" in \"\$homeName\" in \"\$newName\" umbenannt.",
    "Đang ghép nối: \$seconds giây": "Kopplung: \$seconds s",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.": "Die Gerätekopplung wurde in \"\$homeName\" für \$seconds Sekunden aktiviert.",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)": "Der Pausenzeitraum muss im Alarm-Zeitplan liegen (\$start → \$end)",
    "\$passCount/\$total bài test đạt\n\n": "\$passCount/\$total Tests bestanden\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.": "\$name hat keine Telefonnummer im Profil hinterlegt.",
    "Tin nhắn mới trong \$homeName": "Neue Nachricht in \$homeName",
    "\$current/\$total kết quả": "\$current/\$total Ergebnisse",
    "Đang trả lời \$name": "Antwort an \$name",
    "\"\$name\" phát hiện khói trong \"\$homeName\".": "\"\$name\" hat Rauch in \"\$homeName\" erkannt.",
    "\"\$name\" đã trở lại trạng thái bình thường.": "\"\$name\" ist wieder im Normalzustand.",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".": "\"\$name\" hat SOS in \"\$homeName\" ausgelöst.",
    "\"\$name\" đã hết trạng thái SOS.": "\"\$name\" ist nicht mehr im SOS-Zustand.",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".": "\"\$name\" meldet Manipulation in \"\$homeName\".",
    "\"\$name\" đã hết cảnh báo tháo/cạy.": "\"\$name\"-Sabotagealarm wurde beendet.",
    "\"\$name\" đã đóng trong \"\$homeName\".": "\"\$name\" ist in \"\$homeName\" geschlossen.",
    "\"\$name\" đang mở trong \"\$homeName\".": "\"\$name\" ist in \"\$homeName\" geöffnet.",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.": "\"\$name\" in \"\$homeName\" hat einen niedrigen Batteriestand.",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.": "\"\$name\" in \"\$homeName\" ist offline gegangen.",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.": "\"\$name\" in \"\$homeName\" ist wieder online.",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".": "\"\$name\" hat in \"\$homeName\" eine hohe Temperatur gemessen.",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".": "\"\$name\" hat in \"\$homeName\" hohe Luftfeuchtigkeit gemessen.",
    "Có nút SOS vừa được kích hoạt": "Eine SOS-Taste wurde ausgelöst",
    "Có dấu hiệu khói hoặc cháy": "Rauch oder Feuer wurde erkannt",
    "Có dấu hiệu ngập nước": "Wasserüberschwemmung wurde erkannt",
    "Có dấu hiệu rò khí": "Gasleck erkannt",
    "Có cửa đang mở hoặc thiết bị bị tháo": "Eine Tür ist offen oder ein Gerät wurde manipuliert",
    "Có thiết bị đang cảnh báo": "Ein Gerät meldet Alarm",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.": "Wenn niemand bestätigt, wechselt SafeHome zu einem Notruf.",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.": "Erneut um \$time erinnern, wenn das Problem noch nicht behoben ist.",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.": "Alarmiert erneut nach dem eingerichteten Alarm-Zeitplan, wenn das Problem nicht behoben wurde.",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".": "\"\$deviceName\" ist in \"\$resolvedHomeName\" geschlossen.",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".": "\"\$deviceName\" ist in \"\$resolvedHomeName\" geöffnet.",
    "\$count nhà đã chọn": "\$count Zuhause ausgewählt",
    "🚨 \$count nhà không an toàn\$suffix": "🚨 \$count Zuhause unsicher\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix": "⚠️ \$count Häuser benötigen Aufmerksamkeit\$suffix",
    "✅ \$count nhà an toàn": "✅ \$count Zuhause sicher",
    "\$count nhà đang được theo dõi": "\$count Häuser werden überwacht",
    "\$minutes phút": "\$minutes Minuten",
    "Đã cài Reminder cho \$updatedHomes nhà.": "Reminder wurde für \$updatedHomes Zuhause eingerichtet.",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n": "Alarm wurde für \$updatedDevices Geräte in \$updatedHomes Zuhause eingerichtet.\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.": "Die Zuhause, für die du berechtigt bist, wurden geteilt.\n\n\$skipped Zuhause wurden übersprungen, weil du keine Berechtigung zum Teilen hast.",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh": "Alarm auf \$count Sicherheitsgeräte angewendet",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh": "Denselben Zeitplan auf \$count Sicherheitsgeräte anwenden",
    "\$count phút trước": "vor \$count Minuten",
    "\$count giờ trước": "vor \$count Stunden",
    "\${count}h trước": "vor \${count} Std.",
    "\${hours}h\$minutes' trước": "vor \${hours} Std. \${minutes} Min.",
    "\$count ngày trước": "vor \$count Tagen",
    "\$count tháng trước": "vor \$count Monaten",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?": "Möchtest du \$name wirklich aus diesem Zuhause entfernen?",
    "\$targetEmail\nXin gia nhập \"\$homeName\"": "\$targetEmail\nMöchte \"\$homeName\" beitreten",
    "Xin gia nhập \"\$homeName\"": "Möchte \"\$homeName\" beitreten",
    "Bạn được mời nhận quyền nhà \"\$homeName\"": "Du wurdest eingeladen, das Eigentum an \"\$homeName\" zu übernehmen",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"": "\$ownerEmail\nLädt dich ein, \"\$homeName\" beizutreten",
    "Mời bạn gia nhập \"\$homeName\"": "Lädt dich ein, \"\$homeName\" beizutreten",
    "Cần kiểm tra: \$joined": "Zu prüfen: \$joined",
    "Cập nhật \$value": "Aktualisiert: \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.": "Füge dein erstes SafeHome-Gerät hinzu, um dieses Zuhause zu überwachen.",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.": "Prüfe zuerst Notfallwarnungen und kontaktiere danach bei Bedarf Haushaltsmitglieder.",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "Niemand ist zu Hause, aber eine Tür oder ein Schloss ist offen. Prüfe es jetzt.",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "Prüfe die offene Tür oder das offene Schloss, bevor dieses Zuhause im Schutzmodus bleibt.",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.": "Es könnte noch jemand zuhause sein. Falls ja, wechsle zurück in den Normalmodus.",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.": "Bei einigen Mitgliedern ist der Standort unbekannt. Bitte sie, die App zu öffnen oder die Standortberechtigung zu prüfen.",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "Ein Gerät ist getrennt. Prüfe Batterie, Stromversorgung oder Standort.",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.": "Ein Gerät hat einen niedrigen Batteriestand. Tausche die Batterie bald aus, um keine Alarme zu verpassen.",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.": "Reminder ist nicht eingerichtet. Erstelle einen Zeitplan, um dein Zuhause regelmäßig zu prüfen.",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.": "Der Alarm-Zeitplan ist nicht eingerichtet. Aktiviere den Schutz für Zeiten, in denen du normalerweise abwesend bist.",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.": "Es ist keine sofortige Maßnahme erforderlich. Überwache dieses Zuhause weiter.",
    "Lặp sau \$minutes phút": "Wiederholen nach \$minutes Minuten",
    "Đang dùng • \$repeatText": "Aktiv • \$repeatText",
    "Giám sát an ninh • \$repeatText": "Sicherheitsüberwachung • \$repeatText",
    "Gia đình: \$mode": "Zuhause-Modus: \$mode",
    "Gợi ý xử lý": "Empfohlene Maßnahmen",
    "Phát hiện \$count vấn đề cần xử lý": "\$count Probleme erkannt, die bearbeitet werden müssen",
    "Hôm nay các cửa đã được sử dụng \$count lần": "Türen wurden heute \$count-mal benutzt",
    "Đã ghi nhận \$count hoạt động gần đây": "\$count aktuelle Aktivitäten aufgezeichnet",
    "Hệ thống: Cần kiểm tra \$issueCount mục": "System: \$issueCount Elemente müssen geprüft werden",
    "FCM token đã sẵn sàng trên điện thoại này.": "Der FCM-Token ist auf diesem Telefon bereit.",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.": "Der FCM-Token ist bereit, aber für Auto Away fehlt noch eine Voraussetzung.",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.": "\$emergencyTotal Notfallgeräte gefunden. Empfohlenes Minimum: Rauchmelder und SOS.",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?": "Eigentum am Zuhause übertragen an:\n\$targetEmail?",
    "\$count cửa đã đóng an toàn": "\$count Türen sicher geschlossen",
    "\$count cửa và khóa đã an toàn": "\$count Türen und Schlösser gesichert",
    "\$count thiết bị đang được theo dõi": "\$count Geräte werden überwacht",
    "Cập nhật \$timeText": "Aktualisiert: \$timeText",
    "Dữ liệu gần nhất cập nhật \$count phút trước": "Neueste Daten vor \$count Minuten aktualisiert",
    "Dữ liệu gần nhất cập nhật \$count giờ trước": "Neueste Daten vor \$count Stunden aktualisiert",
    "Thành viên trong nhà: \$count": "Mitglieder zu Hause: \$count",
    "Thành viên bên ngoài: \$count": "Mitglieder außerhalb: \$count",
    "Chưa xác định vị trí: \$count": "Standort unbekannt: \$count",
    "Môi trường hiện tại: \$environment": "Aktuelle Umgebung: \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ": "\$name: Offen, während das Zuhause im Schutzmodus ist",
    "An tâm hơn trong từng ngôi nhà": "Mehr Ruhe in jedem Zuhause",
    "Báo động SafeHome": "SafeHome-Alarm",
    "Có cảnh báo an ninh cần kiểm tra ngay.": "Ein Sicherheitsalarm erfordert deine Aufmerksamkeit.",
    "Có cảnh báo cần kiểm tra": "Ein Alarm erfordert deine Aufmerksamkeit",
    "Tự đóng sau \$time": "Schließt automatisch in \$time",
  };

  static const Map<String, String> _russian = {
    "Không tìm thấy người dùng": "Пользователь не найден",
    "Không đọc được số điện thoại": "Не удалось прочитать номер телефона",
    "Tin nhắn quá dài": "Сообщение слишком длинное",
    "Không gửi được tin nhắn": "Не удалось отправить сообщение",
    "Bạn không có quyền sửa lịch chung của nhà": "У вас нет разрешения редактировать общее расписание дома",
    "Nhà của bạn": "Ваш дом",
    "Tải tin cũ hơn": "Загрузить более старые сообщения",
    "Nhà chưa đặt tên": "Дом без названия",
    "Nhà": "Дом",
    "Chưa có thông tin": "Нет информации",
    "Chưa cập nhật": "Не обновлено",
    "Chủ nhà": "Владелец",
    "Nhà được chia sẻ": "Общий дом",
    "Địa chỉ": "Адрес",
    "An ninh ra/vào": "Безопасность входа/выхода",
    "Nguy hiểm khẩn cấp": "Экстренные угрозы",
    "Điều khiển & hạ tầng": "Управление и инфраструктура",
    "Môi trường": "Окружающая среда",
    "Toàn bộ thiết bị SafeHome": "Все устройства SafeHome",
    "Cửa ra/vào": "Входная дверь",
    "Cửa": "Дверь",
    "Cửa sổ": "Окно",
    "Cổng": "Ворота",
    "Khóa thông minh": "Умный замок",
    "Chuyển động": "Движение",
    "Hiện diện": "Присутствие",
    "Rung/chấn động": "Вибрация/удар",
    "Kính vỡ": "Разбитие стекла",
    "Báo khói": "Датчик дыма",
    "Báo nhiệt": "Датчик тепла",
    "Khí CO": "Датчик CO",
    "Báo gas": "Датчик газа",
    "Báo ngập/rò nước": "Датчик затопления/протечки",
    "Nút SOS": "Кнопка SOS",
    "Nhiệt độ/Độ ẩm": "Температура/влажность",
    "Bụi mịn PM2.5": "PM2.5",
    "CO₂": "Датчик CO₂",
    "Chất lượng không khí": "Качество воздуха",
    "Ổ điện thông minh": "Умная розетка",
    "Còi báo động": "Сирена",
    "Van thông minh": "Умный клапан",
    "Camera": "Камера",
    "Chuông cửa": "Дверной звонок",
    "Bàn phím an ninh": "Охранная клавиатура",
    "Bộ mở rộng sóng": "Ретранслятор сигнала",
    "Hub trung tâm": "Центральный Hub",
    "Đo điện năng": "Измерение электроэнергии",
    "Nguồn dự phòng UPS": "Резервное питание UPS",
    "Thiết bị đang Offline": "Устройство офлайн",
    "Thiết bị đang Online": "Устройство онлайн",
    "pin yếu": "низкий заряд батареи",
    "sóng yếu": "слабый сигнал",
    "lâu không phản hồi": "долго не отвечает",
    "Kết nối cần kiểm tra": "Подключение требует проверки",
    "Vừa xong": "Только что",
    "Bị tháo": "Обнаружено снятие",
    "Có khói": "Обнаружен дым",
    "Bình thường": "Обычный режим",
    "Bảo vệ": "Режим охраны",
    "Chế độ Bảo vệ": "Режим охраны",
    "Tự động Bảo vệ khi rời nhà": "Автоматическая охрана при уходе",
    "Đã kích hoạt": "Активировано",
    "Sẵn sàng": "Готово",
    "Đang đóng": "Закрыто",
    "Đang mở": "Открыто",
    "Rò rỉ gas": "Обнаружена утечка газа",
    "Phát hiện ngập nước": "Обнаружено затопление",
    "Phát hiện chuyển động": "Обнаружено движение",
    "Không có chuyển động": "Движение не обнаружено",
    "Phát hiện hiện diện": "Обнаружено присутствие",
    "Không phát hiện hiện diện": "Присутствие не обнаружено",
    "Phát hiện rung/chấn động": "Обнаружена вибрация/удар",
    "Không có rung bất thường": "Аномальная вибрация не обнаружена",
    "Phát hiện kính vỡ": "Обнаружено разбитие стекла",
    "Không có cảnh báo kính vỡ": "Нет тревоги разбития стекла",
    "Nhiệt độ nguy hiểm": "Опасная температура",
    "Phát hiện khí CO": "Обнаружен CO",
    "Không phát hiện khí CO": "CO не обнаружен",
    "Khóa đang mở": "Замок открыт",
    "Khóa đang đóng": "Замок закрыт",
    "Đang bật": "Включено",
    "Đang tắt": "Выключено",
    "Đang theo dõi điện năng": "Мониторинг электроэнергии",
    "Đang dùng nguồn dự phòng": "Работает от резервного питания",
    "Nguồn điện bình thường": "Питание в норме",
    "Còi đang bật": "Сирена активна",
    "Còi sẵn sàng": "Сирена готова",
    "Van đang mở": "Клапан открыт",
    "Van đã đóng": "Клапан закрыт",
    "Đang hoạt động": "Работает",
    "Đang theo dõi": "Под наблюдением",
    "Chưa nhận diện": "Устройство не распознано",
    "Chưa có cập nhật": "Пока нет обновлений",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh": "Устройств пока нет. Нажмите +, чтобы добавить первое и начать защиту дома.",
    "CHƯA AN TOÀN": "НЕБЕЗОПАСНО",
    "CẦN CHÚ Ý": "ТРЕБУЕТ ВНИМАНИЯ",
    "ĐÃ AN TOÀN": "БЕЗОПАСНО",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.": "Дом требует проверки. Просмотрите статусы ниже.",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "Дом работает стабильно, можно быть спокойным.",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "Нет признаков дыма или аномалий SOS.",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "Недостаточно новых действий для подробного анализа.",
    "Hub kết nối bình thường": "Hub подключен нормально",
    "Cài đặt cảnh báo cho nhà hiện tại": "Настройки тревог для текущего дома",
    "Nhận cảnh báo Alarm": "Получать тревоги Alarm",
    "Đang bật cho tài khoản này": "Включено для этого аккаунта",
    "Đang tắt cho tài khoản này": "Выключено для этого аккаунта",
    "Hẹn giờ Reminder": "Расписание Reminder",
    "Nhắc kiểm tra nhà theo thời gian": "Напоминать проверять дом по расписанию",
    "Hẹn giờ Alarm": "Расписание Alarm",
    "Chưa thiết lập": "Не настроено",
    "Chưa thiết lập thời gian": "Время не настроено",
    "Tổng hợp trạng thái nhà": "Сводка состояния дома",
    "Cần xử lý ngay": "Требуется действие",
    "Cần kiểm tra": "Требует проверки",
    "Đánh giá tự động": "Автоматическая оценка",
    "Tự động đánh giá": "Автоматическая оценка",
    "Tổng quan hôm nay": "Обзор за сегодня",
    "Chưa có dữ liệu tổng quan": "Пока нет данных обзора",
    "Chưa có dữ liệu trạng thái": "Пока нет данных состояния",
    "Chưa đủ dữ liệu để đánh giá": "Недостаточно данных для оценки",
    "Chưa có dữ liệu để đánh giá": "Недостаточно данных для оценки",
    "Bấm vào để xem chi tiết": "Нажмите, чтобы посмотреть детали",
    "Nhấn để xem chi tiết...": "Нажмите, чтобы посмотреть детали...",
    "Tạm dừng": "Приостановлено",
    "Tắt": "Выключено",
    "Chi tiết": "Подробности",
    "Tổng hợp trạng thái": "Сводка состояния",
    "Không an toàn": "Небезопасно",
    "Cần chú ý": "Требует внимания",
    "An toàn": "Безопасно",
    "Không có": "Нет",
    "Đổi tên nhóm": "Переименовать группу",
    "Huỷ": "Отмена",
    "Hủy": "Отмена",
    "Lưu": "Сохранить",
    "Thêm": "Добавить",
    "Xoá": "Удалить",
    "Đổi tên": "Переименовать",
    "Nhà của tôi": "Мои дома",
    "Bỏ chọn toàn bộ nhóm": "Снять выбор со всей группы",
    "Chọn toàn bộ nhóm": "Выбрать всю группу",
    "Bỏ chọn": "Снять выбор",
    "Quay lại": "Назад",
    "Tìm kiếm": "Поиск",
    "Đóng tìm kiếm": "Закрыть поиск",
    "Giờ": "Час",
    "Phút": "Минуты",
    "Đặt Home Reminder": "Настроить Reminder для дома",
    "Đặt Home Alarm": "Настроить Alarm для дома",
    "Xác nhận thay đổi": "Подтвердить изменения",
    "Tiếp tục": "Продолжить",
    "Giờ Reminder": "Время Reminder",
    "Giờ bắt đầu Alarm": "Время начала Alarm",
    "Giờ kết thúc Alarm": "Время окончания Alarm",
    "Không có nhà nào đủ điều kiện để cài": "Подходящие дома не найдены",
    "Cài đặt hoàn tất": "Настройка завершена",
    "Xác nhận rời nhà": "Подтвердить выход из дома",
    "Xác nhận xoá nhà": "Подтвердить удаление дома",
    "Nhập mật khẩu": "Введите пароль",
    "Mật khẩu tài khoản": "Пароль аккаунта",
    "Rời khỏi nhà": "Покинуть дом",
    "Xoá nhà": "Удалить дом",
    "Sai mật khẩu": "Неверный пароль",
    "Đã rời khỏi home": "Дом покинут",
    "Đã cập nhật": "Обновлено",
    "Tìm home...": "Поиск домов...",
    "Đặt vị trí nhà và bật bảo vệ tự động": "Задать местоположение дома и включить автоматическую охрану",
    "Chuyển quyền chủ nhà hoặc xoá nhà": "Передать право владельца или удалить дом",
    "Đặt Reminder / Alarm nhà đã chọn": "Настроить Reminder / Alarm для выбранных домов",
    "Chia sẻ nhà đã chọn": "Поделиться выбранными домами",
    "Mở danh sách chia sẻ nhà": "Открыть список доступа к домам",
    "Xoá các nhà đã chọn?": "Удалить выбранные дома?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "Выбранные дома будут удалены навсегда.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn": "Или отсканируйте QR-код, чтобы запросить доступ к выбранным домам",
    "Email người nhận": "Email получателя",
    "Chia sẻ": "Поделиться",
    "Email chưa đăng ký": "Email не зарегистрирован",
    "Chia sẻ hoàn tất": "Доступ предоставлен",
    "Mở List chia sẻ nhà": "Открыть список доступа к домам",
    "Không có nhà nào bạn có quyền quản lý": "У вас нет прав управления выбранными домами",
    "Chưa share cho ai": "Пока ни с кем не поделено",
    "Tìm nhà": "Поиск домов",
    "Xoá các nhà đã chọn ?": "Удалить выбранные дома?",
    "Thông báo Home": "Дом уведомления",
    "Thông báo nhà": "Уведомления дома",
    "Vai trò thành viên đã thay đổi": "Роль участника изменена",
    "Xoá tất cả thông báo?": "Удалить все уведомления?",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "Все уведомления дома будут удалены.",
    "Chưa có thông báo nào": "Уведомлений пока нет",
    "Chưa có thông báo": "Нет уведомлений",
    "Vuốt lên để tải thêm": "Проведите вверх, чтобы загрузить еще",
    "Không có thiết bị": "Нет устройств",
    "Chỉ chủ nhà mới được xoá nhà": "Только владелец может удалить этот дом",
    "Chỉ chủ nhà mới được chuyển quyền": "Только владелец может передать права",
    "Lưu ý khi bật Alarm": "Примечание при включении Alarm",
    "Alarm đã được bật": "Alarm включен",
    "Đã hiểu": "Понятно",
    "Lưu ý tạm tắt Alarm": "Примечание паузы Alarm",
    "Đã bật Alarm": "Alarm включен",
    "Đã tắt Alarm": "Alarm отключен",
    "Tắt Alarm": "Выключить Alarm",
    "Cả ngày": "Весь день",
    "Bạn không có quyền thực hiện thao tác này.": "У вас нет разрешения выполнить это действие.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.": "Не удалось завершить действие. Повторите попытку.",
    "QR gia nhập nhiều nhà không hợp lệ": "Недействительный QR-код для присоединения к нескольким домам",
    "Bạn đang là chủ các nhà này": "Вы владелец этих домов",
    "Một người dùng": "Пользователь",
    "Yêu cầu gia nhập nhà": "Запрос на присоединение к дому",
    "Đã gửi yêu cầu gia nhập nhà": "Запрос на присоединение отправлен",
    "QR gia nhập không hợp lệ": "Недействительный QR-код присоединения",
    "Bạn đang là chủ nhà này": "Вы уже владелец этого дома",
    "QR này không phải mã xin gia nhập nhà": "Этот QR-код не является кодом присоединения к дому",
    "Bạn không có quyền thêm thiết bị": "У вас нет разрешения добавлять устройства",
    "Đã mở chế độ thêm thiết bị": "Сопряжение устройства включено",
    "Rời khỏi Home này?": "Покинуть этот дом?",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.": "Этот дом и все его устройства будут удалены навсегда.",
    "Đã xoá nhà": "Дом удален",
    "QR của nhà này": "QR-код дома",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.": "Другие могут отсканировать этот код, чтобы запросить доступ к дому.",
    "Chia sẻ nhà": "Поделиться домом",
    "Quét QR để xin gia nhập nhà": "Сканируйте QR, чтобы запросить присоединение к дому",
    "Quét QR xin gia nhập nhà": "Сканировать QR для входа в дом",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "Поместите QR-код общего дома в рамку",
    "Mã QR này do chủ nhà chia sẻ":
    "Этот QR-код предоставлен владельцем дома",
    "Nhập mã mời": "Введите код приглашения",
    "Gửi yêu cầu gia nhập": "Отправить запрос на вступление",
    "QR này không phải mã thiết bị":
    "Этот QR-код не является кодом устройства",
    "Xin gia nhập nhà": "Запросить присоединение к дому",
    "Quét mã QR chia sẻ nhà": "Сканировать QR-код общего доступа к дому",
    "Mời thành viên bằng mã QR": "Пригласить участника по QR-коду",
    "Không thể share cho chính bạn": "Нельзя поделиться с самим собой",
    "Lời mời chia sẻ nhà": "Приглашение к доступу к дому",
    "Đã share home": "Дом предоставлен в общий доступ",
    "Chuyển quyền chủ nhà": "Передать права владельца",
    "Không thể chuyển quyền cho chính bạn": "Нельзя передать права владельца самому себе",
    "Không tìm thấy user": "Пользователь не найден",
    "Không tìm thấy tài khoản": "Аккаунт не найден",
    "Xác nhận chuyển quyền": "Подтвердить передачу прав владельца",
    "Chuyển": "Передать",
    "Xác nhận mật khẩu": "Подтвердить пароль",
    "Xác nhận": "Подтвердить",
    "Yêu cầu chuyển quyền chủ nhà": "Запрос передачи прав владельца",
    "Đã gửi yêu cầu chuyển quyền": "Запрос передачи отправлен",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "Запрос передачи прав владельца отправлен",
    "Bạn không có quyền xoá thiết bị": "У вас нет разрешения удалять устройства",
    "Xóa Device?": "Удалить это устройство?",
    "Đã gửi yêu cầu xoá thiết bị": "Запрос на удаление устройства отправлен",
    "Đang xoá thiết bị": "Удаление устройства",
    "Đăng xuất?": "Выйти?",
    "Thêm nhà": "Добавить дом",
    "Thêm nhà mới": "Добавить новый дом",
    "Tạo nhà mới": "Создать новый дом",
    "Tạo một ngôi nhà mới của bạn": "Создать новый дом",
    "Quét mã QR được chủ nhà chia sẻ": "Отсканируйте QR-код, которым поделился владелец",
    "Tên nhà": "Название дома",
    "Số điện thoại": "Номер телефона",
    "Nam": "Мужской",
    "Nữ": "Женский",
    "Ngày": "День",
    "Tháng": "Месяц",
    "Năm": "Год",
    "Thông tin cá nhân": "Личная информация",
    "Thiết lập tài khoản": "Настройка аккаунта",
    "Vui lòng nhập đủ thông tin": "Введите всю необходимую информацию",
    "Không thể lưu thông tin": "Не удалось сохранить информацию",
    "Đã lưu thông tin": "Информация сохранена",
    "Lỗi lưu profile": "Не удалось сохранить профиль",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp": "Добавьте номер телефона для экстренных случаев",
    "Hoàn tất": "Готово",
    "Đã tạo nhà mới": "Дом создан",
    "Về muộn": "Вернуться позже",
    "Ra ngoài": "Выхожу",
    "Khác": "Другое",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ Приостановить Alarm сегодня",
    "Chọn giờ bắt đầu tạm tắt": "Выберите время начала паузы",
    "Từ": "С",
    "Từ giờ": "С",
    "Chọn giờ kết thúc tạm tắt": "Выберите время окончания паузы",
    "Đến": "До",
    "Đến giờ": "До",
    "Xoá lịch tạm tắt": "Удалить расписание паузы",
    "Xóa lịch tạm tắt": "Удалить расписание паузы",
    "Giới tính": "Пол",
    "SĐT": "Телефон",
    "Ngày sinh": "Дата рождения",
    "Yêu cầu & lời mời": "Запросы и приглашения",
    "Xem lời mời chia sẻ và xin gia nhập": "Просмотр приглашений и запросов на присоединение",
    "Cài đặt bảo mật": "Настройки безопасности",
    "Quyền báo động toàn màn hình": "Разрешение полноэкранной тревоги",
    "Báo động toàn màn hình": "Полноэкранная тревога",
    "Đã được cấp quyền": "Разрешение предоставлено",
    "Chưa được cấp quyền": "Разрешение не предоставлено",
    "Mở cài đặt hệ thống": "Открыть системные настройки",
    "Đăng xuất": "Выйти",
    "Thoát tài khoản khỏi thiết bị này": "Выйти с этого устройства",
    "Không có yêu cầu hoặc lời mời nào": "Нет запросов или приглашений",
    "Xoá tài khoản": "Удалить аккаунт",
    "Hành động này sẽ xoá toàn bộ dữ liệu:": "Это удалит все данные:",
    "Nhà và thiết bị": "Дома и устройства",
    "Chia sẻ và quyền truy cập": "Общий доступ и права",
    "Toàn bộ dữ liệu liên quan": "Все связанные данные",
    "Mật khẩu xác nhận": "Пароль подтверждения",
    "Đã xoá tài khoản": "Аккаунт удален",
    "Xoá thất bại": "Удаление не удалось",
    "Lỗi xoá tài khoản": "Не удалось удалить аккаунт",
    "Tình trạng": "Состояние",
    "Tháo/Lắp": "Вскрытие",
    "Pin": "Батарея",
    "Tín hiệu": "Сигнал",
    "Chưa liên kết": "Не привязано",
    "Liên lạc cuối": "Последний контакт",
    "Event cuối": "Последнее событие",
    "Sự kiện cuối": "Последнее событие",
    "Lần kích hoạt cuối": "Последнее срабатывание",
    "Thiết bị không còn tồn tại": "Устройство больше не существует",
    "Mất kết nối": "Отключено",
    "Online": "В сети",
    "Offline": "Не в сети",
    "Loại thiết bị": "Тип устройства",
    "Nhiệt độ": "Температура",
    "Độ ẩm": "Влажность",
    "Công suất": "Мощность",
    "Điện áp": "Напряжение",
    "Dòng điện": "Ток",
    "Điện năng": "Энергия",
    "Cường độ rung": "Сила вибрации",
    "Góc nghiêng": "Угол наклона",
    "Độ mở van": "Открытие клапана",
    "Nguồn dự phòng": "Резервное питание",
    "Ngập/rò nước": "Протечка воды",
    "Phát hiện khói": "Обнаружен дым",
    "Quản lý phòng": "Управление комнатами",
    "Bạn không có quyền quản lý phòng": "У вас нет разрешения управлять комнатами",
    "Đổi tên phòng": "Переименовать комнату",
    "Tên phòng": "Название комнаты",
    "Xoá phòng": "Удалить комната",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.": "Устройства из этой комнаты будут перемещены в раздел «Без комнаты».",
    "Thêm phòng": "Добавить комната",
    "Ví dụ: Phòng khách": "Например: гостиная",
    "Phòng khách": "Гостиная",
    "Tên phòng đã tồn tại": "Название комнаты уже существует",
    "Chưa phân phòng": "Без комнаты",
    "Phòng mặc định": "Комната по умолчанию",
    "Phát hiện bất thường": "Обнаружена аномалия",
    "Phát hiện cạy phá": "Обнаружена попытка вскрытия",
    "Tamper detected": "Обнаружено вскрытие",
    "Tamper cleared": "Вскрытие в норме",
    "Door opened": "Дверь открыта",
    "Door closed": "Дверь закрыта",
    "Motion detected": "Движение обнаружено",
    "Battery low": "Низкий заряд батареи",
    "Device offline": "Устройство не в сети",
    "Device online": "Устройство в сети",
    "Alarm triggered": "Alarm сработал",
    "Alarm cleared": "Alarm снят",
    "Cửa mở": "Дверь открыта",
    "Cửa đóng": "Дверь закрыта",
    "Chưa đặt vị trí nhà": "Местоположение дома не задано",
    "Đặt vị trí nhà tại đây": "Задать местоположение дома здесь",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ": "Задайте местоположение дома перед включением автоматической охраны",
    "Bán kính bảo vệ mặc định: 150 m": "Радиус охраны по умолчанию: 150 м",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.": "Каждый участник должен разрешить постоянный доступ к местоположению, чтобы статус ухода/возвращения домой работал в фоне.",
    "Lưu cài đặt": "Сохранить настройки",
    "Đã đặt vị trí nhà": "Местоположение дома задано",
    "Đang lấy vị trí...": "Получение местоположения...",
    "Đang lưu...": "Сохранение...",
    "Đổi tên hiển thị": "Изменить отображаемое имя",
    "Cập nhật thông tin nhà": "Обновить информацию о доме",
    "Nhập địa chỉ của nhà": "Введите адрес дома",
    "Lưu thay đổi": "Сохранить изменения",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.": "Это имя отображается только в вашей учетной записи.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.": "Имя и адрес будут обновлены для всех участников дома.",
    "Một thành viên": "Участник",
    "Đã cập nhật thông tin nhà": "Информация о доме обновлена",
    "Thay tên": "Переименовать",
    "Đã đổi tên thiết bị": "Устройство переименовано",
    "Chưa chọn nhà để kiểm tra": "Выберите дом для проверки",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner": "Выполните проверку с учетной записью владельца",
    "Không đọc được dữ liệu nhà": "Не удалось прочитать данные дома",
    "Nhà cần có ít nhất một thiết bị để test": "Для проверки в доме должно быть хотя бы одно устройство",
    "Đóng": "Закрыть",
    "Đã thiết lập": "Настроено",
    "Quét QR": "Сканировать QR",
    "Quét QR để thêm thiết bị": "Сканируйте QR, чтобы добавить устройство",
    "Nhập HUB ID thủ công": "Ввести HUB ID вручную",
    "Bạn không có quyền sắp xếp phòng": "У вас нет разрешения менять порядок комнат",
    "Cảnh báo khói": "Тревога дыма",
    "Cập nhật thiết bị": "Обновить устройство",
    "Cửa đang mở": "Дверь открыта",
    "Cửa đã đóng": "Дверь закрыта",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: найдены ошибки",
    "Firebase Rules: ĐẠT": "Firebase Rules: пройдено",
    "Giờ không hợp lệ": "Недопустимое время",
    "Khôi phục mật khẩu": "Сбросить пароль",
    "Nhập email của bạn": "Введите ваш email",
    "Gửi": "Отправить",
    "Đã gửi email khôi phục": "Письмо для сброса пароля отправлено",
    "Không gửi được email": "Не удалось отправить email",
    "Vui lòng nhập email và mật khẩu": "Введите email и пароль",
    "Mật khẩu xác nhận không khớp": "Пароли не совпадают",
    "Không thể tạo tài khoản": "Не удалось создать учетную запись",
    "Sai tài khoản": "Неверная учетная запись",
    "Email đã tồn tại": "Email уже существует",
    "Mật khẩu quá yếu": "Пароль слишком слабый",
    "Sai email hoặc mật khẩu": "Неверный email или пароль",
    "Lỗi đăng nhập": "Ошибка входа",
    "Email": "Эл. почта",
    "Mật khẩu": "Пароль",
    "Ghi nhớ tài khoản": "Запомнить учетную запись",
    "Đăng nhập": "Войти",
    "Đăng ký mới": "Создать аккаунт",
    "Quên mật khẩu?": "Забыли пароль?",
    "Chưa có tài khoản? Đăng ký": "Нет учетной записи? Зарегистрироваться",
    "Đã có tài khoản? Đăng nhập": "Уже есть учетная запись? Войти",
    "Tính năng đang được phát triển": "Эта функция находится в разработке",
    "Thông báo": "Уведомления",
    "Chat trong nhà": "Чат дома",
    "Tìm kiếm tin nhắn": "Поиск сообщений",
    "Xem thành viên": "Просмотреть участников",
    "Tìm nội dung hoặc tên người gửi": "Искать по содержанию или имени отправителя",
    "Xoá từ khoá": "Очистить ключевое слово",
    "Không có kết quả": "Нет результатов",
    "Tìm ngôn ngữ": "Поиск языка",
    "Kết quả trước": "Предыдущий результат",
    "Kết quả tiếp theo": "Следующий результат",
    "Chưa có tin nhắn": "Сообщений пока нет",
    "Không tìm thấy thành viên phù hợp": "Подходящие участники не найдены",
    "Nhắc đến trong tin nhắn": "Упомянуть в сообщении",
    "Huỷ trả lời": "Отменить ответ",
    "Nhắn gì đó...": "Введите сообщение...",
    "Gọi điện": "Позвонить",
    "Alarm thiết bị": "Устройство Alarm",
    "Chế độ áp dụng": "Режим применения",
    "Theo nhà": "Дом расписание",
    "Riêng tôi": "Только я",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập": "Использовать общий график, заданный владельцем или администратором",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn": "Использовать личный график только для вашей учетной записи",
    "Thiết lập nhanh Alarm": "Быстрая настройка Alarm",
    "Thiết lập nhanh toàn bộ thiết bị": "Быстро настроить все устройства",
    "Áp dụng cho toàn bộ thiết bị": "Применить ко всем устройствам",
    "Bắt đầu": "Начало",
    "Kết thúc": "Конец",
    "Thời gian lặp lại": "Интервал повторения",
    "Không lặp lại": "Без повтора",
    "Quét QR HUB": "Сканировать HUB QR",
    "Đưa mã QR vào giữa khung": "Поместите QR-код в рамку",
    "Đang áp dụng...": "Применение...",
    "Hôm nay đã ghi nhận cảnh báo SOS": "Сегодня зафиксирован SOS-сигнал",
    "Hôm nay đã ghi nhận cảnh báo khói": "Сегодня зафиксирована дымовая тревога",
    "Khói đã an toàn": "Дымовая тревога снята",
    "Không tìm thấy nhà của thông báo này": "Дом для этого уведомления не найден",
    "Không tìm thấy thiết bị trong nhà này": "Устройство в этом доме не найдено",
    "Một chủ nhà": "Владелец дома",
    "Ngôi nhà đang hoạt động ổn định": "Дом работает нормально",
    "Nhiệt độ cao": "Высокая температура",
    "OK": "OK",
    "Pin yếu": "Низкий заряд батареи",
    "SOS đã kết thúc": "SOS завершен",
    "SOS được kích hoạt": "SOS активирован",
    "Tamper bình thường": "Вскрытие в норме",
    "Thiết bị bị tháo": "Устройство снято",
    "Thiết bị mới": "Новое устройство",
    "Thiết bị offline": "Устройство офлайн",
    "Thiết bị online": "Устройство онлайн",
    "Báo động kích hoạt": "Alarm сработал",
    "Báo động đã tắt": "Alarm снят",
    "Tạm tắt Alarm hôm nay": "Приостановить Alarm сегодня",
    "Độ ẩm cao": "Высокая влажность",
    "Thử lại": "Повторить",
    "Không thể tải dữ liệu tài khoản": "Не удалось загрузить данные учетной записи",
    "Không": "Нет",
    "Đã chia sẻ nhà thành công.": "Дома успешно переданы в общий доступ.",
    "Tìm nhà...": "Поиск домов...",
    "Đã rời khỏi nhà": "Вы покинули дом",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.": "Вы покинете общие дома.",
    "Các nhà của bạn sẽ bị xoá.\n": "Ваши дома будут удалены.\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n": "Это изменит графики Alarm для дома для всех охранных устройств в выбранных домах.\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n": "Это добавит Reminder для дома для выбранных домов.\n\n",
    "Xác nhận thay đổi Alarm": "Подтвердить изменения Alarm",
    "Xác nhận thay đổi Reminder": "Подтвердить изменения Reminder",
    "Lặp lại khi sự cố vẫn còn": "Повторять, пока проблема сохраняется",
    "Thời gian lặp lại Alarm": "Время повторения Alarm",
    "VD: Mr Chung": "Напр.: Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 Домов пока нет",
    "Vẫn chuyển về Bình thường": "Все равно перейти в обычный режим",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.": "Автоматическая охрана при уходе все еще включена. Если все участники остаются вне дома, система может снова включить режим охраны через несколько минут.",
    "Chuyển về Bình thường?": "Перейти в обычный режим?",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n": "Охранные устройства сразу будут поставлены под наблюдение.\n\n",
    "Bật Bảo vệ thủ công?": "Включить ручной режим охраны?",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ": "Это действие изменит время Alarm для некоторых устройств сегодня...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ": "Это действие отключит все тревоги дома ",
    "Tắt toàn bộ Alarm?": "Отключить все Alarm?",
    "Không xoá được lịch tạm tắt Alarm": "Не удалось удалить график паузы Alarm",
    "Không lưu được tạm tắt Alarm": "Не удалось сохранить паузу Alarm",
    "Không gửi được yêu cầu xoá": "Не удалось отправить запрос на удаление",
    "Không lưu được cài đặt": "Не удалось сохранить настройку",
    "Không lấy được vị trí hiện tại": "Не удалось получить текущее местоположение",
    "Không thể xác nhận tài khoản hiện tại": "Не удалось подтвердить текущую учетную запись",
    "Mật khẩu không đúng": "Неверный пароль",
    "Không thể xác nhận mật khẩu": "Не удалось подтвердить пароль",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động": "Только владелец или администратор может изменить повтор Alarm",
    "Không lưu được thời gian lặp báo động": "Не удалось сохранить время повторения Alarm",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "Только владелец или администратор может изменить режим охраны",
    "Không thể thay đổi chế độ nhà": "Не удалось изменить режим дома",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "Режим охраны включен, но уведомление не отправлено",
    "Đã bật Mode Bảo vệ thủ công": "Ручной режим охраны включен",
    "Đã chuyển nhà về Bình thường": "Дом переведен в обычный режим",
    "60 phút": "60 минут",
    "30 phút": "30 минут",
    "15 phút": "15 минут",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.": "Вы просматриваете график владельца. Выберите «Только я», чтобы задать собственный график Alarm.",
    "Chọn giờ kết thúc Alarm": "Выберите время окончания Alarm",
    "Chọn giờ bắt đầu Alarm": "Выберите время начала Alarm",
    "Bạn không có quyền sửa lịch Alarm của nhà": "У вас нет разрешения редактировать график Alarm этого дома",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị": "Не удалось применить Alarm ко всем устройствам",
    "Nhà chưa có thiết bị an ninh để áp dụng": "В этом доме нет охранных устройств для применения",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.": "У вас нет разрешения редактировать настройки дома. Выберите «Только я».",
    "Không thể lưu chế độ Alarm": "Не удалось сохранить режим Alarm",
    "Thêm Reminder": "Добавить Reminder",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.": "Reminder напомнит вам проверить состояние безопасности дома в выбранное время.",
    "Thêm khung giờ Alarm": "Добавить временное окно Alarm",
    "Đang sử dụng Reminder riêng của bạn": "Используются ваши личные настройки Reminder",
    "Đang sử dụng Reminder của chủ nhà": "Используются настройки Reminder владельца",
    "Sửa giờ Reminder": "Изменить время Reminder",
    "Sửa giờ kết thúc Alarm": "Изменить время окончания Alarm",
    "Sửa giờ bắt đầu Alarm": "Изменить время начала Alarm",
    "Xoá Reminder": "Удалить Reminder",
    "Mỗi 1 giờ": "Каждый час",
    "Mỗi 30 phút": "Каждые 30 минут",
    "Mỗi 15 phút": "Каждые 15 минут",
    "Không báo lại": "Не повторять",
    "Báo lại khi vẫn chưa an toàn": "Повторять, пока небезопасно",
    "Báo lại mỗi 1 giờ": "Повторять каждый час",
    "Báo lại mỗi 30 phút": "Повторять каждые 30 минут",
    "Báo lại mỗi 15 phút": "Повторять каждые 15 минут",
    "Quản lý nhà": "Управление домом",
    "Xoá thành viên": "Удалить участника",
    "Đã xoá thành viên": "Участник удален",
    "Đồng ý": "OK",
    "Bạn chắc chắn muốn rời khỏi nhà này?": "Вы уверены, что хотите покинуть этот дом?",
    "Xoá thành viên?": "Удалить участника?",
    "Rời khỏi nhà?": "Покинуть этот дом?",
    "Chỉ chủ nhà mới được thay đổi vai trò": "Только владелец может менять роли",
    "Bạn không có quyền xoá thành viên này": "У вас нет разрешения удалить этого участника",
    "Bạn": "Вы",
    "Không có email": "Нет email",
    "Chưa có số điện thoại": "Нет номера телефона",
    "Không mở được ứng dụng gọi điện": "Не удалось открыть приложение телефона",
    "Thành viên chưa cập nhật số điện thoại": "Этот участник не добавил номер телефона",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "Ручной режим охраны включен - отключается переходом в обычный режим",
    "Thời gian lặp": "Интервал повторения",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "Выберите 0, чтобы предупредить один раз. Эта настройка применяется к ручному режиму охраны и автоматической охране при уходе.",
    "Lặp báo động khi sự cố vẫn còn": "Повторять Alarm, пока проблема сохраняется",
    "Đang được sử dụng": "Сейчас используется",
    "Chuyển về sử dụng thông thường": "Вернуться к обычному использованию",
    "Chế độ nhà": "Режим дома",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "SOS-устройство не зафиксировало тревогу.",
    "Cảm biến khói chưa ghi nhận bất thường.": "Датчик дыма не зафиксировал аномалий.",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.": "Вы или участник вручную включили режим охраны.",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.": "SafeHome автоматически включил режим охраны, потому что вы покинули дом.",
    "Nhà đang ở chế độ dùng bình thường.": "Этот дом сейчас в обычном режиме.",
    "Bảo vệ thủ công đang bật": "Ручной режим охраны включен",
    "Bảo vệ tự động đang bật": "Автоматическая охрана включена",
    "Bảo vệ đang tắt": "Режим охраны выключен",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.": "Вы недавно открывали приложение для проверки статуса.",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.": "Регулярно открывайте приложение, чтобы проверять разрешения, графики и непрочитанные тревоги.",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.": "После нескольких сеансов SafeHome сможет лучше оценить вашу привычку проверять приложение.",
    "Tần suất vào app ổn": "Частота входа в приложение нормальная",
    "Đã lâu chưa vào app kiểm tra": "Проверка приложения давно не выполнялась",
    "Đang ghi nhận tần suất vào app": "Частота входа в приложение записывается",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.": "Проверьте постоянное разрешение на местоположение и условия фоновой работы.",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.": "Это устройство соответствует требованиям для автоматического ухода из дома.",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.": "Можно включить автоматический переход в режим охраны при уходе.",
    "Auto rời khỏi nhà chưa ổn": "Автоматический уход из дома еще не готов",
    "Auto rời khỏi nhà đã sẵn sàng": "Автоматический уход из дома готов",
    "Auto rời khỏi nhà chưa bật": "Автоматический уход из дома не включен",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.": "Добавьте датчик дыма, SOS или подходящее аварийное устройство для дома.",
    "Chưa có thiết bị khẩn cấp": "Аварийное устройство еще не добавлено",
    "Đã có thiết bị khẩn cấp": "Аварийные устройства добавлены",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.": "Задайте график Alarm на время сна или отсутствия дома.",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.": "В этом доме есть график Alarm или график тревог для отдельных устройств.",
    "Chưa set lịch Alarm": "График Alarm не задан",
    "Đã set lịch Alarm": "График Alarm задан",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.": "Задайте хотя бы один Reminder, чтобы не забывать проверять дом.",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.": "Приложение напомнит проверить дом по заданному графику.",
    "Chưa setup Reminder": "Reminder не настроен",
    "Đã setup Reminder": "Reminder настроен",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.": "Откройте приложение снова или войдите повторно, если это устройство не получает тревоги.",
    "Thiết bị chưa đăng ký nhận cảnh báo": "Это устройство не зарегистрировано для получения тревог",
    "Thiết bị nhận cảnh báo bình thường": "Это устройство может получать тревоги",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.": "iOS строже управляет фоновой работой, чем Android. Оставьте уведомления и постоянное местоположение включенными, если используете автоматический уход из дома.",
    "Cơ chế iOS": "Поведение iOS",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.": "Проверьте разрешение фоновой работы и автозапуск, чтобы тревоги не задерживались.",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.": "Устройство подтвердило важные условия фоновой работы.",
    "Cần kiểm tra chạy nền / tự khởi động": "Нужно проверить фон / автозапуск",
    "Chạy nền ổn định": "Фоновая работа стабильна",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "Некоторые телефоны Android могут задерживать тревоги, если включена оптимизация батареи.",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.": "Этот телефон с меньшей вероятностью задержит тревоги SafeHome.",
    "Chưa tắt tối ưu pin": "Оптимизация батареи все еще включена",
    "Tối ưu pin không chặn app": "Оптимизация батареи не блокирует приложение",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.": "Автоматическому уходу из дома нужен постоянный доступ к местоположению для стабильной работы.",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.": "Для автоматического ухода из дома требуется разрешение на местоположение.",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.": "Служба местоположения отключена, поэтому автоматический уход из дома может работать нестабильно.",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.": "Это разрешение нужно только для автоматического ухода из дома.",
    "Chưa cấp vị trí luôn luôn": "Постоянное местоположение не разрешено",
    "Đã cấp vị trí luôn luôn": "Постоянное местоположение разрешено",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.": "iOS не открывает полноэкранную тревогу как Android; приложение использует системные уведомления и звук.",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.": "Android использует полноэкранные тревоги; разрешите их в настройках, если телефон блокирует их.",
    "Cảnh báo trên iOS": "Тревоги на iOS",
    "Cảnh báo toàn màn hình": "Полноэкранные тревоги",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "Тревоги могут не отображаться, если уведомления отключены.",
    "Điện thoại có thể nhận thông báo SafeHome.": "Этот телефон может получать уведомления SafeHome.",
    "Chưa bật thông báo": "Уведомления не включены",
    "Đã bật thông báo": "Уведомления включены",
    "Hệ thống: Sẵn sàng": "Система: готова",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "Система: тревоги могут быть пропущены",
    "Cách bạn đang dùng app": "Как вы используете приложение",
    "Thiết bị của bạn": "Ваше устройство",
    "Kiểm tra điện thoại và cách bạn đang dùng app.": "Проверяет телефон и использование приложения.",
    "Hệ thống SafeHome": "Система SafeHome",
    "Hệ thống: Đang kiểm tra...": "Система: проверка...",
    "Tên": "Имя",
    "Bạn không có quyền thay đổi vị trí nhà": "У вас нет разрешения изменить местоположение дома",
    "Hãy bật GPS để đặt vị trí nhà": "Включите GPS, чтобы задать местоположение дома",
    "Bạn chưa cấp quyền vị trí": "Разрешение на местоположение не предоставлено",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng": "Предоставьте разрешение на местоположение в настройках приложения",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà": "Автоматическая охрана при уходе всех из дома включена",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà": "Автоматическая охрана при уходе всех из дома отключена",
    "Không thể thay đổi trạng thái Alarm": "Не удалось изменить статус Alarm",
    "Đã tắt toàn bộ Alarm của nhà": "Все Alarm этого дома отключены",
    "QR này không phải mã xin gia nhập Home": "Этот QR-код не является кодом запроса на присоединение к дому",
    "Thêm Home": "Добавить Дом",
    "Mở cài đặt": "Открыть настройки",
    "Để sau": "Позже",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.": "SafeHome нужен постоянный доступ к местоположению, чтобы определять, когда вы уходите из дома или возвращаетесь, даже когда приложение работает в фоне.",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.": "Сейчас SafeHome может получать доступ к местоположению только во время использования приложения.\n\nОткройте разрешение на местоположение и выберите «Разрешать всегда», чтобы автоматическая охрана при уходе работала в фоне.",
    "Cho phép vị trí luôn luôn": "Всегда разрешать местоположение",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.": "Ваши дома будут удалены.\nВы покинете общие дома.",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "Это изменит графики Alarm для дома для всех охранных устройств в выбранных домах.\n\nУчастники, использующие настройки Alarm «По дому», будут затронуты.\nЛичные настройки Alarm в режиме «Только я» не изменятся.",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.": "Это добавит Reminder для дома для выбранных домов.\n\nУчастники, использующие настройки Reminder «По дому», будут затронуты.\nЛичные настройки Reminder в режиме «Только я» не изменятся.",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "Охранные устройства сразу будут поставлены под наблюдение.\n\nАвтоматическая охрана при уходе будет приостановлена. Этот режим не выключается автоматически, когда кто-то возвращается домой, и может быть вручную переведен в обычный режим только участником с разрешением.",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...": "Это действие изменит время Alarm для некоторых устройств сегодня...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.": "Это действие отключит все Alarm для этого дома. Вы больше не будете получать тревоги об опасности на телефон.",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.": "Alarm использует настройки дома.\n\nВы будете получать тревоги по общему графику Alarm, заданному владельцем или администратором.",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.": "Alarm использует личные настройки.\n\nВы будете получать тревоги по личному графику Alarm для этой учетной записи.",
    "Không thể đăng nhập bằng Google": "Не удалось войти через Google",
    "Không đặt được mật khẩu": "Не удалось задать пароль",
    "Chấp nhận": "Принять",
    "Cho phép": "Разрешить",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.": "Не удалось принять приглашение. Повторите попытку.",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.": "Не удалось принять запрос на присоединение. Повторите попытку.",
    "Từ chối": "Отклонить",
    "Lời mời từ chủ nhà": "Приглашение от владельца",
    "Nhận quyền chủ nhà": "Получить права владельца дома",
    "Một người dùng SafeHome": "Пользователь SafeHome",
    "Lời mời gia nhập": "Приглашение присоединиться",
    "Lời xin vào nhà": "Запрос на присоединение к дому",
    "Nhập HUB ID": "Введите HUB ID",
    "VD: HUB_001": "Пример: HUB_001",
    "Pair": "Сопряжение",
    "Mật khẩu tối thiểu 6 ký tự": "Пароль должен содержать не менее 6 символов",
    "Mật khẩu nhập lại không khớp": "Пароли не совпадают",
    "Tạo mật khẩu": "Создать пароль",
    "Mật khẩu mới": "Новый пароль",
    "Nhập lại mật khẩu": "Введите пароль повторно",
    "Xác nhận tắt cảnh báo": "Подтвердить отключение тревоги",
    "HỦY": "ОТМЕНА",
    "XÁC NHẬN": "ПОДТВЕРДИТЬ",
    "CẦN KIỂM TRA": "НУЖНА ПРОВЕРКА",
    "KIỂM TRA NHÀ": "ПРОВЕРИТЬ ДОМ",
    "ĐÓNG NHẮC NHỞ": "ЗАКРЫТЬ Reminder",
    "SafeHome Security Alert": "Оповещение безопасности SafeHome",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "Выберите «Разрешать всегда» для местоположения в настройках приложения",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.": "Для учетной записи Google нужно создать дополнительный пароль, чтобы использовать функции безопасности.",
    "Alarm": "Alarm",
    "Bạn không có quyền thực hiện thao tác này。": "У вас нет разрешения выполнить это действие.",
    "Cài đặt": "Настройки",
    "Cập nhật": "Обновить",
    "Chọn ngôn ngữ": "Выбрать язык",
    "Chưa có dữ liệu thiết bị để đánh giá": "Нет данных устройства для оценки",
    "Chuyển quyền sở hữu cho thành viên khác": "Передать права владельца другому участнику",
    "Có": "Да",
    "Cửa đã đóng an toàn": "Дверь надежно закрыта",
    "Đã xảy ra lỗi. Vui lòng thử lại.": "Произошла ошибка. Повторите попытку.",
    "Đang kiểm tra kết nối Hub": "Проверка соединения Hub",
    "Đang mở khi nhà ở chế độ Bảo vệ": "Открыто, когда дом в режиме охраны",
    "Đang mở trong giờ Alarm": "Открыто во время Alarm",
    "Đang tải...": "Загрузка...",
    "Hồ sơ, yêu cầu và lời mời tham gia": "Профиль, запросы и приглашения",
    "Hub chưa gửi trạng thái": "Статус Hub недоступен",
    "Hub mất kết nối": "Hub отключен",
    "Hub tín hiệu bình thường": "Hub подключен",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ": "Замок открыт, когда дом в режиме охраны",
    "Khóa đang mở trong giờ Alarm": "Замок открыт во время Alarm",
    "Không có thông báo": "Нет уведомлений",
    "Khu vực nguy hiểm": "Опасная зона",
    "Kiểm tra thiết bị trong nhà này": "Проверить устройства в этом доме",
    "Mất điện lưới": "Основное питание потеряно",
    "Mời người khác tham gia nhà này": "Пригласить другого человека присоединиться к этому дому",
    "Môi trường hiện tại": "Текущая среда",
    "MQTT mất kết nối": "MQTT отключен",
    "Ngôn ngữ": "Язык",
    "Nhà đã chia sẻ": "Дом предоставлен в общий доступ",
    "Nhà đang hoạt động bình thường": "Дом работает нормально",
    "Nhập email": "Введите email",
    "Phòng": "Комната",
    "Quản trị viên": "Администратор",
    "Reminder": "Reminder",
    "SafeHome": "SafeHome",
    "Sóng yếu": "Слабый сигнал",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "Аккаунт и система",
    "Tài khoản cá nhân": "Личный аккаунт",
    "Tạo tài khoản": "Создать аккаунт",
    "Thành viên": "Участники",
    "Thành viên trong nhà": "Участники дома",
    "Thay đổi ngôn ngữ hiển thị": "Изменить язык отображения",
    "Thêm, đổi tên và sắp xếp phòng": "Добавление, переименование и сортировка комнат",
    "Thiết bị đang được giám sát": "Устройство под наблюдением",
    "Tiếng Anh": "Английский",
    "Tiếng Hàn": "Корейский",
    "Tiếng Nhật": "Японский",
    "Tiếng Trung": "Китайский",
    "Tiếng Việt": "Вьетнамский",
    "Toàn bộ thiết bị": "Все устройства",
    "Vai trò": "Роль",
    "Về nhà": "Дома",
    "Xem và quản lý quyền thành viên": "Просмотр и управление ролями участников",
    "Xóa": "Удалить",
    "Xóa nhà": "Удалить дом",
    "Xoá toàn bộ dữ liệu và thiết bị": "Удалить все данные дома и устройства",
    "TẮT CẢNH BÁO": "ОСТАНОВИТЬ ТРЕВОГУ",
    "Đã tạo nhà": "Дом создан",

    "Mode Bảo vệ thủ công đã bật": "Ручной режим охраны включён",
    "Báo động không lặp lại.": "Тревога не будет повторяться.",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.": "Тревога повторится через \$securityModeRepeatMinutes мин., если проблема останется.",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage": "\$actorName включил ручной режим охраны для «\$homeName». Этот режим отключается только когда участник с правами переключит дом обратно в обычный режим. \$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".": "Вы включили Alarm для «\$homeName».",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".": "Вы отключили все Alarm для «\$homeName».",
    "Thành viên mới": "Новый участник",
    "Thành viên rời nhà": "Участник покинул дом",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".": "\$displayMemberName покинул(а) \"\$homeName\".",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".": "\$actorName изменил роль \$memberName в «\$homeName» с \$oldRoleName на \$newRoleName.",
    "Còn \$count tin nhắn chưa đọc": "\$count непрочитанных сообщений",
    "Hãy an tâm nghỉ ngơi.": "Можете спокойно отдыхать.",
    "Có thiết bị chưa an toàn.": "Некоторые устройства небезопасны.",
    "SafeHome đang cập nhật vị trí": "SafeHome обновляет местоположение",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.": "Идёт мониторинг для автоматического включения режима охраны.",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.": "Использует местоположение для автоматического включения режима охраны, когда все уходят из дома.",
    "CẢNH BÁO SOS": "SOS-ТРЕВОГА",
    "CẢNH BÁO KHÓI / CHÁY": "ТРЕВОГА ДЫМ / ПОЖАР",
    "CẢNH BÁO NGẬP NƯỚC": "ТРЕВОГА ЗАТОПЛЕНИЯ",
    "CẢNH BÁO RÒ KHÍ": "ТРЕВОГА УТЕЧКИ ГАЗА",
    "CẢNH BÁO CỬA": "ТРЕВОГА ДВЕРИ",
    "CẢNH BÁO AN NINH": "ТРЕВОГА БЕЗОПАСНОСТИ",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.": "Не удалось подтвердить действие в SafeHome. Проверьте подключение и повторите попытку.",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?": "Отключайте тревогу только после проверки состояния дома.\n\nВы уверены, что хотите отключить тревогу?",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome обнаружил тревогу",
    "Mở SafeHome để kiểm tra ngay.": "Откройте SafeHome, чтобы проверить сейчас.",
    "\$count tin nhắn mới": "\$count новых сообщений",
    "Tin nhắn HomeChat": "Сообщение HomeChat",
    "\$senderName đã gửi một tin nhắn": "\$senderName отправил сообщение",
    "Bạn có tin nhắn mới": "У вас новое сообщение",
    "Mode Bảo vệ sẽ chỉ báo động một lần": "Режим охраны подаст тревогу только один раз",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút": "Режим охраны повторит тревогу через \$minutes минут",
    "Đã gửi yêu cầu gia nhập \$count nhà": "Запросы на присоединение отправлены для \$count домов",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".": "\$requesterName просит присоединиться к \"\$homeName\".",
    "Bạn đã xoá nhà \"\$homeName\".": "Вы удалили дом «\$homeName».",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.": "Вы отправили запрос на передачу прав владельца дома «\$homeName» пользователю \$email.",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.": "\$actorName хочет передать вам право владельца дома «\$homeName».",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".": "\$actorName пригласил(а) вас присоединиться к \"\$homeName\".",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".": "SafeHome удаляет устройство «\$deviceName» из «\$homeName».",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".": "Устройство «\$deviceName» добавлено в «\$homeName».",
    "Bạn đã tạo nhà \"\$name\".": "Вы создали дом «\$name».",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.": "\$actorName изменил название дома на «\$newName» и обновил адрес.",
    "\$actorName đã đổi tên nhà thành \"\$newName\".": "\$actorName переименовал(а) дом в \"\$newName\".",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".": "\$actorName обновил(а) адрес дома \"\$newName\".",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".": "\$actorName переименовал устройство «\$oldDeviceName» в «\$newName» в доме «\$homeName».",
    "Đang ghép nối: \$seconds giây": "Сопряжение: \$seconds с",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.": "Режим добавления устройств открыт в «\$homeName» на \$seconds секунд.",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)": "Период паузы должен быть в расписании Alarm (\$start → \$end)",
    "\$passCount/\$total bài test đạt\n\n": "\$passCount/\$total тестов пройдено\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.": "\$name не добавил(а) номер телефона в профиль.",
    "Tin nhắn mới trong \$homeName": "Новое сообщение в \$homeName",
    "\$current/\$total kết quả": "\$current/\$total результатов",
    "Đang trả lời \$name": "Ответ для \$name",
    "\"\$name\" phát hiện khói trong \"\$homeName\".": "\"\$name\" обнаружил(а) дым в \"\$homeName\".",
    "\"\$name\" đã trở lại trạng thái bình thường.": "\"\$name\" вернулся в нормальное состояние.",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".": "\"\$name\" активировал(а) SOS в \"\$homeName\".",
    "\"\$name\" đã hết trạng thái SOS.": "\"\$name\" больше не в состоянии SOS.",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".": "\"\$name\" сообщил(а) о вскрытии в \"\$homeName\".",
    "\"\$name\" đã hết cảnh báo tháo/cạy.": "Тревога вскрытия «\$name» завершена.",
    "\"\$name\" đã đóng trong \"\$homeName\".": "\"\$name\" закрыт в \"\$homeName\".",
    "\"\$name\" đang mở trong \"\$homeName\".": "\"\$name\" открыт в \"\$homeName\".",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.": "У \"\$name\" в \"\$homeName\" низкий заряд батареи.",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.": "\"\$name\" в \"\$homeName\" отключился.",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.": "\"\$name\" в \"\$homeName\" снова онлайн.",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".": "\"\$name\" зафиксировал(а) высокую температуру в \"\$homeName\".",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".": "\"\$name\" зафиксировал(а) высокую влажность в \"\$homeName\".",
    "Có nút SOS vừa được kích hoạt": "Кнопка SOS была активирована",
    "Có dấu hiệu khói hoặc cháy": "Обнаружен дым или пожар",
    "Có dấu hiệu ngập nước": "Обнаружено затопление",
    "Có dấu hiệu rò khí": "Обнаружена утечка газа",
    "Có cửa đang mở hoặc thiết bị bị tháo": "Дверь открыта или устройство было снято",
    "Có thiết bị đang cảnh báo": "Устройство сообщает тревогу",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.": "Если никто не подтвердит, SafeHome перейдёт к экстренному звонку.",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.": "Повторить напоминание в \$time, если проблема не будет устранена.",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.": "Повторная тревога сработает по настроенному расписанию Alarm, если проблема не решена.",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".": "«\$deviceName» закрыт в «\$resolvedHomeName».",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".": "«\$deviceName» открыт в «\$resolvedHomeName».",
    "\$count nhà đã chọn": "Выбрано домов: \$count",
    "🚨 \$count nhà không an toàn\$suffix": "🚨 Небезопасных домов: \$count\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix": "⚠️ Требуют внимания: \$count\$suffix",
    "✅ \$count nhà an toàn": "✅ Безопасных домов: \$count",
    "\$count nhà đang được theo dõi": "Домов под наблюдением: \$count",
    "\$minutes phút": "\$minutes мин.",
    "Đã cài Reminder cho \$updatedHomes nhà.": "Reminder установлен для \$updatedHomes домов.",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n": "Alarm настроен для \$updatedDevices устройств в \$updatedHomes домах.\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.": "Дома, которыми вы можете делиться, были отправлены.\n\n\$skipped домов пропущено, потому что у вас нет разрешения делиться ими.",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh": "Alarm применён к \$count устройствам безопасности",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh": "Применить то же расписание к \$count устройствам безопасности",
    "\$count phút trước": "\$count мин. назад",
    "\$count giờ trước": "\$count ч. назад",
    "\${count}h trước": "\${count} ч. назад",
    "\${hours}h\$minutes' trước": "\${hours} ч. \${minutes} мин. назад",
    "\$count ngày trước": "\$count дн. назад",
    "\$count tháng trước": "\$count мес. назад",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?": "Вы уверены, что хотите удалить \$name из этого дома?",
    "\$targetEmail\nXin gia nhập \"\$homeName\"": "\$targetEmail\nЗапрашивает доступ к \"\$homeName\"",
    "Xin gia nhập \"\$homeName\"": "Запрашивает доступ к \"\$homeName\"",
    "Bạn được mời nhận quyền nhà \"\$homeName\"": "Вас пригласили принять право владельца дома «\$homeName»",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"": "\$ownerEmail\nприглашает вас присоединиться к \"\$homeName\"",
    "Mời bạn gia nhập \"\$homeName\"": "приглашает вас присоединиться к \"\$homeName\"",
    "Cần kiểm tra: \$joined": "Требуется проверка: \$joined",
    "Cập nhật \$value": "Обновлено: \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.": "Добавьте первое устройство SafeHome, чтобы начать наблюдение за этим домом.",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.": "Сначала проверьте экстренные тревоги, затем при необходимости свяжитесь с участниками дома.",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "Никого нет дома, но дверь или замок открыты. Проверьте сейчас.",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "Проверьте открытую дверь или замок, прежде чем оставлять дом в режиме охраны.",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.": "Возможно, кто-то всё ещё дома. Если это так, переключите в обычный режим.",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.": "У некоторых участников неизвестно местоположение. Попросите их открыть приложение или проверить разрешение на местоположение.",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "Устройство отключено. Проверьте батарею, питание или место установки.",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.": "У устройства низкий заряд батареи. Замените батарею заранее, чтобы не пропустить тревоги.",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.": "Reminder не настроен. Создайте расписание для регулярной проверки дома.",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.": "Расписание Alarm не настроено. Включите охрану на время, когда вас обычно нет дома.",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.": "Срочных действий не требуется. Продолжайте наблюдать за состоянием дома.",
    "Lặp sau \$minutes phút": "Повтор через \$minutes мин.",
    "Đang dùng • \$repeatText": "Активно • \$repeatText",
    "Giám sát an ninh • \$repeatText": "Мониторинг безопасности • \$repeatText",
    "Gia đình: \$mode": "Режим дома: \$mode",
    "Gợi ý xử lý": "Рекомендуемые действия",
    "Phát hiện \$count vấn đề cần xử lý": "Обнаружено проблем: \$count",
    "Hôm nay các cửa đã được sử dụng \$count lần": "Двери использовались сегодня \$count раз",
    "Đã ghi nhận \$count hoạt động gần đây": "Записано недавних действий: \$count",
    "Hệ thống: Cần kiểm tra \$issueCount mục": "Система: требуется проверить \$issueCount элементов",
    "FCM token đã sẵn sàng trên điện thoại này.": "FCM-токен готов на этом телефоне.",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.": "FCM-токен готов, но для Auto Away ещё не выполнено одно условие.",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.": "Найдено экстренных устройств: \$emergencyTotal. Рекомендуемый минимум: датчик дыма и SOS.",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?": "Передать право владельца дома:\n\$targetEmail?",
    "\$count cửa đã đóng an toàn": "Безопасно закрыто дверей: \$count",
    "\$count cửa và khóa đã an toàn": "Дверей и замков в безопасности: \$count",
    "\$count thiết bị đang được theo dõi": "\$count устройств под наблюдением",
    "Cập nhật \$timeText": "Обновлено: \$timeText",
    "Dữ liệu gần nhất cập nhật \$count phút trước": "Последние данные обновлены \$count минут назад",
    "Dữ liệu gần nhất cập nhật \$count giờ trước": "Последние данные обновлены \$count часов назад",
    "Thành viên trong nhà: \$count": "Участников дома: \$count",
    "Thành viên bên ngoài: \$count": "Участников вне дома: \$count",
    "Chưa xác định vị trí: \$count": "Местоположение неизвестно: \$count",
    "Môi trường hiện tại: \$environment": "Текущая среда: \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ": "\$name: открыто, пока дом в режиме охраны",
    "An tâm hơn trong từng ngôi nhà": "Спокойствие в каждом доме",
    "Báo động SafeHome": "Тревога SafeHome",
    "Có cảnh báo an ninh cần kiểm tra ngay.": "Тревога безопасности требует вашего внимания.",
    "Có cảnh báo cần kiểm tra": "Тревога требует вашего внимания",
    "Tự đóng sau \$time": "Автоматически закроется через \$time",
  };

  static const Map<String, String> _french = {
    "Không tìm thấy người dùng": "Utilisateur introuvable",
    "Không đọc được số điện thoại":
    "Impossible de lire le numéro de téléphone",
    "Tin nhắn quá dài": "Le message est trop long",
    "Không gửi được tin nhắn": "Impossible d'envoyer le message",
    "Bạn không có quyền sửa lịch chung của nhà":
    "Vous n'avez pas l'autorisation de modifier le planning partagé de la maison",
    "Nhà của bạn": "Votre maison",
    "Tải tin cũ hơn": "Charger les anciens messages",
    "Nhà chưa đặt tên": "Maison sans nom",
    "Nhà": "Maison",
    "Chưa có thông tin": "Aucune information disponible",
    "Chưa cập nhật": "Non mis à jour",
    "Chủ nhà": "Propriétaire",
    "Nhà được chia sẻ": "Maison partagée",
    "Địa chỉ": "Adresse",
    "An ninh ra/vào": "Sécurité des accès",
    "Nguy hiểm khẩn cấp": "Risques d'urgence",
    "Điều khiển & hạ tầng": "Contrôle et infrastructure",
    "Môi trường": "Environnement",
    "Toàn bộ thiết bị SafeHome": "Tous les appareils SafeHome",
    "Cửa ra/vào": "Porte d'entrée",
    "Cửa": "Porte",
    "Cửa sổ": "Fenêtre",
    "Cổng": "Portail",
    "Khóa thông minh": "Serrure intelligente",
    "Chuyển động": "Mouvement",
    "Hiện diện": "Présence",
    "Rung/chấn động": "Vibration/choc",
    "Kính vỡ": "Bris de verre",
    "Báo khói": "Détecteur de fumée",
    "Báo nhiệt": "Détecteur de chaleur",
    "Khí CO": "Monoxyde de carbone",
    "Báo gas": "Détecteur de gaz",
    "Báo ngập/rò nước": "Détecteur d'inondation/fuite d'eau",
    "Nút SOS": "Bouton SOS",
    "Nhiệt độ/Độ ẩm": "Température/Humidité",
    "Bụi mịn PM2.5": "Particules fines PM2.5",
    "CO₂": "Dioxyde de carbone (CO₂)",
    "Chất lượng không khí": "Qualité de l'air",
    "Ổ điện thông minh": "Prise intelligente",
    "Còi báo động": "Sirène",
    "Van thông minh": "Vanne intelligente",
    "Camera": "Caméra",
    "Chuông cửa": "Sonnette",
    "Bàn phím an ninh": "Clavier de sécurité",
    "Bộ mở rộng sóng": "Répéteur",
    "Hub trung tâm": "Hub central",
    "Đo điện năng": "Mesure d'énergie",
    "Nguồn dự phòng UPS": "Alimentation de secours UPS",
    "Thiết bị đang Offline": "Appareil hors ligne",
    "Thiết bị đang Online": "Appareil en ligne",
    "pin yếu": "batterie faible",
    "sóng yếu": "signal faible",
    "lâu không phản hồi": "ne répond pas",
    "Kết nối cần kiểm tra": "Connexion à vérifier",
    "Vừa xong": "À l'instant",
    "Bị tháo": "Arrachement détecté",
    "Có khói": "Fumée détectée",
    "Bình thường": "Mode normal",
    "Bảo vệ": "Mode protection",
    "Chế độ Bảo vệ": "Mode protection",
    "Tự động Bảo vệ khi rời nhà": "Protection automatique en cas d'absence",
    "Đã kích hoạt": "Activé",
    "Sẵn sàng": "Prêt",
    "Đang đóng": "Fermé",
    "Đang mở": "Ouvert",
    "Rò rỉ gas": "Fuite de gaz détectée",
    "Phát hiện ngập nước": "Fuite d'eau détectée",
    "Phát hiện chuyển động": "Mouvement détecté",
    "Không có chuyển động": "Aucun mouvement détecté",
    "Phát hiện hiện diện": "Présence détectée",
    "Không phát hiện hiện diện": "Aucune présence détectée",
    "Phát hiện rung/chấn động": "Vibration/choc détecté",
    "Không có rung bất thường": "Aucune vibration anormale",
    "Phát hiện kính vỡ": "Bris de verre détecté",
    "Không có cảnh báo kính vỡ": "Aucune alerte bris de verre",
    "Nhiệt độ nguy hiểm": "Température dangereuse détectée",
    "Phát hiện khí CO": "Monoxyde de carbone détecté",
    "Không phát hiện khí CO": "Aucun monoxyde de carbone détecté",
    "Khóa đang mở": "Déverrouillé",
    "Khóa đang đóng": "Verrouillé",
    "Đang bật": "Activé",
    "Đang tắt": "Désactivé",
    "Đang theo dõi điện năng": "Surveillance de l'énergie",
    "Đang dùng nguồn dự phòng": "Fonctionne sur l'alimentation de secours",
    "Nguồn điện bình thường": "Alimentation secteur normale",
    "Còi đang bật": "Sirène active",
    "Còi sẵn sàng": "Sirène prête",
    "Van đang mở": "Vanne ouverte",
    "Van đã đóng": "Vanne fermée",
    "Đang hoạt động": "En fonctionnement",
    "Đang theo dõi": "Surveillance en cours",
    "Chưa nhận diện": "Appareil non reconnu",
    "Chưa có cập nhật": "Aucune mise à jour",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh":
    "Aucun appareil pour le moment. Appuyez sur + pour en ajouter un et protéger votre maison.",
    "CHƯA AN TOÀN": "NON SÉCURISÉ",
    "CẦN CHÚ Ý": "ATTENTION REQUISE",
    "ĐÃ AN TOÀN": "SÉCURISÉ",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
    "La maison présente des signes à vérifier. Consultez les statuts ci-dessous.",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.":
    "La maison fonctionne normalement.",
    "Không có dấu hiệu khói hoặc SOS bất thường.":
    "Aucun signe anormal de fumée ou de SOS.",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.":
    "Pas assez d'activité récente pour une analyse plus approfondie.",
    "Hub kết nối bình thường": "Hub connecté",
    "Cài đặt cảnh báo cho nhà hiện tại":
    "Paramètres d'alerte pour cette maison",
    "Nhận cảnh báo Alarm": "Recevoir les alertes Alarm",
    "Đang bật cho tài khoản này": "Activé pour ce compte",
    "Đang tắt cho tài khoản này": "Désactivé pour ce compte",
    "Hẹn giờ Reminder": "Planning Reminder",
    "Nhắc kiểm tra nhà theo thời gian":
    "Rappeler de vérifier la maison à l'heure prévue",
    "Hẹn giờ Alarm": "Planning Alarm",
    "Chưa thiết lập": "Non configuré",
    "Chưa thiết lập thời gian": "Aucun horaire configuré",
    "Tổng hợp trạng thái nhà": "Résumé de l’état de la maison",
    "Cần xử lý ngay": "Action requise",
    "Cần kiểm tra": "À vérifier",
    "Đánh giá tự động": "Évaluation automatique",
    "Tự động đánh giá": "Évaluation automatique",
    "Tổng quan hôm nay": "Vue d'ensemble du jour",
    "Chưa có dữ liệu tổng quan": "Pas encore de données d'ensemble",
    "Chưa có dữ liệu trạng thái": "Pas encore de données de statut",
    "Chưa đủ dữ liệu để đánh giá": "Données insuffisantes pour évaluer",
    "Chưa có dữ liệu để đánh giá": "Données insuffisantes pour évaluer",
    "Bấm vào để xem chi tiết": "Appuyer pour voir les détails",
    "Nhấn để xem chi tiết...": "Appuyer pour voir les détails...",
    "Tạm dừng": "En pause",
    "Tắt": "Désactivé",
    "Chi tiết": "Détails",
    "Tổng hợp trạng thái": "Résumé de l’état",
    "Không an toàn": "Non sécurisé",
    "Cần chú ý": "Attention requise",
    "An toàn": "Sécurisé",
    "Không có": "Aucun",
    "Đổi tên nhóm": "Renommer le groupe",
    "Huỷ": "Annuler",
    "Hủy": "Annuler",
    "Lưu": "Enregistrer",
    "Thêm": "Ajouter",
    "Xoá": "Supprimer",
    "Đổi tên": "Renommer",
    "Nhà của tôi": "My maisons",
    "Bỏ chọn toàn bộ nhóm": "Tout désélectionner dans le groupe",
    "Chọn toàn bộ nhóm": "Tout sélectionner dans le groupe",
    "Bỏ chọn": "Désélectionner",
    "Quay lại": "Retour",
    "Tìm kiếm": "Rechercher",
    "Đóng tìm kiếm": "Fermer la recherche",
    "Giờ": "Heure",
    "Phút": "Min.",
    "Đặt Home Reminder": "Définir Home Reminder",
    "Đặt Home Alarm": "Définir Home Alarm",
    "Xác nhận thay đổi": "Confirmer changes",
    "Tiếp tục": "Continuer",
    "Giờ Reminder": "Heure du Reminder",
    "Giờ bắt đầu Alarm": "Heure de début Alarm",
    "Giờ kết thúc Alarm": "Heure de fin Alarm",
    "Không có nhà nào đủ điều kiện để cài": "Aucune maison éligible n'a été trouvée",
    "Cài đặt hoàn tất": "Configuration terminée",
    "Xác nhận rời nhà": "Confirmer leaving maison",
    "Xác nhận xoá nhà": "Confirmer maison deletion",
    "Nhập mật khẩu": "Saisir le mot de passe",
    "Mật khẩu tài khoản": "Mot de passe du compte",
    "Rời khỏi nhà": "Leave maison",
    "Xoá nhà": "Supprimer la maison",
    "Sai mật khẩu": "Mot de passe incorrect",
    "Đã rời khỏi home": "Left maison",
    "Đã cập nhật": "Mis à jour",
    "Tìm home...": "Rechercher maisons...",
    "Đặt vị trí nhà và bật bảo vệ tự động":
    "Définir la localisation de la maison et activer la protection automatique",
    "Chuyển quyền chủ nhà hoặc xoá nhà":
    "Transférer la propriété ou supprimer la maison",
    "Đặt Reminder / Alarm nhà đã chọn":
    "Définir Reminder / Alarm pour les maisons sélectionnées",
    "Chia sẻ nhà đã chọn": "Partager les maisons sélectionnées",
    "Mở danh sách chia sẻ nhà": "Ouvrir la liste de partage de maison",
    "Xoá các nhà đã chọn?": "Supprimer les maisons sélectionnées ?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.":
    "Les maisons sélectionnées seront supprimées définitivement.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn":
    "Ou scannez un QR pour demander l'accès aux maisons sélectionnées",
    "Email người nhận": "Email du destinataire",
    "Chia sẻ": "Partager",
    "Email chưa đăng ký": "Email non enregistré",
    "Chia sẻ hoàn tất": "Partage terminé",
    "Mở List chia sẻ nhà": "Ouvrir la liste de partage de maison",
    "Không có nhà nào bạn có quyền quản lý":
    "Vous ne gérez aucune maison sélectionnée",
    "Chưa share cho ai": "Aucun partage pour le moment",
    "Tìm nhà": "Rechercher maisons",
    "Xoá các nhà đã chọn ?": "Supprimer les maisons sélectionnées ?",
    "Thông báo Home": "Notifications de la maison",
    "Thông báo nhà": "Notifications de la maison",
    "Vai trò thành viên đã thay đổi": "Rôle du membre modifié",
    "Xoá tất cả thông báo?": "Supprimer toutes les notifications ?",
    "Toàn bộ thông báo nhà sẽ bị xoá.":
    "Toutes les notifications de la maison seront supprimées.",
    "Chưa có thông báo nào": "Aucune notification pour le moment",
    "Chưa có thông báo": "Aucune notification",
    "Vuốt lên để tải thêm": "Balayer vers le haut pour charger plus",
    "Không có thiết bị": "Aucun appareil",
    "Chỉ chủ nhà mới được xoá nhà":
    "Seul le propriétaire peut supprimer cette maison",
    "Chỉ chủ nhà mới được chuyển quyền":
    "Seul le propriétaire peut transférer la propriété",
    "Lưu ý khi bật Alarm": "Remarque lors de l'activation d'Alarm",
    "Alarm đã được bật": "Alarm activé",
    "Đã hiểu": "Compris",
    "Lưu ý tạm tắt Alarm": "Note sur la pause Alarm",
    "Đã bật Alarm": "Alarm activé",
    "Đã tắt Alarm": "Alarm désactivé",
    "Tắt Alarm": "Désactiver Alarm",
    "Cả ngày": "Toute la journée",
    "Bạn không có quyền thực hiện thao tác này.":
    "Vous n'avez pas l'autorisation d'effectuer cette action.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.":
    "Impossible de terminer l'action. Veuillez réessayer.",
    "QR gia nhập nhiều nhà không hợp lệ": "QR d'accès multi-maisons invalide",
    "Bạn đang là chủ các nhà này": "Vous êtes propriétaire de ces maisons",
    "Một người dùng": "Un utilisateur",
    "Yêu cầu gia nhập nhà": "Demande d'accès à la maison",
    "Đã gửi yêu cầu gia nhập nhà": "Demande d'accès envoyée",
    "QR gia nhập không hợp lệ": "QR d'accès invalide",
    "Bạn đang là chủ nhà này": "Vous êtes déjà propriétaire de cette maison",
    "QR này không phải mã xin gia nhập nhà":
    "Ce QR n'est pas un code de demande d'accès à une maison",
    "Bạn không có quyền thêm thiết bị":
    "Vous n'avez pas l'autorisation d'ajouter des appareils",
    "Đã mở chế độ thêm thiết bị": "Mode d'ajout d'appareil activé",
    "Rời khỏi Home này?": "Quitter cette maison ?",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.":
    "Cette maison et tous ses appareils seront supprimés définitivement.",
    "Đã xoá nhà": "Maison supprimée",
    "QR của nhà này": "QR de cette maison",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.":
    "Les autres peuvent scanner ce code pour demander l'accès à la maison.",
    "Chia sẻ nhà": "Partager maison",
    "Quét QR để xin gia nhập nhà":
    "Scanner un QR pour demander l'accès à une maison",
    "Quét QR xin gia nhập nhà":
    "Scanner le QR pour rejoindre la maison",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "Placez le QR de partage de maison dans le cadre",
    "Mã QR này do chủ nhà chia sẻ":
    "Ce QR est partagé par le propriétaire de la maison",
    "Nhập mã mời": "Saisir le code d'invitation",
    "Gửi yêu cầu gia nhập": "Envoyer la demande d'accès",
    "QR này không phải mã thiết bị":
    "Ce QR n'est pas un code d'appareil",
    "Xin gia nhập nhà": "Demander l'accès à la maison",
    "Quét mã QR chia sẻ nhà": "Scanner le QR de partage de maison",
    "Mời thành viên bằng mã QR": "Inviter un membre avec un QR",
    "Không thể share cho chính bạn": "Impossible de partager avec vous-même",
    "Lời mời chia sẻ nhà": "Invitation à partager la maison",
    "Đã share home": "Maison partagée",
    "Chuyển quyền chủ nhà": "Transférer la propriété",
    "Không thể chuyển quyền cho chính bạn":
    "Impossible de transférer à vous-même",
    "Không tìm thấy user": "Utilisateur introuvable",
    "Không tìm thấy tài khoản": "Compte introuvable",
    "Xác nhận chuyển quyền": "Confirmer le transfert de propriété",
    "Chuyển": "Transférer",
    "Xác nhận mật khẩu": "Confirmer le mot de passe",
    "Xác nhận": "Confirmer",
    "Yêu cầu chuyển quyền chủ nhà": "Demande de transfert de propriété",
    "Đã gửi yêu cầu chuyển quyền": "Demande de transfert envoyée",
    "Đã gửi yêu cầu chuyển quyền chủ nhà":
    "Demande de transfert de propriété envoyée",
    "Bạn không có quyền xoá thiết bị":
    "Vous n'avez pas l'autorisation de supprimer des appareils",
    "Xóa Device?": "Supprimer l'appareil ?",
    "Đã gửi yêu cầu xoá thiết bị":
    "Demande de suppression de l'appareil envoyée",
    "Đang xoá thiết bị": "Suppression de l'appareil",
    "Đăng xuất?": "Se déconnecter ?",
    "Thêm nhà": "Ajouter une maison",
    "Thêm nhà mới": "Ajouter une nouvelle maison",
    "Tạo nhà mới": "Créer une nouvelle maison",
    "Tạo một ngôi nhà mới của bạn": "Créer une nouvelle maison",
    "Quét mã QR được chủ nhà chia sẻ":
    "Scannez le QR partagé par le propriétaire",
    "Tên nhà": "Maison name",
    "Số điện thoại": "Numéro de téléphone",
    "Nam": "Homme",
    "Nữ": "Femme",
    "Ngày": "Jour",
    "Tháng": "Mois",
    "Năm": "Année",
    "Thông tin cá nhân": "Informations personnelles",
    "Thiết lập tài khoản": "Configurer le compte",
    "Vui lòng nhập đủ thông tin":
    "Veuillez saisir toutes les informations requises",
    "Không thể lưu thông tin": "Impossible d'enregistrer les informations",
    "Đã lưu thông tin": "Informations enregistrées",
    "Lỗi lưu profile": "Impossible d'enregistrer le profil",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp":
    "Ajoutez un numéro de téléphone pour les urgences",
    "Hoàn tất": "Terminé",
    "Đã tạo nhà mới": "Maison créée",
    "Về muộn": "Retour tardif",
    "Ra ngoài": "Sortie",
    "Khác": "Autre",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ Suspendre Alarm aujourd'hui",
    "Chọn giờ bắt đầu tạm tắt": "Choisir l'heure de début de pause",
    "Từ": "De",
    "Từ giờ": "À partir de",
    "Chọn giờ kết thúc tạm tắt": "Choisir l'heure de fin de pause",
    "Đến": "À",
    "Đến giờ": "Jusqu'à",
    "Xoá lịch tạm tắt": "Supprimer le planning de pause",
    "Xóa lịch tạm tắt": "Supprimer le planning de pause",
    "Giới tính": "Genre",
    "SĐT": "Téléphone",
    "Ngày sinh": "Date de naissance",
    "Yêu cầu & lời mời": "Demandes & invitations",
    "Xem lời mời chia sẻ và xin gia nhập":
    "View sharing invitations and join demandes",
    "Cài đặt bảo mật": "Paramètres de sécurité",
    "Quyền báo động toàn màn hình": "Autorisation d'alerte plein écran",
    "Báo động toàn màn hình": "Alerte plein écran",
    "Đã được cấp quyền": "Autorisation accordée",
    "Chưa được cấp quyền": "Autorisation non accordée",
    "Mở cài đặt hệ thống": "Ouvrir les paramètres système",
    "Đăng xuất": "Se déconnecter",
    "Thoát tài khoản khỏi thiết bị này": "Se déconnecter de cet appareil",
    "Không có yêu cầu hoặc lời mời nào": "Aucune demande ni invitation",
    "Xoá tài khoản": "Supprimer le compte",
    "Hành động này sẽ xoá toàn bộ dữ liệu:":
    "Cette action supprimera toutes les données :",
    "Nhà và thiết bị": "Maisons and appareils",
    "Chia sẻ và quyền truy cập": "Partage et accès",
    "Toàn bộ dữ liệu liên quan": "Toutes les données associées",
    "Mật khẩu xác nhận": "Confirmation du mot de passe",
    "Đã xoá tài khoản": "Compte supprimé",
    "Xoá thất bại": "Supprimer failed",
    "Lỗi xoá tài khoản": "Impossible de supprimer le compte",
    "Tình trạng": "Statut",
    "Tháo/Lắp": "Arrachement",
    "Pin": "Batterie",
    "Tín hiệu": "Niveau du signal",
    "Chưa liên kết": "Non lié",
    "Liên lạc cuối": "Dernier contact",
    "Event cuối": "Dernier événement",
    "Sự kiện cuối": "Dernier événement",
    "Lần kích hoạt cuối": "Dernière activation",
    "Thiết bị không còn tồn tại": "L'appareil n'existe plus",
    "Mất kết nối": "Déconnecté",
    "Online": "En ligne",
    "Offline": "Hors ligne",
    "Loại thiết bị": "Appareil type",
    "Nhiệt độ": "Température",
    "Độ ẩm": "Humidité",
    "Công suất": "Puissance",
    "Điện áp": "Tension",
    "Dòng điện": "Courant",
    "Điện năng": "Énergie",
    "Cường độ rung": "Intensité de vibration",
    "Góc nghiêng": "Angle d'inclinaison",
    "Độ mở van": "Valve ouverting",
    "Nguồn dự phòng": "Alimentation de secours",
    "Ngập/rò nước": "Inondation / fuite d'eau",
    "Phát hiện khói": "Fumée détectée",
    "Quản lý phòng": "Pièce management",
    "Bạn không có quyền quản lý phòng":
    "Vous n'avez pas l'autorisation de gérer les pièces",
    "Đổi tên phòng": "Rename pièce",
    "Tên phòng": "Pièce name",
    "Xoá phòng": "Supprimer pièce",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.":
    "Les appareils de cette pièce seront déplacés vers Non attribué.",
    "Thêm phòng": "Ajouter une pièce",
    "Ví dụ: Phòng khách": "Example: Living pièce",
    "Phòng khách": "Living pièce",
    "Tên phòng đã tồn tại": "Pièce name already exists",
    "Chưa phân phòng": "Non attribué",
    "Phòng mặc định": "Default pièce",
    "Phát hiện bất thường": "Anomalie détectée",
    "Phát hiện cạy phá": "Arrachement détecté",
    "Tamper detected": "Arrachement détecté",
    "Tamper cleared": "Arrachement résolu",
    "Door opened": "Porte ouverte",
    "Door closed": "Porte fermée",
    "Motion detected": "Mouvement détecté",
    "Battery low": "Batterie faible",
    "Device offline": "Appareil hors ligne",
    "Device online": "Appareil en ligne",
    "Alarm triggered": "Alarm déclenché",
    "Alarm cleared": "Alarm terminé",
    "Cửa mở": "La porte est ouverte",
    "Cửa đóng": "La porte est fermée",
    "Chưa đặt vị trí nhà": "Localisation de la maison non définie",
    "Đặt vị trí nhà tại đây": "Définir la localisation de la maison ici",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ":
    "Définissez la localisation de la maison avant d'activer le Mode protection automatique",
    "Bán kính bảo vệ mặc định: 150 m": "Rayon de protection par défaut : 150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
    "Chaque membre doit autoriser la localisation permanente pour que le statut départ/retour fonctionne en arrière-plan.",
    "Lưu cài đặt": "Enregistrer les paramètres",
    "Đã đặt vị trí nhà": "Localisation de la maison définie",
    "Đang lấy vị trí...": "Récupération de la position...",
    "Đang lưu...": "Enregistrement...",
    "Đổi tên hiển thị": "Modifier le nom affiché",
    "Cập nhật thông tin nhà": "Update maison information",
    "Nhập địa chỉ của nhà": "Saisissez l'adresse de la maison",
    "Lưu thay đổi": "Enregistrer changes",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.":
    "Ce nom n'est affiché que sur votre compte.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.":
    "Le nom et l'adresse seront mis à jour pour tous les membres de la maison.",
    "Một thành viên": "Un membre",
    "Đã cập nhật thông tin nhà": "Informations de la maison mises à jour",
    "Thay tên": "Renommer",
    "Đã đổi tên thiết bị": "Nom de l'appareil modifié",
    "Chưa chọn nhà để kiểm tra": "Select a maison to test",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner":
    "Effectuez ce test avec le compte propriétaire",
    "Không đọc được dữ liệu nhà": "Impossible de lire les données de la maison",
    "Nhà cần có ít nhất một thiết bị để test":
    "La maison doit avoir au moins un appareil pour effectuer le test",
    "Đóng": "Fermer",
    "Đã thiết lập": "Configuré",
    "Quét QR": "Scanner QR",
    "Quét QR để thêm thiết bị": "Scanner le QR pour ajouter un appareil",
    "Nhập HUB ID thủ công": "Saisir l'ID HUB manuellement",
    "Bạn không có quyền sắp xếp phòng":
    "Vous n'avez pas l'autorisation de réorganiser les pièces",
    "Cảnh báo khói": "Alerte fumée",
    "Cập nhật thiết bị": "Mise à jour de l'appareil",
    "Cửa đang mở": "La porte est ouverte",
    "Cửa đã đóng": "La porte est fermée",
    "Firebase Rules: CÓ LỖI": "Firebase Rules : problèmes détectés",
    "Firebase Rules: ĐẠT": "Firebase Rules : validées",
    "Giờ không hợp lệ": "Heure invalide",
    "Khôi phục mật khẩu": "Réinitialiser le mot de passe",
    "Nhập email của bạn": "Saisissez votre email",
    "Gửi": "Envoyer",
    "Đã gửi email khôi phục":
    "Email de réinitialisation du mot de passe envoyé",
    "Không gửi được email": "Impossible d'envoyer l'email",
    "Vui lòng nhập email và mật khẩu":
    "Saisissez votre email et votre mot de passe",
    "Mật khẩu xác nhận không khớp": "Les mots de passe ne correspondent pas",
    "Không thể tạo tài khoản": "Impossible de créer le compte",
    "Sai tài khoản": "Compte incorrect",
    "Email đã tồn tại": "Cet email existe déjà",
    "Mật khẩu quá yếu": "Le mot de passe est trop faible",
    "Sai email hoặc mật khẩu": "Email ou mot de passe incorrect",
    "Lỗi đăng nhập": "Erreur de connexion",
    "Email": "Email",
    "Mật khẩu": "Mot de passe",
    "Ghi nhớ tài khoản": "Mémoriser le compte",
    "Đăng nhập": "Se connecter",
    "Đăng ký mới": "Créer un compte",
    "Quên mật khẩu?": "Mot de passe oublié ?",
    "Chưa có tài khoản? Đăng ký": "Vous n'avez pas de compte ? Inscription",
    "Đã có tài khoản? Đăng nhập": "Vous avez déjà un compte ? Connexion",
    "Tính năng đang được phát triển":
    "Cette fonctionnalité est en cours de développement",
    "Thông báo": "Notification",
    "Chat trong nhà": "Maison chat",
    "Tìm kiếm tin nhắn": "Rechercher des messages",
    "Xem thành viên": "Voir les membres",
    "Tìm nội dung hoặc tên người gửi": "Rechercher content or sender name",
    "Xoá từ khoá": "Effacer le mot-clé",
    "Không có kết quả": "Aucun résultat",
    "Tìm ngôn ngữ": "Rechercher une langue",
    "Kết quả trước": "Résultat précédent",
    "Kết quả tiếp theo": "Résultat suivant",
    "Chưa có tin nhắn": "Aucune conversation pour le moment",
    "Không tìm thấy thành viên phù hợp": "Aucun membre correspondant trouvé",
    "Nhắc đến trong tin nhắn": "Mention dans la conversation",
    "Huỷ trả lời": "Annuler reply",
    "Nhắn gì đó...": "Écrire quelque chose...",
    "Gọi điện": "Appeler",
    "Alarm thiết bị": "Appareil Alarm",
    "Chế độ áp dụng": "Mode d'application",
    "Theo nhà": "Planning de la maison",
    "Riêng tôi": "Personnel",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
    "Utiliser le planning partagé défini par le propriétaire ou l'administrateur",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn":
    "Utiliser un planning personnel qui ne s'applique qu'à votre compte",
    "Thiết lập nhanh Alarm": "Configuration rapide Alarm",
    "Thiết lập nhanh toàn bộ thiết bị": "Configuration rapide de tous les appareils",
    "Áp dụng cho toàn bộ thiết bị": "Appliquer à tous les appareils",
    "Bắt đầu": "Début",
    "Kết thúc": "Fin",
    "Thời gian lặp lại": "Intervalle de répétition",
    "Không lặp lại": "Pas de répétition",
    "Quét QR HUB": "Scanner le QR HUB",
    "Đưa mã QR vào giữa khung": "Placez le QR au centre du cadre",
    "Đang áp dụng...": "Application...",
    "Hôm nay đã ghi nhận cảnh báo SOS": "Une alerte SOS a été enregistrée aujourd'hui",
    "Hôm nay đã ghi nhận cảnh báo khói": "Une alerte fumée a été enregistrée aujourd'hui",
    "Khói đã an toàn": "Fumée sécurisée",
    "Không tìm thấy nhà của thông báo này":
    "La maison associée à cette notification est introuvable",
    "Không tìm thấy thiết bị trong nhà này":
    "L'appareil est introuvable dans cette maison",
    "Một chủ nhà": "Un propriétaire",
    "Ngôi nhà đang hoạt động ổn định": "La maison fonctionne normalement",
    "Nhiệt độ cao": "Température élevée",
    "OK": "OK",
    "Pin yếu": "Batterie faible",
    "SOS đã kết thúc": "SOS terminé",
    "SOS được kích hoạt": "SOS déclenché",
    "Tamper bình thường": "Arrachement résolu",
    "Thiết bị bị tháo": "Appareil arraché",
    "Thiết bị mới": "Nouvel appareil",
    "Thiết bị offline": "Appareil hors ligne",
    "Thiết bị online": "Appareil en ligne",
    "Báo động kích hoạt": "Alarm déclenché",
    "Báo động đã tắt": "Alarm terminé",
    "Tạm tắt Alarm hôm nay": "Suspendre Alarm aujourd'hui",
    "Độ ẩm cao": "Humidité élevée",
    "Thử lại": "Réessayer",
    "Không thể tải dữ liệu tài khoản":
    "Impossible de charger les données du compte",
    "Không": "Non",
    "Đã chia sẻ nhà thành công.": "Maisons partagées avec succès.",
    "Tìm nhà...": "Rechercher maisons...",
    "Đã rời khỏi nhà": "Left maison",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.":
    "Vous quitterez les maisons partagées.",
    "Các nhà của bạn sẽ bị xoá.\n": "Vos maisons seront supprimées.\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n":
    "Cette action modifiera les plannings Home Alarm de tous les appareils de sécurité dans les maisons sélectionnées.\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n":
    "Cette action ajoutera un Home Reminder aux maisons sélectionnées.\n\n",
    "Xác nhận thay đổi Alarm": "Confirmer Alarm changes",
    "Xác nhận thay đổi Reminder": "Confirmer Reminder changes",
    "Lặp lại khi sự cố vẫn còn": "Répéter tant que le problème persiste",
    "Thời gian lặp lại Alarm": "Intervalle de répétition Alarm",
    "VD: Mr Chung": "Ex. : Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 Aucune maison pour le moment",
    "Vẫn chuyển về Bình thường": "Repasser quand même en Mode normal",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.":
    "La protection automatique en cas d'absence est toujours activée. Si tous les membres sont encore absents, le système peut réactiver le Mode protection après quelques minutes.",
    "Chuyển về Bình thường?": "Repasser en Mode normal ?",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n":
    "Une fois activé, les appareils de sécurité seront surveillés immédiatement.\n\n",
    "Bật Bảo vệ thủ công?": "Activer le Mode protection manuel ?",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ":
    "Cette action modifiera l'heure d'alarme de certains appareils aujourd'hui...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ":
    "Cette action désactivera toutes les Alarm de cette maison ",
    "Tắt toàn bộ Alarm?": "Désactiver toutes les Alarm ?",
    "Không xoá được lịch tạm tắt Alarm":
    "Impossible de supprimer la pause Alarm",
    "Không lưu được tạm tắt Alarm": "Impossible d'enregistrer la pause Alarm",
    "Không gửi được yêu cầu xoá":
    "Impossible d'envoyer la demande de suppression",
    "Không lưu được cài đặt": "Impossible d'enregistrer le réglage",
    "Không lấy được vị trí hiện tại":
    "Impossible d'obtenir la position actuelle",
    "Không thể xác nhận tài khoản hiện tại":
    "Impossible de confirmer le compte actuel",
    "Mật khẩu không đúng": "Mot de passe incorrect",
    "Không thể xác nhận mật khẩu": "Impossible de vérifier le mot de passe",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động":
    "Seul le Propriétaire ou un Administrateur peut modifier la répétition de l'alarme",
    "Không lưu được thời gian lặp báo động":
    "Impossible d'enregistrer l'intervalle de répétition Alarm",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ":
    "Seul le Propriétaire ou un Administrateur peut modifier le Mode protection",
    "Không thể thay đổi chế độ nhà":
    "Impossible de changer le mode de la maison",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo":
    "Le Mode protection est activé, mais la notification n'a pas pu être envoyée",
    "Đã bật Mode Bảo vệ thủ công": "Mode protection manuel activé",
    "Đã chuyển nhà về Bình thường": "La maison est repassée en Mode normal",
    "60 phút": "60 min",
    "30 phút": "30 min",
    "15 phút": "15 min",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.":
    "Vous consultez le planning du propriétaire. Choisissez Personnel pour définir votre propre planning Alarm.",
    "Chọn giờ kết thúc Alarm": "Choisir l'heure de fin Alarm",
    "Chọn giờ bắt đầu Alarm": "Choisir l'heure de début Alarm",
    "Bạn không có quyền sửa lịch Alarm của nhà":
    "Vous n'avez pas l'autorisation de modifier le planning Alarm de cette maison",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị":
    "Impossible d'appliquer Alarm à tous les appareils",
    "Nhà chưa có thiết bị an ninh để áp dụng":
    "Cette maison n'a aucun appareil de sécurité à appliquer",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.":
    "Vous n'avez pas l'autorisation de modifier le planning de la maison. Choisissez Personnel.",
    "Không thể lưu chế độ Alarm": "Impossible d'enregistrer le mode Alarm",
    "Thêm Reminder": "Ajouter un Reminder",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.":
    "Reminder vous rappellera de vérifier l'état de sécurité de la maison à l'heure sélectionnée.",
    "Thêm khung giờ Alarm": "Ajouter une plage horaire Alarm",
    "Đang sử dụng Reminder riêng của bạn":
    "Utilisation de vos paramètres Reminder personnels",
    "Đang sử dụng Reminder của chủ nhà":
    "Utilisation des paramètres Reminder du propriétaire",
    "Sửa giờ Reminder": "Modifier l'heure Reminder",
    "Sửa giờ kết thúc Alarm": "Modifier l'heure de fin Alarm",
    "Sửa giờ bắt đầu Alarm": "Modifier l'heure de début Alarm",
    "Xoá Reminder": "Supprimer Reminder",
    "Mỗi 1 giờ": "Toutes les heures",
    "Mỗi 30 phút": "Toutes les 30 minutes",
    "Mỗi 15 phút": "Toutes les 15 minutes",
    "Không báo lại": "Ne pas répéter",
    "Báo lại khi vẫn chưa an toàn": "Répéter tant que ce n'est pas sécurisé",
    "Báo lại mỗi 1 giờ": "Répéter toutes les heures",
    "Báo lại mỗi 30 phút": "Répéter toutes les 30 minutes",
    "Báo lại mỗi 15 phút": "Répéter toutes les 15 minutes",
    "Quản lý nhà": "Maison management",
    "Xoá thành viên": "Supprimer membre",
    "Đã xoá thành viên": "Membre supprimé",
    "Đồng ý": "OK",
    "Bạn chắc chắn muốn rời khỏi nhà này?":
    "Voulez-vous vraiment quitter cette maison ?",
    "Xoá thành viên?": "Supprimer membre?",
    "Rời khỏi nhà?": "Quitter la maison ?",
    "Chỉ chủ nhà mới được thay đổi vai trò":
    "Seul le propriétaire peut modifier les rôles",
    "Bạn không có quyền xoá thành viên này":
    "Vous n'avez pas l'autorisation de supprimer ce membre",
    "Bạn": "Vous",
    "Không có email": "Aucun email",
    "Chưa có số điện thoại": "Aucun numéro de téléphone",
    "Không mở được ứng dụng gọi điện":
    "Impossible d'ouvrir l'application d'appel",
    "Thành viên chưa cập nhật số điện thoại":
    "Le membre n'a pas ajouté de numéro de téléphone",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "Le Mode protection manuel est activé — il ne se désactive qu'en repassant en Mode normal",
    "Thời gian lặp": "Intervalle de répétition",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.":
    "Choisissez 0 pour alerter une seule fois. Ce paramètre s'applique au Mode protection manuel et à la protection automatique en cas d'absence.",
    "Lặp báo động khi sự cố vẫn còn":
    "Répéter Alarm tant que le problème persiste",
    "Đang được sử dụng": "Actuellement actif",
    "Chuyển về sử dụng thông thường": "Revenir à l'utilisation normale",
    "Chế độ nhà": "Mode maison",
    "Thiết bị SOS chưa ghi nhận cảnh báo.": "L'appareil SOS n'a encore enregistré aucune alerte.",
    "Cảm biến khói chưa ghi nhận bất thường.": "Le détecteur de fumée n'a détecté aucune anomalie.",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.":
    "Vous ou un membre avez activé manuellement le Mode protection.",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.":
    "SafeHome a activé automatiquement le Mode protection, car vous avez quitté la maison.",
    "Nhà đang ở chế độ dùng bình thường.":
    "Cette maison est actuellement en Mode normal.",
    "Bảo vệ thủ công đang bật": "Le Mode protection manuel est activé",
    "Bảo vệ tự động đang bật": "La protection automatique est activée",
    "Bảo vệ đang tắt": "La protection est désactivée",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.":
    "Vous avez ouvert l'application récemment pour vérifier l'état.",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.":
    "Ouvrez régulièrement l'application pour vérifier les autorisations, les plannings et les alertes non lues.",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.":
    "Après quelques utilisations, SafeHome pourra mieux évaluer votre habitude de vérification App Check.",
    "Tần suất vào app ổn": "La fréquence App Check est correcte",
    "Đã lâu chưa vào app kiểm tra":
    "La dernière vérification App Check remonte à un moment",
    "Đang ghi nhận tần suất vào app":
    "Enregistrement de la fréquence App Check",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.":
    "Vérifiez l'autorisation de localisation permanente et les conditions d'arrière-plan.",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.":
    "Cet appareil remplit les conditions pour Auto Away.",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.":
    "Activez-le si vous voulez que le Mode protection s'active automatiquement à votre départ.",
    "Auto rời khỏi nhà chưa ổn": "Auto Away n'est pas prêt",
    "Auto rời khỏi nhà đã sẵn sàng": "Auto Away est prêt",
    "Auto rời khỏi nhà chưa bật": "Auto Away n'est pas activé",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.":
    "Ajoutez un détecteur de fumée, SOS ou un appareil d'urgence adapté à votre maison.",
    "Chưa có thiết bị khẩn cấp": "Aucun appareil d'urgence pour le moment",
    "Đã có thiết bị khẩn cấp": "Des appareils d'urgence ont été ajoutés",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.":
    "Définissez un planning Alarm pour les heures de sommeil ou d'absence.",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.":
    "Cette maison dispose d'un planning Alarm ou d'un planning d'alerte par appareil.",
    "Chưa set lịch Alarm": "Le planning Alarm n'est pas défini",
    "Đã set lịch Alarm": "Le planning Alarm est défini",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.":
    "Définissez au moins un Reminder pour ne pas oublier de vérifier votre maison.",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.":
    "L'application vous rappellera de vérifier votre maison selon le planning défini.",
    "Chưa setup Reminder": "Reminder n'est pas configuré",
    "Đã setup Reminder": "Reminder est configuré",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.":
    "Rouvrez l'application ou reconnectez-vous si cet appareil ne reçoit pas les alertes.",
    "Thiết bị chưa đăng ký nhận cảnh báo":
    "Cet appareil n'est pas enregistré pour recevoir les alertes",
    "Thiết bị nhận cảnh báo bình thường":
    "Cet appareil peut recevoir les alertes",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.":
    "iOS contrôle plus strictement l'arrière-plan qu'Android ; gardez les notifications et la localisation permanente si vous utilisez Auto Away.",
    "Cơ chế iOS": "Comportement iOS",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.":
    "Vérifiez l'autorisation d'arrière-plan et le démarrage automatique pour éviter les alertes retardées.",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.":
    "The appareil has confirmed the important background conditions.",
    "Cần kiểm tra chạy nền / tự khởi động":
    "Vérifier l'arrière-plan / le démarrage automatique",
    "Chạy nền ổn định": "L'arrière-plan semble stable",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.": "Certains téléphones Android peuvent retarder les alertes si l'optimisation de la batterie est activée.",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.":
    "Le téléphone risque moins de retarder les alertes SafeHome.",
    "Chưa tắt tối ưu pin": "L'optimisation de la batterie est toujours activée",
    "Tối ưu pin không chặn app":
    "L'optimisation batterie ne bloque pas l'application",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.":
    "Auto Away nécessite la localisation permanente pour fonctionner de façon fiable.",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.":
    "L'autorisation de localisation est requise pour Auto Away.",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.":
    "Le service de localisation est désactivé, Auto Away peut donc être instable.",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.":
    "Cette autorisation n'est requise que pour Auto Away.",
    "Chưa cấp vị trí luôn luôn": "Localisation permanente non autorisée",
    "Đã cấp vị trí luôn luôn": "Localisation permanente autorisée",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.":
    "iOS n'ouvre pas d'écran plein écran comme Android ; l'application utilise les notifications et le son système.",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.":
    "Android utilise les alertes plein écran ; autorisez-les dans les paramètres si le téléphone les bloque.",
    "Cảnh báo trên iOS": "Alertes sur iOS",
    "Cảnh báo toàn màn hình": "Alerte plein écran",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.": "Les alertes peuvent ne pas s'afficher si les notifications sont désactivées.",
    "Điện thoại có thể nhận thông báo SafeHome.":
    "Ce téléphone peut recevoir les notifications SafeHome.",
    "Chưa bật thông báo": "Les notifications ne sont pas activées",
    "Đã bật thông báo": "Les notifications sont activées",
    "Hệ thống: Sẵn sàng": "Système : prêt",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "Système : des alertes peuvent être manquées",
    "Cách bạn đang dùng app": "Votre utilisation de l'application",
    "Thiết bị của bạn": "Votre appareil",
    "Kiểm tra điện thoại và cách bạn đang dùng app.":
    "Vérifie votre téléphone et votre utilisation de l'application.",
    "Hệ thống SafeHome": "Système SafeHome",
    "Hệ thống: Đang kiểm tra...": "Système : vérification...",
    "Tên": "Nom",
    "Bạn không có quyền thay đổi vị trí nhà":
    "Vous n'avez pas l'autorisation de modifier la localisation de la maison",
    "Hãy bật GPS để đặt vị trí nhà":
    "Activez le GPS pour définir la localisation de la maison",
    "Bạn chưa cấp quyền vị trí":
    "L'autorisation de localisation n'a pas été accordée",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng":
    "Accordez l'autorisation de localisation dans les paramètres de l'application",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà":
    "Protection automatique activée lorsque tout le monde quitte la maison",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà":
    "Protection automatique désactivée lorsque tout le monde quitte la maison",
    "Không thể thay đổi trạng thái Alarm": "Impossible de changer l'état Alarm",
    "Đã tắt toàn bộ Alarm của nhà": "All maison Alarms have been turned off",
    "QR này không phải mã xin gia nhập Home":
    "Ce QR n'est pas un code de demande d'accès à une maison",
    "Thêm Home": "Ajouter une maison",
    "Mở cài đặt": "Ouvrir les paramètres",
    "Để sau": "Plus tard",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.":
    "SafeHome a besoin de l'autorisation de localisation « Toujours autoriser » pour détecter vos départs et retours, même lorsque l'application fonctionne en arrière-plan.",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.":
    "SafeHome ne peut actuellement accéder à la localisation que lorsque vous utilisez l'application.\n\nOuvrez l'autorisation Localisation et choisissez « Toujours autoriser » pour que la protection automatique continue en arrière-plan.",
    "Cho phép vị trí luôn luôn": "Toujours autoriser la localisation",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.":
    "Vos maisons seront supprimées.\nVous quitterez les maisons partagées.",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.":
    "Cette action modifiera les plannings Home Alarm de tous les appareils de sécurité dans les maisons sélectionnées.\n\nLes membres utilisant Alarm « Planning de la maison » seront affectés.\nLes paramètres Alarm personnels en mode « Personnel » ne seront pas modifiés.",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.":
    "Cette action ajoutera un Home Reminder aux maisons sélectionnées.\n\nLes membres utilisant Reminder « Planning de la maison » seront affectés.\nLes paramètres Reminder personnels en mode « Personnel » ne seront pas modifiés.",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.":
    "Une fois activé, les appareils de sécurité seront surveillés immédiatement.\n\nLa protection automatique en cas d'absence sera suspendue. Ce mode ne se désactive pas automatiquement quand quelqu'un rentre à la maison ; seul un membre autorisé peut revenir au Mode normal.",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...":
    "Cette action modifiera l'heure d'alarme de certains appareils aujourd'hui...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.":
    "Cette action désactivera toutes les alarmes de la maison. Vous ne recevrez plus d'alertes de danger sur ce téléphone.",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.":
    "Alarm utilise le planning de la maison.\n\nVous recevrez les alertes selon le planning Alarm partagé défini par le propriétaire ou l’administrateur.",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.":
    "Alarm utilise mon planning personnel.\n\nVous recevrez les alertes selon le planning Alarm personnel défini pour ce compte.",
    "Không thể đăng nhập bằng Google": "Impossible de se connecter avec Google",
    "Không đặt được mật khẩu": "Impossible de définir le mot de passe",
    "Chấp nhận": "Accepter",
    "Cho phép": "Autoriser",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.":
    "Impossible d'accepter l'invitation. Veuillez réessayer.",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.":
    "Impossible d'accepter la demande d'accès. Veuillez réessayer.",
    "Từ chối": "Refuser",
    "Lời mời từ chủ nhà": "Invitation du propriétaire",
    "Nhận quyền chủ nhà": "Recevoir la propriété de la maison",
    "Một người dùng SafeHome": "Un utilisateur SafeHome",
    "Lời mời gia nhập": "Invitation à rejoindre",
    "Lời xin vào nhà": "Demande d'accès à la maison",
    "Nhập HUB ID": "Saisir l'ID HUB",
    "VD: HUB_001": "Ex. : HUB_001",
    "Pair": "Associer",
    "Mật khẩu tối thiểu 6 ký tự":
    "Le mot de passe doit contenir au moins 6 caractères",
    "Mật khẩu nhập lại không khớp": "Les mots de passe ne correspondent pas",
    "Tạo mật khẩu": "Créer un mot de passe",
    "Mật khẩu mới": "Nouveau mot de passe",
    "Nhập lại mật khẩu": "Saisir à nouveau le mot de passe",
    "Xác nhận tắt cảnh báo": "Confirmer alarm stop",
    "HỦY": "ANNULER",
    "XÁC NHẬN": "CONFIRMER",
    "CẦN KIỂM TRA": "À VÉRIFIER",
    "KIỂM TRA NHÀ": "VÉRIFIER LA MAISON",
    "ĐÓNG NHẮC NHỞ": "FERMER LE REMINDER",
    "SafeHome Security Alert": "Alerte de sécurité SafeHome",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng":
    "Choisissez l'autorisation de localisation permanente dans les paramètres de l'application",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.":
    "Le compte Google doit créer un mot de passe supplémentaire pour utiliser les fonctions de sécurité.",
    "Alarm": "Alarm",
    "Bạn không có quyền thực hiện thao tác này。":
    "Vous n'avez pas l'autorisation d'effectuer cette action.",
    "Cài đặt": "Paramètres",
    "Cập nhật": "Mettre à jour",
    "Chọn ngôn ngữ": "Choisir la langue",
    "Chưa có dữ liệu thiết bị để đánh giá":
    "Aucune donnée d'appareil disponible pour l'évaluation",
    "Chuyển quyền sở hữu cho thành viên khác": "Transférer la propriété à un autre membre",
    "Có": "Oui",
    "Cửa đã đóng an toàn": "Door safely fermé",
    "Đã xảy ra lỗi. Vui lòng thử lại.":
    "Une erreur s'est produite. Veuillez réessayer.",
    "Đang kiểm tra kết nối Hub": "Vérification de la connexion Hub",
    "Đang mở khi nhà ở chế độ Bảo vệ":
    "Ouvert pendant que la maison est en Mode protection",
    "Đang mở trong giờ Alarm": "Ouvert pendant les heures Alarm",
    "Đang tải...": "Chargement...",
    "Hồ sơ, yêu cầu và lời mời tham gia": "Profil, demandes, and invitations",
    "Hub chưa gửi trạng thái": "État Hub indisponible",
    "Hub mất kết nối": "Hub déconnecté",
    "Hub tín hiệu bình thường": "Signal Hub normal",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ":
    "La serrure est déverrouillée lorsque la maison est en Mode protection",
    "Khóa đang mở trong giờ Alarm":
    "Serrure déverrouillée pendant les heures Alarm",
    "Không có thông báo": "Aucune notification",
    "Khu vực nguy hiểm": "Zone dangereuse",
    "Kiểm tra thiết bị trong nhà này": "Examiner les appareils de cette maison",
    "Mất điện lưới": "Alimentation secteur perdue",
    "Mời người khác tham gia nhà này":
    "Inviter quelqu'un à rejoindre cette maison",
    "Môi trường hiện tại": "Environnement actuel",
    "MQTT mất kết nối": "MQTT déconnecté",
    "Ngôn ngữ": "Langue",
    "Nhà đã chia sẻ": "Partagerd maison",
    "Nhà đang hoạt động bình thường": "Maison operating normally",
    "Nhập email": "Saisir l'email",
    "Phòng": "Pièce",
    "Quản trị viên": "Administrateur",
    "Reminder": "Reminder",
    "SafeHome": "SécuriséMaison",
    "Sóng yếu": "Signal faible",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "Compte et système",
    "Tài khoản cá nhân": "Compte personnel",
    "Tạo tài khoản": "Créer un compte",
    "Thành viên": "Membre",
    "Thành viên trong nhà": "Membres de la maison",
    "Thay đổi ngôn ngữ hiển thị": "Changer la langue d'affichage",
    "Thêm, đổi tên và sắp xếp phòng":
    "Ajouter, renommer et organiser les pièces",
    "Thiết bị đang được giám sát": "Appareil surveillé",
    "Tiếng Anh": "Anglais",
    "Tiếng Hàn": "Coréen",
    "Tiếng Nhật": "Japonais",
    "Tiếng Trung": "Chinois",
    "Tiếng Việt": "Vietnamien",
    "Toàn bộ thiết bị": "Tous les appareils",
    "Vai trò": "Rôle",
    "Về nhà": "At maison",
    "Xem và quản lý quyền thành viên": "Voir et gérer les droits des membres",
    "Xóa": "Supprimer",
    "Xóa nhà": "Supprimer la maison",
    "Xoá toàn bộ dữ liệu và thiết bị":
    "Supprimer toutes les données et appareils",
    "TẮT CẢNH BÁO": "ARRÊTER L'ALERTE",
    "Đã tạo nhà": "Maison créée",

    "Mode Bảo vệ thủ công đã bật": "Mode protection manuel activé",
    "Báo động không lặp lại.": "L'alarme ne se répétera pas.",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.":
    "L'alarme se répétera après \$securityModeRepeatMinutes minutes si le problème persiste.",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage":
    "\$actorName a activé le Mode protection manuel pour « \$homeName ». Ce mode ne se désactive que lorsqu'un membre autorisé revient au Mode normal. \$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".":
    "Vous avez activé Alarm pour « \$homeName ».",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".":
    "Vous avez désactivé tous les Alarm de « \$homeName ».",
    "Thành viên mới": "Nouveau membre",
    "Thành viên rời nhà": "Membre parti",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".":
    "\$displayMemberName a quitté « \$homeName ».",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".":
    "\$actorName a changé le rôle de \$memberName de \$oldRoleName à \$newRoleName dans « \$homeName ».",
    "Còn \$count tin nhắn chưa đọc": "\$count messages non lus",
    "Hãy an tâm nghỉ ngơi.": "Vous pouvez vous reposer sereinement.",
    "Có thiết bị chưa an toàn.": "Certains appareils ne sont pas sécurisés.",
    "SafeHome đang cập nhật vị trí": "SafeHome met à jour la position",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.":
    "Surveillance en cours pour activer automatiquement le Mode protection.",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.":
    "Utilise la localisation pour activer automatiquement le Mode protection lorsque tout le monde quitte la maison.",
    "CẢNH BÁO SOS": "ALERTE SOS",
    "CẢNH BÁO KHÓI / CHÁY": "ALERTE FUMÉE / INCENDIE",
    "CẢNH BÁO NGẬP NƯỚC": "ALERTE INONDATION",
    "CẢNH BÁO RÒ KHÍ": "ALERTE FUITE DE GAZ",
    "CẢNH BÁO CỬA": "ALERTE PORTE",
    "CẢNH BÁO AN NINH": "ALERTE SÉCURITÉ",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.":
    "Impossible de confirmer avec SafeHome. Vérifiez votre connexion et réessayez.",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?":
    "Arrêtez l'alerte uniquement après avoir vérifié l'état de la maison.\n\nVoulez-vous vraiment arrêter l'alerte ?",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome a détecté une alerte",
    "Mở SafeHome để kiểm tra ngay.":
    "Ouvrez SafeHome pour vérifier maintenant.",
    "\$count tin nhắn mới": "\$count nouveaux messages",
    "Tin nhắn HomeChat": "Notification HomeChat",
    "\$senderName đã gửi một tin nhắn": "\$senderName vous a écrit",
    "Bạn có tin nhắn mới": "Vous avez une nouvelle notification",
    "Mode Bảo vệ sẽ chỉ báo động một lần":
    "Le Mode protection n'alertera qu'une seule fois",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút":
    "Le Mode protection répétera l'alerte après \$minutes minutes",
    "Đã gửi yêu cầu gia nhập \$count nhà":
    "Demandes d'accès envoyées pour \$count maisons",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".":
    "\$requesterName demande à rejoindre « \$homeName ».",
    "Bạn đã xoá nhà \"\$homeName\".": "Vous avez supprimé « \$homeName ».",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.":
    "Vous avez envoyé une demande de transfert de propriété de « \$homeName » à \$email.",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.":
    "\$actorName souhaite vous transférer la propriété de « \$homeName ».",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".":
    "\$actorName vous a invité à rejoindre « \$homeName ».",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".":
    "SafeHome supprime l'appareil « \$deviceName » de « \$homeName ».",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".":
    "L'appareil « \$deviceName » est apparu dans « \$homeName ».",
    "Bạn đã tạo nhà \"\$name\".": "Vous avez créé « \$name ».",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.":
    "\$actorName a renommé la maison en « \$newName » et a modifié son adresse.",
    "\$actorName đã đổi tên nhà thành \"\$newName\".":
    "\$actorName a renommé la maison en « \$newName ».",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".":
    "\$actorName a mis à jour l'adresse de « \$newName ».",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".":
    "\$actorName a renommé l'appareil « \$oldDeviceName » en « \$newName » dans « \$homeName ».",
    "Đang ghép nối: \$seconds giây": "Appairage : \$seconds s",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.":
    "L'appairage des appareils a été activé dans « \$homeName » pendant \$seconds secondes.",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)":
    "La période de pause doit être dans le planning Alarm (\$start → \$end)",
    "\$passCount/\$total bài test đạt\n\n":
    "\$passCount/\$total tests réussis\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.":
    "\$name n'a pas ajouté de numéro de téléphone à son profil.",
    "Tin nhắn mới trong \$homeName": "Nouvelle notification dans \$homeName",
    "\$current/\$total kết quả": "\$current/\$total résultats",
    "Đang trả lời \$name": "Réponse à \$name",
    "\"\$name\" phát hiện khói trong \"\$homeName\".":
    "« \$name » a détecté de la fumée dans « \$homeName ».",
    "\"\$name\" đã trở lại trạng thái bình thường.":
    "« \$name » est revenu à l'état normal.",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".":
    "« \$name » a déclenché SOS dans « \$homeName ».",
    "\"\$name\" đã hết trạng thái SOS.": "« \$name » n'est plus en état SOS.",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".":
    "« \$name » a signalé une tentative de sabotage dans « \$homeName ».",
    "\"\$name\" đã hết cảnh báo tháo/cạy.":
    "L'alerte sabotage de « \$name » est terminée.",
    "\"\$name\" đã đóng trong \"\$homeName\".":
    "« \$name » est fermé dans « \$homeName ».",
    "\"\$name\" đang mở trong \"\$homeName\".":
    "« \$name » est ouvert dans « \$homeName ».",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.":
    "La batterie de « \$name » dans « \$homeName » est faible.",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.":
    "« \$name » dans « \$homeName » est hors ligne.",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.":
    "« \$name » dans « \$homeName » est de nouveau en ligne.",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".":
    "« \$name » a relevé une température élevée dans « \$homeName ».",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".":
    "« \$name » a relevé une humidité élevée dans « \$homeName ».",
    "Có nút SOS vừa được kích hoạt": "Un bouton SOS vient d'être déclenché",
    "Có dấu hiệu khói hoặc cháy": "De la fumée ou un incendie a été détecté",
    "Có dấu hiệu ngập nước": "Une inondation a été détectée",
    "Có dấu hiệu rò khí": "Une fuite de gaz a été détectée",
    "Có cửa đang mở hoặc thiết bị bị tháo":
    "Une porte est ouverte ou un appareil a été saboté",
    "Có thiết bị đang cảnh báo": "Un appareil est en alerte",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.":
    "Si personne ne confirme, SafeHome passera à un appel d'urgence.",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.":
    "Nouvelle alerte à \$time si le problème n'a pas été traité.",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.":
    "Nouvelle alerte selon le planning Alarm si le problème n'a pas été traité.",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".":
    "« \$deviceName » est fermé dans « \$resolvedHomeName ».",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".":
    "« \$deviceName » est ouvert dans « \$resolvedHomeName ».",
    "\$count nhà đã chọn": "\$count maisons sélectionnées",
    "🚨 \$count nhà không an toàn\$suffix":
    "🚨 \$count maisons non sécurisées\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix":
    "⚠️ \$count maisons nécessitent une attention\$suffix",
    "✅ \$count nhà an toàn": "✅ \$count maisons sécurisées",
    "\$count nhà đang được theo dõi": "\$count maisons surveillées",
    "\$minutes phút": "\$minutes min",
    "Đã cài Reminder cho \$updatedHomes nhà.":
    "Reminder a été configuré pour \$updatedHomes maisons.",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n":
    "Alarm a été configuré pour \$updatedDevices appareils dans \$updatedHomes maisons.\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.":
    "Les maisons que vous gérez ont été partagées.\n\n\$skipped maisons ont été ignorées car vous n'avez pas l'autorisation de partage.",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh":
    "Alarm appliqué à \$count appareils de sécurité",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh":
    "Appliquer le même planning à \$count appareils de sécurité",
    "\$count phút trước": "Il y a \$count minutes",
    "\$count giờ trước": "Il y a \$count heures",
    "\${count}h trước": "Il y a \${count} h",
    "\${hours}h\$minutes' trước": "Il y a \${hours} h \$minutes min",
    "\$count ngày trước": "Il y a \$count jours",
    "\$count tháng trước": "Il y a \$count mois",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?":
    "Voulez-vous vraiment supprimer \$name de cette maison ?",
    "\$targetEmail\nXin gia nhập \"\$homeName\"":
    "\$targetEmail\nDemande à rejoindre « \$homeName »",
    "Xin gia nhập \"\$homeName\"": "Demande à rejoindre « \$homeName »",
    "Bạn được mời nhận quyền nhà \"\$homeName\"":
    "Vous êtes invité à recevoir la propriété de « \$homeName »",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"":
    "\$ownerEmail\nVous invite à rejoindre « \$homeName »",
    "Mời bạn gia nhập \"\$homeName\"": "Vous invite à rejoindre « \$homeName »",
    "Cần kiểm tra: \$joined": "À vérifier : \$joined",
    "Cập nhật \$value": "Mis à jour \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.":
    "Ajoutez votre premier appareil SafeHome pour commencer à surveiller cette maison.",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.":
    "Vérifiez d'abord les alertes d'urgence, puis contactez les membres de la maison si nécessaire.",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.":
    "Aucun membre n'est à la maison mais une porte ou une serrure est ouverte. Vérifiez immédiatement.",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.":
    "Vérifiez la porte ou la serrure ouverte avant de garder la maison en Mode protection.",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.":
    "Quelqu'un peut encore être à la maison ; si c'est le cas, repassez en Mode normal.",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.":
    "Certains membres ont une position inconnue. Demandez-leur d'ouvrir l'application ou de vérifier l'autorisation de localisation.",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.":
    "Un appareil est déconnecté. Vérifiez sa batterie, son alimentation ou son emplacement.",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.":
    "Un appareil a une batterie faible. Remplacez-la bientôt pour éviter de manquer des alertes.",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.":
    "Reminder n'est pas défini. Créez un planning pour vérifier régulièrement la maison.",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.":
    "Le planning Alarm n'est pas défini. Activez la protection aux moments où vous êtes habituellement absent.",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.":
    "Aucune action immédiate n'est nécessaire. Continuez simplement à surveiller cette maison.",
    "Lặp sau \$minutes phút": "Répéter après \$minutes minutes",
    "Đang dùng • \$repeatText": "Actif • \$repeatText",
    "Giám sát an ninh • \$repeatText":
    "Surveillance de sécurité • \$repeatText",
    "Gia đình: \$mode": "Mode maison : \$mode",
    "Gợi ý xử lý": "Actions suggérées",
    "Phát hiện \$count vấn đề cần xử lý":
    "\$count problèmes nécessitent une attention",
    "Hôm nay các cửa đã được sử dụng \$count lần":
    "Les portes ont été utilisées \$count fois aujourd'hui",
    "Đã ghi nhận \$count hoạt động gần đây":
    "\$count activités récentes enregistrées",
    "Hệ thống: Cần kiểm tra \$issueCount mục":
    "Système : \$issueCount éléments à vérifier",
    "FCM token đã sẵn sàng trên điện thoại này.":
    "Le token FCM est prêt sur ce téléphone.",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.":
    "Le token FCM est prêt, mais Auto Away manque encore une condition.",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.":
    "\$emergencyTotal appareils d'urgence détectés. Minimum recommandé : détecteur de fumée et SOS.",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?":
    "Transférer la propriété de la maison à :\n\$targetEmail ?",
    "\$count cửa đã đóng an toàn": "\$count portes fermées en sécurité",
    "\$count cửa và khóa đã an toàn": "\$count portes et serrures sécurisées",
    "\$count thiết bị đang được theo dõi": "\$count appareils surveillés",
    "Cập nhật \$timeText": "Mis à jour \$timeText",
    "Dữ liệu gần nhất cập nhật \$count phút trước":
    "Dernières données mises à jour il y a \$count minutes",
    "Dữ liệu gần nhất cập nhật \$count giờ trước":
    "Dernières données mises à jour il y a \$count heures",
    "Thành viên trong nhà: \$count": "Membres à la maison : \$count",
    "Thành viên bên ngoài: \$count": "Membres absents : \$count",
    "Chưa xác định vị trí: \$count": "Position inconnue : \$count",
    "Môi trường hiện tại: \$environment":
    "Environnement actuel : \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ":
    "\$name : ouvert alors que la maison est en Mode protection",
    "An tâm hơn trong từng ngôi nhà": "Plus de sérénité dans chaque maison",
    "Báo động SafeHome": "Alarm SafeHome",
    "Có cảnh báo an ninh cần kiểm tra ngay.":
    "Une alerte de sécurité nécessite votre attention immédiate.",
    "Có cảnh báo cần kiểm tra": "Une alerte nécessite votre attention",
    "Tự đóng sau \$time": "Fermeture automatique dans \$time",
  };

  static const Map<String, String> _spanish = {
    "Không tìm thấy người dùng": "Usuario no encontrado",
    "Không đọc được số điện thoại": "No se pudo leer el número de teléfono",
    "Tin nhắn quá dài": "El mensaje es demasiado largo",
    "Không gửi được tin nhắn": "No se pudo enviar el mensaje",
    "Bạn không có quyền sửa lịch chung của nhà":
    "No tienes permiso para editar la programación compartida de la casa",
    "Nhà của bạn": "Tu casa",
    "Tải tin cũ hơn": "Cargar mensajes anteriores",
    "Nhà chưa đặt tên": "Casa sin nombre",
    "Nhà": "Casa",
    "Chưa có thông tin": "Sin información disponible",
    "Chưa cập nhật": "Sin actualizar",
    "Chủ nhà": "Propietario",
    "Nhà được chia sẻ": "Casa compartida",
    "Địa chỉ": "Dirección",
    "An ninh ra/vào": "Seguridad de acceso",
    "Nguy hiểm khẩn cấp": "Riesgos de emergencia",
    "Điều khiển & hạ tầng": "Control e infraestructura",
    "Môi trường": "Entorno",
    "Toàn bộ thiết bị SafeHome": "Todos los dispositivos SafeHome",
    "Cửa ra/vào": "Puerta de acceso",
    "Cửa": "Puerta",
    "Cửa sổ": "Ventana",
    "Cổng": "Portón",
    "Khóa thông minh": "Cerradura inteligente",
    "Chuyển động": "Movimiento",
    "Hiện diện": "Presencia",
    "Rung/chấn động": "Vibración",
    "Kính vỡ": "Cristal roto",
    "Báo khói": "Detector de humo",
    "Báo nhiệt": "Detector de calor",
    "Khí CO": "CO",
    "Báo gas": "Alarma de gas",
    "Báo ngập/rò nước": "Alarma de inundación/fuga de agua",
    "Nút SOS": "Botón SOS",
    "Nhiệt độ/Độ ẩm": "Temperatura/Humedad",
    "Bụi mịn PM2.5": "Partículas finas PM2.5",
    "CO₂": "CO₂",
    "Chất lượng không khí": "Calidad del aire",
    "Ổ điện thông minh": "Enchufe inteligente",
    "Còi báo động": "Sirena",
    "Van thông minh": "Válvula inteligente",
    "Camera": "Camera",
    "Chuông cửa": "Timbre",
    "Bàn phím an ninh": "Teclado de seguridad",
    "Bộ mở rộng sóng": "Repetidor",
    "Hub trung tâm": "Hub central",
    "Đo điện năng": "Medidor de energía",
    "Nguồn dự phòng UPS": "Alimentación de respaldo UPS",
    "Thiết bị đang Offline": "El dispositivo está sin conexión",
    "Thiết bị đang Online": "El dispositivo está conectado",
    "pin yếu": "batería baja",
    "sóng yếu": "señal débil",
    "lâu không phản hồi": "sin respuesta",
    "Kết nối cần kiểm tra": "La conexión requiere revisión",
    "Vừa xong": "Ahora mismo",
    "Bị tháo": "Manipulación detectada",
    "Có khói": "Humo detectado",
    "Bình thường": "Modo normal",
    "Bảo vệ": "Modo protección",
    "Chế độ Bảo vệ": "Modo protección",
    "Tự động Bảo vệ khi rời nhà": "Protección automática al salir",
    "Đã kích hoạt": "Activado",
    "Sẵn sàng": "Listo",
    "Đang đóng": "Cerrado",
    "Đang mở": "Abierto",
    "Rò rỉ gas": "Fuga de gas detectada",
    "Phát hiện ngập nước": "Fuga de agua detectada",
    "Phát hiện chuyển động": "Movimiento detectado",
    "Không có chuyển động": "No se detecta movimiento",
    "Phát hiện hiện diện": "Presencia detectada",
    "Không phát hiện hiện diện": "No se detecta presencia",
    "Phát hiện rung/chấn động": "Vibración detectada",
    "Không có rung bất thường": "Sin vibración anormal",
    "Phát hiện kính vỡ": "Cristal roto detectado",
    "Không có cảnh báo kính vỡ": "Sin alerta de cristal roto",
    "Nhiệt độ nguy hiểm": "Calor peligroso detectado",
    "Phát hiện khí CO": "Monóxido de carbono detectado",
    "Không phát hiện khí CO": "No se detecta monóxido de carbono",
    "Khóa đang mở": "Desbloqueado",
    "Khóa đang đóng": "Bloqueado",
    "Đang bật": "Activado",
    "Đang tắt": "Desactivado",
    "Đang theo dõi điện năng": "Supervisando energía",
    "Đang dùng nguồn dự phòng": "Usando alimentación de respaldo",
    "Nguồn điện bình thường": "Alimentación principal normal",
    "Còi đang bật": "Sirena activa",
    "Còi sẵn sàng": "Sirena lista",
    "Van đang mở": "Válvula abierta",
    "Van đã đóng": "Válvula cerrada",
    "Đang hoạt động": "En funcionamiento",
    "Đang theo dõi": "Supervisando",
    "Chưa nhận diện": "Dispositivo no reconocido",
    "Chưa có cập nhật": "Sin actualizaciones",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh":
    "Aún no hay dispositivos. Toca + para añadir uno y empezar a proteger tu casa.",
    "CHƯA AN TOÀN": "NO SEGURO",
    "CẦN CHÚ Ý": "REQUIERE ATENCIÓN",
    "ĐÃ AN TOÀN": "SEGURO",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
    "Tu casa requiere atención. Revisa los estados a continuación.",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.":
    "Tu casa funciona con normalidad. Puedes estar tranquilo.",
    "Không có dấu hiệu khói hoặc SOS bất thường.":
    "No se detectó actividad inusual de humo o SOS.",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.":
    "Aún no hay muchas actividades nuevas para analizar.",
    "Hub kết nối bình thường": "Hub conectado correctamente",
    "Cài đặt cảnh báo cho nhà hiện tại": "Ajustes de alertas de esta casa",
    "Nhận cảnh báo Alarm": "Recibir alertas Alarm",
    "Đang bật cho tài khoản này": "Activado para esta cuenta",
    "Đang tắt cho tài khoản này": "Desactivado para esta cuenta",
    "Hẹn giờ Reminder": "Programación Reminder",
    "Nhắc kiểm tra nhà theo thời gian":
    "Programar recordatorios para revisar la casa",
    "Hẹn giờ Alarm": "Programar Alarm",
    "Chưa thiết lập": "No configurado",
    "Chưa thiết lập thời gian": "Sin horario configurado",
    "Tổng hợp trạng thái nhà": "Resumen del estado de la casa",
    "Cần xử lý ngay": "Acción requerida",
    "Cần kiểm tra": "Requiere revisión",
    "Đánh giá tự động": "Evaluación automática",
    "Tự động đánh giá": "Evaluación automática",
    "Tổng quan hôm nay": "Resumen de hoy",
    "Chưa có dữ liệu tổng quan": "Aún no hay datos de resumen",
    "Chưa có dữ liệu trạng thái": "Aún no hay datos de estado",
    "Chưa đủ dữ liệu để đánh giá": "No hay datos suficientes para evaluar",
    "Chưa có dữ liệu để đánh giá": "No hay datos suficientes para evaluar",
    "Bấm vào để xem chi tiết": "Toca para ver detalles",
    "Nhấn để xem chi tiết...": "Toca para ver detalles...",
    "Tạm dừng": "Pausado",
    "Tắt": "Desactivado",
    "Chi tiết": "Detalles",
    "Tổng hợp trạng thái": "Resumen de estado",
    "Không an toàn": "No seguro",
    "Cần chú ý": "Requiere atención",
    "An toàn": "Seguro",
    "Không có": "Ninguno",
    "Đổi tên nhóm": "Cambiar nombre del grupo",
    "Huỷ": "Cancelar",
    "Hủy": "Cancelar",
    "Lưu": "Guardar",
    "Thêm": "Añadir",
    "Xoá": "Eliminar",
    "Đổi tên": "Cambiar nombre",
    "Nhà của tôi": "Mis casas",
    "Bỏ chọn toàn bộ nhóm": "Deseleccionar todo el grupo",
    "Chọn toàn bộ nhóm": "Seleccionar todo el grupo",
    "Bỏ chọn": "Deseleccionar",
    "Quay lại": "Volver",
    "Tìm kiếm": "Buscar",
    "Đóng tìm kiếm": "Cerrar búsqueda",
    "Giờ": "Hora",
    "Phút": "Minuto",
    "Đặt Home Reminder": "Configurar Home Reminder",
    "Đặt Home Alarm": "Configurar Home Alarm",
    "Xác nhận thay đổi": "Confirmar cambios",
    "Tiếp tục": "Continuar",
    "Giờ Reminder": "Hora de Reminder",
    "Giờ bắt đầu Alarm": "Hora de inicio de Alarm",
    "Giờ kết thúc Alarm": "Hora de fin de Alarm",
    "Không có nhà nào đủ điều kiện để cài": "No se encontraron casas aptas",
    "Cài đặt hoàn tất": "Configuración completada",
    "Xác nhận rời nhà": "Confirmar salida de la casa",
    "Xác nhận xoá nhà": "Confirmar eliminación de la casa",
    "Nhập mật khẩu": "Introducir contraseña",
    "Mật khẩu tài khoản": "Contraseña de la cuenta",
    "Rời khỏi nhà": "Salir de la casa",
    "Xoá nhà": "Eliminar casa",
    "Sai mật khẩu": "Contraseña incorrecta",
    "Đã rời khỏi home": "Has salido de la casa",
    "Đã cập nhật": "Actualizado",
    "Tìm home...": "Buscar casas...",
    "Đặt vị trí nhà và bật bảo vệ tự động":
    "Establecer la ubicación de la casa y activar la protección automática",
    "Chuyển quyền chủ nhà hoặc xoá nhà":
    "Transferir la propiedad de la casa o eliminar la casa",
    "Đặt Reminder / Alarm nhà đã chọn": "Configurar Reminder / Alarm para las casas seleccionadas",
    "Chia sẻ nhà đã chọn": "Compartir casas seleccionadas",
    "Mở danh sách chia sẻ nhà": "Abrir lista de casas compartidas",
    "Xoá các nhà đã chọn?": "¿Eliminar las casas seleccionadas?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.":
    "Las casas seleccionadas se eliminarán permanentemente.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn":
    "O escanea un código QR para solicitar acceso a las casas seleccionadas",
    "Email người nhận": "Email del destinatario",
    "Chia sẻ": "Compartir",
    "Email chưa đăng ký": "El Email no está registrado",
    "Chia sẻ hoàn tất": "Compartido correctamente",
    "Mở List chia sẻ nhà": "Abrir lista de casas compartidas",
    "Không có nhà nào bạn có quyền quản lý":
    "No tienes ninguna casa que puedas administrar.",
    "Chưa share cho ai": "Aún no se ha compartido con nadie",
    "Tìm nhà": "Buscar casas",
    "Xoá các nhà đã chọn ?": "¿Eliminar las casas seleccionadas?",
    "Thông báo Home": "Notificaciones Home",
    "Thông báo nhà": "Notificaciones de la casa",
    "Vai trò thành viên đã thay đổi": "El rol del miembro cambió",
    "Xoá tất cả thông báo?": "¿Eliminar todas las notificaciones?",
    "Toàn bộ thông báo nhà sẽ bị xoá.":
    "Todas las notificaciones de la casa se eliminarán.",
    "Chưa có thông báo nào": "Aún no hay notificaciones",
    "Chưa có thông báo": "Sin notificaciones",
    "Vuốt lên để tải thêm": "Desliza hacia arriba para cargar más",
    "Không có thiết bị": "Sin dispositivos",
    "Chỉ chủ nhà mới được xoá nhà":
    "Solo el propietario puede eliminar esta casa",
    "Chỉ chủ nhà mới được chuyển quyền":
    "Solo el propietario puede transferir la propiedad",
    "Lưu ý khi bật Alarm": "Nota al activar Alarm",
    "Alarm đã được bật": "Alarm activado",
    "Đã hiểu": "Entendido",
    "Lưu ý tạm tắt Alarm": "Nota al pausar Alarm",
    "Đã bật Alarm": "Alarm activado",
    "Đã tắt Alarm": "Alarm desactivado",
    "Tắt Alarm": "Desactivar Alarm",
    "Cả ngày": "Todo el día",
    "Bạn không có quyền thực hiện thao tác này.":
    "No tienes permiso para realizar esta acción.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.":
    "No se pudo completar la acción. Inténtalo de nuevo.",
    "QR gia nhập nhiều nhà không hợp lệ": "Código QR para unirse a varias casas no válido",
    "Bạn đang là chủ các nhà này": "Eres propietario de estas casas.",
    "Một người dùng": "Un usuario",
    "Yêu cầu gia nhập nhà": "Solicitud para unirse a la casa",
    "Đã gửi yêu cầu gia nhập nhà": "Solicitud para unirse enviada",
    "QR gia nhập không hợp lệ": "El QR para unirse no es válido",
    "Bạn đang là chủ nhà này": "Ya eres propietario de esta casa.",
    "QR này không phải mã xin gia nhập nhà":
    "Este código QR no es un código para solicitar acceso a la casa.",
    "Bạn không có quyền thêm thiết bị":
    "No tienes permiso para añadir dispositivos",
    "Đã mở chế độ thêm thiết bị": "Emparejamiento de dispositivos activado",
    "Rời khỏi Home này?": "¿Salir de esta casa?",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.":
    "Esta casa y todos sus dispositivos se eliminarán permanentemente.",
    "Đã xoá nhà": "Casa eliminada",
    "QR của nhà này": "Código QR de esta casa",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.":
    "Otras personas pueden escanear este código para solicitar acceso a la casa.",
    "Chia sẻ nhà": "Compartir casa",
    "Quét QR để xin gia nhập nhà":
    "Escanear QR para solicitar acceso a la casa",
    "Quét QR xin gia nhập nhà":
    "Escanear QR para unirse a la casa",
    "Đưa mã QR chia sẻ nhà vào khung hình":
    "Coloca el QR compartido de la casa dentro del marco",
    "Mã QR này do chủ nhà chia sẻ":
    "Este QR lo comparte el propietario de la casa",
    "Nhập mã mời": "Introducir código de invitación",
    "Gửi yêu cầu gia nhập": "Enviar solicitud de unión",
    "QR này không phải mã thiết bị":
    "Este QR no es un código de dispositivo",
    "Xin gia nhập nhà": "Solicitar acceso a la casa",
    "Quét mã QR chia sẻ nhà": "Escanear un código QR para compartir la casa",
    "Mời thành viên bằng mã QR": "Invitar a un miembro mediante código QR",
    "Không thể share cho chính bạn": "No puedes compartir contigo mismo.",
    "Lời mời chia sẻ nhà": "Invitación para compartir la casa",
    "Đã share home": "Casa compartida",
    "Chuyển quyền chủ nhà": "Transferir propiedad",
    "Không thể chuyển quyền cho chính bạn":
    "No puedes transferirte la propiedad a ti mismo.",
    "Không tìm thấy user": "No se encontró el usuario",
    "Không tìm thấy tài khoản": "Cuenta no encontrada",
    "Xác nhận chuyển quyền": "Confirmar transferencia de propiedad",
    "Chuyển": "Transferir",
    "Xác nhận mật khẩu": "Confirmar contraseña",
    "Xác nhận": "Confirmar",
    "Yêu cầu chuyển quyền chủ nhà": "Solicitud de transferencia de propiedad",
    "Đã gửi yêu cầu chuyển quyền": "Solicitud de transferencia enviada",
    "Đã gửi yêu cầu chuyển quyền chủ nhà":
    "Solicitud de transferencia de propiedad enviada",
    "Bạn không có quyền xoá thiết bị":
    "No tienes permiso para eliminar dispositivos",
    "Xóa Device?": "Eliminar este dispositivo?",
    "Đã gửi yêu cầu xoá thiết bị":
    "Solicitud de eliminación del dispositivo enviada",
    "Đang xoá thiết bị": "Deleting dispositivo",
    "Đăng xuất?": "¿Cerrar sesión?",
    "Thêm nhà": "Añadir una casa",
    "Thêm nhà mới": "Añadir una nueva casa",
    "Tạo nhà mới": "Crear una nueva casa",
    "Tạo một ngôi nhà mới của bạn": "Crear una nueva casa",
    "Quét mã QR được chủ nhà chia sẻ":
    "Escanea el QR compartido por el propietario",
    "Tên nhà": "Nombre de la casa",
    "Số điện thoại": "Número de teléfono",
    "Nam": "Hombre",
    "Nữ": "Mujer",
    "Ngày": "Día",
    "Tháng": "Mes",
    "Năm": "Año",
    "Thông tin cá nhân": "Información personal",
    "Thiết lập tài khoản": "Configurar cuenta",
    "Vui lòng nhập đủ thông tin": "Introduce toda la información",
    "Không thể lưu thông tin": "No se pudo guardar la información.",
    "Đã lưu thông tin": "Information guardard",
    "Lỗi lưu profile": "No se pudo guardar el perfil.",
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp":
    "Añadir a número de teléfono for emergencies",
    "Hoàn tất": "Completar",
    "Đã tạo nhà mới": "Casa creada",
    "Về muộn": "Llegar tarde",
    "Ra ngoài": "Salir",
    "Khác": "Otro",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ Pausar Alarm hoy",
    "Chọn giờ bắt đầu tạm tắt": "Elegir hora de inicio de la pausa",
    "Từ": "Desde",
    "Từ giờ": "Desde la hora",
    "Chọn giờ kết thúc tạm tắt": "Elegir hora de fin de la pausa",
    "Đến": "Hasta",
    "Đến giờ": "Hasta la hora",
    "Xoá lịch tạm tắt": "Eliminar pause programación",
    "Xóa lịch tạm tắt": "Eliminar pause programación",
    "Giới tính": "Género",
    "SĐT": "Teléfono",
    "Ngày sinh": "Fecha de nacimiento",
    "Yêu cầu & lời mời": "Solicitudes e invitaciones",
    "Xem lời mời chia sẻ và xin gia nhập":
    "Ver invitaciones compartidas y solicitudes para unirse",
    "Cài đặt bảo mật": "Configuración de seguridad",
    "Quyền báo động toàn màn hình": "Permiso de alarma de pantalla completa",
    "Báo động toàn màn hình": "Alarma de pantalla completa",
    "Đã được cấp quyền": "Permiso granted",
    "Chưa được cấp quyền": "Permiso no concedido",
    "Mở cài đặt hệ thống": "Abrir system ajustes",
    "Đăng xuất": "Cerrar sesión",
    "Thoát tài khoản khỏi thiết bị này": "Sign out of este dispositivo",
    "Không có yêu cầu hoặc lời mời nào": "No hay solicitudes ni invitaciones",
    "Xoá tài khoản": "Eliminar cuenta",
    "Hành động này sẽ xoá toàn bộ dữ liệu:":
    "Esta acción eliminará todos los datos:",
    "Nhà và thiết bị": "Casas y dispositivos",
    "Chia sẻ và quyền truy cập": "Compartir y acceso",
    "Toàn bộ dữ liệu liên quan": "All related datos",
    "Mật khẩu xác nhận": "Confirmaration contraseña",
    "Đã xoá tài khoản": "Cuenta eliminado",
    "Xoá thất bại": "Eliminar failed",
    "Lỗi xoá tài khoản": "No se pudo eliminar la cuenta.",
    "Tình trạng": "Estado",
    "Tháo/Lắp": "Manipulación/instalación",
    "Pin": "Batería",
    "Tín hiệu": "Señal",
    "Chưa liên kết": "Sin vincular",
    "Liên lạc cuối": "Última comunicación",
    "Event cuối": "Último evento",
    "Sự kiện cuối": "Último evento",
    "Lần kích hoạt cuối": "Última activación",
    "Thiết bị không còn tồn tại": "El dispositivo ya no existe",
    "Mất kết nối": "Desconectado",
    "Online": "Conectado",
    "Offline": "Sin conexión",
    "Loại thiết bị": "Dispositivo type",
    "Nhiệt độ": "Temperatura",
    "Độ ẩm": "Humedad",
    "Công suất": "Energía",
    "Điện áp": "Voltaje",
    "Dòng điện": "Corriente",
    "Điện năng": "Energía",
    "Cường độ rung": "Intensidad de vibración",
    "Góc nghiêng": "Ángulo de inclinación",
    "Độ mở van": "Valve abriring",
    "Nguồn dự phòng": "Backup energía",
    "Ngập/rò nước": "Agua leak",
    "Phát hiện khói": "Humo detectado",
    "Quản lý phòng": "Habitación management",
    "Bạn không có quyền quản lý phòng":
    "No tienes permiso para administrar habitaciones.",
    "Đổi tên phòng": "Rename habitación",
    "Tên phòng": "Habitación name",
    "Xoá phòng": "Eliminar habitación",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.":
    "Los dispositivos de esta habitación se moverán a Sin asignar.",
    "Thêm phòng": "Añadir habitación",
    "Ví dụ: Phòng khách": "Example: Living habitación",
    "Phòng khách": "Living habitación",
    "Tên phòng đã tồn tại": "El nombre de la habitación ya existe",
    "Chưa phân phòng": "Sin habitación asignada",
    "Phòng mặc định": "Default habitación",
    "Phát hiện bất thường": "Anomalía detectada",
    "Phát hiện cạy phá": "Anomalía detectada",
    "Tamper detected": "Manipulación detectada",
    "Tamper cleared": "Manipulación resuelta",
    "Door opened": "La puerta está abierta",
    "Door closed": "La puerta está cerrada",
    "Motion detected": "Movimiento detectado",
    "Battery low": "Batería baja",
    "Device offline": "Dispositivo sin conexión",
    "Device online": "Dispositivo conectado",
    "Alarm triggered": "Alarm activado",
    "Alarm cleared": "Alarm desactivado",
    "Cửa mở": "La puerta está abierta",
    "Cửa đóng": "La puerta está cerrada",
    "Chưa đặt vị trí nhà": "Ubicación de la casa no establecida",
    "Đặt vị trí nhà tại đây": "Establecer la ubicación de la casa aquí",
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ":
    "Establece la ubicación de la casa antes de activar el modo protección automático",
    "Bán kính bảo vệ mặc định: 150 m":
    "Radio de protección predeterminado: 150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
    "Cada miembro debe conceder el permiso de ubicación «Siempre permitido» para que el estado de salida/llegada funcione en segundo plano.",
    "Lưu cài đặt": "Guardar ajustes",
    "Đã đặt vị trí nhà": "Ubicación de la casa establecida",
    "Đang lấy vị trí...": "Getting ubicación...",
    "Đang lưu...": "Guardando...",
    "Đổi tên hiển thị": "Cambiar nombre visible",
    "Cập nhật thông tin nhà": "Actualizar casa información",
    "Nhập địa chỉ của nhà": "Introduce la dirección de la casa",
    "Lưu thay đổi": "Guardar changes",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.":
    "Este nombre solo se muestra en tu cuenta.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.":
    "El nombre y la dirección se actualizarán para todos los miembros de la casa.",
    "Một thành viên": "Un miembro",
    "Đã cập nhật thông tin nhà": "Información de la casa actualizada",
    "Thay tên": "Cambiar nombre",
    "Đã đổi tên thiết bị": "Dispositivo renombrado",
    "Chưa chọn nhà để kiểm tra": "Selecciona una casa para comprobar",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner":
    "Realiza esta prueba con una cuenta de propietario",
    "Không đọc được dữ liệu nhà": "No se pudieron leer los datos de la casa",
    "Nhà cần có ít nhất một thiết bị để test":
    "La casa necesita al menos un dispositivo para la prueba",
    "Đóng": "Cerrar",
    "Đã thiết lập": "Configurado",
    "Quét QR": "Escanear QR",
    "Quét QR để thêm thiết bị": "Escanear QR para añadir un dispositivo",
    "Nhập HUB ID thủ công": "Introducir HUB ID manualmente",
    "Bạn không có quyền sắp xếp phòng":
    "No tienes permiso para reordenar habitaciones",
    "Cảnh báo khói": "Alerta de humo",
    "Cập nhật thiết bị": "Dispositivo actualizar",
    "Cửa đang mở": "La puerta está abierta",
    "Cửa đã đóng": "La puerta está cerrada",
    "Firebase Rules: CÓ LỖI": "Firebase Rules: ERROR",
    "Firebase Rules: ĐẠT": "Firebase Rules: CORRECTO",
    "Giờ không hợp lệ": "Hora no válida",
    "Khôi phục mật khẩu": "Reset contraseña",
    "Nhập email của bạn": "Introduce tu Email",
    "Gửi": "Enviar",
    "Đã gửi email khôi phục": "Email de recuperación enviado",
    "Không gửi được email": "No se pudo enviar el Email",
    "Vui lòng nhập email và mật khẩu": "Introduce tu email y contraseña.",
    "Mật khẩu xác nhận không khớp": "Las contraseñas no coinciden",
    "Không thể tạo tài khoản": "No se pudo crear la cuenta.",
    "Sai tài khoản": "Incorrect cuenta",
    "Email đã tồn tại": "El Email ya existe",
    "Mật khẩu quá yếu": "La contraseña es demasiado débil",
    "Sai email hoặc mật khẩu": "Email o contraseña incorrectos",
    "Lỗi đăng nhập": "Error de inicio de sesión",
    "Email": "Email",
    "Mật khẩu": "Contraseña",
    "Ghi nhớ tài khoản": "Remiembro cuenta",
    "Đăng nhập": "Iniciar sesión",
    "Đăng ký mới": "Crear cuenta",
    "Quên mật khẩu?": "Forgot contraseña?",
    "Chưa có tài khoản? Đăng ký": "Don't have an cuenta? Sign up",
    "Đã có tài khoản? Đăng nhập": "Already have an cuenta? Log in",
    "Tính năng đang được phát triển": "Esta función está en desarrollo",
    "Thông báo": "Notificaciones",
    "Chat trong nhà": "Chat de la casa",
    "Tìm kiếm tin nhắn": "Buscar mensajes",
    "Xem thành viên": "View miembros",
    "Tìm nội dung hoặc tên người gửi": "Buscar contenido o nombre del remitente",
    "Xoá từ khoá": "Borrar palabra clave",
    "Không có kết quả": "Sin resultados",
    "Tìm ngôn ngữ": "Buscar idioma",
    "Kết quả trước": "Resultado anterior",
    "Kết quả tiếp theo": "Resultado siguiente",
    "Chưa có tin nhắn": "Aún no hay mensajes",
    "Không tìm thấy thành viên phù hợp":
    "No se encontraron miembros coincidentes",
    "Nhắc đến trong tin nhắn": "Mention in mensaje",
    "Huỷ trả lời": "Cancelar reply",
    "Nhắn gì đó...": "Type a mensaje...",
    "Gọi điện": "Llamar",
    "Alarm thiết bị": "Dispositivo Alarm",
    "Chế độ áp dụng": "Modo aplicado",
    "Theo nhà": "Programación de la casa",
    "Riêng tôi": "Solo yo",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
    "Usar la programación compartida establecida por el propietario o administrador",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn":
    "Usar una programación personal que solo se aplica a tu cuenta.",
    "Thiết lập nhanh Alarm": "Configuración rápida de Alarm",
    "Thiết lập nhanh toàn bộ thiết bị":
    "Configurar rápidamente todos los dispositivos",
    "Áp dụng cho toàn bộ thiết bị": "Aplicar a todos los dispositivos",
    "Bắt đầu": "Inicio",
    "Kết thúc": "Fin",
    "Thời gian lặp lại": "Intervalo de repetición",
    "Không lặp lại": "No repetir",
    "Quét QR HUB": "Escanear QR del Hub",
    "Đưa mã QR vào giữa khung": "Coloca el código QR en el centro del marco",
    "Đang áp dụng...": "Aplicando...",
    "Hôm nay đã ghi nhận cảnh báo SOS": "Hoy se registró una alerta SOS",
    "Hôm nay đã ghi nhận cảnh báo khói": "Hoy se registró una alerta de humo",
    "Khói đã an toàn": "Humo condition cleared",
    "Không tìm thấy nhà của thông báo này":
    "No se encontró la casa de esta notificación",
    "Không tìm thấy thiết bị trong nhà này":
    "No se encontró el dispositivo en esta casa",
    "Một chủ nhà": "Un propietario",
    "Ngôi nhà đang hoạt động ổn định": "La casa funciona de forma estable",
    "Nhiệt độ cao": "High temperatura",
    "OK": "OK",
    "Pin yếu": "Batería baja",
    "SOS đã kết thúc": "SOS finalizado",
    "SOS được kích hoạt": "SOS activado",
    "Tamper bình thường": "Manipulación normal",
    "Thiết bị bị tháo": "Manipulación detectada",
    "Thiết bị mới": "Nuevo dispositivo",
    "Thiết bị offline": "Dispositivo sin conexión",
    "Thiết bị online": "Dispositivo conectado",
    "Báo động kích hoạt": "Alarma activada",
    "Báo động đã tắt": "Alarma desactivada",
    "Tạm tắt Alarm hôm nay": "Pausar Alarm hoy",
    "Độ ẩm cao": "High humedad",
    "Thử lại": "Intentar de nuevo",
    "Không thể tải dữ liệu tài khoản":
    "No se pudieron cargar los datos de la cuenta.",
    "Không": "No",
    "Đã chia sẻ nhà thành công.": "Casas compartidas correctamente.",
    "Tìm nhà...": "Buscar casas...",
    "Đã rời khỏi nhà": "Saliste de la casa",
    "Bạn sẽ rời khỏi các nhà được chia sẻ.":
    "Saldrás de las casas compartidas.",
    "Các nhà của bạn sẽ bị xoá.\n": "Tus casas serán eliminadas.\n",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\n":
    "Esta acción cambiará la programación de Home Alarm de todos los dispositivos de seguridad en las casas seleccionadas.\n\n",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\n":
    "Esta acción añadirá Home Reminder a las casas seleccionadas.\n\n",
    "Xác nhận thay đổi Alarm": "Confirmar cambios de Alarm",
    "Xác nhận thay đổi Reminder": "Confirmar cambios de Reminder",
    "Lặp lại khi sự cố vẫn còn": "Repetir si el problema continúa",
    "Thời gian lặp lại Alarm": "Intervalo de repetición de Alarm",
    "VD: Mr Chung": "Ej.: Mr Chung",
    "🏡 Chưa có nhà nào": "🏡 Aún no hay casas",
    "Vẫn chuyển về Bình thường": "Cambiar igualmente al modo normal",
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.":
    "La protección automática al salir sigue activada. Si todos los miembros siguen fuera, el sistema puede volver a activar el modo protección después de unos minutos.",
    "Chuyển về Bình thường?": "¿Cambiar al modo normal?",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\n":
    "Al activarlo, los dispositivos de seguridad se supervisarán inmediatamente.\n\n",
    "Bật Bảo vệ thủ công?": "¿Activar el modo protección manual?",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị ":
    "Esta acción cambiará la hora de alarma de algunos dispositivos hoy...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà ":
    "Esta acción desactivará todas las alarmas de la casa ",
    "Tắt toàn bộ Alarm?": "¿Desactivar todos los Alarm?",
    "Không xoá được lịch tạm tắt Alarm":
    "No se pudo eliminar la pausa de Alarm",
    "Không lưu được tạm tắt Alarm": "No se pudo guardar la pausa de Alarm",
    "Không gửi được yêu cầu xoá":
    "No se pudo enviar la solicitud de eliminación",
    "Không lưu được cài đặt": "No se pudo guardar la configuración.",
    "Không lấy được vị trí hiện tại": "No se pudo obtener la ubicación actual.",
    "Không thể xác nhận tài khoản hiện tại":
    "No se pudo verificar la cuenta actual.",
    "Mật khẩu không đúng": "Contraseña incorrecta",
    "Không thể xác nhận mật khẩu": "No se pudo verificar la contraseña.",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi lặp báo động":
    "Solo el propietario o un administrador puede cambiar la repetición de la alarma",
    "Không lưu được thời gian lặp báo động":
    "No se pudo guardar el intervalo de repetición de la alarma.",
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ":
    "Solo el propietario o un administrador puede cambiar el modo protección",
    "Không thể thay đổi chế độ nhà": "No se pudo cambiar el modo de la casa.",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo":
    "El modo protección está activado, pero no se pudo enviar la notificación.",
    "Đã bật Mode Bảo vệ thủ công": "Modo protección manual activado",
    "Đã chuyển nhà về Bình thường": "La casa volvió al modo normal",
    "60 phút": "60 minutos",
    "30 phút": "30 minutos",
    "15 phút": "15 minutos",
    "Bạn đang xem lịch của chủ nhà. Chọn Riêng tôi để tự đặt lịch Alarm.":
    "Estás viendo la programación del propietario. Elige Solo yo para configurar tu propia programación de Alarm.",
    "Chọn giờ kết thúc Alarm": "Elegir hora de fin de Alarm",
    "Chọn giờ bắt đầu Alarm": "Elegir hora de inicio de Alarm",
    "Bạn không có quyền sửa lịch Alarm của nhà":
    "No tienes permiso para editar la programación de Alarm de esta casa",
    "Không thể áp dụng Alarm cho toàn bộ thiết bị":
    "No se pudo aplicar Alarm a todos los dispositivos.",
    "Nhà chưa có thiết bị an ninh để áp dụng":
    "Esta casa no tiene dispositivos de seguridad para aplicar",
    "Bạn không có quyền sửa lịch Theo nhà. Hãy chọn Riêng tôi.":
    "No tienes permiso para editar la programación de la casa. Elige Solo yo.",
    "Không thể lưu chế độ Alarm": "No se pudo guardar el modo de Alarm.",
    "Thêm Reminder": "Añadir Reminder",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.":
    "Reminder te recordará revisar el estado de seguridad de la casa a la hora seleccionada.",
    "Thêm khung giờ Alarm": "Añadir Alarm time window",
    "Đang sử dụng Reminder riêng của bạn":
    "Usando tu propia configuración de Reminder.",
    "Đang sử dụng Reminder của chủ nhà":
    "Usando la configuración de Reminder del propietario",
    "Sửa giờ Reminder": "Editar hora de Reminder",
    "Sửa giờ kết thúc Alarm": "Editar hora de fin de Alarm",
    "Sửa giờ bắt đầu Alarm": "Editar hora de inicio de Alarm",
    "Xoá Reminder": "Eliminar Reminder",
    "Mỗi 1 giờ": "Cada 1 hora",
    "Mỗi 30 phút": "Cada 30 minutos",
    "Mỗi 15 phút": "Cada 15 minutos",
    "Không báo lại": "No volver a avisar",
    "Báo lại khi vẫn chưa an toàn": "Volver a avisar si sigue sin ser seguro",
    "Báo lại mỗi 1 giờ": "Avisar cada 1 hora",
    "Báo lại mỗi 30 phút": "Avisar cada 30 minutos",
    "Báo lại mỗi 15 phút": "Avisar cada 15 minutos",
    "Quản lý nhà": "Casa management",
    "Xoá thành viên": "Eliminar miembro",
    "Đã xoá thành viên": "Miembro eliminado",
    "Đồng ý": "OK",
    "Bạn chắc chắn muốn rời khỏi nhà này?":
    "¿Seguro que quieres salir de esta casa?",
    "Xoá thành viên?": "Eliminar miembro?",
    "Rời khỏi nhà?": "Salir esta casa?",
    "Chỉ chủ nhà mới được thay đổi vai trò":
    "Solo el propietario puede cambiar roles",
    "Bạn không có quyền xoá thành viên này":
    "No tienes permiso para eliminar a este miembro.",
    "Bạn": "Tú",
    "Không có email": "Sin Email",
    "Chưa có số điện thoại": "Sin número de teléfono",
    "Không mở được ứng dụng gọi điện":
    "No se pudo abrir la aplicación de llamadas",
    "Thành viên chưa cập nhật số điện thoại":
    "Este miembro aún no ha actualizado su número de teléfono",
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường":
    "El modo protección manual está activado; solo se desactiva al cambiar al modo normal",
    "Thời gian lặp": "Intervalo de repetición",
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.":
    "Elige 0 para alertar solo una vez. Esta configuración se aplica tanto al modo protección manual como a la protección automática al salir.",
    "Lặp báo động khi sự cố vẫn còn":
    "Repetir la alarma si el problema continúa",
    "Đang được sử dụng": "En uso",
    "Chuyển về sử dụng thông thường": "Volver al uso normal",
    "Chế độ nhà": "Modo de casa",
    "Thiết bị SOS chưa ghi nhận cảnh báo.":
    "El dispositivo SOS aún no ha registrado alertas.",
    "Cảm biến khói chưa ghi nhận bất thường.":
    "El sensor de humo aún no ha detectado anomalías.",
    "Bạn hoặc thành viên đã chủ động bật Bảo vệ.":
    "Tú o un miembro activaron manualmente el modo protección.",
    "SafeHome tự bật Bảo vệ vì bạn đã rời khỏi nhà.":
    "SafeHome activó automáticamente el modo protección porque saliste de casa.",
    "Nhà đang ở chế độ dùng bình thường.":
    "Esta casa está actualmente en uso normal.",
    "Bảo vệ thủ công đang bật": "El modo protección manual está activado",
    "Bảo vệ tự động đang bật": "La protección automática está activada",
    "Bảo vệ đang tắt": "El modo protección está desactivado",
    "Bạn đã mở app gần đây để kiểm tra trạng thái.":
    "Has abierto la app recientemente para revisar el estado.",
    "Bạn nên mở app định kỳ để kiểm tra quyền, lịch và cảnh báo chưa đọc.":
    "Abre la app periódicamente para revisar permisos, programaciones y alertas no leídas.",
    "Sau vài lần sử dụng, SafeHome sẽ đánh giá thói quen kiểm tra app tốt hơn.":
    "Después de algunos usos, SafeHome evaluará mejor tus hábitos de revisión de la app.",
    "Tần suất vào app ổn": "Frecuencia de uso de la app correcta",
    "Đã lâu chưa vào app kiểm tra":
    "Hace tiempo que no abres la app para revisar",
    "Đang ghi nhận tần suất vào app":
    "Registrando la frecuencia de uso de la app",
    "Cần kiểm tra quyền vị trí luôn luôn và điều kiện chạy nền.":
    "Revisa el permiso de ubicación siempre activa y las condiciones de ejecución en segundo plano.",
    "Thiết bị đủ điều kiện để Auto rời khỏi nhà hoạt động.":
    "Este dispositivo cumple los requisitos para que Auto Away funcione.",
    "Bạn có thể bật khi muốn tự động chuyển Bảo vệ lúc rời nhà.":
    "Puedes activarlo si quieres que el modo protección se active automáticamente al salir.",
    "Auto rời khỏi nhà chưa ổn": "Auto Away aún no está listo",
    "Auto rời khỏi nhà đã sẵn sàng": "Auto Away está listo",
    "Auto rời khỏi nhà chưa bật": "Auto Away no está activado",
    "Nên thêm báo khói, SOS hoặc thiết bị khẩn cấp phù hợp với nhà.":
    "Conviene añadir un detector de humo, SOS o un dispositivo de emergencia adecuado para la casa.",
    "Chưa có thiết bị khẩn cấp": "Aún no hay dispositivos de emergencia",
    "Đã có thiết bị khẩn cấp": "Dispositivos de emergencia añadidos",
    "Nên đặt lịch Alarm cho thời gian ngủ hoặc vắng nhà.":
    "Conviene configurar una programación de Alarm para las horas de sueño o ausencia.",
    "Nhà đã có lịch Alarm hoặc lịch cảnh báo theo thiết bị.":
    "Esta casa tiene una programación de Alarm o una programación de alertas por dispositivo.",
    "Chưa set lịch Alarm": "La programación de Alarm no está configurada",
    "Đã set lịch Alarm": "La programación de Alarm está configurada",
    "Nên có ít nhất một Reminder để không quên kiểm tra nhà.":
    "Conviene tener al menos un Reminder para no olvidar revisar la casa.",
    "App sẽ nhắc bạn kiểm tra nhà theo lịch đã đặt.":
    "La app te recordará revisar la casa según la programación configurada.",
    "Chưa setup Reminder": "Reminder no configurado",
    "Đã setup Reminder": "Reminder configurado",
    "Hãy mở lại app hoặc đăng nhập lại nếu thiết bị không nhận cảnh báo.":
    "Vuelve a abrir la app o inicia sesión de nuevo si este dispositivo no recibe alertas.",
    "Thiết bị chưa đăng ký nhận cảnh báo":
    "Este dispositivo no está registrado para recibir alertas",
    "Thiết bị nhận cảnh báo bình thường":
    "Este dispositivo puede recibir alertas con normalidad",
    "iOS quản lý chạy nền chặt hơn Android; hãy giữ thông báo và vị trí luôn luôn nếu dùng Auto rời khỏi nhà.":
    "iOS gestiona el segundo plano de forma más estricta que Android; mantén activadas las notificaciones y la ubicación siempre permitida si usas Auto Away.",
    "Cơ chế iOS": "Mecanismo iOS",
    "Hãy kiểm tra quyền chạy nền và tự khởi động để cảnh báo không bị trễ.":
    "Revisa el permiso de ejecución en segundo plano y el inicio automático para que las alertas no se retrasen.",
    "Thiết bị đã xác nhận các điều kiện chạy nền quan trọng.":
    "El dispositivo ha confirmado las condiciones importantes de ejecución en segundo plano.",
    "Cần kiểm tra chạy nền / tự khởi động":
    "Revisar ejecución en segundo plano / inicio automático",
    "Chạy nền ổn định": "Ejecución en segundo plano estable",
    "Một số máy Android có thể trì hoãn cảnh báo nếu tối ưu pin còn bật.":
    "Algunos teléfonos Android pueden retrasar las alertas si la optimización de batería está activada.",
    "Điện thoại ít có khả năng trì hoãn cảnh báo SafeHome.":
    "Es menos probable que el teléfono retrase las alertas de SafeHome.",
    "Chưa tắt tối ưu pin": "La optimización de batería sigue activada",
    "Tối ưu pin không chặn app":
    "La optimización de batería no bloquea la app.",
    "Auto rời khỏi nhà cần quyền vị trí luôn luôn để chạy ổn định.":
    "Auto Away necesita el permiso de ubicación siempre permitida para funcionar de forma estable.",
    "Cần cấp quyền vị trí để Auto rời khỏi nhà hoạt động.":
    "Se requiere permiso de ubicación para que Auto Away funcione.",
    "Dịch vụ vị trí đang tắt nên Auto rời khỏi nhà không ổn định.":
    "El servicio de ubicación está desactivado, por lo que Auto Away puede no funcionar de forma estable.",
    "Chỉ cần quyền này khi dùng Auto rời khỏi nhà.":
    "Solo necesitas este permiso al usar Auto Away.",
    "Chưa cấp vị trí luôn luôn":
    "La ubicación siempre permitida no está activada.",
    "Đã cấp vị trí luôn luôn": "La ubicación siempre permitida está activada.",
    "iOS không mở toàn màn hình như Android; app dùng notification và âm thanh hệ thống.":
    "iOS no abre pantalla completa como Android; la app usa notificaciones y sonido del sistema.",
    "Android dùng cảnh báo toàn màn hình; nếu máy chặn, hãy cấp quyền trong cài đặt.":
    "Android usa alertas de pantalla completa; si el teléfono las bloquea, concede el permiso en la configuración.",
    "Cảnh báo trên iOS": "Alertas en iOS",
    "Cảnh báo toàn màn hình": "Alertas de pantalla completa",
    "Cảnh báo có thể không hiển thị nếu thông báo bị tắt.":
    "Las alertas pueden no aparecer si las notificaciones están desactivadas.",
    "Điện thoại có thể nhận thông báo SafeHome.":
    "El teléfono puede recibir notificaciones de SafeHome.",
    "Chưa bật thông báo": "Las notificaciones no están activadas",
    "Đã bật thông báo": "Las notificaciones están activadas",
    "Hệ thống: Sẵn sàng": "Sistema: listo",
    "Hệ thống: Có thể bỏ lỡ cảnh báo": "Sistema: se podrían perder alertas",
    "Cách bạn đang dùng app": "Cómo estás usando la app",
    "Thiết bị của bạn": "Tu dispositivo",
    "Kiểm tra điện thoại và cách bạn đang dùng app.":
    "Revisa el teléfono y cómo estás usando la app.",
    "Hệ thống SafeHome": "Sistema SafeHome",
    "Hệ thống: Đang kiểm tra...": "Sistema: comprobando...",
    "Tên": "Nombre",
    "Bạn không có quyền thay đổi vị trí nhà":
    "No tienes permiso para cambiar la ubicación de la casa.",
    "Hãy bật GPS để đặt vị trí nhà":
    "Activa el GPS para establecer la ubicación de la casa.",
    "Bạn chưa cấp quyền vị trí": "No se ha concedido el permiso de ubicación",
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng":
    "Concede el permiso de ubicación en los ajustes de la app",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà":
    "Protección automática activada cuando todos salen de casa",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà":
    "Protección automática desactivada cuando todos salen de casa",
    "Không thể thay đổi trạng thái Alarm":
    "No se pudo cambiar el estado de Alarm",
    "Đã tắt toàn bộ Alarm của nhà":
    "Se desactivaron todos los Alarm de la casa",
    "QR này không phải mã xin gia nhập Home":
    "Este código QR no es un código para solicitar acceso a la casa.",
    "Thêm Home": "Añadir Casa",
    "Mở cài đặt": "Abrir ajustes",
    "Để sau": "Más tarde",
    "SafeHome cần quyền vị trí \"Luôn cho phép\" để nhận biết khi bạn rời hoặc trở về nhà, kể cả khi ứng dụng đang chạy nền.":
    "SafeHome necesita el permiso de ubicación «Siempre permitido» para detectar cuándo sales o vuelves a casa, incluso cuando la app se ejecuta en segundo plano.",
    "SafeHome hiện chỉ được truy cập vị trí khi bạn đang sử dụng ứng dụng.\n\nHãy chọn quyền Vị trí và chuyển sang \"Luôn cho phép\" để tính năng tự động Bảo vệ khi rời nhà hoạt động khi ứng dụng đang chạy nền.":
    "Actualmente SafeHome solo puede acceder a la ubicación mientras usas la app.\n\nAbre el permiso de ubicación y selecciona «Permitir siempre» para que la protección automática al salir funcione en segundo plano.",
    "Cho phép vị trí luôn luôn": "Permitir ubicación siempre",
    "Các nhà của bạn sẽ bị xoá.\nCác nhà được chia sẻ sẽ được rời khỏi.":
    "Tus casas serán eliminadas.\nSaldrás de las casas compartidas.",
    "Thao tác này sẽ thay đổi lịch Home Alarm của toàn bộ thiết bị an ninh trong các nhà đã chọn.\n\nNhững thành viên đang sử dụng Alarm 'Theo nhà' sẽ bị ảnh hưởng.\nAlarm cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.":
    "Esta acción cambiará la programación de Home Alarm de todos los dispositivos de seguridad en las casas seleccionadas.\n\nLos miembros que usan Alarm 'Programación de la casa' se verán afectados.\nLa configuración personal de Alarm en modo 'Solo yo' no cambiará.",
    "Thao tác này sẽ thêm Home Reminder cho các nhà đã chọn.\n\nNhững thành viên đang sử dụng Reminder 'Theo nhà' sẽ bị ảnh hưởng.\nReminder cá nhân ở chế độ 'Riêng tôi' sẽ không bị thay đổi.":
    "Esta acción añadirá Home Reminder a las casas seleccionadas.\n\nLos miembros que usan Reminder 'Programación de la casa' se verán afectados.\nLa configuración personal de Reminder en modo 'Solo yo' no cambiará.",
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.":
    "Al activarlo, los dispositivos de seguridad se supervisarán inmediatamente.\n\nLa protección automática al salir se pausará. Este modo no se desactiva automáticamente cuando alguien vuelve a casa y solo puede desactivarlo un miembro con permiso al cambiar a modo normal.",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...":
    "Esta acción cambiará la hora de alarma de algunos dispositivos hoy...",
    "Hành động này sẽ tắt toàn bộ báo động của nhà dưới mọi hình thức. Bạn sẽ không còn nhận được cảnh báo khi có nguy hiểm trên điện thoại nữa.":
    "Esta acción desactivará todas las alarmas de la casa. Ya no recibirás alertas de peligro en este teléfono.",
    "Alarm đang sử dụng chế độ Theo nhà.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm chung do Chủ nhà hoặc Quản trị viên thiết lập.":
    "Alarm está usando la programación de la casa.\n\nRecibirás alertas según la programación compartida de Alarm configurada por el propietario o un administrador.",
    "Alarm đang sử dụng chế độ Riêng tôi.\n\nBạn sẽ nhận cảnh báo theo lịch Alarm riêng đã thiết lập cho tài khoản này.":
    "Alarm está usando mi programación personal.\n\nRecibirás alertas según la programación personal de Alarm configurada para esta cuenta.",
    "Không thể đăng nhập bằng Google": "No se pudo iniciar sesión con Google",
    "Không đặt được mật khẩu": "No se pudo establecer la contraseña",
    "Chấp nhận": "Aceptar",
    "Cho phép": "Permitir",
    "Không thể chấp nhận lời mời. Vui lòng thử lại.":
    "No se pudo aceptar la invitación. Inténtalo de nuevo.",
    "Không thể chấp nhận lời xin vào nhà. Vui lòng thử lại.":
    "No se pudo aceptar la solicitud para unirse. Inténtalo de nuevo.",
    "Từ chối": "Rechazar",
    "Lời mời từ chủ nhà": "Invitación del propietario",
    "Nhận quyền chủ nhà": "Recibir propiedad de la casa",
    "Một người dùng SafeHome": "Un usuario de SafeHome",
    "Lời mời gia nhập": "Invitación para unirse",
    "Lời xin vào nhà": "Solicitud para unirse a la casa",
    "Nhập HUB ID": "Introducir HUB ID",
    "VD: HUB_001": "Ej.: HUB_001",
    "Pair": "Emparejar",
    "Mật khẩu tối thiểu 6 ký tự":
    "La contraseña debe tener al menos 6 caracteres",
    "Mật khẩu nhập lại không khớp": "Las contraseñas no coinciden",
    "Tạo mật khẩu": "Crear contraseña",
    "Mật khẩu mới": "Nueva contraseña",
    "Nhập lại mật khẩu": "Repetir contraseña",
    "Xác nhận tắt cảnh báo": "Confirmar detención de alarma",
    "HỦY": "CANCELAR",
    "XÁC NHẬN": "CONFIRMAR",
    "CẦN KIỂM TRA": "REQUIERE REVISIÓN",
    "KIỂM TRA NHÀ": "REVISAR CASA",
    "ĐÓNG NHẮC NHỞ": "CERRAR RECORDATORIO",
    "SafeHome Security Alert": "Alerta de seguridad SafeHome",
    "Hãy chọn quyền vị trí Luôn cho phép trong Cài đặt ứng dụng": "Selecciona el permiso de ubicación «Permitir siempre» en los ajustes de la app",
    "Tài khoản Google cần tạo thêm mật khẩu để dùng các chức năng bảo mật.":
    "Tu cuenta de Google necesita una contraseña adicional para usar las funciones de seguridad.",
    "Alarm": "Alarm",
    "Bạn không có quyền thực hiện thao tác này。":
    "No tienes permiso para realizar esta acción.",
    "Cài đặt": "Ajustes",
    "Cập nhật": "Actualizar",
    "Chọn ngôn ngữ": "Elegir idioma",
    "Chưa có dữ liệu thiết bị để đánh giá":
    "No hay datos de dispositivos disponibles para la evaluación",
    "Chuyển quyền sở hữu cho thành viên khác":
    "Transferir la propiedad a otro miembro",
    "Có": "Sí",
    "Cửa đã đóng an toàn": "La puerta está cerrada de forma segura",
    "Đã xảy ra lỗi. Vui lòng thử lại.":
    "Se produjo un error. Inténtalo de nuevo.",
    "Đang kiểm tra kết nối Hub": "Comprobando conexión del Hub",
    "Đang mở khi nhà ở chế độ Bảo vệ":
    "Abierto mientras la casa está en modo protección",
    "Đang mở trong giờ Alarm": "Abierto durante el horario de Alarm",
    "Đang tải...": "Cargando...",
    "Hồ sơ, yêu cầu và lời mời tham gia": "Perfil, solicitudes e invitaciones",
    "Hub chưa gửi trạng thái": "Estado del Hub no disponible",
    "Hub mất kết nối": "Hub desconectado",
    "Hub tín hiệu bình thường": "Hub conectado",
    "Khóa đang mở khi nhà ở chế độ Bảo vệ":
    "La cerradura está abierta mientras la casa está en modo protección",
    "Khóa đang mở trong giờ Alarm":
    "La cerradura está abierta durante el horario de Alarm",
    "Không có thông báo": "Sin notificaciones",
    "Khu vực nguy hiểm": "Zona de peligro",
    "Kiểm tra thiết bị trong nhà này": "Revisar dispositivos en esta casa",
    "Mất điện lưới": "Pérdida de alimentación principal",
    "Mời người khác tham gia nhà này":
    "Invitar a otra persona a unirse a esta casa",
    "Môi trường hiện tại": "Entorno actual",
    "MQTT mất kết nối": "MQTT desconectado",
    "Ngôn ngữ": "Idioma",
    "Nhà đã chia sẻ": "Compartido casa",
    "Nhà đang hoạt động bình thường": "Casa operating normally",
    "Nhập email": "Introducir Email",
    "Phòng": "Habitación",
    "Quản trị viên": "Administrador",
    "Reminder": "Reminder",
    "SafeHome": "SafeHome",
    "Sóng yếu": "Señal débil",
    "SOS": "SOS",
    "Tài khoản & hệ thống": "Cuenta & system",
    "Tài khoản cá nhân": "Personal cuenta",
    "Tạo tài khoản": "Crear cuenta",
    "Thành viên": "Miembro",
    "Thành viên trong nhà": "Miembros de la casa",
    "Thay đổi ngôn ngữ hiển thị": "Cambiar idioma de visualización",
    "Thêm, đổi tên và sắp xếp phòng":
    "Añadir, renombrar y ordenar habitaciones",
    "Thiết bị đang được giám sát": "El dispositivo está siendo supervisado",
    "Tiếng Anh": "Inglés",
    "Tiếng Hàn": "Coreano",
    "Tiếng Nhật": "Japonés",
    "Tiếng Trung": "Chino",
    "Tiếng Việt": "Vietnamita",
    "Toàn bộ thiết bị": "Todos los dispositivos",
    "Vai trò": "Rol",
    "Về nhà": "At casa",
    "Xem và quản lý quyền thành viên": "Ver y administrar los roles de los miembros",
    "Xóa": "Eliminar",
    "Xóa nhà": "Eliminar casa",
    "Xoá toàn bộ dữ liệu và thiết bị":
    "Eliminar todos los datos y dispositivos",
    "TẮT CẢNH BÁO": "DETENER ALERTA",
    "Đã tạo nhà": "Casa creado",
    "Mode Bảo vệ thủ công đã bật": "Modo protección manual activado",
    "Báo động không lặp lại.": "La alarma no se repetirá.",
    "Báo động lặp sau \$securityModeRepeatMinutes phút nếu sự cố vẫn còn.":
    "La alarma se repetirá después de \$securityModeRepeatMinutes minutos si el problema continúa.",
    "\$actorName đã bật Mode Bảo vệ thủ công cho \"\$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. \$repeatMessage":
    "\$actorName activó manualmente el modo protección para «\$homeName». Este modo solo se desactiva cuando un miembro con permiso cambia al modo normal. \$repeatMessage",
    "Bạn đã bật Alarm cho nhà \"\$homeName\".":
    "Activaste Alarm para \"\$homeName\".",
    "Bạn đã tắt toàn bộ Alarm của nhà \"\$homeName\".":
    "Desactivaste todos los Alarm de \"\$homeName\".",
    "Thành viên mới": "Nuevo miembro",
    "Thành viên rời nhà": "Un miembro salió de la casa",
    "\$displayMemberName đã rời khỏi nhà \"\$homeName\".":
    "\$displayMemberName salió de «\$homeName».",
    "\$actorName đã đổi vai trò của \$memberName từ \$oldRoleName thành \$newRoleName trong nhà \"\$homeName\".":
    "\$actorName cambió el rol de \$memberName de \$oldRoleName a \$newRoleName en «\$homeName».",
    "Còn \$count tin nhắn chưa đọc": "\$count mensajes sin leer",
    "Hãy an tâm nghỉ ngơi.": "Puedes descansar con tranquilidad.",
    "Có thiết bị chưa an toàn.": "Algunos dispositivos no son seguros.",
    "SafeHome đang cập nhật vị trí": "SafeHome está actualizando la ubicación",
    "Đang theo dõi để tự động bật Chế độ Bảo vệ.":
    "Supervisando para activar automáticamente el modo protección.",
    "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.":
    "Usa la ubicación para activar automáticamente el modo protección cuando todos salen de casa.",
    "CẢNH BÁO SOS": "ALERTA SOS",
    "CẢNH BÁO KHÓI / CHÁY": "ALERTA DE HUMO / INCENDIO",
    "CẢNH BÁO NGẬP NƯỚC": "ALERTA DE INUNDACIÓN",
    "CẢNH BÁO RÒ KHÍ": "ALERTA DE FUGA DE GAS",
    "CẢNH BÁO CỬA": "ALERTA DE PUERTA",
    "CẢNH BÁO AN NINH": "ALERTA DE SEGURIDAD",
    "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.":
    "No se pudo confirmar con SafeHome. Revisa la conexión e inténtalo de nuevo.",
    "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?":
    "Detén la alerta solo después de revisar el estado de la casa.\n\n¿Seguro que quieres detener la alerta?",
    "🚨 SafeHome phát hiện cảnh báo": "🚨 SafeHome detectó una alerta",
    "Mở SafeHome để kiểm tra ngay.": "Abre SafeHome para revisar ahora.",
    "\$count tin nhắn mới": "\$count mensajes nuevos",
    "Tin nhắn HomeChat": "Mensaje de HomeChat",
    "\$senderName đã gửi một tin nhắn": "\$senderName envió un mensaje",
    "Bạn có tin nhắn mới": "Tienes un mensaje nuevo",
    "Mode Bảo vệ sẽ chỉ báo động một lần":
    "El modo protección alertará solo una vez",
    "Mode Bảo vệ sẽ lặp báo động sau \$minutes phút":
    "El modo protección repetirá la alerta después de \$minutes minutos",
    "Đã gửi yêu cầu gia nhập \$count nhà":
    "Solicitudes de acceso enviadas a \$count casas",
    "\$requesterName đang xin gia nhập nhà \"\$homeName\".":
    "\$requesterName solicitó acceso a «\$homeName».",
    "Bạn đã xoá nhà \"\$homeName\".": "Eliminaste \"\$homeName\".",
    "Bạn đã gửi yêu cầu chuyển quyền chủ nhà \"\$homeName\" cho \$email.":
    "Enviaste una solicitud de transferencia de propiedad de «\$homeName» a \$email.",
    "\$actorName muốn chuyển quyền chủ nhà \"\$homeName\" cho bạn.":
    "\$actorName quiere transferirte la propiedad de «\$homeName».",
    "\$actorName đã mời bạn tham gia nhà \"\$homeName\".":
    "\$actorName te invitó a unirte a «\$homeName».",
    "SafeHome đang xoá thiết bị \"\$deviceName\" khỏi nhà \"\$homeName\".":
    "SafeHome está eliminando el dispositivo «\$deviceName» de «\$homeName».",
    "Thiết bị \"\$deviceName\" đã xuất hiện trong \"\$homeName\".":
    "El dispositivo «\$deviceName» se añadió a «\$homeName».",
    "Bạn đã tạo nhà \"\$name\".": "Creaste la casa \"\$name\".",
    "\$actorName đã cập nhật tên nhà thành \"\$newName\" và thay đổi địa chỉ.":
    "\$actorName actualizó la información de «\$newName».",
    "\$actorName đã đổi tên nhà thành \"\$newName\".":
    "\$actorName cambió el nombre de la casa a «\$newName».",
    "\$actorName đã cập nhật địa chỉ của nhà \"\$newName\".":
    "\$actorName actualizó la dirección de «\$newName».",
    "\$actorName đã đổi tên thiết bị \"\$oldDeviceName\" thành \"\$newName\" trong nhà \"\$homeName\".":
    "\$actorName cambió el nombre del dispositivo «\$oldDeviceName» a «\$newName» en «\$homeName».",
    "Đang ghép nối: \$seconds giây": "Emparejando: \$seconds s",
    "Chế độ thêm thiết bị đã được mở trong nhà \"\$homeName\" trong \$seconds giây.":
    "El modo de emparejamiento de dispositivos se activó en \"\$homeName\" durante \$seconds segundos.",
    "Khoảng thời gian phải nằm trong khung Alarm (\$start → \$end)":
    "El período de pausa debe estar dentro del horario de Alarm (\$start → \$end)",
    "\$passCount/\$total bài test đạt\n\n":
    "\$passCount/\$total pruebas superadas\n\n",
    "\$name chưa cập nhật số điện thoại trong hồ sơ.":
    "\$name aún no ha añadido un número de teléfono a su perfil.",
    "Tin nhắn mới trong \$homeName": "Mensaje nuevo en \$homeName",
    "\$current/\$total kết quả": "\$current/\$total resultados",
    "Đang trả lời \$name": "Respondiendo a \$name",
    "\"\$name\" phát hiện khói trong \"\$homeName\".":
    "«\$name» detectó humo en «\$homeName».",
    "\"\$name\" đã trở lại trạng thái bình thường.":
    "«\$name» volvió al estado normal.",
    "\"\$name\" vừa kích hoạt SOS trong \"\$homeName\".":
    "«\$name» activó SOS en «\$homeName».",
    "\"\$name\" đã hết trạng thái SOS.": "«\$name» ya no está en estado SOS.",
    "\"\$name\" báo bị tháo/cạy trong \"\$homeName\".":
    "«\$name» informó manipulación en «\$homeName».",
    "\"\$name\" đã hết cảnh báo tháo/cạy.":
    "La alerta de manipulación de «\$name» ha finalizado.",
    "\"\$name\" đã đóng trong \"\$homeName\".":
    "«\$name» está cerrado en «\$homeName».",
    "\"\$name\" đang mở trong \"\$homeName\".":
    "«\$name» está abierto en «\$homeName».",
    "\"\$name\" trong \"\$homeName\" đang yếu pin.":
    "La batería de «\$name» en «\$homeName» está baja.",
    "\"\$name\" trong \"\$homeName\" đã mất kết nối.":
    "«\$name» en «\$homeName» perdió la conexión.",
    "\"\$name\" trong \"\$homeName\" đã kết nối trở lại.":
    "«\$name» en «\$homeName» volvió a conectarse.",
    "\"\$name\" ghi nhận nhiệt độ cao trong \"\$homeName\".":
    "\"\$name\" recorded a high temperatura in \"\$homeName\".",
    "\"\$name\" ghi nhận độ ẩm cao trong \"\$homeName\".":
    "\"\$name\" recorded high humedad in \"\$homeName\".",
    "Có nút SOS vừa được kích hoạt": "Se ha activado un botón SOS",
    "Có dấu hiệu khói hoặc cháy": "Se detectó humo o fuego",
    "Có dấu hiệu ngập nước": "Se detectó inundación",
    "Có dấu hiệu rò khí": "Se detectó una fuga de gas",
    "Có cửa đang mở hoặc thiết bị bị tháo":
    "Hay una puerta abierta o un dispositivo manipulado",
    "Có thiết bị đang cảnh báo": "Hay un dispositivo en alerta",
    "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.":
    "Si nadie confirma, SafeHome pasará a una llamada de emergencia.",
    "Báo lại lúc \$time nếu vấn đề chưa được xử lý.":
    "Volverá a avisar a las \$time si el problema no se ha resuelto.",
    "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.":
    "Volverá a avisar según la programación de Alarm si el problema no se ha resuelto.",
    "\"\$deviceName\" đã đóng trong \"\$resolvedHomeName\".":
    "«\$deviceName» está cerrado en «\$resolvedHomeName».",
    "\"\$deviceName\" đang mở trong \"\$resolvedHomeName\".":
    "«\$deviceName» está abierto en «\$resolvedHomeName».",
    "\$count nhà đã chọn": "\$count casas seleccionadas",
    "🚨 \$count nhà không an toàn\$suffix":
    "🚨 \$count casas no seguras\$suffix",
    "⚠️ \$count nhà cần chú ý\$suffix":
    "⚠️ \$count casas requieren atención\$suffix",
    "✅ \$count nhà an toàn": "✅ \$count casas seguras",
    "\$count nhà đang được theo dõi": "\$count casas supervisadas",
    "\$minutes phút": "\$minutes minutos",
    "Đã cài Reminder cho \$updatedHomes nhà.": "Reminder configurado para \$updatedHomes casas.",
    "Đã cài Alarm cho \$updatedDevices thiết bị trong \$updatedHomes nhà.\n":
    "Alarm configurado para \$updatedDevices dispositivos en \$updatedHomes casas.\n",
    "Đã chia sẻ các nhà bạn có quyền.\n\n\$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.":
    "Se compartieron las casas que administras.\n\nSe omitieron \$skipped casas porque no tienes permiso para compartirlas.",
    "Đã áp dụng Alarm cho \$count thiết bị an ninh":
    "Alarm aplicado a \$count dispositivos de seguridad",
    "Áp dụng cùng một lịch cho \$count thiết bị an ninh":
    "Aplicar la misma programación a \$count dispositivos de seguridad",
    "\$count phút trước": "hace \$count minutos",
    "\$count giờ trước": "hace \$count horas",
    "\${count}h trước": "hace \${count}h",
    "\${hours}h\$minutes' trước": "hace \${hours}h \${minutes}m",
    "\$count ngày trước": "hace \$count días",
    "\$count tháng trước": "hace \$count meses",
    "Bạn chắc chắn muốn xoá \$name khỏi nhà này?":
    "¿Seguro que quieres eliminar a \$name de esta casa?",
    "\$targetEmail\nXin gia nhập \"\$homeName\"":
    "\$targetEmail\nSolicita acceso a «\$homeName»",
    "Xin gia nhập \"\$homeName\"": "Solicita acceso a «\$homeName»",
    "Bạn được mời nhận quyền nhà \"\$homeName\"":
    "Te invitaron a recibir la propiedad de «\$homeName»",
    "\$ownerEmail\nMời bạn gia nhập \"\$homeName\"":
    "\$ownerEmail\nTe invita a unirte a «\$homeName»",
    "Mời bạn gia nhập \"\$homeName\"": "Te invita a unirte a «\$homeName»",
    "Cần kiểm tra: \$joined": "Requiere revisión: \$joined",
    "Cập nhật \$value": "Actualizado \$value",
    "Hãy thêm thiết bị SafeHome đầu tiên để bắt đầu theo dõi nhà.":
    "Añade tu primer dispositivo SafeHome para empezar a supervisar esta casa.",
    "Kiểm tra cảnh báo khẩn cấp trước, sau đó liên hệ thành viên trong nhà nếu cần.":
    "Revisa primero las alertas de emergencia y luego contacta con los miembros de la casa si es necesario.",
    "Không có thành viên nào ở nhà nhưng cửa hoặc khóa đang mở, hãy kiểm tra ngay.": "No hay ningún miembro en casa, pero una puerta o cerradura está abierta. Revísalo ahora.",
    "Kiểm tra cửa hoặc khóa đang mở trước khi giữ nhà ở chế độ Bảo vệ.": "Revisa la puerta o cerradura abierta antes de mantener la casa en modo protección.",
    "Có thể vẫn có người ở nhà; nếu đúng, nên chuyển về Bình thường.":
    "Puede que aún haya alguien en casa; si es así, conviene cambiar al modo normal.",
    "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.":
    "Hay miembros con ubicación desconocida; pídeles que abran la app o revisen el permiso de ubicación.",
    "Có thiết bị mất kết nối, hãy kiểm tra pin, nguồn hoặc vị trí đặt thiết bị.": "Un dispositivo perdió la conexión. Revisa la batería, la alimentación o su ubicación.",
    "Có thiết bị pin yếu, nên thay pin sớm để tránh mất cảnh báo.":
    "Hay un dispositivo con batería baja. Cámbiala pronto para evitar perder alertas.",
    "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.":
    "Aún no has configurado Reminder. Crea una programación para revisar la casa periódicamente.",
    "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.":
    "No has configurado una programación de Alarm; conviene activar la protección en los horarios en los que normalmente no hay nadie en casa.",
    "Không có việc cần xử lý ngay, bạn chỉ cần tiếp tục theo dõi trạng thái nhà.":
    "No se necesita ninguna acción inmediata. Sigue supervisando esta casa.",
    "Lặp sau \$minutes phút": "Repetir después de \$minutes minutos",
    "Đang dùng • \$repeatText": "Activo • \$repeatText",
    "Giám sát an ninh • \$repeatText":
    "Supervisión de seguridad • \$repeatText",
    "Gia đình: \$mode": "Casa: \$mode",
    "Gợi ý xử lý": "Acciones sugeridas",
    "Phát hiện \$count vấn đề cần xử lý":
    "\$count problemas requieren atención",
    "Hôm nay các cửa đã được sử dụng \$count lần":
    "Las puertas se usaron \$count veces hoy",
    "Đã ghi nhận \$count hoạt động gần đây":
    "\$count actividades recientes registradas",
    "Hệ thống: Cần kiểm tra \$issueCount mục":
    "Sistema: \$issueCount elementos requieren revisión",
    "FCM token đã sẵn sàng trên điện thoại này.":
    "El token FCM está listo en este teléfono.",
    "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.":
    "El token FCM está listo, pero Auto Away aún necesita cumplir alguna condición.",
    "Hiện có \$emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.":
    "Se encontraron \$emergencyTotal dispositivos de emergencia. Mínimo recomendado: sensor de humo y SOS.",
    "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n\$targetEmail?":
    "¿Seguro que quieres transferir la propiedad de la casa a:\n\$targetEmail?",
    "\$count cửa đã đóng an toàn": "\$count puertas cerradas de forma segura",
    "\$count cửa và khóa đã an toàn": "\$count puertas y cerraduras seguras",
    "\$count thiết bị đang được theo dõi": "\$count dispositivos supervisados",
    "Cập nhật \$timeText": "Actualizado \$timeText",
    "Dữ liệu gần nhất cập nhật \$count phút trước":
    "Los datos más recientes se actualizaron hace \$count minutos",
    "Dữ liệu gần nhất cập nhật \$count giờ trước":
    "Los datos más recientes se actualizaron hace \$count horas",
    "Thành viên trong nhà: \$count": "Miembros en casa: \$count",
    "Thành viên bên ngoài: \$count": "Miembros fuera: \$count",
    "Chưa xác định vị trí: \$count": "Ubicación desconocida: \$count",
    "Môi trường hiện tại: \$environment": "Entorno actual: \$environment",
    "\$name: Đang mở khi nhà ở chế độ Bảo vệ":
    "\$name: abierto mientras la casa está en modo protección",
    "An tâm hơn trong từng ngôi nhà": "Más tranquilidad en cada casa",
    "Báo động SafeHome": "Alarma SafeHome",
    "Có cảnh báo an ninh cần kiểm tra ngay.":
    "Una alerta de seguridad requiere revisión inmediata.",
    "Có cảnh báo cần kiểm tra": "Hay una alerta que revisar",
    "Tự đóng sau \$time": "Se cierra automáticamente en \$time",
  };

  String t(String vi) {
    if (isSpanish) {
      return _spanish[vi] ?? vi;
    }

    if (isFrench) {
      return _french[vi] ?? vi;
    }

    if (isRussian) {
      return _russian[vi] ?? vi;
    }

    if (isGerman) {
      return _german[vi] ?? vi;
    }

    if (isJapanese) {
      return _japanese[vi] ?? vi;
    }

    if (isKorean) {
      return _korean[vi] ?? vi;
    }

    if (isChinese) {
      return _chinese[vi] ?? vi;
    }

    if (!isEnglish) {
      return vi;
    }

    return _english[vi] ?? vi;
  }

  String selectedHomesCountText(int count) => choose(
    vi: "$count nhà đã chọn",
    en: "$count homes selected",
    zh: "已选择 $count 个家庭",
    ko: "선택한 집 $count개",
    ja: "$count 件の家を選択済み",
    de: '$count Zuhause ausgewählt',
    ru: '$count домов выбрано',

    es: "$count casas seleccionadas",
    fr: _fr(vi: "$count nhà đã chọn", en: "$count homes selected"),
  );

  String allHomeDangerCountText(int count, {String reason = ""}) {
    final suffix = reason.trim().isNotEmpty ? " • ${reason.trim()}" : "";
    return choose(
      vi: "🚨 $count nhà không an toàn$suffix",
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
    );
  }

  String allHomeWarningCountText(int count, {String reason = ""}) {
    final suffix = reason.trim().isNotEmpty ? " • ${reason.trim()}" : "";
    return choose(
      vi: "⚠️ $count nhà cần chú ý$suffix",
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
    );
  }

  String allHomeSafeCountText(int count) => choose(
    vi: "✅ $count nhà an toàn",
    en: "✅ $count safe homes",
    zh: "✅ $count 个家庭安全",
    ko: "✅ 안전한 집 $count개",
    ja: "✅ 安全な家 $count 件",
    de: '✅ $count Zuhause sicher',
    ru: '✅ $count домов безопасны',

    es: "✅ $count casas seguras",
    fr: _fr(vi: "✅ $count nhà an toàn", en: "✅ $count safe homes"),
  );

  String monitoredHomesCountText(int count) => choose(
    vi: "$count nhà đang được theo dõi",
    en: "$count homes monitored",
    zh: "正在监测 $count 个家庭",
    ko: "집 $count개를 모니터링 중입니다",
    ja: "$count 件の家を監視中",
    de: '$count Zuhause werden überwacht',
    ru: '$count домов под наблюдением',

    es: "$count casas supervisadas",
    fr: _fr(vi: "$count nhà đang được theo dõi", en: "$count homes monitored"),
  );

  String minuteText(int minutes) => choose(
    vi: "$minutes phút",
    en: "$minutes minutes",
    zh: "$minutes 分钟",
    ko: "$minutes분",
    ja: "$minutes 分",
    de: '$minutes Minuten',
    ru: '$minutes минут',

    es: "$minutes minutos",
    fr: _fr(vi: "$minutes phút", en: "$minutes minutes"),
  );

  String allHomeReminderAppliedText(
      int updatedHomes,
      int skippedHomes,
      ) => choose(
    vi: "Đã cài Reminder cho $updatedHomes nhà."
        "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}",
    en: "Reminder was set for $updatedHomes homes."
        "${skippedHomes > 0 ? "\n\n$skippedHomes homes were skipped because you do not have permission." : ""}",
    zh: "已为 $updatedHomes 个家庭设置 Reminder。"
        "${skippedHomes > 0 ? "\n\n$skippedHomes 个家庭因没有权限而被跳过。" : ""}",
    ko: "$updatedHomes개 집에 Reminder를 설정했습니다."
        "${skippedHomes > 0 ? "\n\n권한이 없어 $skippedHomes개 집을 건너뛰었습니다." : ""}",
    ja: "$updatedHomes 件の家に Reminder を設定しました。"
        "${skippedHomes > 0 ? "\n\n権限がないため $skippedHomes 件の家をスキップしました。" : ""}",
    de:
    'Reminder wurde für $updatedHomes Zuhause eingerichtet.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes Zuhause wurden übersprungen, weil du keine Berechtigung hast." : ""}',
    ru:
    'Reminder установлен для $updatedHomes домов.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes домов пропущено, потому что у вас нет разрешения." : ""}',

    es: "Reminder configurado para $updatedHomes casas."
        "${skippedHomes > 0 ? "\n\nSe omitieron $skippedHomes casas porque no tienes permiso." : ""}",
    fr: "Reminder configuré pour $updatedHomes maisons."
        "${skippedHomes > 0 ? "\n\n$skippedHomes maisons ont été ignorées car vous n'avez pas l'autorisation." : ""}",
  );

  String allHomeAlarmAppliedText({
    required int updatedDevices,
    required int updatedHomes,
    required String repeatLabel,
    required int skippedHomes,
  }) => choose(
    vi: "Đã cài Alarm cho $updatedDevices thiết bị trong $updatedHomes nhà.\n"
        "Thời gian lặp lại: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes nhà bị bỏ qua vì bạn không có quyền." : ""}",
    en: "Alarm was set for $updatedDevices devices across $updatedHomes homes.\n"
        "Repeat time: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes homes were skipped because you do not have permission." : ""}",
    zh: "已为 $updatedHomes 个家庭中的 $updatedDevices 台设备设置 Alarm。\n"
        "重复时间：$repeatLabel。"
        "${skippedHomes > 0 ? "\n\n$skippedHomes 个家庭因没有权限而被跳过。" : ""}",
    ko: "$updatedHomes개 집의 기기 $updatedDevices대에 Alarm을 설정했습니다.\n"
        "반복 시간: $repeatLabel."
        "${skippedHomes > 0 ? "\n\n권한이 없어 $skippedHomes개 집을 건너뛰었습니다." : ""}",
    ja: "$updatedHomes 件の家にある $updatedDevices 台のデバイスに Alarm を設定しました。\n"
        "繰り返し時間: $repeatLabel。"
        "${skippedHomes > 0 ? "\n\n権限がないため $skippedHomes 件の家をスキップしました。" : ""}",
    de:
    'Alarm wurde für $updatedDevices Geräte in $updatedHomes Zuhause eingerichtet.\n'
        'Wiederholungszeit: $repeatLabel.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes Zuhause wurden übersprungen, weil du keine Berechtigung hast." : ""}',
    ru:
    'Alarm установлен для $updatedDevices устройств в $updatedHomes домах.\n'
        'Время повтора: $repeatLabel.'
        '${skippedHomes > 0 ? "\n\n$skippedHomes домов пропущено, потому что у вас нет разрешения." : ""}',

    es: "Alarm configurado para $updatedDevices dispositivos en $updatedHomes casas.\n"
        "Tiempo de repetición: $repeatLabel."
        "${skippedHomes > 0 ? "\n\nSe omitieron $skippedHomes casas porque no tienes permiso." : ""}",
    fr: "Alarm configuré pour $updatedDevices appareils dans $updatedHomes maisons.\n"
        "Délai de répétition : $repeatLabel."
        "${skippedHomes > 0 ? "\n\n$skippedHomes maisons ont été ignorées car vous n'avez pas l'autorisation." : ""}",
  );

  String allHomeShareResultText(int skipped) {
    if (skipped <= 0) {
      return t("Đã chia sẻ nhà thành công.");
    }

    return choose(
      vi: "Đã chia sẻ các nhà bạn có quyền.\n\n$skipped nhà bị bỏ qua vì bạn không có quyền chia sẻ.",
      en: "Homes you manage were shared.\n\n$skipped homes were skipped because you do not have sharing permission.",
      zh: "已共享你有权限管理的家庭。\n\n$skipped 个家庭因没有共享权限而被跳过。",
      ko: "관리 권한이 있는 집을 공유했습니다.\n\n공유 권한이 없어 $skipped개의 집은 건너뛰었습니다.",
      ja: "管理権限のある家を共有しました。\n\n共有権限がないため $skipped 件の家をスキップしました。",
      de: 'Die von dir verwalteten Zuhause wurden geteilt.\n\n$skipped Zuhause wurden übersprungen, weil du keine Freigabeberechtigung hast.',
      ru: 'Дома, которыми вы управляете, были предоставлены.\n\n$skipped домов пропущено, потому что у вас нет разрешения на общий доступ.',

      es: "Se compartieron las casas que administras.\n\nSe omitieron $skipped casas porque no tienes permiso para compartirlas.",
      fr: "Les maisons que vous gérez ont été partagées.\n\n$skipped maisons ont été ignorées car vous n'avez pas l'autorisation de les partager.",
    );
  }

  String alarmAppliedToSecurityDevicesText(int count) => choose(
    vi: "Đã áp dụng Alarm cho $count thiết bị an ninh",
    en: "Alarm applied to $count security devices",
    zh: "Alarm 已应用到 $count 个安全设备",
    ko: "보안 기기 $count대에 Alarm을 적용했습니다",
    ja: "$count 台のセキュリティデバイスに Alarm を適用しました",
    de: 'Alarm auf $count Sicherheitsgeräte angewendet',
    ru: 'Alarm применен к $count устройствам безопасности',

    es: "Alarm aplicado a $count dispositivos de seguridad",
    fr: _fr(
      vi: "Đã áp dụng Alarm cho $count thiết bị an ninh",
      en: "Alarm applied to $count security devices",
    ),
  );

  String applySameAlarmScheduleToSecurityDevicesText(int count) => choose(
    vi: "Áp dụng cùng một lịch cho $count thiết bị an ninh",
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
  );

  String minutesAgo(int count) => choose(
    vi: "$count phút trước",
    en: "$count minutes ago",
    zh: "$count 分钟前",
    ko: "$count분 전",
    ja: "$count 分前",
    de: 'vor $count Minuten',
    ru: '$count минут назад',

    es: "hace $count minutos",
    fr: _fr(vi: "$count phút trước", en: "$count minutes ago"),
  );

  String hoursAgo(int count) => choose(
    vi: "$count giờ trước",
    en: "$count hours ago",
    zh: "$count 小时前",
    ko: "$count시간 전",
    ja: "$count 時間前",
    de: 'vor $count Stunden',
    ru: '$count часов назад',

    es: "hace $count horas",
    fr: _fr(vi: "$count giờ trước", en: "$count hours ago"),
  );

  String hoursAgoShort(int count) => choose(
    vi: "${count}h trước",
    en: "${count}h ago",
    zh: "$count 小时前",
    ko: "$count시간 전",
    ja: "$count 時間前",
    de: 'vor ${count}h',
    ru: '$countч назад',

    es: "hace ${count}h",
    fr: _fr(vi: "${count}h trước", en: "${count}h ago"),
  );

  String hoursMinutesAgoShort(int hours, int minutes) => choose(
    vi: "${hours}h$minutes' trước",
    en: "${hours}h ${minutes}m ago",
    zh: "$hours 小时 $minutes 分钟前",
    ko: "$hours시간 $minutes분 전",
    ja: "$hours 時間 $minutes 分前",
    de: 'vor ${hours}h ${minutes}m',
    ru: '$hoursч $minutesм назад',

    es: "hace ${hours}h ${minutes}m",
    fr: _fr(vi: "${hours}h$minutes' trước", en: "${hours}h ${minutes}m ago"),
  );

  String daysAgo(int count) => choose(
    vi: "$count ngày trước",
    en: "$count days ago",
    zh: "$count 天前",
    ko: "$count일 전",
    ja: "$count 日前",
    de: 'vor $count Tagen',
    ru: '$count дней назад',

    es: "hace $count días",
    fr: _fr(vi: "$count ngày trước", en: "$count days ago"),
  );

  String monthsAgo(int count) => choose(
    vi: "$count tháng trước",
    en: "$count months ago",
    zh: "$count 个月前",
    ko: "$count개월 전",
    ja: "$count か月前",
    de: 'vor $count Monaten',
    ru: '$count месяцев назад',

    es: "hace $count meses",
    fr: _fr(vi: "$count tháng trước", en: "$count months ago"),
  );

  String confirmRemoveMemberFromHomeText(String name) => choose(
    vi: "Bạn chắc chắn muốn xoá $name khỏi nhà này?",
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
  );

  String joinHomeRequestTitle(String targetEmail, String homeName) => choose(
    vi: "$targetEmail\nXin gia nhập \"$homeName\"",
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
  );

  String joinHomeRequestSubtitle(String homeName) => choose(
    vi: "Xin gia nhập \"$homeName\"",
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
  );

  String ownershipInviteTitle(String homeName) => choose(
    vi: "Bạn được mời nhận quyền nhà \"$homeName\"",
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
  );

  String homeInviteTitle(String ownerEmail, String homeName) => choose(
    vi: "$ownerEmail\nMời bạn gia nhập \"$homeName\"",
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
  );

  String homeInviteSubtitle(String homeName) => choose(
    vi: "Mời bạn gia nhập \"$homeName\"",
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
  );

  String deviceWarningsText(List<String> warnings) {
    final joined = warnings.join(", ");
    return choose(
      vi: "Cần kiểm tra: $joined",
      en: "Needs attention: $joined",
      zh: "需要检查: $joined",
      ko: "확인 필요: $joined",
      ja: "確認が必要: $joined",
      de: 'Aufmerksamkeit erforderlich: $joined',
      ru: 'Требует внимания: $joined',

      es: "Requiere revisión: $joined",
      fr: _fr(vi: "Cần kiểm tra: $joined", en: "Needs attention: $joined"),
    );
  }

  String updatedAgoText(String value) => choose(
    vi: "Cập nhật $value",
    en: "Updated $value",
    zh: "$value更新",
    ko: "$value에 업데이트됨",
    ja: "$valueに更新",
    de: 'Aktualisiert $value',
    ru: 'Обновлено $value',

    es: "Actualizado $value",
    fr: _fr(vi: "Cập nhật $value", en: "Updated $value"),
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
    vi: "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.",
    en: "Some members have unknown location. Ask them to open the app or check location permission.",
    zh: "有成员位置未知，请提醒他们打开应用或检查定位权限。",
    ko: "위치를 알 수 없는 구성원이 있습니다. 앱을 열거나 위치 권한을 확인하도록 알려주세요.",
    ja: "位置が不明なメンバーがいます。アプリを開くか位置情報権限を確認してもらってください。",
    de: 'Bei einigen Mitgliedern ist der Standort unbekannt. Bitte erinnere sie, die App zu öffnen oder die Standortberechtigung zu prüfen.',
    ru: 'У некоторых участников местоположение неизвестно. Попросите их открыть приложение или проверить разрешение геолокации.',

    es: "Hay miembros con ubicación desconocida; pídeles que abran la app o revisen el permiso de ubicación.",
    fr: _fr(
      vi: "Có thành viên chưa xác định vị trí, hãy nhắc họ mở app hoặc kiểm tra quyền vị trí.",
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
    vi: "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.",
    en: "Reminder is not set. Create a schedule to check your home regularly.",
    zh: "尚未设置提醒，建议创建定期检查家庭的提醒。",
    ko: "리마인더가 설정되어 있지 않습니다. 집을 정기적으로 확인할 일정을 만들어 보세요.",
    ja: "リマインダーが未設定です。定期的に家を確認する予定を作成してください。",
    de: 'Reminder ist nicht eingerichtet. Erstelle einen Zeitplan, um dein Zuhause regelmäßig zu prüfen.',
    ru: 'Reminder не настроен. Создайте расписание для регулярной проверки дома.',

    es: "Aún no has configurado Reminder. Crea una programación para revisar la casa periódicamente.",
    fr: _fr(
      vi: "Bạn chưa đặt Reminder, nên tạo lịch nhắc kiểm tra nhà định kỳ.",
      en: "Reminder is not set. Create a schedule to check your home regularly.",
    ),
  );

  String statusAlarmMissingSuggestion() => choose(
    vi: "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.",
    en: "Alarm schedule is not set. Enable protection for times you are usually away.",
    zh: "尚未设置警报时间，建议在经常不在家的时段启用防护。",
    ko: "알람 일정이 설정되어 있지 않습니다. 자주 집을 비우는 시간대에 보호를 켜세요.",
    ja: "アラーム予定が未設定です。普段不在の時間帯に保護を有効にしてください。",
    de: 'Der Alarm-Zeitplan ist nicht eingerichtet. Aktiviere Schutz für Zeiten, in denen normalerweise niemand zuhause ist.',
    ru: 'Расписание Alarm не настроено. Включите защиту на время, когда дома обычно никого нет.',

    es: "No has configurado una programación de Alarm; conviene activar la protección en los horarios en los que normalmente no hay nadie en casa.",
    fr: _fr(
      vi: "Bạn chưa đặt lịch Alarm, nên bật bảo vệ theo khung giờ thường vắng nhà.",
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
      en: "Repeat after $minutes minutes",
      zh: "$minutes 分钟后重复",
      ko: "$minutes분 후 반복",
      ja: "$minutes 分後に繰り返し",
      de: 'Wiederholung nach $minutes Minuten',
      ru: 'Повтор через $minutes минут',

      es: "Repetir después de $minutes minutos",
      fr: _fr(vi: "Lặp sau $minutes phút", en: "Repeat after $minutes minutes"),
    );
  }

  String securityModeActiveText(String repeatText) => choose(
    vi: "Đang dùng • $repeatText",
    en: "Active • $repeatText",
    zh: "使用中 • $repeatText",
    ko: "사용 중 • $repeatText",
    ja: "有効 • $repeatText",
    de: 'Aktiv • $repeatText',
    ru: 'Активно • $repeatText',

    es: "Activo • $repeatText",
    fr: _fr(vi: "Đang dùng • $repeatText", en: "Active • $repeatText"),
  );

  String securityModeMonitoringText(String repeatText) => choose(
    vi: "Giám sát an ninh • $repeatText",
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
  );

  String familyModeText(String mode) => choose(
    vi: "Gia đình: $mode",
    en: "Home mode: $mode",
    zh: "家庭模式：$mode",
    ko: "집 모드: $mode",
    ja: "家のモード: $mode",
    de: 'Zuhause-Modus: $mode',
    ru: 'Режим дома: $mode',

    es: "Modo de casa: $mode",
    fr: "Mode maison : $mode",
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
  );

  String doorsUsedTodayText(int count) => choose(
    vi: "Hôm nay các cửa đã được sử dụng $count lần",
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
  );

  String recentActivitiesCountText(int count) => choose(
    vi: "Đã ghi nhận $count hoạt động gần đây",
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
  );

  String systemNeedCheckText(int issueCount) => choose(
    vi: "Hệ thống: Cần kiểm tra $issueCount mục",
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
      vi: "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.",
      en: "The FCM token is ready, but Auto Away is missing a requirement.",
      zh: "FCM token 已准备好，但自动离家仍缺少条件。",
      ko: "FCM 토큰은 준비되었지만 자동 외출에 필요한 조건이 부족합니다.",
      ja: "FCM トークンは準備済みですが、自動外出に必要な条件が不足しています。",
      de: 'FCM-Token ist bereit, aber für Auto Away fehlt noch eine Voraussetzung.',
      ru: 'FCM-токен готов, но для Auto Away не хватает условия.',

      es: "El token FCM está listo, pero Auto Away aún necesita cumplir alguna condición.",
      fr: _fr(
        vi: "FCM token đã sẵn sàng, nhưng Auto rời khỏi nhà còn thiếu điều kiện.",
        en: "The FCM token is ready, but Auto Away is missing a requirement.",
      ),
    );
  }

  String emergencyDeviceRecommendationText(int emergencyTotal) => choose(
    vi: "Hiện có $emergencyTotal thiết bị khẩn cấp. Khuyến nghị tối thiểu: báo khói và SOS.",
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
  );

  String confirmTransferOwnerText(String targetEmail) => choose(
    vi: "Bạn chắc chắn muốn chuyển quyền chủ nhà cho:\n$targetEmail?",
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
  );

  Map<String, String>? get _activeTranslations => isSpanish
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

    final exact = translations?[text];
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
      );
    }

    final deviceMatch = RegExp(
      r"^(\d+) thiết bị đang được theo dõi$",
    ).firstMatch(text);
    if (deviceMatch != null) {
      final count = deviceMatch.group(1)!;
      return choose(
        vi: "$count thiết bị đang được theo dõi",
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
      );
    }

    final doorsUsedTodayMatch = RegExp(
      r"^Hôm nay các cửa đã được sử dụng (\d+) lần$",
    ).firstMatch(text);
    if (doorsUsedTodayMatch != null) {
      final count = doorsUsedTodayMatch.group(1)!;
      return choose(
        vi: "Hôm nay các cửa đã được sử dụng $count lần",
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
      );
    }

    final updatedMatch = RegExp(r"^Cập nhật (.+)$").firstMatch(text);
    if (updatedMatch != null) {
      final timeText = _translateAgoFragment(updatedMatch.group(1)!);
      return choose(
        vi: "Cập nhật $timeText",
        en: "Updated $timeText",
        zh: "$timeText更新",
        ko: "$timeText에 업데이트됨",
        ja: "$timeTextに更新",
        de: 'Aktualisiert $timeText',
        ru: 'Обновлено $timeText',

        es: "Actualizado $timeText",
        fr: _fr(vi: "Cập nhật $timeText", en: "Updated $timeText"),
      );
    }

    final minuteMatch = RegExp(
      r"^Dữ liệu gần nhất cập nhật (\d+) phút trước$",
    ).firstMatch(text);
    if (minuteMatch != null) {
      final count = minuteMatch.group(1)!;
      return choose(
        vi: "Dữ liệu gần nhất cập nhật $count phút trước",
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
      );
    }

    final hourMatch = RegExp(
      r"^Dữ liệu gần nhất cập nhật (\d+) giờ trước$",
    ).firstMatch(text);
    if (hourMatch != null) {
      final count = hourMatch.group(1)!;
      return choose(
        vi: "Dữ liệu gần nhất cập nhật $count giờ trước",
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
      );
    }

    final membersAtHomeMatch = RegExp(
      r"^Thành viên trong nhà: (\d+)/(\d+)$",
    ).firstMatch(text);
    if (membersAtHomeMatch != null) {
      final count =
          "${membersAtHomeMatch.group(1)}/${membersAtHomeMatch.group(2)}";
      return choose(
        vi: "Thành viên trong nhà: $count",
        en: "Members at home: $count",
        zh: "在家成员：$count",
        ko: "집 구성원: $count",
        ja: "在宅メンバー: $count",
        de: 'Mitglieder zuhause: $count',
        ru: 'Участников дома сейчас: $count',

        es: "Miembros en casa: $count",
        fr: _fr(
          vi: "Thành viên trong nhà: $count",
          en: "Members at home: $count",
        ),
      );
    }

    final membersAwayMatch = RegExp(
      r"^Thành viên bên ngoài: (\d+)/(\d+)$",
    ).firstMatch(text);
    if (membersAwayMatch != null) {
      final count = "${membersAwayMatch.group(1)}/${membersAwayMatch.group(2)}";
      return choose(
        vi: "Thành viên bên ngoài: $count",
        en: "Members away: $count",
        zh: "外出成员：$count",
        ko: "외출 구성원: $count",
        ja: "外出中のメンバー: $count",
        de: 'Mitglieder abwesend: $count',
        ru: 'Участников вне дома: $count',

        es: "Miembros fuera: $count",
        fr: _fr(vi: "Thành viên bên ngoài: $count", en: "Members away: $count"),
      );
    }

    final unknownLocationMatch = RegExp(
      r"^(?:Thành viên chưa xác định vị trí|Chưa xác định vị trí): (\d+)/(\d+)$",
    ).firstMatch(text);
    if (unknownLocationMatch != null) {
      final count =
          "${unknownLocationMatch.group(1)}/${unknownLocationMatch.group(2)}";
      return choose(
        vi: "Chưa xác định vị trí: $count",
        en: "Location unknown: $count",
        zh: "位置未知：$count",
        ko: "위치 알 수 없음: $count",
        ja: "位置不明: $count",
        de: 'Standort unbekannt: $count',
        ru: 'Местоположение неизвестно: $count',

        es: "Ubicación desconocida: $count",
        fr: _fr(
          vi: "Chưa xác định vị trí: $count",
          en: "Location unknown: $count",
        ),
      );
    }

    if (text.startsWith("Môi trường hiện tại: ")) {
      final environment = text
          .replaceFirst("Môi trường hiện tại: ", "")
          .split(RegExp(r"\s*/\s*"))
          .map(_translateStatusFragment)
          .join(" / ");
      return choose(
        vi: "Môi trường hiện tại: $environment",
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
      );
    }

    if (!isSpanish &&
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
        en: "$count minutes ago",
        zh: "$count 分钟前",
        ko: "$count분 전",
        ja: "$count 分前",
        de: 'vor $count Minuten',
        ru: '$count минут назад',

        es: "hace $count minutos",
        fr: _fr(vi: "$count phút trước", en: "$count minutes ago"),
      );
    }

    final hourMinuteMatch = RegExp(r"^(\d+)h(\d+)' trước$").firstMatch(clean);
    if (hourMinuteMatch != null) {
      final hours = hourMinuteMatch.group(1)!;
      final minutes = hourMinuteMatch.group(2)!;
      return choose(
        vi: "${hours}h$minutes' trước",
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
      );
    }

    final hourMatch = RegExp(r"^(\d+)h trước$").firstMatch(clean);
    if (hourMatch != null) {
      final count = hourMatch.group(1)!;
      return choose(
        vi: "${count}h trước",
        en: "${count}h ago",
        zh: "$count 小时前",
        ko: "$count시간 전",
        ja: "$count 時間前",
        de: 'vor ${count}h',
        ru: '$countч назад',

        es: "hace ${count}h",
        fr: _fr(vi: "${count}h trước", en: "${count}h ago"),
      );
    }

    final dayMatch = RegExp(r"^(\d+) ngày trước$").firstMatch(clean);
    if (dayMatch != null) {
      final count = dayMatch.group(1)!;
      return choose(
        vi: "$count ngày trước",
        en: "$count days ago",
        zh: "$count 天前",
        ko: "$count일 전",
        ja: "$count 日前",
        de: 'vor $count Tagen',
        ru: '$count дней назад',

        es: "hace $count días",
        fr: _fr(vi: "$count ngày trước", en: "$count days ago"),
      );
    }

    final monthMatch = RegExp(r"^(\d+) tháng trước$").firstMatch(clean);
    if (monthMatch != null) {
      final count = monthMatch.group(1)!;
      return choose(
        vi: "$count tháng trước",
        en: "$count months ago",
        zh: "$count 个月前",
        ko: "$count개월 전",
        ja: "$count か月前",
        de: 'vor $count Monaten',
        ru: '$count месяцев назад',

        es: "hace $count meses",
        fr: _fr(vi: "$count tháng trước", en: "$count months ago"),
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
          en: "SOS activated",
          zh: "SOS 已激活",
          ko: "SOS 활성화됨",
          ja: "SOS が作動しました",
          de: "SOS aktiviert",
          ru: "SOS активирован",
          es: "SOS activado",
          fr: _fr(vi: "Đã kích hoạt SOS", en: "SOS activated"),
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
    final exact = translations?[clean];

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
        "Đang mở trong giờ Alarm": "Alarm 時間中に開いています",
        "Đang mở": "開いています",
        "Phát hiện chuyển động": "動きを検知",
        "Phát hiện hiện diện": "在室を検知",
        "Phát hiện rung/chấn động": "振動/衝撃を検知",
        "Phát hiện kính vỡ": "ガラス破損を検知",
        "Nhiệt độ nguy hiểm": "危険な高温を検知",
        "Phát hiện khí CO": "一酸化炭素を検知",
        "Khóa đang mở khi nhà ở chế độ Bảo vệ": "警戒モード中にロックが解除されています",
        "Khóa đang mở trong giờ Alarm": "Alarm 時間中にロックが解除されています",
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
        "Đang mở trong giờ Alarm": "Alarm 시간 중 열림",
        "Đang mở": "열림",
        "Phát hiện chuyển động": "움직임 감지",
        "Phát hiện hiện diện": "재실 감지",
        "Phát hiện rung/chấn động": "진동/충격 감지",
        "Phát hiện kính vỡ": "유리 파손 감지",
        "Nhiệt độ nguy hiểm": "위험 온도 감지",
        "Phát hiện khí CO": "일산화탄소 감지",
        "Khóa đang mở khi nhà ở chế độ Bảo vệ": "보호 모드에서 잠금 해제됨",
        "Khóa đang mở trong giờ Alarm": "Alarm 시간 중 잠금 해제됨",
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
        "Đang mở trong giờ Alarm": "Alarm 时段内被打开",
        "Đang mở": "已打开",
        "Phát hiện chuyển động": "检测到移动",
        "Phát hiện hiện diện": "检测到有人",
        "Phát hiện rung/chấn động": "检测到震动",
        "Phát hiện kính vỡ": "检测到玻璃破碎",
        "Nhiệt độ nguy hiểm": "危险高温",
        "Phát hiện khí CO": "检测到一氧化碳",
        "Khóa đang mở khi nhà ở chế độ Bảo vệ": "家庭处于布防模式时门锁未锁",
        "Khóa đang mở trong giờ Alarm": "Alarm 时段内门锁未锁",
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
      "Đang mở trong giờ Alarm": "Open during Alarm hours",
      "Đang mở": "Open",
      "Phát hiện chuyển động": "Motion detected",
      "Phát hiện hiện diện": "Presence detected",
      "Phát hiện rung/chấn động": "Vibration detected",
      "Phát hiện kính vỡ": "Glass break detected",
      "Nhiệt độ nguy hiểm": "Dangerous heat detected",
      "Phát hiện khí CO": "Carbon monoxide detected",
      "Khóa đang mở khi nhà ở chế độ Bảo vệ": "Unlocked while Home is in Guard mode",
      "Khóa đang mở trong giờ Alarm": "Unlocked during Alarm hours",
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
      "Chưa có dữ liệu thiết bị để đánh giá": "No device data available for assessment",
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
    zh: "SafeHome Alarm",
    ko: "SafeHome Alarm",
    ja: "SafeHome Alarm",
    de: 'SafeHome Alarm',
    ru: 'SafeHome Alarm',

    es: "Alarm SafeHome",
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
    en: "Auto-closes in $time",
    zh: "$time 后自动关闭",
    ko: "$time 후 자동으로 닫힘",
    ja: "$time 後に自動で閉じます",
    de: 'Schließt automatisch in $time',
    ru: 'Автоматически закроется через $time',

    es: "Se cierra automáticamente en $time",
    fr: _fr(vi: "Tự đóng sau $time", en: "Auto-closes in $time"),
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

    es: "View and manage miembro roles",
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
