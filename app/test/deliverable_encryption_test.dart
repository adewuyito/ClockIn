import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockin/core/services/deliverable_encryption_service.dart';

void main() {
  late DeliverableEncryptionService service;

  setUp(() {
    service = DeliverableEncryptionService();
  });

  group('DeliverableEncryptionService Tests', () {
    test('generateKey produces a valid 32-byte (256-bit) base64url key', () {
      final key = service.generateKey();
      expect(key, isNotEmpty);
      final decoded = base64Url.decode(key);
      expect(decoded.length, equals(32)); // 256 bits
    });

    test('generateKey produces unique keys on successive invocations', () {
      final key1 = service.generateKey();
      final key2 = service.generateKey();
      expect(key1, isNot(equals(key2)));
    });

    test('encrypt and decrypt roundtrip preserves exact plaintext (URLs, notes)', () {
      final key = service.generateKey();
      const plaintext =
          'URL: https://github.com/clockin/pull/42\nNotes: Completed responsive dashboard design with Figma tokens.';

      final encrypted = service.encrypt(plaintext, key);
      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.iv, isNotEmpty);
      expect(encrypted.ciphertext, isNot(contains('github.com')));

      final decrypted = service.decrypt(encrypted, key);
      expect(decrypted, equals(plaintext));
    });

    test('decrypt with incorrect key fails', () {
      final correctKey = service.generateKey();
      final wrongKey = service.generateKey();
      const plaintext = 'Secret deliverable data';

      final encrypted = service.encrypt(plaintext, correctKey);

      expect(
        () => service.decrypt(encrypted, wrongKey),
        throwsA(anything),
      );
    });

    test('computeHash produces valid SHA-256 hex digest', () {
      const text = 'https://figma.com/file/xyz123';
      final hash = service.computeHash(text);

      expect(hash.length, equals(64)); // 32 bytes hex encoded
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('verifyHash returns true for identical content, false for tampered content', () {
      const original = 'Deliverable milestone 1 complete';
      const tampered = 'Deliverable milestone 1 altered';

      final hash = service.computeHash(original);

      expect(service.verifyHash(original, hash), isTrue);
      expect(service.verifyHash(tampered, hash), isFalse);
    });

    test('hashKey deterministically hashes the AES key for safe storage', () {
      final key = service.generateKey();
      final keyHash1 = service.hashKey(key);
      final keyHash2 = service.hashKey(key);

      expect(keyHash1, equals(keyHash2));
      expect(keyHash1.length, equals(64));
      expect(keyHash1, isNot(equals(key)));
    });
  });
}
