import 'package:flutter/material.dart';

import '../../localization/app_strings.dart';
import '../../safehome_theme.dart';

class HomeAlarmPauseFormData {
  const HomeAlarmPauseFormData({
    required this.startTime,
    required this.endTime,
    required this.reason,
  });

  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String reason;
}

Future<void> showHomeAlarmPauseSheet({
  required BuildContext context,
  required TimeOfDay initialStartTime,
  required TimeOfDay initialEndTime,
  required bool showRemoveButton,
  required Future<String?> Function({
    required BuildContext context,
    required String title,
    required String initial,
  })
  onPickTime,
  required Future<bool> Function(
    BuildContext sheetContext,
    HomeAlarmPauseFormData data,
  )
  onSave,
  required Future<bool> Function(BuildContext sheetContext) onRemove,
}) async {
  var startTime = initialStartTime;
  var endTime = initialEndTime;
  var reason = "Về muộn";

  String format(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}";
  }

  TimeOfDay parsePickedTime(String value, TimeOfDay fallback) {
    final parts = value.split(":");

    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? fallback.hour,
      minute: int.tryParse(parts[1]) ?? fallback.minute,
    );
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (stateContext, setSheetState) {
          final sheetStrings = AppStrings.of(stateContext);

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: SafeHomeColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Text(
                    sheetStrings.t("Tạm tắt báo động hôm nay"),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await onPickTime(
                              context: stateContext,
                              title: sheetStrings.t("Chọn giờ bắt đầu tạm tắt"),
                              initial: format(startTime),
                            );

                            if (!stateContext.mounted || picked == null) {
                              return;
                            }

                            setSheetState(() {
                              startTime = parsePickedTime(picked, startTime);
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(sheetStrings.t("Từ")),
                                const SizedBox(height: 6),
                                Text(
                                  format(startTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await onPickTime(
                              context: stateContext,
                              title: sheetStrings.t(
                                "Chọn giờ kết thúc tạm tắt",
                              ),
                              initial: format(endTime),
                            );

                            if (!stateContext.mounted || picked == null) {
                              return;
                            }

                            setSheetState(() {
                              endTime = parsePickedTime(picked, endTime);
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text(sheetStrings.t("Đến")),
                                const SizedBox(height: 6),
                                Text(
                                  format(endTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: ["Về muộn", "Ra ngoài", "Khác"].map((item) {
                      final selected = reason == item;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text(sheetStrings.t(item)),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                reason = item;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: Text(sheetStrings.t("Lưu")),
                      onPressed: () async {
                        final saved = await onSave(
                          sheetContext,
                          HomeAlarmPauseFormData(
                            startTime: startTime,
                            endTime: endTime,
                            reason: reason,
                          ),
                        );

                        if (!sheetContext.mounted || !saved) return;

                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),

                  if (showRemoveButton) ...[
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(sheetStrings.t("Xoá lịch tạm tắt")),
                        onPressed: () async {
                          final removed = await onRemove(sheetContext);

                          if (!sheetContext.mounted || !removed) return;

                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
