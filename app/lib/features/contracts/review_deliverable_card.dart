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
import 'release_and_review_modal.dart';
import 'submit_deliverables_sheet.dart';

/// Card widget displayed on [ContractDetailScreen] showing the latest
/// deliverable submission, encrypted status, and decryption workflow.
class ReviewDeliverableCard extends ConsumerStatefulWidget {
  final EscrowContract contract;
  final DeliverableSubmission submission;
  final bool isEmployer;
  final bool isWorker;
  final String? initialKey;
  final bool autoOpenReview;
  final ValueChanged<String>? onKeyDecrypted;

  const ReviewDeliverableCard({
    super.key,
    required this.contract,
    required this.submission,
    required this.isEmployer,
    required this.isWorker,
    this.initialKey,
    this.autoOpenReview = false,
    this.onKeyDecrypted,
  });

  @override
  ConsumerState<ReviewDeliverableCard> createState() =>
      _ReviewDeliverableCardState();
}

class _ReviewDeliverableCardState extends ConsumerState<ReviewDeliverableCard> {
  final _keyController = TextEditingController();
  bool _isDecrypting = false;
  bool _isAutoUnwrapped = false;
  bool _isAutoUnwrapping = false;
  String? _decryptedContent;
  String? _decryptError;

  @override
  void initState() {
    super.initState();
    if (widget.initialKey != null && widget.initialKey!.isNotEmpty) {
      _keyController.text = widget.initialKey!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDecrypt(autoReview: widget.autoOpenReview);
      });
    } else if (widget.submission.hasWrappedKey && widget.isEmployer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryAutoUnwrapAndDecrypt(autoReview: widget.autoOpenReview);
      });
    }
  }

  @override
  void didUpdateWidget(ReviewDeliverableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.submission != oldWidget.submission && _decryptedContent == null) {
      if (widget.initialKey != null && widget.initialKey!.isNotEmpty) {
        _keyController.text = widget.initialKey!;
        _handleDecrypt(autoReview: widget.autoOpenReview);
      } else if (widget.submission.hasWrappedKey && widget.isEmployer) {
        _tryAutoUnwrapAndDecrypt(autoReview: widget.autoOpenReview);
      }
    }
  }

  Future<void> _tryAutoUnwrapAndDecrypt({bool autoReview = false}) async {
    final wrappedKey = widget.submission.wrappedKey;
    if (wrappedKey == null || wrappedKey.isEmpty) return;

    final wallet = ref.read(walletStateProvider);
    if (!wallet.isConnected || wallet.address == null) return;

    setState(() {
      _isAutoUnwrapping = true;
      _decryptError = null;
    });

    try {
      final repo = ref.read(deliverableRepositoryProvider);
      final encryptionService = ref.read(deliverableEncryptionServiceProvider);

      final privateKey = await repo.getPrivateKey(wallet.address!);
      if (privateKey == null || privateKey.isEmpty) {
        debugPrint('[X25519] No local private key found for ${wallet.address}');
        if (mounted) setState(() => _isAutoUnwrapping = false);
        return;
      }

      final symmetricKey = await encryptionService.unwrapKey(
        wrappedKeyJson: wrappedKey,
        recipientPrivateKeyBase64: privateKey,
      );

      if (mounted) {
        setState(() {
          _keyController.text = symmetricKey;
          _isAutoUnwrapped = true;
          _isAutoUnwrapping = false;
        });
        widget.onKeyDecrypted?.call(symmetricKey);
        _handleDecrypt(autoReview: autoReview);
      }
    } catch (e) {
      debugPrint('[X25519] Auto-unwrap error: $e');
      if (mounted) {
        setState(() {
          _isAutoUnwrapping = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _handleDecrypt({bool autoReview = false}) {
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

      widget.onKeyDecrypted?.call(key);

      if (autoReview &&
          widget.isEmployer &&
          widget.contract.acceptsDeliverableActions &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openEmployerReviewSheet();
        });
      }
    } catch (e) {
      setState(() {
        _isDecrypting = false;
        _decryptError = 'Decryption failed. Please check the key.';
      });
    }
  }

  Future<void> _openEmployerReviewSheet() async {
    if (!widget.contract.acceptsDeliverableActions) return;
    final result = await ReleaseAndReviewModal.show(
      context,
      widget.contract,
      initialDecryptionKey: _keyController.text.trim().isNotEmpty
          ? _keyController.text.trim()
          : null,
      initialDecryptedContent: _decryptedContent,
    );
    if (result == true && mounted) {
      if (widget.submission.id != null) {
        await ref
            .read(deliverableRepositoryProvider)
            .updateStatus(widget.submission.id!, DeliverableStatus.reviewed);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escrow payment released and review completed!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleRequestRevision() async {
    if (!widget.contract.acceptsDeliverableActions) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Request Deliverable Revisions?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Notify the worker that revisions or additional deliverables are needed before escrow release.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Revisions'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && widget.submission.id != null) {
      await ref
          .read(deliverableRepositoryProvider)
          .updateStatus(widget.submission.id!, DeliverableStatus.revisionRequested);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Revision requested from worker.'),
          ),
        );
      }
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
              if (_isAutoUnwrapped || widget.submission.hasWrappedKey) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F9D5B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFF1F9D5B)),
                      const SizedBox(width: 3),
                      Text(
                        'X25519 Auto-Unwrapped',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B5E36),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
          if (widget.isEmployer && !widget.contract.acceptsDeliverableActions) ...[
            const SizedBox(height: 14),
            _buildActionsClosedNotice(),
          ],
          if (widget.isEmployer && widget.contract.acceptsDeliverableActions) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            // Primary Button: Accept Deliverables & Rate Worker -> Opens ReleaseAndReviewModal
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openEmployerReviewSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.verified_rounded, size: 18),
                label: Text(
                  'Accept Deliverables & Rate Worker',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Secondary Button: Request Changes
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: _handleRequestRevision,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.warning.withValues(alpha: 0.6)),
                  foregroundColor: AppColors.warning,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: Text(
                  'Request Changes / Revisions',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployerDecryptPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAutoUnwrapping) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Auto-unwrapping X25519 key envelope...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.submission.hasWrappedKey) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1F9D5B).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_person_rounded, size: 16, color: Color(0xFF1F9D5B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'X25519 key envelope ready.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B5E36),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _tryAutoUnwrapAndDecrypt(autoReview: widget.autoOpenReview),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0B5E36),
                  ),
                  child: const Text('Unwrap & Inspect'),
                ),
              ],
            ),
          ),
        ],
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
    final canRevise = widget.contract.acceptsDeliverableActions;
    final row = Row(
      children: [
        // Revisions only while the contract is active. Sharing the key stays
        // available: the employer may still need it to read the final work.
        if (canRevise) Expanded(
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
        if (canRevise) const SizedBox(width: 10),
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
    if (canRevise) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionsClosedNotice(),
        const SizedBox(height: 10),
        row,
      ],
    );
  }

  /// Explains why deliverable actions are gone, so a settled contract doesn't
  /// look like a broken screen.
  Widget _buildActionsClosedNotice() {
    final reason = widget.contract.deliverableActionsClosedReason ??
        'Deliverable actions are closed.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
