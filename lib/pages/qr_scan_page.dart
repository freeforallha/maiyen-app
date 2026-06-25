import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> openQRScanner(
  BuildContext context, {
  String title = "Quét QR HUB",
  String subtitle = "Đưa mã QR vào giữa khung",
}) async {
  final controller = MobileScannerController();

  return Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          _QRScanPage(controller: controller, title: title, subtitle: subtitle),
    ),
  );
}

class _QRScanPage extends StatefulWidget {
  final MobileScannerController controller;
  final String title;
  final String subtitle;

  const _QRScanPage({
    required this.controller,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<_QRScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController scanController;
  bool scanned = false;

  @override
  void initState() {
    super.initState();

    scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    scanController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> handleDetect(BarcodeCapture capture) async {
    if (scanned) return;

    final code = capture.barcodes.firstOrNull?.rawValue;

    if (code == null || code.trim().isEmpty) return;

    scanned = true;

    await widget.controller.stop();

    if (!mounted) return;

    Navigator.pop(context, code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: widget.controller, onDetect: handleDetect),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: scanController,
                    builder: (_, _) {
                      return Positioned(
                        top: 220 * scanController.value,
                        left: 12,
                        right: 12,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 12,
                                color: Colors.greenAccent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          Positioned(
            top: 55,
            left: 12,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
