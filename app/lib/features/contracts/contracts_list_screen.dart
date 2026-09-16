import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/escrow_contract.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import 'contract_detail_screen.dart';
import 'create_contract_screen.dart';

enum ContractFilter { all, employer, worker }

class ContractsListScreen extends ConsumerStatefulWidget {
  const ContractsListScreen({super.key});

  @override
  ConsumerState<ContractsListScreen> createState() => _ContractsListScreenState();
}

class _ContractsListScreenState extends ConsumerState<ContractsListScreen> {
  ContractFilter _filter = ContractFilter.all;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);
    final contractsAsync = ref.watch(myContractsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: contractsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load contracts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(myContractsProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (allContracts) {
                  if (allContracts.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildContractList(context, wallet.address, allContracts);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateContractScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'New Contract',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 42,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Contracts Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Lock funds safely in a Solana escrow contract before work begins. Payment is automatically released only after the job is completed and approved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateContractScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Create First Contract',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 20, color: AppColors.primaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Zero platform custody. Funds are held in Solana Program Derived Addresses (PDAs).',
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
        ),
      ),
    );
  }

  Widget _buildContractList(
    BuildContext context,
    String? currentWallet,
    List<EscrowContract> contracts,
  ) {
    final activeCount = contracts
        .where((c) =>
            c.status == ContractStatus.created ||
            c.status == ContractStatus.funded ||
            c.status == ContractStatus.inProgress)
        .length;

    final totalSol = contracts
        .where((c) =>
            c.status == ContractStatus.funded ||
            c.status == ContractStatus.inProgress)
        .fold(0.0, (sum, c) => sum + c.amountSol);

    final completedCount =
        contracts.where((c) => c.status == ContractStatus.completed).length;

    // Filter list
    final filteredContracts = contracts.where((c) {
      if (_filter == ContractFilter.employer) {
        return c.isEmployer(currentWallet);
      } else if (_filter == ContractFilter.worker) {
        return c.isWorker(currentWallet);
      }
      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(myContractsProvider);
        await ref.read(myContractsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Header title & badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Contracts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'P2P Solana on-chain escrow agreements',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Solana Devnet',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'ACTIVE',
                  valueWidget: Row(
                    children: [
                      Text(
                        '$activeCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'open',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  topTrailing: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeCount > 0 ? AppColors.success : AppColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  label: 'TOTAL VALUE',
                  valueWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${totalSol.toStringAsFixed(2)} SOL',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      Text(
                        '≈ \$${(totalSol * 140).toStringAsFixed(0)}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  label: 'COMPLETED',
                  valueWidget: Row(
                    children: [
                      Text(
                        '$completedCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ok',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented Filter Pills
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFilterTab(ContractFilter.all, 'All (${contracts.length})'),
                _buildFilterTab(
                  ContractFilter.employer,
                  'As Employer (${contracts.where((c) => c.isEmployer(currentWallet)).length})',
                ),
                _buildFilterTab(
                  ContractFilter.worker,
                  'As Worker (${contracts.where((c) => c.isWorker(currentWallet)).length})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cards list
          if (filteredContracts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No contracts match this filter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...filteredContracts.map((contract) => _buildContractCard(context, contract, currentWallet)),

          const SizedBox(height: 16),
          // Trust Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryFixedDim.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All escrow funds are locked directly in decentralized Solana PDA vaults. Non-custodial and trustless.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      height: 1.4,
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

  Widget _buildSummaryCard({
    required String label,
    required Widget valueWidget,
    Widget? topTrailing,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              ?topTrailing,
            ],
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildFilterTab(ContractFilter filter, String title) {
    final isSelected = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    EscrowContract contract,
    String? currentWallet,
  ) {
    final isEmployer = contract.isEmployer(currentWallet);
    final counterpartyRole = isEmployer ? 'Worker' : 'Employer';
    final counterpartyAddress = isEmployer ? contract.shortWorker : contract.shortEmployer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContractDetailScreen(contractId: contract.contractId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Role + Status Badges + Escrow ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isEmployer
                                ? AppColors.primaryContainer.withValues(alpha: 0.12)
                                : AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isEmployer ? 'EMPLOYER' : 'WORKER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isEmployer ? AppColors.primary : AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status Badge
                        _buildStatusBadge(contract.status),
                      ],
                    ),
                    Text(
                      '#${contract.contractId}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Counterparty & Title Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Geometric Avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        (isEmployer ? contract.worker : contract.employer)
                            .substring(0, 2)
                            .toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
                                '$counterpartyRole: ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                counterpartyAddress,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contract.termsText ?? 'P2P Contract Agreement',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          contract.formattedSol,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '≈ \$${(contract.amountSol * 140).toStringAsFixed(1)} USD',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                const SizedBox(height: 10),

                // Meta Row: Date & Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          contract.deadline != null
                              ? Icons.schedule_rounded
                              : Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contract.deadline != null
                              ? 'Deadline: ${_formatDate(contract.deadline!)}'
                              : 'Created: ${_formatDate(contract.createdAt)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.outlineVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ContractStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData? icon;

    switch (status) {
      case ContractStatus.created:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurfaceVariant;
        label = 'CREATED';
        break;
      case ContractStatus.funded:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'FUNDED';
        icon = Icons.lock_rounded;
        break;
      case ContractStatus.inProgress:
        bg = AppColors.primaryContainer.withValues(alpha: 0.15);
        fg = AppColors.primaryContainer;
        label = 'IN PROGRESS';
        icon = Icons.trending_up_rounded;
        break;
      case ContractStatus.completed:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = 'COMPLETED';
        icon = Icons.check_circle_rounded;
        break;
      case ContractStatus.disputed:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        label = 'DISPUTED';
        icon = Icons.warning_amber_rounded;
        break;
      case ContractStatus.cancelled:
        bg = AppColors.surfaceContainerHighest;
        fg = AppColors.outline;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
