import 'dart:convert';
import 'dart:typed_data';
import 'package:solana/solana.dart';
import '../models/worker_profile.dart';
import '../models/review.dart';

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
}
