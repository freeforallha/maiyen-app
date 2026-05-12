import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> openQRScanner(BuildContext context) async {
  return Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text("Scan QR")),

        body: MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.first;
            final code = barcode.rawValue;

            if (code == null) return;

            Navigator.pop(context, code);
          },
        ),
      ),
    ),
  );
}
