import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/deliverable_repository.dart';
import '../solana/wallet_adapter.dart';
import 'firebase_sync_service.dart';
import 'key_attestation_service.dart';

/// Outcome of attempting to publish this device's attested encryption key.
enum KeyRegistrationResult {
  /// Published (or re-published) a key with a valid wallet attestation.
  published,

  /// No attestation cached yet, and this call was not allowed to prompt for one.
  needsAttestation,

  /// The user declined the wallet signing prompt, or signing failed.
  declined,

  /// Wallet is not connected, so nothing could be signed or published.
  notConnected,
}

/// Publishes this device's X25519 public key to the Firestore directory,
/// accompanied by an Ed25519 attestation from the user's wallet.
///
/// Readers only trust a published key if that attestation verifies against the
/// wallet address they looked up (see [KeyAttestationService]), so publishing an
/// unattested key would be pointless — every counterparty would discard it.
///
/// Attestation is split deliberately into two entry points:
///
///  * [publishIfAttested] never shows a wallet prompt. It is safe to call during
///    app startup / on wallet connect.
///  * [attestAndPublish] shows the one-time signing prompt and must be driven by
///    a deliberate user action.
///
/// The split exists because MWA signing opens a fresh local-association scenario
/// and hands off to the wallet app, and wallets do not reliably return focus to
/// the caller afterwards (see the MWA findings in `docs/ARCHITECTURE.md`).
/// Firing a signing request automatically moments after `connect()` would chain
/// two handoffs back to back and strand the user in the wallet app.
class EncryptionKeyRegistry {
  final WalletAdapter walletAdapter;
  final DeliverableRepository deliverableRepository;
  final FirebaseSyncService syncService;

  const EncryptionKeyRegistry({
    required this.walletAdapter,
    required this.deliverableRepository,
    required this.syncService,
  });

  /// True once this wallet has a cached attestation, meaning counterparties can
  /// encrypt deliverable keys for it without any further user action.
  Future<bool> isAttested(String walletAddress) async {
    final signature =
        await deliverableRepository.getAttestationSignature(walletAddress);
    return signature != null && signature.isNotEmpty;
  }

  /// Re-publishes the already-attested key without prompting.
  ///
  /// Safe to call on every connect: it is a no-op when no attestation is cached,
  /// and otherwise just refreshes the directory entry (which is idempotent).
  Future<KeyRegistrationResult> publishIfAttested(String walletAddress) async {
    try {
      final keyPair = await deliverableRepository.getOrCreateKeyPair(walletAddress);
      final signature =
          await deliverableRepository.getAttestationSignature(walletAddress);

      if (signature == null || signature.isEmpty) {
        debugPrint(
          '[X25519] No cached attestation for $walletAddress; '
          'encrypted deliverables stay opt-in until the user attests.',
        );
        return KeyRegistrationResult.needsAttestation;
      }

      await syncService.registerUserPublicKey(
        walletAddress,
        keyPair.publicKeyBase64,
        attestationSignatureBase64: signature,
      );
      return KeyRegistrationResult.published;
    } catch (e) {
      debugPrint('[X25519] Error publishing attested encryption key: $e');
      return KeyRegistrationResult.declined;
    }
  }

  /// Requests the one-time wallet signature binding [walletAddress] to this
  /// device's X25519 key, caches it, and publishes the attested key.
  ///
  /// Must be triggered by an explicit user action — it opens an MWA handoff.
  Future<KeyRegistrationResult> attestAndPublish(String walletAddress) async {
    if (!walletAdapter.isConnected) {
      return KeyRegistrationResult.notConnected;
    }

    try {
      final keyPair = await deliverableRepository.getOrCreateKeyPair(walletAddress);
      var signature =
          await deliverableRepository.getAttestationSignature(walletAddress);

      if (signature == null || signature.isEmpty) {
        debugPrint('[X25519] Requesting one-time wallet attestation for encryption key...');
        final signatureBytes = await walletAdapter.signMessage(
          KeyAttestationService.buildMessage(
            walletAddress: walletAddress,
            x25519PublicKeyBase64: keyPair.publicKeyBase64,
          ),
        );
        signature = base64.encode(signatureBytes);

        // Verify our own attestation before storing it: a wallet that returns a
        // signature over something other than what we asked it to sign would
        // otherwise leave a permanently-rejected key cached on this device.
        final valid = await KeyAttestationService.verify(
          walletAddress: walletAddress,
          x25519PublicKeyBase64: keyPair.publicKeyBase64,
          signatureBase64: signature,
        );
        if (!valid) {
          debugPrint('[X25519] Wallet returned an attestation that does not verify; discarding.');
          return KeyRegistrationResult.declined;
        }

        await deliverableRepository.saveAttestationSignature(walletAddress, signature);
      }

      await syncService.registerUserPublicKey(
        walletAddress,
        keyPair.publicKeyBase64,
        attestationSignatureBase64: signature,
      );
      return KeyRegistrationResult.published;
    } catch (e) {
      debugPrint('[X25519] Attestation declined or failed: $e');
      return KeyRegistrationResult.declined;
    }
  }
}
