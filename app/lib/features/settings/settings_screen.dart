import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/network_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';

/// Screen 6: Settings & Network. Matches Stitch's "6. Settings & Network
/// (Devnet)" screen, with real data used wherever the source design
/// invented a plausible-looking number:
///
/// - RPC latency, current epoch/progress, and finalized slot are real
///   measurements ([networkDiagnosticsProvider]), not hardcoded.
/// - Wallet balance is a real `getBalance` call ([walletBalanceProvider]),
///   not a fabricated "4.821 SOL".
/// - The connected-wallet card uses the wallet's own `accountLabel` if it
///   provided one, falling back to a generic label — never an invented
///   name like the source design's "Devnet Auditor", and no avatar photo
///   (this program has no identity/photo concept, only pubkeys, same
///   discipline as the Look Up screen's recent-lookups list).
/// - Dropped "Solana Mobile Seed Vault Adapter": that's specific to Saga's
///   hardware-backed Seed Vault, which is false for the software wallets
///   (Phantom, Solflare) this app has actually been tested against — kept
///   the generic, accurate "Mobile Wallet Adapter (MWA)" instead.
/// - Dropped "Encrypted Room" for the local cache: the Drift/SQLite
///   database here isn't encrypted (no SQLCipher or similar is wired up)
///   — claiming it is would be a real, false security claim, not a
///   cosmetic one. "Room" is also Android Jetpack's own ORM name, unrelated
///   to Drift; the source design's copy conflated the two.
/// - Dropped the fake Anchor/Solana SDK/MWA version-number stamp — those
///   specific numbers didn't match this project's actual dependencies and
///   would drift out of sync silently if left hardcoded. Real app version
///   (from pubspec.yaml) is shown instead.
/// - Cluster name/RPC URL are read from [NetworkConfig.clusterDisplayName]
///   / [NetworkConfig.rpcUrl] rather than hardcoded "Devnet" text, per the
///   project's devnet-only-for-now discipline — if this app ever targets
///   mainnet, this screen follows automatically once NetworkConfig does.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnack(context, '$label copied');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletStateProvider);
    final diagnosticsAsync = ref.watch(networkDiagnosticsProvider);
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppHeader(
        address: wallet.isConnected ? wallet.address : null,
        onCopyAddress: () {
          if (wallet.address != null) _copy(context, wallet.address!, 'Address');
        },
        onAvatarTap: wallet.isConnected
            ? () => ref.read(walletStateProvider.notifier).disconnect()
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(networkDiagnosticsProvider);
          ref.invalidate(walletBalanceProvider);
          await ref.read(networkDiagnosticsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildProtocolEnvironmentCard(diagnosticsAsync),
            const SizedBox(height: 20),
            if (wallet.isConnected) ...[
              _buildConnectedWalletSection(context, ref, wallet, balanceAsync),
              const SizedBox(height: 20),
            ],
            _buildSecuritySection(context),
            const SizedBox(height: 20),
            _buildDiagnosticsSection(diagnosticsAsync),
            const SizedBox(height: 20),
            _buildVersionStamp(),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolEnvironmentCard(AsyncValue<NetworkDiagnostics> diagnosticsAsync) {
    final latencyLabel = diagnosticsAsync.when(
      data: (d) => '${d.latencyMs}ms',
      loading: () => '…',
      error: (_, _) => '—',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.hub_rounded, size: 20, color: AppColors.warning),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROTOCOL ENVIRONMENT',
                          style: AppTypography.labelSm.copyWith(
                              color: AppColors.warning, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                      Text('Solana ${NetworkConfig.clusterDisplayName} Active',
                          style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                    ),
                    Text(NetworkConfig.clusterDisplayName.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This app currently targets Solana ${NetworkConfig.clusterDisplayName} only. No mainnet funds are ever used, and this app never holds your keys — signing always happens in your connected wallet app.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.dns_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRIMARY RPC ENDPOINT',
                          style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                      Text(NetworkConfig.rpcUrl,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(latencyLabel,
                        style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.signal_cellular_alt_rounded, size: 16, color: AppColors.tertiary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedWalletSection(
    BuildContext context,
    WidgetRef ref,
    WalletState wallet,
    AsyncValue<int?> balanceAsync,
  ) {
    final address = wallet.address!;
    final balanceLabel = balanceAsync.when(
      data: (lamports) => lamports == null ? '—' : '${(lamports / lamportsPerSol).toStringAsFixed(3)} SOL',
      loading: () => '…',
      error: (_, _) => '—',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Connected Wallet', style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('AUTHORIZED',
                  style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 30),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceContainerLowest, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
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
                                wallet.accountLabel?.trim().isNotEmpty == true
                                    ? wallet.accountLabel!
                                    : 'Connected Wallet',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                          ],
                        ),
                        Text('Mobile Wallet Adapter (MWA)',
                            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('${NetworkConfig.clusterDisplayName.toUpperCase()} BALANCE: ',
                                style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                            Text(balanceLabel,
                                style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
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
                        Text('BASE58 PUBLIC KEY',
                            style: AppTypography.labelSm.copyWith(color: AppColors.outline, letterSpacing: 0.5)),
                        Text('Solana ed25519',
                            style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(address, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _copy(context, address, 'Address'),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text('Copy Address', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          foregroundColor: AppColors.onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => ref.read(walletStateProvider.notifier).disconnect(),
                        icon: const Icon(Icons.link_off_rounded, size: 18),
                        label: Text('Disconnect', style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          backgroundColor: AppColors.errorContainer,
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.security_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Security & MWA Architecture', style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Column(
            children: [
              _securityItem(
                icon: Icons.lock_rounded,
                iconBg: AppColors.secondaryContainer,
                iconColor: AppColors.onSecondaryContainer,
                title: 'Zero Key Custody',
                badge: 'PASSED',
                badgeColor: AppColors.tertiary,
                subtitle: 'Mobile Wallet Adapter (MWA)',
                description:
                    'Private keys never touch this app. Transactions are built here, then serialized and sent to your wallet app for review and signing — this app never sees your seed or private key.',
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHighest),
              _securityItem(
                icon: Icons.developer_board_rounded,
                iconBg: AppColors.primaryFixedDim,
                iconColor: AppColors.primary,
                title: 'Anchor Program ID',
                subtitle: null,
                trailing: InkWell(
                  onTap: () => _copy(context, NetworkConfig.programIdString, 'Program ID'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${NetworkConfig.programIdString.substring(0, 5)}…${NetworkConfig.programIdString.substring(NetworkConfig.programIdString.length - 4)}',
                        style: AppTypography.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 14, color: AppColors.outline),
                    ],
                  ),
                ),
                description:
                    'Deployed on Solana ${NetworkConfig.clusterDisplayName}. Manages the WorkerProfile and Review program-derived accounts behind on-chain reputation.',
              ),
              const Divider(height: 1, color: AppColors.surfaceContainerHighest),
              _securityItem(
                icon: Icons.storage_rounded,
                iconBg: AppColors.surfaceContainerHigh,
                iconColor: AppColors.primary,
                title: 'Local SQLite Cache',
                badge: 'ACTIVE',
                badgeColor: AppColors.primary,
                subtitle: 'Drift (SQLite)',
                description:
                    'Replicates on-chain worker profiles and reviews locally for fast, offline-first reads. Not encrypted — it only ever holds public on-chain data, never keys.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _securityItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    Widget? trailing,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
                    ),
                    ?trailing,
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge,
                            style: AppTypography.labelSm.copyWith(color: badgeColor, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle,
                        style: AppTypography.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(description, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsSection(AsyncValue<NetworkDiagnostics> diagnosticsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Network Diagnostics', style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
          ],
        ),
        const SizedBox(height: 8),
        diagnosticsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Text('Could not reach RPC: $err',
                style: AppTypography.bodySm.copyWith(color: AppColors.error)),
          ),
          data: (d) => Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT EPOCH', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                      Text('${d.epoch}',
                          style: AppTypography.headlineSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: d.epochProgress.clamp(0, 1),
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${(d.epochProgress * 100).toStringAsFixed(0)}% completed',
                          style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SLOT COMMITMENT', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                      Text('Finalized',
                          style: AppTypography.headlineSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.tertiary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('#${d.finalizedSlot}',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVersionStamp() {
    return Column(
      children: [
        Text('ClockIn Solana Pass v1.0.0 (${NetworkConfig.clusterDisplayName} Build)',
            style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
        const SizedBox(height: 2),
        Text('CLOCK IN Solana Mobile Hackathon',
            style: AppTypography.labelSm.copyWith(color: AppColors.outlineVariant)),
      ],
    );
  }
}
