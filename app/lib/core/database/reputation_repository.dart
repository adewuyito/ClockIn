import 'package:drift/drift.dart';
import 'package:solana/solana.dart';
import '../models/review.dart' as domain;
import '../models/worker_profile.dart' as domain;
import '../solana/reputation_service.dart';
import '../solana/wallet_adapter.dart';
import 'app_database.dart';

/// Repository coordinating on-chain Solana state with the local Drift database cache.
/// Implements offline-first caching with active background sync.
class ReputationRepository {
  final AppDatabase db;
  final ReputationService reputationService;

  ReputationRepository({
    required this.db,
    required this.reputationService,
  });

  // ==================== WORKER PROFILES ====================

  /// Watches a worker profile from the local Drift cache reactively.
  Stream<domain.WorkerProfile?> watchWorkerProfile(String address) {
    final query = db.select(db.workerProfiles)
      ..where((tbl) => tbl.address.equals(address));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return domain.WorkerProfile(
        address: row.address,
        totalJobs: row.totalJobs,
        ratingSum: row.ratingSum,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row.createdAt.toInt() * 1000,
          isUtc: true,
        ),
        syncedAt: row.syncedAt,
      );
    });
  }

  /// Gets a worker profile. If [forceRefresh] is false, returns cached data immediately
  /// while asynchronously refreshing from the Solana RPC.
  Future<domain.WorkerProfile?> getWorkerProfile(
    String address, {
    bool forceRefresh = false,
  }) async {
    final cached = await (db.select(db.workerProfiles)
          ..where((tbl) => tbl.address.equals(address)))
        .getSingleOrNull();

    if (cached != null && !forceRefresh) {
      // Trigger background sync without blocking UI
      // ignore: unawaited_futures
      refreshWorkerProfile(address);

      return domain.WorkerProfile(
        address: cached.address,
        totalJobs: cached.totalJobs,
        ratingSum: cached.ratingSum,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          cached.createdAt.toInt() * 1000,
          isUtc: true,
        ),
        syncedAt: cached.syncedAt,
      );
    }

    return await refreshWorkerProfile(address);
  }

  /// Queries Solana RPC for the latest WorkerProfile and updates Drift cache.
  Future<domain.WorkerProfile?> refreshWorkerProfile(String address) async {
    final pubkey = Ed25519HDPublicKey.fromBase58(address);
    final onChain = await reputationService.getWorkerProfile(pubkey);

    if (onChain != null) {
      await db.into(db.workerProfiles).insertOnConflictUpdate(
            WorkerProfilesCompanion.insert(
              address: onChain.address,
              totalJobs: onChain.totalJobs,
              ratingSum: onChain.ratingSum,
              createdAt: BigInt.from(onChain.createdAt.millisecondsSinceEpoch ~/ 1000),
              syncedAt: Value(DateTime.now()),
            ),
          );
    }

    return onChain;
  }

  // ==================== REVIEWS ====================

  /// Watches reviews for a worker from local Drift cache.
  Stream<List<domain.Review>> watchWorkerReviews(String workerAddress) {
    final query = db.select(db.reviews)
      ..where((tbl) => tbl.workerAddress.equals(workerAddress))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return domain.Review(
          id: row.id,
          workerAddress: row.workerAddress,
          reviewerAddress: row.reviewerAddress,
          jobId: row.jobId,
          rating: row.rating,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            row.timestamp.toInt() * 1000,
            isUtc: true,
          ),
          syncedAt: row.syncedAt,
        );
      }).toList();
    });
  }

  /// Gets worker reviews. Serves cache first, then triggers RPC refresh.
  Future<List<domain.Review>> getWorkerReviews(
    String workerAddress, {
    bool forceRefresh = false,
  }) async {
    final cached = await (db.select(db.reviews)
          ..where((tbl) => tbl.workerAddress.equals(workerAddress))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.timestamp, mode: OrderingMode.desc)
          ]))
        .get();

    if (cached.isNotEmpty && !forceRefresh) {
      // ignore: unawaited_futures
      refreshWorkerReviews(workerAddress);

      return cached.map((row) {
        return domain.Review(
          id: row.id,
          workerAddress: row.workerAddress,
          reviewerAddress: row.reviewerAddress,
          jobId: row.jobId,
          rating: row.rating,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            row.timestamp.toInt() * 1000,
            isUtc: true,
          ),
          syncedAt: row.syncedAt,
        );
      }).toList();
    }

    return await refreshWorkerReviews(workerAddress);
  }

  /// Refreshes worker reviews from Solana RPC and syncs to Drift cache.
  Future<List<domain.Review>> refreshWorkerReviews(String workerAddress) async {
    final pubkey = Ed25519HDPublicKey.fromBase58(workerAddress);
    final onChainReviews = await reputationService.getWorkerReviews(pubkey);

    await db.transaction(() async {
      // Delete existing cached reviews for this worker
      await (db.delete(db.reviews)
            ..where((tbl) => tbl.workerAddress.equals(workerAddress)))
          .go();

      // Insert fresh batch
      for (final r in onChainReviews) {
        await db.into(db.reviews).insert(
              ReviewsCompanion.insert(
                workerAddress: r.workerAddress,
                reviewerAddress: r.reviewerAddress,
                jobId: r.jobId,
                rating: r.rating,
                timestamp: BigInt.from(r.timestamp.millisecondsSinceEpoch ~/ 1000),
                syncedAt: Value(DateTime.now()),
              ),
            );
      }
    });

    return onChainReviews;
  }

  // ==================== OFFLINE DRAFT REVIEWS ====================

  /// Saves or updates a draft review locally in Drift.
  Future<int> saveDraftReview({
    int? id,
    required String workerAddress,
    required String jobId,
    required int rating,
    String? notes,
  }) async {
    if (id != null) {
      await (db.update(db.draftReviews)..where((tbl) => tbl.id.equals(id))).write(
        DraftReviewsCompanion(
          workerAddress: Value(workerAddress),
          jobId: Value(jobId),
          rating: Value(rating),
          notes: Value(notes),
        ),
      );
      return id;
    } else {
      return await db.into(db.draftReviews).insert(
            DraftReviewsCompanion.insert(
              workerAddress: workerAddress,
              jobId: jobId,
              rating: rating,
              notes: Value(notes),
            ),
          );
    }
  }

  /// Deletes a draft review once submitted or canceled.
  Future<void> deleteDraftReview(int id) async {
    await (db.delete(db.draftReviews)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watches all offline drafts.
  Stream<List<DraftReview>> watchDraftReviews() {
    return (db.select(db.draftReviews)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // ==================== ON-CHAIN TRANSACTIONS ====================

  /// Registers the connected worker on-chain, then caches the profile locally.
  Future<String> registerWorker({
    required Ed25519HDPublicKey worker,
    required WalletAdapter walletAdapter,
  }) async {
    final signature = await reputationService.registerWorker(
      worker: worker,
      walletAdapter: walletAdapter,
    );

    // Refresh and cache
    await refreshWorkerProfile(worker.toBase58());

    return signature;
  }

  /// Submits a review on-chain, updates local cache, and removes draft if applicable.
  Future<String> submitReview({
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey reviewer,
    required String jobId,
    required int rating,
    required WalletAdapter walletAdapter,
    int? draftId,
  }) async {
    final signature = await reputationService.submitReview(
      worker: worker,
      reviewer: reviewer,
      jobId: jobId,
      rating: rating,
      walletAdapter: walletAdapter,
    );

    // If there was an associated draft, remove it
    if (draftId != null) {
      await deleteDraftReview(draftId);
    }

    // Refresh cached state for worker profile and reviews
    await refreshWorkerProfile(worker.toBase58());
    await refreshWorkerReviews(worker.toBase58());

    return signature;
  }
}
