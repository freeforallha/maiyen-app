import 'system_version.dart';
import 'legacy_identifiers.dart';

class BrandConfig {
  BrandConfig._();

  /// Tên thương hiệu hiển thị với người dùng.
  static const String appName = 'MaiYen';

  /// Dùng tại logo chữ hoặc tiêu đề cần viết hoa toàn bộ.
  static const String appNameUppercase = 'MAIYEN';

  /// Slogan chính thức tại Việt Nam.
  static const String sloganVi = 'Người giữ nhà';

  /// Tên Hub mặc định khi người dùng chưa đặt tên riêng.
  static const String defaultHubName = '$appName Hub';

  /// User-Agent công khai khi ứng dụng gọi dịch vụ bản đồ.
  /// Package kỹ thuật được giữ nguyên để tương thích với bản đang phát hành.
  static const String mapUserAgent =
      '$appName/${SystemVersionConfig.appVersionName} '
      '(${MaiYenLegacyIdentifiers.applicationId})';
}
