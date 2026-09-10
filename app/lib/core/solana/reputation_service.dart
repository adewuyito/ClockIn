import 'dart:typed_data';
import 'package:solana/dto.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import '../models/review.dart';
import '../models/worker_profile.dart';
import 'account_decoders.dart';
import 'network_config.dart';
import 'program_instructions.dart';
import 'wallet_adapter.dart';

/// Service interfacing with the ClockIn Anchor program on Solana Devnet.
class ReputationService {
  final SolanaClient solanaClient;

  ReputationService({SolanaClient? client})
      : solanaClient = client ??
            SolanaClient(
              rpcUrl: Uri.parse(NetworkConfig.devnetRpcUrl),
              websocketUrl: Uri.parse(NetworkConfig.devnetWsUrl),
            );

  /// Reads a worker's on-chain WorkerProfile account via RPC getAccountInfo.
  /// Returns null if the worker has not registered yet.
  Future<WorkerProfile?> getWorkerProfile(Ed25519HDPublicKey worker) async {
    final pda = await NetworkConfig.findWorkerProfilePda(worker);

    final accountInfo = await solanaClient.rpcClient.getAccountInfo(
      pda.toBase58(),
      encoding: Encoding.base64,
      commitment: Commitment.confirmed,
    );

    final account = accountInfo.value;
    if (account == null) {
      return null;
    }

    final data = account.data;
    if (data is BinaryAccountData) {
      return AccountDecoders.decodeWorkerProfile(data.data);
    }

    return null;
  }

  /// Queries all confirmed Review accounts for a specific worker.
  /// Uses getProgramAccounts with memcmp filters matching the Review discriminator
  /// and the worker's public key at offset 8.
  Future<List<Review>> getWorkerReviews(Ed25519HDPublicKey worker) async {
    final accounts = await solanaClient.rpcClient.getProgramAccounts(
      NetworkConfig.programIdString,
      encoding: Encoding.base64,
      commitment: Commitment.confirmed,
      filters: [
        ProgramDataFilter.memcmp(
          offset: 0,
          bytes: AccountDecoders.reviewDiscriminator,
        ),
        ProgramDataFilter.memcmpBase58(
          offset: 8,
          bytes: worker.toBase58(),
        ),
      ],
    );

    final reviews = <Review>[];
    for (final account in accounts) {
      try {
        final data = account.account.data;
        if (data is BinaryAccountData) {
          reviews.add(AccountDecoders.decodeReview(data.data));
        }
      } catch (_) {
        // Skip unparseable accounts
      }
    }

    // Sort newest first
    reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reviews;
  }

  /// Builds a `register_worker` transaction, signs via MWA, and waits for confirmation.
  Future<String> registerWorker({
    required Ed25519HDPublicKey worker,
    required WalletAdapter walletAdapter,
  }) async {
    final instruction = await ProgramInstructions.registerWorker(worker: worker);

    final latestBlockhash =
        await solanaClient.rpcClient.getLatestBlockhash(
          commitment: Commitment.confirmed,
        );

    final compiledMessage = Message.only(instruction).compile(
      recentBlockhash: latestBlockhash.value.blockhash,
      feePayer: worker,
    );

    final txBytes = Uint8List.fromList(
      SignedTx(compiledMessage: compiledMessage).toByteArray().toList(),
    );

    final signature = await walletAdapter.signAndSendTransaction(txBytes);

    await solanaClient.waitForSignatureStatus(
      signature,
      status: Commitment.confirmed,
    );

    return signature;
  }

  /// Builds a `submit_review` transaction, signs via MWA, and waits for confirmation.
  Future<String> submitReview({
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey reviewer,
    required String jobId,
    required int rating,
    required WalletAdapter walletAdapter,
  }) async {
    final instruction = await ProgramInstructions.submitReview(
      worker: worker,
      reviewer: reviewer,
      jobId: jobId,
      rating: rating,
    );

    final latestBlockhash =
        await solanaClient.rpcClient.getLatestBlockhash(
          commitment: Commitment.confirmed,
        );

    final compiledMessage = Message.only(instruction).compile(
      recentBlockhash: latestBlockhash.value.blockhash,
      feePayer: reviewer,
    );

    final txBytes = Uint8List.fromList(
      SignedTx(compiledMessage: compiledMessage).toByteArray().toList(),
    );

    final signature = await walletAdapter.signAndSendTransaction(txBytes);

    await solanaClient.waitForSignatureStatus(
      signature,
      status: Commitment.confirmed,
    );

    return signature;
  }
}
