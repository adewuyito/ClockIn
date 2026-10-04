import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockin/core/database/app_database.dart';
import 'package:clockin/core/database/deliverable_repository.dart';
import 'package:clockin/core/models/deliverable_submission.dart';
import 'package:clockin/core/services/deliverable_encryption_service.dart';
import 'package:clockin/core/services/irys_storage_service.dart';

void main() {
  late AppDatabase db;
  late DeliverableEncryptionService encryptionService;
  late IrysStorageService irysService;
  late DeliverableRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    encryptionService = DeliverableEncryptionService();
    irysService = IrysStorageService();
    repository = DeliverableRepository(
      db: db,
      encryptionService: encryptionService,
      irysService: irysService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DeliverableRepository & Drift Database Tests', () {
    test('submitDeliverable encrypts plaintext, hashes, and stores in Drift', () async {
      final key = encryptionService.generateKey();
      const contractId = 'ctr_test_deliverable_01';
      const submitter = '9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM';
      const deliverableUrl = 'https://github.com/clockin/pull/99';

      final submission = await repository.submitDeliverable(
        contractId: contractId,
        submitterAddress: submitter,
        plaintext: deliverableUrl,
        encryptionKey: key,
        completionNote: 'Initial implementation of responsive dashboard',
      );

      expect(submission.id, isNotNull);
      expect(submission.contractId, equals(contractId));
      expect(submission.submitterAddress, equals(submitter));
      expect(submission.encryptedPayload, isNotEmpty);
      expect(submission.encryptedPayload, isNot(contains(deliverableUrl)));
      expect(submission.status, equals(DeliverableStatus.submitted));
      expect(submission.completionNote, equals('Initial implementation of responsive dashboard'));
      expect(submission.plaintextHash, equals(encryptionService.computeHash(deliverableUrl)));
      expect(submission.decryptionKeyHash, equals(encryptionService.hashKey(key)));
    });

    test('decryptAndVerify successfully retrieves plaintext and verifies integrity', () async {
      final key = encryptionService.generateKey();
      const contractId = 'ctr_test_deliverable_02';
      const submitter = 'WorkerAddress123';
      const plaintext = 'URL: https://figma.com/design/abc\nNotes: All tokens validated';

      final submission = await repository.submitDeliverable(
        contractId: contractId,
        submitterAddress: submitter,
        plaintext: plaintext,
        encryptionKey: key,
      );

      final decrypted = repository.decryptAndVerify(
        submission: submission,
        decryptionKey: key,
      );

      expect(decrypted, equals(plaintext));
    });

    test('decryptAndVerify throws Exception when integrity hash fails', () async {
      final key = encryptionService.generateKey();
      const contractId = 'ctr_test_deliverable_03';
      const submitter = 'WorkerAddress123';

      final submission = await repository.submitDeliverable(
        contractId: contractId,
        submitterAddress: submitter,
        plaintext: 'Original content',
        encryptionKey: key,
      );

      // Tamper with stored plaintext hash
      final tampered = submission.copyWith(plaintextHash: '0000000000000000000000000000000000000000000000000000000000000000');

      expect(
        () => repository.decryptAndVerify(
          submission: tampered,
          decryptionKey: key,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('updateStatus updates deliverable submission to reviewed and revisionRequested', () async {
      final key = encryptionService.generateKey();
      final submission = await repository.submitDeliverable(
        contractId: 'ctr_status_test',
        submitterAddress: 'Worker1',
        plaintext: 'Deliverable v1',
        encryptionKey: key,
      );

      // Request revision
      await repository.updateStatus(submission.id!, DeliverableStatus.revisionRequested);
      var fetched = await repository.getLatestSubmission('ctr_status_test');
      expect(fetched?.status, equals(DeliverableStatus.revisionRequested));

      // Mark reviewed
      await repository.updateStatus(submission.id!, DeliverableStatus.reviewed);
      fetched = await repository.getLatestSubmission('ctr_status_test');
      expect(fetched?.status, equals(DeliverableStatus.reviewed));
    });

    test('watchLatestSubmission emits updates when new deliverable is submitted', () async {
      const contractId = 'ctr_stream_test';
      final stream = repository.watchLatestSubmission(contractId);

      expect(
        stream,
        emitsInOrder([
          isNull, // Initially no submissions
          predicate<DeliverableSubmission?>((sub) =>
              sub != null && sub.contractId == contractId && sub.completionNote == 'Note 1'),
          predicate<DeliverableSubmission?>((sub) =>
              sub != null && sub.contractId == contractId && sub.completionNote == 'Revision 2'),
        ]),
      );

      // First submission
      final key1 = encryptionService.generateKey();
      await repository.submitDeliverable(
        contractId: contractId,
        submitterAddress: 'Worker1',
        plaintext: 'V1 Work',
        encryptionKey: key1,
        completionNote: 'Note 1',
      );

      // Second submission (revision)
      final key2 = encryptionService.generateKey();
      await repository.submitDeliverable(
        contractId: contractId,
        submitterAddress: 'Worker1',
        plaintext: 'V2 Work with fixes',
        encryptionKey: key2,
        completionNote: 'Revision 2',
      );
    });
  });
}
