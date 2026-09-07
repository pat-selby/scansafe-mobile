/// Layers 1-3 of the architecture: camera capture, the OpenCV preprocessing
/// pipeline, and QR decoding.
///
/// This is the seam, not the implementation. Layers 4-6 are pure Dart and run
/// everywhere today; decoding needs OpenCV bound to each platform, which is
/// the next build phase (see docs/product-roadmap.md, Phase 3).
///
/// The interface exists now so the scan flow, the result screen, and history
/// can be built and tested against a fake decoder without waiting on the
/// native integration — and so the eventual OpenCV implementation drops in
/// without touching the UI.
abstract class QrDecoder {
  /// Decode the QR payload from a single camera frame or still image.
  ///
  /// [imageBytes] is raw encoded image data (PNG/JPEG). Returns the decoded
  /// payload, or null when no QR code is present in the frame.
  ///
  /// The production implementation must mirror the prototype's multi-stage
  /// fallback, which exists because single-stage decoding failed on real
  /// samples: original frame, then greyscale, then Otsu binarisation for
  /// coloured/branded codes, then inverted Otsu for light-on-dark codes.
  Future<String?> decode(List<int> imageBytes);
}

/// A decoder that returns a scripted payload. Used by tests and by the
/// manual-entry flow, so the app is exercisable before OpenCV is wired up.
class StubQrDecoder implements QrDecoder {
  StubQrDecoder([this.payload]);

  final String? payload;

  @override
  Future<String?> decode(List<int> imageBytes) async => payload;
}
