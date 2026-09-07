import 'package:flutter/material.dart';

import '../../core/risk_level.dart';
import '../theme.dart';

/// The verdict badge — the loudest element on any result screen, and the only
/// place [AppType.verdict] is used.
///
/// One widget parameterised by level rather than three implementations, so the
/// three verdicts can never drift apart in layout or behaviour.
///
/// The icon and the verdict word carry the meaning alongside the colour, so a
/// result stays readable in greyscale and for colour-blind users. That is a
/// hard rule from `docs/design.md` — colour is never the only signal.
class VerdictBadge extends StatelessWidget {
  const VerdictBadge({
    super.key,
    required this.level,
    required this.score,
  });

  final RiskLevel level;
  final int score;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.verdictStyle(level);
    return Semantics(
      label: '${level.label} verdict, risk score $score',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: style.container,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(style.icon, size: 32, color: style.foreground),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                level.label,
                style: AppType.verdict.copyWith(color: style.foreground),
              ),
            ),
            Text(
              'score $score',
              style: AppType.bodyMuted.copyWith(
                color: style.foreground.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill form of the verdict, used in scan history rows.
///
/// The pill radius distinguishes a summary badge from a tappable card — see
/// `docs/design.md` § Shapes.
class VerdictPill extends StatelessWidget {
  const VerdictPill({
    super.key,
    required this.level,
    required this.score,
  });

  final RiskLevel level;
  final int score;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.verdictStyle(level);
    return Semantics(
      label: '${level.label}, score $score',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: style.container,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 14, color: style.foreground),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${level.label} · $score',
              style: AppType.labelCaps.copyWith(color: style.foreground),
            ),
          ],
        ),
      ),
    );
  }
}
