import 'package:flutter/material.dart';

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
  required VoidCallback onDeleteHome,
  required ValueNotifier<int> inviteCountNotifier,
  required VoidCallback onTransferOwner,
  required VoidCallback onAllDevices,
  required VoidCallback onAccount,
}) {
  Widget tile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("🏡", style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      homeName.isNotEmpty ? homeName : "Chưa đặt tên",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  Icon(
                                    role == "owner"
                                        ? Icons.workspace_premium_rounded
                                        : role == "admin"
                                        ? Icons.admin_panel_settings_rounded
                                        : Icons.person_rounded,
                                    size: 18,
                                    color: role == "owner"
                                        ? Colors.amber
                                        : role == "admin"
                                        ? Colors.deepPurple
                                        : Colors.blueGrey,
                                  ),
                                ],
                              ),
                            ),

                            if (role == "owner" || role == "admin")
                              GestureDetector(
                                onTap: onRenameHome,
                                child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 17,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  SelectableText(
                    "HomeID: $homeId",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (homeAddress.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "📍 $homeAddress",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            tile(
              icon: Icons.share_rounded,
              title: "Chia sẻ nhà",
              color: Colors.blue,
              onTap: () {
                Navigator.of(sheetContext).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onShare();
                });
              },
            ),

            tile(
              icon: Icons.people_alt_rounded,
              title: "Thành viên trong nhà",
              color: Colors.green,
              onTap: () {
                Navigator.of(sheetContext).pop();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onShareList();
                });
              },
            ),
            tile(
              icon: Icons.meeting_room_rounded,
              title: "Quản lý phòng",
              color: Colors.orange,
              onTap: () {
                Navigator.of(sheetContext).pop();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onRooms();
                });
              },
            ),
            if (role == "owner")
              tile(
                icon: Icons.swap_horiz,
                title: "Chuyển quyền chủ nhà",
                color: Colors.purple,
                onTap: onTransferOwner,
              ),

            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.teal,
                  ),
                ),
                title: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Tài khoản cá nhân",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    ValueListenableBuilder<int>(
                      valueListenable: inviteCountNotifier,
                      builder: (_, inviteCount, __) {
                        if (inviteCount <= 0) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            inviteCount > 99 ? "99+" : "$inviteCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onAccount,
              ),
            ),

            tile(
              icon: Icons.sensors_rounded,
              title: "Toàn bộ thiết bị SafeHome",
              color: Colors.indigo,
              onTap: onAllDevices,
            ),

            const SizedBox(height: 8),

            if (role == "owner")
              tile(
                icon: Icons.delete_forever,
                title: "Xoá Nhà",
                color: Colors.red,
                onTap: onDeleteHome,
              ),
          ],
        ),
      );
    },
  );
}