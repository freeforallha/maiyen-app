import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../services/home_notification_service.dart';

void showHomeEventSheet({
  required BuildContext context,
  required String uid,
  String Function(String homeId)? homeNameForId,
  Future<void> Function(Map<String, dynamic> notification)? onTapNotification,
}) {
  final strings = AppStrings.of(context);

  HomeNotificationService.markAllAsRead(uid: uid);

  String formatTime(dynamic value) {
    final ts = int.tryParse(value?.toString() ?? "0") ?? 0;
    if (ts <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return strings.t("Vừa xong");
    if (diff.inHours < 1) {
      return strings.minutesAgo(diff.inMinutes);
    }
    if (diff.inDays < 1) {
      return strings.hoursAgo(diff.inHours);
    }
    return strings.daysAgo(diff.inDays);
  }

  String cleanHomeName(String? value) {
    final name = value?.trim() ?? "";

    if (name.isEmpty || name.startsWith("home_")) return "";

    return name;
  }

  String displayHomeName(Map<String, dynamic> item) {
    final data = item["data"] is Map
        ? Map<String, dynamic>.from(item["data"] as Map)
        : <String, dynamic>{};
    final storedName = cleanHomeName(
      item["homeName"]?.toString() ?? data["homeName"]?.toString(),
    );

    if (storedName.isNotEmpty) return storedName;

    final homeId = item["homeId"]?.toString() ?? "";

    if (homeId.isEmpty || homeNameForId == null) return "";

    return cleanHomeName(homeNameForId(homeId));
  }

  String removeRepeatedHomeName(String text, String homeName) {
    var result = text.trim();
    final cleanName = homeName.trim();

    if (result.isEmpty || cleanName.isEmpty) {
      return result;
    }

    final escapedName = RegExp.escape(cleanName);

    // Xoá dạng: [Tên nhà] Tiêu đề
    result = result.replaceFirst(
      RegExp('^\\s*\\[$escapedName\\]\\s*', caseSensitive: false),
      '',
    );

    // Xoá các dạng:
    // trong "Tên nhà"
    // cho nhà "Tên nhà"
    // tại nhà "Tên nhà"
    // ở nhà "Tên nhà"
    result = result.replaceAll(
      RegExp(
        '\\s+(?:trong|cho\\s+nhà|tại\\s+nhà|ở\\s+nhà)'
        '\\s+["“”]?$escapedName["“”]?',
        caseSensitive: false,
      ),
      '',
    );

    result = result
        .replaceAll(RegExp(r'\s+([,.!?])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    return result;
  }

  String displayTitle(Map<String, dynamic> item, String homeName) {
    final rawTitle = item["title"]?.toString().trim() ?? "";
    final localizedItem = Map<String, dynamic>.from(item);

    if (rawTitle.isNotEmpty) {
      localizedItem["title"] = removeRepeatedHomeName(rawTitle, homeName);
    }

    return strings.notificationTitle(localizedItem, homeName: homeName);
  }

  String displayMessage(Map<String, dynamic> item, String homeName) {
    final rawMessage = item["message"]?.toString().trim() ?? "";
    final localizedItem = Map<String, dynamic>.from(item);

    if (rawMessage.isNotEmpty) {
      localizedItem["message"] = removeRepeatedHomeName(rawMessage, homeName);
    }

    return strings.notificationMessage(localizedItem, homeName: homeName);
  }

  IconData iconForType(String type) {
    switch (type) {
      case "home_created":
      case "home_renamed":
      case "home_deleted":
        return Icons.home_rounded;
      case "alarm_setting_changed":
        return Icons.crisis_alert_rounded;
      case "pair_started":
        return Icons.add_link_rounded;
      case "device_renamed":
      case "device_delete_requested":
        return Icons.sensors_rounded;
      case "device_added":
        return Icons.add_circle_rounded;
      case "device_delete_succeeded":
        return Icons.check_circle_rounded;
      case "device_delete_failed":
        return Icons.error_outline_rounded;
      case "alarm_resolved":
      case "emergency_resolved":
        return Icons.verified_user_rounded;
      case "alarm_pause_ended":
        return Icons.play_circle_fill_rounded;
      case "physical_siren_muted":
        return Icons.volume_off_rounded;
      case "security_mode_normal":
      case "auto_away_armed":
      case "auto_away_normal":
        return Icons.shield_rounded;
      case "system_hub_offline":
      case "system_hub_online":
        return Icons.router_rounded;
      case "system_mqtt_offline":
      case "system_mqtt_online":
        return Icons.wifi_tethering_rounded;
      case "system_device_offline":
        return Icons.wifi_off_rounded;
      case "system_device_online":
        return Icons.wifi_rounded;
      case "system_device_low_battery":
        return Icons.battery_alert_rounded;
      case "system_device_battery_ok":
        return Icons.battery_full_rounded;
      case "device_contact":
        return Icons.sensor_door_rounded;
      case "device_smoke":
      case "device_smoke_clear":
        return Icons.local_fire_department_rounded;
      case "device_sos":
      case "device_sos_clear":
        return Icons.sos_rounded;
      case "device_tamper":
      case "device_tamper_clear":
        return Icons.warning_amber_rounded;
      case "device_battery_low":
        return Icons.battery_alert_rounded;
      case "device_connection":
        return Icons.wifi_rounded;
      case "device_environment":
        return Icons.device_thermostat_rounded;
      case "security":
        return Icons.security_rounded;
      case "chat":
        return Icons.chat_bubble_rounded;
      case "share_request":
        return Icons.mail_rounded;
      case "member_join":
        return Icons.person_add_alt_1_rounded;
      case "member_leave":
        return Icons.logout_rounded;
      case "share_request_accepted":
        return Icons.check_circle_rounded;
      case "share_request_denied":
        return Icons.cancel_rounded;
      case "join_request":
        return Icons.person_add_rounded;
      case "join_request_accepted":
        return Icons.how_to_reg_rounded;
      case "transfer_owner_request":
        return Icons.admin_panel_settings_rounded;
      case "transfer_owner_accepted":
        return Icons.workspace_premium_rounded;
      case "member_role_changed":
      case "role_changed":
        return Icons.manage_accounts_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color colorForType(String type, String severity) {
    switch (severity) {
      case "critical":
        return Colors.red;
      case "warning":
        return Colors.orange;
      case "success":
        return Colors.green;
    }

    switch (type) {
      case "home_created":
      case "home_renamed":
        return Colors.teal;
      case "home_deleted":
        return Colors.red;
      case "alarm_setting_changed":
        return Colors.deepOrange;
      case "pair_started":
        return Colors.indigo;
      case "device_renamed":
      case "device_delete_requested":
        return Colors.blueGrey;
      case "device_added":
      case "system_device_online":
      case "system_device_battery_ok":
      case "system_hub_online":
      case "system_mqtt_online":
      case "alarm_resolved":
      case "emergency_resolved":
      case "alarm_pause_ended":
      case "security_mode_normal":
      case "auto_away_armed":
      case "auto_away_normal":
      case "device_delete_succeeded":
        return Colors.green;
      case "system_device_offline":
      case "system_device_low_battery":
      case "system_hub_offline":
      case "system_mqtt_offline":
      case "physical_siren_muted":
      case "device_delete_failed":
        return Colors.orange;
      case "chat":
        return Colors.green;
      case "share_request":
        return Colors.blue;
      case "share_request_accepted":
      case "member_join":
        return Colors.green;
      case "member_leave":
        return Colors.orange;
      case "share_request_denied":
        return Colors.red;
      case "join_request":
        return Colors.orange;
      case "join_request_accepted":
        return Colors.green;
      case "transfer_owner_request":
        return Colors.purple;
      case "transfer_owner_accepted":
        return Colors.deepPurple;
      case "member_role_changed":
      case "role_changed":
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      strings.notifications,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(strings.t("Xoá tất cả thông báo?")),
                            content: Text(
                              strings.t("Toàn bộ thông báo nhà sẽ bị xoá."),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(strings.t("Huỷ")),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(strings.t("Xoá")),
                              ),
                            ],
                          ),
                        );

                        if (ok == true) {
                          await HomeNotificationService.clearAll(uid: uid);

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref("accounts/$uid/notifications")
                      .orderByChild("time")
                      .limitToLast(20)
                      .onValue,
                  builder: (context, snapshot) {
                    final event = snapshot.data;

                    if (!snapshot.hasData || event?.snapshot.value == null) {
                      return Center(
                        child: Text(strings.t("Chưa có thông báo nào")),
                      );
                    }

                    final value = event?.snapshot.value;

                    if (value is! Map) {
                      return Center(
                        child: Text(strings.t("Chưa có thông báo nào")),
                      );
                    }

                    final raw = Map<String, dynamic>.from(value);

                    final items = raw.values
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList();

                    items.sort((a, b) {
                      final ta =
                          int.tryParse(a["time"]?.toString() ?? "0") ?? 0;
                      final tb =
                          int.tryParse(b["time"]?.toString() ?? "0") ?? 0;
                      return tb.compareTo(ta);
                    });

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final type = item["type"]?.toString() ?? "system";
                        final severity = item["severity"]?.toString() ?? "info";
                        final read = item["read"] == true;
                        final homeName = displayHomeName(item);
                        final timeText = formatTime(item["time"]);
                        final messageText = displayMessage(item, homeName);
                        final metaText =
                            homeName.isNotEmpty &&
                                !messageText.contains(homeName)
                            ? "$homeName • $timeText"
                            : timeText;
                        final subtitleText = messageText.isNotEmpty
                            ? "$messageText\n$metaText"
                            : metaText;

                        return Material(
                          color: read
                              ? Colors.grey.shade100
                              : Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: Icon(
                              iconForType(type),
                              color: read
                                  ? Colors.grey
                                  : colorForType(type, severity),
                            ),
                            title: Text(
                              displayTitle(item, homeName),
                              style: TextStyle(
                                fontWeight: read
                                    ? FontWeight.w500
                                    : FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(subtitleText),
                            isThreeLine: true,
                            onTap: () async {
                              final id = item["id"]?.toString() ?? "";

                              if (id.isNotEmpty) {
                                await FirebaseDatabase.instance
                                    .ref("accounts/$uid/notifications/$id/read")
                                    .set(true);
                              }

                              if (onTapNotification == null) return;

                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              await onTapNotification(item);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
