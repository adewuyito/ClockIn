import 'package:drift/drift.dart';
import 'package:solana/solana.dart';
import '../models/seeker_attestation.dart';
import '../solana/contract_service.dart';
import '../solana/skr_staking.dart';
import 'app_database.dart' hide SeekerAttestation;
import 'app_database.dart' as rows show SeekerAttestation;

/// Seeker attestation, backed by real $SKR stake.
///
/// A wallet is attested when it has at least [minimumStakeThreshold] $SKR
/// actively staked with a Solana Mobile Guardian, read directly from Solana
/// Mobile's staking program (see [SkrStakeReader]). Users stake through
/// stake.solanamobile.com or Seed Vault Wallet; ClockIn only reads the result
/// and never holds, moves, or locks anyone's tokens.
///
/// The Drift table is a cache of the last successful read, so status is
/// available offline and for counterparties' profiles without hammering RPC.
/// It is never a source of truth on its own: nothing writes `isAttested: true`
/// except a verified on-chain read.
class AttestationRepository {
  final AppDatabase db;
  final ContractService contractService;
  final SkrStakeSource stakeSource;

  AttestationRepository({
    required this.db,
    required this.contractService,
    required this.stakeSource,
  });

  /// Minimum active $SKR stake for Seeker attestation.
  static const double minimumStakeThreshold = 250.0;

  /// Guardian name used when a wallet has no active position.
  static const String canonicalGuardianName = 'Solana Mobile';

  /// Where users create, increase, and withdraw their stake.
  static const String stakingPortalUrl = 'https://stake.solanamobile.com';

  /// A cached read younger than this is served without re-querying the chain.
  static const Duration freshness = Duration(minutes: 5);

  /// When the chain can't be reached, a cached attestation is honoured for at
  /// most this long. Past it, the wallet is shown as unattested rather than
  /// trusting a positive result that may have been unstaked since.
  static const Duration maxStaleness = Duration(hours: 24);

  /// Returns the attestation for [address], re-reading the chain unless a
  /// cached result is younger than [freshness] (or [forceRefresh] is set).
  Future<SeekerAttestation> getAttestation(
    String address, {
    bool forceRefresh = false,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now().toUtc();
    final cached = await _cachedRow(address);

    if (!forceRefresh &&
        cached != null &&
        clock.difference(cached.syncedAt.toUtc()) < freshness) {
      return cached;
    }

    try {
      final snapshot = await stakeSource.fetch(address);
      final staked = snapshot.totalActiveSkr;
      final attested = staked >= minimumStakeThreshold;
      final guardians = snapshot.guardianNames;
      final guardianName =
          guardians.isEmpty ? canonicalGuardianName : guardians.join(', ');

      await db.into(db.seekerAttestations).insertOnConflictUpdate(
            SeekerAttestationsCompanion.insert(
              address: address,
              isAttested: attested,
              stakedAmount: Value(staked),
              guardianName: Value(guardianName),
              // Unstake-cooldown fields differ between program versions and
              // are not decoded; active stake already excludes unstaking SKR.
              cooldownActive: const Value(false),
              txSignature: const Value(null),
              syncedAt: Value(snapshot.fetchedAt),
            ),
          );

      return SeekerAttestation(
        address: address,
        isAttested: attested,
        stakedAmount: staked,
        guardianName: guardianName,
        syncedAt: snapshot.fetchedAt,
      );
    } catch (e) {
      return _fallback(address, cached, clock, e);
    }
  }

  /// Serves the last good result after a failed read, within [maxStaleness].
  SeekerAttestation _fallback(
    String address,
    SeekerAttestation? cachedDomain,
    DateTime clock,
    Object error,
  ) {
    final message = _describe(error);
    if (cachedDomain != null &&
        clock.difference(cachedDomain.syncedAt.toUtc()) < maxStaleness) {
      return cachedDomain.copyWith(verificationError: message);
    }
    return SeekerAttestation(
      address: address,
      isAttested: false,
      stakedAmount: 0.0,
      guardianName: canonicalGuardianName,
      syncedAt: cachedDomain?.syncedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      verificationError: message,
    );
  }

  /// Streams attestation for [address] from the cache, triggering a background
  /// on-chain read. Works for any address, so counterparties see the same
  /// verified status the wallet owner sees.
  Stream<SeekerAttestation> watchAttestation(String address) {
    getAttestation(address).ignore();

    return (db.select(db.seekerAttestations)..where((t) => t.address.equals(address)))
        .watchSingleOrNull()
        .map((row) => row == null
            ? SeekerAttestation(
                address: address,
                isAttested: false,
                syncedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              )
            : _toDomain(row)!);
  }

  /// Claims devnet $SKR from the escrow faucet. This is the devnet stand-in
  /// token used for $SKR escrow contracts — it is unrelated to Guardian stake
  /// and cannot produce an attestation.
  Future<String> claimDevnetFaucet({
    required Ed25519HDPublicKey wallet,
    double amount = 500.0,
  }) async {
    return contractService.airdropDevnetSkr(recipient: wallet, amount: amount);
  }

  Future<SeekerAttestation?> _cachedRow(String address) async {
    final row = await (db.select(db.seekerAttestations)
          ..where((t) => t.address.equals(address)))
        .getSingleOrNull();
    return _toDomain(row);
  }

  SeekerAttestation? _toDomain(rows.SeekerAttestation? row) {
    if (row == null) return null;
    return SeekerAttestation(
      address: row.address,
      isAttested: row.isAttested,
      stakedAmount: row.stakedAmount,
      guardianName: row.guardianName,
      cooldownActive: row.cooldownActive,
      syncedAt: row.syncedAt,
    );
  }

  static String _describe(Object error) {
    if (error is SkrStakeLayoutException) {
      return 'Staking program data did not match the expected layout.';
    }
    return 'Could not reach Solana to verify stake.';
  }
}
