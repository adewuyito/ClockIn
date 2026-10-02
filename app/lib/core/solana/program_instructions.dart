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

  /// Anchor instruction discriminator for create_and_fund_token:
  /// sha256("global:create_and_fund_token")[0..8]
  static const List<int> createAndFundTokenDiscriminator = [
    184, 247, 39, 231, 176, 8, 150, 71
  ];

  /// Anchor instruction discriminator for release_and_review_token:
  /// sha256("global:release_and_review_token")[0..8]
  static const List<int> releaseAndReviewTokenDiscriminator = [
    213, 98, 110, 16, 64, 202, 231, 134
  ];

  /// Anchor instruction discriminator for cancel_token_contract:
  /// sha256("global:cancel_token_contract")[0..8]
  static const List<int> cancelTokenContractDiscriminator = [
    164, 206, 114, 109, 35, 64, 101, 152
  ];

  /// Anchor instruction discriminator for resolve_dispute:
  /// sha256("global:resolve_dispute")[0..8]
  static const List<int> resolveDisputeDiscriminator = [
    231, 6, 202, 6, 96, 103, 12, 230
  ];

  /// Anchor instruction discriminator for resolve_token_dispute:
  /// sha256("global:resolve_token_dispute")[0..8]
  static const List<int> resolveTokenDisputeDiscriminator = [
    42, 3, 244, 169, 158, 178, 251, 10
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

  /// Builds a `create_and_fund_token` instruction for SPL tokens ($SKR).
  /// Accounts:
  /// 0. [writable, signer] employer
  /// 1. [] mint
  /// 2. [writable] employer_token_account
  /// 3. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  /// 4. [writable] vault (PDA: [b"vault", contract_id])
  /// 5. [writable] vault_token_account (ATA owned by vault PDA)
  /// 6. [] token_program
  /// 7. [] associated_token_program
  /// 8. [] system_program
  static Future<Instruction> createAndFundToken({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required BigInt amountTokenBaseUnits,
    required List<int> termsHash,
    DateTime? deadline,
    required Ed25519HDPublicKey mint,
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
    if (amountTokenBaseUnits <= BigInt.zero) {
      throw ArgumentError.value(
        amountTokenBaseUnits,
        'amountTokenBaseUnits',
        'Amount must be greater than zero',
      );
    }

    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final vaultTokenAta = await NetworkConfig.findVaultTokenAddress(
      contractId: contractId,
      mint: mint,
    );
    final employerTokenAta = await NetworkConfig.findAssociatedTokenAddress(
      owner: employer,
      mint: mint,
    );

    final contractIdBytes = utf8.encode(contractId);
    final deadlineSeconds = deadline != null
        ? deadline.millisecondsSinceEpoch ~/ 1000
        : 0;

    final totalLen = 8 + 4 + contractIdBytes.length + 32 + 8 + 32 + 8;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    // Discriminator
    uint8List.setRange(0, 8, createAndFundTokenDiscriminator);
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
    byteData.setUint64(offset, amountTokenBaseUnits.toInt(), Endian.little);
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
        AccountMeta.readonly(pubKey: mint, isSigner: false),
        AccountMeta.writeable(pubKey: employerTokenAta, isSigner: false),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultTokenAta, isSigner: false),
        AccountMeta.readonly(pubKey: NetworkConfig.tokenProgramId, isSigner: false),
        AccountMeta.readonly(pubKey: NetworkConfig.associatedTokenProgramId, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds a `release_and_review_token` instruction for SPL tokens ($SKR).
  /// Accounts:
  /// 0. [writable, signer] employer
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  /// 2. [] mint
  /// 3. [writable] vault (PDA: [b"vault", contract_id])
  /// 4. [writable] vault_token_account (ATA owned by vault PDA)
  /// 5. [writable] worker
  /// 6. [writable] worker_token_account (ATA owned by worker)
  /// 7. [writable] worker_profile (PDA: [b"worker", worker])
  /// 8. [writable] review (PDA: [b"review", worker, contract_id])
  /// 9. [] token_program
  /// 10. [] system_program
  static Future<Instruction> releaseAndReviewToken({
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required int rating,
    required Ed25519HDPublicKey mint,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Rating must be between 1 and 5');
    }

    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final vaultTokenAta = await NetworkConfig.findVaultTokenAddress(
      contractId: contractId,
      mint: mint,
    );
    final workerTokenAta = await NetworkConfig.findAssociatedTokenAddress(
      owner: worker,
      mint: mint,
    );
    final workerProfilePda = await NetworkConfig.findWorkerProfilePda(worker);
    final reviewPda = await NetworkConfig.findReviewPda(
      worker: worker,
      jobId: contractId,
    );

    final contractIdBytes = utf8.encode(contractId);
    final totalLen = 8 + 4 + contractIdBytes.length + 1;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, releaseAndReviewTokenDiscriminator);
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
        AccountMeta.readonly(pubKey: mint, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultTokenAta, isSigner: false),
        AccountMeta.writeable(pubKey: worker, isSigner: false),
        AccountMeta.writeable(pubKey: workerTokenAta, isSigner: false),
        AccountMeta.writeable(pubKey: workerProfilePda, isSigner: false),
        AccountMeta.writeable(pubKey: reviewPda, isSigner: false),
        AccountMeta.readonly(pubKey: NetworkConfig.tokenProgramId, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds a `cancel_token_contract` instruction for SPL tokens ($SKR).
  /// Accounts:
  /// 0. [writable, signer] employer
  /// 1. [writable] escrow_contract (PDA: [b"escrow", contract_id])
  /// 2. [] mint
  /// 3. [writable] vault (PDA: [b"vault", contract_id])
  /// 4. [writable] vault_token_account (ATA owned by vault PDA)
  /// 5. [writable] employer_token_account (ATA owned by employer)
  /// 6. [] token_program
  static Future<Instruction> cancelTokenContract({
    required Ed25519HDPublicKey employer,
    required String contractId,
    required Ed25519HDPublicKey mint,
  }) async {
    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final vaultTokenAta = await NetworkConfig.findVaultTokenAddress(
      contractId: contractId,
      mint: mint,
    );
    final employerTokenAta = await NetworkConfig.findAssociatedTokenAddress(
      owner: employer,
      mint: mint,
    );
    final contractIdBytes = utf8.encode(contractId);

    final totalLen = 8 + 4 + contractIdBytes.length;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, cancelTokenContractDiscriminator);
    byteData.setUint32(8, contractIdBytes.length, Endian.little);
    uint8List.setRange(12, 12 + contractIdBytes.length, contractIdBytes);

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: employer, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.readonly(pubKey: mint, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultTokenAta, isSigner: false),
        AccountMeta.writeable(pubKey: employerTokenAta, isSigner: false),
        AccountMeta.readonly(pubKey: NetworkConfig.tokenProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds an instruction to create an Associated Token Account idempotently.
  static Future<Instruction> createAssociatedTokenAccountIdempotent({
    required Ed25519HDPublicKey fundingAccount,
    required Ed25519HDPublicKey walletAddress,
    required Ed25519HDPublicKey mint,
  }) async {
    final ataAddress = await NetworkConfig.findAssociatedTokenAddress(
      owner: walletAddress,
      mint: mint,
    );

    return Instruction(
      programId: NetworkConfig.associatedTokenProgramId,
      accounts: [
        AccountMeta.writeable(pubKey: fundingAccount, isSigner: true),
        AccountMeta.writeable(pubKey: ataAddress, isSigner: false),
        AccountMeta.readonly(pubKey: walletAddress, isSigner: false),
        AccountMeta.readonly(pubKey: mint, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
        AccountMeta.readonly(pubKey: NetworkConfig.tokenProgramId, isSigner: false),
      ],
      data: ByteArray([1]), // 1 = CreateIdempotent
    );
  }

  /// Builds a `resolve_dispute` instruction for native SOL escrows.
  static Future<Instruction> resolveDispute({
    required Ed25519HDPublicKey caller,
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required String contractId,
    required DisputeResolution resolution,
  }) async {
    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final contractIdBytes = utf8.encode(contractId);

    final totalLen = 8 + 4 + contractIdBytes.length + 1;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, resolveDisputeDiscriminator);
    int offset = 8;
    byteData.setUint32(offset, contractIdBytes.length, Endian.little);
    offset += 4;
    uint8List.setRange(offset, offset + contractIdBytes.length, contractIdBytes);
    offset += contractIdBytes.length;
    uint8List[offset] = resolution.value;

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: caller, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.writeable(pubKey: worker, isSigner: false),
        AccountMeta.writeable(pubKey: employer, isSigner: false),
        AccountMeta.readonly(pubKey: systemProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }

  /// Builds a `resolve_token_dispute` instruction for SPL token ($SKR) escrows.
  static Future<Instruction> resolveTokenDispute({
    required Ed25519HDPublicKey caller,
    required Ed25519HDPublicKey employer,
    required Ed25519HDPublicKey worker,
    required Ed25519HDPublicKey mint,
    required String contractId,
    required DisputeResolution resolution,
  }) async {
    final escrowPda = await NetworkConfig.findEscrowPda(contractId);
    final vaultPda = await NetworkConfig.findVaultPda(contractId);
    final vaultTokenAta = await NetworkConfig.findVaultTokenAddress(
      contractId: contractId,
      mint: mint,
    );
    final workerTokenAta = await NetworkConfig.findAssociatedTokenAddress(
      owner: worker,
      mint: mint,
    );
    final employerTokenAta = await NetworkConfig.findAssociatedTokenAddress(
      owner: employer,
      mint: mint,
    );
    final contractIdBytes = utf8.encode(contractId);

    final totalLen = 8 + 4 + contractIdBytes.length + 1;
    final byteData = ByteData(totalLen);
    final uint8List = byteData.buffer.asUint8List();

    uint8List.setRange(0, 8, resolveTokenDisputeDiscriminator);
    int offset = 8;
    byteData.setUint32(offset, contractIdBytes.length, Endian.little);
    offset += 4;
    uint8List.setRange(offset, offset + contractIdBytes.length, contractIdBytes);
    offset += contractIdBytes.length;
    uint8List[offset] = resolution.value;

    return Instruction(
      programId: NetworkConfig.programId,
      accounts: [
        AccountMeta.writeable(pubKey: caller, isSigner: true),
        AccountMeta.writeable(pubKey: escrowPda, isSigner: false),
        AccountMeta.readonly(pubKey: mint, isSigner: false),
        AccountMeta.writeable(pubKey: vaultPda, isSigner: false),
        AccountMeta.writeable(pubKey: vaultTokenAta, isSigner: false),
        AccountMeta.writeable(pubKey: worker, isSigner: false),
        AccountMeta.writeable(pubKey: workerTokenAta, isSigner: false),
        AccountMeta.writeable(pubKey: employer, isSigner: false),
        AccountMeta.writeable(pubKey: employerTokenAta, isSigner: false),
        AccountMeta.readonly(pubKey: NetworkConfig.tokenProgramId, isSigner: false),
      ],
      data: ByteArray(uint8List),
    );
  }
}

/// Dispute resolution outcomes supported on Solana.
enum DisputeResolution {
  releaseToWorker,
  refundToEmployer,
  split5050;

  int get value {
    switch (this) {
      case DisputeResolution.releaseToWorker:
        return 0;
      case DisputeResolution.refundToEmployer:
        return 1;
      case DisputeResolution.split5050:
        return 2;
    }
  }
}
