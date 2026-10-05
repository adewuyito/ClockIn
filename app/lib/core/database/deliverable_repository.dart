import 'package:drift/drift.dart';
import '../models/deliverable_submission.dart' as domain;
import '../services/deliverable_encryption_service.dart';
import '../services/irys_storage_service.dart';
import 'app_database.dart';

/// Repository coordinating local encrypted deliverable submissions in Drift
/// with Irys/Arweave permanent decentralized storage.
class DeliverableRepository {
  final AppDatabase db;
  final DeliverableEncryptionService encryptionService;
  final IrysStorageService irysService;

  DeliverableRepository({
    required this.db,
    required this.encryptionService,
    required this.irysService,
  });

  // ==================== REACTIVE DRIFT STREAMS ====================

  /// Watches all deliverable submissions for a given [contractId], ordered newest first.
  Stream<List<domain.DeliverableSubmission>> watchSubmissionsForContract(String contractId) {
    final query = db.select(db.deliverableSubmissions)
      ..where((tbl) => tbl.contractId.equals(contractId))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.submittedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_rowToDomain).toList());
  }

  /// Watches the latest deliverable submission for a [contractId].
  Stream<domain.DeliverableSubmission?> watchLatestSubmission(String contractId) {
    final query = db.select(db.deliverableSubmissions)
      ..where((tbl) => tbl.contractId.equals(contractId))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.submittedAt, mode: OrderingMode.desc),
      ])
      ..limit(1);

    return query.watchSingleOrNull().map((row) => row != null ? _rowToDomain(row) : null);
  }

  // ==================== READS ====================

  /// Gets all submissions for a contract from Drift cache.
  Future<List<domain.DeliverableSubmission>> getSubmissionsForContract(String contractId) async {
    final query = db.select(db.deliverableSubmissions)
      ..where((tbl) => tbl.contractId.equals(contractId))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.submittedAt, mode: OrderingMode.desc),
      ]);

    final rows = await query.get();
    return rows.map(_rowToDomain).toList();
  }

  /// Gets the latest submission for a contract from Drift cache.
  Future<domain.DeliverableSubmission?> getLatestSubmission(String contractId) async {
    final query = db.select(db.deliverableSubmissions)
      ..where((tbl) => tbl.contractId.equals(contractId))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.submittedAt, mode: OrderingMode.desc),
      ])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row != null ? _rowToDomain(row) : null;
  }

  // ==================== SUBMISSION & ENCRYPTION ====================

  /// Encrypts deliverable plaintext with [encryptionKey] (AES-256-GCM),
  /// computes SHA-256 integrity hash, uploads ciphertext to Irys,
  /// and saves the encrypted submission into Drift.
  ///
  /// Zero information leak: [plaintext] and [encryptionKey] are NEVER stored
  /// in Drift or uploaded to Irys. Only ciphertext, IV, auth tag, and plaintext hash
  // ==================== ASYMMETRIC X25519 ENCRYPTION KEYS ====================

  /// Gets the existing X25519 keypair for [walletAddress] or generates and persists a new one in Drift.
  Future<X25519KeyPairData> getOrCreateKeyPair(String walletAddress) async {
    final existing = await (db.select(db.userEncryptionKeys)
          ..where((tbl) => tbl.walletAddress.equals(walletAddress))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      return X25519KeyPairData(
        publicKeyBase64: existing.publicKey,
        privateKeyBase64: existing.privateKey,
      );
    }

    final keyPair = await encryptionService.generateX25519KeyPair();
    await db.into(db.userEncryptionKeys).insertOnConflictUpdate(
          UserEncryptionKeysCompanion.insert(
            walletAddress: walletAddress,
            publicKey: keyPair.publicKeyBase64,
            privateKey: keyPair.privateKeyBase64,
            createdAt: Value(DateTime.now().toUtc()),
          ),
        );

    return keyPair;
  }

  /// Gets the X25519 private key for [walletAddress] from local Drift storage.
  Future<String?> getPrivateKey(String walletAddress) async {
    final key = await (db.select(db.userEncryptionKeys)
          ..where((tbl) => tbl.walletAddress.equals(walletAddress))
          ..limit(1))
        .getSingleOrNull();
    return key?.privateKey;
  }

  // ==================== SUBMISSION & ENCRYPTION ====================

  /// Encrypts deliverable plaintext with [encryptionKey] (AES-256-GCM),
  /// computes SHA-256 integrity hash, uploads ciphertext to Irys,
  /// and saves the encrypted submission into Drift.
  ///
  /// Zero information leak: [plaintext] and [encryptionKey] are NEVER stored
  /// in Drift or uploaded to Irys. Only ciphertext, IV, auth tag, plaintext hash,
  /// and optional [wrappedKey] are persisted.
  Future<domain.DeliverableSubmission> submitDeliverable({
    required String contractId,
    required String submitterAddress,
    required String plaintext,
    required String encryptionKey,
    String? completionNote,
    String? wrappedKey,
  }) async {
    // 1. Compute SHA-256 integrity hash of original plaintext
    final plaintextHash = encryptionService.computeHash(plaintext);

    // 2. Encrypt plaintext using AES-256-GCM with per-contract key
    final encrypted = encryptionService.encrypt(plaintext, encryptionKey);

    // 3. Compute hash of the key (for verification without storing the key)
    final keyHash = encryptionService.hashKey(encryptionKey);

    final now = DateTime.now().toUtc();

    // 4. Upload encrypted payload to Arweave via Irys
    String? arweaveTxId;
    try {
      arweaveTxId = await irysService.uploadEncryptedDeliverable(
        contractId: contractId,
        submitterAddress: submitterAddress,
        encryptedPayload: encrypted.ciphertext,
        iv: encrypted.iv,
        plaintextHash: plaintextHash,
        authTag: encrypted.authTag,
      );
    } catch (_) {
      // Soft failure: local Drift record is primary
    }

    // 5. Store encrypted record in Drift database
    final insertedId = await db.into(db.deliverableSubmissions).insert(
          DeliverableSubmissionsCompanion.insert(
            contractId: contractId,
            submitterAddress: submitterAddress,
            encryptedPayload: encrypted.ciphertext,
            iv: encrypted.iv,
            authTag: Value(encrypted.authTag),
            plaintextHash: plaintextHash,
            arweaveTxId: Value(arweaveTxId),
            submittedAt: Value(now),
            status: const Value('submitted'),
            decryptionKeyHash: Value(keyHash),
            completionNote: Value(completionNote),
            wrappedKey: Value(wrappedKey),
            syncedAt: Value(now),
          ),
        );

    return domain.DeliverableSubmission(
      id: insertedId,
      contractId: contractId,
      submitterAddress: submitterAddress,
      encryptedPayload: encrypted.ciphertext,
      iv: encrypted.iv,
      authTag: encrypted.authTag,
      plaintextHash: plaintextHash,
      arweaveTxId: arweaveTxId,
      submittedAt: now,
      status: domain.DeliverableStatus.submitted,
      decryptionKeyHash: keyHash,
      completionNote: completionNote,
      wrappedKey: wrappedKey,
      syncedAt: now,
    );
  }

  /// Saves or imports an encrypted deliverable submission received via QR code,
  /// Firebase real-time listener, or peer-to-peer exchange into the local Drift database.
  Future<domain.DeliverableSubmission> saveReceivedSubmission({
    required String contractId,
    required String submitterAddress,
    required String encryptedPayload,
    required String iv,
    required String plaintextHash,
    String authTag = '',
    String? arweaveTxId,
    String? completionNote,
    String? keyHash,
    String? wrappedKey,
  }) async {
    // Prevent duplicate entries if scanned multiple times
    final existing = await (db.select(db.deliverableSubmissions)
          ..where((tbl) =>
              tbl.contractId.equals(contractId) &
              tbl.plaintextHash.equals(plaintextHash))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      if (wrappedKey != null && existing.wrappedKey == null) {
        await (db.update(db.deliverableSubmissions)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(DeliverableSubmissionsCompanion(
          wrappedKey: Value(wrappedKey),
          syncedAt: Value(DateTime.now().toUtc()),
        ));
      }
      return _rowToDomain(existing).copyWith(wrappedKey: wrappedKey ?? existing.wrappedKey);
    }

    final now = DateTime.now().toUtc();
    final insertedId = await db.into(db.deliverableSubmissions).insert(
          DeliverableSubmissionsCompanion.insert(
            contractId: contractId,
            submitterAddress: submitterAddress,
            encryptedPayload: encryptedPayload,
            iv: iv,
            authTag: Value(authTag),
            plaintextHash: plaintextHash,
            arweaveTxId: Value(arweaveTxId),
            submittedAt: Value(now),
            status: const Value('submitted'),
            decryptionKeyHash: Value(keyHash),
            completionNote: Value(completionNote),
            wrappedKey: Value(wrappedKey),
            syncedAt: Value(now),
          ),
        );

    return domain.DeliverableSubmission(
      id: insertedId,
      contractId: contractId,
      submitterAddress: submitterAddress,
      encryptedPayload: encryptedPayload,
      iv: iv,
      authTag: authTag,
      plaintextHash: plaintextHash,
      arweaveTxId: arweaveTxId,
      submittedAt: now,
      status: domain.DeliverableStatus.submitted,
      decryptionKeyHash: keyHash,
      completionNote: completionNote,
      wrappedKey: wrappedKey,
      syncedAt: now,
    );
  }

  // ==================== DECRYPTION & VERIFICATION ====================

  /// Decrypts a submission's encrypted payload using [decryptionKey], and verifies
  /// that SHA-256 of decrypted text matches [DeliverableSubmission.plaintextHash].
  ///
  /// Throws [Exception] if decryption fails or integrity hash mismatch is detected.
  String decryptAndVerify({
    required domain.DeliverableSubmission submission,
    required String decryptionKey,
  }) {
    final payload = EncryptedPayload(
      ciphertext: submission.encryptedPayload,
      iv: submission.iv,
      authTag: submission.authTag,
    );

    final decrypted = encryptionService.decrypt(payload, decryptionKey);

    // Verify integrity
    final matches = encryptionService.verifyHash(decrypted, submission.plaintextHash);
    if (!matches) {
      throw Exception('Deliverable integrity check failed: decrypted text does not match hash!');
    }

    return decrypted;
  }

  // ==================== STATUS UPDATES ====================

  /// Updates the status of a deliverable submission (e.g. reviewed, revision requested).
  Future<void> updateStatus(int submissionId, domain.DeliverableStatus status) async {
    String statusStr;
    switch (status) {
      case domain.DeliverableStatus.submitted:
        statusStr = 'submitted';
        break;
      case domain.DeliverableStatus.reviewed:
        statusStr = 'reviewed';
        break;
      case domain.DeliverableStatus.revisionRequested:
        statusStr = 'revision_requested';
        break;
    }

    await (db.update(db.deliverableSubmissions)..where((tbl) => tbl.id.equals(submissionId))).write(
      DeliverableSubmissionsCompanion(
        status: Value(statusStr),
        syncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ==================== HELPER ====================

  domain.DeliverableSubmission _rowToDomain(DeliverableSubmissionData row) {
    return domain.DeliverableSubmission(
      id: row.id,
      contractId: row.contractId,
      submitterAddress: row.submitterAddress,
      encryptedPayload: row.encryptedPayload,
      iv: row.iv,
      authTag: row.authTag,
      plaintextHash: row.plaintextHash,
      arweaveTxId: row.arweaveTxId,
      submittedAt: row.submittedAt,
      status: domain.DeliverableStatus.fromString(row.status),
      decryptionKeyHash: row.decryptionKeyHash,
      completionNote: row.completionNote,
      wrappedKey: row.wrappedKey,
      syncedAt: row.syncedAt,
    );
  }
}
