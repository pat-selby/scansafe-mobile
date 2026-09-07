import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/risk_level.dart';
import '../../core/scan_result.dart';
import '../theme.dart';
import '../widgets/finding_tile.dart';
import '../widgets/section_label.dart';
import '../widgets/verdict_badge.dart';

/// Layer 5 — the verdict and its reasoning.
///
/// There is deliberately no "open link" affordance anywhere on this screen,
/// and the app does not depend on `url_launcher` at all. ScanSafe explains
/// links; it never becomes the thing that navigates someone to a phishing page.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result});

  final ScanResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _announceVerdict();
  }

  /// A short haptic on arrival, heavier for a verdict that needs attention.
  /// Never a repeating or escalating pattern — alarm is not a security control.
  void _announceVerdict() {
    switch (widget.result.level) {
      case RiskLevel.safe:
        HapticFeedback.lightImpact();
      case RiskLevel.suspicious:
        HapticFeedback.mediumImpact();
      case RiskLevel.highRisk:
        HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final style = AppTheme.verdictStyle(result.level);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan result')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          VerdictBadge(level: result.level, score: result.score),
          const SizedBox(height: AppSpacing.lg),
          Text(style.headline, style: AppType.headline),
          const SizedBox(height: AppSpacing.xl),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Link scanned'),
                const SizedBox(height: AppSpacing.md),
                UrlDisplay(result.url),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (result.isClean)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Plain-English summary'),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'All 22 rules passed. Nothing in this link matched a known '
                    'phishing pattern.',
                    style: AppType.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Stating the limit of the check is part of the voice: a
                  // SAFE verdict should not be over-trusted.
                  Text(
                    'That checks the link itself, not the page it leads to. A '
                    'brand-new phishing site can still look clean here.',
                    style: AppType.bodyMuted,
                  ),
                ],
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(
                    '${result.findings.length} '
                    '${result.findings.length == 1 ? 'finding' : 'findings'}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (var i = 0; i < result.findings.length; i++)
                    FindingTile(
                      finding: result.findings[i],
                      isLast: i == result.findings.length - 1,
                    ),
                ],
              ),
            ),

          if (style.advice != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: style.container,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.icon, size: 20, color: style.foreground),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      style.advice!,
                      // Body copy is never set in a verdict colour — the
                      // heading carries the alarm, the prose carries the
                      // explanation.
                      style: AppType.body.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
