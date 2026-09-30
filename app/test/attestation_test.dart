import 'package:clockin/core/database/app_database.dart' hide SeekerAttestation;
import 'package:clockin/core/database/attestation_repository.dart';
import 'package:clockin/core/solana/contract_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeContractService extends ContractService {
  double fakeSkrBalance = 0.0;

  @override
  Future<double> getSkrBalance(String address) async {
    return fakeSkrBalance;
  }
}

void main() {
  late AppDatabase db;
  late FakeContractService fakeContractService;
  late AttestationRepository repo;

  const testAddress = '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeContractService = FakeContractService();
    repo = AttestationRepository(
      db: db,
      contractService: fakeContractService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AttestationRepository & Drift v6 SeekerAttestations', () {
    test('initial state for unverified address is not attested', () async {
      fakeContractService.fakeSkrBalance = 0.0;
      final attestation = await repo.getAttestation(testAddress);

      expect(attestation.address, testAddress);
      expect(attestation.isAttested, isFalse);
      expect(attestation.stakedAmount, 0.0);
    });

    test('address holding liquid SKR without staking is NOT attested', () async {
      fakeContractService.fakeSkrBalance = 350.0;
      final attestation = await repo.getAttestation(testAddress);

      // Liquid balance does NOT grant attestation without active locked stake
      expect(attestation.isAttested, isFalse);
      expect(attestation.stakedAmount, 0.0);

      // Verify it is cached as un-attested in Drift SQLite
      final cachedRows = await db.select(db.seekerAttestations).get();
      expect(cachedRows.length, 1);
      expect(cachedRows.first.address, testAddress);
      expect(cachedRows.first.isAttested, isFalse);
      expect(cachedRows.first.stakedAmount, 0.0);
    });

    test('stakeDevnetSkr updates Drift and sets active guardian stake', () async {
      await repo.stakeDevnetSkr(address: testAddress, amount: 250.0);

      final row = await (db.select(db.seekerAttestations)
            ..where((t) => t.address.equals(testAddress)))
          .getSingle();

      expect(row.isAttested, isTrue);
      expect(row.stakedAmount, 250.0);
      expect(row.guardianName, 'Helius');
      expect(row.cooldownActive, isTrue);
    });

    test('unstakeDevnetSkr resets attestation to unverified in Drift', () async {
      await repo.stakeDevnetSkr(address: testAddress, amount: 250.0);
      await repo.unstakeDevnetSkr(address: testAddress);

      final row = await (db.select(db.seekerAttestations)
            ..where((t) => t.address.equals(testAddress)))
          .getSingle();

      expect(row.isAttested, isFalse);
      expect(row.stakedAmount, 0.0);
      expect(row.cooldownActive, isFalse);
    });

    test('watchAttestation streams real-time updates when Drift table changes', () async {
      final stream = repo.watchAttestation(testAddress);

      final emissions = <bool>[];
      final subscription = stream.listen((att) {
        emissions.add(att.isAttested);
      });

      // Allow initial emission
      await Future.delayed(const Duration(milliseconds: 50));

      // Stake
      await repo.stakeDevnetSkr(address: testAddress, amount: 250.0);
      await Future.delayed(const Duration(milliseconds: 50));

      // Unstake
      await repo.unstakeDevnetSkr(address: testAddress);
      await Future.delayed(const Duration(milliseconds: 50));

      await subscription.cancel();

      expect(emissions.contains(true), isTrue);
      expect(emissions.last, isFalse);
    });
  });
}
