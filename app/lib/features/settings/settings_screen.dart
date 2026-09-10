import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/network_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/devnet_badge.dart';

/// Screen 6: Settings & Network (Devnet).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(draftReviewsProvider);
    final wallet = ref.watch(walletStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Network'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: DevnetBadge(showProtocol: false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Network Information Section
          const Text(
            'Solana Network Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target Cluster', style: TextStyle(fontSize: 14)),
                      DevnetBadge(showProtocol: false),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildConfigRow(
                    context,
                    'RPC Endpoint',
                    NetworkConfig.devnetRpcUrl,
                    copyable: true,
                  ),
                  const SizedBox(height: 12),
                  _buildConfigRow(
                    context,
                    'Anchor Program ID',
                    NetworkConfig.programIdString,
                    copyable: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Local Database / Offline Persistence Section
          const Text(
            'Local Drift Storage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offline-First Database Cache',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Worker profiles and review feeds are cached locally using Drift SQLite for instant UI loads and offline resilience.',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  draftsAsync.when(
                    data: (drafts) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pending Offline Drafts:',
                            style: TextStyle(fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${drafts.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Connected Wallet Session
          if (wallet.isConnected) ...[
            const Text(
              'Connected Session',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Icon(Icons.account_balance_wallet,
                      color: AppColors.secondary),
                ),
                title: Text(
                  'sol:${wallet.address?.substring(0, 4)}…${wallet.address?.substring(wallet.address!.length - 4)}',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Mobile Wallet Adapter v2.0'),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(walletStateProvider.notifier).disconnect(),
                  child: const Text('Disconnect',
                      style: TextStyle(color: AppColors.error)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Hackathon Badge Info
          Card(
            color: AppColors.surfaceContainerLow,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLOCK IN Solana Mobile Hackathon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Built for RadiantsDAO Hackathon (Sept 8 – Oct 8, 2026). Targeted for Saga & Seeker with Solana Mobile Stack & MWA.',
                    style: TextStyle(fontSize: 12, color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(
    BuildContext context,
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.outline),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (copyable)
              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.copy_rounded, color: AppColors.outline),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
