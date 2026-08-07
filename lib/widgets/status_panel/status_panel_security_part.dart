part of '../status_panel.dart';

extension _StatusPanelSecurityPart on _StatusPanelState {
  void _showSecurityModeOptions(BuildContext context) {
    final currentMode = normalizeSecurityMode(widget.securityMode);
    final allowedRepeatMinutes = <int>[0, 15, 30, 60];
    var localRepeatMinutes =
        allowedRepeatMinutes.contains(widget.securityModeRepeatMinutes)
        ? widget.securityModeRepeatMinutes
        : 0;
    var repeatSaving = false;

    MaiYenNavigation.showModalSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setSheetState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                decoration: const BoxDecoration(
                  color: MaiYenColors.surface,
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
                        color: MaiYenColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Text(
                      _strings.t('Chế độ nhà'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: MaiYenColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: currentMode == 'armed'
                          ? _strings.armedSecurityModeSourceLabel(
                              widget.securityModeSource,
                            )
                          : _strings.t('Bảo vệ'),
                      subtitle: _strings.t('Giám sát toàn diện'),
                      color: MaiYenColors.danger,
                      selected: currentMode == 'armed',
                      trailing: Container(
                        width: 124,
                        height: 40,
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: MaiYenColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: MaiYenColors.primary.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (repeatSaving)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: SizedBox.square(
                                  dimension: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: localRepeatMinutes,
                                  isExpanded: true,
                                  isDense: true,
                                  borderRadius: BorderRadius.circular(14),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: MaiYenColors.primary,
                                  ),
                                  items: allowedRepeatMinutes
                                      .map(
                                        (minutes) => DropdownMenuItem<int>(
                                          value: minutes,
                                          child: Text(
                                            minutes == 0
                                                ? _strings.t('Không lặp lại')
                                                : _strings.minuteText(minutes),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: MaiYenColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged:
                                      widget.onSecurityModeRepeatChanged ==
                                              null ||
                                          repeatSaving
                                      ? null
                                      : (minutes) async {
                                          if (minutes == null ||
                                              minutes == localRepeatMinutes) {
                                            return;
                                          }

                                          setSheetState(() {
                                            repeatSaving = true;
                                          });

                                          final saved =
                                              await widget
                                                  .onSecurityModeRepeatChanged!(
                                                minutes,
                                              );

                                          if (!stateContext.mounted) {
                                            return;
                                          }

                                          setSheetState(() {
                                            if (saved) {
                                              localRepeatMinutes = minutes;
                                            }

                                            repeatSaving = false;
                                          });
                                        },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call('armed');
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.shield_rounded,
                      title: _strings.t('Bình thường'),
                      subtitle: currentMode == 'normal'
                          ? _strings.t('Đang được sử dụng')
                          : _strings.t(
                              'Sử dụng báo động theo lịch đã thiết lập',
                            ),
                      color: MaiYenColors.textSecondary,
                      selectedColor: MaiYenColors.textSecondary,
                      selected: currentMode == 'normal',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call('normal');
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionTile(
                      icon: Icons.shield_outlined,
                      title: _strings.t('Không bảo vệ'),
                      subtitle: _strings.t(
                        'Chỉ gửi thông báo, không kích hoạt báo động',
                      ),
                      color: MaiYenColors.textSecondary,
                      selected: currentMode == 'unprotected',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onSecurityModeChanged?.call('unprotected');
                      },
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

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Color? selectedColor,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: selected
          ? MaiYenColors.primary.withValues(alpha: 0.08)
          : MaiYenColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? MaiYenColors.primary.withValues(alpha: 0.42)
                  : MaiYenColors.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? MaiYenColors.primary.withValues(alpha: 0.14)
                      : color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? (selectedColor ?? MaiYenColors.primary)
                      : color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MaiYenColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: MaiYenColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing],
            ],
          ),
        ),
      ),
    );
  }
}
