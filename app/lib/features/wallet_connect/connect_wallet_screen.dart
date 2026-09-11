import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/wallet_adapter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/devnet_badge.dart';

/// Screen 1 & 1b: Connect Wallet (Mobile Wallet Adapter).
/// The zero-custody entry point of ClockIn.
///
/// Fidelity notes vs. the Stitch design ("Connect Wallet (MWA)" / "No Wallet
/// Found"): the design's "Visual Worker Snapshot" mock card (a fake avatar,
/// a fake "sol:8x2…k9F4" address, "38 shifts logged", "Merkle Root Synced")
/// was dropped entirely rather than adapted — there is no real data to show
/// before a wallet is even connected, and the program has no Merkle tree.
/// The third value-proposition row ("Anchor smart contracts generate
/// deterministic shift hashes...") was replaced with a real, already-built
/// feature (offline draft reviews via the local Drift cache). The "How does
/// this work?" explainer sheet keeps the design's structure but rewrites the
/// "Clock In & Out" / "attestation memos" / shift-hash steps to describe the
/// actual register → review flow. The design's two-stage fake loading
/// animation ("Requesting Wallet Session…" → "Awaiting Signature…", driven
/// by a JS timer unrelated to any real call) was replaced with a single
/// honest "Connecting…" state, since `WalletAdapter.connect()` is one opaque
/// await with no intermediate stages to report truthfully.
class ConnectWalletScreen extends ConsumerWidget {
  const ConnectWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletStateProvider);
    final walletNotifier = ref.read(walletStateProvider.notifier);

    if (walletState.status == WalletStatus.noWalletFound) {
      return _NoWalletFoundView(onCheckAgain: () => walletNotifier.connect());
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: DevnetBadge(),
              ),
              const SizedBox(height: 32),

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

              Text('ClockIn', style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 6),
              Text(
                'Decentralized work reputation that follows you between gigs.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 28),

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
                    'Carry one on-chain reputation record between DAOs, gig platforms, and clients — it lives on Solana, not inside any single app.',
              ),
              const SizedBox(height: 12),
              _buildValueItem(
                icon: Icons.cloud_off_rounded,
                title: 'Offline resilience',
                description:
                    'Draft reviews with the local cache and submit automatically once you\'re back online.',
              ),
              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () => _showExplainerSheet(context),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: const Text('How does this work?'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              const SizedBox(height: 12),

              if (walletState.errorMessage != null)
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: walletState.status == WalletStatus.connecting
                      ? null
                      : () => walletNotifier.connect(),
                  child: walletState.status == WalletStatus.connecting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text('Connecting…'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Connect via Mobile Wallet'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Authorizes via installed MWA wallet (Phantom, Solflare, etc.)',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExplainerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('How ClockIn works', style: AppTypography.headlineSm),
              const SizedBox(height: 20),
              _buildExplainerStep(
                number: '01',
                title: 'One-tap MWA connect',
                description:
                    'Your phone opens a session with your installed wallet app and negotiates authorization — your private key never leaves that wallet.',
              ),
              const SizedBox(height: 16),
              _buildExplainerStep(
                number: '02',
                title: 'Register & get reviewed',
                description:
                    'Create your on-chain worker record once, then clients or collaborators submit a signed review tied to a rating and job ID.',
              ),
              const SizedBox(height: 16),
              _buildExplainerStep(
                number: '03',
                title: 'Portable, permanent reputation',
                description:
                    'Your review history lives in a Solana program account — nobody can quietly edit or delete it, and it\'s yours to carry anywhere that reads the same program.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplainerStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: AppTypography.labelLg.copyWith(color: AppColors.primaryFixedDim, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMd),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, height: 1.4)),
            ],
          ),
        ),
      ],
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
                  Text(title, style: AppTypography.titleMd),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, height: 1.35),
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

/// Screen 1b: No Wallet Found — shown when [WalletAdapter.isWalletAvailable]
/// finds no MWA-compatible wallet app installed on the device.
///
/// Fidelity notes: the design's curated wallet list (Phantom, Solflare,
/// Backpack) is real — these are genuine, installable Android apps that
/// support MWA. The design links directly to each Play Store listing; since
/// launching an external browser/Play Store intent needs a new native
/// plugin (`url_launcher`, plus Android 11+ package-visibility `<queries>`
/// entries) that isn't in this app for anything else yet, tapping a wallet
/// or "Install a wallet" copies its Play Store link to the clipboard instead
/// of opening it directly — same clipboard-fallback pattern used elsewhere
/// in the app rather than adding a plugin for one screen. The "Already
/// installed? Check again" action re-runs the real `connect()` flow (which
/// re-checks wallet availability) instead of the design's `window.location.reload()`,
/// since this is a native app, not a web page.
class _NoWalletFoundView extends StatelessWidget {
  const _NoWalletFoundView({required this.onCheckAgain});

  final VoidCallback onCheckAgain;

  static const _wallets = [
    (
      name: 'Phantom',
      subtitle: 'Most popular Solana wallet · Play Store',
      packageId: 'app.phantom',
      icon: Icons.token_rounded,
      color: Color(0xFF553C9A),
      badge: 'Popular',
    ),
    (
      name: 'Solflare',
      subtitle: 'Mobile & browser support',
      packageId: 'com.solflare.mobile',
      icon: Icons.shield_rounded,
      color: Color(0xFFC2410C),
      badge: null,
    ),
    (
      name: 'Backpack',
      subtitle: 'xNFT & Solana dApp ready',
      packageId: 'app.backpack.mobile',
      icon: Icons.backpack_rounded,
      color: Color(0xFFBE123C),
      badge: null,
    ),
  ];

  Future<void> _copyPlayStoreLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Play Store link copied — open it in your browser.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
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
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text('ClockIn', style: AppTypography.headlineSm),
                    ],
                  ),
                  const DevnetBadge(showProtocol: false),
                ],
              ),
              const SizedBox(height: 28),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.4), shape: BoxShape.circle),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 32, color: AppColors.primaryContainer),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'You\'ll need a wallet app first',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMd,
              ),
              const SizedBox(height: 8),
              Text(
                'ClockIn uses your wallet as your ID. Install one of these, then come back.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _wallets.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _walletTile(context, _wallets[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ClockIn never accesses your private keys or funds. Your wallet acts strictly as an unforgeable digital ID.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _copyPlayStoreLink(
                    context,
                    'https://play.google.com/store/search?q=solana%20wallet&c=apps',
                  ),
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: const Text('Install a wallet'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Copies the Play Store link — paste it in your browser.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onCheckAgain,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Already installed? Check again'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletTile(BuildContext context, ({String name, String subtitle, String packageId, IconData icon, Color color, String? badge}) wallet) {
    return InkWell(
      onTap: () => _copyPlayStoreLink(
        context,
        'https://play.google.com/store/apps/details?id=${wallet.packageId}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: wallet.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(wallet.icon, size: 16, color: wallet.color),
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
                      Text(wallet.name, style: AppTypography.titleMd),
                      if (wallet.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            wallet.badge!,
                            style: AppTypography.labelSm.copyWith(color: AppColors.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    wallet.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
