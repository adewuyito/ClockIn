import 'dart:convert';
import 'dart:typed_data';

import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

/// Read-only client for Solana Mobile's official $SKR Guardian staking program —
/// the program behind stake.solanamobile.com and Seed Vault Wallet staking.
///
/// ClockIn never stakes, unstakes, or touches funds here. It only *reads* a
/// wallet's stake so the Seeker attestation reflects stake the user actually
/// holds, made through Solana Mobile's own staking flow.
///
/// ## Provenance of these constants
///
/// Solana Mobile does not publish the program's IDL or account layout. Every
/// constant below was recovered and then verified against the live chain on
/// 2026-10-06 (see `docs/ARCHITECTURE.md`, "Seeker attestation"):
///
/// * Program IDs, guardians and mints come from the staking site's own frontend
///   config, which carries both a mainnet and a devnet deployment.
/// * Account types were identified by Anchor discriminators
///   (`sha256("account:UserStake")[:8]`, `sha256("account:StakeConfig")[:8]`).
/// * PDA seeds were recovered from the stored bump of real accounts and then
///   confirmed against real mainnet stakers: the derived `UserStake` address is
///   the exact account their staking transaction wrote.
/// * The amount formula `shares × share_price / 1e9` was confirmed two ways on
///   devnet — the sum of every user's shares equals `total_shares` exactly, and
///   active stake plus pending unstakes reconciles with the vault's real token
///   balance to within rounding dust — and bounded against the mainnet vault.
///
/// If Solana Mobile upgrades the program, these decoders refuse unexpected
/// discriminators or sizes rather than misreading bytes.
enum SkrStakingCluster { mainnet, devnet }

/// A Guardian that $SKR can be delegated to.
class SkrGuardian {
  final String name;
  final String address;

  const SkrGuardian({required this.name, required this.address});
}

/// One deployment (cluster) of the staking program.
class SkrStakingDeployment {
  final SkrStakingCluster cluster;
  final String rpcUrl;
  final String programId;
  final String mint;
  final List<SkrGuardian> guardians;

  const SkrStakingDeployment({
    required this.cluster,
    required this.rpcUrl,
    required this.programId,
    required this.mint,
    required this.guardians,
  });

  /// Where real Seeker users stake. Read-only use of mainnet: no keys, no
  /// transactions, no funds — see the devnet-only exception in CLAUDE.md.
  static const mainnet = SkrStakingDeployment(
    cluster: SkrStakingCluster.mainnet,
    rpcUrl: String.fromEnvironment(
      'CLOCKIN_SKR_STAKE_RPC',
      defaultValue: 'https://api.mainnet-beta.solana.com',
    ),
    programId: 'SKRskrmtL83pcL4YqLWt6iPefDqwXQWHSw9S9vz94BZ',
    mint: 'SKRbvo6Gf7GondiT3BbTfuRDPqLWei4j2Qy2NPGZhW3',
    guardians: [
      SkrGuardian(
        name: 'Solana Mobile',
        address: 'SKRGdBwzb1AtFW2chhBnZpGFnFLj6Mi7HM7iwjXALvw',
      ),
    ],
  );

  /// Solana Mobile's own devnet deployment of the same program.
  static const devnet = SkrStakingDeployment(
    cluster: SkrStakingCluster.devnet,
    rpcUrl: 'https://api.devnet.solana.com',
    programId: 'HC5a2WahqscUXB61JVUCjhzAbr8NebKWVWSXEJnVBjAF',
    mint: 'Gn72vA2mZWDhP2WQh91Tud9hh3AC3zy2Wyu2nmqfEwY9',
    guardians: [
      SkrGuardian(
        name: 'Solana Mobile',
        address: '7fLs8CKVvv8Dd5VRMhYakr8JEoNBivKZBwpXj7mMfoLy',
      ),
    ],
  );

  /// Selected with `--dart-define=CLOCKIN_SKR_STAKE_CLUSTER=devnet`; defaults
  /// to mainnet because that is where users actually stake.
  static SkrStakingDeployment get active =>
      const String.fromEnvironment('CLOCKIN_SKR_STAKE_CLUSTER') == 'devnet'
          ? devnet
          : mainnet;

  String get clusterName => cluster.name;
}

/// `share_price` is stored as a fixed-point integer with this scale.
final BigInt skrSharePriceScale = BigInt.from(1000000000);

/// $SKR has 6 decimals on both clusters (verified on-chain).
const int skrDecimals = 6;

BigInt _readUint(Uint8List data, int offset, int length) {
  var value = BigInt.zero;
  for (var i = length - 1; i >= 0; i--) {
    value = (value << 8) | BigInt.from(data[offset + i]);
  }
  return value;
}

String _readPubkey(Uint8List data, int offset) =>
    Ed25519HDPublicKey(data.sublist(offset, offset + 32)).toBase58();

bool _hasPrefix(Uint8List data, List<int> prefix) {
  if (data.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (data[i] != prefix[i]) return false;
  }
  return true;
}

/// Thrown when an account does not match the expected staking layout. Callers
/// treat this as "cannot verify", never as "zero stake".
class SkrStakeLayoutException implements Exception {
  final String message;
  const SkrStakeLayoutException(this.message);
  @override
  String toString() => 'SkrStakeLayoutException: $message';
}

/// The program's global `StakeConfig` account.
///
/// Layout (bytes): 8 discriminator · 1 bump · 32 authority · 32 mint ·
/// 32 vault · u64 min_stake_amount @105 · u64 cooldown_seconds @113 ·
/// u64 total_shares @121 · u64 share_price @137 (1e9 fixed point).
class SkrStakeConfig {
  /// `sha256("account:StakeConfig")[..8]`.
  static const List<int> discriminator = [0xee, 0x97, 0x2b, 0x03, 0x0b, 0x97, 0x3f, 0xb0];
  static const int minLength = 193;

  final String mint;
  final String vault;
  final BigInt minStakeAmount;
  final int cooldownSeconds;
  final BigInt totalShares;
  final BigInt sharePrice;

  const SkrStakeConfig({
    required this.mint,
    required this.vault,
    required this.minStakeAmount,
    required this.cooldownSeconds,
    required this.totalShares,
    required this.sharePrice,
  });

  static SkrStakeConfig decode(Uint8List data) {
    if (data.length < minLength || !_hasPrefix(data, discriminator)) {
      throw const SkrStakeLayoutException('Account is not a StakeConfig');
    }
    return SkrStakeConfig(
      mint: _readPubkey(data, 41),
      vault: _readPubkey(data, 73),
      minStakeAmount: _readUint(data, 105, 8),
      cooldownSeconds: _readUint(data, 113, 8).toInt(),
      totalShares: _readUint(data, 121, 8),
      sharePrice: _readUint(data, 137, 8),
    );
  }
}

/// A wallet's `UserStake` account for one Guardian.
///
/// Layout (bytes): 8 discriminator · 1 bump · 32 stake_config @9 ·
/// 32 user @41 · 32 guardian_pool @73 · u128 shares @105. Devnet accounts are
/// 146 bytes and mainnet 169; both share this prefix, and nothing beyond
/// `shares` is read, because the unstake fields after it differ between the
/// two program versions.
class SkrUserStake {
  /// `sha256("account:UserStake")[..8]`.
  static const List<int> discriminator = [0x66, 0x35, 0xa3, 0x6b, 0x09, 0x8a, 0x57, 0x99];
  static const int minLength = 146;

  final String stakeConfig;
  final String user;
  final String guardianPool;
  final BigInt shares;

  const SkrUserStake({
    required this.stakeConfig,
    required this.user,
    required this.guardianPool,
    required this.shares,
  });

  static SkrUserStake decode(Uint8List data) {
    if (data.length < minLength || !_hasPrefix(data, discriminator)) {
      throw const SkrStakeLayoutException('Account is not a UserStake');
    }
    return SkrUserStake(
      stakeConfig: _readPubkey(data, 9),
      user: _readPubkey(data, 41),
      guardianPool: _readPubkey(data, 73),
      shares: _readUint(data, 105, 16),
    );
  }

  /// Active stake in $SKR base units — exactly what the program would pay out
  /// for these shares: `shares × share_price / 1e9`, rounded down.
  BigInt activeBaseUnits(BigInt sharePrice) => shares * sharePrice ~/ skrSharePriceScale;
}

/// The deterministic addresses for one wallet on one deployment.
class SkrStakeAddresses {
  final String stakeConfig;
  final Map<SkrGuardian, String> guardianPools;
  final Map<SkrGuardian, String> userStakes;

  const SkrStakeAddresses({
    required this.stakeConfig,
    required this.guardianPools,
    required this.userStakes,
  });

  /// PDAs:
  ///   StakeConfig  = ["stake_config"]
  ///   GuardianPool = ["guardian_pool", stake_config, guardian]
  ///   UserStake    = ["user_stake", stake_config, user, guardian_pool]
  static Future<SkrStakeAddresses> derive(
    SkrStakingDeployment deployment,
    String wallet,
  ) async {
    final program = Ed25519HDPublicKey.fromBase58(deployment.programId);
    final user = Ed25519HDPublicKey.fromBase58(wallet);
    final config = await Ed25519HDPublicKey.findProgramAddress(
      seeds: [utf8.encode('stake_config')],
      programId: program,
    );

    final pools = <SkrGuardian, String>{};
    final stakes = <SkrGuardian, String>{};
    for (final guardian in deployment.guardians) {
      final pool = await Ed25519HDPublicKey.findProgramAddress(
        seeds: [
          utf8.encode('guardian_pool'),
          config.bytes,
          Ed25519HDPublicKey.fromBase58(guardian.address).bytes,
        ],
        programId: program,
      );
      final stake = await Ed25519HDPublicKey.findProgramAddress(
        seeds: [utf8.encode('user_stake'), config.bytes, user.bytes, pool.bytes],
        programId: program,
      );
      pools[guardian] = pool.toBase58();
      stakes[guardian] = stake.toBase58();
    }

    return SkrStakeAddresses(
      stakeConfig: config.toBase58(),
      guardianPools: pools,
      userStakes: stakes,
    );
  }
}

/// A wallet's active stake with one Guardian.
class SkrStakePosition {
  final SkrGuardian guardian;
  final BigInt shares;
  final BigInt activeBaseUnits;

  const SkrStakePosition({
    required this.guardian,
    required this.shares,
    required this.activeBaseUnits,
  });
}

/// A verified, point-in-time read of a wallet's $SKR stake.
class SkrStakeSnapshot {
  final String wallet;
  final SkrStakingCluster cluster;
  final List<SkrStakePosition> positions;
  final BigInt sharePrice;
  final int cooldownSeconds;
  final DateTime fetchedAt;

  const SkrStakeSnapshot({
    required this.wallet,
    required this.cluster,
    required this.positions,
    required this.sharePrice,
    required this.cooldownSeconds,
    required this.fetchedAt,
  });

  BigInt get totalActiveBaseUnits =>
      positions.fold(BigInt.zero, (sum, p) => sum + p.activeBaseUnits);

  /// Active stake in whole $SKR, for display and threshold checks.
  double get totalActiveSkr => totalActiveBaseUnits.toDouble() / 1e6;

  /// Guardians this wallet actively stakes with.
  List<String> get guardianNames => [
        for (final p in positions)
          if (p.activeBaseUnits > BigInt.zero) p.guardian.name,
      ];
}

/// Anything that can produce a verified stake snapshot for a wallet. The live
/// implementation is [SkrStakeReader]; tests substitute a fake so attestation
/// logic is exercised without network access.
abstract interface class SkrStakeSource {
  SkrStakingCluster get cluster;
  Future<SkrStakeSnapshot> fetch(String wallet);
}

/// Reads a wallet's stake from the staking program.
class SkrStakeReader implements SkrStakeSource {
  final SkrStakingDeployment deployment;
  final RpcClient _rpc;

  SkrStakeReader({required this.deployment, RpcClient? rpcClient})
      : _rpc = rpcClient ?? RpcClient(deployment.rpcUrl);

  @override
  SkrStakingCluster get cluster => deployment.cluster;

  /// Fetches the config and every Guardian position in a single
  /// `getMultipleAccounts` call — not an indexed query, so it works on public
  /// RPC endpoints that throttle `getProgramAccounts`.
  ///
  /// A wallet that never staked simply has no `UserStake` account and yields an
  /// empty snapshot. Any account that exists but fails validation throws
  /// [SkrStakeLayoutException] instead of being read as zero.
  @override
  Future<SkrStakeSnapshot> fetch(String wallet) async {
    final addresses = await SkrStakeAddresses.derive(deployment, wallet);
    final guardians = deployment.guardians;
    final keys = [
      addresses.stakeConfig,
      for (final g in guardians) addresses.userStakes[g]!,
    ];

    final result = await _rpc.getMultipleAccounts(
      keys,
      encoding: Encoding.base64,
      commitment: Commitment.confirmed,
    );
    final accounts = result.value;

    final config = _decodeOwned(accounts[0], SkrStakeConfig.decode, 'StakeConfig');
    if (config == null) {
      throw const SkrStakeLayoutException('StakeConfig account not found');
    }
    if (config.mint != deployment.mint) {
      throw SkrStakeLayoutException(
        'StakeConfig mint ${config.mint} does not match ${deployment.mint}',
      );
    }

    final positions = <SkrStakePosition>[];
    for (var i = 0; i < guardians.length; i++) {
      final guardian = guardians[i];
      final stake = _decodeOwned(accounts[i + 1], SkrUserStake.decode, 'UserStake');
      if (stake == null) continue;

      // The PDA already pins these, but checking costs nothing and catches a
      // layout drift that happened to keep the discriminator.
      if (stake.user != wallet ||
          stake.stakeConfig != addresses.stakeConfig ||
          stake.guardianPool != addresses.guardianPools[guardian]) {
        throw const SkrStakeLayoutException('UserStake fields do not match its PDA');
      }

      positions.add(SkrStakePosition(
        guardian: guardian,
        shares: stake.shares,
        activeBaseUnits: stake.activeBaseUnits(config.sharePrice),
      ));
    }

    return SkrStakeSnapshot(
      wallet: wallet,
      cluster: deployment.cluster,
      positions: positions,
      sharePrice: config.sharePrice,
      cooldownSeconds: config.cooldownSeconds,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  /// Decodes an account only if it exists and is owned by the staking program.
  /// Anyone can send lamports to a PDA address and create a system-owned
  /// account there, so ownership is what makes the bytes trustworthy.
  T? _decodeOwned<T>(Account? account, T Function(Uint8List) decode, String kind) {
    if (account == null) return null;
    if (account.owner != deployment.programId) {
      throw SkrStakeLayoutException('$kind is not owned by the staking program');
    }
    final data = account.data;
    if (data is! BinaryAccountData) {
      throw SkrStakeLayoutException('$kind returned non-binary data');
    }
    return decode(Uint8List.fromList(data.data));
  }
}
