import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/review.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Screen 2: My Profile (Loaded, Not Registered, Loading Skeleton, Empty Reviews).
///
/// Visually matches the Stitch design ("Clock-In Screen Refinement" project,
/// screen "2d. My Profile (No Reviews)") — see CLAUDE.md for the project
/// link. Two pieces of that design's copy don't map to anything this app's
/// program actually tracks and were swapped for real equivalents rather
/// than shipped as-is: "Merkle Proof: Valid" (there's no Merkle tree
/// anywhere in this program — PDAs, not a Merkle-anchored credential) and
/// "Epoch 648 Active" (WorkerProfile has no epoch field; the network epoch
/// isn't a fact about this specific worker). Both became "Registered
/// [date]" / "On-Chain · Verified", which are things this app can actually
/// prove.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isRegistering = false;
  String? _txError;

  Future<void> _handleRegister() async {
    final wallet = ref.read(walletStateProvider);
    if (!wallet.isConnected || wallet.publicKey == null) return;

    setState(() {
      _isRegistering = true;
      _txError = null;
    });

    try {
      final repo = ref.read(reputationRepositoryProvider);
      final adapter = ref.read(walletAdapterProvider);

      await repo.registerWorker(
        worker: wallet.publicKey!,
        walletAdapter: adapter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Successfully registered worker on Solana Devnet!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _txError = 'Registration failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _copyAddress(String address, {String feedback = 'Address copied to clipboard'}) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(feedback), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);
    final profileAsync = ref.watch(myProfileProvider);

    if (!wallet.isConnected || wallet.address == null) {
      return const Center(child: Text('Wallet not connected'));
    }

    final address = wallet.address!;
    final reviewsAsync = ref.watch(workerReviewsProvider(address));
    final isRegistered = profileAsync.valueOrNull != null;

    return Scaffold(
      appBar: _ProfileHeader(
        address: address,
        onCopyAddress: () => _copyAddress(_shorten(address), feedback: 'Copied'),
        onDisconnect: () => ref.read(walletStateProvider.notifier).disconnect(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final repo = ref.read(reputationRepositoryProvider);
          await Future.wait([
            repo.refreshWorkerProfile(address),
            repo.refreshWorkerReviews(address),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identity pill
              _buildIdentityPill(address, isRegistered, profileAsync.valueOrNull),
              const SizedBox(height: 20),

              // Profile state handling
              profileAsync.when(
                loading: () => _buildSkeletonCard(),
                error: (err, _) => _buildErrorCard(err.toString()),
                data: (profile) {
                  if (profile == null) {
                    return _buildNotRegisteredCard();
                  }
                  return _buildHeroCard(profile);
                },
              ),
              const SizedBox(height: 20),

              // Reviews section
              reviewsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Text(
                  'Failed to load reviews: $err',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return _buildEmptyReviewsCard(address);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work History & Reviews',
                        style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Pro tip card
              _buildProTipCard(),
            ],
          ),
        ),
      ),
    );
  }

  static String _shorten(String address) =>
      '${address.substring(0, 4)}…${address.substring(address.length - 4)}';

  Widget _buildIdentityPill(String address, bool isRegistered, WorkerProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_circle_outlined,
                    color: AppColors.primary, size: 26),
              ),
              if (isRegistered)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceContainerLow, width: 2),
                    ),
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
                        'Solana Contributor',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                      ),
                    ),
                    if (isRegistered) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, size: 18, color: AppColors.tertiary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isRegistered && profile != null
                      ? 'Solana Devnet • Registered ${DateFormat.yMMMd().format(profile.createdAt)}'
                      : 'Solana Devnet • Not registered',
                  style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _copyAddress(address, feedback: 'Copied'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _shorten(address),
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(WorkerProfile profile) {
    final ratingStr = profile.totalJobs > 0
        ? profile.averageRating.toStringAsFixed(1)
        : null;
    final fullStars = profile.totalJobs > 0 ? profile.averageRating.round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          // Verified on-chain badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.tertiary),
                const SizedBox(width: 6),
                Text(
                  'VERIFIED ON-CHAIN',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ratingStr ?? 'No rating yet',
            style: AppTypography.headlineMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                i < fullStars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 24,
                color: i < fullStars ? AppColors.success : AppColors.outlineVariant,
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.totalJobs} jobs reviewed',
            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          // Trust meta bar — real facts only, see file-level doc comment.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _trustMetaColumn(
                  'REGISTERED',
                  DateFormat.yMd().format(profile.createdAt),
                  color: AppColors.onSurface,
                ),
                Container(width: 1, height: 24, color: AppColors.surfaceContainerHighest),
                _trustMetaColumn(
                  'ON-CHAIN',
                  'Verified',
                  color: AppColors.tertiary,
                  showDot: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustMetaColumn(String label, String value, {required Color color, bool showDot = false}) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.outline,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
            Text(
              value,
              style: AppTypography.labelMd.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotRegisteredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Not Registered as a Worker',
                  style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Register your Solana address to start collecting portable ratings and verifiable proofs of work on-chain.',
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          if (_txError != null) ...[
            const SizedBox(height: 12),
            Text(_txError!, style: AppTypography.bodySm.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _isRegistering ? null : _handleRegister,
            child: _isRegistering
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Register On-Chain'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 120, height: 36, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 12),
          Container(width: 180, height: 16, color: AppColors.surfaceContainerHigh),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Text(
        'Error loading profile: $error',
        style: AppTypography.bodyMd.copyWith(color: AppColors.error),
      ),
    );
  }

  Widget _buildEmptyReviewsCard(String address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 32, color: AppColors.primary),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            "Share your address with someone you've worked with to get your first review.",
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copyAddress(address, feedback: 'Address copied — share it with your client'),
              icon: const Icon(Icons.share_rounded, size: 20),
              label: const Text('Share address'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solana Devnet Identity',
                        style: AppTypography.labelSm.copyWith(color: AppColors.outline),
                      ),
                      Text(
                        address,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _copyAddress(address, feedback: 'Copied!'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildProTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.tertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro tip for builders',
                  style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  "ClockIn reviews are non-transferable proof of delivery. When clients submit a review, it's cryptographically anchored to your Solana identity — permanently, and only once per job.",
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.5),
                    child: const Icon(Icons.person, size: 16, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'sol:${review.shortReviewerAddress}',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: starIndex < review.rating ? AppColors.success : AppColors.outlineVariant,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Job ID: ${review.jobId}',
              style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              DateFormat.yMMMd().format(review.timestamp),
              style: AppTypography.bodySm.copyWith(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky header matching the Stitch design: wordmark + tagline, a pulsing
/// "DEVNET" chip, a tappable short-address pill, and an avatar action that
/// disconnects the wallet.
class _ProfileHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileHeader({
    required this.address,
    required this.onCopyAddress,
    required this.onDisconnect,
  });

  final String address;
  final VoidCallback onCopyAddress;
  final VoidCallback onDisconnect;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final short = '${address.substring(0, 4)}…${address.substring(address.length - 4)}';

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ClockIn',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
              Text(
                'SOLANA PASS',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.outline,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'DEVNET',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onCopyAddress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.outline),
                const SizedBox(width: 4),
                Text(short, style: AppTypography.labelSm.copyWith(color: AppColors.onSurface)),
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded, size: 14, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          tooltip: 'Disconnect wallet',
          onPressed: onDisconnect,
        ),
      ],
    );
  }
}
