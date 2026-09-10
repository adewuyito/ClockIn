import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:clockin/core/solana/account_decoders.dart';
import 'package:clockin/core/solana/network_config.dart';
import 'package:clockin/core/solana/program_instructions.dart';

void main() {
  group('NetworkConfig & PDAs', () {
    test('WorkerProfile PDA derives correctly and deterministically', () async {
      final worker = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );

      final pda1 = await NetworkConfig.findWorkerProfilePda(worker);
      final pda2 = await NetworkConfig.findWorkerProfilePda(worker);

      expect(pda1.toBase58(), equals(pda2.toBase58()));
      expect(pda1.bytes.length, equals(32));
    });

    test('Review PDA derives with jobId seed', () async {
      final worker = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );

      final pda = await NetworkConfig.findReviewPda(
        worker: worker,
        jobId: 'job-101',
      );

      expect(pda.bytes.length, equals(32));
    });
  });

  group('AccountDecoders', () {
    test('Decodes valid WorkerProfile binary account data', () {
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );

      // Construct fake account data:
      // 8-byte discriminator + 32-byte worker + 4-byte totalJobs (u32) + 8-byte ratingSum (u64) + 8-byte createdAt (i64) + 1-byte bump
      final buffer = Uint8List(61);
      final byteData = ByteData.sublistView(buffer);

      // Discriminator
      buffer.setRange(0, 8, AccountDecoders.workerProfileDiscriminator);
      // Worker pubkey
      buffer.setRange(8, 40, workerKey.bytes);
      // total_jobs = 12
      byteData.setUint32(40, 12, Endian.little);
      // rating_sum = 58
      byteData.setUint64(44, 58, Endian.little);
      // created_at = 1700000000
      byteData.setInt64(52, 1700000000, Endian.little);
      // bump = 254
      byteData.setUint8(60, 254);

      final profile = AccountDecoders.decodeWorkerProfile(buffer);

      expect(profile.address, equals(workerKey.toBase58()));
      expect(profile.totalJobs, equals(12));
      expect(profile.ratingSum, equals(BigInt.from(58)));
      expect(profile.averageRating, closeTo(58 / 12, 0.001));
      expect(profile.shortAddress, equals('GBZq…fh8P'));
    });

    test('Throws on invalid discriminator', () {
      final buffer = Uint8List(61);
      // Set all zeros
      expect(
        () => AccountDecoders.decodeWorkerProfile(buffer),
        throwsA(isA<FormatException>()),
      );
    });

    test('Decodes valid Review binary account data', () {
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final reviewerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      const jobId = 'plumbing-shift-4';
      final jobIdBytes = utf8.encode(jobId);

      final buffer = Uint8List(8 + 32 + 32 + 4 + jobIdBytes.length + 1 + 8 + 1);
      final byteData = ByteData.sublistView(buffer);

      // Discriminator
      buffer.setRange(0, 8, AccountDecoders.reviewDiscriminator);
      // Worker
      buffer.setRange(8, 40, workerKey.bytes);
      // Reviewer
      buffer.setRange(40, 72, reviewerKey.bytes);
      // jobId len
      int offset = 72;
      byteData.setUint32(offset, jobIdBytes.length, Endian.little);
      offset += 4;
      buffer.setRange(offset, offset + jobIdBytes.length, jobIdBytes);
      offset += jobIdBytes.length;
      // rating = 5
      byteData.setUint8(offset, 5);
      offset += 1;
      // timestamp = 1710000000
      byteData.setInt64(offset, 1710000000, Endian.little);
      offset += 8;
      // bump = 255
      byteData.setUint8(offset, 255);

      final review = AccountDecoders.decodeReview(buffer);

      expect(review.workerAddress, equals(workerKey.toBase58()));
      expect(review.reviewerAddress, equals(reviewerKey.toBase58()));
      expect(review.jobId, equals(jobId));
      expect(review.rating, equals(5));
      expect(review.shortReviewerAddress, equals('FKic…dEt9'));
    });
  });

  group('ProgramInstructions', () {
    test('registerWorker builds instruction with correct accounts and discriminator', () async {
      final worker = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );

      final ix = await ProgramInstructions.registerWorker(worker: worker);

      expect(ix.programId, equals(NetworkConfig.programId));
      expect(ix.accounts.length, equals(3));
      expect(ix.accounts[0].pubKey, equals(worker));
      expect(ix.accounts[0].isSigner, isTrue);
      expect(ix.accounts[0].isWriteable, isTrue);

      expect(ix.data.toList(), equals(ProgramInstructions.registerWorkerDiscriminator));
    });

    test('submitReview validates ratings and prevents self-review', () async {
      final worker = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final reviewer = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );

      // Invalid rating 0
      expect(
        () => ProgramInstructions.submitReview(
          worker: worker,
          reviewer: reviewer,
          jobId: 'job-1',
          rating: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Invalid rating 6
      expect(
        () => ProgramInstructions.submitReview(
          worker: worker,
          reviewer: reviewer,
          jobId: 'job-1',
          rating: 6,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Self review
      expect(
        () => ProgramInstructions.submitReview(
          worker: worker,
          reviewer: worker,
          jobId: 'job-1',
          rating: 5,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Valid call
      final ix = await ProgramInstructions.submitReview(
        worker: worker,
        reviewer: reviewer,
        jobId: 'job-1',
        rating: 5,
      );

      expect(ix.accounts.length, equals(4));
      expect(ix.accounts[0].pubKey, equals(reviewer));
      expect(ix.accounts[0].isSigner, isTrue);
    });
  });
}
