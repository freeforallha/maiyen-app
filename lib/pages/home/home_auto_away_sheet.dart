import 'package:flutter/material.dart';

import '../../helpers/top_toast.dart';
import '../../localization/app_strings.dart';
import '../../navigation/maiyen_navigation.dart';
import '../../maiyen_theme.dart';
import 'home_auto_away_models.dart';

Future<void> showHomeAutoAwaySheet({
  required BuildContext context,
  required AppStrings strings,
  required bool initialEnabled,
  required double? initialLatitude,
  required double? initialLongitude,
  required int radiusMeters,
  required List<HomeAutoAwayMember> members,
  required Set<String> initialParticipantUids,
  required Future<HomeAutoAwayLocation?> Function() onCaptureLocation,
  required Future<HomeAutoAwayLocation?> Function({
    required double? latitude,
    required double? longitude,
    required int radiusMeters,
  })
  onPickLocationOnMap,
  required Future<bool> Function(HomeAutoAwayFormData data) onSave,
}) async {
  var localEnabled = initialEnabled;
  var latitude = initialLatitude;
  var longitude = initialLongitude;
  var locating = false;
  var openingMap = false;
  var saving = false;
  final memberUids = members.map((member) => member.uid).toSet();
  final selectedParticipantUids = initialParticipantUids
      .where(memberUids.contains)
      .toSet();

  if (selectedParticipantUids.isEmpty && members.isNotEmpty) {
    selectedParticipantUids.addAll(memberUids);
  }

  await MaiYenNavigation.pushChildPage<void>(
    context: context,
    routeName: 'home_auto_away',
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (innerContext, setSheetState) {
          final currentLatitude = latitude;
          final currentLongitude = longitude;
          final hasLocation =
              currentLatitude != null && currentLongitude != null;
          final locationText = hasLocation
              ? '${strings.t("Đã đặt vị trí nhà")}\n'
                    '${currentLatitude.toStringAsFixed(6)}, '
                    '${currentLongitude.toStringAsFixed(6)}'
              : strings.t('Chưa đặt vị trí nhà');
          final allParticipantsSelected =
              members.isNotEmpty &&
              selectedParticipantUids.length == memberUids.length;
          final masterParticipantValue = allParticipantsSelected
              ? true
              : selectedParticipantUids.isEmpty
              ? false
              : null;

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

          Future<void> pickLocationOnMap() async {
            if (openingMap) {
              return;
            }

            setSheetState(() {
              openingMap = true;
            });

            try {
              final location = await onPickLocationOnMap(
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
              );

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
                  openingMap = false;
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
                strings.t('Hãy đặt vị trí nhà trước khi bật tự động Bảo vệ'),
                color: Colors.orange,
                icon: Icons.location_on_outlined,
              );
              return;
            }

            if (selectedParticipantUids.isEmpty) {
              showTopToast(
                sheetContext,
                strings.autoAwaySelectAtLeastOneParticipant,
                color: Colors.orange,
                icon: Icons.group_off_rounded,
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
                  participantUids: Set<String>.from(selectedParticipantUids),
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: MaiYenColors.primarySoft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: MaiYenColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t('Tự động Bảo vệ khi rời nhà'),
                              style: const TextStyle(
                                color: MaiYenColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              strings.t('Bán kính bảo vệ mặc định: 150 m'),
                              style: const TextStyle(
                                color: MaiYenColors.textSecondary,
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
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MaiYenColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: MaiYenColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasLocation
                                  ? Icons.check_circle_rounded
                                  : Icons.location_searching_rounded,
                              color: hasLocation
                                  ? MaiYenColors.safe
                                  : MaiYenColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                locationText,
                                style: const TextStyle(
                                  color: MaiYenColors.textPrimary,
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
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: locating
                                  ? null
                                  : captureCurrentLocation,
                              icon: locating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded),
                              label: Text(
                                locating
                                    ? strings.t('Đang lấy vị trí...')
                                    : strings.t('Đặt vị trí nhà tại đây'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: openingMap ? null : pickLocationOnMap,
                              icon: openingMap
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.map_rounded),
                              label: Text(strings.autoAwayChooseOnMap),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        strings.autoAwayParticipantsTitle,
                        style: const TextStyle(
                          color: MaiYenColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        strings.autoAwayParticipantsDescription,
                        style: const TextStyle(
                          color: MaiYenColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: MaiYenColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: MaiYenColors.border),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              onTap: members.isEmpty
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        if (allParticipantsSelected) {
                                          selectedParticipantUids.clear();
                                        } else {
                                          selectedParticipantUids
                                            ..clear()
                                            ..addAll(memberUids);
                                        }
                                      });
                                    },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  8,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.groups_rounded,
                                      color: MaiYenColors.primary,
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Text(
                                        strings.autoAwayAllParticipants,
                                        style: const TextStyle(
                                          color: MaiYenColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Checkbox.adaptive(
                                      tristate: true,
                                      value: masterParticipantValue,
                                      onChanged: members.isEmpty
                                          ? null
                                          : (_) {
                                              setSheetState(() {
                                                if (allParticipantsSelected) {
                                                  selectedParticipantUids
                                                      .clear();
                                                } else {
                                                  selectedParticipantUids
                                                    ..clear()
                                                    ..addAll(memberUids);
                                                }
                                              });
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (members.isNotEmpty)
                              const Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                                color: MaiYenColors.border,
                              ),
                            for (var index = 0; index < members.length; index++)
                              _AutoAwayMemberTile(
                                member: members[index],
                                strings: strings,
                                selected: selectedParticipantUids.contains(
                                  members[index].uid,
                                ),
                                showDivider: index < members.length - 1,
                                onChanged: (selected) {
                                  setSheetState(() {
                                    if (selected) {
                                      selectedParticipantUids.add(
                                        members[index].uid,
                                      );
                                    } else {
                                      selectedParticipantUids.remove(
                                        members[index].uid,
                                      );
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.autoAwaySelectedMembersPermissionHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MaiYenColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    MediaQuery.of(innerContext).viewInsets.bottom + 18,
                  ),
                  child: SizedBox(
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
                            ? strings.t('Đang lưu...')
                            : strings.t('Lưu cài đặt'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _AutoAwayMemberTile extends StatelessWidget {
  const _AutoAwayMemberTile({
    required this.member,
    required this.strings,
    required this.selected,
    required this.showDivider,
    required this.onChanged,
  });

  final HomeAutoAwayMember member;
  final AppStrings strings;
  final bool selected;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  String get _roleLabel {
    switch (member.role) {
      case 'owner':
        return strings.owner;
      case 'admin':
        return strings.admin;
      default:
        return strings.member;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = member.email.trim().isNotEmpty
        ? '${_roleLabel} • ${member.email.trim()}'
        : _roleLabel;

    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(!selected),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: MaiYenColors.primarySoft,
                  backgroundImage: member.photoUrl.trim().isNotEmpty
                      ? NetworkImage(member.photoUrl.trim())
                      : null,
                  child: member.photoUrl.trim().isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: MaiYenColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MaiYenColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MaiYenColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox.adaptive(
                  value: selected,
                  onChanged: (value) => onChanged(value == true),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 63,
            endIndent: 12,
            color: MaiYenColors.border,
          ),
      ],
    );
  }
}
