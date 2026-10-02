import 'package:drift/drift.dart';
import 'package:solana/solana.dart';
import '../models/escrow_contract.dart' as domain;
import '../solana/contract_service.dart';
import '../solana/network_config.dart';
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

  /// Creates and funds an escrow contract (SOL or $SKR SPL token), saving immediately to Drift cache.
  Future<String> createAndFund({
    required String contractId,
    required String workerAddress,
    required BigInt amountLamports,
    required String termsText,
    DateTime? deadline,
    required Ed25519HDPublicKey employer,
    required WalletAdapter walletAdapter,
    bool isToken = false,
    String? tokenMint,
  }) async {
    final termsHash = ContractService.computeTermsHash(termsText);
    final termsHashHex = termsHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final workerPubkey = Ed25519HDPublicKey.fromBase58(workerAddress);

    final String signature;
    if (isToken) {
      final mintPubkey = Ed25519HDPublicKey.fromBase58(
        tokenMint ?? NetworkConfig.devnetSkrMint,
      );
      signature = await contractService.createAndFundToken(
        employer: employer,
        worker: workerPubkey,
        contractId: contractId,
        amountTokenBaseUnits: amountLamports,
        termsHash: termsHash,
        deadline: deadline,
        mint: mintPubkey,
        walletAdapter: walletAdapter,
      );
    } else {
      signature = await contractService.createAndFund(
        employer: employer,
        worker: workerPubkey,
        contractId: contractId,
        amountLamports: amountLamports,
        termsHash: termsHash,
        deadline: deadline,
        walletAdapter: walletAdapter,
      );
    }

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
            isToken: Value(isToken),
            tokenMint: Value(tokenMint ?? (isToken ? NetworkConfig.devnetSkrMint : null)),
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
  /// Automatically detects and routes SPL token ($SKR) vs SOL release instructions.
  Future<String> releaseAndReview({
    required String contractId,
    required String workerAddress,
    required int rating,
    required Ed25519HDPublicKey employer,
    required WalletAdapter walletAdapter,
    bool? isToken,
    String? tokenMint,
  }) async {
    final workerPubkey = Ed25519HDPublicKey.fromBase58(workerAddress);

    // If isToken not explicitly passed, inspect cached contract
    bool tokenEscrow = isToken ?? false;
    String? mint = tokenMint;
    if (isToken == null) {
      final cached = await (db.select(db.escrowContracts)
            ..where((tbl) => tbl.contractId.equals(contractId)))
          .getSingleOrNull();
      if (cached != null) {
        tokenEscrow = cached.isToken;
        mint = cached.tokenMint;
      }
    }

    final String signature;
    if (tokenEscrow) {
      final mintPubkey = Ed25519HDPublicKey.fromBase58(
        mint ?? NetworkConfig.devnetSkrMint,
      );
      signature = await contractService.releaseAndReviewToken(
        employer: employer,
        worker: workerPubkey,
        contractId: contractId,
        rating: rating,
        mint: mintPubkey,
        walletAdapter: walletAdapter,
      );
    } else {
      signature = await contractService.releaseAndReview(
        employer: employer,
        worker: workerPubkey,
        contractId: contractId,
        rating: rating,
        walletAdapter: walletAdapter,
      );
    }

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

  /// Employer cancels an unaccepted escrow contract and reclaims 100% of vault funds (SOL or $SKR).
  Future<String> cancelContract({
    required String contractId,
    required Ed25519HDPublicKey employer,
    required WalletAdapter walletAdapter,
    bool? isToken,
    String? tokenMint,
  }) async {
    // If isToken not explicitly passed, inspect cached contract
    bool tokenEscrow = isToken ?? false;
    String? mint = tokenMint;
    if (isToken == null) {
      final cached = await (db.select(db.escrowContracts)
            ..where((tbl) => tbl.contractId.equals(contractId)))
          .getSingleOrNull();
      if (cached != null) {
        tokenEscrow = cached.isToken;
        mint = cached.tokenMint;
      }
    }

    final String signature;
    if (tokenEscrow) {
      final mintPubkey = Ed25519HDPublicKey.fromBase58(
        mint ?? NetworkConfig.devnetSkrMint,
      );
      signature = await contractService.cancelTokenContract(
        employer: employer,
        contractId: contractId,
        mint: mintPubkey,
        walletAdapter: walletAdapter,
      );
    } else {
      signature = await contractService.cancelContract(
        employer: employer,
        contractId: contractId,
        walletAdapter: walletAdapter,
      );
    }

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
    String? disputeReason,
    String? disputeDetails,
    String? disputeEvidenceUri,
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
        disputeReason: Value(disputeReason),
        disputeDetails: Value(disputeDetails),
        disputeEvidenceUri: Value(disputeEvidenceUri),
        disputeRaisedBy: Value(caller.toBase58()),
        disputeRaisedAt: Value(DateTime.now().toUtc()),
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
    final existing = await (db.select(db.escrowContracts)
          ..where((tbl) => tbl.contractId.equals(contract.contractId)))
        .getSingleOrNull();

    await db.into(db.escrowContracts).insertOnConflictUpdate(
          EscrowContractsCompanion.insert(
            contractId: contract.contractId,
            employer: contract.employer,
            worker: contract.worker,
            amount: contract.amount,
            termsHash: contract.termsHash,
            termsText: Value(termsTextOverride ?? existing?.termsText ?? contract.termsText),
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
            lastTxSignature: Value(contract.lastTxSignature ?? existing?.lastTxSignature),
            syncedAt: Value(DateTime.now().toUtc()),
            isToken: Value(contract.isToken),
            tokenMint: Value(contract.tokenMint),
            disputeReason: Value(existing?.disputeReason ?? contract.disputeReason),
            disputeDetails: Value(existing?.disputeDetails ?? contract.disputeDetails),
            disputeEvidenceUri: Value(existing?.disputeEvidenceUri ?? contract.disputeEvidenceUri),
            disputeRaisedBy: Value(existing?.disputeRaisedBy ?? contract.disputeRaisedBy),
            disputeRaisedAt: Value(existing?.disputeRaisedAt ?? contract.disputeRaisedAt),
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
      isToken: row.isToken,
      tokenMint: row.tokenMint,
      disputeReason: row.disputeReason,
      disputeDetails: row.disputeDetails,
      disputeEvidenceUri: row.disputeEvidenceUri,
      disputeRaisedBy: row.disputeRaisedBy,
      disputeRaisedAt: row.disputeRaisedAt,
    );
  }

  // ==================== OFFLINE DRAFT CONTRACTS ====================

  /// Saves or updates a draft contract locally in Drift.
  Future<int> saveDraftContract({
    int? id,
    required String contractId,
    required String workerAddress,
    required double amountSol,
    String? termsText,
    required BigInt deadline,
    bool isToken = false,
    String? tokenMint,
  }) async {
    if (id != null) {
      await (db.update(db.draftContracts)..where((tbl) => tbl.id.equals(id))).write(
        DraftContractsCompanion(
          contractId: Value(contractId),
          workerAddress: Value(workerAddress),
          amountSol: Value(amountSol),
          termsText: Value(termsText),
          deadline: Value(deadline),
          isToken: Value(isToken),
          tokenMint: Value(tokenMint),
        ),
      );
      return id;
    } else {
      return await db.into(db.draftContracts).insert(
            DraftContractsCompanion.insert(
              contractId: contractId,
              workerAddress: workerAddress,
              amountSol: amountSol,
              termsText: Value(termsText),
              deadline: deadline,
              isToken: Value(isToken),
              tokenMint: Value(tokenMint),
            ),
          );
    }
  }

  /// Gets all draft contracts saved in Drift.
  Future<List<DraftContract>> getDraftContracts() async {
    return await (db.select(db.draftContracts)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Watches all draft contracts saved in Drift.
  Stream<List<DraftContract>> watchDraftContracts() {
    final query = db.select(db.draftContracts)
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)
      ]);
    return query.watch();
  }

  /// Deletes a draft contract by its local SQLite ID.
  Future<void> deleteDraftContract(int id) async {
    await (db.delete(db.draftContracts)..where((tbl) => tbl.id.equals(id))).go();
  }
}
