import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scansafe/core/url_scorer.dart';
import 'package:scansafe/data/scan_history_store.dart';
import 'package:scansafe/ui/screens/home_screen.dart';
import 'package:scansafe/ui/screens/result_screen.dart';
import 'package:scansafe/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility guarantees from the PRD § Non-Functional Requirements.
///
/// A security verdict that is unreadable at large text sizes, or that only
/// exists as a colour, has failed at the one job it has.
Widget _wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('text scaling', () {
    testWidgets('home screen survives 200% text scale without overflow',
        (tester) async {
      await tester.pumpWidget(
        _wrap(HomeScreen(store: ScanHistoryStore()), textScale: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Scan this link'), findsOneWidget);
    });

    testWidgets('result screen survives 200% text scale without overflow',
        (tester) async {
      final result = UrlScorer().score('http://secure-chase-login.tk/verify');
      await tester.pumpWidget(
        _wrap(ResultScreen(result: result), textScale: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HIGH RISK'), findsOneWidget);
    });

    testWidgets('a long URL does not break the result layout', (tester) async {
      final result = UrlScorer().score(
        'https://login.secure.verify.account.update.example-phishing-domain.tk'
        '/auth/session/renew?token=${'a' * 200}',
      );
      await tester.pumpWidget(_wrap(ResultScreen(result: result)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('non-visual signals', () {
    testWidgets('the verdict is announced without relying on colour',
        (tester) async {
      final handle = tester.ensureSemantics();
      final result = UrlScorer().score('https://google.com');
      await tester.pumpWidget(_wrap(ResultScreen(result: result)));

      // The verdict word and score reach a screen reader as one label.
      expect(
        find.bySemanticsLabel(RegExp(r'SAFE verdict, risk score 0')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('every verdict level carries a distinct icon', (tester) async {
      final scorer = UrlScorer();
      final safe = scorer.score('https://google.com');
      final risky = scorer.score('http://secure-chase-login.tk/verify');

      await tester.pumpWidget(_wrap(ResultScreen(result: safe)));
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);

      await tester.pumpWidget(_wrap(ResultScreen(result: risky)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.gpp_maybe_outlined), findsWidgets);
    });
  });
}
