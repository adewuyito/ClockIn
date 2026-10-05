import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:encrypt/encrypt.dart';

/// Service providing AES-256-GCM encryption/decryption and X25519 asymmetric
/// envelope key wrapping for E2EE deliverable submissions.
///
/// Symmetric payload encryption protects the deliverable itself.
/// Asymmetric X25519 key wrapping allows the worker to encrypt the symmetric key
/// directly for the employer's public key so it can be relayed via Firestore
/// with zero plaintext exposure to servers or intermediaries.
class DeliverableEncryptionService {
  /// Generates a cryptographically random 256-bit AES key.
  ///
  /// Returns the key as a base64url-encoded string (44 characters, URL-safe).
  String generateKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(32); // 256 bits
    for (int i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    return base64Url.encode(keyBytes);
  }

  /// Encrypts [plaintext] using AES-256-GCM with the given [base64Key].
  ///
  /// Returns an [EncryptedPayload] containing the ciphertext, IV, and
  /// authentication tag — all base64-encoded for safe storage/transport.
  EncryptedPayload encrypt(String plaintext, String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    final key = Key(Uint8List.fromList(keyBytes));

    // Generate a cryptographically random 96-bit (12-byte) IV per encryption.
    final ivBytes = Uint8List(12);
    final random = Random.secure();
    for (int i = 0; i < ivBytes.length; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    final iv = IV(ivBytes);

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return EncryptedPayload(
      ciphertext: encrypted.base64,
      iv: base64.encode(ivBytes),
      authTag: '', // GCM auth tag is embedded in ciphertext by the encrypt package
    );
  }

  /// Decrypts an [EncryptedPayload] back to plaintext using the shared [base64Key].
  ///
  /// Throws [ArgumentError] if the key is invalid or ciphertext is tampered.
  String decrypt(EncryptedPayload payload, String base64Key) {
    final keyBytes = base64Url.decode(base64Key);
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV(base64.decode(payload.iv));

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = Encrypted.fromBase64(payload.ciphertext);

    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Computes the SHA-256 hex digest of [plaintext].
  ///
  /// Used as a tamper-proof integrity proof: the hash of the original
  /// plaintext is stored alongside the encrypted payload. After decryption,
  /// the employer recomputes the hash to verify nothing was altered.
  String computeHash(String plaintext) {
    final bytes = utf8.encode(plaintext);
    final digest = hash.sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies that [plaintext] matches the expected [expectedHash].
  bool verifyHash(String plaintext, String expectedHash) {
    return computeHash(plaintext) == expectedHash;
  }

  /// Computes the SHA-256 hash of a key (for safe storage / verification
  /// without exposing the key itself).
  String hashKey(String base64Key) {
    final bytes = utf8.encode(base64Key);
    final digest = hash.sha256.convert(bytes);
    return digest.toString();
  }

  // ==================== X25519 ENVELOPE KEY WRAPPING ====================

  /// Generates a new X25519 key pair for asymmetric envelope key wrapping.
  ///
  /// The public key can be published to Firestore (`/users/{walletAddress}`)
  /// while the private key remains strictly on-device in Drift storage.
  Future<X25519KeyPairData> generateX25519KeyPair() async {
    final x25519 = crypto.X25519();
    final keyPair = await x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    return X25519KeyPairData(
      publicKeyBase64: base64.encode(publicKey.bytes),
      privateKeyBase64: base64.encode(privateKeyBytes),
    );
  }

  /// Wraps a symmetric AES key [base64Key] for [recipientPublicKeyBase64] using
  /// X25519 Diffie-Hellman key agreement and AES-256-GCM.
  ///
  /// Returns a JSON-encoded string containing ephemeral public key, nonce, ciphertext, and MAC.
  Future<String> wrapKey({
    required String base64Key,
    required String recipientPublicKeyBase64,
  }) async {
    final x25519 = crypto.X25519();
    final aesGcm = crypto.AesGcm.with256bits();
    final sha256 = crypto.Sha256();

    final recipientPublicKeyBytes = base64.decode(recipientPublicKeyBase64);
    final ephemeralKeyPair = await x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: crypto.SimplePublicKey(
        recipientPublicKeyBytes,
        type: crypto.KeyPairType.x25519,
      ),
    );
    final sharedBytes = await sharedSecret.extractBytes();
    final derivedWrapKey = (await sha256.hash(sharedBytes)).bytes;

    final secretBox = await aesGcm.encrypt(
      utf8.encode(base64Key),
      secretKey: crypto.SecretKey(derivedWrapKey),
    );

    return jsonEncode({
      'epk': base64.encode(ephemeralPublicKey.bytes),
      'nonce': base64.encode(secretBox.nonce),
      'ct': base64.encode(secretBox.cipherText),
      'mac': base64.encode(secretBox.mac.bytes),
    });
  }

  /// Unwraps a wrapped symmetric key using [recipientPrivateKeyBase64].
  ///
  /// Returns the original [base64Key] symmetric AES key string.
  Future<String> unwrapKey({
    required String wrappedKeyJson,
    required String recipientPrivateKeyBase64,
    String? recipientPublicKeyBase64,
  }) async {
    final x25519 = crypto.X25519();
    final aesGcm = crypto.AesGcm.with256bits();
    final sha256 = crypto.Sha256();

    final decoded = jsonDecode(wrappedKeyJson) as Map<String, dynamic>;
    final epkBytes = base64.decode(decoded['epk'] as String);
    final nonce = base64.decode(decoded['nonce'] as String);
    final ct = base64.decode(decoded['ct'] as String);
    final mac = base64.decode(decoded['mac'] as String);

    final privateKeyBytes = base64.decode(recipientPrivateKeyBase64);
    final recipientKeyPair = await x25519.newKeyPairFromSeed(privateKeyBytes);

    final sharedSecret = await x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: crypto.SimplePublicKey(
        epkBytes,
        type: crypto.KeyPairType.x25519,
      ),
    );
    final sharedBytes = await sharedSecret.extractBytes();
    final derivedWrapKey = (await sha256.hash(sharedBytes)).bytes;

    final unwrappedBytes = await aesGcm.decrypt(
      crypto.SecretBox(ct, nonce: nonce, mac: crypto.Mac(mac)),
      secretKey: crypto.SecretKey(derivedWrapKey),
    );

    return utf8.decode(unwrappedBytes);
  }
}

/// Holds the public and private key for X25519 asymmetric envelope encryption.
class X25519KeyPairData {
  final String publicKeyBase64;
  final String privateKeyBase64;

  const X25519KeyPairData({
    required this.publicKeyBase64,
    required this.privateKeyBase64,
  });

  Map<String, String> toJson() => {
        'publicKey': publicKeyBase64,
        'privateKey': privateKeyBase64,
      };

  factory X25519KeyPairData.fromJson(Map<String, dynamic> json) =>
      X25519KeyPairData(
        publicKeyBase64: json['publicKey'] as String,
        privateKeyBase64: json['privateKey'] as String,
      );
}

/// Holds the components of an AES-256-GCM encrypted payload.
class EncryptedPayload {
  final String ciphertext; // base64-encoded ciphertext (includes GCM tag)
  final String iv; // base64-encoded 12-byte initialization vector
  final String authTag; // reserved for explicit auth tag (empty when embedded)

  const EncryptedPayload({
    required this.ciphertext,
    required this.iv,
    required this.authTag,
  });

  /// Serializes to a JSON-safe map for Drift/Irys storage.
  Map<String, String> toJson() => {
        'ciphertext': ciphertext,
        'iv': iv,
        'authTag': authTag,
      };

  /// Deserializes from a JSON map.
  factory EncryptedPayload.fromJson(Map<String, dynamic> json) {
    return EncryptedPayload(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
      authTag: json['authTag'] as String? ?? '',
    );
  }
}
