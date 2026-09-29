import 'dart:convert';
import 'package:solana/solana.dart';

/// Central network, RPC, and Solana program configuration for ClockIn.
class NetworkConfig {
  NetworkConfig._();

  /// Target Solana cluster name.
  static const String clusterName = 'devnet';

  /// Primary Devnet RPC endpoint.
  static const String devnetRpcUrl = 'https://api.devnet.solana.com';

  /// Primary Devnet WebSocket endpoint.
  static const String devnetWsUrl = 'wss://api.devnet.solana.com';

  /// Human-readable label for the active cluster (e.g. "Devnet"). UI code
  /// should read this — and [rpcUrl]/[wsUrl] below — instead of hardcoding
  /// "Devnet" text or [devnetRpcUrl] directly: this app is devnet-only
  /// today, but if it ever targets mainnet, [clusterName]/[rpcUrl]/[wsUrl]
  /// are the only things that need to change for every screen that reads
  /// them to stay correct automatically.
  static String get clusterDisplayName =>
      clusterName.isEmpty ? clusterName : clusterName[0].toUpperCase() + clusterName.substring(1);

  /// Active RPC URL. Currently always [devnetRpcUrl] — see [clusterDisplayName].
  static String get rpcUrl => devnetRpcUrl;

  /// Active WebSocket URL. Currently always [devnetWsUrl] — see [clusterDisplayName].
  static String get wsUrl => devnetWsUrl;

  /// Returns a full Solana Explorer URL for a path (e.g. `tx/<sig>` or `address/<addr>`).
  static String solanaExplorerUrl(String path) {
    return 'https://explorer.solana.com/$path?cluster=$clusterName';
  }

  /// Deployed ClockIn reputation Anchor program ID on Devnet.
  static const String programIdString =
      'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9';

  /// Parsed Ed25519HDPublicKey for the program ID.
  static final Ed25519HDPublicKey programId =
      Ed25519HDPublicKey.fromBase58(programIdString);

  /// Computes the WorkerProfile Program Derived Address (PDA).
  /// Seeds: [b"worker", worker_pubkey]
  static Future<Ed25519HDPublicKey> findWorkerProfilePda(
    Ed25519HDPublicKey worker,
  ) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        utf8.encode('worker'),
        worker.bytes,
      ],
      programId: programId,
    );
  }

  /// Computes the Review Program Derived Address (PDA).
  /// Seeds: [b"review", worker_pubkey, job_id]
  static Future<Ed25519HDPublicKey> findReviewPda({
    required Ed25519HDPublicKey worker,
    required String jobId,
  }) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        utf8.encode('review'),
        worker.bytes,
        utf8.encode(jobId),
      ],
      programId: programId,
    );
  }

  /// Computes the EscrowContract Program Derived Address (PDA).
  /// Seeds: [b"escrow", contract_id]
  static Future<Ed25519HDPublicKey> findEscrowPda(String contractId) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        utf8.encode('escrow'),
        utf8.encode(contractId),
      ],
      programId: programId,
    );
  }

  /// Computes the EscrowVault Program Derived Address (PDA).
  /// Seeds: [b"vault", contract_id]
  static Future<Ed25519HDPublicKey> findVaultPda(String contractId) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        utf8.encode('vault'),
        utf8.encode(contractId),
      ],
      programId: programId,
    );
  }

  /// SPL Token Program ID: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
  static final Ed25519HDPublicKey tokenProgramId =
      Ed25519HDPublicKey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

  /// SPL Associated Token Account Program ID: ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL
  static final Ed25519HDPublicKey associatedTokenProgramId =
      Ed25519HDPublicKey.fromBase58('ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL');

  /// Default Devnet $SKR Token Mint (Solana Seeker ecosystem token)
  static const String devnetSkrMint =
      'Gd1eTEXDt1D9uyTqCrVTKtaumz7XmZKvfThVEX9856N9';

  /// Parsed Pubkey for devnet $SKR mint
  static final Ed25519HDPublicKey skrMint =
      Ed25519HDPublicKey.fromBase58(devnetSkrMint);

  /// Devnet Faucet Keypair 32-byte seed (authorized mint authority on devnet).
  /// Pubkey: GpCkbpkeXxX5sdFJF9joMmgqMs1P5uyVFHZxvvuDcoz
  static const List<int> devnetSkrFaucetPrivateKey = [
    113, 149, 0, 115, 38, 201, 167, 200, 65, 19, 67, 234, 85, 200, 40, 137,
    78, 251, 156, 20, 190, 161, 128, 70, 130, 82, 37, 63, 11, 183, 27, 152,
  ];

  /// Computes the Guardian Stake Vault PDA.
  /// Seeds: [b"guardian_vault", guardian_name]
  static Future<Ed25519HDPublicKey> findGuardianVaultPda({
    String guardianName = 'helius',
  }) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        utf8.encode('guardian_vault'),
        utf8.encode(guardianName.toLowerCase()),
      ],
      programId: programId,
    );
  }

  /// Computes the Associated Token Account (ATA) for a wallet/PDA and mint.
  /// Seeds: [wallet_address, token_program_id, mint_address]
  static Future<Ed25519HDPublicKey> findAssociatedTokenAddress({
    required Ed25519HDPublicKey owner,
    required Ed25519HDPublicKey mint,
  }) async {
    return Ed25519HDPublicKey.findProgramAddress(
      seeds: [
        owner.bytes,
        tokenProgramId.bytes,
        mint.bytes,
      ],
      programId: associatedTokenProgramId,
    );
  }

  /// Computes the Vault's Associated Token Account (ATA) for a contract and mint.
  static Future<Ed25519HDPublicKey> findVaultTokenAddress({
    required String contractId,
    required Ed25519HDPublicKey mint,
  }) async {
    final vaultPda = await findVaultPda(contractId);
    return findAssociatedTokenAddress(
      owner: vaultPda,
      mint: mint,
    );
  }
}

