/// Verdict levels for a scored URL.
///
/// Thresholds are carried over unchanged from the Python prototype
/// (`scansafe_prototype.py`, `RiskLevel.from_score`) so that the Dart engine
/// and the research prototype agree on every verdict:
/// 0-2 = safe, 3-5 = suspicious, 6+ = high risk.
enum RiskLevel {
  safe('SAFE'),
  suspicious('SUSPICIOUS'),
  highRisk('HIGH RISK');

  const RiskLevel(this.label);

  /// Display string, identical to the Python prototype's level strings.
  final String label;

  static RiskLevel fromScore(int score) {
    if (score <= 2) return RiskLevel.safe;
    if (score <= 5) return RiskLevel.suspicious;
    return RiskLevel.highRisk;
  }
}
