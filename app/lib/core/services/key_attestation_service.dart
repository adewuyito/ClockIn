import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';

/// Binds an X25519 encryption public key to a Solana wallet address with an
/// Ed25519 signature produced by that wallet.
///
/// Without this binding, the X25519 public keys published to Firestore are only
/// as trustworthy as Firestore's write rules: anyone able to write
/// `/users/{walletAddress}` could substitute their own encryption key and
/// silently receive every deliverable key wrapped for that address. A signature
/// over a canonical, domain-separated message makes the directory untrusted
/// infrastructure — a substituted key cannot produce a valid signature for a
/// wallet whose private key the attacker does not hold.
///
/// The message is deliberately short, printable ASCII so wallet apps can render
/// it legibly in their "sign message" prompt.
class KeyAttestationService {
  const KeyAttestationService();

  /// Domain separator. Bump the version suffix if the message layout changes so
  /// signatures over an older layout can never be replayed against a newer one.
  static const String domain = 'ClockIn Key Registration v1';

  /// Builds the exact bytes a wallet signs to attest ownership of an X25519 key.
  ///
  /// Both fields are included so a signature is valid for exactly one
  /// (wallet, encryption key) pair and cannot be transplanted onto another.
  static Uint8List buildMessage({
    required String walletAddress,
    required String x25519PublicKeyBase64,
  }) {
    final message = '$domain\n'
        'wallet: $walletAddress\n'
        'x25519: $x25519PublicKeyBase64';
    return Uint8List.fromList(utf8.encode(message));
  }

  /// Verifies that [signatureBase64] is a valid Ed25519 signature by
  /// [walletAddress] over the canonical message for [x25519PublicKeyBase64].
  ///
  /// Returns `false` — never throws — for a malformed address, malformed
  /// signature, or a signature that simply does not verify, so callers can
  /// treat every failure as "no trusted key available".
  static Future<bool> verify({
    required String walletAddress,
    required String x25519PublicKeyBase64,
    required String signatureBase64,
  }) async {
    try {
      final publicKey = Ed25519HDPublicKey.fromBase58(walletAddress);
      final signature = base64.decode(signatureBase64);
      if (signature.length != 64) {
        debugPrint(
          '[KeyAttestation] Rejected key for $walletAddress: '
          'signature is ${signature.length} bytes, expected 64.',
        );
        return false;
      }

      final ok = await verifySignature(
        message: buildMessage(
          walletAddress: walletAddress,
          x25519PublicKeyBase64: x25519PublicKeyBase64,
        ),
        signature: signature,
        publicKey: publicKey,
      );

      if (!ok) {
        debugPrint(
          '[KeyAttestation] Rejected key for $walletAddress: '
          'signature does not verify against this wallet.',
        );
      }
      return ok;
    } catch (e) {
      debugPrint('[KeyAttestation] Rejected key for $walletAddress: $e');
      return false;
    }
  }
}
