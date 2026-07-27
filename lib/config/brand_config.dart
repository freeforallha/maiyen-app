import 'system_version.dart';
import 'maiyen_identifiers.dart';

class BrandConfig {
  BrandConfig._();

  /// Tên thương hiệu hiển thị với người dùng.
  static const String appName = 'MaiYen';

  /// Dùng tại logo chữ hoặc tiêu đề cần viết hoa toàn bộ.
  static const String appNameUppercase = 'MAIYEN';

  /// Slogan chính thức tại Việt Nam.
  static const String sloganVi = 'Vẹn nguyên tổ ấm';

  /// Tên Hub mặc định khi người dùng chưa đặt tên riêng.
  static const String defaultHubName = '$appName Hub';

  /// User-Agent công khai khi ứng dụng gọi dịch vụ bản đồ.
  /// Package kỹ thuật chính thức của ứng dụng MaiYen.
  static const String mapUserAgent =
      '$appName/${SystemVersionConfig.appVersionName} '
      '(${MaiYenIdentifiers.applicationId})';
}
