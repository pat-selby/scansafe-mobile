import 'package:flutter/widgets.dart';

import '../web/camera_scanner.dart';

/// The web build decodes QR codes with the OpenCV.js WASM build.
const bool scannerSupported = true;

class PlatformScanner {
  final CameraScanner _scanner = CameraScanner();

  Future<void> start({required void Function(String payload) onResult}) =>
      _scanner.start(onResult: onResult);

  /// The live camera preview.
  ///
  /// `HtmlElementView` hands the `<video>` element straight to the browser
  /// compositor. Copying frames into a Flutter texture would cost a full
  /// image copy per frame for no visual gain.
  Widget buildPreview() =>
      const HtmlElementView(viewType: CameraScanner.viewType);

  void dispose() => _scanner.dispose();
}
