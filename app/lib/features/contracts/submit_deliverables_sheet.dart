import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../core/models/deliverable_submission.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';

/// Modal bottom sheet allowing a worker to privately submit encrypted deliverables
/// to the employer.
class SubmitDeliverablesSheet extends ConsumerStatefulWidget {
  final EscrowContract contract;

  const SubmitDeliverablesSheet({
    super.key,
    required this.contract,
  });

  static Future<bool?> show(BuildContext context, EscrowContract contract) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitDeliverablesSheet(contract: contract),
    );
  }

  @override
  ConsumerState<SubmitDeliverablesSheet> createState() =>
      _SubmitDeliverablesSheetState();
}

class _SubmitDeliverablesSheetState
    extends ConsumerState<SubmitDeliverablesSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  // State after successful submission:
  bool _submitted = false;
  String? _generatedKey;
  String? _plaintextHash;
  String? _arweaveTxId;
  String? _encryptedPayload;
  String? _iv;
  String? _authTag;
  String? _completionNote;
  String? _wrappedKey;

  @override
  void dispose() {
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final encryptionService = ref.read(deliverableEncryptionServiceProvider);
      final deliverableRepo = ref.read(deliverableRepositoryProvider);
      final wallet = ref.read(walletStateProvider);
      final syncService = ref.read(firebaseSyncServiceProvider);

      if (!wallet.isConnected || wallet.address == null) {
        throw Exception('Please connect your Solana wallet first.');
      }

      // Generate per-contract AES-256-GCM key
      final key = encryptionService.generateKey();

      // Wrap symmetric key for employer if employer published X25519 public key
      String? wrappedKey;
      try {
        final employerPubKey = await syncService.getUserPublicKey(widget.contract.employer);
        if (employerPubKey != null && employerPubKey.isNotEmpty) {
          wrappedKey = await encryptionService.wrapKey(
            base64Key: key,
            recipientPublicKeyBase64: employerPubKey,
          );
          debugPrint('[X25519] Wrapped symmetric key for employer ${widget.contract.employer}');
        } else {
          debugPrint('[X25519] Employer has not published public key yet, falling back to out-of-band');
        }
      } catch (e) {
        debugPrint('[X25519] Error wrapping key for employer: $e');
      }

      // Build payload JSON
      final primaryUrl = _urlController.text.trim();
      final notes = _notesController.text.trim();
      final payloadJson = primaryUrl.contains('\n') || notes.isNotEmpty
          ? 'URL: $primaryUrl\nNotes: $notes'
          : primaryUrl;

      // Submit and encrypt
      final submission = await deliverableRepo.submitDeliverable(
        contractId: widget.contract.contractId,
        submitterAddress: wallet.address!,
        plaintext: payloadJson,
        encryptionKey: key,
        completionNote: notes.isNotEmpty ? notes : null,
        wrappedKey: wrappedKey,
      );

      try {
        await syncService.publishDeliverableSubmission(
          DeliverableSubmission(
            contractId: widget.contract.contractId,
            submitterAddress: wallet.address!,
            encryptedPayload: submission.encryptedPayload,
            iv: submission.iv,
            authTag: submission.authTag,
            plaintextHash: submission.plaintextHash,
            completionNote: submission.completionNote,
            arweaveTxId: submission.arweaveTxId,
            wrappedKey: wrappedKey,
            status: DeliverableStatus.submitted,
            submittedAt: DateTime.now(),
          ),
          employerAddress: widget.contract.employer,
        );
      } catch (e) {
        debugPrint('[DeliverableSubmission] Sync to Firestore error: $e');
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
          _generatedKey = key;
          _plaintextHash = submission.plaintextHash;
          _arweaveTxId = submission.arweaveTxId;
          _encryptedPayload = submission.encryptedPayload;
          _iv = submission.iv;
          _authTag = submission.authTag;
          _completionNote = submission.completionNote;
          _wrappedKey = wrappedKey;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: SingleChildScrollView(
          child: _submitted ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Deliverables',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Contract ${widget.contract.shortId} • E2EE Protected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Security banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your work will be encrypted with AES-256-GCM before storage. Only the employer with your key can decrypt it. Zero public leakage.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Deliverable URL Input
          Text(
            'Deliverable Link or URL *',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _urlController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'https://github.com/... or Figma / Drive link',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please provide a link or URL to your deliverable';
              }
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Notes / Description Input
          Text(
            'Completion Notes (Optional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Summary of completed work, credentials, or instructions...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _isSubmitting
                    ? 'Encrypting & Submitting...'
                    : 'Encrypt & Submit Deliverables',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final uri = Uri(
      scheme: 'clockin',
      host: 'deliverable',
      path: '/${widget.contract.contractId}',
      queryParameters: {
        if (_encryptedPayload != null && _encryptedPayload!.isNotEmpty)
          'ct': _encryptedPayload!,
        if (_iv != null && _iv!.isNotEmpty) 'iv': _iv!,
        if (_authTag != null && _authTag!.isNotEmpty) 'tag': _authTag!,
        if (_plaintextHash != null && _plaintextHash!.isNotEmpty)
          'hash': _plaintextHash!,
        if (_completionNote != null && _completionNote!.isNotEmpty)
          'note': _completionNote!,
        if (_arweaveTxId != null && _arweaveTxId!.isNotEmpty)
          'tx': _arweaveTxId!,
      },
      fragment: 'key=$_generatedKey',
    );
    final keyUrl = uri.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Deliverables Submitted Privately!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _wrappedKey != null
              ? 'Encrypted with AES-256-GCM and sealed with Employer’s X25519 public key. Employer will decrypt automatically with zero interaction.'
              : 'Encrypted with AES-256-GCM. Share this key or QR code with your employer so they can decrypt your work.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),

        if (_wrappedKey != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    'Zero-Knowledge Envelope: Key safely relayed to employer via Firestore. Offline QR code is provided below as backup.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B5E36),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // QR Code for Key Exchange
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: 170,
            height: 170,
            child: PrettyQrView.data(
              data: keyUrl,
              errorCorrectLevel: QrErrorCorrectLevel.M,
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Decryption Key Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.key_rounded,
                  size: 16, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _generatedKey ?? '',
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
                  if (_generatedKey != null) {
                    Clipboard.setData(ClipboardData(text: _generatedKey!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Decryption key copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: keyUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Deliverable link copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.link_rounded, size: 16),
            label: Text(
              'Copy Deliverable Share Link',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        if (_plaintextHash != null) ...[
          const SizedBox(height: 8),
          Text(
            'Integrity Hash: ${_plaintextHash!.substring(0, 16)}…',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],

        if (_arweaveTxId != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_done_outlined,
                  size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Permanently uploaded to Arweave',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 18),

        // Done button
        SizedBox(
          width: double.infinity,
          height: 48,
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
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
