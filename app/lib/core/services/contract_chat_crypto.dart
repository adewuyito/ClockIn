import 'dart:convert';

import 'package:cryptography/cryptography.dart' as crypto;

/// End-to-end encryption for the chat on a single escrow contract.
///
/// Both parties derive the **same** symmetric key on their own devices from
/// their own X25519 private key and the other party's wallet-attested X25519
/// public key (Diffie–Hellman is symmetric). Nothing secret is exchanged or
/// stored server-side, so Firestore only ever holds ciphertext.
///
/// The key is bound to one contract by HKDF (salt = contract id, info = a
/// versioned domain string), so the same two wallets get a different key on
/// every contract and a message can't be replayed into another thread.
///
/// Each message's metadata — contract, sender, timestamp — is authenticated as
/// AES-GCM associated data. A message from anyone who doesn't hold one of the
/// two private keys fails to decrypt and is dropped.
///
/// Known limit: the key is shared by both parties, so cryptographically either
/// one could produce a message labelled as from the other. That is fine for
/// conversation but means chat is not yet evidence-grade for disputes; per
/// message signatures are the planned fix (see docs/ARCHITECTURE.md).
class ContractChatCrypto {
  ContractChatCrypto._();

  /// Domain separator. Bump the version if the derivation or AAD layout
  /// changes, so old and new ciphertext can never be confused.
  static const String domain = 'ClockIn contract chat v1';

  static final _aes = crypto.AesGcm.with256bits();

  /// Derives the per-contract chat key from my X25519 private key seed and the
  /// counterparty's X25519 public key (both base64).
  static Future<crypto.SecretKey> deriveContractKey({
    required String myPrivateKeyBase64,
    required String theirPublicKeyBase64,
    required String contractId,
  }) async {
    final x25519 = crypto.X25519();
    final myKeyPair = await x25519.newKeyPairFromSeed(base64.decode(myPrivateKeyBase64));
    final shared = await x25519.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: crypto.SimplePublicKey(
        base64.decode(theirPublicKeyBase64),
        type: crypto.KeyPairType.x25519,
      ),
    );
    return crypto.Hkdf(hmac: crypto.Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      nonce: utf8.encode(contractId),
      info: utf8.encode(domain),
    );
  }

  /// Associated data authenticated (not encrypted) with every message.
  static List<int> associatedData({
    required String contractId,
    required String sender,
    required int sentAtMillis,
  }) =>
      utf8.encode('$domain|$contractId|$sender|$sentAtMillis');

  /// Encrypts [text] for this contract's thread.
  static Future<EncryptedChatPayload> encrypt({
    required crypto.SecretKey key,
    required String text,
    required String contractId,
    required String sender,
    required int sentAtMillis,
  }) async {
    final box = await _aes.encrypt(
      utf8.encode(text),
      secretKey: key,
      aad: associatedData(contractId: contractId, sender: sender, sentAtMillis: sentAtMillis),
    );
    return EncryptedChatPayload(
      ciphertext: base64.encode(box.cipherText),
      nonce: base64.encode(box.nonce),
      mac: base64.encode(box.mac.bytes),
    );
  }

  /// Decrypts a message, or returns null if it was not produced by a holder of
  /// this contract's key, or its contract / sender / time were altered.
  static Future<String?> decrypt({
    required crypto.SecretKey key,
    required EncryptedChatPayload payload,
    required String contractId,
    required String sender,
    required int sentAtMillis,
  }) async {
    try {
      final clear = await _aes.decrypt(
        crypto.SecretBox(
          base64.decode(payload.ciphertext),
          nonce: base64.decode(payload.nonce),
          mac: crypto.Mac(base64.decode(payload.mac)),
        ),
        secretKey: key,
        aad: associatedData(contractId: contractId, sender: sender, sentAtMillis: sentAtMillis),
      );
      return utf8.decode(clear);
    } catch (_) {
      return null;
    }
  }
}

/// The encrypted parts of one chat message, as stored in Firestore.
class EncryptedChatPayload {
  final String ciphertext;
  final String nonce;
  final String mac;

  const EncryptedChatPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });
}
