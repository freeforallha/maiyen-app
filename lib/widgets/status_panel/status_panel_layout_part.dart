part of '../status_panel.dart';

extension _StatusPanelLayoutPart on _StatusPanelState {
  Widget _buildStatusPanel(BuildContext context) {
    final level = widget.overall["level"]?.toString() ?? "no_data";

    final hasDevices = widget.overall["hasDevices"] == true;

    final noData = level == "no_data" || !hasDevices;
    final emergencyStatus = level == "emergency";

    final issues = List<String>.from(widget.overall["issues"] ?? const []);

    final safeSummary = List<String>.from(
      widget.overall["safeSummary"] ?? const [],
    );

    final presencePanelLines = List<String>.from(
      widget.overall["presencePanelLines"] ?? const [],
    );

    // Trạng thái vị trí không làm đổi mức an toàn chung, nhưng luôn được
    // đưa vào vòng xoay của StatusPanel để người dùng thấy đủ trạng thái
    // toàn bộ thành viên và nhóm được chọn cho Tự động Bảo vệ.
    final allLines = issues.isNotEmpty
        ? _uniqueStatusLines([...issues, ...presencePanelLines])
        : _uniqueStatusLines([...presencePanelLines, ...safeSummary]);

    final normalizedSecurityMode = normalizeSecurityMode(widget.securityMode);
    final manualSecurityMode =
        normalizedSecurityMode == "armed" &&
        widget.securityModeSource == "manual";
    final unprotectedMode = normalizedSecurityMode == "unprotected";

    final manualSecurityModeText = _strings.t(
      "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường",
    );
    final unprotectedModeText = _strings.t(
      "Toàn bộ báo động của nhà đang tắt; hệ thống chỉ gửi thông báo.",
    );

    final normalFirstLine = allLines.isNotEmpty
        ? allLines.first
        : _strings.t("Chưa có dữ liệu trạng thái");

    final firstLine = noData
        ? _strings.t("Chưa đủ dữ liệu để đánh giá")
        : emergencyStatus
        ? normalFirstLine
        : unprotectedMode
        ? unprotectedModeText
        : manualSecurityMode
        ? manualSecurityModeText
        : normalFirstLine;

    final rotatingLines = noData
        ? <String>[]
        : emergencyStatus
        ? allLines.length > 1
              ? allLines.skip(1).toList()
              : <String>[]
        : unprotectedMode || manualSecurityMode
        ? allLines
        : allLines.length > 1
        ? allLines.skip(1).toList()
        : <String>[];

    final secondLine = rotatingLines.isNotEmpty
        ? rotatingLines[_broadcastIndex % rotatingLines.length]
        : _strings.t("Nhấn để xem chi tiết...");
    final displayFirstLine = _strings.statusText(firstLine);
    final displaySecondLine = _strings.statusText(secondLine);
    final displaySecondLineWithHint =
        displaySecondLine.endsWith("...") || displaySecondLine.endsWith("…")
        ? "$displaySecondLine →"
        : "$displaySecondLine... →";

    final emergencyPulseColor = _emergencyPulseDanger
        ? MaiYenColors.danger
        : MaiYenColors.warning;
    final statusColor = emergencyStatus
        ? emergencyPulseColor
        : _statusColor(level);
    final panelColor = emergencyStatus
        ? emergencyPulseColor.withValues(
            alpha: _emergencyPulseDanger ? 0.20 : 0.15,
          )
        : MaiYenColors.surface;
    final statusIcon = _statusIcon(level);
    final statusText = _statusText(level);

    final rawAlarmScheduleText =
        widget.alarmStart.trim().isNotEmpty && widget.alarmStart != "Tắt"
        ? widget.alarmStart.trim()
        : "";

    final alarmScheduleSet = rawAlarmScheduleText.isNotEmpty;

    final alarmScheduleText = alarmScheduleSet
        ? rawAlarmScheduleText
        : _strings.t("Tắt");

    final alarmPauseText = widget.alarmPauseText.trim();

    final alarmPauseSet =
        alarmPauseText.isNotEmpty &&
        alarmPauseText != _strings.t("Tắt") &&
        alarmPauseText != _strings.t("Chưa thiết lập");

    final recentEvents = _sortedRecentEvents();
    final eventCounts = _eventCounts(recentEvents);

    final openCount = eventCounts["open"] ?? 0;
    final smokeCount = eventCounts["smoke"] ?? 0;
    final sosCount = eventCounts["sos"] ?? 0;

    String subtitle;

    if (noData) {
      subtitle = "";
    } else if (issues.isNotEmpty) {
      subtitle = _strings.detectedIssuesCountText(issues.length);
    } else if (smokeCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo khói");
    } else if (sosCount > 0) {
      subtitle = _strings.t("Hôm nay đã ghi nhận cảnh báo SOS");
    } else if (openCount > 0) {
      subtitle = _strings.doorsUsedTodayText(openCount);
    } else if (recentEvents.isNotEmpty) {
      subtitle = _strings.recentActivitiesCountText(recentEvents.length);
    } else {
      subtitle = _strings.t("Ngôi nhà đang hoạt động ổn định");
    }

    final environment = widget.overall["hasEnvironmentDevice"] == true
        ? widget.environmentText
              .replaceAll("/", " | ")
              .replaceAll("  ", " ")
              .trim()
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStatusSummary(context),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: statusColor.withValues(
                  alpha: emergencyStatus ? 0.95 : 0.62,
                ),
                width: emergencyStatus ? 1.5 : 1.15,
              ),
              boxShadow: [
                BoxShadow(
                  color: emergencyStatus
                      ? statusColor.withValues(alpha: 0.20)
                      : Colors.black.withValues(alpha: 0.035),
                  blurRadius: emergencyStatus ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 19),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: statusColor,
                            ),
                          ),
                        ),
                        _buildEnvironmentAction(environment),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 43),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.2,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: issues.isNotEmpty
                              ? statusColor
                              : MaiYenColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(right: 43),
                      child: _statusLine(
                        text: displayFirstLine,
                        color: emergencyStatus
                            ? statusColor
                            : manualSecurityMode
                            ? MaiYenColors.danger
                            : issues.isNotEmpty
                            ? statusColor
                            : MaiYenColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Row(
                        key: ValueKey(displaySecondLine),
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: issues.isNotEmpty
                                  ? statusColor
                                  : MaiYenColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              displaySecondLineWithHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.15,
                                color: issues.isNotEmpty
                                    ? statusColor
                                    : MaiYenColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: _alarmStatusItem(
                            icon: normalizedSecurityMode == "unprotected"
                                ? Icons.shield_outlined
                                : Icons.shield_rounded,
                            value: normalizedSecurityMode == "armed"
                                ? _strings.t("Bảo vệ")
                                : normalizedSecurityMode == "unprotected"
                                ? _strings.t("Không bảo vệ")
                                : _strings.t("Bình thường"),
                            secondaryValue: normalizedSecurityMode == "armed"
                                ? _strings.armedSecurityModeSourceDetailLabel(
                                    widget.securityModeSource,
                                  )
                                : null,
                            active: normalizedSecurityMode != "normal",
                            activeColor: normalizedSecurityMode == "unprotected"
                                ? MaiYenColors.warning
                                : MaiYenColors.danger,
                            onTap: () => _showSecurityModeOptions(context),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: MaiYenColors.border,
                        ),
                        Expanded(
                          child: _alarmStatusItem(
                            icon: Icons.crisis_alert_rounded,
                            value: alarmScheduleText,
                            active: alarmScheduleSet,
                            activeColor: MaiYenColors.primary,
                            onTap: widget.onScheduleAlarm,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: MaiYenColors.border,
                        ),
                        Expanded(
                          child: _alarmStatusItem(
                            icon: Icons.pause_circle_outline_rounded,
                            value: alarmPauseSet
                                ? alarmPauseText
                                : _strings.t("Tắt"),
                            active: alarmPauseSet,
                            activeColor: MaiYenColors.warning,
                            onTap: widget.onAlarmPauseToday,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(top: 23, right: 0, child: _buildQuickSirenAction()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alarmStatusItem({
    required IconData icon,
    required String value,
    String? secondaryValue,
    required bool active,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    final color = active ? activeColor : MaiYenColors.textSecondary;
    final cleanSecondaryValue = secondaryValue?.trim() ?? "";
    final displayValue = cleanSecondaryValue.isEmpty
        ? value
        : "$value - $cleanSecondaryValue";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.9,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine({
    Key? key,
    required String text,
    required Color color,
    Widget? trailing,
  }) {
    return Row(
      key: key,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              height: 1.15,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}
