import 'dart:convert';

import 'rule_data.dart';

/// Phase 2 fuzzy-matching primitives: LCS similarity (Rule 19) and SimHash
/// near-duplicate detection (Rule 20).
///
/// Ported from `scansafe_prototype.py`. Ref: Charikar 2002, "Similarity
/// Estimation Techniques from Rounding Algorithms".

final RegExp _nonAlnum = RegExp(r'[^a-z0-9]');

/// Longest Common Subsequence length, space-optimised DP.
/// O(m*n) time, O(min(m,n)) space.
int lcsLength(String a, String b) {
  if (a.length < b.length) {
    final tmp = a;
    a = b;
    b = tmp;
  }
  final m = a.length;
  final n = b.length;
  var prev = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    final curr = List<int>.filled(n + 1, 0);
    for (var j = 1; j <= n; j++) {
      if (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1)) {
        curr[j] = prev[j - 1] + 1;
      } else {
        curr[j] = curr[j - 1] > prev[j] ? curr[j - 1] : prev[j];
      }
    }
    prev = curr;
  }
  return prev[n];
}

/// LCS-based similarity ratio in [0.0, 1.0].
double lcsSimilarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  return lcsLength(a, b) / (a.length > b.length ? a.length : b.length);
}

/// Registrable domain label, aware of two-part TLDs.
///
/// `amaz0n.co.uk` -> `amaz0n`; `login.paypa1.com` -> `paypa1`.
///
/// Mirrors the prototype's `replaceAll` on `www.` (not a prefix strip) so that
/// hosts are reduced identically in both implementations.
String apexDomain(String host) {
  final parts = host.replaceAll('www.', '').split('.');
  if (parts.length >= 3 && knownSlds.contains(parts[parts.length - 2])) {
    return parts[parts.length - 3];
  }
  return parts.length >= 2 ? parts[parts.length - 2] : parts[0];
}

/// A brand match from [detectTyposquatting].
class TyposquatMatch {
  const TyposquatMatch(this.brand, this.similarity);
  final String brand;
  final double similarity;
}

const double lcsThreshold = 0.75;

/// Compare the apex domain against known brands using LCS similarity.
///
/// Returns the best match at or above [lcsThreshold], skipping exact matches
/// (a domain that *is* the brand is legitimate). Catches `grarnbling.edu`,
/// `paypa1.com`, `arnazon.com` — all of which evade the literal
/// substring check in Rule 8.
TyposquatMatch? detectTyposquatting(String host) {
  final apexClean = apexDomain(host).toLowerCase().replaceAll(_nonAlnum, '');

  String? bestBrand;
  var bestSim = 0.0;
  for (final brand in brandList) {
    final brandClean = brand.toLowerCase().replaceAll(_nonAlnum, '');
    if (apexClean == brandClean) continue; // exact match — legitimate
    final sim = lcsSimilarity(apexClean, brandClean);
    if (sim >= lcsThreshold && sim > bestSim) {
      bestBrand = brand;
      bestSim = sim;
    }
  }
  return bestBrand == null ? null : TyposquatMatch(bestBrand, bestSim);
}

/// Apply the homoglyph substitution table used by Rule 19b.
String normaliseHomoglyphs(String input) {
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    buffer.write(homoglyphMap[ch] ?? ch);
  }
  return buffer.toString();
}

const int _simHashBits = 64;
final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;

/// DJB2-style 64-bit non-cryptographic hash used for SimHash token weighting.
///
/// Uses [BigInt] rather than `int` because Dart's `int` is a 53-bit double with
/// 32-bit bitwise operations when compiled to JavaScript. BigInt keeps the
/// fingerprint bit-identical on mobile, desktop, and web.
BigInt hashToken(String token) {
  var h = BigInt.from(5381);
  for (final byte in utf8.encode(token)) {
    h = ((h << 5) + h + BigInt.from(byte)) & _mask64;
  }
  return h;
}

/// 64-bit SimHash fingerprint of a normalised URL.
///
/// Tokens are lowercase host labels, path segments, and query *key* names.
/// Query values are excluded — they carry per-session noise, not structure.
BigInt simHash(String url) {
  final Uri parsed;
  try {
    parsed = Uri.parse(url.toLowerCase());
  } on FormatException {
    return BigInt.zero;
  }

  final tokens = <String>[
    ...parsed.host.split('.').where((t) => t.isNotEmpty),
    ...parsed.path.split('/').where((t) => t.isNotEmpty),
  ];
  final query = parsed.query;
  if (query.isNotEmpty) {
    for (final kv in query.split('&')) {
      final key = kv.split('=').first;
      if (key.isNotEmpty) tokens.add(key);
    }
  }

  final v = List<int>.filled(_simHashBits, 0);
  for (final token in tokens) {
    final h = hashToken(token);
    for (var i = 0; i < _simHashBits; i++) {
      v[i] += ((h >> i) & BigInt.one) == BigInt.one ? 1 : -1;
    }
  }

  var fingerprint = BigInt.zero;
  for (var i = 0; i < _simHashBits; i++) {
    if (v[i] > 0) fingerprint |= (BigInt.one << i);
  }
  return fingerprint;
}

/// Number of differing bits between two fingerprints.
int hammingDistance(BigInt a, BigInt b) {
  var x = a ^ b;
  var count = 0;
  while (x > BigInt.zero) {
    if ((x & BigInt.one) == BigInt.one) count++;
    x >>= 1;
  }
  return count;
}

const int simHashThreshold = 4;

/// Session-scoped store of SimHash fingerprints for Rule 20.
///
/// The prototype used a module-level global; making it an injectable object
/// keeps scoring deterministic under test and lets the app decide the
/// fingerprint lifetime. Nothing leaves the device.
class SimHashCache {
  final List<(String, BigInt)> _entries = [];

  /// Returns the first cached URL within [simHashThreshold] Hamming distance,
  /// or null. Always records [url], matching the prototype's behaviour.
  String? checkNearDuplicate(String url) {
    final fp = simHash(url);
    String? match;
    for (final (cachedUrl, cachedFp) in _entries) {
      if (hammingDistance(fp, cachedFp) <= simHashThreshold) {
        match = cachedUrl;
        break;
      }
    }
    _entries.add((url, fp));
    return match;
  }

  void clear() => _entries.clear();

  int get length => _entries.length;
}
