import 'package:flutter/material.dart';

import '../core/risk_level.dart';

/// Design tokens, transcribed from the YAML block in `docs/design.md`.
///
/// This file is the only place a raw colour, size, or radius may appear. If a
/// value is needed somewhere else, add a token here rather than inlining it —
/// that rule is what keeps the verdict palette meaning exactly one thing.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color onBackground = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFF141414);
  static const Color onSurface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFF1E1E1E);
  static const Color onSurfaceVariant = Color(0xFF8A8A8A);
  static const Color outline = Color(0xFF2A2A2A);
  static const Color outlineStrong = Color(0xFF3D3D3D);

  static const Color primary = Color(0xFF2FE98A);
  static const Color onPrimary = Color(0xFF04160D);

  static const Color success = Color(0xFF2FE98A);
  static const Color successContainer = Color(0xFF0C2A1B);
  static const Color onSuccessContainer = Color(0xFF7CF3BB);

  static const Color warning = Color(0xFFFFC933);
  static const Color warningContainer = Color(0xFF2E2408);
  static const Color onWarningContainer = Color(0xFFFFDD84);

  static const Color error = Color(0xFFFF4038);
  static const Color errorContainer = Color(0xFF2E0F0D);
  static const Color onErrorContainer = Color(0xFFFF9C97);
}

/// Spacing scale — a 4px base. Screen gutters are [lg].
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. Nothing in the product is fully square — hard corners read as
/// system alerts, and system alerts read as panic.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double pill = 999;
}

/// Type scale. Prose is set in the system sans; anything the user may need to
/// inspect character by character is set in the monospace stack.
class AppType {
  const AppType._();

  /// Monospace stack. Flutter resolves the first available family, so the
  /// platform default is reached without bundling a font.
  static const List<String> monoFallback = <String>[
    'SF Mono',
    'Menlo',
    'Consolas',
    'Roboto Mono',
    'monospace',
  ];

  static const TextStyle verdict = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.34,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.26,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle labelCaps = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.44,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle monoUrl = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: monoFallback,
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle monoDetail = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: monoFallback,
    fontSize: 13,
    height: 1.55,
    color: AppColors.onSurfaceVariant,
  );
}

/// The three colours a verdict may use, plus the icon and copy that carry the
/// same meaning without relying on colour.
class VerdictStyle {
  const VerdictStyle({
    required this.foreground,
    required this.container,
    required this.icon,
    required this.headline,
    required this.advice,
  });

  final Color foreground;
  final Color container;
  final IconData icon;

  /// Sentence shown under the badge, in the product's voice.
  final String headline;

  /// Closing guidance for non-safe verdicts. Null for [RiskLevel.safe].
  final String? advice;
}

class AppTheme {
  const AppTheme._();

  /// Verdict styling. Colour is never the only signal — every entry pairs a
  /// colour with an icon and a word.
  static VerdictStyle verdictStyle(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return const VerdictStyle(
          foreground: AppColors.success,
          container: AppColors.successContainer,
          icon: Icons.check_circle_outline,
          headline: 'Nothing here matched a known phishing pattern',
          advice: null,
        );
      case RiskLevel.suspicious:
        return const VerdictStyle(
          foreground: AppColors.warning,
          container: AppColors.warningContainer,
          icon: Icons.error_outline,
          headline: 'Some warning signs worth a second look',
          advice: 'If this asks you to sign in or confirm details, go to the '
              'site directly instead of using this link.',
        );
      case RiskLevel.highRisk:
        return const VerdictStyle(
          foreground: AppColors.error,
          container: AppColors.errorContainer,
          icon: Icons.gpp_maybe_outlined,
          headline: "This link isn't going where it says",
          advice: "Don't open this link or enter any details on it. If it "
              'claims to be from your school or bank, reach them through an '
              'address you already trust.',
        );
    }
  }

  /// The app is dark-only by design — a true-black ground is honest on the
  /// OLED phones this is used on, and it makes the verdict colours read in
  /// daylight. There is no light variant.
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineStrong,
      error: AppColors.error,
      onError: AppColors.onBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: const TextTheme(
        displayLarge: AppType.verdict,
        headlineSmall: AppType.headline,
        titleMedium: AppType.title,
        bodyLarge: AppType.body,
        bodyMedium: AppType.body,
        bodySmall: AppType.bodyMuted,
        labelSmall: AppType.labelCaps,
      ).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.onBackground,
        titleTextStyle: AppType.headline.copyWith(
          color: AppColors.onBackground,
        ),
      ),
      // No shadows anywhere. On a true-black ground shadow is invisible, and
      // faking it produces muddy grey halos. Depth is surface lightness plus a
      // hairline border.
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          // Disabled must never keep the accent green — green means safe.
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.onSurfaceVariant,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppType.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppType.bodyMuted,
          minimumSize: const Size(0, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        hintStyle: AppType.body.copyWith(color: AppColors.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: AppType.body,
      ),
    );
  }
}
