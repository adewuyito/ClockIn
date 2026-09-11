import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/review.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/reputation_errors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';

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
  ReputationErrorKind? _txErrorKind;

  static IconData _txErrorIcon(ReputationErrorKind? kind) {
    switch (kind) {
      case ReputationErrorKind.network:
        return Icons.wifi_off_rounded;
      case ReputationErrorKind.walletRejected:
        return Icons.account_balance_wallet_outlined;
      case ReputationErrorKind.programRejected:
        return Icons.block_rounded;
      case ReputationErrorKind.unknown:
      case null:
        return Icons.error_outline_rounded;
    }
  }

  Future<void> _handleRegister() async {
    final wallet = ref.read(walletStateProvider);
    if (!wallet.isConnected || wallet.publicKey == null) return;

    setState(() {
      _isRegistering = true;
      _txError = null;
      _txErrorKind = null;
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
      final err = ReputationException.from(e);
      if (mounted) {
        setState(() {
          _txError = err.message;
          _txErrorKind = err.kind;
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

    return Scaffold(
      appBar: AppHeader(
        address: address,
        onCopyAddress: () => _copyAddress(_shorten(address), feedback: 'Copied'),
        onAvatarTap: () => ref.read(walletStateProvider.notifier).disconnect(),
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
          child: profileAsync.when(
            loading: () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityPill(address, false, null),
                const SizedBox(height: 20),
                _buildSkeletonCard(),
              ],
            ),
            error: (err, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityPill(address, false, null),
                const SizedBox(height: 20),
                _buildErrorCard(err.toString()),
              ],
            ),
            data: (profile) {
              // Not registered: matches Stitch's "2b. My Profile (Not
              // Registered)" screen, which is a self-contained onboarding
              // card — no identity pill, no reviews section, no pro tip.
              // Those only make sense once a WorkerProfile actually exists;
              // showing "share your address for reviews" before there's
              // even a profile to attach them to would be confusing.
              if (profile == null) {
                return _buildNotRegisteredCard(address);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentityPill(address, true, profile),
                  const SizedBox(height: 20),
                  _buildHeroCard(profile),
                  const SizedBox(height: 20),
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
                  _buildProTipCard(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
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
          if (profile.syncedAt != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sync_rounded, size: 12, color: AppColors.outline),
                const SizedBox(width: 4),
                Text(
                  'Synced ${_relativeTime(profile.syncedAt!)} · pull to refresh',
                  style: AppTypography.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ],
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

  /// Matches Stitch's "2b. My Profile (Not Registered)" screen. Two pieces
  /// of that design's copy were changed rather than copied verbatim:
  /// "Zero gas required" is false — every Solana transaction, including
  /// this one, has a real fee and needs rent for the new account (the
  /// exact thing that blocked registration earlier in this project until
  /// the test wallet was funded); and "Deliver work or shift shifts" (a
  /// typo in the source design) leaned on shift/time-tracking language
  /// that doesn't match this program's actual model — reviews tied to a
  /// job, not shifts.
  Widget _buildNotRegisteredCard(String address) {
    final short = _shorten(address);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Onboarding indicator row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'SET UP YOUR REPUTATION RECORD',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Takes a few seconds',
                    style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                const SizedBox(width: 2),
                const Icon(Icons.bolt_rounded, size: 14, color: AppColors.outline),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Hero onboarding card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Column(
            children: [
              // Icon cluster
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_rounded, size: 38, color: AppColors.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule_rounded, size: 15, color: AppColors.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "You haven't started your reputation record yet",
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'This is a one-time step so people can leave you verified reviews after jobs.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Benefit tickers
              Row(
                children: [
                  Expanded(
                    child: _benefitTicker(
                      Icons.fingerprint_rounded,
                      AppColors.primary,
                      'Decentralized',
                      'Stored on Solana',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _benefitTicker(
                      Icons.verified_rounded,
                      AppColors.tertiary,
                      'Tamper Proof',
                      'On-chain, signature-gated',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_txError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_txErrorIcon(_txErrorKind), size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_txError!, style: AppTypography.bodySm.copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                  ),
                  child: _isRegistering
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text('Opening wallet…', style: AppTypography.titleMd.copyWith(color: Colors.white)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Create my record', style: AppTypography.titleMd.copyWith(color: Colors.white)),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Text("You'll approve this in your wallet app.",
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // "Why create a record?" mini-card
        Text('Why create a record?', style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
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
            children: [
              _whyRow(Icons.handshake_rounded, AppColors.primary, 'Deliver work for clients or DAOs',
                  'Complete a job the same way you always have'),
              const SizedBox(height: 14),
              _whyRow(Icons.rate_review_rounded, AppColors.secondary, 'Receive verifiable feedback',
                  "Reviews are cryptographically anchored to your key"),
              const SizedBox(height: 14),
              _whyRow(Icons.card_membership_rounded, AppColors.tertiary, 'Carry your pass anywhere',
                  'Portable reputation, readable by anyone on Solana'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Signing wallet summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.key_rounded, size: 18, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SIGNING WALLET',
                          style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.6)),
                      Text(short,
                          style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text('Ready to bind', style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _benefitTicker(IconData icon, Color color, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whyRow(IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
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
