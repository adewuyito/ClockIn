import 'package:drift/drift.dart';
import '../models/seeker_attestation.dart';
import '../solana/contract_service.dart';
import 'app_database.dart' hide SeekerAttestation;

/// Repository managing Seeker Attestation state via Solana RPC and Drift local cache.
class AttestationRepository {
  final AppDatabase db;
  final ContractService contractService;

  AttestationRepository({
    required this.db,
    required this.contractService,
  });

  /// Minimum $SKR token stake required for Seeker Guardian Attestation (proof-of-human).
  static const double minimumStakeThreshold = 250.0;

  /// Retrieves the attestation state for an address.
  /// Combines live on-chain $SKR balance query with local Drift cache.
  Future<SeekerAttestation> getAttestation(String address, {bool forceRefresh = false}) async {
    // 1. Check Drift cache first
    final cached = await (db.select(db.seekerAttestations)
          ..where((t) => t.address.equals(address)))
        .getSingleOrNull();

    // 2. Fetch live $SKR balance from Solana RPC
    double rpcBalance = 0.0;
    try {
      rpcBalance = await contractService.getSkrBalance(address);
    } catch (_) {
      rpcBalance = 0.0;
    }

    final cachedStake = cached?.stakedAmount ?? 0.0;
    final cachedAttested = cached?.isAttested ?? false;

    // Attested if wallet holds >= 250 $SKR on-chain OR has active cached Guardian stake
    final isAttested = (rpcBalance >= minimumStakeThreshold) ||
        (cachedAttested && cachedStake >= minimumStakeThreshold);

    final effectiveStake = rpcBalance >= minimumStakeThreshold
        ? rpcBalance
        : (cachedStake > 0 ? cachedStake : (isAttested ? minimumStakeThreshold : 0.0));

    // 3. Upsert to Drift database
    await db.into(db.seekerAttestations).insertOnConflictUpdate(
          SeekerAttestationsCompanion.insert(
            address: address,
            isAttested: isAttested,
            stakedAmount: Value(effectiveStake),
            guardianName: Value(cached?.guardianName ?? 'Helius'),
            cooldownActive: Value(isAttested),
            syncedAt: Value(DateTime.now()),
          ),
        );

    return SeekerAttestation(
      address: address,
      isAttested: isAttested,
      stakedAmount: effectiveStake,
      guardianName: cached?.guardianName ?? 'Helius',
      cooldownActive: isAttested,
      syncedAt: DateTime.now(),
    );
  }

  /// Streams reactive updates for an address's Seeker Attestation from Drift SQLite.
  Stream<SeekerAttestation> watchAttestation(String address) {
    // Trigger background RPC sync
    getAttestation(address).ignore();

    return (db.select(db.seekerAttestations)..where((t) => t.address.equals(address)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null) {
        return SeekerAttestation(
          address: address,
          isAttested: false,
          stakedAmount: 0.0,
          guardianName: 'Helius',
          cooldownActive: false,
          syncedAt: DateTime.now(),
        );
      }
      return SeekerAttestation(
        address: row.address,
        isAttested: row.isAttested,
        stakedAmount: row.stakedAmount,
        guardianName: row.guardianName,
        cooldownActive: row.cooldownActive,
        syncedAt: row.syncedAt,
      );
    });
  }

  /// Stakes $SKR to Guardian (e.g. Helius) for economic Sybil-resistance on Devnet.
  Future<void> stakeDevnetSkr({
    required String address,
    double amount = minimumStakeThreshold,
  }) async {
    await db.into(db.seekerAttestations).insertOnConflictUpdate(
          SeekerAttestationsCompanion.insert(
            address: address,
            isAttested: true,
            stakedAmount: Value(amount),
            guardianName: const Value('Helius'),
            cooldownActive: const Value(true),
            syncedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Initiates unstaking cooldown.
  Future<void> unstakeDevnetSkr({
    required String address,
  }) async {
    await db.into(db.seekerAttestations).insertOnConflictUpdate(
          SeekerAttestationsCompanion.insert(
            address: address,
            isAttested: false,
            stakedAmount: const Value(0.0),
            guardianName: const Value('Helius'),
            cooldownActive: const Value(false),
            syncedAt: Value(DateTime.now()),
          ),
        );
  }
}
