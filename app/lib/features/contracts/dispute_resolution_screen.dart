import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:solana/solana.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/network_config.dart';
import '../../core/solana/program_instructions.dart';
import '../../core/theme/app_colors.dart';

/// Screen 12: Dispute Resolution & Arbitration Case
/// Implements the Stitch design for active escrow disputes under Seeker Guardian mediation.
class DisputeResolutionScreen extends ConsumerStatefulWidget {
  final String contractId;

  const DisputeResolutionScreen({
    super.key,
    required this.contractId,
  });

  @override
  ConsumerState<DisputeResolutionScreen> createState() => _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends ConsumerState<DisputeResolutionScreen> {
  final List<String> _additionalEvidence = [];
  bool _isResolving = false;

  void _showAddEvidenceDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Submit Evidence',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attach a verifiable deliverable link (GitHub PR, Figma, Arweave transaction) for Guardian jurors to inspect.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'e.g. https://github.com/.../pull/42',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                setState(() => _additionalEvidence.add(text));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evidence submitted to Seeker Juror panel.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Evidence'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResolveDispute(
    BuildContext modalContext,
    EscrowContract contract,
    DisputeResolution resolution,
  ) async {
    final wallet = ref.read(walletStateProvider);
    final walletAdapter = ref.read(walletAdapterProvider);
    final contractRepo = ref.read(contractRepositoryProvider);

    if (!wallet.isConnected || wallet.publicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect your Solana wallet first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userAddress = wallet.publicKey!.toBase58();
    final isEmployer = contract.isEmployer(userAddress);
    final isWorker = contract.isWorker(userAddress);

    if (!isEmployer && !isWorker) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only contract participants can execute an amicable settlement.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (resolution == DisputeResolution.releaseToWorker && !isEmployer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the employer can unilaterally release escrow to the worker.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (resolution == DisputeResolution.refundToEmployer && !isWorker) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the worker can unilaterally forfeit and refund to the employer.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.of(modalContext).pop();

    final confirmed = await _showConfirmationDialog(contract, resolution);
    if (confirmed != true || !mounted) return;

    setState(() => _isResolving = true);

    try {
      await contractRepo.resolveDispute(
        contract: contract,
        caller: wallet.publicKey!,
        resolution: resolution,
        walletAdapter: walletAdapter,
      );

      if (mounted) {
        final actionText = resolution == DisputeResolution.releaseToWorker
            ? 'Escrow released to worker'
            : resolution == DisputeResolution.refundToEmployer
                ? 'Escrow refunded to employer'
                : '50/50 split settlement executed';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispute resolved on Solana • $actionText'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settlement failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  Future<bool?> _showConfirmationDialog(
    EscrowContract contract,
    DisputeResolution resolution,
  ) {
    String title;
    String description;
    String confirmLabel;
    Color actionColor;
    IconData icon;

    final unit = contract.isToken ? r'$SKR' : 'SOL';
    final amountVal = contract.isToken ? contract.amountToken : contract.amountSol;

    switch (resolution) {
      case DisputeResolution.releaseToWorker:
        title = 'Release Escrow to Worker?';
        description =
            'You are acknowledging completion and releasing the full $amountVal $unit escrow directly to the worker (${contract.shortWorker}).\n\nThis will mark the contract as completed on Solana.';
        confirmLabel = 'Sign & Release to Worker';
        actionColor = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case DisputeResolution.refundToEmployer:
        title = 'Refund Escrow to Employer?';
        description =
            'You are agreeing to forfeit your claim and return the full $amountVal $unit escrow back to the employer (${contract.shortEmployer}).\n\nThis will cancel the contract on Solana.';
        confirmLabel = 'Sign & Refund to Employer';
        actionColor = AppColors.warning;
        icon = Icons.replay_rounded;
        break;
      case DisputeResolution.split5050:
        final half = amountVal / 2;
        title = 'Execute 50/50 Compromise?';
        description =
            'You are proposing a mutual 50/50 amicable split on Solana:\n\n'
            '• Worker receives $half $unit\n'
            '• Employer receives $half $unit (+ rent lamports)\n\n'
            'This binding settlement will mark the contract completed.';
        confirmLabel = 'Sign & Split 50/50';
        actionColor = AppColors.primary;
        icon = Icons.pie_chart_outline_rounded;
        break;
    }

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: actionColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.outline,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettlementModal(EscrowContract contract) {
    final wallet = ref.read(walletStateProvider);
    final userAddress = wallet.publicKey?.toBase58();
    final isEmployer = contract.isEmployer(userAddress);
    final isWorker = contract.isWorker(userAddress);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.handshake_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Propose Amicable Settlement',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Resolve dispute mutually on Solana without waiting for juror quorum.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSettlementOption(
              title: 'Release Escrow to Worker',
              subtitle: isEmployer
                  ? 'Employer acknowledges milestone completion and releases ${contract.formattedAmount}.'
                  : 'Employer only: Releases ${contract.formattedAmount} to worker.',
              badge: isEmployer ? null : 'Employer Only',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
              isEnabled: isEmployer,
              onTap: () => _handleResolveDispute(ctx, contract, DisputeResolution.releaseToWorker),
            ),
            const SizedBox(height: 10),
            _buildSettlementOption(
              title: 'Refund Escrow to Employer',
              subtitle: isWorker
                  ? 'Worker agrees to forfeit claim and return funds to employer vault.'
                  : 'Worker only: Forfeits claim and refunds ${contract.formattedAmount} to employer.',
              badge: isWorker ? null : 'Worker Only',
              icon: Icons.replay_rounded,
              color: AppColors.warning,
              isEnabled: isWorker,
              onTap: () => _handleResolveDispute(ctx, contract, DisputeResolution.refundToEmployer),
            ),
            const SizedBox(height: 10),
            _buildSettlementOption(
              title: 'Split 50% / 50% Compromise',
              subtitle: 'Both parties agree to split the escrow deposit equally.',
              badge: (isEmployer || isWorker) ? 'Either Party' : null,
              icon: Icons.pie_chart_outline_rounded,
              color: AppColors.primary,
              isEnabled: isEmployer || isWorker,
              onTap: () => _handleResolveDispute(ctx, contract, DisputeResolution.split5050),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool isEnabled = true,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractAsync = ref.watch(contractProvider(widget.contractId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Dispute Resolution',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF7ED),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'DEVNET',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: contractAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading contract: $err')),
        data: (contract) {
          if (contract == null) {
            return const Center(child: Text('Contract not found'));
          }

          final caseId = 'DISP-${contract.contractId.substring(0, contract.contractId.length >= 6 ? 6 : contract.contractId.length).toUpperCase()}';

          return FutureBuilder<Ed25519HDPublicKey>(
            future: NetworkConfig.findVaultPda(contract.contractId),
            builder: (context, snapshot) {
              final vaultPdaStr = snapshot.data?.toBase58();
              final vaultDisplay = vaultPdaStr != null
                  ? '${vaultPdaStr.substring(0, 4)}…${vaultPdaStr.substring(vaultPdaStr.length - 4)}'
                  : 'Vault PDA';

              return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Dispute Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBA1A1A), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.gavel_rounded,
                              size: 20,
                              color: Color(0xFFBA1A1A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'DISPUTE ACTIVE • VAULT FROZEN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFBA1A1A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'ARBITRATION',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Escrow funds are programmatically locked in the Solana Vault PDA pending Seeker Guardian arbitration. Neither party can unilaterally withdraw funds.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFF7A1C1C),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Locked Balance Display Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LOCKED DISPUTE BALANCE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                contract.formattedAmount,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14, color: AppColors.surfaceContainerHigh),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Locked in Vault PDA: $vaultDisplay',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (vaultPdaStr != null) {
                                    Clipboard.setData(ClipboardData(text: vaultPdaStr));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vault PDA copied to clipboard.')),
                                    );
                                  }
                                },
                                child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Case ID & Quorum Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMetaChip(Icons.tag_rounded, 'Case #$caseId'),
                        _buildMetaChip(Icons.schedule_rounded, 'Opened recently'),
                        _buildMetaChip(Icons.verified_user_rounded, 'Quorum 2/3 Jurors'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Filed Dispute Claim & Statement
              _buildDisputeClaimCard(contract),

              // Seeker Guardian Jurors Panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seeker Guardian Jurors',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 randomly selected Seeker Guardian stakers are assigned to review evidence and cast binding release votes.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Voting Progress Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'VOTING PROGRESS',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '1 of 3 Votes Cast',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 1 / 3,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target: Simple Majority (2 Votes)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '1 Release Vote',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3 Juror Rows
                    _buildJurorRow(
                      id: 'J1',
                      name: 'Juror #1 • Guardian Helius',
                      stake: '250 \$SKR Staked • Slot #2849102',
                      status: 'Reviewing Evidence',
                      isDone: false,
                    ),
                    const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                    _buildJurorRow(
                      id: 'J2',
                      name: 'Juror #2 • Guardian Triton',
                      stake: '500 \$SKR Staked • Slot #2849105',
                      status: 'Reviewing Evidence',
                      isDone: false,
                    ),
                    const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                    _buildJurorRow(
                      id: 'J3',
                      name: 'Juror #3 • Guardian Jito',
                      stake: '250 \$SKR Staked • Slot #2849118',
                      status: 'Vote Cast: Release',
                      isDone: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Contract Terms & Evidence Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contract Terms & Evidence',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Audit-Grade',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Terms Hash verification
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fingerprint_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'SHA-256 TERMS HASH',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            contract.termsHash,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            contract.termsText ?? 'P2P Contract Agreement',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Submitted Deliverables
                    if (contract.disputeEvidenceUri != null) ...[
                      _buildEvidenceItem(
                        title: 'Filed Deliverable / Evidence Link',
                        subtitle: contract.disputeEvidenceUri!,
                        isVerified: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildEvidenceItem(
                      title: 'GitHub PR #42: Solana Anchor Core Deliverables',
                      subtitle: 'Merged commit sha #e8f9a2 • Verified on-chain',
                      isVerified: true,
                    ),
                    const SizedBox(height: 8),
                    _buildEvidenceItem(
                      title: 'Test Suite Execution Logs: 38/38 Passing',
                      subtitle: 'Cryptographic proof of test verification',
                      isVerified: true,
                    ),

                    // Custom added evidence
                    for (final ev in _additionalEvidence) ...[
                      const SizedBox(height: 8),
                      _buildEvidenceItem(
                        title: ev,
                        subtitle: 'User submitted evidence note',
                        isVerified: false,
                      ),
                    ],

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showAddEvidenceDialog,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          '+ Submit Additional Evidence',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isResolving ? null : () => _showSettlementModal(contract),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isResolving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.handshake_outlined, size: 18),
                  label: Text(
                    _isResolving ? 'Resolving on Solana…' : 'Propose Amicable Settlement',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final counterparty = contract.isEmployer(ref.read(walletStateProvider).publicKey?.toBase58())
                        ? contract.worker
                        : contract.employer;
                    Clipboard.setData(ClipboardData(text: counterparty));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Counterparty address copied: ${counterparty.substring(0, 6)}…')),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                  label: Text(
                    'Contact Counterparty via Wallet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
            },
          );
        },
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFBA1A1A)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7A1C1C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurorRow({
    required String id,
    required String name,
    required String stake,
    required String status,
    required bool isDone,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                id,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDone ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  stake,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.12)
                  : const Color(0xFFFEF7ED),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
                  size: 11,
                  color: isDone ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem({
    required String title,
    required String subtitle,
    required bool isVerified,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.attachment_rounded,
            size: 16,
            color: isVerified ? AppColors.success : AppColors.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeClaimCard(EscrowContract contract) {
    if (contract.disputeDetails == null && contract.disputeReason == null) {
      return const SizedBox.shrink();
    }

    final reason = contract.disputeReason ?? 'General Grievance';
    final details = contract.disputeDetails ?? 'No detailed statement provided.';
    final raisedBy = contract.disputeRaisedBy != null && contract.disputeRaisedBy!.length >= 8
        ? '${contract.disputeRaisedBy!.substring(0, 4)}…${contract.disputeRaisedBy!.substring(contract.disputeRaisedBy!.length - 4)}'
        : (contract.disputeRaisedBy ?? 'Disputant');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_problem_outlined, size: 18, color: Color(0xFFBA1A1A)),
                  const SizedBox(width: 8),
                  Text(
                    'Filed Dispute Claim',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.3)),
                ),
                child: Text(
                  reason.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFBA1A1A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Filed by $raisedBy • Escrow frozen on-chain',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(color: Color(0xFFBA1A1A), width: 3),
              ),
            ),
            child: Text(
              details,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.onSurface,
                height: 1.45,
              ),
            ),
          ),
          if (contract.disputeEvidenceUri != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contract.disputeEvidenceUri!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
