import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/review.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Screen 4a/4b: Worker Profile (Loaded / Not Registered) — pushed from
/// the Look Up screen after a successful search, matching how Stitch
/// scoped it as its own screen (own back-button header, own sticky CTA)
/// rather than content stacked below the search box.
///
/// Matches Stitch's "4a. Worker Profile (Loaded)" screen, with the same
/// discipline applied to the rest of this app: real data kept real,
/// fabricated data dropped or replaced with what this program actually
/// records.
///
/// - "Completion: 100%" / "Epoch Attestations: 684" -> "Registered [date]"
///   / "On-Chain · Verified" (same pattern as MyProfileScreen's hero
///   card). This program has no completion-percentage or epoch-attestation
///   concept for a worker — `total_jobs` simply *is* the review count
///   (every `submit_review` increments it by exactly 1; there's no
///   separate "mark complete" step), so a completion percentage isn't a
///   real, independently-measurable fact here.
/// - Review comments ("Very professional...") are entirely fabricated —
///   `Review` (program/programs/reputation/src/lib.rs) has no text field:
///   worker, reviewer, job_id, rating, timestamp, bump, nothing else.
///   Shown instead: reviewer address, rating, job ID, relative time —
///   everything this program actually stores.
/// - No avatar photos — this program has no identity/photo concept, only
///   pubkeys (see the "Worker identity" non-goal in ARCHITECTURE.md).
/// - "Load more reviews" genuinely reveals more of the list already
///   fetched in one RPC call (`getProgramAccounts` returns every Review
///   account at once — there's no server-side pagination to fake) rather
///   than replaying the source design's fake "Fetching on-chain
///   attestations..." network-call animation.
class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({
    super.key,
    required this.address,
    this.onSelectWorkerForReview,
  });

  final String address;
  final void Function(String workerAddress)? onSelectWorkerForReview;

  @override
  ConsumerState<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen> {
  static const int _pageSize = 4;
  int _visibleCount = _pageSize;

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 2)),
    );
  }

  static String _shorten(String address) =>
      '${address.substring(0, 4)}…${address.substring(address.length - 4)}';

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(workerProfileProvider(widget.address));
    final reviewsAsync = ref.watch(workerReviewsProvider(widget.address));
    final isRegistered = profileAsync.valueOrNull != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, isRegistered ? 100 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityBanner(),
                    const SizedBox(height: 16),
                    profileAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => _buildErrorCard(err.toString()),
                      data: (profile) {
                        if (profile == null) return _buildNotRegisteredCard();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroCard(profile),
                            const SizedBox(height: 20),
                            reviewsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              error: (err, _) => Text('Failed to load reviews: $err',
                                  style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
                              data: (reviews) => _buildReviewsSection(profile, reviews),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isRegistered ? _buildLeaveReviewBar(context) : null,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _copy(widget.address, 'Address'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(_shorten(widget.address),
                        style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.outline),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
                Text('DEVNET',
                    style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.badge_rounded, size: 18, color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INDEPENDENT WORKER',
                      style: AppTypography.labelSm.copyWith(color: AppColors.outline, letterSpacing: 0.6)),
                  Text('ClockIn Reputation Pass',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
            child: Text('Public View', style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(WorkerProfile profile) {
    final ratingStr = profile.totalJobs > 0 ? profile.averageRating.toStringAsFixed(1) : null;
    final fullStars = profile.totalJobs > 0 ? profile.averageRating.round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppColors.tertiary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 16, color: AppColors.tertiary),
                const SizedBox(width: 6),
                Text('VERIFIED ON-CHAIN',
                    style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (ratingStr != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(ratingStr,
                    style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface, fontSize: 48, height: 1)),
                const SizedBox(width: 4),
                Text('/ 5.0', style: AppTypography.titleMd.copyWith(color: AppColors.outline)),
              ],
            )
          else
            Text('No rating yet', style: AppTypography.headlineMd.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                i < fullStars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 26,
                color: i < fullStars ? AppColors.success : AppColors.outlineVariant,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text('${profile.totalJobs} jobs reviewed', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('REGISTERED', style: AppTypography.labelSm.copyWith(color: AppColors.outline, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.createdAt.year}-${profile.createdAt.month.toString().padLeft(2, '0')}-${profile.createdAt.day.toString().padLeft(2, '0')}',
                      style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(width: 1, height: 24, color: AppColors.surfaceContainerHighest),
                Column(
                  children: [
                    Text('ON-CHAIN', style: AppTypography.labelSm.copyWith(color: AppColors.outline, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 4), decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle)),
                        Text('Verified', style: AppTypography.labelMd.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotRegisteredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
            child: const Icon(Icons.person_off_outlined, size: 28, color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          Text('This address hasn\'t registered yet',
              textAlign: TextAlign.center, style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 6),
          Text(
            'There\'s no ClockIn reputation record for this address on ${_shorten(widget.address)} — nothing has been registered on-chain.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
          ),
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
      child: Text('Lookup error: $error', style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
    );
  }

  Widget _buildReviewsSection(WorkerProfile profile, List<Review> reviews) {
    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Center(
          child: Text('No reviews yet for this worker.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    final visible = reviews.take(_visibleCount).toList();
    final hasMore = _visibleCount < reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('All reviews', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
            Text('Showing ${visible.length} of ${reviews.length}',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.surfaceContainer),
                _buildReviewTile(visible[i]),
              ],
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _visibleCount += _pageSize),
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      label: const Text('Load more reviews'),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLow,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTile(Review review) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
            child: const Icon(Icons.account_circle_outlined, size: 20, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.shortReviewerAddress,
                        style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 15,
                          color: i < review.rating ? AppColors.success : AppColors.outlineVariant,
                        );
                      }),
                    ),
                  ],
                ),
                Text(_relativeTime(review.timestamp), style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(6)),
                  child: Text('Job: ${review.jobId}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveReviewBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            final onSelect = widget.onSelectWorkerForReview;
            if (onSelect != null) {
              Navigator.of(context).pop();
              onSelect(widget.address);
            }
          },
          icon: const Icon(Icons.rate_review_rounded, size: 20),
          label: const Text('Leave a review'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
