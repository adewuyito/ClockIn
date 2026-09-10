import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:solana/solana.dart';
import '../../core/models/review.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/devnet_badge.dart';

/// Screen 3 & 4: Look Up Worker by Address.
/// Free public on-chain read (no wallet signature required).
class LookupWorkerScreen extends ConsumerStatefulWidget {
  final void Function(String workerAddress)? onSelectWorkerForReview;

  const LookupWorkerScreen({super.key, this.onSelectWorkerForReview});

  @override
  ConsumerState<LookupWorkerScreen> createState() => _LookupWorkerScreenState();
}

class _LookupWorkerScreenState extends ConsumerState<LookupWorkerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchedAddress;
  String? _validationError;

  void _performSearch([String? customAddress]) {
    final query = (customAddress ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() {
        _searchedAddress = null;
        _validationError = 'Please enter a Solana address';
      });
      return;
    }

    try {
      // Validate Base58 Solana public key
      Ed25519HDPublicKey.fromBase58(query);
      setState(() {
        _searchedAddress = query;
        _validationError = null;
      });
    } catch (_) {
      setState(() {
        _searchedAddress = null;
        _validationError = 'Invalid Solana public key format';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _searchController.text = data!.text!.trim();
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Look Up Worker'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: DevnetBadge(showProtocol: false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Public Attestation Lookup',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Search Bar & Paste
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter Solana worker address…',
                prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, color: AppColors.primary),
                  tooltip: 'Paste address',
                  onPressed: _pasteFromClipboard,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),

            if (_validationError != null) ...[
              const SizedBox(height: 6),
              Text(
                _validationError!,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _performSearch(),
              child: const Text('Search On-Chain'),
            ),

            const SizedBox(height: 24),

            // Search Results Section
            if (_searchedAddress != null)
              _buildWorkerResultSection(_searchedAddress!),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerResultSection(String address) {
    final profileAsync = ref.watch(workerProfileProvider(address));
    final reviewsAsync = ref.watch(workerReviewsProvider(address));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        profileAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Lookup error: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.person_off_outlined,
                          size: 36, color: AppColors.outline),
                      const SizedBox(height: 10),
                      const Text(
                        'Worker Not Registered',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This address ($address) has not initialized a worker profile on Devnet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkerCard(profile),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Review This Worker'),
                  onPressed: () {
                    widget.onSelectWorkerForReview?.call(profile.address);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Reviews & Attestations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                reviewsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No reviews found for this worker.',
                              style: TextStyle(color: AppColors.outline),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _buildReviewCard(reviews[i]),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkerCard(WorkerProfile profile) {
    final ratingStr = profile.totalJobs > 0
        ? profile.averageRating.toStringAsFixed(1)
        : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'sol:${profile.shortAddress}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.totalJobs} jobs logged',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        ratingStr,
                        style: const TextStyle(
                          fontSize: 14,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${DateFormat.yMMMd().format(profile.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.outline),
                ),
                const Text(
                  'Verified via Anchor',
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
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'From: sol:${review.shortReviewerAddress}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: List.generate(5, (star) {
                    return Icon(
                      star < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 15,
                      color: star < review.rating
                          ? AppColors.success
                          : AppColors.outlineVariant,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Job: ${review.jobId}',
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
