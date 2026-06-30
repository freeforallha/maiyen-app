import 'package:flutter/material.dart';

class AppStrings {
  final bool isEnglish;

  const AppStrings._({
    required this.isEnglish,
  });

  factory AppStrings.fromLocale(Locale locale) {
    return AppStrings._(
      isEnglish: locale.languageCode == "en",
    );
  }

  static AppStrings of(BuildContext context) {
    return AppStrings.fromLocale(
      Localizations.localeOf(context),
    );
  }

  String choose({
    required String vi,
    required String en,
  }) {
    return isEnglish ? en : vi;
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
    "Chưa nhận diện": "Unrecognized device",
    "Chưa có cập nhật": "No updates yet",
    "Chưa có thiết bị, hãy nhấn nút + để thêm để bắt đầu duy trì an ninh":
    "No devices yet. Tap + to add one and start monitoring your home.",
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
    "Cài đặt cảnh báo cho nhà hiện tại":
    "Alert settings for this home",
    "Nhận cảnh báo Alarm": "Receive Alarm alerts",
    "Đang bật cho tài khoản này": "Enabled for this account",
    "Đang tắt cho tài khoản này": "Disabled for this account",
    "Hẹn giờ Reminder": "Reminder schedule",
    "Nhắc kiểm tra nhà theo thời gian": "Schedule home check reminders",
    "Hẹn giờ Alarm": "Alarm schedule",
    "Chưa thiết lập": "Not configured",
    "Chưa thiết lập thời gian": "No schedule configured",
    "Tổng hợp trạng thái nhà": "Home status summary",
    "Cần xử lý ngay": "Action required",
    "Cần kiểm tra": "Needs attention",
    "Đánh giá tự động": "Automated assessment",
    "Tổng quan hôm nay": "Today overview",
    "Chưa có dữ liệu tổng quan": "No overview data yet",
    "Chưa có dữ liệu trạng thái": "No status data yet",
    "Bấm vào để xem chi tiết": "Tap to view details",
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
    "Nhà của tôi": "My homes",
    "Bỏ chọn toàn bộ nhóm": "Deselect entire group",
    "Chọn toàn bộ nhóm": "Select entire group",
    "Giờ": "Hour",
    "Phút": "Minute",
    "Đặt Home Reminder": "Set Home Reminder",
    "Đặt Home Alarm": "Set Home Alarm",
    "Xác nhận thay đổi": "Confirm changes",
    "Tiếp tục": "Continue",
    "Giờ Reminder": "Reminder time",
    "Giờ bắt đầu Alarm": "Alarm start time",
    "Giờ kết thúc Alarm": "Alarm end time",
    "Không có nhà nào đủ điều kiện để cài":
    "No eligible homes were found",
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
    "Đặt Reminder / Alarm nhà đã chọn":
    "Set Reminder / Alarm for selected homes",
    "Chia sẻ nhà đã chọn": "Share selected homes",
    "Hoặc quét QR để xin gia nhập các nhà đã chọn":
    "Or scan a QR code to request access to selected homes",
    "Email người nhận": "Recipient email",
    "Chia sẻ": "Share",
    "Email chưa đăng ký": "Email is not registered",
    "Chia sẻ hoàn tất": "Sharing complete",
    "Mở List chia sẻ nhà": "Open home sharing list",
    "Không có nhà nào bạn có quyền quản lý":
    "You do not manage any selected homes",
    "Chưa share cho ai": "Not shared with anyone",
    "Xoá các nhà đã chọn ?": "Delete selected homes?",
    "Thông báo Home": "Home notifications",
    "Không có thiết bị": "No devices",
    "Chỉ chủ nhà mới được xoá nhà":
    "Only the owner can delete this home",
    "Chỉ chủ nhà mới được chuyển quyền":
    "Only the owner can transfer ownership",
    "Lưu ý khi bật Alarm": "Alarm notice",
    "Đã hiểu": "Got it",
    "Lưu ý tạm tắt Alarm": "Pause Alarm notice",
    "Đã bật Alarm": "Alarm enabled",
    "Đã tắt Alarm": "Alarm disabled",
    "Cả ngày": "All day",
    "QR gia nhập nhiều nhà không hợp lệ":
    "Invalid multi-home join QR code",
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
    "Xin gia nhập nhà": "Join a home",
    "Quét mã QR chia sẻ nhà": "Scan a home sharing QR code",
    "Mời thành viên bằng mã QR": "Invite members with a QR code",
    "Không thể share cho chính bạn": "You cannot share with yourself",
    "Lời mời chia sẻ nhà": "Home sharing invitation",
    "Đã share home": "Home shared",
    "Chuyển quyền chủ nhà": "Transfer ownership",
    "Không thể chuyển quyền cho chính bạn":
    "You cannot transfer ownership to yourself",
    "Không tìm thấy user": "User not found",
    "Xác nhận chuyển quyền": "Confirm ownership transfer",
    "Chuyển": "Transfer",
    "Xác nhận mật khẩu": "Confirm password",
    "Xác nhận": "Confirm",
    "Yêu cầu chuyển quyền chủ nhà": "Ownership transfer request",
    "Đã gửi yêu cầu chuyển quyền": "Transfer request sent",
    "Đã gửi yêu cầu chuyển quyền chủ nhà":
    "Ownership transfer request sent",
    "Bạn không có quyền xoá thiết bị":
    "You do not have permission to delete devices",
    "Xóa Device?": "Delete this device?",
    "Đã gửi yêu cầu xoá thiết bị": "Device deletion request sent",
    "Đang xoá thiết bị": "Deleting device",
    "Đăng xuất?": "Sign out?",
    "Thêm nhà mới": "Add a new home",
    "Tên nhà": "Home name",
    "Đã tạo nhà mới": "Home created",
    "Về muộn": "Coming home late",
    "Ra ngoài": "Going out",
    "Khác": "Other",
    "⏸️ Tạm tắt Alarm hôm nay": "⏸️ Pause Alarm today",
    "Chọn giờ bắt đầu tạm tắt": "Choose pause start time",
    "Từ giờ": "From",
    "Chọn giờ kết thúc tạm tắt": "Choose pause end time",
    "Đến giờ": "Until",
    "Xóa lịch tạm tắt": "Delete pause schedule",
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
    "Đã thiết lập": "Configured",
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
    "Hôm nay đã ghi nhận cảnh báo SOS":
    "An SOS alert was recorded today",
    "Hôm nay đã ghi nhận cảnh báo khói":
    "A smoke alert was recorded today",
    "Khói đã an toàn": "Smoke condition cleared",
    "Không tìm thấy nhà của thông báo này":
    "The home for this notification was not found",
    "Không tìm thấy thiết bị trong nhà này":
    "The device was not found in this home",
    "Một chủ nhà": "A homeowner",
    "Ngôi nhà đang hoạt động ổn định":
    "The home is operating normally",
    "Nhiệt độ cao": "High temperature",
    "OK": "OK",
    "Pin yếu": "Low battery",
    "SOS đã kết thúc": "SOS cleared",
    "SOS được kích hoạt": "SOS activated",
    "Tamper bình thường": "Tamper condition cleared",
    "Thiết bị bị tháo": "Tamper detected",
    "Thiết bị mới": "New device",
    "Thiết bị offline": "Device offline",
    "Thiết bị online": "Device online",
    "Tạm tắt Alarm hôm nay": "Pause Alarm today",
    "Độ ẩm cao": "High humidity",
  };

  String t(String vi) {
    if (!isEnglish) {
      return vi;
    }

    return _english[vi] ?? vi;
  }

  String statusText(String text) {
    if (!isEnglish || text.trim().isEmpty) {
      return text;
    }

    final exact = _english[text];
    if (exact != null) {
      return exact;
    }

    final issueParts = text.split(": ");
    if (issueParts.length >= 2) {
      final name = issueParts.first;
      final details = issueParts.sublist(1).join(": ");
      final translatedDetails = details
          .split(" & ")
          .map(_translateStatusFragment)
          .join(" & ");
      return "$name: $translatedDetails";
    }

    final closedMatch = RegExp(
      r"^(\d+)/(\d+) cửa đã đóng an toàn$",
    ).firstMatch(text);
    if (closedMatch != null) {
      return "${closedMatch.group(1)}/${closedMatch.group(2)} doors safely closed";
    }

    final securedAccessMatch = RegExp(
      r"^(\d+)/(\d+) cửa và khóa đã an toàn$",
    ).firstMatch(text);
    if (securedAccessMatch != null) {
      return "${securedAccessMatch.group(1)}/${securedAccessMatch.group(2)} doors and locks secured";
    }

    final deviceMatch = RegExp(
      r"^(\d+) thiết bị đang được theo dõi$",
    ).firstMatch(text);
    if (deviceMatch != null) {
      return "${deviceMatch.group(1)} devices monitored";
    }

    final minuteMatch = RegExp(
      r"^Dữ liệu gần nhất cập nhật (\d+) phút trước$",
    ).firstMatch(text);
    if (minuteMatch != null) {
      return "Latest data updated ${minuteMatch.group(1)} minutes ago";
    }

    final hourMatch = RegExp(
      r"^Dữ liệu gần nhất cập nhật (\d+) giờ trước$",
    ).firstMatch(text);
    if (hourMatch != null) {
      return "Latest data updated ${hourMatch.group(1)} hours ago";
    }

    if (text.startsWith("Môi trường hiện tại: ")) {
      return text.replaceFirst(
        "Môi trường hiện tại: ",
        "Current environment: ",
      );
    }

    return _translateStatusFragment(text);
  }

  String _translateStatusFragment(String text) {
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
      "Khóa đang mở trong giờ Alarm":
      "Unlocked during Alarm hours",
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
      "Hub đang kết nối": "Hub connected",
      "Chưa có dữ liệu thiết bị để đánh giá":
      "No device data available for assessment",
    };

    return fragments[text] ?? text;
  }

  String get splashTagline => choose(
    vi: "An tâm hơn trong từng ngôi nhà",
    en: "Peace of mind in every home",
  );

  String get alarmTitle => choose(
    vi: "Báo động SafeHome",
    en: "SafeHome Alarm",
  );

  String get alarmBody => choose(
    vi: "Có cảnh báo an ninh cần kiểm tra ngay.",
    en: "A security alert requires your attention.",
  );

  String get alarmFallback => choose(
    vi: "Có cảnh báo cần kiểm tra",
    en: "An alert requires your attention",
  );

  String get owner => t("Chủ nhà");
  String get admin => choose(vi: "Quản trị viên", en: "Admin");
  String get member => choose(vi: "Thành viên", en: "Member");
  String get notUpdated => t("Chưa cập nhật");
  String get unnamedHome => t("Nhà chưa đặt tên");
  String get role => choose(vi: "Vai trò", en: "Role");
  String get address => t("Địa chỉ");
  String get members => choose(vi: "Thành viên", en: "Members");
  String get loading => choose(vi: "Đang tải...", en: "Loading...");
  String get manageHome => choose(vi: "Quản lý nhà", en: "Home management");
  String get shareHome => t("Chia sẻ nhà");
  String get shareHomeSubtitle => choose(
    vi: "Mời người khác tham gia nhà này",
    en: "Invite someone to join this home",
  );
  String get homeMembers => choose(vi: "Thành viên trong nhà", en: "Home members");
  String get homeMembersSubtitle => choose(
    vi: "Xem và quản lý quyền thành viên",
    en: "View and manage member roles",
  );
  String get manageRooms => choose(vi: "Quản lý phòng", en: "Manage rooms");
  String get manageRoomsSubtitle => choose(
    vi: "Thêm, đổi tên và sắp xếp phòng",
    en: "Add, rename and reorder rooms",
  );
  String get allDevices => choose(vi: "Toàn bộ thiết bị", en: "All devices");
  String get allDevicesSubtitle => choose(
    vi: "Kiểm tra thiết bị trong nhà này",
    en: "Review devices in this home",
  );
  String get transferOwnership => t("Chuyển quyền chủ nhà");
  String get transferOwnershipSubtitle => choose(
    vi: "Chuyển quyền sở hữu cho thành viên khác",
    en: "Transfer ownership to another member",
  );
  String get accountAndSystem => choose(
    vi: "Tài khoản & hệ thống",
    en: "Account & system",
  );
  String get personalAccount => choose(
    vi: "Tài khoản cá nhân",
    en: "Personal account",
  );
  String get personalAccountSubtitle => choose(
    vi: "Hồ sơ, yêu cầu và lời mời tham gia",
    en: "Profile, requests and invitations",
  );
  String get language => choose(vi: "Ngôn ngữ", en: "Language");
  String get languageSubtitle => choose(
    vi: "Thay đổi ngôn ngữ hiển thị",
    en: "Change the display language",
  );
  String get chooseLanguage => choose(
    vi: "Chọn ngôn ngữ",
    en: "Choose language",
  );
  String get vietnamese => choose(vi: "Tiếng Việt", en: "Vietnamese");
  String get english => choose(vi: "Tiếng Anh", en: "English");
  String get currentLanguageName => isEnglish ? "English" : "Tiếng Việt";
  String get dangerZone => choose(vi: "Khu vực nguy hiểm", en: "Danger zone");
  String get deleteHome => t("Xoá nhà");
  String get deleteHomeSubtitle => choose(
    vi: "Xoá toàn bộ dữ liệu và thiết bị",
    en: "Delete all home data and devices",
  );
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
