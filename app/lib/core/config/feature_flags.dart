/// Compile-time feature switches.
class FeatureFlags {
  FeatureFlags._();

  /// Juror arbitration for disputes. Off until jurors are selected by the
  /// protocol (e.g. from real $SKR Guardian stakers) rather than by a party to
  /// the dispute. Must stay in step with `JURY_ENABLED` in the on-chain program,
  /// which refuses to open a juror case while it is false.
  ///
  /// Enable for development with `--dart-define=CLOCKIN_ENABLE_JURY=true`.
  static const bool juryArbitration = bool.fromEnvironment('CLOCKIN_ENABLE_JURY');
}
