import 'dart:convert';

/// A deliverable item attached to a verified ClockIn review on Arweave.
class ReviewDeliverable {
  final String title;
  final String uri;
  final String? hash;

  const ReviewDeliverable({
    required this.title,
    required this.uri,
    this.hash,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'uri': uri,
        if (hash != null) 'hash': hash,
      };

  factory ReviewDeliverable.fromJson(Map<String, dynamic> json) {
    return ReviewDeliverable(
      title: json['title'] as String? ?? 'Deliverable',
      uri: json['uri'] as String? ?? '',
      hash: json['hash'] as String?,
    );
  }
}

/// Canonical metadata payload for a ClockIn review inscribed immutably
/// onto the Arweave permaweb via Irys.
class ClockInReviewMetadata {
  static const String currentProtocol = 'ClockIn';
  static const String currentVersion = '1.0.0';

  final String protocol;
  final String version;
  final String jobId;
  final String? contractId;
  final String worker;
  final String reviewer;
  final int rating;
  final Map<String, int> categoryRatings;
  final String reviewNote;
  final List<ReviewDeliverable> deliverables;
  final int timestamp;
  final bool escrowSettled;
  final String? clientSignature;

  const ClockInReviewMetadata({
    this.protocol = currentProtocol,
    this.version = currentVersion,
    required this.jobId,
    this.contractId,
    required this.worker,
    required this.reviewer,
    required this.rating,
    this.categoryRatings = const {},
    required this.reviewNote,
    this.deliverables = const [],
    required this.timestamp,
    this.escrowSettled = false,
    this.clientSignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'version': version,
      'jobId': jobId,
      if (contractId != null) 'contractId': contractId,
      'worker': worker,
      'reviewer': reviewer,
      'rating': rating,
      if (categoryRatings.isNotEmpty) 'categoryRatings': categoryRatings,
      'reviewNote': reviewNote,
      if (deliverables.isNotEmpty)
        'deliverables': deliverables.map((d) => d.toJson()).toList(),
      'timestamp': timestamp,
      'escrowSettled': escrowSettled,
      if (clientSignature != null) 'clientSignature': clientSignature,
    };
  }

  factory ClockInReviewMetadata.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categoryRatings'] as Map<String, dynamic>? ?? {};
    final cats = rawCats.map((k, v) => MapEntry(k, (v as num).toInt()));

    final rawDelivs = json['deliverables'] as List<dynamic>? ?? [];
    final delivs = rawDelivs
        .map((e) => ReviewDeliverable.fromJson(e as Map<String, dynamic>))
        .toList();

    return ClockInReviewMetadata(
      protocol: json['protocol'] as String? ?? currentProtocol,
      version: json['version'] as String? ?? currentVersion,
      jobId: json['jobId'] as String? ?? '',
      contractId: json['contractId'] as String?,
      worker: json['worker'] as String? ?? '',
      reviewer: json['reviewer'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      categoryRatings: cats,
      reviewNote: json['reviewNote'] as String? ?? '',
      deliverables: delivs,
      timestamp: (json['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      escrowSettled: json['escrowSettled'] as bool? ?? false,
      clientSignature: json['clientSignature'] as String?,
    );
  }

  /// Returns sorted canonical JSON string for hashing / signing.
  String toCanonicalJson() {
    final map = toJson();
    final sortedKeys = map.keys.toList()..sort();
    final sortedMap = <String, dynamic>{};
    for (final key in sortedKeys) {
      sortedMap[key] = map[key];
    }
    return jsonEncode(sortedMap);
  }
}
