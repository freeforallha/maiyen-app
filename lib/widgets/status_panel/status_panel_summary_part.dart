part of '../status_panel.dart';

extension _StatusPanelSummaryPart on _StatusPanelState {
  void _showStatusSummary(BuildContext context) {
    if (!mounted) {
      return;
    }

    final strings = AppStrings.of(context);

    MaiYenNavigation.showModalSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
            ),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            decoration: const BoxDecoration(
              color: MaiYenColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: MaiYenColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.t("Tổng hợp trạng thái nhà"),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: MaiYenColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.insights_rounded,
                      color: MaiYenColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(child: _buildLiveStatusSummaryList(strings)),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<DatabaseEvent>? _sharedOwnerUidStream() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (currentUid.isEmpty || widget.homeId.trim().isEmpty) {
      return null;
    }

    return FirebaseDatabase.instance
        .ref("accounts/$currentUid/sharedHomes/${widget.homeId}/ownerUid")
        .onValue;
  }

  String _fallbackOwnerUid() {
    final ownerUid = widget.ownerUid.trim();

    if (ownerUid.isNotEmpty) {
      return ownerUid;
    }

    return FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  Widget _buildLiveStatusSummaryList(AppStrings strings) {
    final ownerStream = _sharedOwnerUidStream();

    if (ownerStream == null) {
      return _buildOwnerHomeStream(_fallbackOwnerUid(), strings);
    }

    return StreamBuilder<DatabaseEvent>(
      stream: ownerStream,
      builder: (context, ownerSnapshot) {
        final sharedOwnerUid =
            ownerSnapshot.data?.snapshot.value?.toString().trim() ?? "";
        final resolvedOwnerUid = sharedOwnerUid.isNotEmpty
            ? sharedOwnerUid
            : _fallbackOwnerUid();

        return _buildOwnerHomeStream(resolvedOwnerUid, strings);
      },
    );
  }

  Widget _buildOwnerHomeStream(String ownerUid, AppStrings strings) {
    final cleanOwnerUid = ownerUid.trim();
    final cleanHomeId = widget.homeId.trim();

    if (cleanOwnerUid.isEmpty || cleanHomeId.isEmpty) {
      return _summaryMessage(
        icon: Icons.home_work_outlined,
        text: strings.t("Chưa có dữ liệu trạng thái"),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      key: ValueKey("$cleanOwnerUid/$cleanHomeId"),
      stream: FirebaseDatabase.instance
          .ref("accounts/$cleanOwnerUid/homes/$cleanHomeId")
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _summaryMessage(
            icon: Icons.hourglass_empty_rounded,
            text: strings.loading,
          );
        }

        if (snapshot.hasError) {
          return _summaryMessage(
            icon: Icons.cloud_off_rounded,
            text: strings.t("Chưa có dữ liệu trạng thái"),
          );
        }

        final liveHome = safeMap(snapshot.data?.snapshot.value);

        if (liveHome.isEmpty) {
          return _summaryMessage(
            icon: Icons.home_work_outlined,
            text: strings.t("Chưa có dữ liệu trạng thái"),
          );
        }

        return _buildStatusSummarySections(liveHome, strings);
      },
    );
  }

  List<String> _uniqueStatusLines(Iterable<String> lines) {
    final result = <String>[];
    final seen = <String>{};

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line.isEmpty || !seen.add(line)) {
        continue;
      }

      result.add(line);
    }

    return result;
  }

  bool _isEnvironmentSummaryLine(String text) {
    final normalized = text.trim().toLowerCase();

    return normalized.startsWith("môi trường hiện tại:") ||
        normalized.startsWith("current environment:") ||
        normalized.startsWith("当前环境") ||
        normalized.startsWith("현재 환경:");
  }

  String _overviewEnvironmentLine({
    required Map<String, dynamic> liveOverall,
    required Map<String, dynamic> devices,
    required AppStrings strings,
  }) {
    if (liveOverall["hasEnvironmentDevice"] != true) {
      return "";
    }

    final panelEnvironment = widget.environmentText
        .replaceAll(" | ", " / ")
        .replaceAll(RegExp(r"\s+"), " ")
        .trim();
    final fallbackEnvironment = HomeDataHelpers.getHomeEnvironmentText(
      devices: devices,
    ).trim();
    final environment = panelEnvironment.isNotEmpty
        ? panelEnvironment
        : fallbackEnvironment;

    if (environment.isEmpty) {
      return "";
    }

    return strings.statusText("Môi trường hiện tại: $environment");
  }

  Widget _buildStatusSummarySections(
    Map<String, dynamic> liveHome,
    AppStrings strings,
  ) {
    final liveOverall = getHomeOverallStatus(liveHome);

    final rawEmergencyIssues = List<String>.from(
      liveOverall["emergencyIssues"] ?? const [],
    );

    final rawDangerIssues = List<String>.from(
      liveOverall["dangerIssues"] ?? const [],
    );

    final rawWarningIssues = List<String>.from(
      liveOverall["warningIssues"] ?? const [],
    );

    final rawPresenceWarnings = List<String>.from(
      liveOverall["presenceWarnings"] ?? const [],
    );

    final rawPresencePanelLines = List<String>.from(
      liveOverall["presencePanelLines"] ?? const [],
    );

    final emergencyIssues = _uniqueStatusLines(
      rawEmergencyIssues.map(strings.statusText),
    );

    final dangerIssues = _uniqueStatusLines(
      rawDangerIssues.map(strings.statusText),
    );

    final warningIssues = _uniqueStatusLines(
      [...rawWarningIssues, ...rawPresenceWarnings].map(strings.statusText),
    );

    final rawSafeSummary = List<String>.from(
      liveOverall["safeSummary"] ?? const [],
    );
    final rawIssueLines = <String>{
      ...rawEmergencyIssues.map((line) => line.trim()),
      ...rawDangerIssues.map((line) => line.trim()),
      ...rawWarningIssues.map((line) => line.trim()),
      ...rawPresenceWarnings.map((line) => line.trim()),
    };
    final safeSummary = _uniqueStatusLines(
      rawSafeSummary
          .where(
            (line) =>
                !_isEnvironmentSummaryLine(line) &&
                !rawIssueLines.contains(line.trim()),
          )
          .map(strings.statusText),
    );

    final actionSuggestions = _buildActionSuggestions(
      strings: strings,
      liveHome: liveHome,
      overall: liveOverall,
      rawEmergencyIssues: rawEmergencyIssues,
      rawDangerIssues: rawDangerIssues,
      rawWarningIssues: rawWarningIssues,
    );

    final normalizedLiveSecurityMode = normalizeSecurityMode(
      liveHome["securityMode"],
    );
    final liveSecurityMode = normalizedLiveSecurityMode == "armed"
        ? strings.t("Bảo vệ")
        : normalizedLiveSecurityMode == "unprotected"
        ? strings.t("Không bảo vệ")
        : strings.t("Bình thường");

    final devices = safeMap(liveHome["devices"]);
    final environmentLine = _overviewEnvironmentLine(
      liveOverall: liveOverall,
      devices: devices,
      strings: strings,
    );
    final presenceWarningLines = rawPresenceWarnings
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet();
    final overviewItems = _uniqueStatusLines([
      strings.familyModeText(liveSecurityMode),
      if (environmentLine.isNotEmpty) environmentLine,
      ...rawPresencePanelLines
          .where((line) => !presenceWarningLines.contains(line.trim()))
          .map(strings.statusText),
      ...safeSummary,
    ]);

    return ListView(
      shrinkWrap: true,
      children: [
        if (emergencyIssues.isNotEmpty) ...[
          _summarySection(
            title: strings.emergencySectionTitle(),
            icon: Icons.crisis_alert_rounded,
            color: MaiYenColors.emergency,
            items: emergencyIssues,
          ),
          const SizedBox(height: 12),
        ],
        if (dangerIssues.isNotEmpty) ...[
          _summarySection(
            title: strings.t("Cần xử lý ngay"),
            icon: Icons.warning_amber_rounded,
            color: MaiYenColors.danger,
            items: dangerIssues,
          ),
          const SizedBox(height: 12),
        ],
        if (warningIssues.isNotEmpty) ...[
          _summarySection(
            title: strings.t("Cần kiểm tra"),
            icon: Icons.info_outline_rounded,
            color: MaiYenColors.warning,
            items: warningIssues,
          ),
          const SizedBox(height: 12),
        ],
        _summarySection(
          title: strings.actionSuggestionTitle(),
          icon: Icons.tips_and_updates_rounded,
          color: MaiYenColors.info,
          items: actionSuggestions,
        ),
        const SizedBox(height: 12),
        _summarySection(
          title: strings.t("Tổng hợp trạng thái"),
          icon: Icons.bar_chart_rounded,
          color: MaiYenColors.safe,
          items: overviewItems.isEmpty
              ? [strings.t("Chưa có dữ liệu tổng quan")]
              : overviewItems,
        ),
      ],
    );
  }

  Widget _summaryMessage({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: MaiYenColors.textSecondary, size: 34),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MaiYenColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summarySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: MaiYenColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _summaryItem(text: item, color: color)),
        ],
      ),
    );
  }

  Widget _summaryItem({required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 9),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: MaiYenColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
