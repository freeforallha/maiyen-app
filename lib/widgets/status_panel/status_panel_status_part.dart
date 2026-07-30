part of '../status_panel.dart';

extension _StatusPanelStatusPart on _StatusPanelState {
  Color _statusColor(String level) {
    if (level == "no_data") {
      return MaiYenColors.textSecondary;
    }

    if (level == "emergency") {
      return MaiYenColors.emergency;
    }

    if (level == "danger") {
      return MaiYenColors.danger;
    }

    if (level == "warning") {
      return MaiYenColors.warning;
    }

    return MaiYenColors.safe;
  }

  IconData _statusIcon(String level) {
    if (level == "no_data") {
      return Icons.remove_circle_outline_rounded;
    }

    if (level == "emergency") {
      return Icons.crisis_alert_rounded;
    }

    if (level == "danger") {
      return Icons.warning_amber_rounded;
    }

    if (level == "warning") {
      return Icons.info_outline_rounded;
    }

    return Icons.verified_rounded;
  }

  String _statusText(String level) {
    if (level == "no_data") {
      return "-------";
    }

    if (level == "emergency") {
      return _strings.emergencyStatusTitle();
    }

    if (level == "danger") {
      return _strings.t("CHƯA AN TOÀN");
    }

    if (level == "warning") {
      return _strings.t("CẦN CHÚ Ý");
    }

    return _strings.t("ĐÃ AN TOÀN");
  }

  List<Map<String, dynamic>> _sortedRecentEvents([
    Map<String, dynamic>? source,
  ]) {
    final events = (source ?? widget.homeEvents).values
        .map((item) => safeMap(item))
        .toList();

    events.sort((a, b) {
      final first = int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
      final second = int.tryParse(b["time"]?.toString() ?? "0") ?? 0;

      return second.compareTo(first);
    });

    return events.take(20).toList();
  }

  Map<String, int> _eventCounts(List<Map<String, dynamic>> recentEvents) {
    int openCount = 0;
    int smokeCount = 0;
    int sosCount = 0;

    for (final event in recentEvents) {
      final text = (event["text"] ?? "").toString().toLowerCase();

      if (text.contains("mở")) {
        openCount++;
      }

      if (text.contains("khói")) {
        smokeCount++;
      }

      if (text.contains("sos")) {
        sosCount++;
      }
    }

    return {"open": openCount, "smoke": smokeCount, "sos": sosCount};
  }

  List<String> _buildActionSuggestions({
    required AppStrings strings,
    required Map<String, dynamic> liveHome,
    required Map<String, dynamic> overall,
    required List<String> rawEmergencyIssues,
    required List<String> rawDangerIssues,
    required List<String> rawWarningIssues,
  }) {
    if (overall["hasDevices"] != true) {
      return [strings.statusAddFirstDeviceSuggestion()];
    }

    final suggestions = <String>[];

    void addSuggestion(String text) {
      final cleanText = text.trim();

      if (cleanText.isEmpty || suggestions.contains(cleanText)) {
        return;
      }

      if (suggestions.length >= 3) {
        return;
      }

      suggestions.add(cleanText);
    }

    final securityMode = normalizeSecurityMode(liveHome["securityMode"]);
    final securityModeSource =
        liveHome["securityModeSource"]?.toString().trim().toLowerCase() ?? "";
    final isArmed = securityMode == "armed";
    final isManualArmed =
        isArmed &&
        (securityModeSource.isEmpty || securityModeSource == "manual");

    final autoAway = safeMap(liveHome["autoAway"]);
    final autoAwayEnabled = autoAway["enabled"] == true;
    final presenceSummary = safeMap(liveHome["presenceSummary"]);

    int summaryCount(String key) {
      return int.tryParse(presenceSummary[key]?.toString() ?? "") ?? 0;
    }

    final insideCount = summaryCount("insideCount");
    final outsideCount = summaryCount("outsideCount");
    final unknownCount = summaryCount("unknownCount");
    final explicitTotalMemberCount = summaryCount("totalMemberCount");
    final totalMemberCount = explicitTotalMemberCount > 0
        ? explicitTotalMemberCount
        : insideCount + outsideCount + unknownCount;
    final hasPresenceCounts = totalMemberCount > 0;
    final noMemberInside =
        hasPresenceCounts && insideCount == 0 && unknownCount == 0;
    final hasMemberInside = insideCount > 0;

    var participantUnknownCount = summaryCount("participantUnknownCount");

    // Tương thích khi backend chưa kịp ghi participantUnknownCount.
    if (!presenceSummary.containsKey("participantUnknownCount")) {
      final memberPresenceStatus = safeMap(liveHome["memberPresenceStatus"]);

      participantUnknownCount = memberPresenceStatus.values.where((rawStatus) {
        final status = safeMap(rawStatus);
        final state = status["state"]?.toString().trim().toLowerCase() ?? "";

        return status["autoAwayParticipant"] == true && state == "unknown";
      }).length;
    }

    final devices = safeMap(liveHome["devices"]);
    var hasOpenDevice = false;
    var hasDisconnectedDevice = false;
    var hasLowBatteryDevice = false;

    for (final rawDevice in devices.values) {
      final device = safeMap(rawDevice);

      if (device.isEmpty) {
        continue;
      }

      final evaluation = evaluateDeviceStatus(
        device,
        securityMode: securityMode,
      );
      final deviceWarnings = List<String>.from(
        evaluation["warningIssues"] ?? const <String>[],
      );

      hasOpenDevice = hasOpenDevice || evaluation["isOpen"] == true;
      hasDisconnectedDevice =
          hasDisconnectedDevice || deviceWarnings.contains("Mất kết nối");
      hasLowBatteryDevice =
          hasLowBatteryDevice || deviceWarnings.contains("Pin yếu");
    }

    final hubNeedsAttention =
        overall["hubTracked"] == true &&
        overall["hubChecking"] != true &&
        overall["hubOnline"] != true;

    // Khi có tình huống khẩn cấp, chỉ giữ một hành động ưu tiên cao nhất
    // để tránh các gợi ý cấu hình hoặc bảo trì làm loãng thông tin.
    if (rawEmergencyIssues.isNotEmpty) {
      return [strings.statusEmergencyActionSuggestion()];
    }

    if (hasOpenDevice) {
      if (noMemberInside) {
        addSuggestion(strings.statusOpenHomeEmptySuggestion());
      } else if (isManualArmed) {
        // Chỉ dùng câu "trước khi giữ nhà ở chế độ Bảo vệ" khi người dùng
        // hoặc thành viên đã chủ động bật Bảo vệ.
        addSuggestion(strings.statusArmedOpenSuggestion());
      } else {
        // Auto Away và lịch tự động đã bật Bảo vệ rồi, nên không dùng câu
        // mang nghĩa người dùng còn đang chuẩn bị bật chế độ.
        addSuggestion(strings.t("Kiểm tra thiết bị trong nhà này"));
      }
    }

    // Có người ở nhà chỉ là lý do cân nhắc tắt Bảo vệ khi chế độ được bật
    // thủ công. Với Auto Away, hệ thống chỉ dựa vào nhóm thành viên đã chọn.
    if (isManualArmed && hasMemberInside) {
      addSuggestion(strings.statusMemberInsideWhileArmedSuggestion());
    }

    // Chỉ nhắc xử lý vị trí khi người chưa xác định thuộc chính nhóm dùng
    // để quyết định Auto Away. Thành viên không tham gia không được tạo ra
    // một gợi ý xử lý sai ngữ cảnh.
    if (autoAwayEnabled && participantUnknownCount > 0) {
      addSuggestion(strings.statusUnknownLocationSuggestion());
    }

    // Hub/MQTT mất kết nối không được dùng câu hướng dẫn thay pin của cảm biến.
    if (hubNeedsAttention) {
      addSuggestion(strings.t("Kiểm tra thiết bị trong nhà này"));
    }

    if (hasDisconnectedDevice) {
      addSuggestion(strings.statusDisconnectedDeviceSuggestion());
    }

    if (hasLowBatteryDevice) {
      addSuggestion(strings.statusLowBatterySuggestion());
    }

    // Bổ sung đường lui cho các cảnh báo khác như bị tháo, chuyển động,
    // nhiệt độ/độ ẩm cao, sóng yếu hoặc mất điện lưới để không báo sai rằng
    // "không có việc cần xử lý".
    if (suggestions.isEmpty &&
        (rawDangerIssues.isNotEmpty || rawWarningIssues.isNotEmpty)) {
      addSuggestion(strings.t("Kiểm tra thiết bị trong nhà này"));
    }

    if (suggestions.isEmpty) {
      addSuggestion(strings.statusNoImmediateActionSuggestion());
    }

    return suggestions;
  }

}
