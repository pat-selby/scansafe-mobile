/// Not every QR code contains a link.
///
/// Wi-Fi joins (`WIFI:S:...`), contact cards (`BEGIN:VCARD`), `mailto:`,
/// `tel:`, `geo:` and plain text are all common. Feeding those to the URL
/// scorer produces a confident, meaningless verdict — the engine would
/// prepend `https://` and score the result — which is worse than saying
/// plainly that the code was not a link.
library;

final RegExp _anyScheme = RegExp(r'^[a-z][a-z0-9+.\-]*:');

/// Bare host with at least one dot, optionally followed by a delimiter.
final RegExp _bareDomain = RegExp(
  r'^[a-z0-9]([a-z0-9\-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]*[a-z0-9])?)+([/?#:]|$)',
);

/// Schemes that must reach the scorer even though they are not ordinary links.
///
/// Rule 14 exists specifically to flag these — a `blob:` URL in a QR code was
/// a real GSU attack — so they are routed into scoring, not filtered out.
const Set<String> _scoredSchemes = {
  'http', 'https', 'blob', 'data', 'javascript', 'vbscript',
};

/// Whether [payload] should be handed to the URL risk engine.
bool looksLikeUrl(String payload) {
  final trimmed = payload.trim().toLowerCase();
  if (trimmed.isEmpty) return false;

  final match = _anyScheme.firstMatch(trimmed);
  if (match != null) {
    final scheme = match.group(0)!.substring(0, match.group(0)!.length - 1);
    return _scoredSchemes.contains(scheme);
  }

  return _bareDomain.hasMatch(trimmed);
}

/// A short, human description of a non-link payload, for the "this wasn't a
/// link" message. Deliberately coarse — the goal is to reassure the user the
/// app understood the code, not to build a QR content parser.
String describePayload(String payload) {
  final trimmed = payload.trim();
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('wifi:')) return 'Wi-Fi network details';
  if (lower.startsWith('begin:vcard')) return 'a contact card';
  if (lower.startsWith('begin:vevent')) return 'a calendar event';
  if (lower.startsWith('mailto:')) return 'an email address';
  if (lower.startsWith('tel:')) return 'a phone number';
  if (lower.startsWith('sms:') || lower.startsWith('smsto:')) {
    return 'a text message';
  }
  if (lower.startsWith('geo:')) return 'a map location';
  if (lower.startsWith('otpauth:')) return 'a two-factor setup code';
  if (lower.startsWith('bitcoin:') || lower.startsWith('ethereum:')) {
    return 'a cryptocurrency address';
  }
  return 'plain text';
}
