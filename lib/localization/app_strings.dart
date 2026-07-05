import 'package:flutter/material.dart';

class AppStrings {
  final bool isEnglish;
  final bool isChinese;

  const AppStrings._({required this.isEnglish, required this.isChinese});

  factory AppStrings.fromLocale(Locale locale) {
    return AppStrings._(
      isEnglish: locale.languageCode == "en",
      isChinese: locale.languageCode == "zh",
    );
  }

  static AppStrings of(BuildContext context) {
    return AppStrings.fromLocale(Localizations.localeOf(context));
  }

  String choose({required String vi, required String en, String? zh}) {
    if (isChinese) {
      return zh ?? _chinese[vi] ?? vi;
    }

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
    "Môi trường": "Environment",
    "Toàn bộ thiết bị SafeHome": "All SafeHome devices",
    "Cửa ra/vào": "Entry door",
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
    "Cài đặt cảnh báo cho nhà hiện tại": "Alert settings for this home",
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
    "Chưa share cho ai": "Not shared with anyone",
    "Xoá các nhà đã chọn ?": "Delete selected homes?",
    "Thông báo Home": "Home notifications",
    "Thông báo nhà": "Home notifications",
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
    "Đã hiểu": "Got it",
    "Lưu ý tạm tắt Alarm": "Pause Alarm notice",
    "Đã bật Alarm": "Alarm enabled",
    "Đã tắt Alarm": "Alarm disabled",
    "Cả ngày": "All day",
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
    "Mời thành viên bằng mã QR": "Invite members with a QR code",
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
    "Đăng xuất?": "Sign out?",
    "Thêm nhà": "Add home",
    "Thêm nhà mới": "Add a new home",
    "Tạo nhà mới": "Create new home",
    "Tạo một ngôi nhà mới của bạn": "Create a new home for yourself",
    "Quét mã QR được chủ nhà chia sẻ": "Scan the QR code shared by the owner",
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
    "Ghi nhớ tài khoản": "Remember account",
    "Đăng nhập": "Sign in",
    "Đăng ký mới": "Create account",
    "Quên mật khẩu?": "Forgot password?",
    "Chưa có tài khoản? Đăng ký": "No account yet? Sign up",
    "Đã có tài khoản? Đăng nhập": "Already have an account? Sign in",
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
    "Nhắn gì đó...": "Message something...",
    "Gọi điện": "Call",
    "Alarm thiết bị": "Device Alarm",
    "Chế độ áp dụng": "Apply mode",
    "Theo nhà": "Home settings",
    "Riêng tôi": "Only me",
    "Thiết lập nhanh Alarm": "Quick Alarm setup",
    "Thiết lập nhanh toàn bộ thiết bị": "Quick setup for all devices",
    "Áp dụng cho toàn bộ thiết bị": "Apply to all devices",
    "Bắt đầu": "Start",
    "Kết thúc": "End",
    "Thời gian lặp lại": "Repeat interval",
    "Không lặp lại": "Do not repeat",
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
    "Tamper bình thường": "Tamper condition cleared",
    "Thiết bị bị tháo": "Tamper detected",
    "Thiết bị mới": "New device",
    "Thiết bị offline": "Device offline",
    "Thiết bị online": "Device online",
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
    "Chưa nhận diện": "未识别设备",
    "Chưa có cập nhật": "暂无更新",
    "CHƯA AN TOÀN": "不安全",
    "CẦN CHÚ Ý": "需要注意",
    "ĐÃ AN TOÀN": "安全",
    "Nhà đang có dấu hiệu cần kiểm tra, bạn nên xem lại các trạng thái bên dưới.":
        "家中有需要检查的迹象，请查看下面的状态。",
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.": "家中运行稳定，可以安心。",
    "Không có dấu hiệu khói hoặc SOS bất thường.": "未发现异常烟雾或 SOS。",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.": "暂无足够的新活动用于深入分析。",
    "Cài đặt cảnh báo cho nhà hiện tại": "当前家庭的提醒设置",
    "Nhận cảnh báo Alarm": "接收 Alarm 提醒",
    "Đang bật cho tài khoản này": "此账户已开启",
    "Đang tắt cho tài khoản này": "此账户已关闭",
    "Hẹn giờ Reminder": "Reminder 计划",
    "Nhắc kiểm tra nhà theo thời gian": "按时间提醒检查家庭",
    "Hẹn giờ Alarm": "Alarm 计划",
    "Chưa thiết lập": "未设置",
    "Chưa thiết lập thời gian": "未设置时间",
    "Tổng hợp trạng thái nhà": "家庭状态汇总",
    "Cần xử lý ngay": "需要立即处理",
    "Cần kiểm tra": "需要检查",
    "Đánh giá tự động": "自动评估",
    "Tổng quan hôm nay": "今日概览",
    "Chưa có dữ liệu tổng quan": "暂无概览数据",
    "Chưa có dữ liệu trạng thái": "暂无状态数据",
    "Bấm vào để xem chi tiết": "点击查看详情",
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
    "Nhà của tôi": "我的家庭",
    "Bỏ chọn toàn bộ nhóm": "取消选择整个分组",
    "Chọn toàn bộ nhóm": "选择整个分组",
    "Bỏ chọn": "取消选择",
    "Quay lại": "返回",
    "Tìm kiếm": "搜索",
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
    "Chia sẻ": "共享",
    "Email người nhận": "收件人邮箱",
    "Email chưa đăng ký": "邮箱未注册",
    "Chia sẻ hoàn tất": "共享完成",
    "Mở danh sách chia sẻ nhà": "打开家庭共享列表",
    "Xoá các nhà đã chọn?": "删除所选家庭？",
    "Các nhà đã chọn sẽ bị xoá vĩnh viễn.": "所选家庭将被永久删除。",
    "Mở List chia sẻ nhà": "打开家庭共享列表",
    "Không có nhà nào bạn có quyền quản lý": "没有你有权管理的家庭",
    "Chưa share cho ai": "尚未共享给任何人",
    "Xoá các nhà đã chọn ?": "删除所选家庭？",
    "Thông báo Home": "家庭通知",
    "Thông báo nhà": "家庭通知",
    "Xoá tất cả thông báo?": "删除所有通知？",
    "Toàn bộ thông báo nhà sẽ bị xoá.": "所有家庭通知将被删除。",
    "Chưa có thông báo nào": "暂无通知",
    "Chưa có thông báo": "暂无通知",
    "Vuốt lên để tải thêm": "向上滑动加载更多",
    "Không có thiết bị": "没有设备",
    "Chỉ chủ nhà mới được xoá nhà": "只有屋主可以删除家庭",
    "Chỉ chủ nhà mới được chuyển quyền": "只有屋主可以转移所有权",
    "Lưu ý khi bật Alarm": "开启 Alarm 提示",
    "Đã hiểu": "知道了",
    "Đã bật Alarm": "Alarm 已开启",
    "Đã tắt Alarm": "Alarm 已关闭",
    "Cả ngày": "全天",
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
    "Mời thành viên bằng mã QR": "用二维码邀请成员",
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
    "Tạo một ngôi nhà mới của bạn": "创建属于你的新家庭",
    "Quét mã QR được chủ nhà chia sẻ": "扫描屋主分享的二维码",
    "Tên nhà": "家庭名称",
    "Đã tạo nhà mới": "家庭已创建",
    "Về muộn": "晚回家",
    "Ra ngoài": "外出",
    "Khác": "其他",
    "Tạm tắt Alarm hôm nay": "今天暂停 Alarm",
    "Chọn giờ bắt đầu tạm tắt": "选择暂停开始时间",
    "Từ giờ": "从",
    "Chọn giờ kết thúc tạm tắt": "选择暂停结束时间",
    "Đến giờ": "到",
    "Xóa lịch tạm tắt": "删除暂停计划",
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
    "Ghi nhớ tài khoản": "记住账户",
    "Đăng nhập": "登录",
    "Đăng ký mới": "创建账户",
    "Quên mật khẩu?": "忘记密码？",
    "Chưa có tài khoản? Đăng ký": "还没有账户？注册",
    "Đã có tài khoản? Đăng nhập": "已有账户？登录",
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
    "Nhắn gì đó...": "发点什么...",
    "Gọi điện": "拨打电话",
    "Alarm thiết bị": "设备 Alarm",
    "Chế độ áp dụng": "应用模式",
    "Theo nhà": "按家庭",
    "Riêng tôi": "仅自己",
    "Thiết lập nhanh Alarm": "快速设置 Alarm",
    "Thiết lập nhanh toàn bộ thiết bị": "快速设置所有设备",
    "Áp dụng cho toàn bộ thiết bị": "应用到所有设备",
    "Bắt đầu": "开始",
    "Kết thúc": "结束",
    "Thời gian lặp lại": "重复间隔",
    "Không lặp lại": "不重复",
    "Đang áp dụng...": "正在应用...",
    "Ngôi nhà đang hoạt động ổn định": "家庭运行稳定",
    "Nhiệt độ cao": "温度过高",
    "OK": "确定",
    "Pin yếu": "电量低",
    "SOS đã kết thúc": "SOS 已结束",
    "SOS được kích hoạt": "SOS 已触发",
    "Tamper bình thường": "防拆状态正常",
    "Thiết bị bị tháo": "设备被拆卸",
    "Thiết bị mới": "新设备",
    "Thiết bị offline": "设备离线",
    "Thiết bị online": "设备在线",
    "Độ ẩm cao": "湿度过高",
  };

  String t(String vi) {
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

    final translations = isChinese
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
      );
    }

    if (!isEnglish && !isChinese) {
      return text;
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

    return _translateStatusFragment(text);
  }

  String _translateStatusFragment(String text) {
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
        "Đang mở khi nhà ở chế độ Bảo vệ": "家庭处于布防模式时被打开",
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
  );

  String get alarmTitle => choose(
    vi: "Báo động SafeHome",
    en: "SafeHome Alarm",
    zh: "SafeHome Alarm",
  );

  String get alarmBody => choose(
    vi: "Có cảnh báo an ninh cần kiểm tra ngay.",
    en: "A security alert requires your attention.",
    zh: "有安全警报需要立即检查。",
  );

  String get alarmFallback => choose(
    vi: "Có cảnh báo cần kiểm tra",
    en: "An alert requires your attention",
    zh: "有警报需要检查",
  );

  String get owner => t("Chủ nhà");
  String get admin => choose(vi: "Quản trị viên", en: "Admin", zh: "管理员");
  String get member => choose(vi: "Thành viên", en: "Member", zh: "成员");
  String get notUpdated => t("Chưa cập nhật");
  String get unnamedHome => t("Nhà chưa đặt tên");
  String get role => choose(vi: "Vai trò", en: "Role", zh: "角色");
  String get address => t("Địa chỉ");
  String get members => choose(vi: "Thành viên", en: "Members", zh: "成员");
  String get loading =>
      choose(vi: "Đang tải...", en: "Loading...", zh: "正在加载...");
  String get manageHome =>
      choose(vi: "Quản lý nhà", en: "Home management", zh: "家庭管理");
  String get shareHome => t("Chia sẻ nhà");
  String get shareHomeSubtitle => choose(
    vi: "Mời người khác tham gia nhà này",
    en: "Invite someone to join this home",
    zh: "邀请他人加入此家庭",
  );
  String get homeMembers =>
      choose(vi: "Thành viên trong nhà", en: "Home members", zh: "家庭成员");
  String get homeMembersSubtitle => choose(
    vi: "Xem và quản lý quyền thành viên",
    en: "View and manage member roles",
    zh: "查看和管理成员权限",
  );
  String get manageRooms =>
      choose(vi: "Quản lý phòng", en: "Manage rooms", zh: "管理房间");
  String get manageRoomsSubtitle => choose(
    vi: "Thêm, đổi tên và sắp xếp phòng",
    en: "Add, rename and reorder rooms",
    zh: "添加、重命名和排序房间",
  );
  String get allDevices =>
      choose(vi: "Toàn bộ thiết bị", en: "All devices", zh: "全部设备");
  String get allDevicesSubtitle => choose(
    vi: "Kiểm tra thiết bị trong nhà này",
    en: "Review devices in this home",
    zh: "查看此家庭中的设备",
  );
  String get transferOwnership => t("Chuyển quyền chủ nhà");
  String get transferOwnershipSubtitle => choose(
    vi: "Chuyển quyền sở hữu cho thành viên khác",
    en: "Transfer ownership to another member",
    zh: "将所有权转移给其他成员",
  );
  String get accountAndSystem =>
      choose(vi: "Tài khoản & hệ thống", en: "Account & system", zh: "账户与系统");
  String get personalAccount =>
      choose(vi: "Tài khoản cá nhân", en: "Personal account", zh: "个人账户");
  String get personalAccountSubtitle => choose(
    vi: "Hồ sơ, yêu cầu và lời mời tham gia",
    en: "Profile, requests and invitations",
    zh: "个人资料、申请和邀请",
  );
  String get language => choose(vi: "Ngôn ngữ", en: "Language", zh: "语言");
  String get languageSubtitle => choose(
    vi: "Thay đổi ngôn ngữ hiển thị",
    en: "Change the display language",
    zh: "更改显示语言",
  );
  String get chooseLanguage =>
      choose(vi: "Chọn ngôn ngữ", en: "Choose language", zh: "选择语言");
  String get vietnamese =>
      choose(vi: "Tiếng Việt", en: "Vietnamese", zh: "越南语");
  String get english => choose(vi: "Tiếng Anh", en: "English", zh: "英语");
  String get chinese => choose(vi: "Tiếng Trung", en: "Chinese", zh: "中文");
  String get currentLanguageName {
    if (isChinese) {
      return "中文";
    }

    return isEnglish ? "English" : "Tiếng Việt";
  }

  String get dangerZone =>
      choose(vi: "Khu vực nguy hiểm", en: "Danger zone", zh: "危险区域");
  String get deleteHome => t("Xoá nhà");
  String get deleteHomeSubtitle => choose(
    vi: "Xoá toàn bộ dữ liệu và thiết bị",
    en: "Delete all home data and devices",
    zh: "删除所有家庭数据和设备",
  );
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
