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
}
