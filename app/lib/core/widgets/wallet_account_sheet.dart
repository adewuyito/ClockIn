import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../solana/network_config.dart';
import '../theme/app_colors.dart';
import 'profile_qr_sheet.dart';

/// Modal bottom sheet displaying connected wallet identity, balance,
/// explorer links, and a deliberate, confirmed disconnect option.
class WalletAccountSheet extends ConsumerWidget {
  const WalletAccountSheet({super.key});

  /// Presents the [WalletAccountSheet] bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WalletAccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletStateProvider);
    final balanceAsync = ref.watch(walletBalanceProvider);
    final address = wallet.address ?? '';

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connected Wallet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Solana Devnet • MWA v2.0',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Address & Balance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PUBLIC KEY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (address.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: address));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Solana address copied to clipboard.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address.isNotEmpty ? address : 'Not connected',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Devnet Balance',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    balanceAsync.when(
                      data: (lamports) {
                        if (lamports == null) return const Text('—');
                        final sol = lamports / 1e9;
                        return Text(
                          '${sol.toStringAsFixed(3)} SOL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, stack) => const Text('Error loading'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          r'$SKR Token Balance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SPL',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6750A4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ref.watch(walletSkrBalanceProvider).when(
                      data: (skr) => Text(
                        '${skr >= 1.0 ? skr.toStringAsFixed(1) : skr.toStringAsFixed(0)} \$SKR',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6750A4),
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => const Text(r'0 $SKR'),
                    ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, _) {
                      final attestation = ref.watch(seekerAttestationProvider(address)).valueOrNull;
                      final isAttested = attestation?.isAttested ?? false;
                      final stakedAmt = (attestation?.stakedAmount ?? 0) >= 1.0
                          ? '${attestation!.stakedAmount.toStringAsFixed(0)} \$SKR'
                          : r'250 $SKR';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isAttested ? Icons.shield_rounded : Icons.shield_outlined,
                                size: 16,
                                color: isAttested ? const Color(0xFF1F9D5B) : AppColors.outline,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Seeker Attestation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAttested ? const Color(0xFFE8F8F0) : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAttested
                                    ? const Color(0xFF1F9D5B).withValues(alpha: 0.3)
                                    : AppColors.outlineVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isAttested ? 'Attested • $stakedAmt' : 'Unverified Stake',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isAttested ? const Color(0xFF0B5E36) : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action 1: Copy Explorer Link
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.onSurface),
            ),
            title: Text(
              'Copy Solana Explorer Link',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            subtitle: Text(
              'View address on Solana Devnet explorer',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            onTap: () {
              if (address.isNotEmpty) {
                final url =
                    'https://explorer.solana.com/address/$address?cluster=${NetworkConfig.clusterName}';
                Clipboard.setData(ClipboardData(text: url));
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Explorer URL copied to clipboard.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 6),

          // Action 2: Show Address QR Code
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.primary),
            ),
            title: Text(
              'Show Address QR Code',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            subtitle: Text(
              'Display scannable code for ClockIn or Solana wallets',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              ProfileQrSheet.show(
                context,
                address: address,
                label: 'Wallet QR Code',
              );
            },
          ),
          const SizedBox(height: 6),

          // Action 3: Disconnect Action
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            ),
            title: Text(
              'Disconnect Wallet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            subtitle: Text(
              'End current Mobile Wallet session',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text(
                    'Disconnect Wallet?',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    'Are you sure you want to disconnect? You will need to re-authorize with Phantom or Solflare to interact with on-chain contracts.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                HapticFeedback.mediumImpact();
                await ref.read(walletStateProvider.notifier).disconnect();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wallet disconnected.')),
                  );
                }
              }
            },
          ),
        ],
      ),
      ),
    );
  }
}
