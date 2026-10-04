import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/attestation_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/device_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/seeker_logo.dart';

/// Modal bottom sheet for Non-Custodial Seeker Guardian Attestation (Option 1).
/// Verifies the worker's active $SKR stake delegated to an official Solana Mobile Guardian
/// via stake.solanamobile.com or the Seeker Seed Vault. ClockIn NEVER takes custody of staked funds.
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
                      'Solana Mobile • Non-Custodial Verification',
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
            'ClockIn verifies your active \$SKR stake directly from Solana Mobile’s official Guardian network. ClockIn is 100% non-custodial and never holds your staked tokens. Delegate 250+ \$SKR via your Seeker Seed Vault or the official portal.',
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
                  label: 'Designated Guardian',
                  value: 'Solana Mobile',
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
                  label: 'Custody Model',
                  value: 'Non-Custodial (Official)',
                  isPositive: true,
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 10),
                _buildMetricRow(
                  label: r'Liquid Wallet $SKR Balance',
                  value: skrBalanceAsync.when(
                    data: (b) => '${b >= 1.0 ? b.toStringAsFixed(1) : b.toStringAsFixed(0)} \$SKR',
                    loading: () => 'Loading...',
                    error: (_, _) => '0.0 \$SKR',
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
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isVerifying = true;
                        _isError = false;
                        _statusMessage = 'Querying Solana Mobile Guardian staking state...';
                      });

                      try {
                        final repo = ref.read(attestationRepositoryProvider);

                        // Verify non-custodial attestation with official Solana Mobile Guardian
                        await repo.verifyAttestation(
                          address: widget.address,
                          guardianName: 'Solana Mobile',
                          stakedAmount: AttestationRepository.minimumStakeThreshold,
                        );

                        // Invalidate attestation provider for instant reactive UI updates
                        ref.invalidate(seekerAttestationProvider(widget.address));

                        if (mounted) {
                          setState(() {
                            _isVerifying = false;
                            _isError = false;
                            _statusMessage = 'Verified! Active stake confirmed with Solana Mobile Guardian.';
                          });

                          HapticFeedback.heavyImpact();

                          await Future.delayed(const Duration(milliseconds: 900));
                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF1F9D5B),
                                content: Text('Seeker Attestation verified! Active stake confirmed with Solana Mobile Guardian.'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _isVerifying = false;
                            _isError = true;
                            _statusMessage = 'Verification failed: $e';
                          });
                        }
                      }
                    },
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_rounded, size: 20),
              label: Text(
                _isVerifying ? 'Verifying on Solana...' : 'Verify On-Chain Attestation',
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
                  _isClaiming ? 'Claiming Devnet \$SKR...' : r'Claim 500 Devnet $SKR (For Escrow Contracts)',
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
              'ClockIn is 100% non-custodial. Your staked tokens remain in your official Solana Mobile staking account.',
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
