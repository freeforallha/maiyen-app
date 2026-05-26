import 'package:flutter/material.dart';

class DeviceList extends StatelessWidget {
  final Map<String, dynamic> devices;

  final bool isShared;
  final String ownerEmail;
  final Widget? header;

  final Function(String) onRename;
  final Function(String) onDelete;
  final Function(String) onTapDevice;

  const DeviceList({
    this.header,
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

  bool isDeviceOnline(dynamic ts) {
    if (ts == null) return false;

    final value = int.tryParse(ts.toString());
    if (value == null || value <= 0) return false;

    final lastSeen = DateTime.fromMillisecondsSinceEpoch(value);
    final now = DateTime.now();

    return now.difference(lastSeen).inMinutes <= 120;
  }

  String formatAgo(dynamic ts) {
    if (ts == null) return "--";

    final value = int.tryParse(ts.toString());
    if (value == null || value <= 0) return "--";

    final dt = DateTime.fromMillisecondsSinceEpoch(value);
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return "Vừa xong";

    if (diff.inHours < 1) {
      return "${diff.inMinutes} phút trước";
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;

      if (m == 0) return "${h}h trước";
      return "${h}h${m}' trước";
    }

    return "${diff.inDays} ngày trước";
  }

  Widget _deviceCard({
    required BuildContext context,
    required String id,
    required Map<String, dynamic> d,
    required bool compact,
  }) {
    final isUnsafe = d["status"] != "closed" || d["tamper"] == true;
    final online = isDeviceOnline(d["last_seen"]);
    final eventAgo = formatAgo(d["last_event"]);

    final titleSize = compact ? 14.0 : 16.0;
    final textSize = compact ? 12.0 : 13.0;
    final smallTextSize = compact ? 10.5 : 12.0;
    final padding = compact ? 8.0 : 10.0;

    return Align(
      alignment: Alignment.topLeft,
      child: InkWell(
        onTap: () => onTapDevice(id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isUnsafe ? Colors.red.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnsafe ? Colors.red.shade300 : Colors.green.shade300,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d["name"]?.toString() ?? id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    d["status"] == "closed"
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: compact ? 15 : 16,
                    color: d["status"] == "closed" ? Colors.green : Colors.red,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    d["status"] == "closed" ? "Đóng" : "Mở",
                    style: TextStyle(fontSize: textSize),
                  ),

                  SizedBox(width: compact ? 10 : 14),

                  Icon(
                    d["tamper"] == true ? Icons.cancel : Icons.check_circle,
                    size: compact ? 15 : 16,
                    color: d["tamper"] == true ? Colors.red : Colors.green,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    d["tamper"] == true ? "Bị tháo" : "BT",
                    style: TextStyle(fontSize: textSize),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Text(
                    "Trạng thái:",
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: online ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Text(
                    online ? "Online" : "Offline",
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Text(
                    "Cập nhật:",
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      eventAgo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: smallTextSize,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (header != null) header!,

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 390;
                    final spacing = compact ? 10.0 : 16.0;
                    final itemWidth =
                        (constraints.maxWidth - spacing - 16) / 2;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: 10,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          children: devices.entries.map((entry) {
                            final d = safeMap(entry.value);

                            return SizedBox(
                              width: itemWidth,
                              child: _deviceCard(
                                context: context,
                                id: entry.key,
                                d: d,
                                compact: compact,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}