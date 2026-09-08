import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import '../scanner/scan_failure.dart';
import 'web_qr_decoder.dart';

/// Layer 1 on the web: live camera capture feeding the OpenCV decode pipeline.
///
/// Frames are pulled from a `<video>` element into an offscreen canvas, then
/// handed to [WebQrDecoder]. Nothing is uploaded and no frame is retained —
/// each one is overwritten by the next.
class CameraScanner {
  CameraScanner({this.framesPerSecond = 5});

  /// Decode attempts per second.
  ///
  /// Five is deliberate. A full four-stage decode costs real time on a phone,
  /// and running it every frame at 30fps starves the UI thread and heats the
  /// device without finding codes meaningfully faster — a QR code stays in
  /// frame for far longer than 200ms.
  final int framesPerSecond;

  static const String viewType = 'scansafe-camera-preview';
  static bool _viewFactoryRegistered = false;

  final WebQrDecoder _decoder = WebQrDecoder();

  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  web.HTMLCanvasElement? _canvas;
  Timer? _pump;
  bool _decoding = false;
  bool _disposed = false;

  /// Start the camera and begin decoding. [onResult] fires once, on the first
  /// successful decode; the caller is expected to stop the scanner then.
  Future<void> start({required void Function(String payload) onResult}) async {
    if (_disposed) return;

    try {
      await _decoder.initialise();
    } on Object catch (e) {
      throw CameraScanException(CameraFailure.decoderUnavailable, '$e');
    }

    final mediaDevices = web.window.navigator.mediaDevices;
    // getUserMedia is undefined outside a secure context, which is the single
    // most likely reason this fails in the field.
    if (!(mediaDevices as JSObject).getProperty('getUserMedia'.toJS)
        .isDefinedAndNotNull) {
      throw const CameraScanException(CameraFailure.insecureContext);
    }

    try {
      // facingMode 'environment' asks for the rear camera — the front camera
      // cannot see a code the user is pointing the phone at.
      _stream = await mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              video: {'facingMode': 'environment'}.jsify()!,
              audio: false.toJS,
            ),
          )
          .toDart;
    } on Object catch (e) {
      throw CameraScanException(_classify('$e'), '$e');
    }

    if (_disposed) {
      _stopStream();
      return;
    }

    final video = web.document.createElement('video') as web.HTMLVideoElement
      ..autoplay = true
      // Both are required for autoplay on iOS Safari: without playsInline the
      // video is forced fullscreen, and without muted it will not start.
      ..muted = true
      ..srcObject = _stream;
    video.setAttribute('playsinline', 'true');
    video.style
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'cover';
    _video = video;

    if (!_viewFactoryRegistered) {
      ui_web.platformViewRegistry
          .registerViewFactory(viewType, (int _) => _currentVideoOrPlaceholder());
      _viewFactoryRegistered = true;
    }

    _canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;

    _pump = Timer.periodic(
      Duration(milliseconds: (1000 / framesPerSecond).round()),
      (_) => _tick(onResult),
    );
  }

  /// The factory is registered once per page but the element changes each time
  /// the scanner is opened, so it resolves the current one at build time.
  web.HTMLElement _currentVideoOrPlaceholder() =>
      _video ?? (web.document.createElement('div') as web.HTMLElement);

  CameraFailure _classify(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('notallowed') || lower.contains('permission')) {
      return CameraFailure.permissionDenied;
    }
    if (lower.contains('notfound') || lower.contains('devicesnotfound')) {
      return CameraFailure.noCamera;
    }
    if (lower.contains('notreadable') || lower.contains('trackstart')) {
      return CameraFailure.noCamera;
    }
    return CameraFailure.unknown;
  }

  void _tick(void Function(String payload) onResult) {
    // Skip rather than queue: decoding is synchronous and can outrun the
    // timer on a slow device, and a backlog of stale frames helps nobody.
    if (_decoding || _disposed) return;

    final video = _video;
    final canvas = _canvas;
    if (video == null || canvas == null) return;
    if (video.videoWidth == 0 || video.videoHeight == 0) return;

    _decoding = true;
    try {
      canvas
        ..width = video.videoWidth
        ..height = video.videoHeight;
      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (context == null) return;

      context.drawImage(video, 0, 0);
      final imageData =
          context.getImageData(0, 0, canvas.width, canvas.height);

      final payload = _decoder.decodeImageData(imageData);
      if (payload != null && !_disposed) onResult(payload);
    } finally {
      _decoding = false;
    }
  }

  void _stopStream() {
    final tracks = _stream?.getTracks().toDart;
    if (tracks != null) {
      for (final track in tracks) {
        track.stop();
      }
    }
    _stream = null;
  }

  /// Stop the camera and release the decoder. Always call this when leaving
  /// the scan screen — a live camera the user cannot see is a privacy problem
  /// regardless of what the app does with the frames.
  void dispose() {
    _disposed = true;
    _pump?.cancel();
    _pump = null;
    _stopStream();
    _video?.srcObject = null;
    _video = null;
    _canvas = null;
    _decoder.dispose();
  }
}
