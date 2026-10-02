import 'dart:convert';
import 'dart:typed_data';
import 'package:solana/solana.dart';
import '../models/worker_profile.dart';
import '../models/review.dart';
import '../models/escrow_contract.dart';
import '../models/dispute_case.dart';

/// Decoders for Anchor accounts stored on Solana.
class AccountDecoders {
  AccountDecoders._();

  /// Anchor account discriminator for WorkerProfile: sha256("account:WorkerProfile")[0..8]
  static const List<int> workerProfileDiscriminator = [
    40, 244, 208, 98, 69, 236, 70, 229
  ];

  /// Anchor account discriminator for Review: sha256("account:Review")[0..8]
  static const List<int> reviewDiscriminator = [
    124, 63, 203, 215, 226, 30, 222, 15
  ];

  /// Anchor account discriminator for EscrowContract: sha256("account:EscrowContract")[0..8]
  static const List<int> escrowContractDiscriminator = [
    217, 21, 73, 45, 210, 127, 211, 81
  ];

  /// Anchor account discriminator for DisputeCase: sha256("account:DisputeCase")[0..8]
  static const List<int> disputeCaseDiscriminator = [
    164, 200, 54, 239, 94, 76, 51, 130
  ];

  /// Decodes raw binary account data into a WorkerProfile domain model.
  static WorkerProfile decodeWorkerProfile(List<int> bytes) {
    if (bytes.length < 61) {
      throw FormatException(
        'WorkerProfile data too short: expected at least 61 bytes, got ${bytes.length}',
      );
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Verify 8-byte Anchor discriminator
    for (int i = 0; i < 8; i++) {
      if (byteData.getUint8(i) != workerProfileDiscriminator[i]) {
        throw const FormatException('Invalid WorkerProfile account discriminator');
      }
    }

    int offset = 8;

    // worker: Pubkey (32 bytes)
    final workerBytes = bytes.sublist(offset, offset + 32);
    final workerAddress = Ed25519HDPublicKey(workerBytes).toBase58();
    offset += 32;

    // total_jobs: u32 (4 bytes, little-endian)
    final totalJobs = byteData.getUint32(offset, Endian.little);
    offset += 4;

    // rating_sum: u64 (8 bytes, little-endian)
    final ratingSum = byteData.getUint64(offset, Endian.little);
    offset += 8;

    // created_at: i64 (8 bytes, little-endian unix timestamp)
    final createdAtSeconds = byteData.getInt64(offset, Endian.little);
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(createdAtSeconds * 1000, isUtc: true);
    offset += 8;

    // bump: u8 (1 byte)
    // ignore: unused_local_variable
    final bump = byteData.getUint8(offset);

    return WorkerProfile(
      address: workerAddress,
      totalJobs: totalJobs,
      ratingSum: BigInt.from(ratingSum),
      createdAt: createdAt,
      syncedAt: DateTime.now().toUtc(),
    );
  }

  /// Decodes raw binary account data into a Review domain model.
  static Review decodeReview(List<int> bytes) {
    if (bytes.length < 82) {
      throw FormatException(
        'Review data too short: expected at least 82 bytes, got ${bytes.length}',
      );
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Verify 8-byte Anchor discriminator
    for (int i = 0; i < 8; i++) {
      if (byteData.getUint8(i) != reviewDiscriminator[i]) {
        throw const FormatException('Invalid Review account discriminator');
      }
    }

    int offset = 8;

    // worker: Pubkey (32 bytes)
    final workerBytes = bytes.sublist(offset, offset + 32);
    final workerAddress = Ed25519HDPublicKey(workerBytes).toBase58();
    offset += 32;

    // reviewer: Pubkey (32 bytes)
    final reviewerBytes = bytes.sublist(offset, offset + 32);
    final reviewerAddress = Ed25519HDPublicKey(reviewerBytes).toBase58();
    offset += 32;

    // job_id: String (4-byte length prefix + utf8 bytes)
    final jobIdLength = byteData.getUint32(offset, Endian.little);
    offset += 4;

    if (bytes.length < offset + jobIdLength + 10) {
      throw const FormatException('Corrupt Review data: job_id length overflow');
    }

    final jobIdBytes = bytes.sublist(offset, offset + jobIdLength);
    final jobId = utf8.decode(jobIdBytes);
    offset += jobIdLength;

    // rating: u8 (1 byte)
    final rating = byteData.getUint8(offset);
    offset += 1;

    // timestamp: i64 (8 bytes, little-endian)
    final timestampSeconds = byteData.getInt64(offset, Endian.little);
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000, isUtc: true);
    offset += 8;

    // bump: u8 (1 byte)
    // ignore: unused_local_variable
    final bump = byteData.getUint8(offset);

    return Review(
      workerAddress: workerAddress,
      reviewerAddress: reviewerAddress,
      jobId: jobId,
      rating: rating,
      timestamp: timestamp,
      syncedAt: DateTime.now().toUtc(),
    );
  }

  /// Decodes raw binary account data into an EscrowContract domain model.
  static EscrowContract decodeEscrowContract(List<int> bytes) {
    if (bytes.length < 150) {
      throw FormatException(
        'EscrowContract data too short: expected at least 150 bytes, got ${bytes.length}',
      );
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Verify 8-byte Anchor discriminator
    for (int i = 0; i < 8; i++) {
      if (byteData.getUint8(i) != escrowContractDiscriminator[i]) {
        throw const FormatException('Invalid EscrowContract account discriminator');
      }
    }

    int offset = 8;

    // contract_id: String (4-byte length prefix + utf8 bytes)
    final contractIdLength = byteData.getUint32(offset, Endian.little);
    offset += 4;

    if (bytes.length < offset + contractIdLength + 100) {
      throw const FormatException('Corrupt EscrowContract data: contract_id length overflow');
    }

    final contractIdBytes = bytes.sublist(offset, offset + contractIdLength);
    final contractId = utf8.decode(contractIdBytes);
    offset += contractIdLength;

    // employer: Pubkey (32 bytes)
    final employerBytes = bytes.sublist(offset, offset + 32);
    final employer = Ed25519HDPublicKey(employerBytes).toBase58();
    offset += 32;

    // worker: Pubkey (32 bytes)
    final workerBytes = bytes.sublist(offset, offset + 32);
    final worker = Ed25519HDPublicKey(workerBytes).toBase58();
    offset += 32;

    // amount: u64 (8 bytes, little-endian)
    final amount = byteData.getUint64(offset, Endian.little);
    offset += 8;

    // terms_hash: [u8; 32]
    final termsHashBytes = bytes.sublist(offset, offset + 32);
    final termsHash = termsHashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    offset += 32;

    // status: u8 (1 byte enum index)
    final statusIndex = byteData.getUint8(offset);
    final status = ContractStatus.fromIndex(statusIndex);
    offset += 1;

    // deadline: i64 (8 bytes, little-endian)
    final deadlineSeconds = byteData.getInt64(offset, Endian.little);
    final deadline = deadlineSeconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(deadlineSeconds * 1000, isUtc: true)
        : null;
    offset += 8;

    // created_at: i64 (8 bytes, little-endian)
    final createdAtSeconds = byteData.getInt64(offset, Endian.little);
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(createdAtSeconds * 1000, isUtc: true);
    offset += 8;

    // funded_at: i64 (8 bytes, little-endian)
    final fundedAtSeconds = byteData.getInt64(offset, Endian.little);
    final fundedAt = fundedAtSeconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(fundedAtSeconds * 1000, isUtc: true)
        : null;
    offset += 8;

    // completed_at: i64 (8 bytes, little-endian)
    final completedAtSeconds = byteData.getInt64(offset, Endian.little);
    final completedAt = completedAtSeconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(completedAtSeconds * 1000, isUtc: true)
        : null;
    offset += 8;

    // rating: u8 (1 byte)
    final rating = byteData.getUint8(offset);
    offset += 1;

    // bump: u8 (1 byte)
    offset += 1;

    // vault_bump: u8 (1 byte)
    offset += 1;

    // is_token: bool (1 byte)
    bool isToken = false;
    if (offset < bytes.length) {
      isToken = byteData.getUint8(offset) != 0;
      offset += 1;
    }

    // token_mint: Pubkey (32 bytes)
    String? tokenMint;
    if (offset + 32 <= bytes.length) {
      final mintBytes = bytes.sublist(offset, offset + 32);
      final mintPubkey = Ed25519HDPublicKey(mintBytes).toBase58();
      if (isToken && mintPubkey != '11111111111111111111111111111111') {
        tokenMint = mintPubkey;
      }
      offset += 32;
    }

    return EscrowContract(
      contractId: contractId,
      employer: employer,
      worker: worker,
      amount: BigInt.from(amount),
      termsHash: termsHash,
      status: status,
      deadline: deadline,
      createdAt: createdAt,
      fundedAt: fundedAt,
      completedAt: completedAt,
      rating: rating,
      isToken: isToken,
      tokenMint: tokenMint,
      syncedAt: DateTime.now().toUtc(),
    );
  }

  /// Decodes raw binary account data into a DisputeCase domain model.
  static DisputeCase decodeDisputeCase(List<int> bytes) {
    if (bytes.length < 8 + 4 + 32 + 96 + 3 + 1 + 1 + 8 + 8 + 1) {
      throw FormatException(
        'DisputeCase data too short: expected at least 162 bytes, got ${bytes.length}',
      );
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Verify 8-byte Anchor discriminator
    for (int i = 0; i < 8; i++) {
      if (byteData.getUint8(i) != disputeCaseDiscriminator[i]) {
        throw const FormatException('Invalid DisputeCase account discriminator');
      }
    }

    int offset = 8;

    // contract_id: Borsh string (4-byte length prefix + utf-8 bytes)
    final contractIdLen = byteData.getUint32(offset, Endian.little);
    offset += 4;
    final contractId = utf8.decode(bytes.sublist(offset, offset + contractIdLen));
    offset += contractIdLen;

    // escrow_contract: Pubkey (32 bytes)
    // ignore: unused_local_variable
    final escrowPubkey = Ed25519HDPublicKey(bytes.sublist(offset, offset + 32)).toBase58();
    offset += 32;

    // jurors: [Pubkey; 3] (3 * 32 = 96 bytes)
    final juror1 = Ed25519HDPublicKey(bytes.sublist(offset, offset + 32)).toBase58();
    offset += 32;
    final juror2 = Ed25519HDPublicKey(bytes.sublist(offset, offset + 32)).toBase58();
    offset += 32;
    final juror3 = Ed25519HDPublicKey(bytes.sublist(offset, offset + 32)).toBase58();
    offset += 32;

    // votes: [u8; 3]
    final vote1 = byteData.getUint8(offset);
    offset += 1;
    final vote2 = byteData.getUint8(offset);
    offset += 1;
    final vote3 = byteData.getUint8(offset);
    offset += 1;

    // quorum_outcome: u8
    final quorumOutcome = byteData.getUint8(offset);
    offset += 1;

    // status: DisputeCaseStatus (1 byte: 0=voting, 1=quorumReached, 2=executed)
    final statusByte = byteData.getUint8(offset);
    offset += 1;
    final DisputeCaseStatus status;
    switch (statusByte) {
      case 0:
        status = DisputeCaseStatus.voting;
        break;
      case 1:
        status = DisputeCaseStatus.quorumReached;
        break;
      case 2:
        status = DisputeCaseStatus.executed;
        break;
      default:
        status = DisputeCaseStatus.voting;
    }

    // created_at: i64 (8 bytes)
    final createdAtSeconds = byteData.getInt64(offset, Endian.little);
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(createdAtSeconds * 1000, isUtc: true);
    offset += 8;

    // resolved_at: i64 (8 bytes)
    final resolvedAtSeconds = byteData.getInt64(offset, Endian.little);
    final resolvedAt = resolvedAtSeconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(resolvedAtSeconds * 1000, isUtc: true)
        : null;
    offset += 8;

    // bump: u8
    // ignore: unused_local_variable
    final bump = byteData.getUint8(offset);

    return DisputeCase(
      contractId: contractId,
      juror1: juror1,
      juror2: juror2,
      juror3: juror3,
      vote1: vote1,
      vote2: vote2,
      vote3: vote3,
      quorumOutcome: quorumOutcome,
      status: status,
      createdAt: createdAt,
      resolvedAt: resolvedAt,
      syncedAt: DateTime.now().toUtc(),
    );
  }
}
