import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  final Map<String, dynamic> devices;
  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;

  const DeviceList({
    super.key,
    required this.devices,
    required this.onRename,
    required this.onDelete,
    required this.onTapDevice,
  });

  Map<String, dynamic> safeMap(dynamic data) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                  ],
                ),
              ),

              // ===== DEVICE LIST =====
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 2.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  children: devices.entries.map((e) {
                    final d = safeMap(e.value);

                    return Container(
                      margin: EdgeInsets.all(2),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),

                      decoration: BoxDecoration(
                        color: (d["status"] != "closed" || d["tamper"] == true)
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
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            // 👈 CĂN GIỮA
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== NAME =====
                              Text(
                                d["name"]?.toString() ?? e.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15, // 👈 giảm lại cho gọn
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 6),

                              // ===== STATUS 1 =====
                              Row(
                                children: [
                                  Icon(
                                    d["status"] == "closed"
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 12,
                                    color: d["status"] == "closed"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    d["status"] == "closed" ? "Đóng" : "Mở",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4),

                              // ===== STATUS 2 =====
                              Row(
                                children: [
                                  Icon(
                                    d["tamper"] == true
                                        ? Icons.cancel
                                        : Icons.check_circle,
                                    size: 12,
                                    color: d["tamper"] == true
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    d["tamper"] == true ? "Tháo" : "OK",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
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
    );
  }
}
