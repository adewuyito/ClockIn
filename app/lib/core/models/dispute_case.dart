enum DisputeCaseStatus {
  voting,
  quorumReached,
  executed,
}

enum DisputeVote {
  none,
  releaseToWorker,
  refundToEmployer,
  split5050;

  int get value {
    switch (this) {
      case DisputeVote.none:
        return 0;
      case DisputeVote.releaseToWorker:
        return 1;
      case DisputeVote.refundToEmployer:
        return 2;
      case DisputeVote.split5050:
        return 3;
    }
  }
}

/// Domain model representing a 3-juror Seeker Guardian arbitration panel and dispute case.
class DisputeCase {
  final String contractId;
  final String juror1;
  final String juror2;
  final String juror3;
  final int vote1;
  final int vote2;
  final int vote3;
  final int quorumOutcome;
  final DisputeCaseStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime syncedAt;

  const DisputeCase({
    required this.contractId,
    required this.juror1,
    required this.juror2,
    required this.juror3,
    this.vote1 = 0,
    this.vote2 = 0,
    this.vote3 = 0,
    this.quorumOutcome = 0,
    this.status = DisputeCaseStatus.voting,
    required this.createdAt,
    this.resolvedAt,
    required this.syncedAt,
  });

  List<String> get jurors => [juror1, juror2, juror3];
  List<int> get votes => [vote1, vote2, vote3];

  int get totalVotesCast {
    var count = 0;
    if (vote1 > 0) count++;
    if (vote2 > 0) count++;
    if (vote3 > 0) count++;
    return count;
  }

  int get votesCastCount => totalVotesCast;

  bool hasVoted(int index) => index >= 0 && index < 3 && votes[index] > 0;

  String shortJuror(int index) {
    if (index < 0 || index >= 3) return '';
    final j = jurors[index];
    if (j.length <= 8) return j;
    return '${j.substring(0, 4)}…${j.substring(j.length - 4)}';
  }

  bool isJuror(String? address) {
    if (address == null) return false;
    return juror1 == address || juror2 == address || juror3 == address;
  }

  int getJurorIndex(String? address) {
    if (address == null) return -1;
    if (juror1 == address) return 0;
    if (juror2 == address) return 1;
    if (juror3 == address) return 2;
    return -1;
  }

  bool hasJurorVoted(String? address) {
    final idx = getJurorIndex(address);
    if (idx == -1) return false;
    return votes[idx] > 0;
  }

  DisputeVote getJurorVote(String? address) {
    final idx = getJurorIndex(address);
    if (idx == -1) return DisputeVote.none;
    switch (votes[idx]) {
      case 1:
        return DisputeVote.releaseToWorker;
      case 2:
        return DisputeVote.refundToEmployer;
      case 3:
        return DisputeVote.split5050;
      default:
        return DisputeVote.none;
    }
  }

  static String voteDisplay(int vote) {
    switch (vote) {
      case 1:
        return 'Release to Worker';
      case 2:
        return 'Refund to Employer';
      case 3:
        return '50/50 Split';
      default:
        return 'Reviewing Evidence';
    }
  }

  String get outcomeDisplay {
    switch (quorumOutcome) {
      case 1:
        return 'Release to Worker';
      case 2:
        return 'Refund to Employer';
      case 3:
        return '50/50 Split';
      default:
        return 'Pending Quorum';
    }
  }

  String get statusDisplay {
    switch (status) {
      case DisputeCaseStatus.voting:
        return 'Voting in Progress';
      case DisputeCaseStatus.quorumReached:
        return 'Quorum Reached';
      case DisputeCaseStatus.executed:
        return 'Ruling Executed';
    }
  }
}
