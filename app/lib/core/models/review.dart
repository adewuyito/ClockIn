/// Domain model representing a verified on-chain review.
class Review {
  final int? id;
  final String workerAddress;
  final String reviewerAddress;
  final String jobId;
  final int rating;
  final DateTime timestamp;
  final DateTime? syncedAt;

  const Review({
    this.id,
    required this.workerAddress,
    required this.reviewerAddress,
    required this.jobId,
    required this.rating,
    required this.timestamp,
    this.syncedAt,
  });

  /// Short truncated reviewer address for UI cards, e.g. "8x2…k9F4".
  String get shortReviewerAddress {
    if (reviewerAddress.length <= 10) return reviewerAddress;
    return '${reviewerAddress.substring(0, 4)}…${reviewerAddress.substring(reviewerAddress.length - 4)}';
  }

  /// Short truncated worker address.
  String get shortWorkerAddress {
    if (workerAddress.length <= 10) return workerAddress;
    return '${workerAddress.substring(0, 4)}…${workerAddress.substring(workerAddress.length - 4)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review &&
          runtimeType == other.runtimeType &&
          workerAddress == other.workerAddress &&
          reviewerAddress == other.reviewerAddress &&
          jobId == other.jobId &&
          rating == other.rating &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      workerAddress.hashCode ^
      reviewerAddress.hashCode ^
      jobId.hashCode ^
      rating.hashCode ^
      timestamp.hashCode;
}
