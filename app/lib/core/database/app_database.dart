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
  TextColumn get reviewNote => text().nullable()();
  TextColumn get arweaveTxId => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Offline-first drafts and pending review submissions.
class DraftReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workerAddress => text()();
  TextColumn get jobId => text()();
  IntColumn get rating => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get arweaveTxId => text().nullable()();
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
  BoolColumn get isToken => boolean().withDefault(const Constant(false))();
  TextColumn get tokenMint => text().nullable()();
  TextColumn get disputeReason => text().nullable()();
  TextColumn get disputeDetails => text().nullable()();
  TextColumn get disputeEvidenceUri => text().nullable()();
  TextColumn get disputeRaisedBy => text().nullable()();
  DateTimeColumn get disputeRaisedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {contractId};
}

/// Offline-first drafts for contracts created while disconnected.
class DraftContracts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contractId => text()();
  TextColumn get workerAddress => text()();
  RealColumn get amountSol => real()();
  TextColumn get termsText => text().nullable()();
  Int64Column get deadline => int64()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isToken => boolean().withDefault(const Constant(false))();
  TextColumn get tokenMint => text().nullable()();
}

/// Local cache for Seeker Attestation and Guardian staking status.
class SeekerAttestations extends Table {
  TextColumn get address => text()();
  BoolColumn get isAttested => boolean()();
  RealColumn get stakedAmount => real().withDefault(const Constant(0.0))();
  TextColumn get guardianName => text().withDefault(const Constant('Helius'))();
  BoolColumn get cooldownActive => boolean().withDefault(const Constant(false))();
  TextColumn get txSignature => text().nullable()();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {address};
}

/// Local cache for Seeker Guardian juror panel and dispute cases.
@DataClassName('DisputeCaseData')
class DisputeCases extends Table {
  TextColumn get contractId => text().withLength(min: 1, max: 32)();
  TextColumn get juror1 => text()();
  TextColumn get juror2 => text()();
  TextColumn get juror3 => text()();
  IntColumn get vote1 => integer().withDefault(const Constant(0))();
  IntColumn get vote2 => integer().withDefault(const Constant(0))();
  IntColumn get vote3 => integer().withDefault(const Constant(0))();
  IntColumn get quorumOutcome => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('voting'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {contractId};
}

/// E2EE deliverable submissions from workers to employers.
/// Encrypted payload is AES-256-GCM ciphertext; the key is never stored here.
@DataClassName('DeliverableSubmissionData')
class DeliverableSubmissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contractId => text()();
  TextColumn get submitterAddress => text()();
  TextColumn get encryptedPayload => text()(); // base64 AES-256-GCM ciphertext
  TextColumn get iv => text()(); // base64 12-byte initialization vector
  TextColumn get authTag => text().withDefault(const Constant(''))(); // base64 GCM auth tag
  TextColumn get plaintextHash => text()(); // SHA-256 hex digest of original plaintext
  TextColumn get arweaveTxId => text().nullable()();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('submitted'))(); // 'submitted', 'reviewed', 'revision_requested'
  TextColumn get decryptionKeyHash => text().nullable()(); // SHA-256 of AES key (never the key itself)
  TextColumn get completionNote => text().nullable()(); // optional unencrypted worker summary
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  WorkerProfiles,
  Reviews,
  DraftReviews,
  RecentLookups,
  EscrowContracts,
  DraftContracts,
  SeekerAttestations,
  DisputeCases,
  DeliverableSubmissions,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'clockin_db'));

  @override
  int get schemaVersion => 11;

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
          if (from < 4) {
            await m.createTable(draftContracts);
          }
          if (from < 5) {
            await m.addColumn(escrowContracts, escrowContracts.isToken);
            await m.addColumn(escrowContracts, escrowContracts.tokenMint);
            await m.addColumn(draftContracts, draftContracts.isToken);
            await m.addColumn(draftContracts, draftContracts.tokenMint);
          }
          if (from < 6) {
            await m.createTable(seekerAttestations);
          }
          if (from < 7) {
            await m.deleteTable('seeker_attestations');
            await m.createTable(seekerAttestations);
          }
          if (from < 8) {
            await m.addColumn(escrowContracts, escrowContracts.disputeReason);
            await m.addColumn(escrowContracts, escrowContracts.disputeDetails);
            await m.addColumn(escrowContracts, escrowContracts.disputeEvidenceUri);
            await m.addColumn(escrowContracts, escrowContracts.disputeRaisedBy);
            await m.addColumn(escrowContracts, escrowContracts.disputeRaisedAt);
          }
          if (from < 9) {
            await m.createTable(disputeCases);
          }
          if (from < 10) {
            await m.addColumn(reviews, reviews.reviewNote);
            await m.addColumn(reviews, reviews.arweaveTxId);
            await m.addColumn(draftReviews, draftReviews.arweaveTxId);
          }
          if (from < 11) {
            await m.createTable(deliverableSubmissions);
          }
        },
      );
}


