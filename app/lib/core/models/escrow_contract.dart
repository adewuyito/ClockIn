import '../solana/network_config.dart';

/// Denomination of an escrow contract.
///
/// The on-chain program accepts *any* SPL mint for token escrows, so the app
/// must not assume every token contract is one it recognises. [unknown] covers
/// a mint that is neither devnet USDC nor devnet $SKR: it is shown in raw base
/// units under an explicit "unverified" label, because its decimals and its
/// value are both unknown — and a worker must never be told a contract is
/// funded in $SKR or USDC when the vault actually holds some other token.
enum EscrowCurrency {
  sol,
  usdc,
  skr,
  unknown;

  String get symbol {
    switch (this) {
      case EscrowCurrency.sol:
        return 'SOL';
      case EscrowCurrency.usdc:
        return 'USDC';
      case EscrowCurrency.skr:
        return r'$SKR';
      case EscrowCurrency.unknown:
        return 'UNVERIFIED';
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
      case EscrowCurrency.unknown:
        return 'Unverified SPL token';
    }
  }

  /// Short descriptor shown under amounts in lists and cards.
  String get subtitle {
    switch (this) {
      case EscrowCurrency.sol:
        return 'Native SOL';
      case EscrowCurrency.usdc:
        return 'USD Coin (SPL)';
      case EscrowCurrency.skr:
        return 'Seeker SPL';
      case EscrowCurrency.unknown:
        return 'Unverified mint';
    }
  }

  /// Decimal places of the mint. For [unknown] this is 0: amounts are shown in
  /// raw base units rather than scaled by a guessed precision.
  int get decimals {
    switch (this) {
      case EscrowCurrency.sol:
        return 9;
      case EscrowCurrency.usdc:
      case EscrowCurrency.skr:
        return 6;
      case EscrowCurrency.unknown:
        return 0;
    }
  }

  /// `10^decimals` — base units per whole token.
  double get divisor {
    switch (this) {
      case EscrowCurrency.sol:
        return 1e9;
      case EscrowCurrency.usdc:
      case EscrowCurrency.skr:
        return 1e6;
      case EscrowCurrency.unknown:
        return 1;
    }
  }

  bool get isToken => this != EscrowCurrency.sol;

  /// Whether this is a token the app recognises and can value.
  bool get isRecognised => this != EscrowCurrency.unknown;

  /// Configured devnet mint for a recognised token; null for SOL and [unknown].
  String? get mintAddress {
    switch (this) {
      case EscrowCurrency.sol:
      case EscrowCurrency.unknown:
        return null;
      case EscrowCurrency.usdc:
        return NetworkConfig.devnetUsdcMint;
      case EscrowCurrency.skr:
        return NetworkConfig.devnetSkrMint;
    }
  }

  /// Classifies a contract by its on-chain mint.
  ///
  /// A token contract with no recorded mint is treated as $SKR: rows cached
  /// before multi-currency support were written with `tokenMint ?? devnetSkrMint`
  /// semantics, and $SKR was the only token escrow that existed then.
  static EscrowCurrency fromMintOrToken({required bool isToken, String? tokenMint}) {
    if (!isToken) return EscrowCurrency.sol;
    if (tokenMint == null || tokenMint.isEmpty) return EscrowCurrency.skr;
    if (tokenMint == NetworkConfig.devnetUsdcMint) return EscrowCurrency.usdc;
    if (tokenMint == NetworkConfig.devnetSkrMint) return EscrowCurrency.skr;
    return EscrowCurrency.unknown;
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

  /// Whether this contract's mint is one the app does not recognise.
  bool get isUnknownMint => currency == EscrowCurrency.unknown;

  /// Currency symbol ("SOL", "USDC", "$SKR", or "UNVERIFIED").
  String get currencySymbol => currency.symbol;

  /// Amount in whole units of this contract's own currency (scaled by its
  /// decimals). This is the only amount accessor: per-currency getters such as
  /// a fixed ÷1e9 "amountSol" silently mis-scale token contracts, which is how
  /// the contracts-list total came to show 50 USDC as "0".
  double get amountUi => amount.toDouble() / currency.divisor;

  /// Formats [baseUnits] (lamports for SOL, raw token units otherwise) as an
  /// exact amount in this contract's currency, e.g. "1.5 SOL", "12.345678 USDC".
  ///
  /// Uses integer arithmetic only, so the figure shown is exactly what the
  /// program will move — no float rounding. This matters on confirmation
  /// screens: a 50/50 split of 0.000005 USDC must not be displayed as "0.00".
  /// Unrecognised mints are shown in raw base units with no symbol, since their
  /// decimals and value are unknown.
  String formatBaseUnits(BigInt baseUnits) {
    if (currency == EscrowCurrency.unknown) {
      return '$baseUnits base units (unverified token)';
    }
    final scale = BigInt.from(10).pow(currency.decimals);
    final whole = baseUnits ~/ scale;
    final frac = (baseUnits % scale)
        .toString()
        .padLeft(currency.decimals, '0')
        .replaceAll(RegExp(r'0+$'), '');
    final number = frac.isEmpty ? '$whole' : '$whole.$frac';
    return '$number ${currency.symbol}';
  }

  /// The full escrow amount in this contract's currency (e.g. "500 $SKR",
  /// "50 USDC", "1.5 SOL"). See [formatBaseUnits].
  String get formattedAmount => formatBaseUnits(amount);

  /// The amount the worker receives on a 50/50 dispute split.
  ///
  /// Mirrors the program exactly: `worker_amount = amount / 2` in integer base
  /// units, rounding down.
  BigInt get splitWorkerShare => amount ~/ BigInt.two;

  /// The amount the employer receives on a 50/50 split: the remainder after
  /// [splitWorkerShare], so an odd base unit goes to the employer. Vault rent is
  /// refunded to the employer separately and is not included here.
  BigInt get splitEmployerShare => amount - splitWorkerShare;

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
