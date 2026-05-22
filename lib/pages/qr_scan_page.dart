import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> openQRScanner(BuildContext context) async {
  final controller = MobileScannerController();

  return Navigator.push<String>(
    context,

    MaterialPageRoute(builder: (_) => _QRScanPage(controller: controller)),
  );
}

class _QRScanPage extends StatefulWidget {
  final MobileScannerController controller;

  const _QRScanPage({required this.controller});

  @override
  State<_QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<_QRScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController scanController;

  @override
  void initState() {
    super.initState();

    scanController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    scanController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          MobileScanner(
            controller: widget.controller,

            onDetect: (capture) {
              final barcode = capture.barcodes.first;

              final code = barcode.rawValue;

              if (code == null) return;

              Navigator.pop(context, code);
            },
          ),

          // ================= DARK OVERLAY =================
          Container(color: Colors.black.withValues(alpha: 0.45)),

          // ================= SCAN AREA =================
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
                  // clear center
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.transparent,
                    ),
                  ),

                  // ================= SCAN LINE =================
                  AnimatedBuilder(
                    animation: scanController,

                    builder: (_, __) {
                      return Positioned(
                        top: 220 * scanController.value,

                        left: 12,
                        right: 12,

                        child: Container(
                          height: 3,

                          decoration: BoxDecoration(
                            color: Colors.greenAccent,

                            borderRadius: BorderRadius.circular(12),

                            boxShadow: [
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

          // ================= TEXT =================
          Positioned(
            bottom: 140,
            left: 24,
            right: 24,

            child: Column(
              children: [
                Text(
                  "Quét QR HUB",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  "Đưa mã QR vào giữa khung",
                  textAlign: TextAlign.center,

                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),

          // ================= CLOSE =================
          Positioned(
            top: 55,
            left: 12,

            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),

                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
