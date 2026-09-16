import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import 'contract_share_screen.dart';
import 'release_and_review_modal.dart';

class ContractDetailScreen extends ConsumerStatefulWidget {
  final String contractId;

  const ContractDetailScreen({
    super.key,
    required this.contractId,
  });

  @override
  ConsumerState<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  bool _isActionLoading = false;
  String? _actionError;

  Future<void> _handleAccept(EscrowContract contract) async {
    setState(() {
      _isActionLoading = true;
      _actionError = null;
    });

    try {
      final wallet = ref.read(walletStateProvider);
      final walletAdapter = ref.read(walletAdapterProvider);
      final contractRepo = ref.read(contractRepositoryProvider);

      if (!wallet.isConnected || wallet.publicKey == null) {
        throw Exception('Please connect your Solana wallet.');
      }

      await contractRepo.acceptContract(
        contractId: contract.contractId,
        worker: wallet.publicKey!,
        walletAdapter: walletAdapter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract accepted! Status updated to In Progress.')),
        );
      }
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleCancel(EscrowContract contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Contract?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this contract? 100% of the locked SOL in the vault will be refunded back to your employer wallet.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Contract'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel & Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isActionLoading = true;
      _actionError = null;
    });

    try {
      final wallet = ref.read(walletStateProvider);
      final walletAdapter = ref.read(walletAdapterProvider);
      final contractRepo = ref.read(contractRepositoryProvider);

      if (!wallet.isConnected || wallet.publicKey == null) {
        throw Exception('Please connect your Solana wallet.');
      }

      await contractRepo.cancelContract(
        contractId: contract.contractId,
        employer: wallet.publicKey!,
        walletAdapter: walletAdapter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contract cancelled. Funds returned to your wallet.')),
        );
      }
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleDispute(EscrowContract contract) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Raise Dispute?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Raising a dispute marks this contract as Disputed on Solana. Vault funds will remain locked until resolved.',
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
            child: const Text('Raise Dispute'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isActionLoading = true;
      _actionError = null;
    });

    try {
      final wallet = ref.read(walletStateProvider);
      final walletAdapter = ref.read(walletAdapterProvider);
      final contractRepo = ref.read(contractRepositoryProvider);

      if (!wallet.isConnected || wallet.publicKey == null) {
        throw Exception('Please connect your Solana wallet.');
      }

      await contractRepo.raiseDispute(
        contractId: contract.contractId,
        caller: wallet.publicKey!,
        walletAdapter: walletAdapter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute raised on Solana.')),
        );
      }
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractAsync = ref.watch(contractProvider(widget.contractId));
    final wallet = ref.watch(walletStateProvider);
    final currentAddress = wallet.address;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Contract #${widget.contractId}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          contractAsync.maybeWhen(
            data: (contract) => contract != null
                ? IconButton(
                    icon: const Icon(Icons.share_rounded, color: AppColors.primary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ContractShareScreen(contract: contract),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: contractAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading contract: $err'),
          ),
        ),
        data: (contract) {
          if (contract == null) {
            return const Center(child: Text('Contract not found'));
          }
          return _buildContent(context, contract, currentAddress);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EscrowContract contract,
    String? currentAddress,
  ) {
    final isEmployer = contract.isEmployer(currentAddress);
    final isWorker = contract.isWorker(currentAddress);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Escrow Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusPill(contract.status),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isEmployer ? AppColors.primaryContainer : AppColors.success)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEmployer
                          ? 'YOUR ROLE: EMPLOYER'
                          : isWorker
                              ? 'YOUR ROLE: WORKER'
                              : 'VIEW ONLY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isEmployer ? AppColors.primary : AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'ESCROW VALUE LOCKED',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    contract.formattedSol,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '≈ \$${(contract.amountSol * 140).toStringAsFixed(2)} USD',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Lifecycle Milestones Stepper
        _buildLifecycleStepper(contract),
        const SizedBox(height: 18),

        // Terms & Deliverables Card
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
                'Scope of Work & Terms',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contract.termsText ?? 'P2P Contract Agreement',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHA-256 Terms Hash',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${contract.termsHash.substring(0, 6)}…${contract.termsHash.substring(contract.termsHash.length - 6)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Participant Addresses Card
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
                'Participants & On-Chain Addresses',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildAddressRow('Employer', contract.employer, isYou: isEmployer),
              const SizedBox(height: 10),
              _buildAddressRow('Worker', contract.worker, isYou: isWorker),
              if (contract.lastTxSignature != null) ...[
                const SizedBox(height: 10),
                _buildAddressRow(
                  'Last TX Hash',
                  contract.lastTxSignature!,
                  isTx: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        if (_actionError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _actionError!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Primary Action: Worker Accept
        if (contract.canAccept(currentAddress))
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isActionLoading ? null : () => _handleAccept(contract),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isActionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                'Accept Contract & Begin Work',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        // Primary Action: Employer Release & Review
        if (contract.canRelease(currentAddress))
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isActionLoading
                  ? null
                  : () => ReleaseAndReviewModal.show(context, contract),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.verified_rounded),
              label: Text(
                'Release Payment & Rate Worker',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),

        // Secondary Action: Employer Cancel & Refund
        if (contract.canCancel(currentAddress) &&
            contract.status == ContractStatus.funded) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isActionLoading ? null : () => _handleCancel(contract),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
              label: Text(
                'Cancel Contract & Reclaim Funds',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ],

        // Tertiary Action: Dispute
        if (contract.canDispute(currentAddress) &&
            contract.status == ContractStatus.inProgress) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: _isActionLoading ? null : () => _handleDispute(contract),
              icon: const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
              label: Text(
                'Raise Dispute on Solana',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLifecycleStepper(EscrowContract contract) {
    final isFunded = contract.status != ContractStatus.created;
    final isInProgress = contract.status == ContractStatus.inProgress ||
        contract.status == ContractStatus.completed;
    final isCompleted = contract.status == ContractStatus.completed;

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
          Text(
            'Contract Lifecycle',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          _buildStepRow(
            stepNumber: '1',
            title: 'Created & Escrow Funded',
            subtitle: 'Employer locked funds into Solana vault',
            isDone: isFunded,
            isCurrent: contract.status == ContractStatus.funded,
          ),
          _buildStepConnector(isDone: isInProgress),
          _buildStepRow(
            stepNumber: '2',
            title: 'Worker Accepted',
            subtitle: 'Terms agreed and work in progress',
            isDone: isInProgress,
            isCurrent: contract.status == ContractStatus.inProgress,
          ),
          _buildStepConnector(isDone: isCompleted),
          _buildStepRow(
            stepNumber: '3',
            title: 'Settlement & Verified Rating',
            subtitle: contract.status == ContractStatus.completed
                ? 'Released payment and anchored ${contract.rating}-star review'
                : 'Awaiting employer review and release',
            isDone: isCompleted,
            isCurrent: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success
                : isCurrent
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    stepNumber,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : AppColors.outline,
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
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isDone || isCurrent ? AppColors.onSurface : AppColors.outline,
                ),
              ),
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
      ],
    );
  }

  Widget _buildStepConnector({required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 18,
        color: isDone ? AppColors.success : AppColors.surfaceContainerHigh,
      ),
    );
  }

  Widget _buildAddressRow(String label, String address, {bool isYou = false, bool isTx = false}) {
    final short = address.length > 12
        ? '${address.substring(0, 6)}…${address.substring(address.length - 6)}'
        : address;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (isYou) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'YOU',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        Row(
          children: [
            Text(
              short,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied $label to clipboard')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill(ContractStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case ContractStatus.created:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurfaceVariant;
        label = 'CREATED';
        break;
      case ContractStatus.funded:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'ESCROW FUNDED';
        break;
      case ContractStatus.inProgress:
        bg = AppColors.primaryContainer.withValues(alpha: 0.15);
        fg = AppColors.primaryContainer;
        label = 'IN PROGRESS';
        break;
      case ContractStatus.completed:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = 'COMPLETED & RELEASED';
        break;
      case ContractStatus.disputed:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        label = 'DISPUTED';
        break;
      case ContractStatus.cancelled:
        bg = AppColors.surfaceContainerHighest;
        fg = AppColors.outline;
        label = 'CANCELLED & REFUNDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
