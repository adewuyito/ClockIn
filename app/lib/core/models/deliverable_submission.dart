/// Status of a deliverable submission in the contract lifecycle.
enum DeliverableStatus {
  /// Worker has submitted and encrypted the deliverable.
  submitted,

  /// Employer has reviewed (accepted) the deliverable.
  reviewed,

  /// Employer has requested a revision.
  revisionRequested;

  static DeliverableStatus fromString(String str) {
    switch (str.toLowerCase()) {
      case 'submitted':
        return DeliverableStatus.submitted;
      case 'reviewed':
        return DeliverableStatus.reviewed;
      case 'revision_requested':
      case 'revisionrequested':
        return DeliverableStatus.revisionRequested;
      default:
        return DeliverableStatus.submitted;
    }
  }

  String get displayName {
    switch (this) {
      case DeliverableStatus.submitted:
        return 'Submitted';
      case DeliverableStatus.reviewed:
        return 'Reviewed';
      case DeliverableStatus.revisionRequested:
        return 'Revision Requested';
    }
  }
}

/// Domain model for an E2EE deliverable submission from a worker to an employer.
///
/// The [encryptedPayload] contains AES-256-GCM ciphertext that can only be
/// decrypted with the per-contract symmetric key shared out-of-band via QR.
/// The [plaintextHash] is a SHA-256 digest of the original plaintext, used
/// for integrity verification after decryption.
class DeliverableSubmission {
  final int? id;
  final String contractId;
  final String submitterAddress;
  final String encryptedPayload; // base64 AES-256-GCM ciphertext
  final String iv; // base64 12-byte initialization vector
  final String authTag; // base64 GCM authentication tag (or empty if embedded)
  final String plaintextHash; // SHA-256 hex digest of plaintext
  final String? arweaveTxId; // Irys permanent storage TX ID
  final DateTime submittedAt;
  final DeliverableStatus status;
  final String? decryptionKeyHash; // SHA-256 of the AES key (never the key itself)
  final String? completionNote; // Optional unencrypted worker summary
  final DateTime? syncedAt;

  const DeliverableSubmission({
    this.id,
    required this.contractId,
    required this.submitterAddress,
    required this.encryptedPayload,
    required this.iv,
    required this.authTag,
    required this.plaintextHash,
    this.arweaveTxId,
    required this.submittedAt,
    this.status = DeliverableStatus.submitted,
    this.decryptionKeyHash,
    this.completionNote,
    this.syncedAt,
  });

  /// Whether this submission has been permanently stored on Arweave via Irys.
  bool get hasArweaveProvenance =>
      arweaveTxId != null && arweaveTxId!.isNotEmpty;

  /// Whether the employer has completed review.
  bool get isReviewed => status == DeliverableStatus.reviewed;

  /// Whether revision was requested.
  bool get needsRevision => status == DeliverableStatus.revisionRequested;

  DeliverableSubmission copyWith({
    int? id,
    String? contractId,
    String? submitterAddress,
    String? encryptedPayload,
    String? iv,
    String? authTag,
    String? plaintextHash,
    String? arweaveTxId,
    DateTime? submittedAt,
    DeliverableStatus? status,
    String? decryptionKeyHash,
    String? completionNote,
    DateTime? syncedAt,
  }) {
    return DeliverableSubmission(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      submitterAddress: submitterAddress ?? this.submitterAddress,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      iv: iv ?? this.iv,
      authTag: authTag ?? this.authTag,
      plaintextHash: plaintextHash ?? this.plaintextHash,
      arweaveTxId: arweaveTxId ?? this.arweaveTxId,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      decryptionKeyHash: decryptionKeyHash ?? this.decryptionKeyHash,
      completionNote: completionNote ?? this.completionNote,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliverableSubmission &&
          runtimeType == other.runtimeType &&
          contractId == other.contractId &&
          submitterAddress == other.submitterAddress &&
          plaintextHash == other.plaintextHash;

  @override
  int get hashCode =>
      contractId.hashCode ^
      submitterAddress.hashCode ^
      plaintextHash.hashCode;
}
