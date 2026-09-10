import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/devnet_badge.dart';

/// Screen 5, 5b, 5e: Submit Review Form with Self-Review Block & MWA Signing.
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

  int _rating = 5;
  bool _isSubmitting = false;
  String? _txError;
  String? _successTxSignature;

  @override
  void initState() {
    super.initState();
    _workerController =
        TextEditingController(text: widget.initialWorkerAddress ?? '');
    _jobIdController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _workerController.dispose();
    _jobIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isSelfReview(String? connectedAddress) {
    final entered = _workerController.text.trim();
    if (connectedAddress == null || entered.isEmpty) return false;
    return connectedAddress == entered;
  }

  Future<void> _handleSubmit() async {
    final wallet = ref.read(walletStateProvider);
    if (!wallet.isConnected || wallet.publicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your wallet first.')),
      );
      return;
    }

    final workerAddress = _workerController.text.trim();
    final jobId = _jobIdController.text.trim();

    if (workerAddress.isEmpty) {
      setState(() => _txError = 'Worker address is required.');
      return;
    }
    if (jobId.isEmpty) {
      setState(() => _txError = 'Job ID is required.');
      return;
    }
    if (jobId.length > 32) {
      setState(() => _txError = 'Job ID must be 32 characters or fewer.');
      return;
    }

    if (_isSelfReview(wallet.address)) {
      setState(() => _txError = 'Self-review is prohibited by the program.');
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
          content: Text('Draft saved locally in Drift database.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);
    final isSelf = _isSelfReview(wallet.address);

    // Screen 5e: Success Screen
    if (_successTxSignature != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Confirmed')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Review Confirmed On-Chain!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your star rating has been permanently recorded in the worker’s on-chain profile on Solana Devnet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction Signature:',
                        style: TextStyle(fontSize: 12, color: AppColors.outline),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _successTxSignature!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _successTxSignature = null;
                    _jobIdController.clear();
                    _notesController.clear();
                  });
                },
                child: const Text('Submit Another Review'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Review'),
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
              'Attest Work Quality',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Worker Address Field
            TextField(
              controller: _workerController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Worker Solana Address',
                hintText: 'Enter worker base58 address…',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),

            // Screen 5b: Self-Review Warning Box
            if (isSelf) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block_rounded, color: AppColors.error),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Self-Review Prohibited: You cannot submit a review for your own connected address.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Job ID Field (Seed component)
            TextField(
              controller: _jobIdController,
              maxLength: 32,
              decoration: const InputDecoration(
                labelText: 'Job Reference / ID',
                hintText: 'e.g. plumbing-job-101',
                prefixIcon: Icon(Icons.work_outline),
                helperText: 'Max 32 chars. Used as unique on-chain seed.',
              ),
            ),
            const SizedBox(height: 14),

            // Star Rating Picker
            const Text(
              'Rating (1 to 5 Stars)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  iconSize: 38,
                  icon: Icon(
                    starValue <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: starValue <= _rating
                        ? AppColors.success
                        : AppColors.outlineVariant,
                  ),
                  onPressed: () => setState(() => _rating = starValue),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Optional Notes Field (Drift offline metadata)
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional Local Draft)',
                hintText: 'Any specific feedback for your records…',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),

            if (_txError != null) ...[
              Text(
                _txError!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: (_isSubmitting || isSelf || !wallet.isConnected)
                  ? null
                  : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Review (MWA Signed)'),
            ),
            const SizedBox(height: 10),

            // Draft Button
            OutlinedButton(
              onPressed: _handleSaveDraft,
              child: const Text('Save as Offline Draft'),
            ),
          ],
        ),
      ),
    );
  }
}
