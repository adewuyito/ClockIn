enum ContractStatus {
  created,
  funded,
  inProgress,
  completed,
  disputed,
  cancelled;

  static ContractStatus fromIndex(int index) {
    switch (index) {
      case 0:
        return ContractStatus.created;
      case 1:
        return ContractStatus.funded;
      case 2:
        return ContractStatus.inProgress;
      case 3:
        return ContractStatus.completed;
      case 4:
        return ContractStatus.disputed;
      case 5:
        return ContractStatus.cancelled;
      default:
        return ContractStatus.created;
    }
  }

  static ContractStatus fromString(String str) {
    switch (str.toLowerCase()) {
      case 'created':
        return ContractStatus.created;
      case 'funded':
        return ContractStatus.funded;
      case 'inprogress':
      case 'in_progress':
        return ContractStatus.inProgress;
      case 'completed':
        return ContractStatus.completed;
      case 'disputed':
        return ContractStatus.disputed;
      case 'cancelled':
        return ContractStatus.cancelled;
      default:
        return ContractStatus.created;
    }
  }

  String get displayName {
    switch (this) {
      case ContractStatus.created:
        return 'Created (Unfunded)';
      case ContractStatus.funded:
        return 'Funded (Escrow Locked)';
      case ContractStatus.inProgress:
        return 'In Progress';
      case ContractStatus.completed:
        return 'Completed & Released';
      case ContractStatus.disputed:
        return 'Disputed';
      case ContractStatus.cancelled:
        return 'Cancelled & Refunded';
    }
  }
}

/// Domain model representing an on-chain P2P escrow contract.
class EscrowContract {
  final String contractId;
  final String employer;
  final String worker;
  final BigInt amount; // lamports
  final String termsHash;
  final String? termsText;
  final ContractStatus status;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? fundedAt;
  final DateTime? completedAt;
  final int rating;
  final String? lastTxSignature;
  final DateTime? syncedAt;

  const EscrowContract({
    required this.contractId,
    required this.employer,
    required this.worker,
    required this.amount,
    required this.termsHash,
    this.termsText,
    required this.status,
    this.deadline,
    required this.createdAt,
    this.fundedAt,
    this.completedAt,
    this.rating = 0,
    this.lastTxSignature,
    this.syncedAt,
  });

  /// Amount formatted in SOL (e.g. 1.5).
  double get amountSol => amount.toDouble() / 1e9;

  /// Formatted SOL string with up to 4 decimals (e.g. "1.5 SOL").
  String get formattedSol {
    final sol = amountSol;
    if (sol == sol.roundToDouble()) {
      return '${sol.toStringAsFixed(0)} SOL';
    } else {
      return '${sol.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '')} SOL';
    }
  }

  /// Truncated employer address for UI display.
  String get shortEmployer => _shortAddress(employer);

  /// Truncated worker address for UI display.
  String get shortWorker => _shortAddress(worker);

  static String _shortAddress(String addr) {
    if (addr.length <= 10) return addr;
    return '${addr.substring(0, 4)}…${addr.substring(addr.length - 4)}';
  }

  bool isEmployer(String? currentWallet) =>
      currentWallet != null && employer.toLowerCase() == currentWallet.toLowerCase();

  bool isWorker(String? currentWallet) =>
      currentWallet != null && worker.toLowerCase() == currentWallet.toLowerCase();

  bool canAccept(String? currentWallet) =>
      status == ContractStatus.funded && isWorker(currentWallet);

  bool canRelease(String? currentWallet) =>
      (status == ContractStatus.funded || status == ContractStatus.inProgress) &&
      isEmployer(currentWallet);

  bool canCancel(String? currentWallet) =>
      (status == ContractStatus.created || status == ContractStatus.funded) &&
      isEmployer(currentWallet);

  bool canDispute(String? currentWallet) =>
      (status == ContractStatus.funded || status == ContractStatus.inProgress) &&
      (isEmployer(currentWallet) || isWorker(currentWallet));

  EscrowContract copyWith({
    String? contractId,
    String? employer,
    String? worker,
    BigInt? amount,
    String? termsHash,
    String? termsText,
    ContractStatus? status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? fundedAt,
    DateTime? completedAt,
    int? rating,
    String? lastTxSignature,
    DateTime? syncedAt,
  }) {
    return EscrowContract(
      contractId: contractId ?? this.contractId,
      employer: employer ?? this.employer,
      worker: worker ?? this.worker,
      amount: amount ?? this.amount,
      termsHash: termsHash ?? this.termsHash,
      termsText: termsText ?? this.termsText,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      fundedAt: fundedAt ?? this.fundedAt,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      lastTxSignature: lastTxSignature ?? this.lastTxSignature,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EscrowContract &&
          runtimeType == other.runtimeType &&
          contractId == other.contractId &&
          status == other.status &&
          amount == other.amount;

  @override
  int get hashCode => contractId.hashCode ^ status.hashCode ^ amount.hashCode;
}
