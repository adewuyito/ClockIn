import 'dart:convert';
import 'dart:typed_data';

import 'package:clockin/core/solana/skr_staking.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real account bytes captured from Solana Mobile's $SKR staking program on
/// 2026-10-06. Using live-captured data (rather than hand-built bytes) is the
/// point: these tests fail if the decoders drift from what the chain holds.

// ---- mainnet: a real staker ----
const _mainnetUser = 'FiT7dbQgJKAx1vDmhQim9btuvECbCs3Q3bQ2jQrwFsfR';
const _mainnetStakeConfigB64 =
    '7pcrAwuXP7D/99/RmBWIoUKnBCJppz3tD3Kiqm19wGlNrfxqo58KnyMGfFo+Bf5BRxKnour+Qr52'
    'ELzZDL9XFid1g3PLitDYpHK7t3HxKVTi9/Qhl74s+E4dlydE1728RBtKSZ5/fy2TQEIPAAAAAAAA'
    'owIAAAAAADyopN4qgg8AAAAAAAAAAABxZo1EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAAASOLtJl+wRAA==';
const _mainnetUserStakeB64 =
    'ZjWjawmKV5n/MMd0OFYtRe9beSkvYc8PNRQ1nYzgszbll2atCImxvN7aofUsEqkbTIIjrTNnrTJx'
    'i5sSJG62vx2NDfKSXcDUrLgCUtGNtSuONRWJvQL7jRyzJlcF9a4LANKbp5jhwl3hHt/pEgIAAAAA'
    'AAAAAAAAAAsKQEMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/+4cDQAAAADuzMRqAAAAAA==';

// ---- devnet: Solana Mobile's own devnet deployment ----
const _devnetUser = 'A9z56FTYk97CgMS2bkHCiQrtmRK9YX5hM7MjHCepnWJp';
const _devnetStakeConfigB64 =
    '7pcrAwuXP7D/tWFX6M7AIhVDVkesrwXLFvvyB6yWiu92O6K33KLuCWvqbUMLA5IZn8ppQXpvhYHC'
    'oB99qBmTaJSEcLYcWFzrjsF5HbsHryCBAEIItItRozHbsKdoYafq9hPupe3RrMPHgJaYAAAAAAAK'
    'AAAAAAAAAGCD3AqgAwAAAAAAAAAAAAD2GyxRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    'AAAAAAAAAAAAAAAAAABB0wdz8QQAAA==';
const _devnetUserStakeB64 =
    'ZjWjawmKV5n9LQ2F64oGQwH3b/LkfkdM6FsJpvS2Ff7gfd2u1BnHisqIBlvRFoaBnG7452Pkn/Vx'
    'nYxo0I1HxMN1Qn5WgrM29YOkgxM6cay7KGVn2HUE5eguJ01DtubhYi+u5fE2EnbO6+3aAAAAAAAA'
    'AAAAAAAAAOvSdBkAAAAAASJCDwAAAAAA4Qw4aQAAAAA=';

Uint8List _b64(String s) => base64.decode(s);

void main() {
  group('PDA derivation reproduces real on-chain addresses', () {
    test('mainnet: StakeConfig, GuardianPool, and a real staker\'s UserStake', () async {
      final a = await SkrStakeAddresses.derive(SkrStakingDeployment.mainnet, _mainnetUser);
      final g = SkrStakingDeployment.mainnet.guardians.single;
      expect(a.stakeConfig, '4HQy82s9CHTv1GsYKnANHMiHfhcqesYkK6sB3RDSYyqw');
      expect(a.guardianPools[g], 'DPJ58trLsF9yPrBa2pk6UaRkvqW8hWUYjawe788WBuqr');
      // The exact account this wallet's staking transaction wrote to.
      expect(a.userStakes[g], 'Ht5LbuZjASDFa1ALRnSW16nAzVX5EnRd2X6YPcS9vTNa');
    });

    test('devnet: same seeds against Solana Mobile\'s devnet deployment', () async {
      final a = await SkrStakeAddresses.derive(SkrStakingDeployment.devnet, _devnetUser);
      final g = SkrStakingDeployment.devnet.guardians.single;
      expect(a.stakeConfig, '42sJmTg166DoBZsJ9BKPcPBEdCP2o8Gdr24yRSphksbw');
      expect(a.guardianPools[g], '9rsuQvjo7L2WiDybt5Qcsp7QxEshvG32ffrbFjwUXoth');
      expect(a.userStakes[g], 'jBSKrytRad637PthkwFz8UL6tc9oDRygRxABq2yfN4Y');
    });
  });

  group('StakeConfig decoding', () {
    test('mainnet config: mint, 48h cooldown, share price', () {
      final c = SkrStakeConfig.decode(_b64(_mainnetStakeConfigB64));
      expect(c.mint, SkrStakingDeployment.mainnet.mint);
      // Matches the "48-hour cooldown" advertised on stake.solanamobile.com.
      expect(c.cooldownSeconds, 172800);
      expect(c.minStakeAmount, BigInt.from(1000000));
      expect(c.sharePrice, BigInt.parse('1150117489'));
    });

    test('devnet config: mint and short test cooldown', () {
      final c = SkrStakeConfig.decode(_b64(_devnetStakeConfigB64));
      expect(c.mint, SkrStakingDeployment.devnet.mint);
      expect(c.cooldownSeconds, 10);
    });

    test('rejects a non-StakeConfig account', () {
      expect(
        () => SkrStakeConfig.decode(_b64(_mainnetUserStakeB64)),
        throwsA(isA<SkrStakeLayoutException>()),
      );
    });
  });

  group('UserStake decoding & active stake', () {
    test('mainnet (169-byte layout): fields link back to config, user, pool', () {
      final raw = _b64(_mainnetUserStakeB64);
      expect(raw.length, 169);
      final s = SkrUserStake.decode(raw);
      expect(s.user, _mainnetUser);
      expect(s.stakeConfig, '4HQy82s9CHTv1GsYKnANHMiHfhcqesYkK6sB3RDSYyqw');
      expect(s.guardianPool, 'DPJ58trLsF9yPrBa2pk6UaRkvqW8hWUYjawe788WBuqr');
      expect(s.shares, BigInt.parse('8907251486'));
    });

    test('mainnet: active stake = shares × share_price / 1e9', () {
      final c = SkrStakeConfig.decode(_b64(_mainnetStakeConfigB64));
      final s = SkrUserStake.decode(_b64(_mainnetUserStakeB64));
      expect(s.activeBaseUnits(c.sharePrice), BigInt.parse('10244385712'));
    });

    test('devnet (146-byte layout) decodes with the same prefix', () {
      final raw = _b64(_devnetUserStakeB64);
      expect(raw.length, 146);
      final c = SkrStakeConfig.decode(_b64(_devnetStakeConfigB64));
      final s = SkrUserStake.decode(raw);
      expect(s.user, _devnetUser);
      expect(s.activeBaseUnits(c.sharePrice), BigInt.parse('19539421'));
    });

    test('rejects a truncated account rather than misreading it', () {
      final raw = _b64(_mainnetUserStakeB64).sublist(0, 120);
      expect(() => SkrUserStake.decode(raw), throwsA(isA<SkrStakeLayoutException>()));
    });

    test('rejects a wrong discriminator', () {
      final raw = Uint8List.fromList(_b64(_mainnetUserStakeB64));
      raw[0] ^= 0xff;
      expect(() => SkrUserStake.decode(raw), throwsA(isA<SkrStakeLayoutException>()));
    });

    test('active stake rounds down, like the program', () {
      final s = SkrUserStake(
        stakeConfig: '', user: '', guardianPool: '',
        shares: BigInt.from(3),
      );
      // 3 × 1.5 = 4.5 base units → 4.
      expect(s.activeBaseUnits(BigInt.from(1500000000)), BigInt.from(4));
    });
  });

  group('SkrStakeSnapshot', () {
    final g = SkrStakingDeployment.mainnet.guardians.single;
    SkrStakeSnapshot snap(List<SkrStakePosition> p) => SkrStakeSnapshot(
          wallet: _mainnetUser,
          cluster: SkrStakingCluster.mainnet,
          positions: p,
          sharePrice: BigInt.from(1000000000),
          cooldownSeconds: 172800,
          fetchedAt: DateTime.utc(2026, 10, 6),
        );

    test('a wallet that never staked has zero active stake', () {
      final s = snap(const []);
      expect(s.totalActiveBaseUnits, BigInt.zero);
      expect(s.totalActiveSkr, 0);
      expect(s.guardianNames, isEmpty);
    });

    test('sums positions and reports whole SKR', () {
      final s = snap([
        SkrStakePosition(guardian: g, shares: BigInt.one, activeBaseUnits: BigInt.from(250000000)),
      ]);
      expect(s.totalActiveSkr, 250.0);
      expect(s.guardianNames, ['Solana Mobile']);
    });

    test('a fully-unstaked position (0 shares) does not list its guardian', () {
      final s = snap([
        SkrStakePosition(guardian: g, shares: BigInt.zero, activeBaseUnits: BigInt.zero),
      ]);
      expect(s.guardianNames, isEmpty);
    });
  });
}
