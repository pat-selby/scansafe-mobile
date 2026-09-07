import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scansafe/core/scan_result.dart';
import 'package:scansafe/core/url_scorer.dart';
import 'package:scansafe/data/scan_history_store.dart';
import 'package:scansafe/ui/screens/history_screen.dart';
import 'package:scansafe/ui/screens/home_screen.dart';
import 'package:scansafe/ui/screens/result_screen.dart';
import 'package:scansafe/ui/theme.dart';
import 'package:scansafe/ui/widgets/dashed_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      home: child,
    );

/// Render into a surface tall enough that a lazy ListView builds every child,
/// so an assertion about something below the fold means what it says.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('scan flow', () {
    testWidgets('a risky link produces a verdict with its findings',
        (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(store: ScanHistoryStore())));

      await tester.enterText(
        find.byType(TextField),
        'http://secure-chase-login.tk/account/verify',
      );
      await tester.tap(find.text('Scan this link'));
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
      // The plain-English layer must name the pattern actually detected,
      // not issue a generic warning.
      expect(find.textContaining('.tk'), findsWidgets);
    });

    testWidgets('an empty link is rejected without navigating', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(store: ScanHistoryStore())));

      await tester.tap(find.text('Scan this link'));
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsNothing);
      expect(find.text('Type or paste a link to check.'), findsOneWidget);
    });

    testWidgets('QR scanning is visible but not yet enabled', (tester) async {
      await tester.pumpWidget(_wrap(HomeScreen(store: ScanHistoryStore())));

      final button = tester.widget<DashedButton>(find.byType(DashedButton));
      expect(button.onPressed, isNull);
      expect(find.text('Scan a QR code'), findsOneWidget);
    });

    testWidgets('a scan is written to history', (tester) async {
      final store = ScanHistoryStore();
      await tester.pumpWidget(_wrap(HomeScreen(store: store)));

      await tester.enterText(find.byType(TextField), 'https://paypa1.com');
      await tester.tap(find.text('Scan this link'));
      await tester.pumpAndSettle();

      expect((await store.load()).single.url, 'https://paypa1.com');
    });
  });

  group('result screen', () {
    testWidgets('technical detail stays hidden until asked for',
        (tester) async {
      final result = UrlScorer().score('http://example.com');
      await tester.pumpWidget(_wrap(ResultScreen(result: result)));

      expect(find.textContaining('Rule 1:'), findsNothing);

      await tester.tap(find.text('See details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rule 1:'), findsOneWidget);
      expect(find.text('Hide details'), findsOneWidget);
    });

    testWidgets('a clean link states the limits of the check', (tester) async {
      final result = UrlScorer().score('https://google.com');
      await tester.pumpWidget(_wrap(ResultScreen(result: result)));

      expect(find.text('SAFE'), findsOneWidget);
      expect(find.textContaining('All 22 rules passed'), findsOneWidget);
      expect(
        find.textContaining('not the page it leads to'),
        findsOneWidget,
      );
    });

    testWidgets('a high-risk verdict carries closing advice', (tester) async {
      // The advice card sits below the findings in a lazy ListView. A tall
      // surface builds the whole tree, which is more reliable here than
      // scrolling — the screen contains more than one Scrollable.
      _useTallSurface(tester);

      final result = UrlScorer().score('http://secure-chase-login.tk/verify');
      await tester.pumpWidget(_wrap(ResultScreen(result: result)));

      expect(find.textContaining("Don't open this link"), findsOneWidget);
    });

    testWidgets('a safe verdict carries no advice card', (tester) async {
      _useTallSurface(tester);

      final result = UrlScorer().score('https://google.com');
      await tester.pumpWidget(_wrap(ResultScreen(result: result)));

      expect(find.textContaining("Don't open this link"), findsNothing);
      expect(find.textContaining('go to the site directly'), findsNothing);
    });
  });

  group('history screen', () {
    testWidgets('empty state states that history is device-only',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryScreen(store: ScanHistoryStore())));
      await tester.pumpAndSettle();

      expect(find.text('No scans yet'), findsOneWidget);
      expect(find.textContaining('never uploaded'), findsOneWidget);
    });

    testWidgets('lists past scans newest first', (tester) async {
      final store = ScanHistoryStore();
      final scorer = UrlScorer();
      await store.add(scorer.score('https://first.example.com'));
      await store.add(scorer.score('https://second.example.com'));

      await tester.pumpWidget(_wrap(HistoryScreen(store: store)));
      await tester.pumpAndSettle();

      final urls = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s.contains('example.com'))
          .toList();
      expect(urls.first, contains('second'));
    });
  });

  group('scan history store', () {
    test('keeps newest first and caps at 50 entries', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ScanHistoryStore();
      final scorer = UrlScorer();

      for (var i = 0; i < 55; i++) {
        await store.add(scorer.score('https://example.com/page$i'));
      }

      final history = await store.load();
      expect(history.length, ScanHistoryStore.maxEntries);
      expect(history.first.url, 'https://example.com/page54');
    });

    test('round-trips a result through storage without losing findings',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = ScanHistoryStore();
      final original = UrlScorer().score('http://192.168.1.1/login');

      await store.add(original);
      final restored = (await store.load()).single;

      expect(restored.score, original.score);
      expect(restored.level, original.level);
      expect(restored.findings.length, original.findings.length);
      expect(
        restored.findings.first.technical,
        original.findings.first.technical,
      );
    });

    test('removing an entry persists', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ScanHistoryStore();
      final scorer = UrlScorer();
      await store.add(scorer.score('https://a.example.com'));
      await store.add(scorer.score('https://b.example.com'));

      final after = await store.removeAt(0);
      expect(after.length, 1);
      expect((await store.load()).single.url, 'https://a.example.com');
    });

    test('survives a corrupt stored blob', () async {
      SharedPreferences.setMockInitialValues({
        ScanHistoryStore.storageKey: 'not json at all',
      });
      expect(await ScanHistoryStore().load(), isEmpty);
    });
  });

  group('ScanResult serialisation', () {
    test('is stable across encode and decode', () {
      final result = UrlScorer().score('https://paypa1.com/verify');
      final restored = ScanResult.fromJson(result.toJson());
      expect(restored.score, result.score);
      expect(restored.level, result.level);
      expect(
        restored.findings.map((f) => f.ruleId),
        result.findings.map((f) => f.ruleId),
      );
    });
  });
}
