import 'package:drift/drift.dart';
import 'package:solana/solana.dart';
import '../models/seeker_attestation.dart';
import '../solana/contract_service.dart';
import '../solana/wallet_adapter.dart';
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

    // Attested if active cached Guardian stake is present, or if uncached address holds threshold tokens
    final isAttested = (cachedAttested && cachedStake >= minimumStakeThreshold) ||
        (cached == null && rpcBalance >= minimumStakeThreshold);

    final effectiveStake = cachedStake > 0
        ? cachedStake
        : (isAttested ? (rpcBalance > 0 ? rpcBalance : minimumStakeThreshold) : 0.0);

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

  /// Real on-chain staking flow:
  /// Transfers 250 $SKR from connected wallet to Guardian Stake Vault PDA on-chain
  /// via Mobile Wallet Adapter (Phantom/Solflare).
  /// Once confirmed on Solana Devnet, records verified attestation in Drift SQLite.
  Future<String> stakeSkrOnChain({
    required Ed25519HDPublicKey wallet,
    required WalletAdapter walletAdapter,
    double amount = minimumStakeThreshold,
    String guardianName = 'Helius',
  }) async {
    final signature = await contractService.stakeSkrToGuardian(
      wallet: wallet,
      walletAdapter: walletAdapter,
      amount: amount,
      guardianName: guardianName,
    );

    // Save confirmed stake to Drift SQLite
    await db.into(db.seekerAttestations).insertOnConflictUpdate(
          SeekerAttestationsCompanion.insert(
            address: wallet.toBase58(),
            isAttested: true,
            stakedAmount: Value(amount),
            guardianName: Value(guardianName),
            cooldownActive: const Value(true),
            syncedAt: Value(DateTime.now()),
          ),
        );

    return signature;
  }

  /// Claims 500 Devnet $SKR tokens from authorized Devnet Faucet Keypair directly to user's wallet ATA.
  Future<String> claimDevnetFaucet({
    required Ed25519HDPublicKey wallet,
    double amount = 500.0,
  }) async {
    final signature = await contractService.airdropDevnetSkr(
      recipient: wallet,
      amount: amount,
    );
    return signature;
  }

  /// Stakes $SKR to Guardian (e.g. Helius) for testing/local state.
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

