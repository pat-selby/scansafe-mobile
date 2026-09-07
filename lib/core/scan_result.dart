import 'finding.dart';
import 'risk_level.dart';

/// The outcome of scoring one URL.
class ScanResult {
  ScanResult({
    required this.url,
    required this.score,
    required this.level,
    required this.findings,
    required this.scannedAt,
  });

  final String url;
  final int score;
  final RiskLevel level;
  final List<Finding> findings;
  final DateTime scannedAt;

  /// True when no rule fired, so the UI can show the clean-verdict copy
  /// instead of an empty findings list.
  bool get isClean => findings.isEmpty;

  Map<String, dynamic> toJson() => {
        'url': url,
        'score': score,
        'level': level.label,
        'scannedAt': scannedAt.toIso8601String(),
        'findings': findings
            .map((f) => {
                  'ruleId': f.ruleId,
                  'plain': f.plain,
                  'technical': f.technical,
                  'points': f.points,
                })
            .toList(),
      };

  static ScanResult fromJson(Map<String, dynamic> json) => ScanResult(
        url: json['url'] as String,
        score: json['score'] as int,
        level: RiskLevel.values.firstWhere(
          (l) => l.label == json['level'],
          orElse: () => RiskLevel.suspicious,
        ),
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        findings: (json['findings'] as List<dynamic>)
            .map((f) => Finding(
                  ruleId: f['ruleId'] as int,
                  plain: f['plain'] as String,
                  technical: f['technical'] as String,
                  points: f['points'] as int,
                ))
            .toList(),
      );
}
