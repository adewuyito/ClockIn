import 'package:drift/drift.dart';
import 'package:solana/solana.dart';
import '../models/escrow_contract.dart' as domain;
import '../solana/contract_service.dart';
import '../solana/wallet_adapter.dart';
import 'app_database.dart';

/// Repository coordinating on-chain Solana escrow state with local Drift database cache.
/// Implements offline-first caching with active background sync.
class ContractRepository {
  final AppDatabase db;
  final ContractService contractService;

  ContractRepository({
    required this.db,
    required this.contractService,
  });

  // ==================== REACTIVE DRIFT STREAMS ====================

  /// Watches all contracts where the given wallet address is employer or worker.
  Stream<List<domain.EscrowContract>> watchContractsForWallet(String walletAddress) {
    final query = db.select(db.escrowContracts)
      ..where((tbl) =>
          tbl.employer.equals(walletAddress) | tbl.worker.equals(walletAddress))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
      ]);

    return query.watch().map((rows) => rows.map(_rowToDomain).toList());
  }

  /// Watches a single contract reactively from local Drift database.
  Stream<domain.EscrowContract?> watchContract(String contractId) {
    final query = db.select(db.escrowContracts)
      ..where((tbl) => tbl.contractId.equals(contractId));

    return query.watchSingleOrNull().map((row) => row != null ? _rowToDomain(row) : null);
  }

  // ==================== READ & SYNC ====================

  /// Gets a contract. If [forceRefresh] is false, returns cached Drift data immediately
  /// while asynchronously refreshing from Solana RPC.
  Future<domain.EscrowContract?> getContract(
    String contractId, {
    bool forceRefresh = false,
  }) async {
    final cached = await (db.select(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contractId)))
        .getSingleOrNull();

    if (cached != null && !forceRefresh) {
      // Trigger background sync without blocking UI
      // ignore: unawaited_futures
      refreshContract(contractId, existingTermsText: cached.termsText);
      return _rowToDomain(cached);
    }

    return await refreshContract(contractId, existingTermsText: cached?.termsText);
  }

  /// Fetches the latest on-chain contract state from Solana RPC and updates Drift cache.
  Future<domain.EscrowContract?> refreshContract(
    String contractId, {
    String? existingTermsText,
  }) async {
    final onChain = await contractService.getContract(contractId);
    if (onChain != null) {
      await _upsertOnChainContract(onChain, termsTextOverride: existingTermsText);
      return onChain.copyWith(termsText: existingTermsText);
    }
    return null;
  }

  /// Refreshes all contracts for a wallet address from on-chain RPC and updates Drift cache.
  Future<List<domain.EscrowContract>> refreshContractsForWallet(String walletAddress) async {
    final onChainList = await contractService.getContractsForParticipant(walletAddress);
    for (final contract in onChainList) {
      // Preserve any existing termsText in Drift
      final cached = await (db.select(db.escrowContracts)
            ..where((tbl) => tbl.contractId.equals(contract.contractId)))
          .getSingleOrNull();
      await _upsertOnChainContract(contract, termsTextOverride: cached?.termsText);
    }
    return onChainList;
  }

  /// Stores or updates plain text terms for a contract (e.g. from share URL or form input).
  Future<void> saveContractTerms({
    required String contractId,
    required String termsText,
  }) async {
    final existing = await (db.select(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contractId)))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.escrowContracts)
            ..where((tbl) => tbl.contractId.equals(contractId)))
          .write(EscrowContractsCompanion(termsText: Value(termsText)));
    }
  }

  // ==================== ON-CHAIN TRANSACTIONS ====================

  /// Creates and funds an escrow contract, saving immediately to Drift cache.
  Future<String> createAndFund({
    required String contractId,
    required String workerAddress,
    required BigInt amountLamports,
    required String termsText,
    DateTime? deadline,
    required Ed25519HDPublicKey employer,
    required WalletAdapter walletAdapter,
  }) async {
    final termsHash = ContractService.computeTermsHash(termsText);
    final termsHashHex = termsHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final workerPubkey = Ed25519HDPublicKey.fromBase58(workerAddress);

    final signature = await contractService.createAndFund(
      employer: employer,
      worker: workerPubkey,
      contractId: contractId,
      amountLamports: amountLamports,
      termsHash: termsHash,
      deadline: deadline,
      walletAdapter: walletAdapter,
    );

    // Save optimistically to Drift
    final now = DateTime.now().toUtc();
    await db.into(db.escrowContracts).insertOnConflictUpdate(
          EscrowContractsCompanion.insert(
            contractId: contractId,
            employer: employer.toBase58(),
            worker: workerAddress,
            amount: amountLamports,
            termsHash: termsHashHex,
            termsText: Value(termsText),
            status: domain.ContractStatus.funded.name,
            deadline: deadline != null
                ? BigInt.from(deadline.millisecondsSinceEpoch ~/ 1000)
                : BigInt.zero,
            createdAt: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
            fundedAt: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
            completedAt: BigInt.zero,
            rating: 0,
            lastTxSignature: Value(signature),
            syncedAt: Value(now),
          ),
        );

    // Asynchronously refresh to ensure exact on-chain slot timestamps
    // ignore: unawaited_futures
    refreshContract(contractId, existingTermsText: termsText);

    return signature;
  }

  /// Worker accepts an escrow contract, moving it into InProgress.
  Future<String> acceptContract({
    required String contractId,
    required Ed25519HDPublicKey worker,
    required WalletAdapter walletAdapter,
  }) async {
    final signature = await contractService.acceptContract(
      worker: worker,
      contractId: contractId,
      walletAdapter: walletAdapter,
    );

    await (db.update(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contractId)))
        .write(
      EscrowContractsCompanion(
        status: Value(domain.ContractStatus.inProgress.name),
        lastTxSignature: Value(signature),
        syncedAt: Value(DateTime.now().toUtc()),
      ),
    );

    // ignore: unawaited_futures
    refreshContract(contractId);

    return signature;
  }

  /// Employer releases escrow payment to worker and writes verified on-chain review.
  Future<String> releaseAndReview({
    required String contractId,
    required String workerAddress,
    required int rating,
    required Ed25519HDPublicKey employer,
    required WalletAdapter walletAdapter,
  }) async {
    final workerPubkey = Ed25519HDPublicKey.fromBase58(workerAddress);

    final signature = await contractService.releaseAndReview(
      employer: employer,
      worker: workerPubkey,
      contractId: contractId,
      rating: rating,
      walletAdapter: walletAdapter,
    );

    final now = DateTime.now().toUtc();
    await (db.update(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contractId)))
        .write(
      EscrowContractsCompanion(
        status: Value(domain.ContractStatus.completed.name),
        completedAt: Value(BigInt.from(now.millisecondsSinceEpoch ~/ 1000)),
        rating: Value(rating),
        lastTxSignature: Value(signature),
        syncedAt: Value(now),
      ),
    );

    // ignore: unawaited_futures
    refreshContract(contractId);

    return signature;
  }

  /// Employer cancels an unaccepted escrow contract and reclaims 100% of vault SOL.
  Future<String> cancelContract({
    required String contractId,
    required Ed25519HDPublicKey employer,
    required WalletAdapter walletAdapter,
  }) async {
    final signature = await contractService.cancelContract(
      employer: employer,
      contractId: contractId,
      walletAdapter: walletAdapter,
    );

    await (db.update(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contractId)))
        .write(
      EscrowContractsCompanion(
        status: Value(domain.ContractStatus.cancelled.name),
        lastTxSignature: Value(signature),
        syncedAt: Value(DateTime.now().toUtc()),
      ),
    );

    // ignore: unawaited_futures
    refreshContract(contractId);

    return signature;
  }

  /// Either participant raises a dispute.
  Future<String> raiseDispute({
    required String contractId,
    required Ed25519HDPublicKey caller,
    required WalletAdapter walletAdapter,
  }) async {
    final signature = await contractService.raiseDispute(
      caller: caller,
      contractId: contractId,
      walletAdapter: walletAdapter,
    );

    await (db.update(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contractId)))
        .write(
      EscrowContractsCompanion(
        status: Value(domain.ContractStatus.disputed.name),
        lastTxSignature: Value(signature),
        syncedAt: Value(DateTime.now().toUtc()),
      ),
    );

    // ignore: unawaited_futures
    refreshContract(contractId);

    return signature;
  }

  // ==================== HELPERS ====================

  Future<void> _upsertOnChainContract(
    domain.EscrowContract contract, {
    String? termsTextOverride,
  }) async {
    await db.into(db.escrowContracts).insertOnConflictUpdate(
          EscrowContractsCompanion.insert(
            contractId: contract.contractId,
            employer: contract.employer,
            worker: contract.worker,
            amount: contract.amount,
            termsHash: contract.termsHash,
            termsText: Value(termsTextOverride ?? contract.termsText),
            status: contract.status.name,
            deadline: contract.deadline != null
                ? BigInt.from(contract.deadline!.millisecondsSinceEpoch ~/ 1000)
                : BigInt.zero,
            createdAt: BigInt.from(contract.createdAt.millisecondsSinceEpoch ~/ 1000),
            fundedAt: contract.fundedAt != null
                ? BigInt.from(contract.fundedAt!.millisecondsSinceEpoch ~/ 1000)
                : BigInt.zero,
            completedAt: contract.completedAt != null
                ? BigInt.from(contract.completedAt!.millisecondsSinceEpoch ~/ 1000)
                : BigInt.zero,
            rating: contract.rating,
            lastTxSignature: Value(contract.lastTxSignature),
            syncedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  domain.EscrowContract _rowToDomain(EscrowContract row) {
    return domain.EscrowContract(
      contractId: row.contractId,
      employer: row.employer,
      worker: row.worker,
      amount: row.amount,
      termsHash: row.termsHash,
      termsText: row.termsText,
      status: domain.ContractStatus.fromString(row.status),
      deadline: row.deadline > BigInt.zero
          ? DateTime.fromMillisecondsSinceEpoch(row.deadline.toInt() * 1000, isUtc: true)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          row.createdAt.toInt() * 1000, isUtc: true),
      fundedAt: row.fundedAt > BigInt.zero
          ? DateTime.fromMillisecondsSinceEpoch(row.fundedAt.toInt() * 1000, isUtc: true)
          : null,
      completedAt: row.completedAt > BigInt.zero
          ? DateTime.fromMillisecondsSinceEpoch(
              row.completedAt.toInt() * 1000, isUtc: true)
          : null,
      rating: row.rating,
      lastTxSignature: row.lastTxSignature,
      syncedAt: row.syncedAt,
    );
  }
}
