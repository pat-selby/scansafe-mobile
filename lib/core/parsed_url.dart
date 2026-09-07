/// A minimal, faithful reimplementation of Python's `urllib.parse.urlparse`.
///
/// Dart's built-in [Uri] normalises aggressively — it lowercases the host,
/// strips the port out of the authority, re-encodes path characters, and
/// throws on inputs Python happily accepts. Any of those differences would
/// silently change a rule's outcome and break parity with the research
/// prototype, so the engine parses with these rules instead.
///
/// Splitting follows the same order Python uses: fragment, scheme, netloc,
/// query, path.
class ParsedUrl {
  const ParsedUrl({
    required this.scheme,
    required this.netloc,
    required this.path,
    required this.query,
    required this.fragment,
  });

  /// Lowercased scheme without the trailing colon, or '' when absent.
  final String scheme;

  /// Authority as Python reports it: `user:pass@host:port`, including the
  /// port. Rules 2, 5, 10 and 15 depend on this exact shape.
  final String netloc;

  final String path;
  final String query;
  final String fragment;

  static final RegExp _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*$');

  static ParsedUrl parse(String url) {
    var rest = url;
    var fragment = '';
    var scheme = '';
    var netloc = '';
    var query = '';

    final hashIndex = rest.indexOf('#');
    if (hashIndex >= 0) {
      fragment = rest.substring(hashIndex + 1);
      rest = rest.substring(0, hashIndex);
    }

    // A scheme only counts when the colon precedes the first slash, matching
    // Python — otherwise `example.com/a:b` would parse `example.com/a` as one.
    final colonIndex = rest.indexOf(':');
    if (colonIndex > 0) {
      final candidate = rest.substring(0, colonIndex);
      final slashIndex = rest.indexOf('/');
      final colonBeforeSlash = slashIndex < 0 || colonIndex < slashIndex;
      if (colonBeforeSlash && _schemePattern.hasMatch(candidate)) {
        scheme = candidate.toLowerCase();
        rest = rest.substring(colonIndex + 1);
      }
    }

    if (rest.startsWith('//')) {
      rest = rest.substring(2);
      var end = rest.length;
      for (final delimiter in ['/', '?']) {
        final index = rest.indexOf(delimiter);
        if (index >= 0 && index < end) end = index;
      }
      netloc = rest.substring(0, end);
      rest = rest.substring(end);
    }

    final questionIndex = rest.indexOf('?');
    if (questionIndex >= 0) {
      query = rest.substring(questionIndex + 1);
      rest = rest.substring(0, questionIndex);
    }

    return ParsedUrl(
      scheme: scheme,
      netloc: netloc,
      path: rest,
      query: query,
      fragment: fragment,
    );
  }

  /// Values for [key] in the query string, percent-decoded, mirroring
  /// `parse_qs` closely enough for Rule 13's `url=` extraction.
  List<String> queryValues(String key) {
    final values = <String>[];
    for (final pair in query.split('&')) {
      if (pair.isEmpty) continue;
      final eq = pair.indexOf('=');
      if (eq < 0) continue;
      if (pair.substring(0, eq) != key) continue;
      final raw = pair.substring(eq + 1);
      if (raw.isEmpty) continue;
      values.add(_unquote(raw));
    }
    return values;
  }

  /// Percent-decode, treating '+' as a literal (Python's `unquote`, not
  /// `unquote_plus`). Malformed escapes are left as-is rather than throwing.
  static String _unquote(String input) {
    try {
      return Uri.decodeComponent(input);
    } on ArgumentError {
      return input;
    } on FormatException {
      return input;
    }
  }
}
