import 'package:clockin/core/database/app_database.dart' hide EscrowContract;
import 'package:clockin/core/database/deliverable_repository.dart';
import 'package:clockin/core/models/escrow_contract.dart';
import 'package:clockin/core/services/contract_chat_crypto.dart';
import 'package:clockin/core/services/contract_chat_service.dart';
import 'package:clockin/core/services/deliverable_encryption_service.dart';
import 'package:clockin/core/services/firebase_sync_service.dart';
import 'package:clockin/core/services/irys_storage_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Stands in for the Firestore key directory: returns a counterparty's
/// wallet-verified X25519 key, or null if they haven't published one.
class _FakeDirectory extends FirebaseSyncService {
  final Map<String, String> keys;
  _FakeDirectory(this.keys);
  @override
  Future<String?> getUserPublicKey(String walletAddress) async => keys[walletAddress];
}

void main() {
  const employer = 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ';
  const worker = 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk';
  const stranger = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
  const contractId = 'ctr-chat-1';

  EscrowContract contractWith(ContractStatus status) => EscrowContract(
        contractId: contractId,
        employer: employer,
        worker: worker,
        amount: BigInt.from(500000000),
        termsHash: '00',
        status: status,
        createdAt: DateTime.utc(2026, 10, 8),
      );

  late AppDatabase db;
  late DeliverableRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DeliverableRepository(
      db: db,
      encryptionService: DeliverableEncryptionService(),
      irysService: IrysStorageService(client: MockClient((_) async => http.Response('{}', 500))),
    );
  });
  tearDown(() async => db.close());

  group('openSession explains why a chat is unavailable', () {
    test('a wallet that is not a party cannot open the chat', () async {
      final s = await ContractChatService(deliverableRepository: repo, syncService: _FakeDirectory({}))
          .openSession(contractWith(ContractStatus.inProgress), stranger);
      expect(s.state, ChatSetupState.notAParty);
      expect(s.canSend, isFalse);
    });

    test('a party who has not attested their key is asked to set it up', () async {
      final s = await ContractChatService(deliverableRepository: repo, syncService: _FakeDirectory({}))
          .openSession(contractWith(ContractStatus.inProgress), worker);
      expect(s.state, ChatSetupState.needsMyKey);
      expect(s.counterparty, employer);
    });

    test('waits for the counterparty when they have no verified key', () async {
      await repo.getOrCreateKeyPair(worker);
      await repo.saveAttestationSignature(worker, 'sig');
      final s = await ContractChatService(deliverableRepository: repo, syncService: _FakeDirectory({}))
          .openSession(contractWith(ContractStatus.inProgress), worker);
      expect(s.state, ChatSetupState.waitingForCounterparty);
    });

    test('with both keys but no Firebase, reports unavailable rather than failing', () async {
      final employerKeys = await DeliverableEncryptionService().generateX25519KeyPair();
      await repo.getOrCreateKeyPair(worker);
      await repo.saveAttestationSignature(worker, 'sig');
      final s = await ContractChatService(
        deliverableRepository: repo,
        syncService: _FakeDirectory({employer: employerKeys.publicKeyBase64}),
      ).openSession(contractWith(ContractStatus.inProgress), worker);
      // No Firebase app is initialised in unit tests.
      expect(s.state, ChatSetupState.unavailable);
    });

    test('a settled contract opens read-only', () async {
      final s = await ContractChatService(deliverableRepository: repo, syncService: _FakeDirectory({}))
          .openSession(contractWith(ContractStatus.completed), worker);
      expect(s.readOnly, isTrue);
    });
  });

  group('decodeMessage keeps only genuine messages from the two parties', () {
    late ChatSession workerSide;
    late dynamic sharedKey;

    setUp(() async {
      final k = DeliverableEncryptionService();
      final e = await k.generateX25519KeyPair();
      final w = await k.generateX25519KeyPair();
      sharedKey = await ContractChatCrypto.deriveContractKey(
        myPrivateKeyBase64: w.privateKeyBase64,
        theirPublicKeyBase64: e.publicKeyBase64,
        contractId: contractId,
      );
      workerSide = ContractChatService.sessionForTest(
        contractId: contractId,
        me: worker,
        counterparty: employer,
        key: sharedKey,
      );
    });

    Future<Map<String, dynamic>> stored(String sender, String text, {int at = 1791400000000}) async {
      final p = await ContractChatCrypto.encrypt(
        key: sharedKey,
        text: text,
        contractId: contractId,
        sender: sender,
        sentAtMillis: at,
      );
      return {'v': 1, 'sender': sender, 'sentAt': at, 'ct': p.ciphertext, 'nonce': p.nonce, 'mac': p.mac};
    }

    test('decodes a message from the counterparty', () async {
      final m = await ContractChatService.decodeMessage(
        session: workerSide,
        id: 'm1',
        data: await stored(employer, 'Can you send the Figma file?'),
      );
      expect(m!.text, 'Can you send the Figma file?');
      expect(m.isFrom(employer), isTrue);
      expect(m.sentAt, DateTime.fromMillisecondsSinceEpoch(1791400000000));
    });

    test('drops a validly-encrypted message claiming a third sender', () async {
      final m = await ContractChatService.decodeMessage(
        session: workerSide,
        id: 'm2',
        data: await stored(stranger, 'hi'),
      );
      expect(m, isNull);
    });

    test('drops a message whose sender label was swapped after encryption', () async {
      final data = await stored(employer, 'release funds')..['sender'] = worker;
      expect(await ContractChatService.decodeMessage(session: workerSide, id: 'm3', data: data), isNull);
    });

    test('drops malformed or unknown-version documents', () async {
      final good = await stored(employer, 'x');
      expect(await ContractChatService.decodeMessage(session: workerSide, id: 'a', data: {...good, 'v': 2}), isNull);
      expect(await ContractChatService.decodeMessage(session: workerSide, id: 'b', data: {...good, 'sentAt': '1'}), isNull);
      expect(await ContractChatService.decodeMessage(session: workerSide, id: 'c', data: {'v': 1}), isNull);
    });

    test('carries the pending flag for queued sends', () async {
      final m = await ContractChatService.decodeMessage(
        session: workerSide,
        id: 'm4',
        data: await stored(worker, 'on my way'),
        pending: true,
      );
      expect(m!.pending, isTrue);
    });
  });

  group('send refuses what it must', () {
    late ContractChatService service;
    late dynamic key;

    setUp(() async {
      service = ContractChatService(deliverableRepository: repo, syncService: _FakeDirectory({}));
      final k = DeliverableEncryptionService();
      key = await ContractChatCrypto.deriveContractKey(
        myPrivateKeyBase64: (await k.generateX25519KeyPair()).privateKeyBase64,
        theirPublicKeyBase64: (await k.generateX25519KeyPair()).publicKeyBase64,
        contractId: contractId,
      );
    });

    ChatSession session({bool readOnly = false}) => ContractChatService.sessionForTest(
          contractId: contractId,
          me: worker,
          counterparty: employer,
          key: key,
          readOnly: readOnly,
        );

    test('read-only threads', () => expect(() => service.send(session(readOnly: true), 'hi'), throwsStateError));
    test('empty messages', () => expect(() => service.send(session(), '   '), throwsStateError));
    test('over-long messages', () => expect(
          () => service.send(session(), 'x' * (ContractChatService.maxMessageLength + 1)),
          throwsStateError,
        ));
  });
}
