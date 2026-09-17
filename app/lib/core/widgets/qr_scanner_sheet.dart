import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';

/// Parsed outcome of a QR code scan.
class QrScanResult {
  final String raw;
  final String? solanaAddress;
  final double? amountSol;
  final String? contractId;

  const QrScanResult({
    required this.raw,
    this.solanaAddress,
    this.amountSol,
    this.contractId,
  });

  /// Extracts Solana addresses, Solana Pay URIs, or ClockIn contract IDs.
  static QrScanResult parse(String raw) {
    final trimmed = raw.trim();

    // 1. ClockIn deep links:
    // - contract: clockin://contract/<id> or clockin:contract:<id>
    // - worker profile: clockin://worker/<address> or clockin:worker:<address>
    if (trimmed.startsWith('clockin://contract/')) {
      final id = trimmed.substring('clockin://contract/'.length);
      return QrScanResult(raw: trimmed, contractId: id);
    }
    if (trimmed.startsWith('clockin:contract:')) {
      final id = trimmed.substring('clockin:contract:'.length);
      return QrScanResult(raw: trimmed, contractId: id);
    }
    if (trimmed.startsWith('clockin://worker/')) {
      final addr = trimmed.substring('clockin://worker/'.length);
      return QrScanResult(raw: trimmed, solanaAddress: addr);
    }
    if (trimmed.startsWith('clockin:worker:')) {
      final addr = trimmed.substring('clockin:worker:'.length);
      return QrScanResult(raw: trimmed, solanaAddress: addr);
    }

    // 2. Solana Pay URI: solana:<pubkey>?amount=1.5
    if (trimmed.startsWith('solana:')) {
      try {
        final uri = Uri.parse(trimmed);
        final address = uri.path;
        final amountStr = uri.queryParameters['amount'];
        final amount = amountStr != null ? double.tryParse(amountStr) : null;
        return QrScanResult(
          raw: trimmed,
          solanaAddress: address.isNotEmpty ? address : null,
          amountSol: amount,
        );
      } catch (_) {
        // Fall through
      }
    }

    // 3. Raw Solana base58 public key (32-44 base58 characters)
    final base58Regex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$');
    if (base58Regex.hasMatch(trimmed)) {
      return QrScanResult(raw: trimmed, solanaAddress: trimmed);
    }

    // 4. Fallback: treat as raw text
    return QrScanResult(raw: trimmed);
  }
}

/// A bottom sheet modal displaying a camera viewfinder for scanning QR codes.
class QrScannerSheet extends StatefulWidget {
  final String title;
  final String hintText;

  const QrScannerSheet({
    super.key,
    this.title = 'Scan Solana QR Code',
    this.hintText = 'Align QR code inside frame',
  });

  /// Opens the scanner modal and returns the [QrScanResult] if detected.
  static Future<QrScanResult?> show(
    BuildContext context, {
    String title = 'Scan Solana QR Code',
    String hintText = 'Align QR code inside frame',
  }) {
    return showModalBottomSheet<QrScanResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrScannerSheet(
        title: title,
        hintText: hintText,
      ),
    );
  }

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasDetected = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _hasDetected = true;
        HapticFeedback.mediumImpact();
        final result = QrScanResult.parse(rawValue);
        if (mounted) {
          Navigator.of(context).pop(result);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header with controls
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.hintText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        size: 20,
                        color: _isTorchOn ? AppColors.warning : AppColors.onSurfaceVariant,
                      ),
                      tooltip: 'Toggle flash',
                      onPressed: () async {
                        await _controller.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.flip_camera_ios_rounded, size: 20, color: AppColors.onSurfaceVariant),
                      tooltip: 'Switch camera',
                      onPressed: () => _controller.switchCamera(),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.onSurfaceVariant),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Camera Viewport with viewfinder overlay
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) {
                      return Container(
                        color: AppColors.surfaceContainerLow,
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_off_outlined,
                                size: 48,
                                color: AppColors.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Camera Access Required',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Allow camera permission or paste the address directly from your clipboard.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Viewfinder Target Cutout
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryContainer,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Corner accent indicators
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                  left: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                  right: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                  left: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                  right: BorderSide(color: AppColors.primaryFixedDim, width: 4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom scanning guide
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Supports Solana addresses & Solana Pay URIs',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
