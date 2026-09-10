import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/review.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/devnet_badge.dart';

/// Screen 2: My Profile (Loaded, Not Registered, Loading Skeleton, Empty Reviews).
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

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);
    final profileAsync = ref.watch(myProfileProvider);

    if (!wallet.isConnected || wallet.address == null) {
      return const Center(child: Text('Wallet not connected'));
    }

    final reviewsAsync = ref.watch(workerReviewsProvider(wallet.address!));

    return Scaffold(
      appBar: AppBar(
        title: const DevnetBadge(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Disconnect wallet',
            onPressed: () => ref.read(walletStateProvider.notifier).disconnect(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final repo = ref.read(reputationRepositoryProvider);
          await Future.wait([
            repo.refreshWorkerProfile(wallet.address!),
            repo.refreshWorkerReviews(wallet.address!),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address & Copy pill
              _buildAddressPill(wallet.address!),
              const SizedBox(height: 16),

              // Profile State handling
              profileAsync.when(
                loading: () => _buildSkeletonCard(),
                error: (err, _) => _buildErrorCard(err.toString()),
                data: (profile) {
                  if (profile == null) {
                    // Screen 2b: Not Registered Yet
                    return _buildNotRegisteredCard();
                  }

                  // Screen 2: Loaded Profile Hero Card
                  return _buildProfileHero(profile);
                },
              ),
              const SizedBox(height: 24),

              // Section Title: Reviews
              const Text(
                'Work History & Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Reviews list handling (Screen 2d: No Reviews)
              reviewsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Text(
                  'Failed to load reviews: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return _buildEmptyReviewsCard();
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildReviewCard(reviews[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPill(String address) {
    final short =
        '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'sol:$short',
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Address copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(WorkerProfile profile) {
    final ratingStr = profile.totalJobs > 0
        ? profile.averageRating.toStringAsFixed(1)
        : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          ratingStr,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star_rounded,
                          size: 32,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.totalJobs} verified jobs completed',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 36,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.outline),
                    const SizedBox(width: 6),
                    Text(
                      'Active since ${DateFormat.yMMMd().format(profile.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.outline),
                    ),
                  ],
                ),
                if (profile.syncedAt != null)
                  Text(
                    'Synced: ${DateFormat.Hm().format(profile.syncedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotRegisteredCard() {
    return Card(
      color: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                const Text(
                  'Not Registered as a Worker',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Register your Solana address to start collecting portable ratings and verifiable proofs of work on-chain.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
            if (_txError != null) ...[
              const SizedBox(height: 12),
              Text(
                _txError!,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isRegistering ? null : _handleRegister,
              child: _isRegistering
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Register On-Chain'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 36, color: AppColors.surfaceContainerHigh),
            const SizedBox(height: 12),
            Container(width: 180, height: 16, color: AppColors.surfaceContainerHigh),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error loading profile: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildEmptyReviewsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 40, color: AppColors.outline),
              const SizedBox(height: 12),
              const Text(
                'No reviews logged yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completed jobs and ratings from clients will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: starIndex < review.rating
                          ? AppColors.success
                          : AppColors.outlineVariant,
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
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat.yMMMd().format(review.timestamp),
                style: const TextStyle(fontSize: 11, color: AppColors.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
