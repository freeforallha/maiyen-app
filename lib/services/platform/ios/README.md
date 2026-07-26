# MaiYen iOS Alarm Bridge

## Đã triển khai trong bước này

- Foreground: `alarm_siren` vẫn mở `FullscreenAlarmPage` ngay và dùng nguyên
  logic gom incident của Android.
- Khi người dùng chạm Alarm trên iOS: ứng dụng mở trang Alarm trước, sau đó
  tải lại toàn bộ `alarmIncidents` đang `active` để gom nhiều nhà/nhiều thiết
  bị vào cùng giao diện.
- Background / màn hình khoá:
  - Alarm an ninh dùng APNs Time Sensitive ngay từ cấp phát hiện đầu tiên;
    cấp đầu có thể im lặng, các cấp sau phát âm thanh theo logic hiện tại.
  - Emergency dùng Time Sensitive trong giai đoạn chưa có Critical Alerts
    entitlement.
  - Notification được nhóm theo Home và cập nhật theo incident.
- Notification cục bộ foreground dùng category, thread và interruption level
  riêng cho Alarm, Emergency, Sensor, Chat và Reminder.
- Màn hình cấu hình Alarm và bảng kiểm tra hệ thống hiển thị rõ giới hạn iOS.

## Critical Alerts đã được chuẩn bị nhưng mặc định tắt

Không thêm `com.apple.developer.usernotifications.critical-alerts` vào
`Runner.entitlements` khi chưa được Apple phê duyệt, vì việc thêm sớm có thể
làm lỗi signing/provisioning.

Sau khi Apple cấp entitlement:

1. Bật Push Notifications, Background Modes → Remote notifications và
   Time Sensitive Notifications trong Xcode.
2. Bật Critical Alerts capability sau khi Apple phê duyệt.
3. Thêm entitlement do Apple cấp vào provisioning profile.
4. Build Flutter với:

   `--dart-define=SAFEHOME_IOS_CRITICAL_ALERTS=true`

5. Trên backend đặt:

   `SAFEHOME_IOS_CRITICAL_ALERTS_ENABLED=true`

Nếu chưa bật hai phía trên, Emergency tự động dùng Time Sensitive và âm thanh
notification thông thường, không làm hỏng build tài khoản cá nhân.


## Giới hạn cần giữ nguyên trong thiết kế

- iOS không cho ứng dụng tự ép mở giao diện Flutter khi đang background hoặc
  ở màn hình khoá. Notification hệ thống là điểm tiếp cận chính; khi người
  dùng chạm vào, MaiYen mới mở `FullscreenAlarmPage`.
- Push `alarm_resolved` chạy nền có thể bị iOS trì hoãn hoặc không giao ngay.
  Việc dọn notification đã giao là best-effort; dữ liệu incident trên Firebase
  vẫn là nguồn trạng thái thật khi ứng dụng được mở lại.
- iOS 14 bỏ qua interruption level Time Sensitive và tự rơi về notification
  có âm thanh thông thường.

## Việc cần test khi có Apple Developer account

- APNs token và FCM token trên thiết bị thật.
- Push Notifications capability.
- Background Modes: Remote notifications.
- Time Sensitive trong Focus và khi màn hình khoá.
- Critical Alerts sau khi entitlement được duyệt.
- Âm thanh khi máy ở Silent/Focus.
- Tap notification từ foreground, background và terminated.
- Nhiều incident cùng nhà và khác nhà.
