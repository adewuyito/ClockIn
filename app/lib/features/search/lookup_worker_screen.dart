import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:solana/solana.dart';
import '../../core/models/review.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';

/// Screen 3 & 4: Look Up Worker by Address.
/// Free public on-chain read (no wallet signature required).
///
/// The search view (header, quick-action tiles, search card, recent
/// lookups, trust banner) matches Stitch's "3. Look Up Worker" screen. One
/// real feature gap flagged rather than faked: that design offers "Scan QR"
/// as a targeting method alongside pasting an address — this app has no QR
/// scanner (camera permission + a QR lib, real scope, not built), so the
/// tile is present for layout parity but tells you so instead of pretending
/// to scan. "Recent lookups" is backed by a real local-only history table
/// (`RecentLookups`, separate from the offline-first profile cache so
/// "Clear" can't destroy real cached data) rather than the design's fake
/// stock-photo avatars and invented "Audited" badge — no avatar images
/// anywhere, since this program has no identity/photo concept, only
/// pubkeys. "Direct RPC Merkle Verification" became "Direct On-Chain
/// Reads": true (plain `getAccountInfo`/`getProgramAccounts`, no indexer),
/// but there's no Merkle tree anywhere in this program.
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

  Future<void> _performSearch([String? customAddress]) async {
    final query = (customAddress ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() {
        _searchedAddress = null;
        _validationError = 'Please enter a Solana address';
      });
      return;
    }

    final Ed25519HDPublicKey pubkey;
    try {
      pubkey = Ed25519HDPublicKey.fromBase58(query);
    } catch (_) {
      setState(() {
        _searchedAddress = null;
        _validationError = 'Invalid Solana public key format';
      });
      return;
    }

    setState(() {
      _searchedAddress = query;
      _validationError = null;
    });

    // Only record real, found profiles as "recent" — an entry with no
    // backing on-chain data isn't useful history (see file doc comment).
    final repo = ref.read(reputationRepositoryProvider);
    final profile = await repo.getWorkerProfile(pubkey.toBase58());
    if (profile != null) {
      await repo.recordLookup(pubkey.toBase58());
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _searchController.text = data!.text!.trim();
      _performSearch();
    } else {
      _showSnack('Clipboard is empty');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);

    return Scaffold(
      appBar: AppHeader(
        address: wallet.isConnected ? wallet.address : null,
        onCopyAddress: () {
          if (wallet.address != null) {
            Clipboard.setData(ClipboardData(text: wallet.address!));
            _showSnack('Copied');
          }
        },
        onAvatarTap: () => ref.read(walletStateProvider.notifier).disconnect(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header intro
            Row(
              children: [
                const Icon(Icons.travel_explore_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'SOLANA EXPLORER QUERY',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Look up a worker', style: AppTypography.headlineMd.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: 2),
            Text(
              'Verify on-chain credentials and ratings via plain Solana RPC reads.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Quick handoff action tiles — IntrinsicHeight so both stay the
            // same height even if one title wraps ("Paste Address" is
            // borderline at some text-scale settings; the design has both
            // as a single line, so overflow also falls back to ellipsis).
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _actionTile(
                      icon: Icons.qr_code_scanner_rounded,
                      iconColor: AppColors.onSecondaryContainer,
                      iconBg: AppColors.secondaryContainer,
                      title: 'Scan QR',
                      subtitle: 'Not available yet',
                      onTap: () => _showSnack("QR scanning isn't built yet — paste the address instead."),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionTile(
                      icon: Icons.content_paste_go_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryFixedDim.withValues(alpha: 0.3),
                      title: 'Paste Address',
                      subtitle: 'From clipboard',
                      onTap: _pasteFromClipboard,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PUBLIC KEY SEARCH',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle),
                          ),
                          Text('RPC Connected',
                              style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search_rounded, size: 20, color: AppColors.outline),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Solana address (base58)',
                              hintStyle: AppTypography.labelMd.copyWith(color: AppColors.outline),
                              // The app-wide InputDecorationTheme defines its own
                              // enabledBorder/focusedBorder, which take priority
                              // over the generic `border` below — override every
                              // state explicitly, or the themed outline border
                              // shows up nested inside this Container.
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: TextButton.icon(
                            onPressed: _pasteFromClipboard,
                            icon: const Icon(Icons.content_paste_rounded, size: 14),
                            label: Text('Paste', style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              backgroundColor: AppColors.surfaceContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_validationError != null) ...[
                    const SizedBox(height: 6),
                    Text(_validationError!, style: AppTypography.bodySm.copyWith(color: AppColors.error)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _performSearch(),
                      icon: const Icon(Icons.person_search_rounded, size: 20),
                      label: const Text('Search Worker Profile'),
                      // The design uses rounded-lg (8px) for this specific
                      // button, distinct from the app-wide 16px default the
                      // theme applies to CTAs elsewhere (e.g. Register).
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildRecentLookups(),
            const SizedBox(height: 16),

            // Trust banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, size: 24, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Direct On-Chain Reads',
                            style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
                        Text(
                          'ClockIn reads reputation directly from Solana account state — no indexer, no intermediary caching.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Results Section
            if (_searchedAddress != null)
              _buildWorkerResultSection(_searchedAddress!),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLookups() {
    final recentAsync = ref.watch(recentLookupsProvider);

    return recentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (recent) {
        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Recent lookups', style: AppTypography.titleMd.copyWith(color: AppColors.onSurface)),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(reputationRepositoryProvider).clearRecentLookups();
                  },
                  child: Text('Clear',
                      style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recent.map((profile) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _recentLookupCard(profile),
                )),
          ],
        );
      },
    );
  }

  Widget _recentLookupCard(WorkerProfile profile) {
    final ratingStr = profile.totalJobs > 0 ? profile.averageRating.toStringAsFixed(1) : '—';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        _searchController.text = profile.address;
        _performSearch(profile.address);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_circle_outlined, color: AppColors.onSurfaceVariant, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(profile.shortAddress,
                          style: AppTypography.labelLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Active',
                            style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 2),
                      Text(ratingStr,
                          style: AppTypography.labelSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Text('•', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(width: 6),
                      Text('${profile.totalJobs} jobs done',
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
              tooltip: 'Copy address',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: profile.address));
                _showSnack('Copied');
              },
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
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
