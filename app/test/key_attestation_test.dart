import 'dart:convert';

import 'package:clockin/core/services/key_attestation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';

/// These tests pin down the property that makes the Firestore key directory
/// safe to read: a published X25519 key is only trusted when accompanied by an
/// Ed25519 signature from the wallet it claims to belong to.
void main() {
  late Ed25519HDKeyPair wallet;
  late Ed25519HDKeyPair attacker;
  const x25519PublicKey = 'TFZGVGhpc0lzQVRlc3RYMjU1MTlQdWJsaWNLZXk9';

  Future<String> signAs(
    Ed25519HDKeyPair signer, {
    required String walletAddress,
    required String keyBase64,
  }) async {
    final message = KeyAttestationService.buildMessage(
      walletAddress: walletAddress,
      x25519PublicKeyBase64: keyBase64,
    );
    final signature = await signer.sign(message);
    return base64.encode(signature.bytes);
  }

  setUp(() async {
    wallet = await Ed25519HDKeyPair.random();
    attacker = await Ed25519HDKeyPair.random();
  });

  group('KeyAttestationService.buildMessage', () {
    test('is deterministic for the same wallet and key', () {
      final a = KeyAttestationService.buildMessage(
        walletAddress: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
        x25519PublicKeyBase64: x25519PublicKey,
      );
      final b = KeyAttestationService.buildMessage(
        walletAddress: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
        x25519PublicKeyBase64: x25519PublicKey,
      );
      expect(a, equals(b));
    });

    test('is domain-separated and binds both wallet and key', () {
      final message = utf8.decode(
        KeyAttestationService.buildMessage(
          walletAddress: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
          x25519PublicKeyBase64: x25519PublicKey,
        ),
      );
      expect(message, startsWith(KeyAttestationService.domain));
      expect(message, contains('Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ'));
      expect(message, contains(x25519PublicKey));
    });

    test('differs when only the encryption key differs', () {
      final a = KeyAttestationService.buildMessage(
        walletAddress: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
        x25519PublicKeyBase64: x25519PublicKey,
      );
      final b = KeyAttestationService.buildMessage(
        walletAddress: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
        x25519PublicKeyBase64: 'c29tZU90aGVyWDI1NTE5UHVibGljS2V5VmFsdWU9',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('KeyAttestationService.verify', () {
    test('accepts a key signed by the wallet that claims it', () async {
      final address = wallet.address;
      final signature = await signAs(
        wallet,
        walletAddress: address,
        keyBase64: x25519PublicKey,
      );

      expect(
        await KeyAttestationService.verify(
          walletAddress: address,
          x25519PublicKeyBase64: x25519PublicKey,
          signatureBase64: signature,
        ),
        isTrue,
      );
    });

    test('rejects a key substituted by an attacker (the MITM case)', () async {
      // The attacker overwrites the victim's directory entry with their own
      // X25519 key, signing with their own wallet. The signature is internally
      // valid but is not from the wallet the reader asked about.
      const attackerKey = 'YXR0YWNrZXJDb250cm9sbGVkWDI1NTE5S2V5VmFsdWU9';
      final signature = await signAs(
        attacker,
        walletAddress: attacker.address,
        keyBase64: attackerKey,
      );

      expect(
        await KeyAttestationService.verify(
          walletAddress: wallet.address,
          x25519PublicKeyBase64: attackerKey,
          signatureBase64: signature,
        ),
        isFalse,
      );
    });

    test('rejects a valid signature transplanted onto a different key', () async {
      final address = wallet.address;
      final signature = await signAs(
        wallet,
        walletAddress: address,
        keyBase64: x25519PublicKey,
      );

      expect(
        await KeyAttestationService.verify(
          walletAddress: address,
          x25519PublicKeyBase64: 'c3Vic3RpdHV0ZWRLZXlXaXRoU3RvbGVuU2lnPT0h',
          signatureBase64: signature,
        ),
        isFalse,
      );
    });

    test('rejects a signature bound to a different wallet address', () async {
      // Signed over the attacker's address, then replayed under the victim's.
      final signature = await signAs(
        wallet,
        walletAddress: attacker.address,
        keyBase64: x25519PublicKey,
      );

      expect(
        await KeyAttestationService.verify(
          walletAddress: wallet.address,
          x25519PublicKeyBase64: x25519PublicKey,
          signatureBase64: signature,
        ),
        isFalse,
      );
    });

    test('rejects malformed input without throwing', () async {
      final address = wallet.address;

      expect(
        await KeyAttestationService.verify(
          walletAddress: address,
          x25519PublicKeyBase64: x25519PublicKey,
          signatureBase64: 'not-valid-base64!!!',
        ),
        isFalse,
      );

      expect(
        await KeyAttestationService.verify(
          walletAddress: address,
          x25519PublicKeyBase64: x25519PublicKey,
          signatureBase64: base64.encode(List<int>.filled(16, 7)),
        ),
        isFalse,
      );

      expect(
        await KeyAttestationService.verify(
          walletAddress: 'not-a-solana-address',
          x25519PublicKeyBase64: x25519PublicKey,
          signatureBase64: base64.encode(List<int>.filled(64, 0)),
        ),
        isFalse,
      );
    });
  });
}
