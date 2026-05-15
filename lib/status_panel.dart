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
          color: overall["safe"] ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              overall["safe"] ? Icons.verified : Icons.warning,
              color: overall["safe"] ? Colors.green : Colors.red,
            ),

            SizedBox(width: 6),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overall["safe"]
                      ? "ĐÃ AN TOÀN"
                      : "CHƯA AN TOÀN - KIỂM TRA LẠI !",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: overall["safe"] ? Colors.green : Colors.red,
                  ),
                ),

                SizedBox(height: 2),

                // 👇 DÒNG MỚI: alarm nhỏ, không đậm
                Text(
                  "⏰ Báo động: $alarmStart - $alarmEnd",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
