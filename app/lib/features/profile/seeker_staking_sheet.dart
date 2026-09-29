import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/attestation_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Modal bottom sheet guiding workers through the real on-chain $SKR staking flow.
/// Checks wallet balance, provides an authorized Devnet faucet claim, and routes
/// through Mobile Wallet Adapter (Phantom/Solflare) to cryptographically stake
/// 250 $SKR tokens into the Guardian Stake Vault PDA.
class SeekerStakingSheet extends ConsumerStatefulWidget {
  final String address;

  const SeekerStakingSheet({
    super.key,
    required this.address,
  });

  /// Opens the Seeker Staking modal sheet.
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
  bool _isClaiming = false;
  bool _isStaking = false;
  String? _statusMessage;
  String? _txSignature;

  @override
  Widget build(BuildContext context) {
    final skrBalanceAsync = ref.watch(walletSkrBalanceProvider);
    final walletState = ref.watch(walletStateProvider);
    final skrBalance = skrBalanceAsync.valueOrNull ?? 0.0;
    final hasEnoughSkr = skrBalance >= AttestationRepository.minimumStakeThreshold;

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

          // Header with shield icon
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F9D5B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFF1F9D5B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seeker Guardian Staking',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Solana Devnet • Mobile Wallet Adapter',
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
            r'Stake 250 $SKR tokens into the Guardian Stake Vault to cryptographically attest your identity, protect against Sybil bots, and unlock verified priority in employer searches.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Balance & Staking Details Card
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
                  label: r'Your Wallet $SKR Balance',
                  value: skrBalanceAsync.when(
                    data: (b) => '${b >= 1.0 ? b.toStringAsFixed(1) : b.toStringAsFixed(0)} \$SKR',
                    loading: () => 'Loading...',
                    error: (_, _) => '0.0 \$SKR',
                  ),
                  isPositive: hasEnoughSkr,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Required Stake Amount',
                  value: r'250.0 $SKR',
                  isPositive: true,
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Designated Guardian',
                  value: 'Helius Stake Vault',
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: 'Unstaking Cooldown',
                  value: '48 Hours',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status / Tx feedback
          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isStaking || _isClaiming
                    ? AppColors.primaryContainer.withValues(alpha: 0.15)
                    : const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isStaking || _isClaiming
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : const Color(0xFF1F9D5B).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  if (_isStaking || _isClaiming)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1F9D5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _isStaking || _isClaiming
                                ? AppColors.onSurface
                                : const Color(0xFF0B5E36),
                          ),
                        ),
                        if (_txSignature != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Tx: ${_txSignature!.substring(0, 14)}…',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0B5E36).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Actions based on balance
          if (!hasEnoughSkr) ...[
            // Insufficient balance warning + Faucet button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF856404)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r'You do not have enough $SKR in your wallet to stake. Claim 500 free Devnet $SKR from the faucet below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF856404),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Faucet Claim Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isClaiming || _isStaking
                    ? null
                    : () async {
                        if (walletState.publicKey == null) return;
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isClaiming = true;
                          _statusMessage = 'Minting 500 \$SKR on Solana Devnet...';
                        });

                        try {
                          final repo = ref.read(attestationRepositoryProvider);
                          final sig = await repo.claimDevnetFaucet(
                            wallet: walletState.publicKey!,
                            amount: 500.0,
                          );

                          ref.invalidate(walletSkrBalanceProvider);
                          await ref.read(walletSkrBalanceProvider.future);

                          if (mounted) {
                            setState(() {
                              _isClaiming = false;
                              _txSignature = sig;
                              _statusMessage = 'Claimed 500 \$SKR! Ready to stake.';
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isClaiming = false;
                              _statusMessage = 'Faucet claim failed: $e';
                            });
                          }
                        }
                      },
                icon: _isClaiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.water_drop_rounded, size: 20),
                label: Text(
                  _isClaiming ? 'Claiming Devnet \$SKR...' : 'Claim 500 Devnet \$SKR (Faucet)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            // Has enough SKR -> Stake via MWA Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isStaking || _isClaiming
                    ? null
                    : () async {
                        if (walletState.publicKey == null) return;
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isStaking = true;
                          _statusMessage = 'Opening Phantom / Solflare to approve stake...';
                        });

                        try {
                          final repo = ref.read(attestationRepositoryProvider);
                          final walletAdapter = ref.read(walletAdapterProvider);

                          final sig = await repo.stakeSkrOnChain(
                            wallet: walletState.publicKey!,
                            walletAdapter: walletAdapter,
                            amount: AttestationRepository.minimumStakeThreshold,
                            guardianName: 'Helius',
                          );

                          // Invalidate relevant providers for immediate reactive UI update
                          ref.invalidate(walletSkrBalanceProvider);
                          ref.invalidate(seekerAttestationProvider(widget.address));

                          if (mounted) {
                            setState(() {
                              _isStaking = false;
                              _txSignature = sig;
                              _statusMessage = 'Successfully staked 250 \$SKR! Seeker Attested.';
                            });

                            HapticFeedback.heavyImpact();

                            await Future.delayed(const Duration(milliseconds: 1200));
                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF1F9D5B),
                                  content: Text('Staked 250 \$SKR to Guardian Helius. Seeker Attested!'),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isStaking = false;
                              _statusMessage = 'Staking transaction failed or cancelled.';
                            });
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text('Staking error: $e'),
                              ),
                            );
                          }
                        }
                      },
                icon: _isStaking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.shield_rounded, size: 20),
                label: Text(
                  _isStaking ? 'Signing in Wallet...' : 'Stake 250 \$SKR via Wallet',
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
          ],
          const SizedBox(height: 10),

          // Security footnote
          Center(
            child: Text(
              'Tokens remain in Guardian escrow and can be unstaked with cooldown.',
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
