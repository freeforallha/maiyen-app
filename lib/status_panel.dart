import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final Map<String, dynamic> overall;
  final VoidCallback onPair;
  final VoidCallback onQR;

  const StatusPanel({
    super.key,
    required this.overall,
    required this.onPair,
    required this.onQR,
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

                  if (!overall["safe"])
                    ...overall["issues"].map<Widget>(
                      (e) => Text(
                        "- $e",
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            Row(
              children: [
                FloatingActionButton.small(
                  heroTag: "pair",
                  onPressed: onPair,
                  child: Icon(Icons.link),
                ),

                SizedBox(width: 8),

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
