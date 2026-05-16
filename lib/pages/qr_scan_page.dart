import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> openQRScanner(BuildContext context) async {
  final controller = MobileScannerController();

  return Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text("Scan QR"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
          ),
        ),

        body: MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final barcode = capture.barcodes.first;
            final code = barcode.rawValue;

            if (code == null) return;

            controller.dispose(); // 🔥 quan trọng
            Navigator.pop(context, code);
          },
        ),
      ),
    ),
  );
}
