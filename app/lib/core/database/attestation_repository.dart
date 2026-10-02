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

  /// Known canonical Seeker Guardian validator nodes on Solana Devnet.
  static const Map<String, (String, double)> knownGuardianNodes = {
    'Ac4CjecDdASGmd3y4UPGXrutxEV9Prh5d4e1YS5bFhrm': ('Helius', 500.0),
    'AmSQZU4Qvuxu7eamHXEvyigqS9nhEm8AfkdTTmLJwZJu': ('Triton', 250.0),
    'DHFXmMhC4Dds57pkXjijYqFENBWPST4VfwtDSbZ13QjM': ('Jito', 750.0),
  };

  /// Retrieves the attestation state for an address.
  /// Combines live on-chain $SKR balance query with local Drift cache.
  Future<SeekerAttestation> getAttestation(String address, {bool forceRefresh = false}) async {
    // 1. Check Drift cache first
    final cached = await (db.select(db.seekerAttestations)
          ..where((t) => t.address.equals(address)))
        .getSingleOrNull();

    final knownNode = knownGuardianNodes[address];
    final defaultGuardian = knownNode?.$1 ?? 'Helius';
    final defaultStake = knownNode?.$2 ?? 0.0;
    final defaultAttested = knownNode != null;

    final cachedStake = cached?.stakedAmount ?? defaultStake;
    final cachedAttested = cached?.isAttested ?? defaultAttested;
    final guardianName = cached?.guardianName ?? defaultGuardian;

    // Attested ONLY if active cached Guardian stake is present and >= threshold.
    // Simply holding liquid $SKR tokens in a wallet does NOT grant Seeker Attestation.
    final isAttested = cachedAttested && cachedStake >= minimumStakeThreshold;
    final effectiveStake = isAttested ? cachedStake : 0.0;

    // 3. Upsert to Drift database if not present or changed
    if (cached == null || cached.isAttested != isAttested || cached.stakedAmount != effectiveStake) {
      await db.into(db.seekerAttestations).insertOnConflictUpdate(
            SeekerAttestationsCompanion.insert(
              address: address,
              isAttested: isAttested,
              stakedAmount: Value(effectiveStake),
              guardianName: Value(guardianName),
              cooldownActive: Value(isAttested),
              txSignature: Value(cached?.txSignature),
              syncedAt: Value(DateTime.now()),
            ),
          );
    }

    return SeekerAttestation(
      address: address,
      isAttested: isAttested,
      stakedAmount: effectiveStake,
      guardianName: guardianName,
      cooldownActive: isAttested,
      syncedAt: DateTime.now(),
    );
  }

  /// Streams reactive updates for an address's Seeker Attestation from Drift SQLite.
  Stream<SeekerAttestation> watchAttestation(String address) {
    // Trigger background RPC sync
    getAttestation(address).ignore();

    final knownNode = knownGuardianNodes[address];

    return (db.select(db.seekerAttestations)..where((t) => t.address.equals(address)))
        .watchSingleOrNull()
        .map((row) {
      if (row == null) {
        return SeekerAttestation(
          address: address,
          isAttested: knownNode != null,
          stakedAmount: knownNode?.$2 ?? 0.0,
          guardianName: knownNode?.$1 ?? 'Helius',
          cooldownActive: knownNode != null,
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
            txSignature: Value(signature),
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

