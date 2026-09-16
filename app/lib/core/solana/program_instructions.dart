import 'dart:convert';
import 'dart:typed_data';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'network_config.dart';

/// Instruction builders for ClockIn reputation Anchor program.
class ProgramInstructions {
  ProgramInstructions._();

  /// System Program ID: 11111111111111111111111111111111
  static final Ed25519HDPublicKey systemProgramId =
      Ed25519HDPublicKey.fromBase58('11111111111111111111111111111111');

  /// Anchor instruction discriminator for register_worker:
  /// sha256("global:register_worker")[0..8]
  static const List<int> registerWorkerDiscriminator = [
    22, 253, 23, 225, 230, 31, 6, 192
  ];

  /// Anchor instruction discriminator for submit_review:
  /// sha256("global:submit_review")[0..8]
  static const List<int> submitReviewDiscriminator = [
    106, 30, 50, 83, 89, 46, 213, 239
  ];

  /// Anchor instruction discriminator for create_and_fund:
  /// sha256("global:create_and_fund")[0..8]
  static const List<int> createAndFundDiscriminator = [
    81, 241, 83, 179, 19, 203, 167, 64
  ];

  /// Anchor instruction discriminator for accept_contract:
  /// sha256("global:accept_contract")[0..8]
  static const List<int> acceptContractDiscriminator = [
    217, 254, 164, 16, 244, 59, 30, 81
  ];

  /// Anchor instruction discriminator for release_and_review:
  /// sha256("global:release_and_review")[0..8]
  static const List<int> releaseAndReviewDiscriminator = [
    234, 163, 144, 157, 56, 76, 46, 44
  ];

  /// Anchor instruction discriminator for cancel_contract:
  /// sha256("global:cancel_contract")[0..8]
  static const List<int> cancelContractDiscriminator = [
    3, 168, 37, 73, 140, 194, 156, 165
  ];

  /// Anchor instruction discriminator for raise_dispute:
  /// sha256("global:raise_dispute")[0..8]
  static const List<int> raiseDisputeDiscriminator = [
    41, 243, 1, 51, 150, 95, 246, 73
  ];

  /// Builds a `register_worker` instruction.
  /// Accounts:
  /// 0. [writable, signer] worker
  /// 1. [writable] worker_profile (PDA: [b"worker", worker])
  /// 2. [] system_program
  static Future<Instruction> registerWorker({
    required Ed25519HDPublicKey worker,
  }) async {
    final workerProfilePda = await NetworkConfig.findWorkerProfilePda(worker);

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: worker, isSigner: true),
        AccountMeta.writeable(pubKey: workerProfilePda, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(registerWorkerDiscriminator),
    );
  }

  /// Builds a `submit_review` instruction.
  /// Accounts:
  /// 0. [writable, signer] reviewer
  /// 1. [writable] worker_profile (PDA: [b"worker", worker])
  /// 2. [writable] review (PDA: [b"review", worker, job_id])
  /// 3. [] system_program
  static Future<Instruction> submitReview({
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey reviewer,
    required String jobId,
    required int rating,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be between 1 and 5');
    }
    if (jobId.isEmpty || jobId.length > 32) {
      throw ArgumentError.value(
        jobId,
        'jobId',
        'Job ID must be between 1 and 32 characters',
      );
    }
    if (worker == reviewer) {
      throw ArgumentError('Worker cannot submit a review for themself');
    }

    final workerProfilePda = await NetworkConfig.findWorkerProfilePda(worker);
    final reviewPda = await NetworkConfig.findReviewPda(
      worker: worker,
      jobId: jobId,
    );

    // Encode instruction data: 8-byte discriminator + Borsh string + u8 rating
    final jobIdBytes = utf8.encode(jobId);
    final byteData = ByteData(4 + jobIdBytes.length + 1);

    // 4-byte length prefix (u32 little endian)
    byteData.setUint32(0, jobIdBytes.length, Endian.little);

    final encodedData = Uint8List(8 + 4 + jobIdBytes.length + 1);
    encodedData.setRange(0, 8, submitReviewDiscriminator);
    encodedData.setRange(8, 12, byteData.buffer.asUint8List(0, 4));
    encodedData.setRange(12, 12 + jobIdBytes.length, jobIdBytes);
    encodedData[12 + jobIdBytes.length] = rating;

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: reviewer, isSigner: true),
        AccountMeta.writeable(pubKey: workerProfilePda, isSigner: false),
        AccountMeta.writeable(pubKey: reviewPda, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(encodedData),
    );
  }

  /// Builds a `create_and_fund` instruction.
  /// Accounts:
  /// 0. [writable, signer] employer
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  /// 2. [writable] vault (PDA: [b"vault", contract_id])
  /// 3. [] system_program
  static Future<Instruction> createAndFund({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required BigInt amountLamports,
    required List<int> termsHash,
    DateTime? deadline,
  }) async {
    if (contractId.isEmpty || contractId.length > 32) {
      throw ArgumentError.value(
        contractId,
        'contractId',
        'Contract ID must be between 1 and 32 characters',
      );
    }
    if (termsHash.length != 32) {
      throw ArgumentError.value(
        termsHash.length,
        'termsHash',
        'Terms hash must be exactly 32 bytes',
      );
    }
    if (employer == worker) {
      throw ArgumentError('Employer cannot hire themself');
    }
    if (amountLamports <= BigInt.zero) {
      throw ArgumentError.value(
        amountLamports,
        'amountLamports',
        'Amount must be greater than zero',
      );
    }

    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);

    final contractIdBytes = utf8.encode(contractId);
    final deadlineSeconds = deadline != null
        ? deadline.millisecondsSinceEpoch ~/ 1000
        : 0;

    final totalLen = 8 + 4 + contractIdBytes.length + 32 + 8 + 32 + 8;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    // Discriminator
    uint8List.setRange(0, 8, createAndFundDiscriminator);
    int offset = 8;

    // contract_id length + string
    byteData.setUint32(offset, contractIdBytes.length, Endian.little);
    offset += 4;
    uint8List.setRange(offset, offset + contractIdBytes.length, contractIdBytes);
    offset += contractIdBytes.length;

    // worker pubkey (32 bytes)
    uint8List.setRange(offset, offset + 32, worker.bytes);
    offset += 32;

    // amount (u64 little-endian)
    byteData.setUint64(offset, amountLamports.toInt(), Endian.little);
    offset += 8;

    // terms_hash (32 bytes)
    uint8List.setRange(offset, offset + 32, termsHash);
    offset += 32;

    // deadline (i64 little-endian)
    byteData.setInt64(offset, deadlineSeconds, Endian.little);
    offset += 8;

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: employer, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds an `accept_contract` instruction.
  /// Accounts:
  /// 0. [writable, signer] worker
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  static Future<Instruction> acceptContract({
    required Ed25519HDPublicKey worker,
    required String contractId,
  }) async {
    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final contractIdBytes = utf8.encode(contractId);

    final totalLen = 8 + 4 + contractIdBytes.length;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, acceptContractDiscriminator);
    byteData.setUint32(8, contractIdBytes.length, Endian.little);
    uint8List.setRange(12, 12 + contractIdBytes.length, contractIdBytes);

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: worker, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds a `release_and_review` instruction.
  /// Accounts:
  /// 0. [writable, signer] employer
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  /// 2. [writable] vault (PDA: [b"vault", contract_id])
  /// 3. [writable] worker
  /// 4. [writable] worker_profile (PDA: [b"worker", worker])
  /// 5. [writable] review (PDA: [b"review", worker, contract_id])
  /// 6. [] system_program
  static Future<Instruction> releaseAndReview({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required int rating,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be between 1 and 5');
    }

    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final workerProfilePda = await NetworkConfig.findWorkerProfilePda(worker);
    final reviewPda = await NetworkConfig.findReviewPda(
      worker: worker,
      jobId: contractId,
    );

    final contractIdBytes = utf8.encode(contractId);
    final totalLen = 8 + 4 + contractIdBytes.length + 1;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, releaseAndReviewDiscriminator);
    int offset = 8;
    byteData.setUint32(offset, contractIdBytes.length, Endian.little);
    offset += 4;
    uint8List.setRange(offset, offset + contractIdBytes.length, contractIdBytes);
    offset += contractIdBytes.length;
    uint8List[offset] = rating;

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: employer, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.writeable(pubKey: worker, isSigner: false),
        AccountMeta.writeable(pubKey: workerProfilePda, isSigner: false),
        AccountMeta.writeable(pubKey: reviewPda, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds a `cancel_contract` instruction.
  /// Accounts:
  /// 0. [writable, signer] employer
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  /// 2. [writable] vault (PDA: [b"vault", contract_id])
  static Future<Instruction> cancelContract({
    required Ed25519HDPublicKey employer,
    required String contractId,
  }) async {
    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final contractIdBytes = utf8.encode(contractId);

    final totalLen = 8 + 4 + contractIdBytes.length;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, cancelContractDiscriminator);
    byteData.setUint32(8, contractIdBytes.length, Endian.little);
    uint8List.setRange(12, 12 + contractIdBytes.length, contractIdBytes);

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: employer, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds a `raise_dispute` instruction.
  /// Accounts:
  /// 0. [writable, signer] caller (employer or worker)
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  static Future<Instruction> raiseDispute({
    required Ed25519HDPublicKey caller,
    required String contractId,
  }) async {
    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final contractIdBytes = utf8.encode(contractId);

    final totalLen = 8 + 4 + contractIdBytes.length;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, raiseDisputeDiscriminator);
    byteData.setUint32(8, contractIdBytes.length, Endian.little);
    uint8List.setRange(12, 12 + contractIdBytes.length, contractIdBytes);

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: caller, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }
}
