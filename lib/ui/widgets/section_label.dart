import 'package:flutter/material.dart';

import '../theme.dart';

/// The uppercase, letter-spaced label that heads each card section —
/// PLAIN-ENGLISH SUMMARY, TECHNICAL DETAIL — carried over from the prototype.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text.toUpperCase(), style: AppType.labelCaps),
    );
  }
}

/// A monospace block for a URL.
///
/// Selectable so it can be copied for analysis, never tappable: the app
/// explains links, it never navigates to them. Scrolls horizontally rather
/// than wrapping, so a long URL cannot break the layout.
class UrlDisplay extends StatelessWidget {
  const UrlDisplay(this.url, {super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          url,
          maxLines: 1,
          style: AppType.monoUrl.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Standard card container: surface fill, hairline border, 18px radius.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}
