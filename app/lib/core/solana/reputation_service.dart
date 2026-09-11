import 'dart:typed_data';
import 'package:solana/dto.dart' hide Instruction;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import '../models/review.dart';
import '../models/worker_profile.dart';
import 'account_decoders.dart';
import 'network_config.dart';
import 'program_instructions.dart';
import 'reputation_errors.dart';
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

  /// Builds a `register_worker` transaction, signs via MWA, and waits for
  /// confirmation. Throws a [ReputationException] on any failure — network,
  /// wallet, or on-chain program rejection — never a raw/untyped exception.
  Future<String> registerWorker({
    required Ed25519HDPublicKey worker,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: worker,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.registerWorker(worker: worker),
      );

      await solanaClient.waitForSignatureStatus(
        signature,
        status: Commitment.confirmed,
      );

      return signature;
    } catch (e) {
      throw ReputationException.from(e);
    }
  }

  /// Builds a `submit_review` transaction, signs via MWA, and waits for
  /// confirmation. Throws a [ReputationException] on any failure — network,
  /// wallet, or on-chain program rejection — never a raw/untyped exception.
  Future<String> submitReview({
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey reviewer,
    required String jobId,
    required int rating,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: reviewer,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.submitReview(
          worker: worker,
          reviewer: reviewer,
          jobId: jobId,
          rating: rating,
        ),
      );

      await solanaClient.waitForSignatureStatus(
        signature,
        status: Commitment.confirmed,
      );

      return signature;
    } catch (e) {
      throw ReputationException.from(e);
    }
  }

  /// Compiles, signs (via MWA), and sends a single-instruction transaction,
  /// retrying once with a freshly-fetched blockhash if the wallet rejects it.
  ///
  /// The blockhash is fetched as late as possible (right before compiling),
  /// but MWA's wallet-approval round trip — app switch, wallet cold start,
  /// the user actually reviewing the request — can still comfortably exceed
  /// a blockhash's ~60-90s validity window, especially on the first attempt
  /// against a cold wallet app. Observed directly against devnet: Solflare
  /// surfaces this as "Blockhash expired ... please try signing again",
  /// and a same-instant retry (wallet now warm, session already
  /// established) is materially faster and much more likely to land inside
  /// the window. This does not fix the underlying race — only Solana
  /// durable nonces (a transaction type that isn't tied to a recent
  /// blockhash) remove it entirely — but it recovers the common case
  /// without making the user manually redo the whole connect+approve flow.
  Future<String> _signAndSendWithRetry({
    required Ed25519HDPublicKey feePayer,
    required WalletAdapter walletAdapter,
    required Future<Instruction> Function() buildInstruction,
    int maxAttempts = 2,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final instruction = await buildInstruction();

        final latestBlockhash = await solanaClient.rpcClient.getLatestBlockhash(
          commitment: Commitment.confirmed,
        );

        final compiledMessage = Message.only(instruction).compile(
          recentBlockhash: latestBlockhash.value.blockhash,
          feePayer: feePayer,
        );

        final placeholderSignature = Signature(List.filled(64, 0), publicKey: feePayer);
        final txBytes = Uint8List.fromList(
          SignedTx(
            compiledMessage: compiledMessage,
            signatures: [placeholderSignature],
          ).toByteArray().toList(),
        );

        return await walletAdapter.signAndSendTransaction(txBytes);
      } catch (e) {
        if (attempt >= maxAttempts) {
          rethrow;
        }
      }
    }
    // Unreachable: the loop above always either returns or rethrows on the
    // final attempt.
    throw StateError('_signAndSendWithRetry exhausted attempts without returning or throwing.');
  }
}
