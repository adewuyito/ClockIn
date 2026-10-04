import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../core/models/deliverable_submission.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/qr_scanner_sheet.dart';
import 'submit_deliverables_sheet.dart';

/// Card widget displayed on [ContractDetailScreen] showing the latest
/// deliverable submission, encrypted status, and decryption workflow.
class ReviewDeliverableCard extends ConsumerStatefulWidget {
  final EscrowContract contract;
  final DeliverableSubmission submission;
  final bool isEmployer;
  final bool isWorker;

  const ReviewDeliverableCard({
    super.key,
    required this.contract,
    required this.submission,
    required this.isEmployer,
    required this.isWorker,
  });

  @override
  ConsumerState<ReviewDeliverableCard> createState() =>
      _ReviewDeliverableCardState();
}

class _ReviewDeliverableCardState extends ConsumerState<ReviewDeliverableCard> {
  final _keyController = TextEditingController();
  bool _isDecrypting = false;
  String? _decryptedContent;
  String? _decryptError;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _handleDecrypt() {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _decryptError = 'Please enter or scan the decryption key');
      return;
    }

    setState(() {
      _isDecrypting = true;
      _decryptError = null;
    });

    try {
      final repo = ref.read(deliverableRepositoryProvider);
      final plaintext = repo.decryptAndVerify(
        submission: widget.submission,
        decryptionKey: key,
      );

      setState(() {
        _isDecrypting = false;
        _decryptedContent = plaintext;
      });
    } catch (e) {
      setState(() {
        _isDecrypting = false;
        _decryptError = 'Decryption failed. Please check the key.';
      });
    }
  }

  Future<void> _scanKeyQr() async {
    final scanned = await QrScannerSheet.show(context);
    if (scanned != null && mounted) {
      final key = scanned.deliverableKey ??
          (scanned.raw.contains('#key=')
              ? scanned.raw.split('#key=').last
              : scanned.raw.trim());
      _keyController.text = key;
      _handleDecrypt();
    }
  }

  void _showWorkerKeySheet() {
    // Show worker the QR code & instructions to re-share key
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Deliverable Share Key',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this QR code with the employer so they can decrypt your deliverables.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 160,
                height: 160,
                child: PrettyQrView.data(
                  data:
                      'clockin://deliverable/${widget.contract.contractId}#worker',
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(color: Color(0xFF1E1E1E)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _decryptedContent != null
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _decryptedContent != null
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _decryptedContent != null
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    color: _decryptedContent != null
                        ? AppColors.success
                        : AppColors.primaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.isWorker
                                ? 'Your Deliverable'
                                : 'Worker Deliverables',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(),
                        ],
                      ),
                      Text(
                        'AES-256-GCM Encrypted',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion Note (if present)
                if (widget.submission.completionNote != null &&
                    widget.submission.completionNote!.isNotEmpty) ...[
                  Text(
                    'Worker Note:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.submission.completionNote!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Decrypted view or Decrypt action
                if (_decryptedContent != null)
                  _buildDecryptedView()
                else if (widget.isEmployer)
                  _buildEmployerDecryptPrompt()
                else
                  _buildWorkerInfoView(),

                // Metadata Footer
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.fingerprint_rounded,
                        size: 14, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'SHA-256: ${widget.submission.plaintextHash.substring(0, 16)}…',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (widget.submission.hasArweaveProvenance) ...[
                      const Icon(Icons.cloud_done_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Arweave',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = widget.submission.status;
    Color color;
    switch (status) {
      case DeliverableStatus.submitted:
        color = AppColors.primaryContainer;
        break;
      case DeliverableStatus.reviewed:
        color = AppColors.success;
        break;
      case DeliverableStatus.revisionRequested:
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDecryptedView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                'Decrypted & Integrity Verified',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Copy Deliverable Content',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _decryptedContent!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deliverable copied!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            _decryptedContent!,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployerDecryptPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter or scan the decryption key provided by the worker to access deliverables:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _keyController,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Decryption Key (Base64)',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primaryContainer),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _scanKeyQr,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              tooltip: 'Scan Key QR',
            ),
          ],
        ),
        if (_decryptError != null) ...[
          const SizedBox(height: 6),
          Text(
            _decryptError!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: _isDecrypting ? null : _handleDecrypt,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.key_rounded, size: 16),
            label: Text(
              _isDecrypting ? 'Decrypting...' : 'Decrypt & Verify Deliverables',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerInfoView() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => SubmitDeliverablesSheet.show(context, widget.contract),
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(
              'Submit Revision',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showWorkerKeySheet,
            icon: const Icon(Icons.qr_code_rounded, size: 16),
            label: Text(
              'Share Key QR',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
