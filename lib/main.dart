import 'package:flutter/material.dart';

import 'data/scan_history_store.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const ScanSafeApp());
}

/// ScanSafe — on-device QR phishing detection.
///
/// Layers 4-6 (risk scoring, verdict display, local history) are implemented.
/// Layers 1-3 (camera, OpenCV pipeline, QR decode) land in Phase 2 behind the
/// `QrDecoder` interface. Layer 7 (agentic investigation) is out of scope for
/// this release by design — see docs/product-vision.md.
class ScanSafeApp extends StatelessWidget {
  const ScanSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanSafe',
      debugShowCheckedModeBanner: false,
      // Dark only. The design system commits to a true-black ground; there is
      // no light variant to fall back to.
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: HomeScreen(store: ScanHistoryStore()),
    );
  }
}
