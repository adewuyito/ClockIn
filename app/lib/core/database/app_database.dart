import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Local cache for on-chain worker profiles.
class WorkerProfiles extends Table {
  TextColumn get address => text()();
  IntColumn get totalJobs => integer()();
  Int64Column get ratingSum => int64()();
  Int64Column get createdAt => int64()();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {address};
}

/// Local cache for confirmed on-chain reviews.
class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workerAddress => text()();
  TextColumn get reviewerAddress => text()();
  TextColumn get jobId => text()();
  IntColumn get rating => integer()();
  Int64Column get timestamp => int64()();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Offline-first drafts and pending review submissions.
class DraftReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workerAddress => text()();
  TextColumn get jobId => text()();
  IntColumn get rating => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('draft'))();
}

@DriftDatabase(tables: [WorkerProfiles, Reviews, DraftReviews])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'clockin_db'));

  @override
  int get schemaVersion => 1;
}
