import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/review.dart';
import '../../core/models/seeker_attestation.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/device_service.dart';
import '../../core/solana/reputation_errors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/profile_qr_sheet.dart';
import '../../core/widgets/seeker_logo.dart';
import 'seeker_staking_sheet.dart';

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
    final attestationAsync = ref.watch(seekerAttestationProvider(address));

    return Scaffold(
      appBar: AppHeader(
        address: address,
        onCopyAddress: () => _copyAddress(_shorten(address), feedback: 'Copied'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final repo = ref.read(reputationRepositoryProvider);
          final attestationRepo = ref.read(attestationRepositoryProvider);
          await Future.wait([
            repo.refreshWorkerProfile(address),
            repo.refreshWorkerReviews(address),
            attestationRepo.getAttestation(address),
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

              final attestation = attestationAsync.valueOrNull ??
                  SeekerAttestation(
                    address: address,
                    isAttested: false,
                    syncedAt: DateTime.now(),
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentityPill(address, true, profile),
                  const SizedBox(height: 14),
                  _buildSeekerStakingCard(address, attestation),
                  const SizedBox(height: 14),
                  _buildHeroCard(profile, attestation),
                  const SizedBox(height: 16),
                  ProfileQrCard(
                    address: address,
                    isRegistered: true,
                    title: 'Reputation Pass QR',
                    subtitle: 'Scan with ClockIn, Phantom, or Solflare to verify reputation or hire.',
                    isCompact: true,
                  ),
                  const SizedBox(height: 16),
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

  /// Initials from the wallet's account label ("Solana Test Wallet" → "ST"),
  /// falling back to the address's first two characters when the wallet
  /// doesn't provide a label.
  static String _walletInitials(String? label, String address) {
    final words = (label ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(w[0]))
        .toList();
    if (words.isNotEmpty) {
      return words.take(2).map((w) => w[0]).join().toUpperCase();
    }
    return address.length >= 2 ? address.substring(0, 2).toUpperCase() : '?';
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
                alignment: Alignment.center,
                child: Text(
                  _walletInitials(ref.watch(walletStateProvider).accountLabel, address),
                  style: AppTypography.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ProfileQrSheet.show(
              context,
              address: address,
              label: 'My Reputation Pass',
              isRegistered: isRegistered,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekerStakingCard(String address, SeekerAttestation attestation) {
    final isAttested = attestation.isAttested;
    final seekerDevice = ref.watch(seekerDeviceProvider);
    final isSeekerHardware = seekerDevice.isSeeker;
    final stakeDisplay = attestation.stakedAmount >= 1.0
        ? '${attestation.stakedAmount.toStringAsFixed(0)} \$SKR'
        : r'250 $SKR';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAttested ? const Color(0xFFE8F8F0) : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAttested
              ? const Color(0xFF1F9D5B).withValues(alpha: 0.35)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SeekerLogo(
                size: 16,
                isActive: isSeekerHardware,
                withGlow: isSeekerHardware,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isAttested ? 'SEEKER ATTESTED' : 'SEEKER VERIFICATION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isAttested ? const Color(0xFF0B5E36) : AppColors.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                // Status is read from Solana Mobile's staking program, so it
                // can't be toggled here — the sheet shows the live stake and
                // links to stake.solanamobile.com to change it.
                onTap: () {
                  HapticFeedback.selectionClick();
                  SeekerStakingSheet.show(context, address: address);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isAttested ? const Color(0xFFD1F2DE) : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isAttested
                          ? const Color(0xFF1F9D5B).withValues(alpha: 0.35)
                          : AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          color: isAttested ? const Color(0xFF1F9D5B) : AppColors.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4.5),
                      Text(
                        isAttested ? 'Stake Active' : 'Unverified',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isAttested ? const Color(0xFF0B5E36) : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isSeekerHardware || isAttested) ...[
            const SizedBox(height: 7),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (isSeekerHardware)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14F195).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF00D18C).withValues(alpha: 0.4),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      'SEEKER HARDWARE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B5E36),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                if (isAttested) ...[
                  _buildCompactPill('$stakeDisplay Staked'),
                  const Text('•', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  _buildCompactPill('Guardian: ${attestation.guardianName}'),
                ],
              ],
            ),
          ],
          if (!isAttested) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    r'Verify 250 $SKR Guardian stake for proof-of-human badge.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    SeekerStakingSheet.show(context, address: address);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F9D5B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(60, 30),
                    maximumSize: const Size(double.infinity, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Plus Jakarta Sans carries a tall ascent; height 1 with even
                  // leading keeps the label optically centred in the button.
                  child: Text(
                    'Stake',
                    textHeightBehavior: const TextHeightBehavior(
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF1F9D5B).withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0B5E36),
        ),
      ),
    );
  }

  Widget _buildHeroCard(WorkerProfile profile, SeekerAttestation attestation) {
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
                Expanded(
                  child: _trustMetaColumn(
                    'REGISTERED',
                    DateFormat.yMd().format(profile.createdAt),
                    color: AppColors.onSurface,
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.surfaceContainerHighest),
                Expanded(
                  child: _trustMetaColumn(
                    'ON-CHAIN',
                    'Verified',
                    color: AppColors.tertiary,
                    showDot: true,
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.surfaceContainerHighest),
                Expanded(
                  child: _trustMetaColumn(
                    'GUARDIAN',
                    attestation.isAttested
                        ? (attestation.stakedAmount >= 1.0
                            ? '${attestation.stakedAmount.toStringAsFixed(0)} \$SKR'
                            : r'250 $SKR')
                        : 'Unstaked',
                    color: attestation.isAttested ? const Color(0xFF1F9D5B) : AppColors.outline,
                    showDot: attestation.isAttested,
                  ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
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
        const SizedBox(height: 16),
        ProfileQrCard(
          address: address,
          isRegistered: false,
          title: 'Wallet Address QR',
          subtitle: 'Scan with ClockIn, Solflare, or Phantom to view address or transfer Devnet SOL.',
          isCompact: true,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rate_review_outlined, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No reviews yet',
                      style: AppTypography.titleMd.copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share your QR code above with a client or DAO you worked with to receive verified feedback.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ProfileQrSheet.show(
                    context,
                    address: address,
                    label: 'My Reputation Pass',
                  ),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Enlarge QR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyAddress(address, feedback: 'Address copied — share it with your client'),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share address'),
                ),
              ),
            ],
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
          if (review.reviewNote != null && review.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.25)),
              ),
              child: Text(
                '“${review.reviewNote!}”',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
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
                  if (review.hasArweaveProvenance) ...[
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: 'https://gateway.irys.xyz/${review.arweaveTxId}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied Arweave permaweb link to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_done_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Arweave Permaweb',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                DateFormat.yMMMd().format(review.timestamp),
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
