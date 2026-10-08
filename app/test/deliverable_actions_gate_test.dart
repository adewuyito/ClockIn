import 'package:clockin/core/database/app_database.dart' hide EscrowContract;
import 'package:clockin/core/database/deliverable_repository.dart';
import 'package:clockin/core/models/deliverable_submission.dart';
import 'package:clockin/core/models/escrow_contract.dart';
import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/core/services/deliverable_encryption_service.dart';
import 'package:clockin/core/services/irys_storage_service.dart';
import 'package:clockin/features/contracts/review_deliverable_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Once a contract is settled its deliverables are final: the employer can no
/// longer accept or send work back, and the worker can no longer submit a
/// revision. These actions exist only while the contract is In Progress.
void main() {
  const employer = 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ';
  const worker = 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk';
  const plaintext = 'URL: https://github.com/clockin/pull/42';

  final encryption = DeliverableEncryptionService();
  final key = encryption.generateKey();
  final payload = encryption.encrypt(plaintext, key);

  final submission = DeliverableSubmission(
    id: 1,
    contractId: 'ctr-gate',
    submitterAddress: worker,
    encryptedPayload: payload.ciphertext,
    iv: payload.iv,
    authTag: payload.authTag,
    plaintextHash: encryption.computeHash(plaintext),
    submittedAt: DateTime.utc(2026, 10, 6),
  );

  EscrowContract contractWith(ContractStatus status) => EscrowContract(
        contractId: 'ctr-gate',
        employer: employer,
        worker: worker,
        amount: BigInt.from(500000000),
        termsHash: '00',
        status: status,
        createdAt: DateTime.utc(2026, 10, 6),
      );

  Future<void> pumpCard(
    WidgetTester tester, {
    required ContractStatus status,
    required bool asEmployer,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DeliverableRepository(
      db: db,
      encryptionService: encryption,
      irysService: IrysStorageService(
        client: MockClient((_) async => http.Response('{}', 500)),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [deliverableRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReviewDeliverableCard(
                contract: contractWith(status),
                submission: submission,
                isEmployer: asEmployer,
                isWorker: !asEmployer,
                // Employer gets the real key so the card decrypts on its own,
                // which is what reveals Accept / Request Changes. The worker
                // view shows its actions only before decryption, as it does
                // on the worker's own device.
                initialKey: asEmployer ? key : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final accept = find.text('Accept Deliverables & Rate Worker');
  final requestChanges = find.text('Request Changes / Revisions');
  final submitRevision = find.text('Submit Revision');
  final shareKey = find.text('Share Key QR');

  group('model rule', () {
    test('deliverable actions are open only while In Progress', () {
      for (final s in ContractStatus.values) {
        expect(contractWith(s).acceptsDeliverableActions, s == ContractStatus.inProgress,
            reason: s.name);
        expect(contractWith(s).deliverableActionsClosedReason == null,
            s == ContractStatus.inProgress,
            reason: s.name);
      }
    });
  });

  group('employer view', () {
    testWidgets('In Progress: can accept or request changes', (tester) async {
      await pumpCard(tester, status: ContractStatus.inProgress, asEmployer: true);
      expect(find.textContaining(plaintext), findsOneWidget); // decrypted
      expect(accept, findsOneWidget);
      expect(requestChanges, findsOneWidget);
    });

    for (final status in [
      ContractStatus.completed,
      ContractStatus.cancelled,
      ContractStatus.disputed,
    ]) {
      testWidgets('${status.name}: no accept / request changes, reason shown', (tester) async {
        await pumpCard(tester, status: status, asEmployer: true);
        expect(find.textContaining(plaintext), findsOneWidget); // still readable
        expect(accept, findsNothing);
        expect(requestChanges, findsNothing);
        expect(find.text(contractWith(status).deliverableActionsClosedReason!), findsOneWidget);
      });
    }
  });

  group('worker view', () {
    testWidgets('In Progress: can submit a revision and share the key', (tester) async {
      await pumpCard(tester, status: ContractStatus.inProgress, asEmployer: false);
      expect(submitRevision, findsOneWidget);
      expect(shareKey, findsOneWidget);
    });

    testWidgets('completed: no revision, key sharing still available', (tester) async {
      await pumpCard(tester, status: ContractStatus.completed, asEmployer: false);
      expect(submitRevision, findsNothing);
      expect(shareKey, findsOneWidget);
      expect(find.text('Contract completed — deliverables are final.'), findsOneWidget);
    });
  });
}
