import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/wallet_adapter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/devnet_badge.dart';

/// Screen 1 & 1b: Connect Wallet (Mobile Wallet Adapter).
/// The zero-custody entry point of ClockIn.
class ConnectWalletScreen extends ConsumerWidget {
  const ConnectWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletStateProvider);
    final walletNotifier = ref.read(walletStateProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Devnet status bar
              const Align(
                alignment: Alignment.centerLeft,
                child: DevnetBadge(),
              ),
              const SizedBox(height: 28),

              // Brand Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.tertiaryContainer,
                        child: Icon(Icons.bolt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Title and Subtitle
              const Text(
                'ClockIn',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Decentralized work reputation that follows you between gigs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Mock Preview Card (Stitch Snapshot Card)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.secondaryContainer,
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verified Contributor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'sol:8x2…k9F4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 14, color: AppColors.success),
                                SizedBox(width: 3),
                                Text(
                                  '5.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '38 shifts logged',
                            style: TextStyle(fontSize: 11, color: AppColors.outline),
                          ),
                          Text(
                            'On-Chain Attested',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Value Proposition Items
              _buildValueItem(
                icon: Icons.shield_outlined,
                title: 'Zero key custody',
                description:
                    'Private keys never touch this app. Sessions sign purely inside your hardware-backed wallet.',
              ),
              const SizedBox(height: 12),
              _buildValueItem(
                icon: Icons.sync_alt_rounded,
                title: 'Port across platforms',
                description:
                    'Export tamper-proof proof of work records between DAOs, gig platforms, and clients.',
              ),
              const SizedBox(height: 12),
              _buildValueItem(
                icon: Icons.cloud_off_rounded,
                title: 'Offline resilience',
                description:
                    'Draft reviews with Drift local cache and synchronize automatically when connected.',
              ),
              const SizedBox(height: 28),

              // State Variant: No Wallet Found Error Alert (Screen 1b)
              if (walletState.status == WalletStatus.noWalletFound)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No compatible Solana wallet found. Please install Phantom or Solflare on your Android device to connect.',
                          style: TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

              if (walletState.errorMessage != null &&
                  walletState.status != WalletStatus.noWalletFound)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error, width: 1),
                  ),
                  child: Text(
                    walletState.errorMessage!,
                    style: const TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                ),

              // Connect Button
              ElevatedButton(
                onPressed: walletState.status == WalletStatus.connecting
                    ? null
                    : () => walletNotifier.connect(),
                child: walletState.status == WalletStatus.connecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Connect Wallet (MWA)'),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Requires Phantom, Solflare, or SMS-compatible wallet',
                style: TextStyle(fontSize: 11, color: AppColors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.35,
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
}
