import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:solana/solana.dart';
import '../../core/models/worker_profile.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/network_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_header.dart';

/// Screen 5 / 5b / 5e: Submit Review (form, self-review-blocked, success).
///
/// Fidelity notes vs. the Stitch designs:
/// - The worker "identity preview" card in the design shows a fabricated
///   name ("Alex Rivera"), a stock photo, and a "Solana Guild Contributor •
///   Tier 1" credential — none of that exists on `WorkerProfile` (see the
///   worker-identity Non-goal in docs/ARCHITECTURE.md). Replaced with a
///   generic avatar and the worker's real on-chain stats (registered date,
///   review count, average rating), fetched live via `workerProfileProvider`
///   as the address is typed. This also lets the form warn before
///   submitting to an address that isn't registered yet — the program's
///   `NotRegistered` error would otherwise reject the transaction only
///   after a full wallet round-trip.
/// - The design's Review Note helper text ("This feedback will be anchored
///   immutably to the worker's on-chain trust score") is false — `Review`
///   has no text field. The note stays a local-only field with honest copy
///   explaining it never leaves the device.
/// - 5e's "Slot #289104821" is a fabricated proof detail; dropped in favor
///   of "confirmed just now", which is actually true immediately post-submit.
/// - "View on explorer" copies the explorer URL to the clipboard rather than
///   opening it directly — the same `url_launcher`-avoidance decision made
///   for the Connect Wallet screens, kept consistent across the app.
/// - The design's fake two-stage submit animation (a `setTimeout` flipping
///   to "Submitted & Inscribed!" regardless of outcome) was replaced with a
///   single honest "Requesting MWA Signature…" state tied to the real
///   in-flight `submitReview` call.
class SubmitReviewScreen extends ConsumerStatefulWidget {
  final String? initialWorkerAddress;

  const SubmitReviewScreen({super.key, this.initialWorkerAddress});

  @override
  ConsumerState<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  late final TextEditingController _workerController;
  late final TextEditingController _jobIdController;
  late final TextEditingController _notesController;

  static const _ratingTierLabels = {
    1: 'Critical Deficits',
    2: 'Below Expectations',
    3: 'Standard Delivery',
    4: 'Exceeded Targets',
    5: 'Exceptional Quality',
  };

  int _rating = 5;
  bool _isSubmitting = false;
  String? _txError;

  // Captured at the moment of a successful submit, since the input fields
  // get cleared once the user taps "Done" on the success screen.
  String? _successTxSignature;
  String? _successWorkerAddress;
  String? _successJobId;
  int _successRating = 5;

  @override
  void initState() {
    super.initState();
    _workerController = TextEditingController(text: widget.initialWorkerAddress ?? '');
    _jobIdController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SubmitReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent shell reuses this widget across tab switches, so a new
    // prefilled address (from "Leave a review" elsewhere in the app) only
    // arrives as an updated prop, not a fresh initState.
    if (widget.initialWorkerAddress != null &&
        widget.initialWorkerAddress != oldWidget.initialWorkerAddress) {
      _workerController.text = widget.initialWorkerAddress!;
    }
  }

  @override
  void dispose() {
    _workerController.dispose();
    _jobIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  static String? _parseAddress(String raw) {
    if (raw.isEmpty) return null;
    try {
      Ed25519HDPublicKey.fromBase58(raw);
      return raw;
    } catch (_) {
      return null;
    }
  }

  static String _shorten(String address) =>
      '${address.substring(0, 4)}…${address.substring(address.length - 4)}';

  void _copy(String text, String feedback) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }

  Future<void> _switchConnectedWallet() async {
    final notifier = ref.read(walletStateProvider.notifier);
    await notifier.disconnect();
    await notifier.connect();
  }

  Future<void> _handleSubmit(WorkerProfile? targetProfile) async {
    final wallet = ref.read(walletStateProvider);
    if (!wallet.isConnected || wallet.publicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your wallet first.')),
      );
      return;
    }

    final workerAddress = _workerController.text.trim();
    final jobId = _jobIdController.text.trim();

    if (_parseAddress(workerAddress) == null) {
      setState(() => _txError = 'Enter a valid worker Solana address.');
      return;
    }
    if (jobId.isEmpty) {
      setState(() => _txError = 'Job reference is required.');
      return;
    }
    if (jobId.length > 32) {
      setState(() => _txError = 'Job reference must be 32 characters or fewer.');
      return;
    }
    if (targetProfile == null) {
      setState(() => _txError = 'This worker hasn\'t registered on-chain yet.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _txError = null;
    });

    try {
      final workerPubkey = Ed25519HDPublicKey.fromBase58(workerAddress);
      final repo = ref.read(reputationRepositoryProvider);
      final adapter = ref.read(walletAdapterProvider);

      final signature = await repo.submitReview(
        worker: workerPubkey,
        reviewer: wallet.publicKey!,
        jobId: jobId,
        rating: _rating,
        walletAdapter: adapter,
      );

      setState(() {
        _successTxSignature = signature;
        _successWorkerAddress = workerAddress;
        _successJobId = jobId;
        _successRating = _rating;
      });
    } catch (e) {
      setState(() {
        _txError = 'Review submission failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleSaveDraft() async {
    final workerAddress = _workerController.text.trim();
    final jobId = _jobIdController.text.trim();
    final notes = _notesController.text.trim();

    if (workerAddress.isEmpty || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter worker address and job ID to save draft.')),
      );
      return;
    }

    final repo = ref.read(reputationRepositoryProvider);
    await repo.saveDraftReview(
      workerAddress: workerAddress,
      jobId: jobId,
      rating: _rating,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Draft saved locally.'),
        ),
      );
    }
  }

  void _showSelfReviewExplainer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why can\'t I review myself?'),
        content: const Text(
          'The ClockIn program rejects any review where the reviewer and worker '
          'are the same address — this is enforced on-chain, not just in this app. '
          'Without it, anyone could inflate their own rating for free. Reviews only '
          'count when they come from someone else\'s wallet.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);

    if (_successTxSignature != null) {
      return _buildSuccessScreen(context, wallet);
    }

    final enteredAddress = _workerController.text.trim();
    final validAddress = _parseAddress(enteredAddress);
    final isSelf = validAddress != null && wallet.address != null && wallet.address == validAddress;

    if (isSelf) {
      return _buildSelfReviewBlockedScreen(context, wallet, validAddress);
    }

    return _buildFormScreen(context, wallet, validAddress, enteredAddress);
  }

  // ==================== Screen 5: Form ====================

  Widget _buildFormScreen(
    BuildContext context,
    WalletState wallet,
    String? validAddress,
    String enteredAddress,
  ) {
    final targetProfileAsync =
        validAddress != null ? ref.watch(workerProfileProvider(validAddress)) : null;
    final targetProfile = targetProfileAsync?.asData?.value;
    final targetLookupResolved = targetProfileAsync?.hasValue ?? false;
    final targetNotRegistered =
        validAddress != null && targetLookupResolved && targetProfile == null;

    final canSubmit = wallet.isConnected &&
        !_isSubmitting &&
        validAddress != null &&
        _jobIdController.text.trim().isNotEmpty &&
        targetProfile != null;

    return Scaffold(
      appBar: AppHeader(
        address: wallet.address,
        onCopyAddress: wallet.address == null ? null : () => _copy(wallet.address!, 'Copied'),
        onAvatarTap: wallet.isConnected
            ? () => ref.read(walletStateProvider.notifier).disconnect()
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave a review', style: AppTypography.headlineSm),
            const SizedBox(height: 4),
            Text(
              'Rate a worker for a completed job. This is written on-chain and can\'t be edited afterward.',
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Worker address input
            Text('Worker\'s address', style: AppTypography.titleMd),
            const SizedBox(height: 6),
            TextField(
              controller: _workerController,
              onChanged: (_) => setState(() {}),
              style: AppTypography.labelMd,
              decoration: const InputDecoration(
                hintText: 'Enter worker base58 address…',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 8),
            _buildWorkerPreview(enteredAddress, validAddress, targetProfileAsync, targetNotRegistered),
            const SizedBox(height: 16),

            // Job reference
            Text('Job reference', style: AppTypography.titleMd),
            const SizedBox(height: 6),
            TextField(
              controller: _jobIdController,
              maxLength: 32,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'e.g. bathroom-tile-14-elm',
                prefixIcon: Icon(Icons.assignment_outlined),
                counterText: '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                'A unique job ID. A worker can only be reviewed once per job ID.',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),

            // Rating
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Text('Overall performance score', style: AppTypography.titleMd),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: starValue <= _rating ? Colors.amber : AppColors.surfaceContainerHighest,
                        ),
                        onPressed: () => setState(() => _rating = starValue),
                      );
                    }),
                  ),
                  Text(
                    _ratingTierLabels[_rating] ?? '',
                    style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 star (Unsatisfactory)', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                      Text('5 stars (Exceptional)', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes (local-only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Note (optional)', style: AppTypography.titleMd),
                Text('${_notesController.text.length} / 280', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 280,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Any specific feedback for your own records…',
                counterText: '',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                'Saved on this device only. The on-chain program has no field for review text, so this never leaves your phone.',
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.security_rounded, size: 18, color: AppColors.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Immutable attestation', style: AppTypography.titleMd),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                            children: [
                              const TextSpan(text: 'Your signed rating is written permanently to Solana '),
                              TextSpan(text: NetworkConfig.clusterDisplayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const TextSpan(text: ' via Mobile Wallet Adapter. Network fee: '),
                              const TextSpan(text: '~0.000005 SOL', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_txError != null) ...[
              Text(_txError!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? () => _handleSubmit(targetProfile) : null,
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 10),
                          Text('Requesting MWA Signature…'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Authorize & Submit Review'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Requires MWA signing. Reviews are permanent once submitted.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleSaveDraft,
                child: const Text('Save as offline draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerPreview(
    String enteredAddress,
    String? validAddress,
    AsyncValue<WorkerProfile?>? targetProfileAsync,
    bool targetNotRegistered,
  ) {
    if (enteredAddress.isEmpty) {
      return Text(
        'Enter a worker\'s address to preview their on-chain profile.',
        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    if (validAddress == null) {
      return Text(
        'Not a valid Solana address.',
        style: AppTypography.bodySm.copyWith(color: AppColors.error),
      );
    }

    return targetProfileAsync!.when(
      loading: () => Row(
        children: [
          const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Checking on-chain profile…', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
      error: (_, _) => Text(
        'Could not check this address right now.',
        style: AppTypography.bodySm.copyWith(color: AppColors.error),
      ),
      data: (profile) {
        if (profile == null) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This address hasn\'t registered a ClockIn profile yet — submitting will fail until they do.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          );
        }

        final reviewWord = profile.totalJobs == 1 ? 'review' : 'reviews';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, size: 18, color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.shortAddress, style: AppTypography.labelMd),
                    Text(
                      'Registered ${DateFormat.yMMMd().format(profile.createdAt)} • ${profile.totalJobs} $reviewWord'
                      '${profile.totalJobs > 0 ? ' • ${profile.averageRating.toStringAsFixed(1)}★ avg' : ''}',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () => _copy(profile.address, 'Copied'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== Screen 5b: Self-Review Blocked ====================

  Widget _buildSelfReviewBlockedScreen(BuildContext context, WalletState wallet, String address) {
    return Scaffold(
      appBar: AppHeader(
        address: wallet.address,
        onCopyAddress: () => _copy(wallet.address!, 'Copied'),
        onAvatarTap: () => ref.read(walletStateProvider.notifier).disconnect(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: AppColors.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_shorten(address), style: AppTypography.titleMd),
                        Row(
                          children: [
                            Text('Connected Identity', style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
                            const SizedBox(width: 6),
                            const Icon(Icons.circle, size: 4, color: AppColors.outlineVariant),
                            const SizedBox(width: 6),
                            Text(
                              'YOUR PROFILE',
                              style: AppTypography.labelSm.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('Worker\'s address', style: AppTypography.titleMd),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.outline),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_shorten(address), style: AppTypography.labelLg)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(999)),
                    child: Text('Self identity match', style: AppTypography.labelSm.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('Overall performance score', style: AppTypography.titleMd),
            const SizedBox(height: 4),
            Opacity(
              opacity: 0.4,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.star_outline_rounded, size: 34, color: AppColors.outline),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Text('Locked — you can\'t rate your own connected identity', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_rounded, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You can\'t review yourself.', style: AppTypography.titleMd.copyWith(color: const Color(0xFF6D3B00))),
                            const SizedBox(height: 4),
                            Text(
                              'This address matches your connected wallet. You can only review workers you have hired.',
                              style: AppTypography.bodySm.copyWith(color: const Color(0xFF7D4800)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF8F5500)),
                          const SizedBox(width: 6),
                          Text('Sybil Resistance Safeguard', style: AppTypography.labelSm.copyWith(color: const Color(0xFF8F5500), fontWeight: FontWeight.w700)),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showSelfReviewExplainer,
                        child: Text('Learn more', style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _switchConnectedWallet,
                child: const Text('Switch Connected Wallet'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => setState(() => _workerController.clear()),
                child: const Text('Cancel and return'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Screen 5e: Success ====================

  Widget _buildSuccessScreen(BuildContext context, WalletState wallet) {
    final signature = _successTxSignature!;
    final workerAddress = _successWorkerAddress ?? '';
    final explorerUrl = 'https://explorer.solana.com/tx/$signature?cluster=${NetworkConfig.clusterName}';

    return Scaffold(
      appBar: AppHeader(address: wallet.address),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Color(0xFFE8F6EE), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text('Review submitted', style: AppTypography.headlineMd),
            const SizedBox(height: 6),
            Text(
              'Your rating is now recorded on Solana ${NetworkConfig.clusterDisplayName}.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: AppColors.onSecondaryContainer),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WORKER', style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                              Text(
                                workerAddress.length > 8 ? _shorten(workerAddress) : workerAddress,
                                style: AppTypography.labelLg,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFE8F6EE), borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 12, color: AppColors.success),
                              const SizedBox(width: 3),
                              Text('Reviewed', style: AppTypography.labelSm.copyWith(color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('You rated', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < _successRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Job', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                            Flexible(
                              child: Text(
                                _successJobId ?? '',
                                textAlign: TextAlign.right,
                                style: AppTypography.titleMd,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Status', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                            Text('Confirmed just now', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () => _copy(explorerUrl, 'Explorer link copied — paste it in your browser.'),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Copy explorer link'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryContainer),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _successTxSignature = null;
                    _successWorkerAddress = null;
                    _successJobId = null;
                    _workerController.clear();
                    _jobIdController.clear();
                    _notesController.clear();
                    _rating = 5;
                  });
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
