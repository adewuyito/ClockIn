import 'package:clockin/core/database/app_database.dart' hide SeekerAttestation;
import 'package:clockin/core/database/attestation_repository.dart';
import 'package:clockin/core/solana/contract_service.dart';
import 'package:clockin/core/solana/skr_staking.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeContractService extends ContractService {
  @override
  Future<double> getSkrBalance(String address) async => 0.0;
}

class FakeSkrStakeSource implements SkrStakeSource {
  @override
  SkrStakingCluster get cluster => SkrStakingCluster.devnet;

  double fakeStakeSkr = 0.0;
  List<String> fakeGuardians = ['Solana Mobile'];
  bool shouldThrow = false;

  @override
  Future<SkrStakeSnapshot> fetch(String wallet) async {
    if (shouldThrow) {
      throw Exception('RPC timeout / node unreachable');
    }
    final baseUnits = BigInt.from((fakeStakeSkr * 1e6).round());
    final positions = [
      if (fakeStakeSkr > 0)
        SkrStakePosition(
          guardian: SkrGuardian(
            name: fakeGuardians.first,
            address: 'FakeGuardian11111111111111111111111111111111',
          ),
          shares: baseUnits,
          activeBaseUnits: baseUnits,
        ),
    ];
    return SkrStakeSnapshot(
      wallet: wallet,
      cluster: cluster,
      positions: positions,
      sharePrice: skrSharePriceScale,
      cooldownSeconds: 172800,
      fetchedAt: DateTime.now().toUtc(),
    );
  }
}

void main() {
  late AppDatabase db;
  late FakeContractService fakeContractService;
  late FakeSkrStakeSource fakeStakeSource;
  late AttestationRepository repo;

  const testAddress = '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeContractService = FakeContractService();
    fakeStakeSource = FakeSkrStakeSource();
    repo = AttestationRepository(
      db: db,
      contractService: fakeContractService,
      stakeSource: fakeStakeSource,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AttestationRepository & Real Guardian Staking Drift Cache', () {
    test('initial state for un-staked address is not attested', () async {
      fakeStakeSource.fakeStakeSkr = 0.0;
      final attestation = await repo.getAttestation(testAddress);

      expect(attestation.address, testAddress);
      expect(attestation.isAttested, isFalse);
      expect(attestation.stakedAmount, 0.0);
      expect(attestation.hasSufficientStake, isFalse);
      expect(attestation.isFreshlyVerified, isTrue);
    });

    test(r'stake below minimum threshold (100 < 250 $SKR) is NOT attested', () async {
      fakeStakeSource.fakeStakeSkr = 100.0;
      final attestation = await repo.getAttestation(testAddress);

      expect(attestation.isAttested, isFalse);
      expect(attestation.stakedAmount, 100.0);
      expect(attestation.hasSufficientStake, isFalse);

      final cachedRows = await db.select(db.seekerAttestations).get();
      expect(cachedRows.length, 1);
      expect(cachedRows.first.isAttested, isFalse);
      expect(cachedRows.first.stakedAmount, 100.0);
    });

    test(r'stake >= 250 $SKR grants Seeker attestation and persists to Drift', () async {
      fakeStakeSource.fakeStakeSkr = 250.0;
      fakeStakeSource.fakeGuardians = ['Solana Mobile Guardian Alpha'];
      final attestation = await repo.getAttestation(testAddress);

      expect(attestation.isAttested, isTrue);
      expect(attestation.stakedAmount, 250.0);
      expect(attestation.hasSufficientStake, isTrue);
      expect(attestation.guardianName, 'Solana Mobile Guardian Alpha');

      final row = await (db.select(db.seekerAttestations)
            ..where((t) => t.address.equals(testAddress)))
          .getSingle();

      expect(row.isAttested, isTrue);
      expect(row.stakedAmount, 250.0);
      expect(row.guardianName, 'Solana Mobile Guardian Alpha');
    });

    test('serves cached attestation on network failure within maxStaleness', () async {
      // 1. Prime the cache with verified stake
      fakeStakeSource.fakeStakeSkr = 500.0;
      await repo.getAttestation(testAddress);

      // 2. Network fails, force refresh
      fakeStakeSource.shouldThrow = true;
      final fallback = await repo.getAttestation(testAddress, forceRefresh: true);

      expect(fallback.isAttested, isTrue);
      expect(fallback.stakedAmount, 500.0);
      expect(fallback.verificationError, isNotNull);
      expect(fallback.isFreshlyVerified, isFalse);
    });

    test('watchAttestation streams updates from Drift database cache', () async {
      final stream = repo.watchAttestation(testAddress);
      final emissions = <bool>[];
      final subscription = stream.listen((att) {
        emissions.add(att.isAttested);
      });

      await pumpEventQueue();

      // Update stake and verify
      fakeStakeSource.fakeStakeSkr = 300.0;
      await repo.getAttestation(testAddress, forceRefresh: true);

      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.contains(true), isTrue);
    });
  });
}
