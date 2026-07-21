import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../safehome_theme.dart';
import '../localization/app_language_controller.dart';
import '../localization/app_strings.dart';
import '../navigation/safehome_navigation.dart';
import '../services/platform/platform_auto_away_task_service.dart';
import 'hub_info_sheet.dart';

String _languageSubtitle(String code) {
  switch (code) {
    case "vi":
      return "Vietnamese";
    case "en":
      return "English";
    case "zh":
      return "Chinese Simplified";
    case "ko":
      return "Korean";
    case "ja":
      return "Japanese";
    case "de":
      return "German";
    case "ru":
      return "Russian";
    case "fr":
      return "French";
    case "es":
      return "Spanish";
    case "id":
      return "Indonesian";
    case "th":
      return "Thai";
    case "ms":
      return "Malay";
    case "fil":
      return "Filipino";
    case "km":
      return "Khmer";
    case "my":
      return "Burmese • Myanmar";
    case "lo":
      return appLanguageController.languageCode == "vi" ? "Tiếng Lào" : "Lao";
    case "ta":
      return "Tamil • Singapore";
    case "pt":
      return "Portuguese • Timor-Leste";
    case "tet":
      return "Tetum • Timor-Leste";
    case "it":
      return "Italian • Italy";
    case "pl":
      return "Polish • Poland";
    case "nl":
      return "Dutch • Netherlands";
    case "cs":
      return "Czech • Czechia";
    case "sk":
      return "Slovak • Slovakia";
    case "uk":
      return "Ukrainian • Ukraine";
    case "ro":
      return "Romanian • Romania";
    case "hu":
      return "Hungarian • Hungary";
    case "bg":
      return "Bulgarian • Bulgaria";
    case "hr":
      return "Croatian • Croatia";
    case "sr":
      return "Serbian • Serbia";
    case "bs":
      return "Bosnian • Bosnia and Herzegovina";
    case "sl":
      return "Slovenian • Slovenia";
    case "mk":
      return "Macedonian • North Macedonia";
    case "sq":
      return "Albanian • Albania";
    case "el":
      return "Greek • Greece";
    case "tr":
      return "Turkish • Türkiye";
    case "sv":
      return "Swedish • Sweden";
    case "da":
      return "Danish • Denmark";
    case "nb":
      return "Norwegian Bokmål • Norway";
    case "fi":
      return "Finnish • Finland";
    case "is":
      return "Icelandic • Iceland";
    case "et":
      return "Estonian • Estonia";
    case "lv":
      return "Latvian • Latvia";
    case "lt":
      return "Lithuanian • Lithuania";
    case "ga":
      return "Irish • Ireland";
    case "mt":
      return "Maltese • Malta";
    case "be":
      return "Belarusian • Belarus";
    case "lb":
      return "Luxembourgish • Luxembourg";
    case "ca":
      return "Catalan • Andorra";
    case "cnr":
      return "Montenegrin • Montenegro";
    case "hy":
      return "Armenian • Armenia";
    case "ka":
      return "Georgian • Georgia";
    case "az":
      return "Azerbaijani • Azerbaijan";
    default:
      return code;
  }
}

String _languageSearchAliases(String code) {
  return switch (code) {
    "lo" => "lao tiếng lào ລາວ",
    "ta" => "tamil tiếng tamil தமிழ் singapore",
    "pt" => "portuguese tiếng bồ đào nha português timor leste",
    "tet" => "tetum tiếng tetum tetun timor leste",
    "it" => "italian italiano tiếng ý italy italia",
    "pl" => "polish polski tiếng ba lan poland polska",
    "nl" => "dutch nederlands tiếng hà lan netherlands nederland",
    "cs" => "czech čeština tiếng séc czechia česko",
    "sk" => "slovak slovenčina tiếng slovakia slovensko",
    "uk" => "ukrainian українська tiếng ukraina ukraine україна",
    "ro" => "romanian română tiếng rumani romania românia",
    "hu" => "hungarian magyar tiếng hungary magyarország",
    "bg" => "bulgarian български tiếng bulgaria българия",
    "hr" => "croatian hrvatski tiếng croatia hrvatska",
    "sr" => "serbian srpski tiếng serbia srbija",
    "bs" => "bosnian bosanski tiếng bosnia bosna hercegovina",
    "sl" => "slovenian slovenščina tiếng slovenia slovenija",
    "mk" => "macedonian македонски tiếng bắc macedonia severna makedonija",
    "sq" => "albanian shqip tiếng albania shqipëri",
    "el" => "greek ελληνικά tiếng hy lạp greece ελλάδα",
    "tr" => "turkish türkçe tiếng thổ nhĩ kỳ türkiye",
    "sv" => "swedish svenska tiếng thụy điển sweden sverige",
    "da" => "danish dansk tiếng đan mạch denmark danmark",
    "nb" => "norwegian norsk bokmål tiếng na uy norway norge",
    "fi" => "finnish suomi tiếng phần lan finland",
    "is" => "icelandic íslenska tiếng iceland iceland",
    "et" => "estonian eesti tiếng estonia estonia",
    "lv" => "latvian latviešu tiếng latvia latvija",
    "lt" => "lithuanian lietuvių tiếng litva lithuania lietuva",
    "ga" => "irish gaeilge tiếng ireland éire",
    "mt" => "maltese malti tiếng malta",
    "be" => "belarusian беларуская tiếng belarus беларусь",
    "lb" => "luxembourgish lëtzebuergesch tiếng luxembourg luxemburg",
    "ca" => "catalan català tiếng catalan andorra catalunya",
    "cnr" => "montenegrin crnogorski tiếng montenegro crna gora",
    "hy" => "armenian հայերեն tiếng armenia hayastan",
    "ka" => "georgian ქართული tiếng georgia sakartvelo",
    "az" => "azerbaijani azərbaycan dili tiếng azerbaijan azərbaycan",
    _ => "",
  };
}

String _languageFlag(String code) {
  return AppLanguageController.languageFlags[code] ?? "🌐";
}

Future<void> _showLanguageSheet(BuildContext context) async {
  final strings = AppStrings.of(context);
  bool isSearching = false;
  String query = "";

  Widget languageOption({
    required BuildContext sheetContext,
    required String code,
    required String title,
    required String subtitle,
  }) {
    final selected = appLanguageController.languageCode == code;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await appLanguageController.setLanguageCode(code);
            await PlatformAutoAwayTaskService.refreshNotificationLanguage();

            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? SafeHomeColors.primary
                    : SafeHomeColors.border,
                width: selected ? 1.4 : 0.9,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? SafeHomeColors.primarySoft
                        : SafeHomeColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _languageFlag(code),
                    style: TextStyle(
                      color: selected
                          ? SafeHomeColors.primary
                          : SafeHomeColors.textSecondary,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: SafeHomeColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: SafeHomeColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  await SafeHomeNavigation.pushChildPage<void>(
    context: context,
    routeName: "language",
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final q = query.trim().toLowerCase();
          final visibleCodes =
              AppLanguageController.supportedCodes.where((code) {
                final title =
                    AppLanguageController.languageLabels[code] ?? code;
                final subtitle = _languageSubtitle(code);
                final aliases = _languageSearchAliases(code);

                if (q.isEmpty) {
                  return true;
                }

                return code.toLowerCase().contains(q) ||
                    title.toLowerCase().contains(q) ||
                    subtitle.toLowerCase().contains(q) ||
                    aliases.contains(q);
              }).toList()..sort(
                (a, b) => _languageSubtitle(
                  a,
                ).toLowerCase().compareTo(_languageSubtitle(b).toLowerCase()),
              );
          final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
          final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: ColoredBox(
              color: SafeHomeColors.background,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: SafeHomeColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: SafeHomeColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.chooseLanguage,
                            style: const TextStyle(
                              color: SafeHomeColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.35,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.t("Tìm ngôn ngữ"),
                          style: IconButton.styleFrom(
                            backgroundColor: SafeHomeColors.surface,
                            foregroundColor: SafeHomeColors.primary,
                            side: const BorderSide(
                              color: SafeHomeColors.border,
                              width: 0.9,
                            ),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              isSearching = !isSearching;

                              if (!isSearching) {
                                query = "";
                              }
                            });
                          },
                          icon: Icon(
                            isSearching
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                          ),
                        ),
                      ],
                    ),
                    if (isSearching) ...[
                      const SizedBox(height: 14),
                      TextField(
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: strings.t("Tìm ngôn ngữ"),
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: SafeHomeColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.only(bottom: 18 + bottomSafe),
                        children: visibleCodes.isEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Text(
                                    strings.t("Không có kết quả"),
                                    style: const TextStyle(
                                      color: SafeHomeColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]
                            : [
                                for (final code in visibleCodes)
                                  languageOption(
                                    sheetContext: sheetContext,
                                    code: code,
                                    title:
                                        AppLanguageController
                                            .languageLabels[code] ??
                                        code,
                                    subtitle: _languageSubtitle(code),
                                  ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void showSettingsSheet({
  required String homeId,
  required String ownerUid,
  required String homeName,
  required String homeAddress,
  required String role,
  required BuildContext context,
  required VoidCallback onShareRequests,
  required VoidCallback onShare,
  required VoidCallback onShareList,
  required VoidCallback onRooms,
  required VoidCallback onAutoAway,
  required VoidCallback onLogout,
  required VoidCallback onRenameHome,
  required VoidCallback onSecurityTest,
  required VoidCallback onDeleteHome,
  required ValueNotifier<int> inviteCountNotifier,
  required VoidCallback onTransferOwner,
  required VoidCallback onAllDevices,
  required VoidCallback onAccount,
}) {
  int hiddenSecurityTapCount = 0;
  DateTime? lastHiddenSecurityTapAt;
  var strings = AppStrings.fromLocale(appLanguageController.locale);

  final normalizedOwnerUid = ownerUid.trim();

  final memberCountFuture = FirebaseDatabase.instance
      .ref("sharedByHome/$homeId")
      .get()
      .then<int>((snapshot) {
        final raw = snapshot.value;

        if (raw is! Map) {
          return normalizedOwnerUid.isEmpty ? 0 : 1;
        }

        final memberUids = raw.entries
            .where((entry) => entry.value != null)
            .map((entry) => entry.key.toString())
            .toSet();

        if (normalizedOwnerUid.isNotEmpty) {
          memberUids.add(normalizedOwnerUid);
        }

        return memberUids.length;
      })
      .catchError((_) => normalizedOwnerUid.isEmpty ? 0 : 1);

  void handleHiddenSecurityTap(BuildContext sheetContext) {
    if (role != "owner") {
      return;
    }

    final now = DateTime.now();

    final previousTapAt = lastHiddenSecurityTapAt;
    final isContinuous =
        previousTapAt != null &&
        now.difference(previousTapAt).inMilliseconds <= 1500;

    if (isContinuous) {
      hiddenSecurityTapCount++;
    } else {
      hiddenSecurityTapCount = 1;
    }

    lastHiddenSecurityTapAt = now;

    if (hiddenSecurityTapCount < 5) {
      return;
    }

    hiddenSecurityTapCount = 0;
    lastHiddenSecurityTapAt = null;

    Navigator.of(sheetContext).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSecurityTest();
    });
  }

  void openChild(VoidCallback action) {
    action();
  }

  IconData roleIcon() {
    if (role == "owner") {
      return Icons.workspace_premium_rounded;
    }

    if (role == "admin") {
      return Icons.admin_panel_settings_rounded;
    }

    return Icons.person_rounded;
  }

  Color roleColor() {
    if (role == "owner") {
      return const Color(0xFFD79A24);
    }

    if (role == "admin") {
      return const Color(0xFF7656C8);
    }

    return SafeHomeColors.info;
  }

  String roleText() {
    if (role == "owner") {
      return strings.owner;
    }

    if (role == "admin") {
      return strings.admin;
    }

    return strings.member;
  }

  Widget homeInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    final displayValue = value.trim().isEmpty
        ? strings.notUpdated
        : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: valueColor ?? SafeHomeColors.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                      color: SafeHomeColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: displayValue,
                    style: TextStyle(
                      color: valueColor ?? SafeHomeColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 9),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: SafeHomeColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.75,
          ),
        ),
      ),
    );
  }

  Widget tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
    bool destructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: destructive
                    ? SafeHomeColors.danger.withValues(alpha: 0.16)
                    : SafeHomeColors.border,
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.028),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: destructive
                              ? SafeHomeColors.danger
                              : SafeHomeColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SafeHomeColors.textSecondary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showHomeManagementSheet(BuildContext settingsSheetContext) {
    SafeHomeNavigation.pushChildPage<void>(
      context: settingsSheetContext,
      routeName: "home_management",
      builder: (managementContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: const BoxDecoration(
              color: SafeHomeColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.home_work_rounded,
                      color: SafeHomeColors.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        strings.t("Quản lý nhà"),
                        style: const TextStyle(
                          color: SafeHomeColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                tile(
                  icon: Icons.hub_rounded,
                  title: "${strings.t('Hub trung tâm')} SafeHome (HUB)",
                  subtitle: "${strings.t('Tình trạng')} • Device ID • Wi-Fi",
                  color: SafeHomeColors.primaryDark,
                  onTap: () {
                    showHubInfoSheet(
                      context: managementContext,
                      ownerUid: ownerUid,
                      homeId: homeId,
                      homeName: homeName,
                    );
                  },
                ),

                tile(
                  icon: Icons.swap_horiz_rounded,
                  title: strings.transferOwnership,
                  subtitle: strings.transferOwnershipSubtitle,
                  color: const Color(0xFF7656C8),
                  onTap: () {
                    openChild(onTransferOwner);
                  },
                ),

                tile(
                  icon: Icons.delete_forever_rounded,
                  title: strings.deleteHome,
                  subtitle: strings.deleteHomeSubtitle,
                  color: SafeHomeColors.danger,
                  destructive: true,
                  onTap: () {
                    openChild(onDeleteHome);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SafeHomeNavigation.pushChildPage<void>(
    context: context,
    routeName: "settings",
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: appLanguageController,
        builder: (context, _) {
          strings = AppStrings.fromLocale(appLanguageController.locale);
          final bottomPadding = MediaQuery.paddingOf(sheetContext).bottom;

          return ColoredBox(
            color: SafeHomeColors.background,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 20 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SafeHomeColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: SafeHomeColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 108,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: SafeHomeColors.primarySoft,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: SafeHomeColors.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.home_rounded,
                                        color: SafeHomeColors.primary,
                                        size: 36,
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Material(
                                        color: SafeHomeColors.primary,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          onTap: () {
                                            openChild(onRenameHome);
                                          },
                                          customBorder: const CircleBorder(),
                                          child: const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Icon(
                                              Icons.edit_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    handleHiddenSecurityTap(sheetContext);
                                  },
                                  child: Text(
                                    homeName.trim().isNotEmpty
                                        ? homeName.trim()
                                        : strings.unnamedHome,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: SafeHomeColors.textPrimary,
                                      fontSize: 15,
                                      height: 1.15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(
                            width: 25,
                            thickness: 1,
                            color: SafeHomeColors.border,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                homeInfoRow(
                                  icon: roleIcon(),
                                  label: strings.role,
                                  value: roleText(),
                                  valueColor: roleColor(),
                                ),
                                homeInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: strings.address,
                                  value: homeAddress,
                                  maxLines: 2,
                                ),
                                FutureBuilder<int>(
                                  future: memberCountFuture,
                                  builder: (context, snapshot) {
                                    final value =
                                        snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? strings.loading
                                        : "${snapshot.data ?? 0}";

                                    return homeInfoRow(
                                      icon: Icons.people_alt_rounded,
                                      label: strings.members,
                                      value: value,
                                    );
                                  },
                                ),
                                homeInfoRow(
                                  icon: Icons.fingerprint_rounded,
                                  label: "HomeID",
                                  value: homeId,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  sectionTitle(strings.manageHome),

                  if (role == "owner" || role == "admin")
                    tile(
                      icon: Icons.share_rounded,
                      title: strings.shareHome,
                      subtitle: strings.shareHomeSubtitle,
                      color: SafeHomeColors.info,
                      onTap: () {
                        openChild(onShare);
                      },
                    ),

                  tile(
                    icon: Icons.people_alt_rounded,
                    title: strings.homeMembers,
                    subtitle: strings.homeMembersSubtitle,
                    color: SafeHomeColors.safe,
                    onTap: () {
                      openChild(onShareList);
                    },
                  ),

                  if (role == "owner" || role == "admin")
                    tile(
                      icon: Icons.location_on_rounded,
                      title: strings.t("Tự động Bảo vệ khi rời nhà"),
                      subtitle: strings.t("Đặt vị trí nhà và bật bảo vệ tự động"),
                      color: const Color(0xFF2F8F6B),
                      onTap: () {
                        openChild(onAutoAway);
                      },
                    ),

                  if (role == "owner" || role == "admin")
                    tile(
                      icon: Icons.meeting_room_rounded,
                      title: strings.manageRooms,
                      subtitle: strings.manageRoomsSubtitle,
                      color: SafeHomeColors.warning,
                      onTap: () {
                        openChild(onRooms);
                      },
                    ),

                  tile(
                    icon: Icons.sensors_rounded,
                    title: strings.allDevices,
                    subtitle: strings.allDevicesSubtitle,
                    color: const Color(0xFF576FD0),
                    onTap: () {
                      openChild(onAllDevices);
                    },
                  ),

                  if (role == "owner")
                    tile(
                      icon: Icons.home_work_rounded,
                      title: strings.t("Quản lý nhà"),
                      subtitle: strings.t("Chuyển quyền chủ nhà hoặc xoá nhà"),
                      color: const Color(0xFF7656C8),
                      onTap: () {
                        showHomeManagementSheet(sheetContext);
                      },
                    ),

                  const SizedBox(height: 5),
                  sectionTitle(strings.accountAndSystem),

                  tile(
                    icon: Icons.person_rounded,
                    title: strings.personalAccount,
                    subtitle: strings.personalAccountSubtitle,
                    color: SafeHomeColors.primary,
                    trailing: ValueListenableBuilder<int>(
                      valueListenable: inviteCountNotifier,
                      builder: (_, inviteCount, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (inviteCount > 0)
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: SafeHomeColors.danger,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  inviteCount > 99 ? "99+" : "$inviteCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            if (inviteCount > 0) const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: SafeHomeColors.textSecondary,
                            ),
                          ],
                        );
                      },
                    ),
                    onTap: () {
                      openChild(onAccount);
                    },
                  ),

                  tile(
                    icon: Icons.language_rounded,
                    title: strings.language,
                    subtitle:
                        "${strings.languageSubtitle} • "
                        "${strings.currentLanguageName}",
                    color: SafeHomeColors.primary,
                    onTap: () {
                      _showLanguageSheet(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
