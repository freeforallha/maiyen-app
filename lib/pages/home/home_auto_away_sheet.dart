import 'package:flutter/material.dart';

import '../../helpers/top_toast.dart';
import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';
import '../../navigation/safehome_navigation.dart';

class HomeAutoAwayLocation {
  const HomeAutoAwayLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class HomeAutoAwayFormData {
  const HomeAutoAwayFormData({
    required this.enabled,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final bool enabled;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
}

Future<void> showHomeAutoAwaySheet({
  required BuildContext context,
  required AppStrings strings,
  required bool initialEnabled,
  required double? initialLatitude,
  required double? initialLongitude,
  required int radiusMeters,
  required Future<HomeAutoAwayLocation?> Function() onCaptureLocation,
  required Future<bool> Function(HomeAutoAwayFormData data) onSave,
}) async {
  var localEnabled = initialEnabled;
  var latitude = initialLatitude;
  var longitude = initialLongitude;
  var locating = false;
  var saving = false;

  await SafeHomeNavigation.pushChildPage<void>(
    context: context,
    routeName: "home_auto_away",
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (innerContext, setSheetState) {
          final currentLatitude = latitude;
          final currentLongitude = longitude;
          final hasLocation =
              currentLatitude != null && currentLongitude != null;
          final locationText = hasLocation
              ? "${strings.t("Đã đặt vị trí nhà")}\n"
                    "${currentLatitude.toStringAsFixed(6)}, "
                    "${currentLongitude.toStringAsFixed(6)}"
              : strings.t("Chưa đặt vị trí nhà");

          Future<void> captureCurrentLocation() async {
            if (locating) {
              return;
            }

            setSheetState(() {
              locating = true;
            });

            try {
              final location = await onCaptureLocation();

              if (!sheetContext.mounted || location == null) {
                return;
              }

              setSheetState(() {
                latitude = location.latitude;
                longitude = location.longitude;
              });
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() {
                  locating = false;
                });
              }
            }
          }

          Future<void> saveAutoAway() async {
            if (saving) {
              return;
            }

            if (localEnabled && !hasLocation) {
              showTopToast(
                sheetContext,
                strings.t("Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ"),
                color: Colors.orange,
                icon: Icons.location_on_outlined,
              );
              return;
            }

            setSheetState(() {
              saving = true;
            });

            try {
              final saved = await onSave(
                HomeAutoAwayFormData(
                  enabled: localEnabled,
                  latitude: latitude,
                  longitude: longitude,
                  radiusMeters: radiusMeters,
                ),
              );

              if (!sheetContext.mounted) {
                return;
              }

              if (saved) {
                Navigator.of(sheetContext).pop();
              }
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() {
                  saving = false;
                });
              }
            }
          }

          return SafeArea(
            child: Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 12,
                bottom: MediaQuery.of(innerContext).viewInsets.bottom + 18,
              ),
              decoration: const BoxDecoration(
                color: SafeHomeColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: SafeHomeColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: SafeHomeColors.primarySoft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: SafeHomeColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t("Tự động Bảo vệ khi rời nhà"),
                              style: const TextStyle(
                                color: SafeHomeColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              strings.t("Bán kính bảo vệ mặc định: 150 m"),
                              style: const TextStyle(
                                color: SafeHomeColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: localEnabled,
                        onChanged: (value) {
                          setSheetState(() {
                            localEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SafeHomeColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SafeHomeColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasLocation
                              ? Icons.check_circle_rounded
                              : Icons.location_searching_rounded,
                          color: hasLocation
                              ? SafeHomeColors.safe
                              : SafeHomeColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            locationText,
                            style: const TextStyle(
                              color: SafeHomeColors.textPrimary,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: locating ? null : captureCurrentLocation,
                      icon: locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: Text(
                        locating
                            ? strings.t("Đang lấy vị trí...")
                            : strings.t("Đặt vị trí nhà tại đây"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.t(
                      "Mỗi thành viên sẽ cần cấp quyền vị trí Luôn cho phép để trạng thái rời/đến nhà hoạt động khi ứng dụng chạy nền.",
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SafeHomeColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : saveAutoAway,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        saving
                            ? strings.t("Đang lưu...")
                            : strings.t("Lưu cài đặt"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
