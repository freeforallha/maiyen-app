import 'package:flutter/material.dart';

void showDeviceMenuSheet({
  required BuildContext context,
  required String deviceId,
  required Map d,
  required VoidCallback onRename,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,

    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),

    builder: (_) {
      final status = d["status"]?.toString();
      final tamper = d["tamper"] == true;

      return Padding(
        padding: EdgeInsets.all(16),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text(
              d["name"] ?? deviceId,

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  status == "closed" ? Icons.check_circle : Icons.cancel,

                  color: status == "closed" ? Colors.green : Colors.red,
                ),

                SizedBox(width: 6),

                Text(status == "closed" ? "Đang Đóng" : "Đang Mở"),
              ],
            ),

            SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Icon(
                  tamper ? Icons.warning : Icons.verified,

                  color: tamper ? Colors.red : Colors.green,
                ),

                SizedBox(width: 6),

                Text(tamper ? "Bị tháo" : "Bình thường"),
              ],
            ),

            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRename();
                  },

                  icon: Icon(Icons.edit),

                  label: Text("Rename"),
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },

                  icon: Icon(Icons.delete),

                  label: Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
