import 'package:flutter/widgets.dart';

import 'scan_failure.dart';

/// No camera implementation in this build.
///
/// Native OpenCV decoding via `dartcv4` is a later phase. The UI reads this
/// flag to hide the scan affordance entirely.
const bool scannerSupported = false;

class PlatformScanner {
  Future<void> start({required void Function(String payload) onResult}) async {
    throw const CameraScanException(CameraFailure.unsupportedPlatform);
  }

  Widget buildPreview() => const SizedBox.shrink();

  void dispose() {}
}
