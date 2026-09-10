/// Domain model representing a worker's on-chain reputation profile.
class WorkerProfile {
  final String address;
  final int totalJobs;
  final BigInt ratingSum;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const WorkerProfile({
    required this.address,
    required this.totalJobs,
    required this.ratingSum,
    required this.createdAt,
    this.syncedAt,
  });

  /// Average star rating (1.0 to 5.0), or 0.0 if no reviews exist.
  double get averageRating {
    if (totalJobs == 0) return 0.0;
    return ratingSum.toDouble() / totalJobs;
  }

  /// Truncated address for UI display, e.g. "GBZq…fh8P".
  String get shortAddress {
    if (address.length <= 10) return address;
    return '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
  }

  /// Copies with optional overrides.
  WorkerProfile copyWith({
    String? address,
    int? totalJobs,
    BigInt? ratingSum,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return WorkerProfile(
      address: address ?? this.address,
      totalJobs: totalJobs ?? this.totalJobs,
      ratingSum: ratingSum ?? this.ratingSum,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerProfile &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          totalJobs == other.totalJobs &&
          ratingSum == other.ratingSum &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      address.hashCode ^
      totalJobs.hashCode ^
      ratingSum.hashCode ^
      createdAt.hashCode;
}
