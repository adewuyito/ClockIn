import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/database/attestation_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/seeker_attestation.dart';
import '../../core/services/device_service.dart';
import '../../core/solana/skr_staking.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/seeker_logo.dart';

/// Seeker attestation sheet.
///
/// Shows the wallet's *active* $SKR stake as read from Solana Mobile's Guardian
/// staking program. Users stake through stake.solanamobile.com or Seed Vault
/// Wallet; this sheet only reads and refreshes that on-chain state. Nothing here
/// can mark a wallet attested — only a successful read of ≥250 staked $SKR does.
class SeekerStakingSheet extends ConsumerStatefulWidget {
  final String address;

  const SeekerStakingSheet({
    super.key,
    required this.address,
  });

  /// Opens the Seeker Attestation modal sheet.
  static Future<void> show(BuildContext context, {required String address}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SeekerStakingSheet(address: address),
    );
  }

  @override
  ConsumerState<SeekerStakingSheet> createState() => _SeekerStakingSheetState();
}

class _SeekerStakingSheetState extends ConsumerState<SeekerStakingSheet> {
  bool _isVerifying = false;
  bool _isClaiming = false;
  bool _isError = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final skrBalanceAsync = ref.watch(walletSkrBalanceProvider);
    final walletState = ref.watch(walletStateProvider);
    final skrBalance = skrBalanceAsync.valueOrNull ?? 0.0;
    final seekerDevice = ref.watch(seekerDeviceProvider);
    final isSeekerHardware = seekerDevice.isSeeker;
    final attestationAsync = ref.watch(seekerAttestationProvider(widget.address));
    final attestation = attestationAsync.valueOrNull;
    final hasVerified = attestation != null && attestation.syncedAt.millisecondsSinceEpoch > 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
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
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Seeker Mobile logo
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSeekerHardware
                      ? const Color(0xFF14F195).withValues(alpha: 0.16)
                      : const Color(0xFF1F9D5B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: isSeekerHardware
                      ? Border.all(color: const Color(0xFF00D18C).withValues(alpha: 0.4), width: 1)
                      : null,
                ),
                child: Center(
                  child: SeekerLogo(
                    size: 24,
                    isActive: isSeekerHardware,
                    withGlow: isSeekerHardware,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seeker Guardian Attestation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Solana Mobile Guardian stake • read-only',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Explainer text
          Text(
            'Stake 250+ \$SKR with a Guardian at stake.solanamobile.com or in Seed Vault Wallet. ClockIn reads your active stake straight from Solana Mobile’s staking program — it never asks you to sign anything here and never touches your tokens.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Attestation Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _buildMetricRow(
                  label: 'Active Guardian Stake',
                  value: attestationAsync.isLoading && attestation == null
                      ? 'Reading…'
                      : (hasVerified
                          ? '${_formatSkr(attestation.stakedAmount)} \$SKR'
                          : 'Not verified'),
                  isPositive: hasVerified ? attestation.isAttested : null,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Required for Attestation',
                  value: '${_formatSkr(AttestationRepository.minimumStakeThreshold)} \$SKR',
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Guardian',
                  value: hasVerified && attestation.stakedAmount > 0
                      ? attestation.guardianName
                      : '—',
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Last Verified On-Chain',
                  value: hasVerified ? _timeAgo(attestation.syncedAt) : 'Never',
                  isPositive: attestation?.verificationError != null ? false : null,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Read From',
                  value: SkrStakingDeployment.active.cluster == SkrStakingCluster.mainnet
                      ? 'Solana Mainnet'
                      : 'Solana Devnet',
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                // The escrow faucet token is a devnet stand-in: it is NOT stake
                // and can never count toward attestation.
                _buildMetricRow(
                  label: r'Devnet Escrow $SKR (test)',
                  value: skrBalanceAsync.when(
                    data: (b) => '${_formatSkr(b)} \$SKR',
                    loading: () => 'Loading...',
                    error: (_, _) => '—',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Official Staking Portal Link Box
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: 'https://stake.solanamobile.com'));
              HapticFeedback.selectionClick();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF12242A),
                    content: Text('Copied https://stake.solanamobile.com to clipboard!'),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Staking Portal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'stake.solanamobile.com',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.outline),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status feedback
          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isError
                    ? const Color(0xFFFDE8E8)
                    : (_isVerifying || _isClaiming
                        ? AppColors.primaryContainer.withValues(alpha: 0.15)
                        : const Color(0xFFE8F8F0)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isError
                      ? const Color(0xFFF87171)
                      : (_isVerifying || _isClaiming
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : const Color(0xFF1F9D5B).withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  if (_isVerifying || _isClaiming)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_isError)
                    const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626))
                  else
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1F9D5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _isError
                            ? const Color(0xFF991B1B)
                            : (_isVerifying || _isClaiming
                                ? AppColors.onSurface
                                : const Color(0xFF0B5E36)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Primary Verification Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isVerifying || _isClaiming
                  ? null
                  : _refreshStake,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                _isVerifying ? 'Reading stake from Solana…' : 'Refresh Stake from Solana',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F9D5B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Optional Faucet Claim for Escrow Contracts
          if (walletState.publicKey != null && skrBalance < 250.0) ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: _isClaiming || _isVerifying
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isClaiming = true;
                          _isError = false;
                          _statusMessage = 'Minting 500 \$SKR for Escrow Contracts...';
                        });

                        try {
                          final repo = ref.read(attestationRepositoryProvider);
                          await repo.claimDevnetFaucet(
                            wallet: walletState.publicKey!,
                            amount: 500.0,
                          );

                          ref.invalidate(walletSkrBalanceProvider);
                          await ref.read(walletSkrBalanceProvider.future);

                          if (mounted) {
                            setState(() {
                              _isClaiming = false;
                              _isError = false;
                              _statusMessage = 'Claimed 500 \$SKR for Escrow Contracts!';
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isClaiming = false;
                              _isError = true;
                              _statusMessage = 'Faucet claim failed: $e';
                            });
                          }
                        }
                      },
                icon: _isClaiming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.water_drop_outlined, size: 18),
                label: Text(
                  _isClaiming ? 'Claiming Devnet \$SKR...' : r'Claim 500 Devnet $SKR for Escrow (not stake)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Security footnote
          Center(
            child: Text(
              'Read-only: ClockIn never signs, stakes, or moves \$SKR. Your stake stays in Solana Mobile’s staking program.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Forces an on-chain read and reports exactly what was found. Each outcome
  /// gets its own message — "below threshold" and "couldn't reach Solana" must
  /// never look like each other, or like success.
  Future<void> _refreshStake() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isVerifying = true;
      _isError = false;
      _statusMessage = 'Reading your stake from Solana Mobile’s staking program…';
    });

    final repo = ref.read(attestationRepositoryProvider);
    final SeekerAttestation result =
        await repo.getAttestation(widget.address, forceRefresh: true);
    ref.invalidate(seekerAttestationProvider(widget.address));
    if (!mounted) return;

    final staked = _formatSkr(result.stakedAmount);
    final needed = _formatSkr(AttestationRepository.minimumStakeThreshold);
    setState(() {
      _isVerifying = false;
      if (result.verificationError != null) {
        _isError = true;
        _statusMessage = '${result.verificationError} Try again in a moment.';
      } else if (result.isAttested) {
        _isError = false;
        _statusMessage =
            'Verified on-chain: $staked \$SKR actively staked with ${result.guardianName}.';
      } else if (result.stakedAmount > 0) {
        _isError = true;
        _statusMessage =
            'Found $staked \$SKR staked — $needed needed. Add more at stake.solanamobile.com, then refresh.';
      } else {
        _isError = true;
        _statusMessage =
            'No active \$SKR stake found for this wallet. Stake $needed+ at stake.solanamobile.com, then refresh.';
      }
    });
    if (result.isAttested && result.verificationError == null) {
      HapticFeedback.heavyImpact();
    }
  }

  static final NumberFormat _skrFormat = NumberFormat('#,##0.##');

  static String _formatSkr(double amount) => _skrFormat.format(amount);

  static String _timeAgo(DateTime when) {
    final diff = DateTime.now().toUtc().difference(when.toUtc());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    bool? isPositive,
  }) {
    Color valueColor = AppColors.onSurface;
    if (isPositive == true) {
      valueColor = const Color(0xFF0B5E36);
    } else if (isPositive == false) {
      valueColor = AppColors.error;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
