import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Loads the bundled OpenCV.js WASM build on demand.
///
/// The build is ~11MB, so it is deliberately *not* loaded at startup — the app
/// shell stays fast and only pays for OpenCV when someone actually opens the
/// scanner. Loading is idempotent: concurrent callers share one future.
///
/// The script is served from the app's own origin (`web/opencv.js`), never a
/// CDN. Fetching it from a third party would mean the browser announcing to
/// someone else that a scan is starting, which contradicts the product's
/// central promise that nothing leaves the device.
class OpenCvLoader {
  static Future<void>? _loading;

  /// True once `cv` is initialised and usable.
  static bool get isReady {
    final cv = globalContext.getProperty('cv'.toJS);
    return cv.isDefinedAndNotNull &&
        (cv as JSObject).getProperty('Mat'.toJS).isDefinedAndNotNull;
  }

  /// The initialised `cv` namespace. Only valid after [load] completes.
  static JSObject get cv => globalContext.getProperty('cv'.toJS) as JSObject;

  /// Inject the script tag (once) and resolve when the WASM runtime is up.
  static Future<void> load() {
    return _loading ??= _load().catchError((Object error) {
      // Let a failed load be retried rather than caching the failure forever —
      // this is usually a transient network problem on campus Wi-Fi.
      _loading = null;
      throw error;
    });
  }

  static Future<void> _load() async {
    if (isReady) return;

    if (web.document.querySelector('script[data-opencv]') == null) {
      final script = web.document.createElement('script') as web.HTMLScriptElement
        ..src = 'opencv.js'
        ..async = true;
      script.setAttribute('data-opencv', 'true');
      web.document.head!.appendChild(script);
    }

    // OpenCV.js signals readiness differently across builds — some expose a
    // promise, some an `onRuntimeInitialized` hook, some are ready on load.
    // Polling for `cv.Mat` covers every variant without guessing which one
    // this build is.
    const timeout = Duration(seconds: 60);
    const interval = Duration(milliseconds: 50);
    final deadline = DateTime.now().add(timeout);

    while (!isReady) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          'OpenCV.js did not finish loading within ${timeout.inSeconds}s.',
        );
      }
      await Future<void>.delayed(interval);
    }
  }
}
