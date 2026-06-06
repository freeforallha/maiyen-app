import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final Map<String, dynamic> overall;
  final VoidCallback? onPair;
  final VoidCallback? onQR;
  final String alarmStart;
  final String alarmEnd;
  final String environmentText;
  final VoidCallback? onEnvironmentTap;

  final bool alarmEnabled;
  final ValueChanged<bool>? onAlarmEnabledChanged;

  final VoidCallback? onScheduleNotification;
  final VoidCallback? onScheduleAlarm;

  const StatusPanel({
    super.key,
    required this.overall,
    required this.onPair,
    required this.onQR,
    required this.alarmStart,
    required this.alarmEnd,
    required this.environmentText,
    this.onEnvironmentTap,
    this.alarmEnabled = true,
    this.onAlarmEnabledChanged,
    this.onScheduleNotification,
    this.onScheduleAlarm,
  });

  void _showScheduleOptions(BuildContext context) {
    bool localAlarmEnabled = alarmEnabled;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: localAlarmEnabled,
                      activeThumbColor: Colors.red,
                      secondary: const Icon(
                        Icons.crisis_alert_rounded,
                        color: Colors.red,
                      ),
                      title: const Text(
                        "Nhận cảnh báo Alarm",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        "Bật/tắt alarm cho tài khoản này trong nhà hiện tại",
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          localAlarmEnabled = value;
                        });

                        onAlarmEnabledChanged?.call(value);
                      },
                    ),

                    const Divider(),

                    ListTile(
                      leading: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.orange,
                      ),
                      title: const Text("Hẹn giờ Notification"),
                      onTap: () {
                        Navigator.pop(context);
                        onScheduleNotification?.call();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.shield_moon_rounded,
                        color: Colors.deepPurple,
                      ),
                      title: const Text("Hẹn giờ Alarm"),
                      onTap: () {
                        Navigator.pop(context);
                        onScheduleAlarm?.call();
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

  @override
  Widget build(BuildContext context) {
    final alarmText = alarmEnabled ? "Alarm đang bật" : "Alarm đã tắt";
    final level = overall["level"]?.toString() ?? "safe";

    final statusColor = level == "danger"
        ? Colors.red
        : level == "warning"
        ? Colors.orange
        : Colors.green;

    final statusText = level == "danger"
        ? "CHƯA AN TOÀN"
        : level == "warning"
        ? "CẦN CHÚ Ý"
        : "ĐÃ AN TOÀN";

    final statusIcon = level == "danger"
        ? Icons.warning_rounded
        : level == "warning"
        ? Icons.info_rounded
        : Icons.verified_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
      ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("🏡", style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          statusText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: statusColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onEnvironmentTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.thermostat_rounded,
                                color: Colors.blue,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                environmentText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  InkWell(
                    onTap: () => _showScheduleOptions(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alarmEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          size: 17,
                          color: alarmEnabled ? Colors.deepPurple : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "$alarmText • ${alarmEnd.isEmpty ? alarmStart : "$alarmStart - $alarmEnd"}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (onPair != null || onQR != null)
              Row(
                children: [
                  if (onPair != null)
                    FloatingActionButton.small(
                      heroTag: "pair",
                      onPressed: onPair,
                      child: const Icon(Icons.link),
                    ),
                  if (onPair != null && onQR != null)
                    const SizedBox(width: 8),
                  if (onQR != null)
                    FloatingActionButton.small(
                      heroTag: "qr",
                      onPressed: onQR,
                      child: const Icon(Icons.qr_code_scanner),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}