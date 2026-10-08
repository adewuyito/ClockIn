import 'package:clockin/core/services/contract_chat_crypto.dart';
import 'package:clockin/core/services/deliverable_encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The chat is only private if these hold: both parties derive one key on
/// their own devices, that key is unique per contract, and anything a third
/// party produces — or anything altered in transit — fails to decrypt.
void main() {
  final keys = DeliverableEncryptionService();
  late X25519KeyPairData employer;
  late X25519KeyPairData worker;
  late X25519KeyPairData stranger;

  const contractId = 'ctr-321723';
  const employerAddr = '4ojAkcXs48y2M8xLXYNkG5ULw4rabNT87BeNTcGYVAqq';
  const workerAddr = 'DE34zEfbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const sentAt = 1791400000000;

  Future<dynamic> keyFor(X25519KeyPairData me, X25519KeyPairData them, [String id = contractId]) =>
      ContractChatCrypto.deriveContractKey(
        myPrivateKeyBase64: me.privateKeyBase64,
        theirPublicKeyBase64: them.publicKeyBase64,
        contractId: id,
      );

  setUp(() async {
    employer = await keys.generateX25519KeyPair();
    worker = await keys.generateX25519KeyPair();
    stranger = await keys.generateX25519KeyPair();
  });

  test('employer and worker derive the same key independently', () async {
    final a = await (await keyFor(employer, worker)).extractBytes();
    final b = await (await keyFor(worker, employer)).extractBytes();
    expect(a, equals(b));
    expect(a.length, 32);
  });

  test('the key is different on every contract for the same two wallets', () async {
    final a = await (await keyFor(employer, worker, 'ctr-a')).extractBytes();
    final b = await (await keyFor(employer, worker, 'ctr-b')).extractBytes();
    expect(a, isNot(equals(b)));
  });

  test('a message round-trips between the two parties', () async {
    final payload = await ContractChatCrypto.encrypt(
      key: await keyFor(worker, employer),
      text: 'Deliverables are submitted — check the encrypted card.',
      contractId: contractId,
      sender: workerAddr,
      sentAtMillis: sentAt,
    );
    expect(payload.ciphertext, isNot(contains('Deliverables')));

    final text = await ContractChatCrypto.decrypt(
      key: await keyFor(employer, worker),
      payload: payload,
      contractId: contractId,
      sender: workerAddr,
      sentAtMillis: sentAt,
    );
    expect(text, 'Deliverables are submitted — check the encrypted card.');
  });

  test('a stranger cannot read the thread', () async {
    final payload = await ContractChatCrypto.encrypt(
      key: await keyFor(worker, employer),
      text: 'private',
      contractId: contractId,
      sender: workerAddr,
      sentAtMillis: sentAt,
    );
    // The stranger only knows public keys; their best guess at the key fails.
    final guess = await ContractChatCrypto.decrypt(
      key: await keyFor(stranger, employer),
      payload: payload,
      contractId: contractId,
      sender: workerAddr,
      sentAtMillis: sentAt,
    );
    expect(guess, isNull);
  });

  test('a stranger cannot inject a message the parties would accept', () async {
    final forged = await ContractChatCrypto.encrypt(
      key: await keyFor(stranger, worker),
      text: 'Send the funds to me instead',
      contractId: contractId,
      sender: employerAddr,
      sentAtMillis: sentAt,
    );
    final seenByWorker = await ContractChatCrypto.decrypt(
      key: await keyFor(worker, employer),
      payload: forged,
      contractId: contractId,
      sender: employerAddr,
      sentAtMillis: sentAt,
    );
    expect(seenByWorker, isNull);
  });

  group('metadata is authenticated', () {
    late EncryptedChatPayload payload;
    setUp(() async {
      payload = await ContractChatCrypto.encrypt(
        key: await keyFor(worker, employer),
        text: 'hello',
        contractId: contractId,
        sender: workerAddr,
        sentAtMillis: sentAt,
      );
    });

    Future<String?> readAs({String id = contractId, String sender = workerAddr, int at = sentAt}) async =>
        ContractChatCrypto.decrypt(
          key: await keyFor(employer, worker),
          payload: payload,
          contractId: id,
          sender: sender,
          sentAtMillis: at,
        );

    test('relabelled sender is rejected', () async => expect(await readAs(sender: employerAddr), isNull));
    test('moved to another contract is rejected', () async => expect(await readAs(id: 'ctr-other'), isNull));
    test('altered timestamp is rejected', () async => expect(await readAs(at: sentAt + 1), isNull));
    test('unaltered metadata decrypts', () async => expect(await readAs(), 'hello'));
  });

  test('malformed payloads are dropped, not thrown', () async {
    final text = await ContractChatCrypto.decrypt(
      key: await keyFor(employer, worker),
      payload: const EncryptedChatPayload(ciphertext: '!!', nonce: 'AA==', mac: 'AA=='),
      contractId: contractId,
      sender: workerAddr,
      sentAtMillis: sentAt,
    );
    expect(text, isNull);
  });
}
