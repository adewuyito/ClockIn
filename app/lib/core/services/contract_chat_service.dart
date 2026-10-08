import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart';

import '../database/deliverable_repository.dart';
import '../models/escrow_contract.dart';
import 'contract_chat_crypto.dart';
import 'firebase_sync_service.dart';

/// Why a chat can or can't be used right now.
enum ChatSetupState {
  /// Both parties have published wallet-attested keys; messages can flow.
  ready,

  /// This wallet hasn't done the one-time "Sign & publish encryption key" step.
  needsMyKey,

  /// The other party hasn't published a wallet-attested key yet.
  waitingForCounterparty,

  /// The connected wallet is neither the employer nor the worker.
  notAParty,

  /// Firebase isn't available in this build.
  unavailable,
}

/// Everything a chat screen needs to read and write one contract's thread.
class ChatSession {
  final ChatSetupState state;
  final String contractId;
  final String? me;
  final String? counterparty;

  /// True once the contract is completed or cancelled: history stays readable,
  /// new messages are refused.
  final bool readOnly;

  final crypto.SecretKey? _key;

  const ChatSession._({
    required this.state,
    required this.contractId,
    this.me,
    this.counterparty,
    this.readOnly = false,
    this._key,
  });

  bool get canRead => state == ChatSetupState.ready;
  bool get canSend => canRead && !readOnly;

  // The key is derived deterministically from these fields, so it is left out:
  // two equal sessions read and write the same thread. This lets a contract
  // refresh re-open the session without resubscribing to the message stream.
  @override
  bool operator ==(Object other) =>
      other is ChatSession &&
      other.state == state &&
      other.contractId == contractId &&
      other.me == me &&
      other.counterparty == counterparty &&
      other.readOnly == readOnly;

  @override
  int get hashCode => Object.hash(state, contractId, me, counterparty, readOnly);
}

/// One decrypted message.
class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime sentAt;

  /// Still queued on this device (offline, or not yet acknowledged).
  final bool pending;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.pending = false,
  });

  bool isFrom(String? address) => address != null && sender == address;
}

/// The encrypted chat attached to each escrow contract.
///
/// Messages live at `contracts/{contractId}/messages` as ciphertext only (see
/// [ContractChatCrypto]). Firestore's own offline cache provides offline
/// reading and queued sending, so there is no separate local table.
class ContractChatService {
  final DeliverableRepository deliverableRepository;
  final FirebaseSyncService syncService;
  final FirebaseFirestore? _firestore;

  ContractChatService({
    required this.deliverableRepository,
    required this.syncService,
    this._firestore,
  });

  /// Longest message accepted, in characters. Mirrored by the Firestore rules'
  /// ciphertext size cap.
  static const int maxMessageLength = 2000;

  /// How much history a thread loads.
  static const int historyLimit = 500;

  FirebaseFirestore? get _fs {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _messages(String contractId) =>
      _fs?.collection('contracts').doc(contractId).collection('messages');

  /// Works out whether [me] can use this contract's chat, and if so derives
  /// the shared contract key.
  Future<ChatSession> openSession(EscrowContract contract, String? me) async {
    final id = contract.contractId;
    if (me == null || !(contract.isEmployer(me) || contract.isWorker(me))) {
      return ChatSession._(state: ChatSetupState.notAParty, contractId: id, me: me);
    }
    final counterparty = contract.isEmployer(me) ? contract.worker : contract.employer;
    final readOnly = contract.status.isTerminal;
    ChatSession blocked(ChatSetupState s) => ChatSession._(
          state: s,
          contractId: id,
          me: me,
          counterparty: counterparty,
          readOnly: readOnly,
        );

    // My key only counts once my wallet has attested it — otherwise the other
    // party's app would reject it, and so would mine.
    final mySignature = await deliverableRepository.getAttestationSignature(me);
    if (mySignature == null || mySignature.isEmpty) {
      return blocked(ChatSetupState.needsMyKey);
    }

    // Verified against the counterparty's wallet signature; null if absent or forged.
    final theirPublicKey = await syncService.getUserPublicKey(counterparty);
    if (theirPublicKey == null) return blocked(ChatSetupState.waitingForCounterparty);

    if (_fs == null) return blocked(ChatSetupState.unavailable);

    final myKeyPair = await deliverableRepository.getOrCreateKeyPair(me);
    final key = await ContractChatCrypto.deriveContractKey(
      myPrivateKeyBase64: myKeyPair.privateKeyBase64,
      theirPublicKeyBase64: theirPublicKey,
      contractId: id,
    );
    return ChatSession._(
      state: ChatSetupState.ready,
      contractId: id,
      me: me,
      counterparty: counterparty,
      readOnly: readOnly,
      key: key,
    );
  }

  /// Live, decrypted messages in send order. Anything that doesn't decrypt or
  /// claims a sender outside the two parties is dropped silently.
  Stream<List<ChatMessage>> watch(ChatSession session) {
    final collection = _messages(session.contractId);
    if (!session.canRead || collection == null) return Stream.value(const []);

    return collection
        .orderBy('sentAt')
        .limitToLast(historyLimit)
        .snapshots(includeMetadataChanges: true)
        .asyncMap((snapshot) async {
      final out = <ChatMessage>[];
      for (final doc in snapshot.docs) {
        final message = await decodeMessage(
          session: session,
          id: doc.id,
          data: doc.data(),
          pending: doc.metadata.hasPendingWrites,
        );
        if (message != null) out.add(message);
      }
      return out;
    });
  }

  /// Encrypts and posts [text]. Throws [StateError] if the session can't send
  /// or the message is empty / too long.
  Future<void> send(ChatSession session, String text) async {
    final trimmed = text.trim();
    if (!session.canSend) throw StateError('This chat is read-only.');
    if (trimmed.isEmpty) throw StateError('Message is empty.');
    if (trimmed.length > maxMessageLength) {
      throw StateError('Messages are limited to $maxMessageLength characters.');
    }
    final collection = _messages(session.contractId);
    if (collection == null) throw StateError('Chat is unavailable.');

    final sentAt = DateTime.now().millisecondsSinceEpoch;
    final payload = await ContractChatCrypto.encrypt(
      key: session._key!,
      text: trimmed,
      contractId: session.contractId,
      sender: session.me!,
      sentAtMillis: sentAt,
    );
    await collection.add({
      'v': 1,
      'sender': session.me,
      'sentAt': sentAt,
      'ct': payload.ciphertext,
      'nonce': payload.nonce,
      'mac': payload.mac,
    });
  }

  /// Turns one stored document into a message, or null if it isn't a valid
  /// message from one of the two parties. Public for testing.
  @visibleForTesting
  static Future<ChatMessage?> decodeMessage({
    required ChatSession session,
    required String id,
    required Map<String, dynamic> data,
    bool pending = false,
  }) async {
    final key = session._key;
    final sender = data['sender'];
    final sentAt = data['sentAt'];
    final ct = data['ct'];
    final nonce = data['nonce'];
    final mac = data['mac'];
    if (key == null ||
        data['v'] != 1 ||
        sender is! String ||
        sentAt is! int ||
        ct is! String ||
        nonce is! String ||
        mac is! String) {
      return null;
    }
    if (sender != session.me && sender != session.counterparty) return null;

    final text = await ContractChatCrypto.decrypt(
      key: key,
      payload: EncryptedChatPayload(ciphertext: ct, nonce: nonce, mac: mac),
      contractId: session.contractId,
      sender: sender,
      sentAtMillis: sentAt,
    );
    if (text == null) return null;

    return ChatMessage(
      id: id,
      sender: sender,
      text: text,
      sentAt: DateTime.fromMillisecondsSinceEpoch(sentAt),
      pending: pending,
    );
  }

  /// Builds a session directly — for tests only. A [ChatSetupState.ready]
  /// session needs a [key].
  @visibleForTesting
  static ChatSession sessionForTest({
    required String contractId,
    required String me,
    required String counterparty,
    crypto.SecretKey? key,
    bool readOnly = false,
    ChatSetupState state = ChatSetupState.ready,
  }) =>
      ChatSession._(
        state: state,
        contractId: contractId,
        me: me,
        counterparty: counterparty,
        readOnly: readOnly,
        key: key,
      );
}
