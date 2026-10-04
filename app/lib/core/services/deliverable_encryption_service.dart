import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:encrypt/encrypt.dart';

/// Service providing AES-256-GCM encryption/decryption for E2EE deliverable
/// submissions. Each contract gets a unique symmetric key generated locally
/// by the worker. The key is shared out-of-band (QR fragment) and never
/// stored on-chain or uploaded to Irys.
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
