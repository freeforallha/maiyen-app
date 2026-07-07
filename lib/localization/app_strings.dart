import 'package:flutter/material.dart';

class AppStrings {
  final bool isEnglish;
  final bool isChinese;
  final bool isKorean;
  final bool isJapanese;

  const AppStrings._({
    required this.isEnglish,
    required this.isChinese,
    required this.isKorean,
    required this.isJapanese,
  });

  factory AppStrings.fromLocale(Locale locale) {
    return AppStrings._(
      isEnglish: locale.languageCode == "en",
      isChinese: locale.languageCode == "zh",
      isKorean: locale.languageCode == "ko",
      isJapanese: locale.languageCode == "ja",
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
  }) {
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

  String get permissionDeniedMessage => choose(
    vi: "Bạn không có quyền thực hiện thao tác này.",
    en: "You don't have permission to perform this action.",
    zh: "你没有权限执行此操作。",
    ko: "이 작업을 수행할 권한이 없습니다.",
    ja: "この操作を実行する権限がありません。",
  );

  String get genericOperationError => choose(
    vi: "Không thể hoàn tất thao tác. Vui lòng thử lại.",
    en: "Couldn't complete the action. Please try again.",
    zh: "无法完成此操作。请重试。",
    ko: "작업을 완료할 수 없습니다. 다시 시도해 주세요.",
    ja: "操作を完了できませんでした。もう一度お試しください。",
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
        );
      case "admin":
        return choose(
          vi: "Quản trị viên",
          en: "Admin",
          zh: "管理员",
          ko: "관리자",
          ja: "管理者",
        );
      case "member":
        return choose(
          vi: "Thành viên",
          en: "Member",
          zh: "成员",
          ko: "구성원",
          ja: "メンバー",
        );
    }

    return role;
  }

  String notificationTitle(
    Map<String, dynamic> item, {
    String homeName = "",
  }) {
    final type = _notificationString(item, "type").toLowerCase();
    final rawTitle = _notificationString(item, "title");

    if (_isMemberRoleNotification(type)) {
      return choose(
        vi: "Vai trò thành viên đã thay đổi",
        en: "Member role changed",
        zh: "成员角色已更改",
        ko: "구성원 역할이 변경됨",
        ja: "メンバーの役割が変更されました",
      );
    }

    if (_isAbnormalNotification(type, rawTitle)) {
      return choose(
        vi: "Phát hiện bất thường",
        en: "Abnormal activity detected",
        zh: "检测到异常",
        ko: "이상 감지",
        ja: "異常を検知",
      );
    }

    final doorClosed = _notificationDoorClosed(item);
    if (doorClosed != null &&
        (rawTitle.isEmpty ||
            _isDoorNotificationType(type) ||
            _doorClosedFromText(rawTitle) != null)) {
      return _doorStatusTitle(doorClosed);
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

    if (_isMemberRoleNotification(type)) {
      final actorName = _firstNotificationString(item, const ["actorName"]);
      final targetName = _firstNotificationString(
        item,
        const ["targetName", "memberName"],
      );
      final oldRole = _firstNotificationString(item, const ["oldRole"]);
      final newRole = _firstNotificationString(item, const ["newRole"]);

      if (actorName.isNotEmpty &&
          targetName.isNotEmpty &&
          oldRole.isNotEmpty &&
          newRole.isNotEmpty &&
          resolvedHomeName.isNotEmpty) {
        final oldRoleName = roleName(oldRole);
        final newRoleName = roleName(newRole);

        return choose(
          vi:
              "$actorName đã đổi vai trò của $targetName từ $oldRoleName thành $newRoleName trong nhà \"$resolvedHomeName\".",
          en:
              "$actorName changed $targetName's role from $oldRoleName to $newRoleName in \"$resolvedHomeName\".",
          zh:
              "$actorName 已将 $targetName 在“$resolvedHomeName”中的角色从 $oldRoleName 更改为 $newRoleName。",
          ko:
              "$actorName님이 \"$resolvedHomeName\"에서 $targetName님의 역할을 $oldRoleName에서 $newRoleName로 변경했습니다.",
          ja:
              "$actorName が「$resolvedHomeName」で $targetName の役割を $oldRoleName から $newRoleName に変更しました。",
        );
      }
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
              )
            : choose(
                vi: "\"$deviceName\" đang mở trong \"$resolvedHomeName\".",
                en: "\"$deviceName\" is open in \"$resolvedHomeName\".",
                zh: "“$deviceName”在“$resolvedHomeName”中处于打开状态。",
                ko: "\"$resolvedHomeName\"의 \"$deviceName\"이 열려 있습니다.",
                ja: "「$resolvedHomeName」の「$deviceName」が開いています。",
              );
      }

      if (deviceName.isNotEmpty) {
        return "$deviceName: ${_doorStatusTitle(doorClosed)}";
      }
    }

    final rawMessage = _firstNotificationString(
      item,
      const ["message", "body", "text"],
    );
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
          )
        : choose(
            vi: "Cửa đang mở",
            en: "Door is open",
            zh: "门已打开",
            ko: "문이 열려 있음",
            ja: "ドアが開いています",
          );
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
      "device_door",
      "status",
    }.contains(type);
  }

  bool _isDoorDevice(Map<String, dynamic> item) {
    final deviceType =
        _firstNotificationString(item, const ["deviceType", "entityType"])
            .toLowerCase();

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

    final contactValue = _firstNotificationValue(
      item,
      const ["contact", "isClosed", "closed"],
    );
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
    final direct = _firstNotificationString(
      item,
      const ["deviceName", "device_name"],
    );

    if (direct.isNotEmpty) {
      return direct;
    }

    final rawLine = _firstNotificationString(
      item,
      const ["message", "body", "text", "title"],
    );
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
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh":
        "No devices yet. Tap + to add one and start protecting your home.",
    "CHƯA AN TOÀN": "UNSAFE",
    "CẦN CHÚ Ý": "NEEDS ATTENTION",
    "ĐÃ AN TOÀN": "SAFE",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
        "Your home needs attention. Review the statuses below.",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.":
        "Your home is operating normally.",
    "Không có dấu hiệu khói hoặc SOS bất thường.":
        "No unusual smoke or SOS activity detected.",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.":
        "There is not enough recent activity for a deeper analysis.",
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
    "Đặt vị trí nhà và bật bảo vệ tự động":
        "Set home location and enable automatic protection",
    "Chuyển quyền chủ nhà hoặc xoá nhà":
        "Transfer home ownership or delete home",
    "Đặt Reminder / Alarm nhà đã chọn":
        "Set Reminder / Alarm for selected homes",
    "Chia sẻ nhà đã chọn": "Share selected homes",
    "Mở danh sách chia sẻ nhà": "Open home sharing list",
    "Xoá các nhà đã chọn?": "Delete selected homes?",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.":
        "Selected homes will be permanently deleted.",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn":
        "Or scan a QR code to request access to selected homes",
    "Email người nhận": "Recipient email",
    "Chia sẻ": "Share",
    "Email chưa đăng ký": "Email is not registered",
    "Chia sẻ hoàn tất": "Sharing complete",
    "Mở List chia sẻ nhà": "Open home sharing list",
    "Không có nhà nào bạn có quyền quản lý":
        "You do not manage any selected homes",
    "Chưa share cho ai": "Not shared with anyone yet",
    "Tìm nhà": "Search homes",
    "Xoá các nhà đã chọn ?": "Delete selected homes?",
    "Thông báo Home": "Home notifications",
    "Thông báo nhà": "Home notifications",
    "Vai trò thành viên đã thay đổi": "Member role changed",
    "Xoá tất cả thông báo?": "Delete all notifications?",
    "Toàn bộ thông báo nhà sẽ bị xoá.":
        "All home notifications will be deleted.",
    "Chưa có thông báo nào": "No notifications yet",
    "Chưa có thông báo": "No notifications",
    "Vuốt lên để tải thêm": "Swipe up to load more",
    "Không có thiết bị": "No devices",
    "Chỉ chủ nhà mới được xoá nhà": "Only the owner can delete this home",
    "Chỉ chủ nhà mới được chuyển quyền":
        "Only the owner can transfer ownership",
    "Lưu ý khi bật Alarm": "Alarm notice",
    "Alarm đã được bật": "Alarm enabled",
    "Đã hiểu": "Got it",
    "Lưu ý tạm tắt Alarm": "Alarm pause note",
    "Đã bật Alarm": "Alarm enabled",
    "Đã tắt Alarm": "Alarm disabled",
    "Tắt Alarm": "Turn off Alarm",
    "Cả ngày": "All day",
    "Bạn không có quyền thực hiện thao tác này.":
        "You don't have permission to perform this action.",
    "Không thể hoàn tất thao tác. Vui lòng thử lại.":
        "Couldn't complete the action. Please try again.",
    "QR gia nhập nhiều nhà không hợp lệ": "Invalid multi-home join QR code",
    "Bạn đang là chủ các nhà này": "You own these homes",
    "Một người dùng": "A user",
    "Yêu cầu gia nhập nhà": "Home join request",
    "Đã gửi yêu cầu gia nhập nhà": "Join request sent",
    "QR gia nhập không hợp lệ": "Invalid join QR code",
    "Bạn đang là chủ nhà này": "You already own this home",
    "QR này không phải mã xin gia nhập nhà":
        "This QR code is not a home join code",
    "Bạn không có quyền thêm thiết bị":
        "You do not have permission to add devices",
    "Đã mở chế độ thêm thiết bị": "Device pairing enabled",
    "Rời khỏi Home này?": "Leave this home?",
    "Nhà này và toàn bộ thiết bị bên trong sẽ bị xoá vĩnh viễn.":
        "This home and all its devices will be permanently deleted.",
    "Đã xoá nhà": "Home deleted",
    "QR của nhà này": "Home QR code",
    "Người khác quét mã này để gửi yêu cầu gia nhập nhà.":
        "Others can scan this code to request access to the home.",
    "Chia sẻ nhà": "Share home",
    "Quét QR để xin gia nhập nhà": "Scan QR to join a home",
    "Xin gia nhập nhà": "Request to join home",
    "Quét mã QR chia sẻ nhà": "Scan a home sharing QR code",
    "Mời thành viên bằng mã QR": "Invite member with QR code",
    "Không thể share cho chính bạn": "You cannot share with yourself",
    "Lời mời chia sẻ nhà": "Home sharing invitation",
    "Đã share home": "Home shared",
    "Chuyển quyền chủ nhà": "Transfer ownership",
    "Không thể chuyển quyền cho chính bạn":
        "You cannot transfer ownership to yourself",
    "Không tìm thấy user": "User not found",
    "Không tìm thấy tài khoản": "Account not found",
    "Xác nhận chuyển quyền": "Confirm ownership transfer",
    "Chuyển": "Transfer",
    "Xác nhận mật khẩu": "Confirm password",
    "Xác nhận": "Confirm",
    "Yêu cầu chuyển quyền chủ nhà": "Ownership transfer request",
    "Đã gửi yêu cầu chuyển quyền": "Transfer request sent",
    "Đã gửi yêu cầu chuyển quyền chủ nhà": "Ownership transfer request sent",
    "Bạn không có quyền xoá thiết bị":
        "You do not have permission to delete devices",
    "Xóa Device?": "Delete this device?",
    "Đã gửi yêu cầu xoá thiết bị": "Device deletion request sent",
    "Đang xoá thiết bị": "Deleting device",
    "Đăng xuất?": "Log out?",
    "Thêm nhà": "Add home",
    "Thêm nhà mới": "Add new home",
    "Tạo nhà mới": "Create new home",
    "Tạo một ngôi nhà mới của bạn": "Create a new home",
    "Quét mã QR được chủ nhà chia sẻ":
        "Scan the QR code shared by the homeowner",
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
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp":
        "Add a phone number for emergencies",
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
    "Xem lời mời chia sẻ và xin gia nhập":
        "View sharing invitations and join requests",
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
    "Bạn không có quyền quản lý phòng":
        "You don't have permission to manage rooms",
    "Đổi tên phòng": "Rename room",
    "Tên phòng": "Room name",
    "Xoá phòng": "Delete room",
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.":
        "Devices in this room will be moved to Unassigned.",
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
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ":
        "Set the home location before turning on Auto Guard",
    "Bán kính bảo vệ mặc định: 150 m": "Default protection radius: 150 m",
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
        "Each member needs to allow Always location permission so away/home status can work in the background.",
    "Lưu cài đặt": "Save settings",
    "Đã đặt vị trí nhà": "Home location set",
    "Đang lấy vị trí...": "Getting location...",
    "Đang lưu...": "Saving...",
    "Đổi tên hiển thị": "Change display name",
    "Cập nhật thông tin nhà": "Update home information",
    "Nhập địa chỉ của nhà": "Enter the home address",
    "Lưu thay đổi": "Save changes",
    "Tên này chỉ hiển thị riêng trên tài khoản của bạn.":
        "This name is only shown on your account.",
    "Tên và địa chỉ sẽ được cập nhật cho toàn bộ thành viên trong nhà.":
        "The name and address will be updated for all home members.",
    "Một thành viên": "A member",
    "Đã cập nhật thông tin nhà": "Home information updated",
    "Thay tên": "Rename",
    "Đã đổi tên thiết bị": "Device renamed",
    "Chưa chọn nhà để kiểm tra": "Select a home to test",
    "Hãy thực hiện kiểm tra bằng tài khoản Owner":
        "Run this test using the owner account",
    "Không đọc được dữ liệu nhà": "Unable to read home data",
    "Nhà cần có ít nhất một thiết bị để test":
        "The home needs at least one device for testing",
    "Đóng": "Close",
    "Đã thiết lập": "Set",
    "Quét QR": "Scan QR",
    "Quét QR để thêm thiết bị": "Scan QR to add a device",
    "Nhập HUB ID thủ công": "Enter HUB ID manually",
    "Bạn không có quyền sắp xếp phòng":
        "You do not have permission to reorder rooms",
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
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
        "Use the shared schedule set by the owner or admin",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn":
        "Use a personal schedule that only applies to your account",
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
    "Không tìm thấy nhà của thông báo này":
        "The home for this notification was not found",
    "Không tìm thấy thiết bị trong nhà này":
        "The device was not found in this home",
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
  };

  static const Map<String, String> _chinese = {
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
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh":
        "暂无设备。点击 + 添加设备，开始保护你的家庭。",
    "CHƯA AN TOÀN": "不安全",
    "CẦN CHÚ Ý": "需要注意",
    "ĐÃ AN TOÀN": "安全",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
        "家中有需要检查的迹象，请查看下面的状态。",
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
    "Thiết bị trong phòng này sẽ được chuyển về Chưa phân phòng.":
        "此房间中的设备将移动到未分配房间。",
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
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
        "每位成员都需要授予“始终允许”位置权限，离家/到家状态才能在后台工作。",
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
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
        "使用房主或管理员设置的共享日程",
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
  };

  static const Map<String, String> _korean = {
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
    "Không thể hoàn tất thao tác. Vui lòng thử lại.":
        "작업을 완료할 수 없습니다. 다시 시도해 주세요.",
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
    "Nhấn để xem chi tiết...": "자세히 보려면 누르세요...",
    "Nhà đang hoạt động bình thường": "집이 정상적으로 작동 중입니다",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "집이 안정적으로 작동 중입니다.",
    "Ngôi nhà đang hoạt động ổn định": "집이 안정적으로 작동 중입니다",
    "Thiết bị đang được giám sát": "기기 모니터링 중",
    "Chưa có dữ liệu trạng thái": "상태 데이터가 없습니다",
    "Chưa có dữ liệu tổng quan": "요약 데이터가 없습니다",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.":
        "자세히 분석할 새 활동이 많지 않습니다.",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
        "집에 확인이 필요한 신호가 있습니다. 아래 상태를 확인해 주세요.",
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
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
        "각 구성원은 앱이 백그라운드에서 실행될 때 외출/귀가 상태가 작동하도록 위치 권한을 항상 허용해야 합니다.",
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
    "Thêm số điện thoại để dùng cho các trường hợp khẩn cấp":
        "긴급 상황에 사용할 전화번호를 추가하세요",
    "Lưu thay đổi": "변경 사항 저장",
    "Hoàn tất": "완료",
    "Cài đặt": "설정",
    "Thông báo": "알림",
    "Tìm kiếm": "검색",
    "Tìm nhà": "집 검색",
    "Không có kết quả": "결과 없음",
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
    "Hoặc quét QR để xin gia nhập các nhà đã chọn":
        "또는 QR 코드를 스캔하여 선택한 집 참여를 요청하세요",
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
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
        "집 주인 또는 관리자가 설정한 공용 일정을 사용합니다",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn":
        "내 계정에만 적용되는 개인 일정을 사용합니다",
    "Thiết lập nhanh Alarm": "Alarm 빠른 설정",
    "Thiết lập nhanh toàn bộ thiết bị": "모든 기기 빠른 설정",
    "Không lặp lại": "반복 없음",
    "Thời gian lặp lại": "반복 시간",
    "Chưa thiết lập": "설정되지 않음",
    "Đã thiết lập": "설정됨",
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.":
        "Reminder는 선택한 시간에 집의 안전 상태를 확인하도록 알려줍니다.",
    "Thêm Reminder": "Reminder 추가",
    "Hành động này sẽ thay đổi thời gian báo động của một số thiết bị trong hôm nay...":
        "이 작업은 오늘 일부 기기의 Alarm 시간을 변경합니다...",
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
  };

  static const Map<String, String> _japanese = {
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
    "Tự động Bảo vệ khi rời nhà vẫn đang bật. Nếu mọi thành viên vẫn ở ngoài, hệ thống có thể tự bật lại Bảo vệ sau vài phút.":
        "外出時の自動警戒がまだ有効です。全員が外出中の場合、数分後に警戒モードが自動で再び有効になることがあります。",
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
    "Reminder sẽ nhắc bạn kiểm tra trạng thái an toàn của ngôi nhà vào giờ đã chọn.":
        "Reminder は、選択した時刻に家の安全状態を確認するよう通知します。",
    "Thêm Reminder": "Reminder を追加",
    "Alarm thiết bị": "デバイス Alarm",
    "Chế độ áp dụng": "適用モード",
    "Theo nhà": "家の設定",
    "Riêng tôi": "自分のみ",
    "Dùng lịch chung do Chủ nhà hoặc Quản trị viên thiết lập":
        "家の所有者または管理者が設定した共通スケジュールを使用します",
    "Dùng lịch riêng chỉ áp dụng cho tài khoản của bạn":
        "自分のアカウントにのみ適用される個人スケジュールを使用します",
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
    "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi app chạy nền.":
        "外出/帰宅状態をバックグラウンドで動作させるには、各メンバーが位置情報を「常に許可」にする必要があります。",
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
  };

  String t(String vi) {
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

  String statusText(String text) {
    if (text.trim().isEmpty) {
      return text;
    }

    final translations = isKorean
        ? _korean
        : isJapanese
        ? _japanese
        : isChinese
        ? _chinese
        : isEnglish
        ? _english
        : null;

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
      );
    }

    if (!isEnglish && !isChinese && !isKorean && !isJapanese) {
      return text;
    }

    final issueParts = text.split(": ");
    if (issueParts.length >= 2) {
      final name = issueParts.first;
      final details = issueParts.sublist(1).join(": ");
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
        );
      }

      final translatedDetails = details
          .split(" & ")
          .map(_translateStatusFragment)
          .join(" & ");
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
      );
    }

    return _translateStatusFragment(clean);
  }

  String _translateStatusFragment(String text) {
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
      "Khóa đang mở khi nhà ở chế độ Bảo vệ":
          "Unlocked while Home is in Guard mode",
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
  );

  String get alarmTitle => choose(
    vi: "Báo động SafeHome",
    en: "SafeHome Alarm",
    zh: "SafeHome Alarm",
    ko: "SafeHome Alarm",
    ja: "SafeHome Alarm",
  );

  String get alarmBody => choose(
    vi: "Có cảnh báo an ninh cần kiểm tra ngay.",
    en: "A security alert requires your attention.",
    zh: "有安全警报需要立即检查。",
    ko: "확인이 필요한 보안 경고가 있습니다.",
    ja: "確認が必要なセキュリティ警告があります。",
  );

  String get alarmFallback => choose(
    vi: "Có cảnh báo cần kiểm tra",
    en: "An alert requires your attention",
    zh: "有警报需要检查",
    ko: "확인이 필요한 경고가 있습니다",
    ja: "確認が必要な警告があります",
  );

  String get owner => t("Chủ nhà");
  String get admin => choose(
    vi: "Quản trị viên",
    en: "Admin",
    zh: "管理员",
    ko: "관리자",
    ja: "管理者",
  );
  String get member => choose(
    vi: "Thành viên",
    en: "Member",
    zh: "成员",
    ko: "구성원",
    ja: "メンバー",
  );
  String get notUpdated => t("Chưa cập nhật");
  String get unnamedHome => t("Nhà chưa đặt tên");
  String get role =>
      choose(vi: "Vai trò", en: "Role", zh: "角色", ko: "역할", ja: "役割");
  String get address => t("Địa chỉ");
  String get members => choose(
    vi: "Thành viên",
    en: "Members",
    zh: "成员",
    ko: "구성원",
    ja: "メンバー",
  );
  String get loading => choose(
    vi: "Đang tải...",
    en: "Loading...",
    zh: "正在加载...",
    ko: "로딩 중...",
    ja: "読み込み中...",
  );
  String get manageHome => choose(
    vi: "Quản lý nhà",
    en: "Home management",
    zh: "家庭管理",
    ko: "집 관리",
    ja: "家の管理",
  );
  String get shareHome => t("Chia sẻ nhà");
  String get shareHomeSubtitle => choose(
    vi: "Mời người khác tham gia nhà này",
    en: "Invite someone to join this home",
    zh: "邀请他人加入此家庭",
    ko: "다른 사람을 이 집에 초대합니다",
    ja: "他の人をこの家に招待します",
  );
  String get homeMembers => choose(
    vi: "Thành viên trong nhà",
    en: "Home members",
    zh: "家庭成员",
    ko: "집 구성원",
    ja: "家のメンバー",
  );
  String get homeMembersSubtitle => choose(
    vi: "Xem và quản lý quyền thành viên",
    en: "View and manage member roles",
    zh: "查看和管理成员权限",
    ko: "구성원 권한을 보고 관리합니다",
    ja: "メンバーの権限を表示・管理します",
  );
  String get manageRooms => choose(
    vi: "Quản lý phòng",
    en: "Manage rooms",
    zh: "管理房间",
    ko: "방 관리",
    ja: "部屋の管理",
  );
  String get manageRoomsSubtitle => choose(
    vi: "Thêm, đổi tên và sắp xếp phòng",
    en: "Add, rename and reorder rooms",
    zh: "添加、重命名和排序房间",
    ko: "방을 추가, 이름 변경 및 정렬합니다",
    ja: "部屋の追加、名前変更、並べ替えを行います",
  );
  String get allDevices => choose(
    vi: "Toàn bộ thiết bị",
    en: "All devices",
    zh: "全部设备",
    ko: "전체 기기",
    ja: "すべてのデバイス",
  );
  String get allDevicesSubtitle => choose(
    vi: "Kiểm tra thiết bị trong nhà này",
    en: "Review devices in this home",
    zh: "查看此家庭中的设备",
    ko: "이 집의 기기를 확인합니다",
    ja: "この家のデバイスを確認します",
  );
  String get transferOwnership => t("Chuyển quyền chủ nhà");
  String get transferOwnershipSubtitle => choose(
    vi: "Chuyển quyền sở hữu cho thành viên khác",
    en: "Transfer ownership to another member",
    zh: "将所有权转移给其他成员",
    ko: "소유권을 다른 구성원에게 이전합니다",
    ja: "所有権を他のメンバーに移転します",
  );
  String get accountAndSystem => choose(
    vi: "Tài khoản & hệ thống",
    en: "Account & system",
    zh: "账户与系统",
    ko: "계정 및 시스템",
    ja: "アカウントとシステム",
  );
  String get personalAccount => choose(
    vi: "Tài khoản cá nhân",
    en: "Personal account",
    zh: "个人账户",
    ko: "개인 계정",
    ja: "個人アカウント",
  );
  String get personalAccountSubtitle => choose(
    vi: "Hồ sơ, yêu cầu và lời mời tham gia",
    en: "Profile, requests and invitations",
    zh: "个人资料、申请和邀请",
    ko: "프로필, 요청 및 초대",
    ja: "プロフィール、リクエスト、招待",
  );
  String get language =>
      choose(vi: "Ngôn ngữ", en: "Language", zh: "语言", ko: "언어", ja: "言語");
  String get languageSubtitle => choose(
    vi: "Thay đổi ngôn ngữ hiển thị",
    en: "Change the display language",
    zh: "更改显示语言",
    ko: "표시 언어 변경",
    ja: "表示言語を変更",
  );
  String get chooseLanguage => choose(
    vi: "Chọn ngôn ngữ",
    en: "Choose language",
    zh: "选择语言",
    ko: "언어 선택",
    ja: "言語を選択",
  );
  String get vietnamese =>
      choose(vi: "Tiếng Việt", en: "Vietnamese", zh: "越南语", ko: "베트남어", ja: "ベトナム語");
  String get english =>
      choose(vi: "Tiếng Anh", en: "English", zh: "英语", ko: "영어", ja: "英語");
  String get chinese =>
      choose(vi: "Tiếng Trung", en: "Chinese", zh: "中文", ko: "중국어", ja: "中国語");
  String get korean =>
      choose(vi: "Tiếng Hàn", en: "Korean", zh: "韩语", ko: "한국어", ja: "韓国語");
  String get japanese =>
      choose(vi: "Tiếng Nhật", en: "Japanese", zh: "日语", ko: "일본어", ja: "日本語");
  String get currentLanguageName {
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
  );
  String get deleteHome => t("Xoá nhà");
  String get deleteHomeSubtitle => choose(
    vi: "Xoá toàn bộ dữ liệu và thiết bị",
    en: "Delete all home data and devices",
    zh: "删除所有家庭数据和设备",
    ko: "모든 집 데이터와 기기를 삭제합니다",
    ja: "家のデータとデバイスをすべて削除します",
  );
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
