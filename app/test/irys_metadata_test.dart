import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:clockin/core/database/app_database.dart' hide Review;
import 'package:clockin/core/models/review_metadata.dart';
import 'package:clockin/core/models/review.dart' as domain;
import 'package:clockin/core/services/irys_storage_service.dart';

void main() {
  group('ClockInReviewMetadata', () {
    test('serializes to JSON and deserializes correctly', () {
      final metadata = ClockInReviewMetadata(
        jobId: 'contract-flutter-ui-123',
        worker: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
        reviewer: 'DYw8jCTfwHNRJhhmFcbXvVDTqWMEVFBX6ZKUmG5CNSKK',
        rating: 5,
        reviewNote: 'Outstanding flutter architecture and clean UI delivery.',
        deliverables: [
          const ReviewDeliverable(
            title: 'GitHub PR',
            uri: 'https://github.com/clockin/app/pull/42',
            hash: 'sha256-abc123',
          ),
        ],
        timestamp: 1727884800000,
      );

      final json = metadata.toJson();
      expect(json['protocol'], 'ClockIn');
      expect(json['version'], '1.0.0');
      expect(json['jobId'], 'contract-flutter-ui-123');
      expect(json['worker'], '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM');
      expect(json['rating'], 5);
      expect(json['reviewNote'], 'Outstanding flutter architecture and clean UI delivery.');
      expect((json['deliverables'] as List).length, 1);

      final parsed = ClockInReviewMetadata.fromJson(json);
      expect(parsed.jobId, metadata.jobId);
      expect(parsed.worker, metadata.worker);
      expect(parsed.reviewer, metadata.reviewer);
      expect(parsed.rating, metadata.rating);
      expect(parsed.reviewNote, metadata.reviewNote);
      expect(parsed.deliverables.first.title, 'GitHub PR');
      expect(parsed.deliverables.first.uri, 'https://github.com/clockin/app/pull/42');
      expect(parsed.deliverables.first.hash, 'sha256-abc123');
      expect(parsed.timestamp, metadata.timestamp);
    });

    test('toCanonicalJson produces deterministic, repeatable output', () {
      const meta1 = ClockInReviewMetadata(
        jobId: 'job-1',
        worker: 'worker-1',
        reviewer: 'reviewer-1',
        rating: 4,
        reviewNote: 'Good job',
        timestamp: 1700000000,
      );

      const meta2 = ClockInReviewMetadata(
        jobId: 'job-1',
        worker: 'worker-1',
        reviewer: 'reviewer-1',
        rating: 4,
        reviewNote: 'Good job',
        timestamp: 1700000000,
      );

      expect(meta1.toCanonicalJson(), meta2.toCanonicalJson());
    });
  });

  group('IrysStorageService', () {
    late IrysStorageService irysService;

    setUp(() {
      irysService = IrysStorageService();
    });

    test('gateway and explorer URLs format correctly', () {
      const txId = '4k7yR8f4z2A_arweave_tx_hash_123';
      expect(irysService.gatewayUrl, 'https://gateway.irys.xyz');
      expect(
        irysService.getExplorerUrl(txId),
        'https://gateway.irys.xyz/4k7yR8f4z2A_arweave_tx_hash_123',
      );
    });

    test('uploads with devnet fallback when offline/devnet node fails', () async {
      final metadata = ClockInReviewMetadata(
        jobId: 'offline-test-job',
        worker: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
        reviewer: 'DYw8jCTfwHNRJhhmFcbXvVDTqWMEVFBX6ZKUmG5CNSKK',
        rating: 5,
        reviewNote: 'Offline resilient review note',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final txId = await irysService.uploadReviewMetadata(metadata);
      expect(txId.isNotEmpty, isTrue);
      // Either a 43-character base64 Arweave ID or devnet fallback ID
      expect(
        txId.startsWith('irys_') || txId.length >= 32,
        isTrue,
      );
    });
  });

  group('Drift Schema v10 Review Persistence', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Reviews table persists and retrieves reviewNote and arweaveTxId', () async {
      final now = DateTime.now().toUtc();
      const testArweaveTx = 'tx_irys_arweave_inscription_test_42';
      const testNote = 'Completed contract ahead of schedule with top tier code.';

      await db.into(db.reviews).insert(
            ReviewsCompanion.insert(
              workerAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
              reviewerAddress: 'DYw8jCTfwHNRJhhmFcbXvVDTqWMEVFBX6ZKUmG5CNSKK',
              jobId: 'contract-sol-999',
              rating: 5,
              timestamp: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
              reviewNote: const Value(testNote),
              arweaveTxId: const Value(testArweaveTx),
              syncedAt: Value(now),
            ),
          );

      final saved = await db.select(db.reviews).get();
      expect(saved.length, 1);
      final r = saved.first;
      expect(r.jobId, 'contract-sol-999');
      expect(r.reviewNote, testNote);
      expect(r.arweaveTxId, testArweaveTx);

      // Verify domain Review mapping
      final domainReview = domain.Review(
        workerAddress: r.workerAddress,
        reviewerAddress: r.reviewerAddress,
        jobId: r.jobId,
        rating: r.rating,
        timestamp: DateTime.fromMillisecondsSinceEpoch(r.timestamp.toInt() * 1000),
        reviewNote: r.reviewNote,
        arweaveTxId: r.arweaveTxId,
      );
      expect(domainReview.hasArweaveProvenance, isTrue);
      expect(domainReview.reviewNote, testNote);
    });

    test('DraftReviews table stores arweaveTxId for offline sync resume', () async {
      await db.into(db.draftReviews).insert(
            DraftReviewsCompanion.insert(
              workerAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
              jobId: 'draft-job-irys-1',
              rating: 5,
              notes: const Value('Drafted note before signing'),
              arweaveTxId: const Value('tx_presaved_arweave_id_888'),
            ),
          );

      final drafts = await db.select(db.draftReviews).get();
      expect(drafts.length, 1);
      expect(drafts.first.arweaveTxId, 'tx_presaved_arweave_id_888');
      expect(drafts.first.notes, 'Drafted note before signing');
    });
  });
}
