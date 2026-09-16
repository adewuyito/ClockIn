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

/// A worker address the user has successfully looked up before, for the
/// Look Up screen's "Recent lookups" list. Deliberately a separate table
/// from [WorkerProfiles] rather than reusing its `syncedAt` ordering: that
/// table is the offline-first *data* cache (see ARCHITECTURE.md's trust
/// model), and "Clear" on this list must never delete cached on-chain data,
/// only the recency pointer.
class RecentLookups extends Table {
  TextColumn get address => text()();
  DateTimeColumn get lastViewedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {address};
}

/// Local cache for on-chain escrow contracts.
class EscrowContracts extends Table {
  TextColumn get contractId => text()();
  TextColumn get employer => text()();
  TextColumn get worker => text()();
  Int64Column get amount => int64()();
  TextColumn get termsHash => text()();
  TextColumn get termsText => text().nullable()();
  TextColumn get status => text()(); // 'created', 'funded', 'in_progress', 'completed', 'disputed', 'cancelled'
  Int64Column get deadline => int64()();
  Int64Column get createdAt => int64()();
  Int64Column get fundedAt => int64()();
  Int64Column get completedAt => int64()();
  IntColumn get rating => integer()();
  TextColumn get lastTxSignature => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {contractId};
}

@DriftDatabase(tables: [WorkerProfiles, Reviews, DraftReviews, RecentLookups, EscrowContracts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'clockin_db'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(recentLookups);
          }
          if (from < 3) {
            await m.createTable(escrowContracts);
          }
        },
      );
}

