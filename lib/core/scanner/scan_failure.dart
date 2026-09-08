/// Why a camera scan could not start.
///
/// Platform-neutral so both the web scanner and the future native scanner
/// report failures the UI already knows how to explain. Each case maps to copy
/// the user can act on — "something went wrong" is useless when the fix is a
/// permissions toggle.
enum CameraFailure {
  /// The user declined, or the browser has a standing block for this origin.
  permissionDenied,

  /// No camera on the device, or it is claimed by another app.
  noCamera,

  /// The camera API is unavailable — on the web this is almost always plain
  /// HTTP, since browsers only expose the camera in a secure context.
  insecureContext,

  /// The QR decoder failed to load or initialise.
  decoderUnavailable,

  /// This build has no camera implementation.
  unsupportedPlatform,

  unknown,
}

class CameraScanException implements Exception {
  const CameraScanException(this.failure, [this.detail]);

  final CameraFailure failure;
  final String? detail;

  @override
  String toString() => 'CameraScanException($failure, $detail)';
}
