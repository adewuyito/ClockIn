import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/deliverable_submission.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/models/review_metadata.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/irys_storage_service.dart';
import '../../core/solana/network_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/celebration_badge.dart';

class ReleaseAndReviewModal extends ConsumerStatefulWidget {
  final EscrowContract contract;
  final String? initialDecryptionKey;
  final String? initialDecryptedContent;

  const ReleaseAndReviewModal({
    super.key,
    required this.contract,
    this.initialDecryptionKey,
    this.initialDecryptedContent,
  });

  static Future<bool?> show(
    BuildContext context,
    EscrowContract contract, {
    String? initialDecryptionKey,
    String? initialDecryptedContent,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReleaseAndReviewModal(
        contract: contract,
        initialDecryptionKey: initialDecryptionKey,
        initialDecryptedContent: initialDecryptedContent,
      ),
    );
  }

  @override
  ConsumerState<ReleaseAndReviewModal> createState() => _ReleaseAndReviewModalState();
}

class _ReleaseAndReviewModalState extends ConsumerState<ReleaseAndReviewModal> {
  int _selectedRating = 5;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _txSignature;
  String? _arweaveTxId;
  String? _submittedNote;
  String? _errorMessage;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _deliverableKeyController = TextEditingController();
  String? _decryptedDeliverable;
  bool _isDecryptingDeliverable = false;
  String? _deliverableDecryptError;

  final List<String> _ratingLabels = [
    '1 - Poor',
    '2 - Fair',
    '3 - Good',
    '4 - Very Good',
    '5 - Excellent',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDecryptedContent != null) {
      _decryptedDeliverable = widget.initialDecryptedContent;
    } else if (widget.initialDecryptionKey != null) {
      _deliverableKeyController.text = widget.initialDecryptionKey!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptDeliverableDecryption();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryAutoUnwrapDeliverable();
      });
    }
  }

  Future<void> _tryAutoUnwrapDeliverable() async {
    final sub = ref.read(latestDeliverableProvider(widget.contract.contractId)).asData?.value;
    if (sub == null || !sub.hasWrappedKey) return;

    final wallet = ref.read(walletStateProvider);
    if (!wallet.isConnected || wallet.address == null) return;

    setState(() {
      _isDecryptingDeliverable = true;
      _deliverableDecryptError = null;
    });

    try {
      final repo = ref.read(deliverableRepositoryProvider);
      final encryptionService = ref.read(deliverableEncryptionServiceProvider);

      final privateKey = await repo.getPrivateKey(wallet.address!);
      if (privateKey == null || privateKey.isEmpty) {
        if (mounted) setState(() => _isDecryptingDeliverable = false);
        return;
      }

      final symmetricKey = await encryptionService.unwrapKey(
        wrappedKeyJson: sub.wrappedKey!,
        recipientPrivateKeyBase64: privateKey,
      );

      if (mounted) {
        setState(() {
          _deliverableKeyController.text = symmetricKey;
        });
        _attemptDeliverableDecryption(sub);
      }
    } catch (e) {
      debugPrint('[ReleaseAndReviewModal] Auto-unwrap error: $e');
      if (mounted) {
        setState(() {
          _isDecryptingDeliverable = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _deliverableKeyController.dispose();
    super.dispose();
  }

  void _attemptDeliverableDecryption([DeliverableSubmission? submission]) {
    final key = _deliverableKeyController.text.trim();
    if (key.isEmpty) return;

    final sub = submission ??
        ref.read(latestDeliverableProvider(widget.contract.contractId)).asData?.value;
    if (sub == null) return;

    setState(() {
      _isDecryptingDeliverable = true;
      _deliverableDecryptError = null;
    });

    try {
      final repo = ref.read(deliverableRepositoryProvider);
      final plaintext = repo.decryptAndVerify(
        submission: sub,
        decryptionKey: key,
      );
      setState(() {
        _isDecryptingDeliverable = false;
        _decryptedDeliverable = plaintext;
      });
    } catch (_) {
      setState(() {
        _isDecryptingDeliverable = false;
        _deliverableDecryptError = 'Decryption failed. Please verify the key.';
      });
    }
  }

  Future<void> _handleRelease() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final wallet = ref.read(walletStateProvider);
      final walletAdapter = ref.read(walletAdapterProvider);
      final contractRepo = ref.read(contractRepositoryProvider);
      final irys = ref.read(irysStorageServiceProvider);

      if (!wallet.isConnected || wallet.publicKey == null) {
        throw Exception('Please connect your Solana wallet first.');
      }

      final noteText = _notesController.text.trim();

      // 1. Inscribe review note and contract settlement metadata to Arweave via Irys
      String? arweaveId;
      try {
        final metadata = ClockInReviewMetadata(
          jobId: widget.contract.contractId,
          contractId: widget.contract.contractId,
          worker: widget.contract.worker,
          reviewer: wallet.publicKey!.toBase58(),
          rating: _selectedRating,
          reviewNote: noteText.isNotEmpty
              ? noteText
              : 'Escrow payment released with $_selectedRating-star rating.',
          escrowSettled: true,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        arweaveId = await irys.uploadReviewMetadata(metadata);
      } catch (_) {
        // Fallback handled gracefully inside IrysStorageService
      }

      // 2. Execute on-chain Solana escrow settlement & review PDA minting
      final signature = await contractRepo.releaseAndReview(
        contractId: widget.contract.contractId,
        workerAddress: widget.contract.worker,
        rating: _selectedRating,
        employer: wallet.publicKey!,
        walletAdapter: walletAdapter,
        isToken: widget.contract.isToken,
        tokenMint: widget.contract.tokenMint,
        reviewNote: noteText.isNotEmpty ? noteText : null,
        arweaveTxId: arweaveId,
      );

      // 3. Mark deliverable as reviewed in Drift and Firebase if present
      final sub = ref.read(latestDeliverableProvider(widget.contract.contractId)).asData?.value;
      if (sub != null && sub.id != null) {
        await ref
            .read(deliverableRepositoryProvider)
            .updateStatus(sub.id!, DeliverableStatus.reviewed);
      }
      try {
        await ref.read(firebaseSyncServiceProvider).updateDeliverableStatus(
              widget.contract.contractId,
              DeliverableStatus.reviewed,
              workerAddress: widget.contract.worker,
            );
      } catch (_) {}

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _txSignature = signature;
        _arweaveTxId = arweaveId;
        _submittedNote = noteText.isNotEmpty ? noteText : null;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isSuccess ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    final deliverableAsync = ref.watch(latestDeliverableProvider(widget.contract.contractId));
    final submission = deliverableAsync.asData?.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Release & Review',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Settlement',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Release Callout
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                'RELEASING FROM ESCROW TO WORKER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.contract.formattedAmount,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.contract.isToken
                    ? 'Vault ATA → Worker ATA (${widget.contract.shortWorker})'
                    : 'To: ${widget.contract.shortWorker}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Submitted Deliverables Inspection Card
        if (submission != null) ...[
          const SizedBox(height: 14),
          _buildDeliverableCard(submission),
        ],

        const SizedBox(height: 20),

        // Rating Section
        Text(
          'Rate Worker Performance',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= _selectedRating;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRating = starIndex);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 38,
                  color: isFilled ? const Color(0xFFE5A100) : AppColors.outlineVariant,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _ratingLabels[_selectedRating - 1],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC97A0A),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Feedback Note (stored permanently on Arweave)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feedback Note (Optional)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              '${_notesController.text.length} / 280',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          maxLines: 2,
          maxLength: 280,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Excellent work, delivered on time and high quality.',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            counterText: '',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Inscribed permanently to Arweave permaweb via Irys & anchored on Solana.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Atomic settlement note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.contract.isToken
                ? const Color(0xFFF3EDF7)
                : AppColors.primaryContainer.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.contract.isToken
                  ? const Color(0xFF6750A4).withValues(alpha: 0.25)
                  : AppColors.primaryContainer.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on_rounded,
                    size: 18,
                    color: widget.contract.isToken
                        ? const Color(0xFF6750A4)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.contract.isToken
                        ? 'ATOMIC ${widget.contract.currencySymbol} SETTLEMENT (1 TX BLOCK)'
                        : 'ATOMIC ESCROW SETTLEMENT (1 TX BLOCK)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: widget.contract.isToken
                          ? const Color(0xFF6750A4)
                          : AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.contract.isToken) ...[
                _buildAtomicStep('1', '${widget.contract.formattedAmount} transfers from Vault ATA to Worker ATA'),
                const SizedBox(height: 5),
                _buildAtomicStep('2', 'Program closes Vault ATA and refunds rent lamports to you'),
                const SizedBox(height: 5),
                _buildAtomicStep('3', 'Immutable Review PDA is minted on Solana'),
                const SizedBox(height: 5),
                _buildAtomicStep('4', "Worker's aggregate reputation score increments"),
              ] else ...[
                _buildAtomicStep('1', '${widget.contract.formattedAmount} transfers from Vault PDA to Worker'),
                const SizedBox(height: 5),
                _buildAtomicStep('2', 'Vault PDA rent lamports automatically refund to you'),
                const SizedBox(height: 5),
                _buildAtomicStep('3', 'Immutable Review PDA is minted on Solana'),
                const SizedBox(height: 5),
                _buildAtomicStep('4', "Worker's aggregate reputation score increments"),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleRelease,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Release ${widget.contract.formattedAmount} & Submit Review',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        if (submission != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : () => _handleRequestRevision(submission),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.warning.withValues(alpha: 0.7)),
                foregroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(
                'Request Changes / Revisions',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeliverableCard(DeliverableSubmission submission) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _decryptedDeliverable != null
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _decryptedDeliverable != null
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _decryptedDeliverable != null
                    ? Icons.verified_rounded
                    : Icons.lock_outline_rounded,
                size: 16,
                color: _decryptedDeliverable != null
                    ? AppColors.success
                    : AppColors.primaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                _decryptedDeliverable != null
                    ? 'Decrypted & Integrity Verified'
                    : 'Worker Submitted Deliverables',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _decryptedDeliverable != null
                      ? AppColors.success
                      : AppColors.onSurface,
                ),
              ),
              const Spacer(),
              if (_decryptedDeliverable != null)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy Deliverable',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _decryptedDeliverable!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deliverables copied!')),
                    );
                  },
                ),
            ],
          ),
          if (submission.completionNote != null &&
              submission.completionNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Worker Note: ${submission.completionNote}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (_decryptedDeliverable != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                _decryptedDeliverable!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _deliverableKeyController,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11.5),
                      decoration: InputDecoration(
                        hintText: 'Decryption Key',
                        filled: true,
                        fillColor: AppColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isDecryptingDeliverable
                      ? null
                      : () => _attemptDeliverableDecryption(submission),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(
                    _isDecryptingDeliverable ? '...' : 'Decrypt',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (_deliverableDecryptError != null) ...[
              const SizedBox(height: 4),
              Text(
                _deliverableDecryptError!,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.error),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _handleRequestRevision(DeliverableSubmission submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Request Revisions?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Notify the worker that revisions are required before escrow release. The funds will remain locked in escrow.',
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

    if (confirmed == true && mounted && submission.id != null) {
      await ref
          .read(deliverableRepositoryProvider)
          .updateStatus(submission.id!, DeliverableStatus.revisionRequested);
      try {
        await ref.read(firebaseSyncServiceProvider).updateDeliverableStatus(
              widget.contract.contractId,
              DeliverableStatus.revisionRequested,
              submissionId: submission.id,
              workerAddress: widget.contract.worker,
            );
      } catch (_) {}
      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision requested from worker.')),
        );
      }
    }
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        const CelebrationBadge(
          icon: Icons.verified_rounded,
          color: AppColors.success,
          size: 76,
        ),
        const SizedBox(height: 16),
        Text(
          'Payment Released!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.contract.formattedAmount} was transferred to the worker and your $_selectedRating-star review was permanently anchored on Solana.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        if (_submittedNote != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'REVIEW FEEDBACK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _submittedNote!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_arweaveTxId != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARWEAVE PROVENANCE (IRYS)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _arweaveTxId!.length > 16
                            ? '${_arweaveTxId!.substring(0, 8)}…${_arweaveTxId!.substring(_arweaveTxId!.length - 8)}'
                            : _arweaveTxId!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.primary),
                  onPressed: () {
                    final link = 'https://gateway.irys.xyz/$_arweaveTxId';
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied Arweave permaweb link to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_txSignature != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSACTION SIGNATURE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _txSignature!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _txSignature!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied signature to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final url = NetworkConfig.solanaExplorerUrl('tx/$_txSignature');
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Explorer link copied to clipboard')),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(
              'Copy Solana Explorer Link',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtomicStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2, right: 8),
          decoration: BoxDecoration(
            color: widget.contract.isToken
                ? const Color(0xFF6750A4).withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: widget.contract.isToken
                    ? const Color(0xFF6750A4)
                    : AppColors.primary,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
