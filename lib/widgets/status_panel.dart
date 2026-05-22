import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final Map<String, dynamic> overall;
  final VoidCallback? onPair;
  final VoidCallback? onQR;
  final String alarmStart;
  final String alarmEnd;

  const StatusPanel({
    super.key,
    required this.overall,
    required this.onPair,
    required this.onQR,
    required this.alarmStart,
    required this.alarmEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
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
                      Icon(
                        overall["safe"] ? Icons.verified : Icons.warning,
                        color: overall["safe"] ? Colors.green : Colors.red,
                      ),

                      SizedBox(width: 6),

                      Text(
                        overall["safe"] ? "ĐÃ AN TOÀN" : "CHƯA AN TOÀN",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: overall["safe"] ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Alarm: $alarmStart - $alarmEnd",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
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
