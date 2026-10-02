import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import 'dispute_resolution_screen.dart';

/// Modal bottom sheet allowing an employer or worker to file a structured dispute
/// with mandatory detailed explanation, category selection, and evidence link
/// before signing the on-chain freeze transaction via MWA.
class RaiseDisputeSheet extends ConsumerStatefulWidget {
  final EscrowContract contract;

  const RaiseDisputeSheet({
    super.key,
    required this.contract,
  });

  static Future<bool?> show(BuildContext context, EscrowContract contract) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RaiseDisputeSheet(contract: contract),
    );
  }

  @override
  ConsumerState<RaiseDisputeSheet> createState() => _RaiseDisputeSheetState();
}

class _RaiseDisputeSheetState extends ConsumerState<RaiseDisputeSheet> {
  final _detailsController = TextEditingController();
  final _evidenceController = TextEditingController();

  static const List<String> _categories = [
    'Incomplete Work',
    'Quality Deficient',
    'Missed Deadline',
    'Scope Violation',
    'Unresponsive',
    'Other',
  ];

  String _selectedCategory = _categories.first;
  bool _acknowledged = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _detailsController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final details = _detailsController.text.trim();
    return details.length >= 20 && _acknowledged && !_isSubmitting;
  }

  Future<void> _submitDispute() async {
    if (!_isValid) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final wallet = ref.read(walletStateProvider);
      final walletAdapter = ref.read(walletAdapterProvider);
      final contractRepo = ref.read(contractRepositoryProvider);

      if (!wallet.isConnected || wallet.publicKey == null) {
        throw Exception('Please connect your Solana wallet.');
      }

      final evidenceText = _evidenceController.text.trim();

      await contractRepo.raiseDispute(
        contractId: widget.contract.contractId,
        caller: wallet.publicKey!,
        walletAdapter: walletAdapter,
        disputeReason: _selectedCategory,
        disputeDetails: _detailsController.text.trim(),
        disputeEvidenceUri: evidenceText.isNotEmpty ? evidenceText : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispute filed on Solana • Escrow vault frozen'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DisputeResolutionScreen(
              contractId: widget.contract.contractId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final detailsLength = _detailsController.text.trim().length;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag pill
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

                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: Color(0xFFBA1A1A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open Dispute & Freeze Vault',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${widget.contract.formattedAmount} • Contract #${widget.contract.shortId}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLow,
                        foregroundColor: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Critical Notice Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBA1A1A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: Color(0xFFBA1A1A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Freezes funds in the Solana Vault PDA. Seeker Guardian jurors will review this filed statement and evidence.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF7A1C1C),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Section 1: Dispute Reason Category
                Text(
                  '1. Dispute Category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return InkWell(
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFBA1A1A)
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFBA1A1A)
                                : AppColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Section 2: Detailed Explanation (Mandatory)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '2. Detailed Statement *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '$detailsLength chars (min 20)',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: detailsLength >= 20
                            ? AppColors.success
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _detailsController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText:
                        'Detail specifically what was agreed upon vs what occurred. Include relevant deliverable issues, timeline notes, or unfulfilled promises...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.outline,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 18),

                // Section 3: Deliverable / Evidence Link
                Text(
                  '3. Primary Deliverable / Evidence URL (Recommended)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _evidenceController,
                  enabled: !_isSubmitting,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'https://github.com/.../pull/42 or Figma / Arweave link',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.outline,
                    ),
                    prefixIcon: const Icon(
                      Icons.link_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 4: Acknowledgment Checkbox
                InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() => _acknowledged = !_acknowledged),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acknowledged,
                          onChanged: _isSubmitting
                              ? null
                              : (val) => setState(() => _acknowledged = val ?? false),
                          activeColor: const Color(0xFFBA1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'I confirm this dispute is filed in good faith. Frivolous disputes may negatively affect my Seeker Guardian Attestation.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error message banner if any
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFFBA1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isValid ? _submitDispute : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.outline,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.gavel_rounded, size: 20),
                    label: Text(
                      _isSubmitting
                          ? 'Broadcasting to Solana Devnet...'
                          : 'Sign & Freeze Vault on Solana',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
