import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../safehome_theme.dart';

/// Điều hướng thống nhất theo đúng loại giao diện của SafeHome.
///
/// - Trang chức năng/chi tiết: mở toàn màn hình, trượt từ phải sang.
/// - Thao tác nhanh/lựa chọn/xác nhận: dùng bottom sheet từ dưới lên.
/// - Không chèn nút Back tùy chỉnh vào nội dung.
/// - Android dùng nút Back hệ thống; iOS hỗ trợ vuốt từ mép trái.
class SafeHomeNavigation {
  const SafeHomeNavigation._();

  /// Mở trang chức năng hoặc trang chi tiết.
  ///
  /// CupertinoPageRoute được dùng cho cả Android và iOS để giữ cùng chuyển
  /// động ngang, đồng thời cho phép thao tác vuốt Back tự nhiên trên iOS.
  static Future<T?> pushChildPage<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? routeName,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);

    return navigator.push<T>(
      CupertinoPageRoute<T>(
        settings: RouteSettings(name: routeName),
        builder: (pageContext) {
          return Scaffold(
            backgroundColor: SafeHomeColors.background,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              bottom: false,
              child: SizedBox.expand(
                child: Builder(builder: builder),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Mở thao tác ngắn bằng bottom sheet chuẩn của Flutter.
  ///
  /// Hàm giữ nguyên tên để các vị trí hiện tại không cần sửa đồng loạt, nhưng
  /// hành vi đã trở lại đúng chuẩn: xuất hiện từ dưới lên và có thể vuốt xuống.
  static Future<T?> showModalSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    Color? backgroundColor,
    ShapeBorder? shape,
    bool useRootNavigator = false,
    bool useSafeArea = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool? showDragHandle,
    BoxConstraints? constraints,
    RouteSettings? routeSettings,
    Color? barrierColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: shape,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      constraints: constraints,
      routeSettings: routeSettings,
      barrierColor: barrierColor,
    );
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
