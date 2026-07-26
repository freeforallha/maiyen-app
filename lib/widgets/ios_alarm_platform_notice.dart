import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../maiyen_theme.dart';

/// Cảnh báo ngắn đặt ngay cạnh phần cấu hình Alarm cá nhân trên iOS.
/// Dùng toàn bộ key dịch đã có, không phát sinh key localization mới.
class IosAlarmPlatformNotice extends StatelessWidget {
  const IosAlarmPlatformNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    final strings = AppStrings.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MaiYenColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaiYenColors.info.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.phone_iphone_rounded,
              size: 20,
              color: MaiYenColors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('Cảnh báo trên iOS'),
                  style: const TextStyle(
                    color: MaiYenColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.t(
                    'iOS không mở toàn màn hình như Android; ứng dụng dùng thông báo và âm thanh hệ thống.',
                  ),
                  style: const TextStyle(
                    color: MaiYenColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
