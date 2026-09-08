import 'package:flutter/material.dart';

import '../../core/payload_kind.dart';
import '../../core/scanner/platform_scanner.dart';
import '../../core/url_scorer.dart';
import '../../data/scan_history_store.dart';
import '../theme.dart';
import '../widgets/dashed_button.dart';
import '../widgets/section_label.dart';
import 'history_screen.dart';
import 'result_screen.dart';
import 'scan_screen.dart';

/// Entry point for a scan.
///
/// Camera scanning is the primary path; typing a link is the fallback. The
/// scan button is only enabled where a decoder exists (`scannerSupported`) —
/// on the web that is the OpenCV.js WASM build. On platforms without one it
/// stays visibly disabled rather than hidden, so the app's shape matches the
/// architecture and nobody wonders whether the feature exists.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final ScanHistoryStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  /// One scorer for the whole app session, so Rule 20 (SimHash near-duplicate)
  /// can see URLs scanned earlier in this session — matching the prototype's
  /// session-scoped cache.
  final UrlScorer _scorer = UrlScorer();

  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Type or paste a link to check.');
      return;
    }
    setState(() => _error = null);
    await _scoreAndShow(input);
  }

  /// Open the camera, and score whatever it decodes.
  ///
  /// The scan screen only returns a payload; scoring stays here so a typed
  /// link and a scanned one take exactly the same path, including history.
  Future<void> _scanQr() async {
    final payload = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (payload == null || !mounted) return;

    // A QR code is not necessarily a link. Scoring a Wi-Fi join or a contact
    // card as a URL would produce a confident, meaningless verdict.
    if (!looksLikeUrl(payload)) {
      await _showNotALink(payload);
      return;
    }
    await _scoreAndShow(payload);
  }

  Future<void> _showNotALink(String payload) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("That code wasn't a link"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'It contained ${describePayload(payload)}, so there is no link '
              'to check. ScanSafe only rates links.',
              style: AppType.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                payload.length > 200 ? '${payload.substring(0, 200)}...' : payload,
                style: AppType.monoDetail,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _scoreAndShow(String input) async {
    final result = _scorer.score(input);
    await widget.store.add(result);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryScreen(store: widget.store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanSafe'),
        actions: [
          IconButton(
            tooltip: 'Scan history',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text('Check a link before you open it', style: AppType.headline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ScanSafe scores the link against 22 phishing rules on your phone. '
            'Nothing is sent anywhere.',
            style: AppType.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.xl),

          TextField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _scan(),
            style: AppType.body,
            decoration: InputDecoration(
              hintText: 'example.com/login',
              errorText: _error,
              prefixIcon: const Icon(
                Icons.link,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          FilledButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Scan this link'),
          ),
          const SizedBox(height: AppSpacing.md),

          DashedButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan a QR code',
            onPressed: scannerSupported ? _scanQr : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            scannerSupported
                ? 'Decoded on your device with OpenCV. Nothing is uploaded.'
                : 'Camera scanning is not wired up on this platform yet.',
            textAlign: TextAlign.center,
            style: AppType.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.xl),

          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('On-device only'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Scoring runs entirely offline. Your scan history stays '
                        'on this device and is never uploaded.',
                        style: AppType.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
