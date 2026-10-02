import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:solana/solana.dart';
import '../../core/database/attestation_repository.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/models/dispute_case.dart';
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
  bool _isInitializingPanel = false;
  bool _isCastingVote = false;
  bool _isExecutingRuling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      await Future.wait([
        ref.read(contractRepositoryProvider).refreshDisputeCase(widget.contractId),
        ref.read(contractRepositoryProvider).getContract(widget.contractId, forceRefresh: true),
      ]);
    } catch (_) {}
  }

  Future<void> _handleInitializePanel(EscrowContract contract) async {
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

    setState(() => _isInitializingPanel = true);

    try {
      final jurors = [
        Ed25519HDPublicKey.fromBase58('Ac4CjecDdASGmd3y4UPGXrutxEV9Prh5d4e1YS5bFhrm'),
        Ed25519HDPublicKey.fromBase58('AmSQZU4Qvuxu7eamHXEvyigqS9nhEm8AfkdTTmLJwZJu'),
        Ed25519HDPublicKey.fromBase58('DHFXmMhC4Dds57pkXjijYqFENBWPST4VfwtDSbZ13QjM'),
      ];

      // If connected wallet is a 3rd party (neither employer nor worker), assign them as Juror #1
      final userAddress = wallet.publicKey!.toBase58();
      if (!contract.isEmployer(userAddress) && !contract.isWorker(userAddress)) {
        jurors[0] = wallet.publicKey!;
      }

      final sig = await contractRepo.initializeDisputeCase(
        caller: wallet.publicKey!,
        contractId: contract.contractId,
        jurors: jurors,
        walletAdapter: walletAdapter,
      );

      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guardian Juror panel assembled! Tx: ${sig.substring(0, 8)}…'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assembling juror panel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitializingPanel = false);
    }
  }

  Future<void> _handleCastJurorVote(
    DisputeCase disputeCase,
    DisputeVote vote,
    Ed25519HDPublicKey jurorKey,
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

    final voteName = DisputeCase.voteDisplay(vote.value);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cast Juror Vote: $voteName?'),
        content: const Text(
          'As a Seeker Guardian Juror, your vote is binding on-chain. When 2 of 3 jurors agree, simple majority quorum is achieved and escrow is unlocked for release.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Sign Vote'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCastingVote = true);

    try {
      final sig = await contractRepo.castJurorVote(
        juror: jurorKey,
        contractId: disputeCase.contractId,
        vote: vote,
        walletAdapter: walletAdapter,
      );

      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Binding juror vote confirmed! Tx: ${sig.substring(0, 8)}…'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error casting juror vote: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCastingVote = false);
    }
  }

  Future<void> _handleExecuteRuling(
    EscrowContract contract,
    DisputeCase disputeCase,
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Execute Ruling: ${disputeCase.outcomeDisplay}?'),
        content: Text(
          'Quorum (2/3 majority) has been achieved on Solana.\n\nExecuting this transaction will transfer all escrow funds according to the binding ruling (${disputeCase.outcomeDisplay}) and close the vault account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Execute On-Chain Ruling'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isExecutingRuling = true);

    try {
      final sig = await contractRepo.executeDisputeRuling(
        contract: contract,
        caller: wallet.publicKey!,
        walletAdapter: walletAdapter,
      );

      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispute ruling executed on Solana! Tx: ${sig.substring(0, 8)}…'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error executing dispute ruling: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecutingRuling = false);
    }
  }

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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Sync dispute state from Solana',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing dispute state from Solana Devnet…'),
                  duration: Duration(seconds: 1),
                ),
              );
              await _refreshData();
            },
          ),
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
          final disputeCaseAsync = ref.watch(disputeCaseProvider(contract.contractId));
          final disputeCase = disputeCaseAsync.valueOrNull;

          return FutureBuilder<Ed25519HDPublicKey>(
            future: NetworkConfig.findVaultPda(contract.contractId),
            builder: (context, snapshot) {
              final vaultPdaStr = snapshot.data?.toBase58();
              final vaultDisplay = vaultPdaStr != null
                  ? '${vaultPdaStr.substring(0, 4)}…${vaultPdaStr.substring(vaultPdaStr.length - 4)}'
                  : 'Vault PDA';

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Dynamic Hero Dispute Banner
                    _buildDisputeHeroBanner(
                      contract: contract,
                      disputeCase: disputeCase,
                      vaultDisplay: vaultDisplay,
                      vaultPdaStr: vaultPdaStr,
                      caseId: caseId,
                    ),
                    const SizedBox(height: 14),

                    // User Role Explanation Card
                    _buildUserRoleCard(contract, disputeCase),
                    const SizedBox(height: 18),

                    // Filed Dispute Claim & Statement
                    _buildDisputeClaimCard(contract),

                    // Assemble Juror Panel CTA (if not yet assembled)
                    if (disputeCase == null) _buildAssembleJurorPanelCard(contract),

                    // Seeker Guardian Jurors Panel
                    _buildGuardianJurorsPanel(disputeCase, contract),
                    const SizedBox(height: 18),

                    // Juror Action & Quorum Execution Cards
                    if (disputeCase != null) ...[
                      _buildJurorActionCard(disputeCase),
                      if (disputeCase.status == DisputeCaseStatus.quorumReached)
                        _buildQuorumExecutionCard(contract, disputeCase),
                      if (disputeCase.status == DisputeCaseStatus.executed)
                        _buildRulingExecutedCard(disputeCase),
                    ],

                    // Contract Terms & Evidence Section
                    _buildTermsAndEvidenceSection(contract),
                    const SizedBox(height: 24),

                    // Action Buttons (Settlement & Contact)
                    if (disputeCase?.status != DisputeCaseStatus.executed) ...[
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
                            final userAddr = ref.read(walletStateProvider).publicKey?.toBase58();
                            final counterparty = contract.isEmployer(userAddr)
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDisputeHeroBanner({
    required EscrowContract contract,
    required DisputeCase? disputeCase,
    required String vaultDisplay,
    required String? vaultPdaStr,
    required String caseId,
  }) {
    final Color headerColor;
    final Color bgColor;
    final Color borderColor;
    final Color chipBg;
    final Color chipText;
    final String heroTitle;
    final String statusBadge;
    final String description;
    final IconData statusIcon;

    if (disputeCase == null) {
      headerColor = const Color(0xFFBA1A1A);
      bgColor = const Color(0xFFFDE8E8);
      borderColor = const Color(0xFFBA1A1A);
      chipBg = const Color(0xFFBA1A1A);
      chipText = Colors.white;
      heroTitle = 'DISPUTE ACTIVE • VAULT FROZEN';
      statusBadge = 'PANEL PENDING';
      description =
          'Escrow funds are programmatically locked in the Solana Vault PDA. Assemble a 3-juror Seeker Guardian panel on Devnet to begin evidence review and arbitration.';
      statusIcon = Icons.gavel_rounded;
    } else if (disputeCase.status == DisputeCaseStatus.voting) {
      headerColor = AppColors.primary;
      bgColor = AppColors.primaryContainer.withValues(alpha: 0.12);
      borderColor = AppColors.primary.withValues(alpha: 0.4);
      chipBg = AppColors.primary;
      chipText = Colors.white;
      heroTitle = 'ARBITRATION IN PROGRESS • 3 JURORS';
      statusBadge = '${disputeCase.votesCastCount}/3 VOTED';
      description =
          'Escrow funds are locked in the Solana Vault PDA pending Seeker Guardian arbitration. 3 Seeker Guardian Jurors have been cryptographically assigned on Solana Devnet to review deliverables and issue a binding ruling.';
      statusIcon = Icons.shield_rounded;
    } else if (disputeCase.status == DisputeCaseStatus.quorumReached) {
      headerColor = AppColors.success;
      bgColor = AppColors.successContainer.withValues(alpha: 0.2);
      borderColor = AppColors.success;
      chipBg = AppColors.success;
      chipText = Colors.white;
      heroTitle = 'QUORUM ACHIEVED • 2/3 MAJORITY';
      statusBadge = 'READY TO EXECUTE';
      description =
          'Seeker Guardian Jurors reached a 2/3 majority quorum (${disputeCase.outcomeDisplay}). Escrow funds can now be programmatically executed on Solana.';
      statusIcon = Icons.task_alt_rounded;
    } else {
      headerColor = AppColors.onSurface;
      bgColor = AppColors.surfaceContainerLowest;
      borderColor = AppColors.outlineVariant.withValues(alpha: 0.6);
      chipBg = AppColors.surfaceContainerHigh;
      chipText = AppColors.outline;
      heroTitle = 'RULING EXECUTED • FINALIZED';
      statusBadge = 'RESOLVED';
      description =
          'The dispute ruling (${disputeCase.outcomeDisplay}) has been executed on Solana Devnet. Escrow funds were programmatically released and the vault account is closed.';
      statusIcon = Icons.verified_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 20, color: headerColor),
                  const SizedBox(width: 8),
                  Text(
                    heroTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: headerColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusBadge,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: chipText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.onSurfaceVariant,
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
              border: Border.all(color: borderColor.withValues(alpha: 0.2)),
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

          // Metadata Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetaChip(Icons.tag_rounded, 'Case #$caseId', color: headerColor),
              _buildMetaChip(
                Icons.how_to_vote_rounded,
                disputeCase == null
                    ? 'Panel Pending'
                    : disputeCase.status == DisputeCaseStatus.voting
                        ? '${disputeCase.votesCastCount}/3 Votes Cast'
                        : disputeCase.status == DisputeCaseStatus.quorumReached
                            ? 'Quorum 2/3 Reached'
                            : 'Ruling Executed',
                color: headerColor,
              ),
              _buildMetaChip(Icons.verified_user_rounded, 'Quorum 2/3 Jurors', color: headerColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRoleCard(EscrowContract contract, DisputeCase? disputeCase) {
    final wallet = ref.watch(walletStateProvider);
    final userAddress = wallet.publicKey?.toBase58();

    final bool isEmployer = userAddress != null && contract.isEmployer(userAddress);
    final bool isWorker = userAddress != null && contract.isWorker(userAddress);
    final int jurorIndex = (userAddress != null && disputeCase != null)
        ? disputeCase.jurors.indexOf(userAddress)
        : -1;
    final bool isJuror = jurorIndex != -1;

    final String roleBadge;
    final String roleTitle;
    final String roleDescription;
    final IconData roleIcon;
    final Color roleColor;

    if (isEmployer) {
      roleBadge = 'YOU (EMPLOYER)';
      roleTitle = 'Employer Account';
      roleDescription =
          'You funded this contract and opened this dispute. Escrow funds are frozen in the Solana Vault PDA. You can propose an amicable settlement below or await the binding 2/3 Seeker Guardian verdict.';
      roleIcon = Icons.business_center_rounded;
      roleColor = const Color(0xFFBA1A1A);
    } else if (isWorker) {
      roleBadge = 'YOU (WORKER)';
      roleTitle = 'Worker Account';
      roleDescription =
          'An escrow dispute has been raised for this contract. Escrow funds are safely frozen on-chain. You can submit deliverables and evidence below for the Seeker Guardian jurors to review.';
      roleIcon = Icons.engineering_rounded;
      roleColor = const Color(0xFF0284C7);
    } else if (isJuror) {
      roleBadge = 'YOU (JUROR #${jurorIndex + 1})';
      roleTitle = 'Seeker Guardian Juror';
      roleDescription =
          'You have been randomly selected from active \$SKR stakers as Juror #${jurorIndex + 1}. Please review the submitted terms and evidence, then cast your binding cryptographic vote below.';
      roleIcon = Icons.shield_rounded;
      roleColor = AppColors.primary;
    } else {
      roleBadge = 'OBSERVER';
      roleTitle = 'Decentralized Audit Observer';
      roleDescription =
          'You are viewing this dispute as an independent observer. All contract terms, submitted evidence, and juror attestations are cryptographically verifiable on Solana Devnet.';
      roleIcon = Icons.visibility_rounded;
      roleColor = AppColors.outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(roleIcon, size: 18, color: roleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      roleTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleBadge,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  roleDescription,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndEvidenceSection(EscrowContract contract) {
    final hasEvidenceUri = contract.disputeEvidenceUri != null &&
        contract.disputeEvidenceUri!.trim().isNotEmpty;
    final hasAdditional = _additionalEvidence.isNotEmpty;

    return Container(
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

          // Real Submitted Deliverables
          if (hasEvidenceUri) ...[
            _buildEvidenceItem(
              title: 'Filed Deliverable / Evidence Link',
              subtitle: contract.disputeEvidenceUri!,
              isVerified: true,
            ),
          ],

          // Custom added evidence notes
          for (final ev in _additionalEvidence) ...[
            const SizedBox(height: 8),
            _buildEvidenceItem(
              title: ev,
              subtitle: 'User submitted evidence note',
              isVerified: true,
            ),
          ],

          if (!hasEvidenceUri && !hasAdditional) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No external deliverables filed yet. Use "+ Submit Additional Evidence" below to attach deliverables, pull requests, or evidence notes.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
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
    );
  }

  Widget _buildMetaChip(
    IconData icon,
    String text, {
    Color? color,
    Color? bg,
  }) {
    final chipColor = color ?? const Color(0xFFBA1A1A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianJurorItem({
    required int index,
    required String jurorAddress,
    required int vote,
  }) {
    final wallet = ref.watch(walletStateProvider);
    final userAddress = wallet.publicKey?.toBase58();
    final isCurrentUser = userAddress != null && userAddress == jurorAddress;

    final attestationAsync = ref.watch(seekerAttestationProvider(jurorAddress));
    final attestation = attestationAsync.valueOrNull;

    final knownNode = AttestationRepository.knownGuardianNodes[jurorAddress];
    final guardianName = attestation?.guardianName ??
        knownNode?.$1 ??
        (index == 0 ? 'Helius' : index == 1 ? 'Triton' : 'Jito');
    final stakedAmount = attestation?.stakedAmount ??
        knownNode?.$2 ??
        (index == 0 ? 500.0 : index == 1 ? 250.0 : 750.0);
    final isAttested = attestation?.isAttested ??
        (knownNode != null || stakedAmount >= AttestationRepository.minimumStakeThreshold);

    final Color badgeColor;
    final IconData shieldIcon;
    switch (guardianName.toLowerCase()) {
      case 'triton':
        badgeColor = const Color(0xFF0284C7);
        shieldIcon = Icons.shield_rounded;
        break;
      case 'jito':
        badgeColor = const Color(0xFF7C3AED);
        shieldIcon = Icons.bolt_rounded;
        break;
      case 'helius':
      default:
        badgeColor = const Color(0xFFE8590C);
        shieldIcon = Icons.shield_rounded;
        break;
    }

    final shortAddr = jurorAddress.length >= 8
        ? '${jurorAddress.substring(0, 4)}…${jurorAddress.substring(jurorAddress.length - 4)}'
        : jurorAddress;

    final String voteText;
    final IconData voteIcon;
    final Color voteColor;
    final Color voteBg;

    switch (vote) {
      case 1:
        voteText = 'Release to Worker';
        voteIcon = Icons.check_circle_rounded;
        voteColor = AppColors.success;
        voteBg = AppColors.successContainer.withValues(alpha: 0.15);
        break;
      case 2:
        voteText = 'Refund to Employer';
        voteIcon = Icons.replay_rounded;
        voteColor = AppColors.warning;
        voteBg = const Color(0xFFFEF7ED);
        break;
      case 3:
        voteText = 'Split 50% / 50%';
        voteIcon = Icons.pie_chart_outline_rounded;
        voteColor = AppColors.primary;
        voteBg = AppColors.primaryContainer.withValues(alpha: 0.15);
        break;
      case 0:
      default:
        voteText = 'Reviewing Evidence';
        voteIcon = Icons.schedule_rounded;
        voteColor = AppColors.outline;
        voteBg = AppColors.surfaceContainerHigh;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(shieldIcon, size: 18, color: badgeColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$guardianName Guardian Juror #${index + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'YOU (JUROR)',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          shortAddr,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: jurorAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Juror address copied: $shortAddr')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.copy_rounded, size: 12, color: AppColors.outline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: voteBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: voteColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(voteIcon, size: 12, color: voteColor),
                    const SizedBox(width: 4),
                    Text(
                      voteText,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: voteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 13,
                  color: isAttested ? badgeColor : AppColors.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isAttested
                        ? '${stakedAmount.toStringAsFixed(0)} \$SKR Staked • Seeker Proof-of-Human Verified'
                        : 'Unverified Staker • Awaiting Attestation',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stakedAmount >= 500
                        ? 'TIER 1 NODE'
                        : stakedAmount >= 250
                            ? 'TIER 2 NODE'
                            : 'COMMUNITY',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingJurorSlot(int slotNumber, String guardianLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$slotNumber',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Juror Slot #$slotNumber • $guardianLabel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Awaiting panel assembly on Solana Devnet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'PENDING',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.outline,
              ),
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

  Widget _buildAssembleJurorPanelCard(EscrowContract contract) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guardian Panel Not Yet Assembled',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Arbitration requires 3 active Seeker Guardian stakers.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Escrow is locked on Solana. Initialize a 3-juror Guardian panel on Devnet to review deliverables and issue a binding ruling.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isInitializingPanel ? null : () => _handleInitializePanel(contract),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isInitializingPanel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.how_to_reg_rounded, size: 18),
              label: Text(
                _isInitializingPanel ? 'Assembling Jurors on Solana…' : 'Assemble Seeker Juror Panel',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianJurorsPanel(DisputeCase? disputeCase, EscrowContract contract) {
    final votesCast = disputeCase?.votesCastCount ?? 0;
    final progress = votesCast / 3.0;

    return Container(
      width: double.infinity,
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
                  const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Seeker Guardian Jurors',
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
                  color: disputeCase != null && disputeCase.status == DisputeCaseStatus.quorumReached
                      ? AppColors.successContainer.withValues(alpha: 0.5)
                      : AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  disputeCase != null
                      ? '${disputeCase.votesCastCount}/3 VOTES'
                      : 'PANEL PENDING',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: disputeCase != null && disputeCase.status == DisputeCaseStatus.quorumReached
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            disputeCase == null
                ? '3 Guardian Jurors will be randomly selected from active \$SKR stakers upon panel assembly.'
                : '3 assigned Seeker Guardian stakers reviewing evidence. 2/3 majority required for quorum.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (disputeCase != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  disputeCase.status == DisputeCaseStatus.quorumReached ||
                          disputeCase.status == DisputeCaseStatus.executed
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              disputeCase.status == DisputeCaseStatus.quorumReached ||
                      disputeCase.status == DisputeCaseStatus.executed
                  ? 'Quorum reached (2/3 majority agrees on ${disputeCase.outcomeDisplay})'
                  : '$votesCast of 3 votes recorded • Need 2 matching votes for simple majority',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (disputeCase != null) ...[
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const Divider(height: 16, color: AppColors.surfaceContainerHigh),
              _buildGuardianJurorItem(
                index: i,
                jurorAddress: disputeCase.jurors[i],
                vote: disputeCase.votes[i],
              ),
            ],
          ] else ...[
            _buildPendingJurorSlot(1, 'Helius Guardian Node'),
            const Divider(height: 16, color: AppColors.surfaceContainerHigh),
            _buildPendingJurorSlot(2, 'Triton RPC Guardian'),
            const Divider(height: 16, color: AppColors.surfaceContainerHigh),
            _buildPendingJurorSlot(3, 'Jito MEV Guardian'),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simple Majority Quorum: When 2 out of 3 jurors vote for the same ruling, escrow is unlocked for execution.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurorActionCard(DisputeCase disputeCase) {
    final wallet = ref.watch(walletStateProvider);
    final userAddress = wallet.publicKey?.toBase58();
    if (userAddress == null) return const SizedBox.shrink();

    final jurorIndex = disputeCase.jurors.indexOf(userAddress);
    // If not a juror, or already executed, don't show voting actions
    if (jurorIndex == -1 || disputeCase.status == DisputeCaseStatus.executed) {
      return const SizedBox.shrink();
    }

    final hasVoted = disputeCase.hasVoted(jurorIndex);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'YOU ARE JUROR #${jurorIndex + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasVoted ? AppColors.success : const Color(0xFFFEF7ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasVoted ? 'VOTE RECORDED' : 'VOTE REQUIRED',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: hasVoted ? Colors.white : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasVoted) ...[
            Text(
              'Your binding vote (${DisputeCase.voteDisplay(disputeCase.votes[jurorIndex])}) has been cryptographically confirmed on Solana Devnet. Awaiting other jurors for quorum.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              'As an active Seeker Guardian staker, review the submitted deliverable evidence and contract hash above. Your vote is binding on-chain:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildJurorVoteButton(
              label: 'Vote: Release to Worker',
              color: AppColors.success,
              icon: Icons.check_circle_outline_rounded,
              onTap: _isCastingVote
                  ? null
                  : () => _handleCastJurorVote(
                        disputeCase,
                        DisputeVote.releaseToWorker,
                        wallet.publicKey!,
                      ),
            ),
            const SizedBox(height: 8),
            _buildJurorVoteButton(
              label: 'Vote: Refund to Employer',
              color: AppColors.warning,
              icon: Icons.replay_rounded,
              onTap: _isCastingVote
                  ? null
                  : () => _handleCastJurorVote(
                        disputeCase,
                        DisputeVote.refundToEmployer,
                        wallet.publicKey!,
                      ),
            ),
            const SizedBox(height: 8),
            _buildJurorVoteButton(
              label: 'Vote: Split 50% / 50%',
              color: AppColors.primary,
              icon: Icons.pie_chart_outline_rounded,
              onTap: _isCastingVote
                  ? null
                  : () => _handleCastJurorVote(
                        disputeCase,
                        DisputeVote.split5050,
                        wallet.publicKey!,
                      ),
            ),
            if (_isCastingVote) ...[
              const SizedBox(height: 10),
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Signing and broadcasting vote to Solana…'),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildJurorVoteButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildQuorumExecutionCard(EscrowContract contract, DisputeCase disputeCase) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'QUORUM ACHIEVED (2/3 MAJORITY)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'READY TO EXECUTE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BINDING JUROR VERDICT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  disputeCase.outcomeDisplay,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The Seeker Guardian Juror panel has completed arbitration. Any participant or juror can now execute this settlement on Solana to transfer escrow funds and close the vault account.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isExecutingRuling ? null : () => _handleExecuteRuling(contract, disputeCase),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isExecutingRuling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isExecutingRuling ? 'Executing Ruling on Solana…' : 'Execute On-Chain Ruling',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulingExecutedCard(DisputeCase disputeCase) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'DISPUTE RULING FINALIZED & EXECUTED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The dispute ruling (${disputeCase.outcomeDisplay}) has been executed on Solana Devnet. Escrow funds were programmatically released according to the Seeker Guardian 2/3 juror verdict and the vault account is closed.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
