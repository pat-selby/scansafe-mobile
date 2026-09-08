/// Resolves to the web camera scanner when compiling for the web, and to a
/// stub everywhere else.
///
/// Native platforms will get a `dartcv4` implementation in a later phase (see
/// docs/product-roadmap.md). Until then the scan button is hidden rather than
/// shown broken — offering a control that cannot work is worse than not
/// offering it.
library;

export 'platform_scanner_stub.dart'
    if (dart.library.js_interop) 'platform_scanner_web.dart';
