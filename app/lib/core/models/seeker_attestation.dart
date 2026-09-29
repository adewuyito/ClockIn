/// Domain model representing a worker's Seeker Attestation status.
class SeekerAttestation {
  final String address;
  final bool isAttested;
  final double stakedAmount;
  final String guardianName;
  final bool cooldownActive;
  final DateTime syncedAt;

  const SeekerAttestation({
    required this.address,
    required this.isAttested,
    this.stakedAmount = 0.0,
    this.guardianName = 'Helius',
    this.cooldownActive = false,
    required this.syncedAt,
  });

  bool get hasSufficientStake => stakedAmount >= 250.0;

  String get shortAddress =>
      address.length > 8 ? '${address.substring(0, 4)}…${address.substring(address.length - 4)}' : address;

  SeekerAttestation copyWith({
    String? address,
    bool? isAttested,
    double? stakedAmount,
    String? guardianName,
    bool? cooldownActive,
    DateTime? syncedAt,
  }) {
    return SeekerAttestation(
      address: address ?? this.address,
      isAttested: isAttested ?? this.isAttested,
      stakedAmount: stakedAmount ?? this.stakedAmount,
      guardianName: guardianName ?? this.guardianName,
      cooldownActive: cooldownActive ?? this.cooldownActive,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
