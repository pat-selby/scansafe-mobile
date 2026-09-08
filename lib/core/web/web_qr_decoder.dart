import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'opencv_loader.dart';

/// Layers 2-3 on the web: the OpenCV preprocessing pipeline and QR decoding,
/// running against the OpenCV.js WASM build.
///
/// This mirrors `decode_qr_from_frame()` in `scansafe_prototype.py` stage for
/// stage. The multi-stage fallback is not defensive padding — single-stage
/// decoding measurably failed on real samples (coloured and branded codes,
/// light-on-dark codes, low-contrast frames), which is why the prototype grew
/// these stages in the first place.
///
/// Verified against the prototype on the five test images in the research
/// repo: identical results on all five, including the shared failure on
/// `qr_mal_2fa.png`. See docs/evaluation.md.
///
/// Uses `objdetect.QRCodeDetector`, never the `wechat_qrcode` contrib
/// detector — the latter runs two pretrained CNNs, which would violate the
/// "no pretrained ML in Layers 1-6" research constraint.
class WebQrDecoder {
  JSObject? _detector;

  /// Must be awaited before [decodeImageData]. Safe to call repeatedly.
  Future<void> initialise() async {
    await OpenCvLoader.load();
    _detector ??= (OpenCvLoader.cv.getProperty('QRCodeDetector'.toJS)
            as JSFunction)
        .callAsConstructor<JSObject>();
  }

  int _constant(String name) =>
      (OpenCvLoader.cv.getProperty(name.toJS) as JSNumber).toDartInt;

  JSObject _newMat() =>
      (OpenCvLoader.cv.getProperty('Mat'.toJS) as JSFunction)
          .callAsConstructor<JSObject>();

  String? _attempt(JSObject mat) {
    final result = _detector!.callMethod<JSString?>('detectAndDecode'.toJS, mat);
    final payload = result?.toDart;
    return (payload == null || payload.isEmpty) ? null : payload;
  }

  /// Decode a QR payload from one camera frame, or null if none is present.
  ///
  /// Every `Mat` is released in a finally block. OpenCV.js allocates in the
  /// WASM heap, which the JavaScript garbage collector does not manage — at
  /// several frames per second a leak here exhausts memory within a minute.
  String? decodeImageData(web.ImageData imageData) {
    final cv = OpenCvLoader.cv;
    final src = cv.callMethod<JSObject>(
      'matFromImageData'.toJS,
      imageData as JSAny,
    );

    JSObject? gray;
    JSObject? binary;
    JSObject? inverted;

    try {
      // Stage 1 — the original colour frame.
      final direct = _attempt(src);
      if (direct != null) return direct;

      // Stage 2 — greyscale.
      gray = _newMat();
      cv.callMethod<JSAny?>(
        'cvtColor'.toJS,
        src,
        gray,
        _constant('COLOR_RGBA2GRAY').toJS,
      );
      final fromGray = _attempt(gray);
      if (fromGray != null) return fromGray;

      // Stage 3 — Otsu binarisation. Handles coloured and branded codes by
      // collapsing a non-black module colour to true black.
      binary = _newMat();
      // callMethod accepts at most four arguments; threshold takes five, so
      // this one goes through the varargs form.
      cv.callMethodVarArgs<JSAny?>('threshold'.toJS, [
        gray,
        binary,
        0.toJS,
        255.toJS,
        (_constant('THRESH_BINARY') | _constant('THRESH_OTSU')).toJS,
      ]);
      final fromBinary = _attempt(binary);
      if (fromBinary != null) return fromBinary;

      // Stage 4 — inverted Otsu, for light-on-dark codes.
      inverted = _newMat();
      cv.callMethod<JSAny?>('bitwise_not'.toJS, binary, inverted);
      return _attempt(inverted);
    } finally {
      for (final mat in [src, gray, binary, inverted]) {
        mat?.callMethod<JSAny?>('delete'.toJS);
      }
    }
  }

  /// Release the detector's native memory.
  void dispose() {
    _detector?.callMethod<JSAny?>('delete'.toJS);
    _detector = null;
  }
}
