import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockin/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('WorkerProfile can be inserted and queried in Drift', () async {
    await db.into(db.workerProfiles).insert(
      WorkerProfilesCompanion.insert(
        address: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
        totalJobs: 5,
        ratingSum: BigInt.from(24),
        createdAt: BigInt.from(1690000000),
      ),
    );

    final profiles = await db.select(db.workerProfiles).get();
    expect(profiles.length, 1);
    expect(profiles.first.address, '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM');
    expect(profiles.first.totalJobs, 5);
    expect(profiles.first.ratingSum, BigInt.from(24));
  });

  test('DraftReview can be saved for offline use and retrieved', () async {
    await db.into(db.draftReviews).insert(
      DraftReviewsCompanion.insert(
        workerAddress: '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM',
        jobId: 'job-plumbing-101',
        rating: 5,
        notes: const Value('Punctual and great craftmanship'),
      ),
    );

    final drafts = await db.select(db.draftReviews).get();
    expect(drafts.length, 1);
    expect(drafts.first.jobId, 'job-plumbing-101');
    expect(drafts.first.status, 'draft');
    expect(drafts.first.rating, 5);
  });
}
