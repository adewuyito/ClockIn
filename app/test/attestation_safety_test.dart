import 'package:clockin/core/database/app_database.dart' hide SeekerAttestation;
import 'package:clockin/core/database/attestation_repository.dart';
import 'package:clockin/core/solana/contract_service.dart';
import 'package:clockin/core/solana/skr_staking.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Safety properties of Seeker attestation that `attestation_test.dart` does
/// not cover: threshold boundaries, liquid balance never counting, unstaking
/// taking effect, cache freshness, and failures never *creating* or
/// indefinitely *preserving* an attestation.

class _LiquidRichContractService extends ContractService {
  @override
  Future<double> getSkrBalance(String address) async => 10000.0;
}

class _ScriptedStakeSource implements SkrStakeSource {
  double activeSkr = 0;
  Object? error;
  int fetches = 0;

  @override
  SkrStakingCluster get cluster => SkrStakingCluster.mainnet;

  @override
  Future<SkrStakeSnapshot> fetch(String wallet) async {
    fetches++;
    final e = error;
    if (e != null) throw e;
    final units = BigInt.from((activeSkr * 1e6).round());
    return SkrStakeSnapshot(
      wallet: wallet,
      cluster: cluster,
      positions: activeSkr > 0
          ? [
              SkrStakePosition(
                guardian: const SkrGuardian(
                  name: 'Solana Mobile',
                  address: 'SKRGdBwzb1AtFW2chhBnZpGFnFLj6Mi7HM7iwjXALvw',
                ),
                shares: units,
                activeBaseUnits: units,
              ),
            ]
          : const [],
      sharePrice: skrSharePriceScale,
      cooldownSeconds: 172800,
      fetchedAt: DateTime.utc(2026, 10, 6, 12),
    );
  }
}

void main() {
  late AppDatabase db;
  late _ScriptedStakeSource stake;
  late AttestationRepository repo;

  const wallet = '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM';
  final t0 = DateTime.utc(2026, 10, 6, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    stake = _ScriptedStakeSource();
    repo = AttestationRepository(
      db: db,
      contractService: _LiquidRichContractService(),
      stakeSource: stake,
    );
  });

  tearDown(() async => db.close());

  test(r'10,000 liquid $SKR with no stake is NOT attested', () async {
    final a = await repo.getAttestation(wallet, now: t0);
    expect(a.isAttested, isFalse);
    expect(a.stakedAmount, 0.0);
  });

  test('exactly 250 attests; a hair below does not', () async {
    stake.activeSkr = 250.0;
    expect((await repo.getAttestation(wallet, now: t0)).isAttested, isTrue);

    stake.activeSkr = 249.999999;
    final below = await repo.getAttestation(wallet, forceRefresh: true, now: t0);
    expect(below.isAttested, isFalse);
  });

  test('unstaking revokes attestation on the next read', () async {
    stake.activeSkr = 500.0;
    expect((await repo.getAttestation(wallet, now: t0)).isAttested, isTrue);

    stake.activeSkr = 0.0;
    final after = await repo.getAttestation(wallet, forceRefresh: true, now: t0);
    expect(after.isAttested, isFalse);

    final row = (await db.select(db.seekerAttestations).get()).single;
    expect(row.isAttested, isFalse);
  });

  test('a fresh cache is reused; an expired one or forceRefresh re-reads', () async {
    stake.activeSkr = 300.0;
    await repo.getAttestation(wallet, now: t0);
    await repo.getAttestation(wallet, now: t0.add(const Duration(minutes: 2)));
    expect(stake.fetches, 1);

    await repo.getAttestation(wallet, now: t0.add(const Duration(minutes: 6)));
    await repo.getAttestation(wallet, forceRefresh: true, now: t0.add(const Duration(minutes: 6)));
    expect(stake.fetches, 3);
  });

  test('an outage after 24h does NOT keep a wallet attested', () async {
    stake.activeSkr = 300.0;
    await repo.getAttestation(wallet, now: t0);

    stake.error = Exception('timeout');
    final a = await repo.getAttestation(
      wallet,
      forceRefresh: true,
      now: t0.add(const Duration(hours: 25)),
    );
    expect(a.isAttested, isFalse);
    expect(a.verificationError, isNotNull);
  });

  test('an outage with no cache is unattested — never assumed staked', () async {
    stake.error = Exception('offline');
    final a = await repo.getAttestation(wallet, now: t0);
    expect(a.isAttested, isFalse);
    expect(a.stakedAmount, 0.0);
    expect(a.isFreshlyVerified, isFalse);
  });

  test('a staking-program layout change is reported distinctly from an outage', () async {
    stake.error = const SkrStakeLayoutException('unexpected discriminator');
    final layout = await repo.getAttestation(wallet, now: t0);
    expect(layout.verificationError, contains('layout'));

    stake.error = Exception('429');
    final outage = await repo.getAttestation(wallet, forceRefresh: true, now: t0);
    expect(outage.verificationError, contains('Could not reach Solana'));
  });
}
