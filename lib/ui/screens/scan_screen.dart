import 'package:flutter/material.dart';

import '../../core/scanner/platform_scanner.dart';
import '../../core/scanner/scan_failure.dart';
import '../theme.dart';

/// Live QR scanning — Layers 1-3.
///
/// Pops with the decoded payload on success, or with null if the user backs
/// out. Scoring stays on the caller so this screen has exactly one job.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _Stage { preparing, scanning, failed }

class _ScanScreenState extends State<ScanScreen> {
  final PlatformScanner _scanner = PlatformScanner();

  _Stage _stage = _Stage.preparing;
  CameraFailure? _failure;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _scanner.start(onResult: _onPayload);
      if (mounted) setState(() => _stage = _Stage.scanning);
    } on CameraScanException catch (e) {
      if (mounted) {
        setState(() {
          _stage = _Stage.failed;
          _failure = e.failure;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _stage = _Stage.failed;
          _failure = CameraFailure.unknown;
        });
      }
    }
  }

  void _onPayload(String payload) {
    // The frame pump can fire again before the route finishes popping, so the
    // first result wins and the rest are ignored.
    if (_handled || !mounted) return;
    _handled = true;
    Navigator.of(context).pop(payload);
  }

  @override
  void dispose() {
    // Releases the camera. A live camera behind a dismissed screen is a
    // privacy problem no matter what the app does with the frames.
    _scanner.dispose();
    super.dispose();
  }

  /// Copy is specific per failure — the fix differs completely between a
  /// denied permission and an insecure origin, and "something went wrong"
  /// helps with neither.
  ({String title, String body}) _failureCopy(CameraFailure failure) {
    switch (failure) {
      case CameraFailure.permissionDenied:
        return (
          title: 'Camera access is blocked',
          body: 'Allow camera access for this site in your browser settings, '
              'then try again. Nothing from the camera leaves your device.',
        );
      case CameraFailure.noCamera:
        return (
          title: 'No camera available',
          body: 'This device has no camera, or another app is using it. '
              'You can still check a link by typing it.',
        );
      case CameraFailure.insecureContext:
        return (
          title: 'This page is not secure',
          body: 'Browsers only allow camera access over HTTPS. Open the app '
              'over a secure connection and try again.',
        );
      case CameraFailure.decoderUnavailable:
        return (
          title: "The scanner didn't load",
          body: 'The QR decoder failed to download. Check your connection and '
              'try again — it is about 11MB and only downloads once.',
        );
      case CameraFailure.unsupportedPlatform:
        return (
          title: 'Scanning is not available in this build',
          body: 'Camera scanning is not wired up on this platform yet. '
              'You can still check a link by typing it.',
        );
      case CameraFailure.unknown:
        return (
          title: "The camera didn't start",
          body: 'Something stopped the camera from starting. '
              'You can still check a link by typing it.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Scan a QR code')),
      body: switch (_stage) {
        _Stage.preparing => _buildPreparing(),
        _Stage.failed => _buildFailure(),
        _Stage.scanning => _buildScanning(),
      },
    );
  }

  Widget _buildPreparing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text('Starting the camera', style: AppType.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The QR decoder is about 11MB and downloads once. '
              'Your browser will ask for camera permission.',
              textAlign: TextAlign.center,
              style: AppType.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailure() {
    final copy = _failureCopy(_failure ?? CameraFailure.unknown);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 44,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(copy.title, textAlign: TextAlign.center, style: AppType.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              copy.body,
              textAlign: TextAlign.center,
              style: AppType.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Type a link instead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanning() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _scanner.buildPreview(),
        // Reticle. Deliberately a plain outline: no animated sweep line, no
        // pulsing. docs/design.md forbids motion as a risk signal, and a
        // scanner that looks like it is "analysing" implies a verdict it has
        // not reached yet.
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xxl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Text(
                    'Point at a QR code. Nothing is uploaded.',
                    textAlign: TextAlign.center,
                    style: AppType.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
