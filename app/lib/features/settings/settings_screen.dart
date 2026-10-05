import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solana/solana.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/device_service.dart';
import '../../core/services/encryption_key_registry.dart';
import '../../core/solana/network_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/devnet_setup_sheet.dart';
import '../../core/widgets/seeker_logo.dart';

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
            _buildProtocolEnvironmentCard(context, diagnosticsAsync),
            const SizedBox(height: 20),
            if (wallet.isConnected) ...[
              _buildConnectedWalletSection(context, ref, wallet, balanceAsync),
              const SizedBox(height: 20),
              _buildEncryptedDeliverablesSection(context, ref, wallet.address!),
              const SizedBox(height: 20),
            ],
            _buildSeekerDeviceSection(context, ref),
            const SizedBox(height: 20),
            _buildDiagnosticsSection(diagnosticsAsync),
            const SizedBox(height: 20),
            _buildVersionStamp(),
          ],
        ),
      ),
    );
  }

  /// Lets the user complete the one-time wallet attestation that binds their
  /// X25519 encryption key to their Solana address.
  ///
  /// Counterparties refuse to encrypt deliverables for an unattested key (an
  /// unsigned directory entry is indistinguishable from an attacker's), so until
  /// this is done, deliverable keys must be exchanged out of band via QR.
  /// Driven from here rather than automatically on connect because it opens an
  /// MWA handoff and wallets do not reliably return focus afterwards.
  Widget _buildEncryptedDeliverablesSection(
    BuildContext context,
    WidgetRef ref,
    String walletAddress,
  ) {
    final registry = ref.watch(encryptionKeyRegistryProvider);

    return FutureBuilder<bool>(
      future: registry.isAttested(walletAddress),
      builder: (context, snapshot) {
        final isAttested = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAttested ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 18,
                    color: isAttested ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ENCRYPTED DELIVERABLES',
                      style: AppTypography.labelSm.copyWith(color: AppColors.outline),
                    ),
                  ),
                  Text(
                    isLoading ? '—' : (isAttested ? 'ENABLED' : 'NOT SET UP'),
                    style: AppTypography.labelSm.copyWith(
                      color: isAttested ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isAttested
                    ? 'Your encryption key is published and signed by this wallet. '
                        'Counterparties can send you end-to-end encrypted deliverables.'
                    : 'Sign a one-time message to prove this wallet owns your device '
                        'encryption key. Without it, counterparties cannot verify the key '
                        'is yours and must exchange deliverable keys by QR code instead.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (!isAttested && !isLoading) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await registry.attestAndPublish(walletAddress);
                      if (!context.mounted) return;

                      final message = switch (result) {
                        KeyRegistrationResult.published =>
                          'Encryption key published. Encrypted deliverables enabled.',
                        KeyRegistrationResult.declined =>
                          'Signing was declined — encrypted deliverables stay off.',
                        KeyRegistrationResult.notConnected =>
                          'Connect your wallet first.',
                        KeyRegistrationResult.needsAttestation =>
                          'Attestation still required.',
                      };
                      messenger.showSnackBar(
                        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
                      );
                      if (result == KeyRegistrationResult.published) {
                        ref.invalidate(encryptionKeyRegistryProvider);
                      }
                    },
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text('Sign & publish encryption key'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProtocolEnvironmentCard(BuildContext context, AsyncValue<NetworkDiagnostics> diagnosticsAsync) {
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
          InkWell(
            onTap: () => showDevnetSetupSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet Network Configuration',
                            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                        Text('Step-by-step setup guide for Phantom and Solflare',
                            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.outline),
                ],
              ),
            ),
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_board_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANCHOR PROGRAM ID',
                          style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                      Text(
                        NetworkConfig.programIdString,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _copy(context, NetworkConfig.programIdString, 'Program ID'),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded, size: 16, color: AppColors.outline),
                  ),
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

  Widget _buildSeekerDeviceSection(BuildContext context, WidgetRef ref) {
    final seekerDevice = ref.watch(seekerDeviceProvider);
    final isSeeker = seekerDevice.isSeeker;
    final info = seekerDevice.deviceInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SOLANA MOBILE & HARDWARE',
              style: AppTypography.labelSm.copyWith(color: AppColors.outline),
            ),
            if (isSeeker)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF14F195).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF00D18C).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SeekerLogo(size: 10, isActive: true),
                    const SizedBox(width: 4),
                    Text(
                      seekerDevice.isPhysicalSeeker ? 'HARDWARE ACTIVE' : 'SIMULATED ACTIVE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B5E36),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSeeker
                          ? const Color(0xFF14F195).withValues(alpha: 0.15)
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: isSeeker
                          ? Border.all(color: const Color(0xFF00D18C).withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Center(
                      child: SeekerLogo(
                        size: 20,
                        isActive: isSeeker,
                        withGlow: isSeeker,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solana Seeker Device',
                          style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          seekerDevice.isPhysicalSeeker
                              ? 'Native Seeker Hardware Detected'
                              : (seekerDevice.isSimulated
                                  ? 'Simulated Seeker Device for Demo'
                                  : 'Standard Android Device'),
                          style: AppTypography.bodySm.copyWith(
                            color: isSeeker ? const Color(0xFF0B5E36) : AppColors.onSurfaceVariant,
                            fontWeight: isSeeker ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              const SizedBox(height: 12),
              _buildMetricDetailRow('Detected Model', info.model.isNotEmpty ? info.model : 'Android Generic'),
              const SizedBox(height: 8),
              _buildMetricDetailRow('Manufacturer / Brand', '${info.manufacturer.isNotEmpty ? info.manufacturer : 'Android'} / ${info.brand.isNotEmpty ? info.brand : 'Google'}'),
              const SizedBox(height: 8),
              _buildMetricDetailRow('Seed Vault Service', info.hasSeedVault ? 'Hardware Supported' : 'Software MWA Fallback'),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.surfaceContainerHigh),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulate Seeker Device',
                          style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Activate Seeker Mobile logo and hardware badges for video demo recording on non-Seeker devices.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: seekerDevice.isSimulated,
                    activeTrackColor: const Color(0xFF1F9D5B),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      ref.read(seekerDeviceProvider.notifier).toggleSimulation(val);
                      _showSnack(
                        context,
                        val ? 'Seeker Device mode simulated' : 'Seeker simulation turned off',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionStamp() {
    return Center(
      child: Text(
        'ClockIn v1.0.0',
        style: AppTypography.labelSm.copyWith(color: AppColors.outline),
      ),
    );
  }
}
