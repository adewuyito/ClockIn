import 'dart:async';
import 'dart:io';

/// Broad category of a failure from a [ReputationService] write call — lets
/// the UI show something more useful than a raw exception string, and
/// distinguishes "your connection dropped" from "the program said no" from
/// "you (or your wallet) said no". See ROADMAP.md Phase 5, which asked for
/// exactly this distinction.
enum ReputationErrorKind {
  /// RPC/network layer failed before or during submission — no on-chain
  /// outcome either way. Worth letting the user retry.
  network,

  /// The wallet app declined to sign, or the app couldn't reach it (session
  /// not connected, user rejected the prompt, wrong network selected).
  walletRejected,

  /// The transaction landed and the Anchor program itself rejected it — see
  /// [ReputationException.programError] for which rule it hit. Retrying the
  /// same call will fail the same way until the underlying state changes.
  programRejected,

  /// Doesn't match a recognized pattern; treat like a generic failure.
  unknown,
}

/// One of the seven `#[error_code]` variants in
/// `program/programs/reputation/src/lib.rs`'s `ReputationError` enum.
///
/// Anchor assigns custom error codes positionally starting at 6000, so
/// [code] below must stay in the same order as the Rust enum — there's no
/// way to fetch this mapping from the chain itself; if the program's error
/// enum changes, update this one too.
enum ProgramErrorCode {
  alreadyRegistered(6000, 'This address is already registered.'),
  notRegistered(6001, "This worker hasn't registered on-chain yet."),
  invalidRating(6002, 'Rating must be between 1 and 5.'),
  duplicateReview(6003, 'A review for this job has already been submitted.'),
  selfReview(6004, "You can't review your own connected address."),
  jobIdTooLong(6005, 'Job reference is too long.'),
  overflow(6006, 'Arithmetic overflow on-chain — this should not happen in practice.');

  const ProgramErrorCode(this.code, this.friendlyMessage);

  final int code;
  final String friendlyMessage;

  static ProgramErrorCode? fromCode(int code) {
    for (final value in ProgramErrorCode.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Typed failure from a [ReputationService] write call. Callers should
/// catch/inspect this rather than stringifying a bare exception — the
/// [kind] says whether retrying makes sense at all (network — maybe;
/// walletRejected — only if the user wants to try again; programRejected —
/// never, the same call will fail again until on-chain state changes).
class ReputationException implements Exception {
  const ReputationException({
    required this.kind,
    required this.message,
    required this.cause,
    this.programError,
  });

  final ReputationErrorKind kind;
  final String message;
  final ProgramErrorCode? programError;
  final Object cause;

  /// Classifies a caught error into a [ReputationException]. Idempotent —
  /// passing an existing [ReputationException] back through returns it
  /// unchanged, so this is safe to call from multiple catch sites without
  /// double-wrapping.
  factory ReputationException.from(Object error) {
    if (error is ReputationException) return error;

    final programCode = _extractCustomErrorCode(error);
    if (programCode != null) {
      final known = ProgramErrorCode.fromCode(programCode);
      return ReputationException(
        kind: ReputationErrorKind.programRejected,
        message: known?.friendlyMessage ?? 'The program rejected this transaction (error $programCode).',
        programError: known,
        cause: error,
      );
    }

    final text = error.toString();

    if (error is SocketException ||
        error is TimeoutException ||
        text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('Connection closed') ||
        text.contains('Connection reset')) {
      return ReputationException(
        kind: ReputationErrorKind.network,
        message: "Couldn't reach Solana Devnet. Check your connection and try again.",
        cause: error,
      );
    }

    if (text.contains('rejected by wallet') ||
        text.contains('declined') ||
        text.contains('not connected')) {
      return ReputationException(
        kind: ReputationErrorKind.walletRejected,
        message: "Your wallet didn't approve this. Make sure it's connected and set to Devnet, then try again.",
        cause: error,
      );
    }

    return ReputationException(
      kind: ReputationErrorKind.unknown,
      message: 'Something went wrong: $text',
      cause: error,
    );
  }

  /// Looks for Anchor's `{InstructionError: [index, {Custom: N}]}` shape,
  /// which is what `waitForSignatureStatus` throws (as a Dart Map's default
  /// `toString()`, not JSON) when a transaction lands but the program
  /// itself rejects it.
  static int? _extractCustomErrorCode(Object error) {
    final match = RegExp(r'Custom:\s*(\d+)').firstMatch(error.toString());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  @override
  String toString() => 'ReputationException($kind): $message';
}
