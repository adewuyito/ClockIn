import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../theme/app_colors.dart';

/// Reusable widget displaying an AES-256-GCM deliverable decryption key
/// as both a formatted QR code and a copyable string.
class DeliverableKeyQr extends StatelessWidget {
  final String contractId;
  final String decryptionKey;
  final String? plaintextHash;
  final String? encryptedPayload;
  final String? iv;
  final String? authTag;
  final String? completionNote;
  final String? arweaveTxId;
  final double qrSize;

  const DeliverableKeyQr({
    super.key,
    required this.contractId,
    required this.decryptionKey,
    this.plaintextHash,
    this.encryptedPayload,
    this.iv,
    this.authTag,
    this.completionNote,
    this.arweaveTxId,
    this.qrSize = 160,
  });

  /// Deep link URL containing payload parameters and key in URL fragment (#key=...)
  /// URL fragments are never sent to web servers or stored in access logs.
  String get deepLinkUrl {
    final query = <String, String>{
      if (encryptedPayload != null && encryptedPayload!.isNotEmpty) 'ct': encryptedPayload!,
      if (iv != null && iv!.isNotEmpty) 'iv': iv!,
      if (authTag != null && authTag!.isNotEmpty) 'tag': authTag!,
      if (plaintextHash != null && plaintextHash!.isNotEmpty) 'hash': plaintextHash!,
      if (completionNote != null && completionNote!.isNotEmpty) 'note': completionNote!,
      if (arweaveTxId != null && arweaveTxId!.isNotEmpty) 'tx': arweaveTxId!,
    };
    final uri = Uri(
      scheme: 'clockin',
      host: 'deliverable',
      path: '/$contractId',
      queryParameters: query.isNotEmpty ? query : null,
      fragment: 'key=$decryptionKey',
    );
    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR Container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: qrSize,
            height: qrSize,
            child: PrettyQrView.data(
              data: deepLinkUrl,
              errorCorrectLevel: QrErrorCorrectLevel.M,
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(color: Color(0xFF1B1B1F)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Key display & copy button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.key_rounded, size: 16, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  decryptionKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Copy Key',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: decryptionKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Decryption key copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        if (plaintextHash != null) ...[
          const SizedBox(height: 6),
          Text(
            'SHA-256: ${plaintextHash!.substring(0, 16)}…',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
