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

  /// Resolves an active dispute on a native SOL escrow contract.
  Future<String> resolveDispute({
    required Ed25519HDPublicKey caller,
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required DisputeResolution resolution,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendWithRetry(
        feePayer: caller,
        walletAdapter: walletAdapter,
        buildInstruction: () => ProgramInstructions.resolveDispute(
          caller: caller,
          employer: employer,
          worker: worker,
          contractId: contractId,
          resolution: resolution,
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

  /// Resolves an active dispute on an SPL token ($SKR) escrow contract.
  Future<String> resolveTokenDispute({
    required Ed25519HDPublicKey caller,
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey mint,
    required String contractId,
    required DisputeResolution resolution,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendInstructionsWithRetry(
        feePayer: caller,
        walletAdapter: walletAdapter,
        buildInstructions: () async {
          final instructions = <Instruction>[];

          // Check if worker ATA exists; if not, prepend idempotent ATA creation
          final workerAta = await NetworkConfig.findAssociatedTokenAddress(
            owner: worker,
            mint: mint,
          );
          final workerAtaInfo = await solanaClient.rpcClient.getAccountInfo(
            workerAta.toBase58(),
            encoding: Encoding.base64,
            commitment: Commitment.confirmed,
          );
          if (workerAtaInfo.value == null) {
            instructions.add(
              await ProgramInstructions.createAssociatedTokenAccountIdempotent(
                fundingAccount: caller,
                walletAddress: worker,
                mint: mint,
              ),
            );
          }

          // Check if employer ATA exists; if not, prepend idempotent ATA creation
          final employerAta = await NetworkConfig.findAssociatedTokenAddress(
            owner: employer,
            mint: mint,
          );
          final employerAtaInfo = await solanaClient.rpcClient.getAccountInfo(
            employerAta.toBase58(),
            encoding: Encoding.base64,
            commitment: Commitment.confirmed,
          );
          if (employerAtaInfo.value == null) {
            instructions.add(
              await ProgramInstructions.createAssociatedTokenAccountIdempotent(
                fundingAccount: caller,
                walletAddress: employer,
                mint: mint,
              ),
            );
          }

          instructions.add(
            await ProgramInstructions.resolveTokenDispute(
              caller: caller,
              employer: employer,
              worker: worker,
              mint: mint,
              contractId: contractId,
              resolution: resolution,
            ),
          );

          return instructions;
        },
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

  /// Creates and funds an SPL token ($SKR) escrow contract.
  Future<String> createAndFundToken({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required BigInt amountTokenBaseUnits,
    required List<int> termsHash,
    DateTime? deadline,
    required Ed25519HDPublicKey mint,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendInstructionsWithRetry(
        feePayer: employer,
        walletAdapter: walletAdapter,
        buildInstructions: () async {
          final instruction = await ProgramInstructions.createAndFundToken(
            employer: employer,
            worker: worker,
            contractId: contractId,
            amountTokenBaseUnits: amountTokenBaseUnits,
            termsHash: termsHash,
            deadline: deadline,
            mint: mint,
          );
          return [instruction];
        },
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

  /// Releases escrow token payment to worker and submits on-chain rating.
  /// Automatically ensures worker has an ATA created idempotently if not already present.
  Future<String> releaseAndReviewToken({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required int rating,
    required Ed25519HDPublicKey mint,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendInstructionsWithRetry(
        feePayer: employer,
        walletAdapter: walletAdapter,
        buildInstructions: () async {
          final instructions = <Instruction>[];

          // Check if worker ATA exists; if not, prepend idempotent ATA creation
          final workerAta = await NetworkConfig.findAssociatedTokenAddress(
            owner: worker,
            mint: mint,
          );
          final ataInfo = await solanaClient.rpcClient.getAccountInfo(
            workerAta.toBase58(),
            encoding: Encoding.base64,
            commitment: Commitment.confirmed,
          );

          if (ataInfo.value == null) {
            instructions.add(
              await ProgramInstructions.createAssociatedTokenAccountIdempotent(
                fundingAccount: employer,
                walletAddress: worker,
                mint: mint,
              ),
            );
          }

          instructions.add(
            await ProgramInstructions.releaseAndReviewToken(
              employer: employer,
              worker: worker,
              contractId: contractId,
              rating: rating,
              mint: mint,
            ),
          );

          return instructions;
        },
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

  /// Employer cancels an unaccepted SPL token escrow contract, reclaiming vault tokens.
  Future<String> cancelTokenContract({
    required Ed25519HDPublicKey employer,
    required String contractId,
    required Ed25519HDPublicKey mint,
    required WalletAdapter walletAdapter,
  }) async {
    try {
      final signature = await _signAndSendInstructionsWithRetry(
        feePayer: employer,
        walletAdapter: walletAdapter,
        buildInstructions: () async {
          final instruction = await ProgramInstructions.cancelTokenContract(
            employer: employer,
            contractId: contractId,
            mint: mint,
          );
          return [instruction];
        },
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
  }) {
    return _signAndSendInstructionsWithRetry(
      feePayer: feePayer,
      walletAdapter: walletAdapter,
      buildInstructions: () async => [await buildInstruction()],
      maxAttempts: maxAttempts,
    );
  }

  Future<String> _signAndSendInstructionsWithRetry({
    required Ed25519HDPublicKey feePayer,
    required WalletAdapter walletAdapter,
    required Future<List<Instruction>> Function() buildInstructions,
    int maxAttempts = 2,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final instructions = await buildInstructions();

        final latestBlockhash = await solanaClient.rpcClient.getLatestBlockhash(
          commitment: Commitment.confirmed,
        );

        final compiledMessage = Message(instructions: instructions).compile(
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
    throw StateError('_signAndSendInstructionsWithRetry exhausted attempts without returning or throwing.');
  }

  /// Fetches the live $SKR token balance for a wallet address from Solana Devnet RPC.
  /// Returns 0.0 if the Associated Token Account does not exist or has zero balance.
  Future<double> getSkrBalance(String address) async {
    try {
      final owner = Ed25519HDPublicKey.fromBase58(address);
      final mint = NetworkConfig.skrMint;
      final ata = await NetworkConfig.findAssociatedTokenAddress(
        owner: owner,
        mint: mint,
      );

      final res = await solanaClient.rpcClient.getTokenAccountBalance(
        ata.toBase58(),
        commitment: Commitment.confirmed,
      );
      final uiStr = res.value.uiAmountString;
      if (uiStr != null) {
        return double.tryParse(uiStr) ?? 0.0;
      }
      return 0.0;
    } catch (_) {
      // ATA doesn't exist yet or has no balance
      return 0.0;
    }
  }

  /// Faucet: Mints devnet $SKR tokens directly to a recipient wallet on Solana Devnet.
  Future<String> airdropDevnetSkr({
    required Ed25519HDPublicKey recipient,
    double amount = 500.0,
  }) async {
    try {
      final privateKeyBytes = NetworkConfig.devnetSkrFaucetPrivateKey.length == 64
          ? NetworkConfig.devnetSkrFaucetPrivateKey.sublist(0, 32)
          : NetworkConfig.devnetSkrFaucetPrivateKey;
      final faucetKey = await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: privateKeyBytes,
      );
      final mint = NetworkConfig.skrMint;
      final recipientAta = await NetworkConfig.findAssociatedTokenAddress(
        owner: recipient,
        mint: mint,
      );

      final instructions = <Instruction>[];

      // Check if recipient ATA exists; if not, prepend create ATA instruction
      final ataInfo = await solanaClient.rpcClient.getAccountInfo(
        recipientAta.toBase58(),
        encoding: Encoding.base64,
        commitment: Commitment.confirmed,
      );

      if (ataInfo.value == null) {
        instructions.add(
          await ProgramInstructions.createAssociatedTokenAccountIdempotent(
            fundingAccount: faucetKey.publicKey,
            walletAddress: recipient,
            mint: mint,
          ),
        );
      }

      instructions.add(
        TokenInstruction.mintTo(
          mint: mint,
          destination: recipientAta,
          authority: faucetKey.publicKey,
          amount: (amount * 1e6).round(),
        ),
      );

      final signature = await solanaClient.sendAndConfirmTransaction(
        message: Message(instructions: instructions),
        signers: [faucetKey],
        commitment: Commitment.confirmed,
      );

      return signature;
    } catch (e) {
      throw ReputationException.from(e);
    }
  }

  /// Staking: Transfers 250 $SKR from connected wallet to Guardian Stake Vault PDA on-chain.
  /// Routes through Mobile Wallet Adapter (MWA) for Phantom/Solflare approval.
  Future<String> stakeSkrToGuardian({
    required Ed25519HDPublicKey wallet,
    required WalletAdapter walletAdapter,
    double amount = 250.0,
    String guardianName = 'Helius',
  }) async {
    try {
      final mint = NetworkConfig.skrMint;
      final userAta = await NetworkConfig.findAssociatedTokenAddress(
        owner: wallet,
        mint: mint,
      );
      final guardianVaultPda = await NetworkConfig.findGuardianVaultPda(
        guardianName: guardianName,
      );
      final guardianVaultAta = await NetworkConfig.findAssociatedTokenAddress(
        owner: guardianVaultPda,
        mint: mint,
      );

      final signature = await _signAndSendInstructionsWithRetry(
        feePayer: wallet,
        walletAdapter: walletAdapter,
        buildInstructions: () async {
          final instructions = <Instruction>[];

          // Ensure guardian vault ATA exists
          final vaultAtaInfo = await solanaClient.rpcClient.getAccountInfo(
            guardianVaultAta.toBase58(),
            encoding: Encoding.base64,
            commitment: Commitment.confirmed,
          );
          if (vaultAtaInfo.value == null) {
            instructions.add(
              await ProgramInstructions.createAssociatedTokenAccountIdempotent(
                fundingAccount: wallet,
                walletAddress: guardianVaultPda,
                mint: mint,
              ),
            );
          }

          // Transfer $SKR from user ATA to Guardian Vault ATA
          instructions.add(
            TokenInstruction.transfer(
              amount: (amount * 1e6).round(),
              source: userAta,
              destination: guardianVaultAta,
              owner: wallet,
            ),
          );

          return instructions;
        },
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
}
