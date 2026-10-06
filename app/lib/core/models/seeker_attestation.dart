/// Domain model representing a wallet's Seeker Attestation status.
///
/// [stakedAmount] is the wallet's *active* $SKR stake as read from Solana
/// Mobile's Guardian staking program, and [syncedAt] is when that read last
/// succeeded. [verificationError] is set when the latest read failed and this
/// value comes from the local cache instead.
class SeekerAttestation {
  final String address;
  final bool isAttested;
  final double stakedAmount;
  final String guardianName;
  final bool cooldownActive;
  final DateTime syncedAt;
  final String? verificationError;

  const SeekerAttestation({
    required this.address,
    required this.isAttested,
    this.stakedAmount = 0.0,
    this.guardianName = 'Solana Mobile',
    this.cooldownActive = false,
    required this.syncedAt,
    this.verificationError,
  });

  bool get hasSufficientStake => stakedAmount >= 250.0;

  /// True when this status was confirmed on-chain rather than served from a
  /// cache after a failed read.
  bool get isFreshlyVerified => verificationError == null;

  String get shortAddress =>
      address.length > 8 ? '${address.substring(0, 4)}…${address.substring(address.length - 4)}' : address;

  SeekerAttestation copyWith({
    String? address,
    bool? isAttested,
    double? stakedAmount,
    String? guardianName,
    bool? cooldownActive,
    DateTime? syncedAt,
    String? verificationError,
  }) {
    return SeekerAttestation(
      address: address ?? this.address,
      isAttested: isAttested ?? this.isAttested,
      stakedAmount: stakedAmount ?? this.stakedAmount,
      guardianName: guardianName ?? this.guardianName,
      cooldownActive: cooldownActive ?? this.cooldownActive,
      syncedAt: syncedAt ?? this.syncedAt,
      verificationError: verificationError ?? this.verificationError,
    );
  }
}
