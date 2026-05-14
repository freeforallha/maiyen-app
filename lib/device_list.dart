import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  final Map<String, dynamic> devices;

  final bool isShared;
  final String ownerEmail;

  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;

  const DeviceList({
    super.key,
    required this.devices,

    required this.isShared,
    required this.ownerEmail,

    required this.onRename,
    required this.onDelete,
    required this.onTapDevice,
  });

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  String formatLastSeen(dynamic ts) {
    if (ts == null) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(targetDay).inDays;

    final time =
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}";

    if (diff == 0) {
      return "Hôm nay $time";
    } else if (diff == 1) {
      return "Hôm qua $time";
    } else {
      return "${dt.day.toString().padLeft(2, '0')}/"
          "${dt.month.toString().padLeft(2, '0')}";
    }
  }

  String formatLastSeenLabel(dynamic ts) {
    if (ts == null) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(ts.toString()) ?? 0,
    );

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(targetDay).inDays;

    if (diff == 0) {
      return "Hôm nay";
    } else if (diff == 1) {
      return "Hôm qua";
    } else {
      return "$diff ngày trước";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),

            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),

            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),

          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              children: [
                // ===== HEADER =====
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),

                  child: Row(
                    children: [
                      Icon(Icons.sensors, color: Colors.white70, size: 18),

                      SizedBox(width: 6),

                      Text(
                        "DEVICES",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),

                      if (isShared) ...[
                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            "(Chia sẻ bởi $ownerEmail)",
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ===== DEVICE LIST =====
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    children: devices.entries.map((e) {
                      final d = safeMap(e.value);
                      final lastSeen = d["last_seen_text"] ?? "--";
                      final lastSeenLabel = formatLastSeenLabel(d["last_seen"]);

                      return Container(
                        margin: EdgeInsets.all(2),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color:
                              (d["status"] != "closed" || d["tamper"] == true)
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                (d["status"] != "closed" || d["tamper"] == true)
                                ? Colors.red.shade300
                                : Colors.green.shade300,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => onTapDevice(e.key),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              // 👈 CĂN GIỮA
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ===== NAME =====
                                Spacer(),
                                Text(
                                  d["name"]?.toString() ?? e.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),

                                SizedBox(height: 6),
                                // ===== STATUS =====
                                Row(
                                  children: [
                                    Icon(
                                      d["status"] == "closed"
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 18,
                                      color: d["status"] == "closed"
                                          ? Colors.green
                                          : Colors.red,
                                    ),

                                    SizedBox(width: 4),

                                    Text(
                                      d["status"] == "closed" ? "Đóng" : "Mở",
                                      style: TextStyle(fontSize: 14),
                                    ),

                                    SizedBox(width: 12),

                                    Icon(
                                      d["tamper"] == true
                                          ? Icons.cancel
                                          : Icons.check_circle,
                                      size: 18,
                                      color: d["tamper"] == true
                                          ? Colors.red
                                          : Colors.green,
                                    ),

                                    SizedBox(width: 4),

                                    Text(
                                      d["tamper"] == true
                                          ? "Bị tháo"
                                          : "BT"
                                                "",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 4),

                                // ===== LAST UPDATE =====
                                Row(
                                  children: [
                                    Text(
                                      "Cập nhật:",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    SizedBox(width: 6),

                                    Text(
                                      lastSeenLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2),

                                Text(
                                  lastSeen,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
