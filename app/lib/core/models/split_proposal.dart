/// An open offer by one party to settle a disputed contract 50/50.
///
/// On-chain a 50/50 split takes money from both sides, so it needs both: one
/// party proposes, and the split executes only when the *other* party accepts.
/// At most one proposal exists per contract.
class SplitProposal {
  final String escrowContract;
  final String proposer;
  final DateTime createdAt;

  const SplitProposal({
    required this.escrowContract,
    required this.proposer,
    required this.createdAt,
  });

  bool isProposedBy(String? address) => address != null && address == proposer;
}
