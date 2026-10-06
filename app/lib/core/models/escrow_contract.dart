import '../solana/network_config.dart';

enum EscrowCurrency {
  sol,
  usdc,
  skr;

  String get symbol {
    switch (this) {
      case EscrowCurrency.sol:
        return 'SOL';
      case EscrowCurrency.usdc:
        return 'USDC';
      case EscrowCurrency.skr:
        return r'$SKR';
    }
  }

  String get displayName {
    switch (this) {
      case EscrowCurrency.sol:
        return 'Native SOL';
      case EscrowCurrency.usdc:
        return 'USD Coin (USDC)';
      case EscrowCurrency.skr:
        return r'Seeker Token ($SKR)';
    }
  }

  int get decimals {
    switch (this) {
      case EscrowCurrency.sol:
        return 9;
      case EscrowCurrency.usdc:
      case EscrowCurrency.skr:
        return 6;
    }
  }

  double get divisor {
    switch (this) {
      case EscrowCurrency.sol:
        return 1e9;
      case EscrowCurrency.usdc:
      case EscrowCurrency.skr:
        return 1e6;
    }
  }

  bool get isToken => this != EscrowCurrency.sol;

  String? get mintAddress {
    switch (this) {
      case EscrowCurrency.sol:
        return null;
      case EscrowCurrency.usdc:
        return NetworkConfig.devnetUsdcMint;
      case EscrowCurrency.skr:
        return NetworkConfig.devnetSkrMint;
    }
  }

  static EscrowCurrency fromMintOrToken({required bool isToken, String? tokenMint}) {
    if (!isToken) return EscrowCurrency.sol;
    if (tokenMint == NetworkConfig.devnetUsdcMint) return EscrowCurrency.usdc;
    return EscrowCurrency.skr;
  }
}

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

  /// True once the contract has reached a settled end state, so no further
  /// action or notification about it is meaningful.
  ///
  /// `disputed` is deliberately NOT terminal — a dispute is still live work
  /// (direct resolution or juror arbitration) and both parties still need
  /// events about it.
  bool get isTerminal =>
      this == ContractStatus.completed || this == ContractStatus.cancelled;

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
  final bool isToken;
  final String? tokenMint;
  final String? disputeReason;
  final String? disputeDetails;
  final String? disputeEvidenceUri;
  final String? disputeRaisedBy;
  final DateTime? disputeRaisedAt;

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
    this.isToken = false,
    this.tokenMint,
    this.disputeReason,
    this.disputeDetails,
    this.disputeEvidenceUri,
    this.disputeRaisedBy,
    this.disputeRaisedAt,
  });

  /// The currency for this escrow contract.
  EscrowCurrency get currency =>
      EscrowCurrency.fromMintOrToken(isToken: isToken, tokenMint: tokenMint);

  /// Whether this contract is denominated in USDC.
  bool get isUsdc => currency == EscrowCurrency.usdc;

  /// Whether this contract is denominated in $SKR SPL tokens.
  bool get isSkr => currency == EscrowCurrency.skr;

  /// Currency symbol ("SOL", "USDC", or "$SKR").
  String get currencySymbol => currency.symbol;

  /// Formatted base amount in UI units (scaled by currency decimals).
  double get amountUi => amount.toDouble() / currency.divisor;

  /// Amount formatted in SOL (e.g. 1.5).
  double get amountSol => amount.toDouble() / 1e9;

  /// Amount formatted in SPL tokens (e.g. 500.0).
  double get amountToken => amount.toDouble() / 1e6;

  /// Formatted SOL string with up to 4 decimals (e.g. "1.5 SOL").
  String get formattedSol {
    final sol = amountSol;
    if (sol == sol.roundToDouble()) {
      return '${sol.toStringAsFixed(0)} SOL';
    } else {
      return '${sol.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '')} SOL';
    }
  }

  /// Formatted amount string with currency symbol (e.g. "500 $SKR", "50 USDC", or "1.5 SOL").
  String get formattedAmount {
    switch (currency) {
      case EscrowCurrency.sol:
        return formattedSol;
      case EscrowCurrency.usdc:
        final val = amountUi;
        if (val == val.roundToDouble()) {
          return '${val.toStringAsFixed(0)} USDC';
        } else {
          return '${val.toStringAsFixed(2)} USDC';
        }
      case EscrowCurrency.skr:
        final tokenVal = amountUi;
        if (tokenVal == tokenVal.roundToDouble()) {
          return '${tokenVal.toStringAsFixed(0)} \$SKR';
        } else {
          return '${tokenVal.toStringAsFixed(2)} \$SKR';
        }
    }
  }

  /// Truncated contract ID for UI display (e.g. "ctr_9x").
  String get shortId =>
      contractId.length >= 8 ? '${contractId.substring(0, 6)}…' : contractId;

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
    bool? isToken,
    String? tokenMint,
    String? disputeReason,
    String? disputeDetails,
    String? disputeEvidenceUri,
    String? disputeRaisedBy,
    DateTime? disputeRaisedAt,
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
      isToken: isToken ?? this.isToken,
      tokenMint: tokenMint ?? this.tokenMint,
      disputeReason: disputeReason ?? this.disputeReason,
      disputeDetails: disputeDetails ?? this.disputeDetails,
      disputeEvidenceUri: disputeEvidenceUri ?? this.disputeEvidenceUri,
      disputeRaisedBy: disputeRaisedBy ?? this.disputeRaisedBy,
      disputeRaisedAt: disputeRaisedAt ?? this.disputeRaisedAt,
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
