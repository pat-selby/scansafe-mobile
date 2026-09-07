/// A single fired rule, carrying both display layers.
///
/// Layer 5 of the architecture renders [plain] always and reveals [technical]
/// behind a "See details" toggle. Keeping both on one object means a finding
/// can never lose half of its explanation as it moves through the app.
class Finding {
  const Finding({
    required this.ruleId,
    required this.plain,
    required this.technical,
    required this.points,
  });

  /// Rule number from the architecture doc (1-22). Rule 19b is reported as 19.
  final int ruleId;

  /// Plain-English explanation, always visible.
  final String plain;

  /// Technical detail for security professionals, shown on demand.
  final String technical;

  /// Weight this rule contributed to the total score.
  final int points;
}
