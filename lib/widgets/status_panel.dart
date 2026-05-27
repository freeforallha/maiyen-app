import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final Map<String, dynamic> overall;
  final VoidCallback? onPair;
  final VoidCallback? onQR;
  final String alarmStart;
  final String alarmEnd;

  final VoidCallback? onScheduleNotification;
  final VoidCallback? onScheduleAlarm;

  const StatusPanel({
    super.key,
    required this.overall,
    required this.onPair,
    required this.onQR,
    required this.alarmStart,
    required this.alarmEnd,
    this.onScheduleNotification,
    this.onScheduleAlarm,
  });

  void _showScheduleOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
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
                        overall["safe"] ? Icons.verified : Icons.warning,
                        color: overall["safe"] ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          overall["safe"] ? "ĐÃ AN TOÀN" : "CHƯA AN TOÀN",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: overall["safe"] ? Colors.green : Colors.red,
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
                        const Icon(
                          Icons.more_time_rounded,
                          size: 17,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          alarmEnd.isEmpty
                              ? alarmStart
                              : "$alarmStart - $alarmEnd",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
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
                      child: Icon(Icons.link),
                    ),
                  if (onPair != null && onQR != null) SizedBox(width: 8),
                  if (onQR != null)
                    FloatingActionButton.small(
                      heroTag: "qr",
                      onPressed: onQR,
                      child: Icon(Icons.qr_code_scanner),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}