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
}
