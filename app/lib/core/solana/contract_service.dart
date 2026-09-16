import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:solana/dto.dart' hide Instruction;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import '../models/escrow_contract.dart';
import 'account_decoders.dart';
import 'network_config.dart';
import 'program_instructions.dart';
import 'reputation_errors.dart';
import 'wallet_adapter.dart';

/// Service interfacing with the Escrow protocol on Solana Devnet.
class ContractService {
  final SolanaClient solanaClient;

  ContractService({SolanaClient? client})
      : solanaClient = client ??
            SolanaClient(
              rpcUrl: Uri.parse(NetworkConfig.devnetRpcUrl),
              websocketUrl: Uri.parse(NetworkConfig.devnetWsUrl),
            );

  /// Computes 32-byte SHA-256 hash of arbitrary string terms.
  static List<int> computeTermsHash(String terms) {
    return sha256.convert(utf8.encode(terms)).bytes;
  }

  /// Fetches an on-chain EscrowContract account by its contractId.
  /// Returns null if not found.
  Future<EscrowContract?> getContract(String contractId) async {
    final pda = await NetworkConfig.findEscrowPda(contractId);

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
      return AccountDecoders.decodeEscrowContract(data.data);
    }

    return null;
  }

  /// Queries all on-chain EscrowContract accounts via getProgramAccounts.
  Future<List<EscrowContract>> getAllContracts() async {
    final accounts = await solanaClient.rpcClient.getProgramAccounts(
      NetworkConfig.programIdString,
      encoding: Encoding.base64,
      commitment: Commitment.confirmed,
      filters: [
        ProgramDataFilter.memcmp(
          offset: 0,
          bytes: AccountDecoders.escrowContractDiscriminator,
        ),
      ],
    );

    final contracts = <EscrowContract>[];
    for (final account in accounts) {
      try {
        final data = account.account.data;
        if (data is BinaryAccountData) {
          contracts.add(AccountDecoders.decodeEscrowContract(data.data));
        }
      } catch (_) {
        // Skip unparseable accounts
      }
    }

    // Sort newest first
    contracts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return contracts;
  }

  /// Queries all contracts where the given address is either employer or worker.
  Future<List<EscrowContract>> getContractsForParticipant(String walletAddress) async {
    final all = await getAllContracts();
    final lower = walletAddress.toLowerCase();
    return all.where((c) =>
      c.employer.toLowerCase() == lower || c.worker.toLowerCase() == lower
    ).toList();
  }

  /// Creates and funds an escrow contract in a single atomic transaction.
  Future<String> createAndFund({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required BigInt amountLamports,
    required List<int> termsHash,
    DateTime? deadline,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: employer,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.createAndFund(
          employer: employer,
          worker: worker,
          contractId: contractId,
          amountLamports: amountLamports,
          termsHash: termsHash,
          deadline: deadline,
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

  /// Worker accepts an escrow contract, locking it into InProgress.
  Future<String> acceptContract({
    required Ed25519HDPublicKey worker,
    required String contractId,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: worker,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.acceptContract(
          worker: worker,
          contractId: contractId,
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

  /// Employer releases payment to worker and submits on-chain rating.
  Future<String> releaseAndReview({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required int rating,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: employer,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.releaseAndReview(
          employer: employer,
          worker: worker,
          contractId: contractId,
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

  /// Employer cancels an unaccepted contract, reclaiming vault funds.
  Future<String> cancelContract({
    required Ed25519HDPublicKey employer,
    required String contractId,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: employer,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.cancelContract(
          employer: employer,
          contractId: contractId,
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

  /// Either participant raises a dispute.
  Future<String> raiseDispute({
    required Ed25519HDPublicKey caller,
    required String contractId,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: caller,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.raiseDispute(
          caller: caller,
          contractId: contractId,
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
    throw StateError('_signAndSendWithRetry exhausted attempts without returning or throwing.');
  }
}
