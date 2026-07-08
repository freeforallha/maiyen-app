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

  String manualSecurityModeEnabledTitle() => choose(
    vi: "Mode Bảo vệ thủ công đã bật",
    en: "Manual Guard mode enabled",
    zh: "手动保护模式已开启",
    ko: "수동 보호 모드가 켜졌습니다",
    ja: "手動Guardモードがオンになりました",
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
          )
        : choose(
            vi:
                "Báo động lặp sau $securityModeRepeatMinutes phút nếu sự cố vẫn còn.",
            en:
                "The alarm repeats after $securityModeRepeatMinutes minutes if the issue remains.",
            zh: "如果问题仍然存在，警报将在 $securityModeRepeatMinutes 分钟后重复。",
            ko:
                "문제가 계속되면 $securityModeRepeatMinutes분 후 Alarm이 반복됩니다.",
            ja:
                "問題が残っている場合、$securityModeRepeatMinutes 分後に Alarm が繰り返されます。",
          );

    return choose(
      vi:
          "$actorName đã bật Mode Bảo vệ thủ công cho \"$homeName\". Chế độ này chỉ tắt khi một thành viên có quyền chủ động chuyển về Bình thường. $repeatMessage",
      en:
          "$actorName turned on Manual Guard mode for \"$homeName\". This mode only turns off when a permitted member switches back to Normal. $repeatMessage",
      zh:
          "$actorName 已为“$homeName”开启手动保护模式。只有具备权限的成员主动切换回普通模式时，此模式才会关闭。$repeatMessage",
      ko:
          "$actorName님이 \"$homeName\"에 수동 보호 모드를 켰습니다. 권한이 있는 구성원이 Normal로 직접 전환해야 이 모드가 꺼집니다. $repeatMessage",
      ja:
          "$actorName が「$homeName」で手動Guardモードをオンにしました。このモードは、権限のあるメンバーがNormalに戻した場合にのみオフになります。$repeatMessage",
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
          )
        : choose(
            vi: "Bạn đã tắt toàn bộ Alarm của nhà \"$homeName\".",
            en: "You disabled every Alarm for \"$homeName\".",
            zh: "你已关闭“$homeName”的所有 Alarm。",
            ko: "\"$homeName\"의 모든 Alarm을 껐습니다.",
            ja: "「$homeName」のすべての Alarm をオフにしました。",
          );
  }

  String memberLeftHomeTitle() => choose(
    vi: "Thành viên rời nhà",
    en: "Member left home",
    zh: "成员已离开家庭",
    ko: "구성원이 집에서 나갔습니다",
    ja: "メンバーが家から退出しました",
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
          );

    return choose(
      vi: "$displayMemberName đã rời khỏi nhà \"$homeName\".",
      en: "$displayMemberName left \"$homeName\".",
      zh: "$displayMemberName 已离开“$homeName”。",
      ko: "$displayMemberName님이 \"$homeName\"에서 나갔습니다.",
      ja: "$displayMemberName が「$homeName」から退出しました。",
    );
  }

  String memberRoleChangedTitle() => choose(
    vi: "Vai trò thành viên đã thay đổi",
    en: "Member role changed",
    zh: "成员角色已更改",
    ko: "구성원 역할이 변경되었습니다",
    ja: "メンバーの役割が変更されました",
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
      vi:
          "$actorName đã đổi vai trò của $memberName từ $oldRoleName thành $newRoleName trong nhà \"$homeName\".",
      en:
          "$actorName changed $memberName's role from $oldRoleName to $newRoleName in \"$homeName\".",
      zh:
          "$actorName 已将 $memberName 在“$homeName”中的角色从 $oldRoleName 更改为 $newRoleName。",
      ko:
          "$actorName님이 \"$homeName\"에서 $memberName님의 역할을 $oldRoleName에서 $newRoleName로 변경했습니다.",
      ja:
          "$actorName が「$homeName」で $memberName の役割を $oldRoleName から $newRoleName に変更しました。",
    );
  }

  String unreadChatNotice(int count) => choose(
    vi: "Còn $count tin nhắn chưa đọc",
    en: "$count unread messages",
    zh: "还有 $count 条未读消息",
    ko: "읽지 않은 메시지 ${count}개",
    ja: "未読メッセージが $count 件あります",
  );

  String safeStatusTitle() => choose(
    vi: "ĐÃ AN TOÀN",
    en: "SAFE",
    zh: "安全",
    ko: "안전",
    ja: "安全",
  );

  String unsafeStatusTitle() => choose(
    vi: "CHƯA AN TOÀN",
    en: "UNSAFE",
    zh: "不安全",
    ko: "안전하지 않음",
    ja: "安全ではありません",
  );

  String safeReminderBody() => choose(
    vi: "Hãy an tâm nghỉ ngơi.",
    en: "You can rest assured.",
    zh: "你可以放心休息。",
    ko: "안심하고 쉬셔도 됩니다.",
    ja: "安心してお休みください。",
  );

  String unsafeReminderBody(String reason) {
    final cleanReason = reason.trim();

    if (cleanReason.isNotEmpty) {
      return cleanReason;
    }

    return choose(
      vi: "Có thiết bị chưa an toàn.",
      en: "Some devices are not safe.",
      zh: "有设备处于不安全状态。",
      ko: "일부 기기가 안전하지 않습니다.",
      ja: "一部のデバイスが安全ではありません。",
    );
  }

  String safetyReminderBody({
    required bool isSafe,
    String reason = "",
  }) {
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
  );

  String updatingLocationNotificationBody() => choose(
    vi: "Đang theo dõi để tự động bật Chế độ Bảo vệ.",
    en: "Monitoring to turn on Guard mode automatically.",
    zh: "正在监测以自动开启保护模式。",
    ko: "보호 모드를 자동으로 켜기 위해 모니터링 중입니다.",
    ja: "Guardモードを自動でオンにするため監視しています。",
  );

  String updatingLocationChannelDescription() => choose(
    vi: "Dùng vị trí để tự động bật Chế độ Bảo vệ khi mọi người rời nhà.",
    en: "Uses location to turn on Guard mode automatically when everyone leaves home.",
    zh: "使用位置在所有人离家时自动开启保护模式。",
    ko: "모두가 집을 떠나면 위치를 사용해 보호 모드를 자동으로 켭니다.",
    ja: "全員が外出したときに位置情報を使ってGuardモードを自動でオンにします。",
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
        );
      case "smoke":
      case "fire":
        return choose(
          vi: "CẢNH BÁO KHÓI / CHÁY",
          en: "SMOKE / FIRE ALERT",
          zh: "烟雾 / 火灾警报",
          ko: "연기 / 화재 경보",
          ja: "煙 / 火災アラート",
        );
      case "flood":
      case "water":
        return choose(
          vi: "CẢNH BÁO NGẬP NƯỚC",
          en: "FLOOD ALERT",
          zh: "漏水警报",
          ko: "침수 경보",
          ja: "浸水アラート",
        );
      case "gas":
        return choose(
          vi: "CẢNH BÁO RÒ KHÍ",
          en: "GAS LEAK ALERT",
          zh: "燃气泄漏警报",
          ko: "가스 누출 경보",
          ja: "ガス漏れアラート",
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
        );
      default:
        return choose(
          vi: "CẢNH BÁO AN NINH",
          en: "SECURITY ALERT",
          zh: "安全警报",
          ko: "보안 경보",
          ja: "セキュリティアラート",
        );
    }
  }

  String stopAlarmLabel() => choose(
    vi: "TẮT CẢNH BÁO",
    en: "STOP ALERT",
    zh: "停止警报",
    ko: "경보 중지",
    ja: "アラートを停止",
  );

  String defaultHomeName() => choose(
    vi: "Nhà",
    en: "Home",
    zh: "家庭",
    ko: "집",
    ja: "家",
  );

  String defaultUnsafeReminderReason() => unsafeReminderBody("");

  String alarmActionErrorMessage() => choose(
    vi: "Không thể xác nhận với SafeHome. Hãy kiểm tra kết nối và thử lại.",
    en: "Could not confirm with SafeHome. Check your connection and try again.",
    zh: "无法与 SafeHome 确认。请检查连接后重试。",
    ko: "SafeHome에 확인할 수 없습니다. 연결을 확인한 뒤 다시 시도해 주세요.",
    ja: "SafeHome に確認できませんでした。接続を確認してもう一度お試しください。",
  );

  String confirmStopAlarmBody() => choose(
    vi:
        "Chỉ tắt cảnh báo khi bạn đã kiểm tra tình trạng trong nhà.\n\nBạn chắc chắn muốn tắt cảnh báo?",
    en:
        "Only stop the alert after checking the home's condition.\n\nAre you sure you want to stop the alert?",
    zh: "请仅在检查家庭状态后停止警报。\n\n确定要停止警报吗？",
    ko: "집 상태를 확인한 뒤에만 경보를 중지하세요.\n\n경보를 중지하시겠습니까?",
    ja: "家の状態を確認してからアラートを停止してください。\n\nアラートを停止しますか？",
  );

  String priorityAlarmNotificationTitle() => choose(
    vi: "🚨 SafeHome phát hiện cảnh báo",
    en: "🚨 SafeHome detected an alert",
    zh: "🚨 SafeHome 检测到警报",
    ko: "🚨 SafeHome이 경보를 감지했습니다",
    ja: "🚨 SafeHome がアラートを検知しました",
  );

  String openSafeHomeToCheckBody() => choose(
    vi: "Mở SafeHome để kiểm tra ngay.",
    en: "Open SafeHome to check now.",
    zh: "打开 SafeHome 立即检查。",
    ko: "SafeHome을 열어 지금 확인하세요.",
    ja: "SafeHome を開いて今すぐ確認してください。",
  );

  String homeChatNewMessages(int count) => choose(
    vi: "$count tin nhắn mới",
    en: "$count new messages",
    zh: "$count 条新消息",
    ko: "새 메시지 ${count}개",
    ja: "新着メッセージが $count 件あります",
  );

  String homeChatTitle() => choose(
    vi: "Tin nhắn HomeChat",
    en: "HomeChat message",
    zh: "HomeChat 消息",
    ko: "HomeChat 메시지",
    ja: "HomeChat メッセージ",
  );

  String homeChatSenderMessage(String senderName) => choose(
    vi: "$senderName đã gửi một tin nhắn",
    en: "$senderName sent a message",
    zh: "$senderName 发送了一条消息",
    ko: "$senderName님이 메시지를 보냈습니다",
    ja: "$senderName がメッセージを送信しました",
  );

  String homeChatNewMessage() => choose(
    vi: "Bạn có tin nhắn mới",
    en: "You have a new message",
    zh: "你有一条新消息",
    ko: "새 메시지가 있습니다",
    ja: "新着メッセージがあります",
  );

  String homeSecurityRepeatToast(int minutes) {
    return minutes == 0
        ? choose(
            vi: "Mode Bảo vệ sẽ chỉ báo động một lần",
            en: "Guard mode will alert only once",
            zh: "保护模式只会警报一次",
            ko: "보호 모드는 한 번만 경보를 보냅니다",
            ja: "Guardモードは一度だけアラートします",
          )
        : choose(
            vi: "Mode Bảo vệ sẽ lặp báo động sau $minutes phút",
            en: "Guard mode will repeat the alert after $minutes minutes",
            zh: "保护模式将在 $minutes 分钟后重复警报",
            ko: "보호 모드는 $minutes분 후 경보를 반복합니다",
            ja: "Guardモードは $minutes 分後にアラートを繰り返します",
          );
  }

  String joinRequestsSentMessage(int count) => choose(
    vi: "Đã gửi yêu cầu gia nhập $count nhà",
    en: "Join requests sent for $count homes",
    zh: "已发送 $count 个家庭的加入请求",
    ko: "$count개 집에 가입 요청을 보냈습니다",
    ja: "$count 件の家への参加リクエストを送信しました",
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
  );

  String homeDeletedMessage(String homeName) => choose(
    vi: "Bạn đã xoá nhà \"$homeName\".",
    en: "You deleted \"$homeName\".",
    zh: "你已删除“$homeName”。",
    ko: "\"$homeName\"을 삭제했습니다.",
    ja: "「$homeName」を削除しました。",
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
  );

  String homeCreatedMessage(String name) => choose(
    vi: "Bạn đã tạo nhà \"$name\".",
    en: "You created the home \"$name\".",
    zh: "你已创建家庭“$name”。",
    ko: "\"$name\" 집을 만들었습니다.",
    ja: "家「$name」を作成しました。",
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
      );
    }

    if (nameChanged) {
      return choose(
        vi: "$actorName đã đổi tên nhà thành \"$newName\".",
        en: "$actorName renamed the home to \"$newName\".",
        zh: "$actorName 已将家庭名称改为“$newName”。",
        ko: "$actorName님이 집 이름을 \"$newName\"(으)로 변경했습니다.",
        ja: "$actorName が家の名前を「$newName」に変更しました。",
      );
    }

    return choose(
      vi: "$actorName đã cập nhật địa chỉ của nhà \"$newName\".",
      en: "$actorName updated the address of \"$newName\".",
      zh: "$actorName 已更新“$newName”的地址。",
      ko: "$actorName님이 \"$newName\"의 주소를 업데이트했습니다.",
      ja: "$actorName が「$newName」の住所を更新しました。",
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
  );

  String pairingCountdownText(int seconds) => choose(
    vi: "Đang ghép nối: $seconds giây",
    en: "Pairing: $seconds s",
    zh: "正在配对: $seconds 秒",
    ko: "페어링 중: $seconds초",
    ja: "ペアリング中: $seconds 秒",
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
  );

  String memberPhoneMissingProfileMessage(String name) => choose(
    vi: "$name chưa cập nhật số điện thoại trong hồ sơ.",
    en: "$name has not added a phone number to their profile.",
    zh: "$name 尚未在个人资料中添加电话号码。",
    ko: "$name님이 프로필에 전화번호를 추가하지 않았습니다.",
    ja: "$name はプロフィールに電話番号を追加していません。",
  );

  String newChatInHomeTitle(String homeName) => choose(
    vi: "Tin nhắn mới trong $homeName",
    en: "New message in $homeName",
    zh: "$homeName 有新消息",
    ko: "$homeName 새 메시지",
    ja: "$homeName に新しいメッセージがあります",
  );

  String searchResultCountText({
    required int current,
    required int total,
  }) => choose(
    vi: "$current/$total kết quả",
    en: "$current/$total results",
    zh: "$current/$total 个结果",
    ko: "$current/$total개 결과",
    ja: "$current/$total 件の結果",
  );

  String replyingToText(String name) => choose(
    vi: "Đang trả lời $name",
    en: "Replying to $name",
    zh: "正在回复 $name",
    ko: "$name님에게 답장 중",
    ja: "$name に返信中",
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
  );

  String deviceReturnedNormalMessage(String name) => choose(
    vi: "\"$name\" đã trở lại trạng thái bình thường.",
    en: "\"$name\" has returned to normal.",
    zh: "“$name”已恢复正常状态。",
    ko: "\"$name\"이 정상 상태로 돌아왔습니다.",
    ja: "「$name」は通常状態に戻りました。",
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
  );

  String deviceSosClearedMessage(String name) => choose(
    vi: "\"$name\" đã hết trạng thái SOS.",
    en: "\"$name\" is no longer in SOS state.",
    zh: "“$name”的 SOS 状态已解除。",
    ko: "\"$name\"의 SOS 상태가 해제되었습니다.",
    ja: "「$name」の SOS 状態は解除されました。",
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
  );

  String deviceTamperClearedMessage(String name) => choose(
    vi: "\"$name\" đã hết cảnh báo tháo/cạy.",
    en: "\"$name\" tamper alert has cleared.",
    zh: "“$name”的拆卸/撬动警报已解除。",
    ko: "\"$name\"의 분리 경고가 해제되었습니다.",
    ja: "「$name」の取り外し警告は解除されました。",
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
        );
      case "smoke":
      case "fire":
        return choose(
          vi: "Có dấu hiệu khói hoặc cháy",
          en: "Smoke or fire was detected",
          zh: "检测到烟雾或火灾迹象",
          ko: "연기 또는 화재 징후가 있습니다",
          ja: "煙または火災の兆候があります",
        );
      case "flood":
      case "water":
        return choose(
          vi: "Có dấu hiệu ngập nước",
          en: "Water flooding was detected",
          zh: "检测到漏水迹象",
          ko: "침수 징후가 있습니다",
          ja: "浸水の兆候があります",
        );
      case "gas":
        return choose(
          vi: "Có dấu hiệu rò khí",
          en: "A gas leak was detected",
          zh: "检测到燃气泄漏迹象",
          ko: "가스 누출 징후가 있습니다",
          ja: "ガス漏れの兆候があります",
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
        );
      default:
        return choose(
          vi: "Có thiết bị đang cảnh báo",
          en: "A device is alerting",
          zh: "有设备正在报警",
          ko: "경보 중인 기기가 있습니다",
          ja: "アラート中のデバイスがあります",
        );
    }
  }

  String alarmEmergencyEscalationText() => choose(
    vi: "Nếu chưa có ai xác nhận, SafeHome sẽ chuyển sang gọi điện khẩn cấp.",
    en: "If no one confirms, SafeHome will switch to an emergency call.",
    zh: "如果没有人确认，SafeHome 将转为紧急呼叫。",
    ko: "아무도 확인하지 않으면 SafeHome이 긴급 전화로 전환합니다.",
    ja: "誰も確認しない場合、SafeHome は緊急通話に切り替えます。",
  );

  String alarmRepeatAtText(String time) => choose(
    vi: "Báo lại lúc $time nếu vấn đề chưa được xử lý.",
    en: "Alerts again at $time if the issue has not been handled.",
    zh: "如果问题尚未处理，将在 $time 再次提醒。",
    ko: "문제가 처리되지 않으면 $time에 다시 알립니다.",
    ja: "問題が解決されていない場合、$time に再度通知します。",
  );

  String alarmRepeatByScheduleText() => choose(
    vi: "Sẽ báo lại theo lịch Alarm đã cài nếu vấn đề chưa được xử lý.",
    en: "Alerts again according to the Alarm schedule if the issue has not been handled.",
    zh: "如果问题尚未处理，将按已设置的 Alarm 计划再次提醒。",
    ko: "문제가 처리되지 않으면 설정된 Alarm 일정에 따라 다시 알립니다.",
    ja: "問題が解決されていない場合、設定済みの Alarm スケジュールに従って再度通知します。",
  );

  String stripSafetyStatusText(String text) {
    var result = text
        .replaceAll("⚠️", "")
        .replaceAll("✅", "");

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
    ]) {
      result = result.replaceAll(value, "");
    }

    return result.trim();
  }

  String notificationTitle(
    Map<String, dynamic> item, {
    String homeName = "",
  }) {
    final type = _notificationString(item, "type").toLowerCase();
    final rawTitle = _notificationString(item, "title");

    if (_isManualSecurityModeNotification(type)) {
      return manualSecurityModeEnabledTitle();
    }

    if (_isMemberLeftHomeNotification(type)) {
      return memberLeftHomeTitle();
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

    if (_isManualSecurityModeNotification(type)) {
      final actorName = _firstNotificationString(item, const ["actorName"]);
      final repeatMinutesValue = _firstNotificationValue(
        item,
        const ["securityModeRepeatMinutes"],
      );
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
      final memberName = _firstNotificationString(
        item,
        const ["targetName", "memberName"],
      );
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

  bool _isManualSecurityModeNotification(String type) {
    return type == "manual_security_mode_enabled";
  }

  bool _isMemberLeftHomeNotification(String type) {
    return type == "member_leave" || type == "member_left_home";
  }

  bool _isAlarmSettingChangedNotification(String type) {
    return type == "alarm_setting_changed";
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
    "TẮT CẢNH BÁO": "TURN OFF ALERT",
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
    "TẮT CẢNH BÁO": "关闭警报",
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
    "Bật Bảo vệ thủ công?": "수동 Guard 모드를 켜시겠습니까?",
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
    "Đã chuyển nhà về Bình thường": "집이 Normal로 전환되었습니다",
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
    "Bảo vệ thủ công đang bật - chỉ tắt khi chuyển về Bình thường": "수동 Guard 모드가 켜져 있습니다 - 끄려면 Normal로 전환하세요",
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
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "켜면 보안 기기가 즉시 모니터링됩니다.\n\n외출 시 자동 Guard는 일시 중지됩니다. 이 모드는 누군가 집에 돌아와도 자동으로 꺼지지 않으며, 권한이 있는 구성원이 직접 Normal로 전환해야 합니다.",
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
    "TẮT CẢNH BÁO": "경고 끄기",
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
    "Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ":
        "自動警戒を有効にする前に家の位置を設定してください",
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
    "Hãy cấp quyền vị trí trong Cài đặt ứng dụng":
        "アプリ設定で位置情報の権限を許可してください",
    "Đã bật tự động Bảo vệ khi mọi người rời nhà":
        "全員が外出したときの自動警戒を有効にしました",
    "Đã tắt tự động Bảo vệ khi mọi người rời nhà":
        "全員が外出したときの自動警戒を無効にしました",
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
    "Nhà cần có ít nhất một thiết bị để test":
        "テストするには家に少なくとも 1 台のデバイスが必要です",
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
    "Hành động này sẽ xoá toàn bộ dữ liệu:":
        "この操作によりすべてのデータが削除されます:",
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
    "Nhà đang hoạt động ổn định, bạn có thể yên tâm.":
        "家は安定して稼働しています。安心してご利用いただけます。",
    "Chưa có nhiều hoạt động mới để phân tích sâu hơn.":
        "詳細に分析するための新しい活動がまだ十分にありません。",
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
    "Bật Bảo vệ thủ công?": "手動 Guard モードをオンにしますか？",
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
    "Chỉ Chủ nhà hoặc Quản trị viên mới có quyền thay đổi Mode Bảo vệ": "所有者または管理者のみがGuardモードを変更できます",
    "Không thể thay đổi chế độ nhà": "家のモードを変更できませんでした",
    "Đã bật Bảo vệ nhưng chưa gửi được thông báo": "Guardモードはオンですが、通知を送信できませんでした",
    "Đã bật Mode Bảo vệ thủ công": "手動Guardモードがオンになりました",
    "Đã chuyển nhà về Bình thường": "家をNormalに戻しました",
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
    "Chọn 0 để chỉ báo một lần. Cài đặt này dùng cho cả Bảo vệ thủ công và Tự động Bảo vệ khi rời nhà.": "0 を選ぶと 1 回だけ通知します。この設定は手動 Guard モードと外出時の自動 Guard の両方に適用されます。",
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
    "Khi bật, các thiết bị an ninh sẽ được giám sát ngay.\n\nTự động Bảo vệ khi rời nhà sẽ tạm dừng. Chế độ này không tự tắt khi có người về nhà và chỉ được tắt khi một thành viên có quyền chủ động chuyển về Bình thường.": "オンにすると、セキュリティデバイスはすぐに監視されます。\n\n外出時の自動 Guard は一時停止します。このモードは誰かが帰宅しても自動ではオフにならず、権限のあるメンバーが手動で Normal に戻す必要があります。",
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
    "TẮT CẢNH BÁO": "警報を停止",
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

  String autoCloseAfter(String time) => choose(
    vi: "Tự đóng sau $time",
    en: "Auto-closes in $time",
    zh: "$time 后自动关闭",
    ko: "$time 후 자동으로 닫힘",
    ja: "$time 後に自動で閉じます",
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
