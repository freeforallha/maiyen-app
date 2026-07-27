import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../localization/app_strings.dart';
import '../config/maiyen_identifiers.dart';

enum MaiYenQrScanMode { pairDevice, joinHome }

bool _isJoinHomeQr(String value) {
  return value.startsWith(MaiYenIdentifiers.joinHomeQrPrefix) ||
      value.startsWith(
        MaiYenIdentifiers.joinMultipleHomesQrPrefix,
      );
}

bool _looksLikeJoinHomeQr(String value) {
  return value.startsWith(
    MaiYenIdentifiers.joinHomeQrFamilyPrefix,
  );
}

Future<String?> openQRScanner(
  BuildContext context, {
  required MaiYenQrScanMode mode,
}) async {
  final controller = MobileScannerController();

  return Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => _QRScanPage(controller: controller, mode: mode),
    ),
  );
}

class _QRScanPage extends StatefulWidget {
  final MobileScannerController controller;
  final MaiYenQrScanMode mode;

  const _QRScanPage({required this.controller, required this.mode});

  @override
  State<_QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<_QRScanPage>
    with SingleTickerProviderStateMixin {
  late AnimationController scanController;
  bool scanned = false;
  String? scanError;

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

    final value = code.trim();
    final isJoinHomeQr = _isJoinHomeQr(value);
    final acceptsCode = switch (widget.mode) {
      MaiYenQrScanMode.joinHome => isJoinHomeQr,
      MaiYenQrScanMode.pairDevice => !_looksLikeJoinHomeQr(value),
    };

    if (!acceptsCode) {
      final strings = AppStrings.of(context);

      setState(() {
        scanError = widget.mode == MaiYenQrScanMode.joinHome
            ? strings.t("QR này không phải mã xin gia nhập nhà")
            : strings.t("QR này không phải mã thiết bị");
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      scanned = false;
      await widget.controller.start();
      return;
    }

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isJoinHome = widget.mode == MaiYenQrScanMode.joinHome;
    final title = isJoinHome
        ? strings.t("Quét QR xin gia nhập nhà")
        : strings.t("Quét QR để thêm thiết bị");
    final subtitle = isJoinHome
        ? strings.t("Đưa mã QR chia sẻ nhà vào khung hình")
        : strings.t("Đưa mã QR vào giữa khung");
    final helpText = isJoinHome
        ? strings.t("Mã QR này do chủ nhà chia sẻ")
        : null;

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
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                if (helpText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    helpText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
                if (scanError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    scanError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
