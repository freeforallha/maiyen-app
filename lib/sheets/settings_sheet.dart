import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../safehome_theme.dart';

void showSettingsSheet({
  required String homeId,
  required String homeName,
  required String homeAddress,
  required String role,
  required BuildContext context,
  required VoidCallback onShareRequests,
  required VoidCallback onShare,
  required VoidCallback onShareList,
  required VoidCallback onRooms,
  required VoidCallback onLogout,
  required VoidCallback onRenameHome,
  required VoidCallback onSecurityTest,
  required VoidCallback onDeleteHome,
  required ValueNotifier<int> inviteCountNotifier,
  required VoidCallback onTransferOwner,
  required VoidCallback onAllDevices,
  required VoidCallback onAccount,
}) {
  int hiddenSecurityTapCount = 0;
  DateTime? lastHiddenSecurityTapAt;

  final memberCountFuture = FirebaseDatabase.instance
      .ref("sharedByHome/$homeId")
      .get()
      .then<int>((snapshot) {
    final raw = snapshot.value;

    if (raw is! Map) {
      return 0;
    }

    return raw.values.where((value) => value != null).length;
  }).catchError((_) => 0);

  void handleHiddenSecurityTap(
      BuildContext sheetContext,
      ) {
    if (role != "owner") {
      return;
    }

    final now = DateTime.now();

    final isContinuous = lastHiddenSecurityTapAt != null &&
        now.difference(lastHiddenSecurityTapAt!).inMilliseconds <=
            1500;

    if (isContinuous) {
      hiddenSecurityTapCount++;
    } else {
      hiddenSecurityTapCount = 1;
    }

    lastHiddenSecurityTapAt = now;

    if (hiddenSecurityTapCount < 5) {
      return;
    }

    hiddenSecurityTapCount = 0;
    lastHiddenSecurityTapAt = null;

    Navigator.of(sheetContext).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSecurityTest();
    });
  }

  void closeThen(
      BuildContext sheetContext,
      VoidCallback action,
      ) {
    Navigator.of(sheetContext).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      action();
    });
  }

  IconData roleIcon() {
    if (role == "owner") {
      return Icons.workspace_premium_rounded;
    }

    if (role == "admin") {
      return Icons.admin_panel_settings_rounded;
    }

    return Icons.person_rounded;
  }

  Color roleColor() {
    if (role == "owner") {
      return const Color(0xFFD79A24);
    }

    if (role == "admin") {
      return const Color(0xFF7656C8);
    }

    return SafeHomeColors.info;
  }

  String roleText() {
    if (role == "owner") {
      return "Chủ nhà";
    }

    if (role == "admin") {
      return "Quản trị viên";
    }

    return "Thành viên";
  }

  Widget homeInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    final displayValue =
    value.trim().isEmpty ? "Chưa cập nhật" : value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: valueColor ?? SafeHomeColors.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(
                      color: SafeHomeColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: displayValue,
                    style: TextStyle(
                      color:
                      valueColor ?? SafeHomeColors.textPrimary,
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 9),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: SafeHomeColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.75,
          ),
        ),
      ),
    );
  }

  Widget tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
    bool destructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: SafeHomeColors.surface,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: destructive
                    ? SafeHomeColors.danger.withValues(alpha: 0.16)
                    : SafeHomeColors.border,
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.028),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: destructive
                              ? SafeHomeColors.danger
                              : SafeHomeColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SafeHomeColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SafeHomeColors.textSecondary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
            MediaQuery.of(sheetContext).size.height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: SafeHomeColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: SafeHomeColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SafeHomeColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: SafeHomeColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.04,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 108,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: SafeHomeColors
                                                .primarySoft,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: SafeHomeColors
                                                  .primary
                                                  .withValues(
                                                alpha: 0.18,
                                              ),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.home_rounded,
                                            color:
                                            SafeHomeColors.primary,
                                            size: 36,
                                          ),
                                        ),
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Material(
                                            color:
                                            SafeHomeColors.primary,
                                            shape:
                                            const CircleBorder(),
                                            child: InkWell(
                                              onTap: () {
                                                closeThen(
                                                  sheetContext,
                                                  onRenameHome,
                                                );
                                              },
                                              customBorder:
                                              const CircleBorder(),
                                              child: const SizedBox(
                                                width: 28,
                                                height: 28,
                                                child: Icon(
                                                  Icons.edit_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 9),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        handleHiddenSecurityTap(
                                          sheetContext,
                                        );
                                      },
                                      child: Text(
                                        homeName.trim().isNotEmpty
                                            ? homeName.trim()
                                            : "Nhà chưa đặt tên",
                                        maxLines: 2,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color:
                                          SafeHomeColors.textPrimary,
                                          fontSize: 15,
                                          height: 1.15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const VerticalDivider(
                                width: 25,
                                thickness: 1,
                                color: SafeHomeColors.border,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    homeInfoRow(
                                      icon: roleIcon(),
                                      label: "Vai trò",
                                      value: roleText(),
                                      valueColor: roleColor(),
                                    ),
                                    homeInfoRow(
                                      icon:
                                      Icons.location_on_outlined,
                                      label: "Địa chỉ",
                                      value: homeAddress,
                                      maxLines: 2,
                                    ),
                                    FutureBuilder<int>(
                                      future: memberCountFuture,
                                      builder: (context, snapshot) {
                                        final value =
                                        snapshot.connectionState ==
                                            ConnectionState
                                                .waiting
                                            ? "Đang tải..."
                                            : "${snapshot.data ?? 0}";

                                        return homeInfoRow(
                                          icon:
                                          Icons.people_alt_rounded,
                                          label: "Thành viên",
                                          value: value,
                                        );
                                      },
                                    ),
                                    homeInfoRow(
                                      icon:
                                      Icons.fingerprint_rounded,
                                      label: "HomeID",
                                      value: homeId,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      sectionTitle("Quản lý nhà"),

                      if (role == "owner" || role == "admin")
                        tile(
                          icon: Icons.share_rounded,
                          title: "Chia sẻ nhà",
                          subtitle:
                          "Mời người khác tham gia nhà này",
                          color: SafeHomeColors.info,
                          onTap: () {
                            closeThen(sheetContext, onShare);
                          },
                        ),

                      tile(
                        icon: Icons.people_alt_rounded,
                        title: "Thành viên trong nhà",
                        subtitle:
                        "Xem và quản lý quyền thành viên",
                        color: SafeHomeColors.safe,
                        onTap: () {
                          closeThen(sheetContext, onShareList);
                        },
                      ),

                      if (role == "owner" || role == "admin")
                        tile(
                          icon: Icons.meeting_room_rounded,
                          title: "Quản lý phòng",
                          subtitle:
                          "Thêm, đổi tên và sắp xếp phòng",
                          color: SafeHomeColors.warning,
                          onTap: () {
                            closeThen(sheetContext, onRooms);
                          },
                        ),

                      tile(
                        icon: Icons.sensors_rounded,
                        title: "Toàn bộ thiết bị",
                        subtitle:
                        "Kiểm tra thiết bị trong nhà này",
                        color: const Color(0xFF576FD0),
                        onTap: () {
                          closeThen(sheetContext, onAllDevices);
                        },
                      ),

                      if (role == "owner")
                        tile(
                          icon: Icons.swap_horiz_rounded,
                          title: "Chuyển quyền chủ nhà",
                          subtitle:
                          "Chuyển quyền sở hữu cho thành viên khác",
                          color: const Color(0xFF7656C8),
                          onTap: () {
                            closeThen(
                              sheetContext,
                              onTransferOwner,
                            );
                          },
                        ),

                      const SizedBox(height: 5),
                      sectionTitle("Tài khoản & hệ thống"),

                      tile(
                        icon: Icons.person_rounded,
                        title: "Tài khoản cá nhân",
                        subtitle:
                        "Hồ sơ, yêu cầu và lời mời tham gia",
                        color: SafeHomeColors.primary,
                        trailing:
                        ValueListenableBuilder<int>(
                          valueListenable:
                          inviteCountNotifier,
                          builder: (_, inviteCount, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (inviteCount > 0)
                                  Container(
                                    constraints:
                                    const BoxConstraints(
                                      minWidth: 22,
                                      minHeight: 22,
                                    ),
                                    alignment: Alignment.center,
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SafeHomeColors.danger,
                                      borderRadius:
                                      BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      inviteCount > 99
                                          ? "99+"
                                          : "$inviteCount",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight:
                                        FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                if (inviteCount > 0)
                                  const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: SafeHomeColors
                                      .textSecondary,
                                ),
                              ],
                            );
                          },
                        ),
                        onTap: () {
                          closeThen(sheetContext, onAccount);
                        },
                      ),

                      if (role == "owner") ...[
                        const SizedBox(height: 5),
                        sectionTitle("Khu vực nguy hiểm"),
                        tile(
                          icon: Icons.delete_forever_rounded,
                          title: "Xoá nhà",
                          subtitle:
                          "Xoá toàn bộ dữ liệu và thiết bị",
                          color: SafeHomeColors.danger,
                          destructive: true,
                          onTap: () {
                            closeThen(
                              sheetContext,
                              onDeleteHome,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
